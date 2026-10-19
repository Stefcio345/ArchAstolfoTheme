"""Kitty watcher: lay out the existing ornaments at each window's native size.

Original artwork is never changed. Rendered window backgrounds live in the
user cache; Pillow is already a dependency of the terminal theme.
"""
from functools import lru_cache
import hashlib
import os
from pathlib import Path
import tempfile

from PIL import Image, ImageChops

SOURCE = Path(__file__).resolve().with_name("gothic-corners-v4.png")
BACKGROUND = (26, 27, 31)
CROPS = {
    "top_left": (0, 0, .30, .23),
    "top_right": (.72, 0, 1, .29),
    "bottom_left": (0, .76, .36, 1),
    "bottom_right": (.65, .75, 1, 1),
    "crest": (.55, .265, .985, .725),
}


@lru_cache(maxsize=2)
def _artwork(version):
    with Image.open(SOURCE) as opened:
        image = opened.convert("RGB")
    red, green, _ = image.split()
    # The ornaments are rose; the backdrop is neutral charcoal. Separate the
    # linework from its old canvas so cropped rectangular backdrops cannot show.
    alpha = ImageChops.subtract(red, green).point([min(255, n * 64) for n in range(256)])
    image.putalpha(alpha)
    width, height = image.size
    pieces = {name: image.crop(tuple(round(v * (width if i % 2 == 0 else height))
                                     for i, v in enumerate(box)))
              for name, box in CROPS.items()}
    return image.size, pieces


def _source_version():
    stat = SOURCE.stat()
    return stat.st_mtime_ns, stat.st_size


def placements(width, height):
    if width < 1 or height < 1:
        raise ValueError("Window dimensions must be positive")
    (source_width, source_height), pieces = _artwork(_source_version())
    scale = min(width / source_width, height / source_height)
    result = {}
    for name, image in pieces.items():
        w, h = max(1, round(image.width * scale)), max(1, round(image.height * scale))
        x = width - w if name in ("top_right", "bottom_right", "crest") else 0
        y = height - h if name.startswith("bottom") else 0
        if name == "crest":
            y = (height - h) // 2
        result[name] = x, y, w, h
    return result


def render_background(width, height, cache_dir=None):
    version = _source_version()
    digest = hashlib.sha256(f"{SOURCE}:{version}".encode()).hexdigest()[:12]
    cache = Path(cache_dir) if cache_dir is not None else (
        Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") /
        "astolfo-goth/responsive-backgrounds")
    cache.mkdir(parents=True, exist_ok=True)
    destination = cache / f"bg-v2-{width}x{height}-{digest}.png"
    if destination.is_file():
        return destination
    boxes = placements(width, height)
    _, pieces = _artwork(version)
    canvas = Image.new("RGB", (width, height), BACKGROUND)
    for name, (x, y, w, h) in boxes.items():
        piece = pieces[name].resize((w, h), Image.Resampling.LANCZOS)
        if name == "crest":
            piece.putalpha(piece.getchannel("A").point([round(n * .58) for n in range(256)]))
        canvas.paste(piece, (x, y), piece)
    # Separate Kitty processes can request the same size simultaneously.
    with tempfile.NamedTemporaryFile(dir=cache, suffix=".png", delete=False) as output:
        temporary = Path(output.name)
    try:
        canvas.save(temporary, "PNG", compress_level=2)
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    # Limit generated resize variants, without touching artwork or other caches.
    variants = sorted(cache.glob("bg-v[12]-*.png"), key=lambda p: p.stat().st_mtime, reverse=True)
    for old in variants[32:]:
        if old != destination:
            old.unlink(missing_ok=True)
    return destination


_pending = {}
_scheduled = set()
_applied = {}


def on_resize(boss, window, data):
    from kitty.fast_data_types import add_timer, get_os_window_size
    os_id = window.os_window_id
    size = get_os_window_size(os_id)
    if size is None:
        return
    dimensions = size["width"], size["height"]
    if min(dimensions) < 1:
        return
    _pending[os_id] = dimensions
    if os_id in _scheduled:
        return
    _scheduled.add(os_id)

    def update(timer_id):
        _scheduled.discard(os_id)
        dimensions = _pending.pop(os_id, None)
        if dimensions is None or os_id not in boss.os_window_map:
            return
        key = dimensions, _source_version()
        if _applied.get(os_id) == key:
            return
        try:
            path = render_background(*dimensions)
            # The canvas is exactly the OS window size. Only the ornaments were
            # scaled, uniformly; this final blit cannot crop off the corners.
            boss.set_background_image(str(path), (os_id,), False, "scaled")
            _applied[os_id] = key
        except Exception as exc:
            from kitty.utils import log_error
            log_error(f"Gothic background: {exc}")

    add_timer(update, .12, False)


def on_focus_change(boss, window, data):
    if data.get("focused"):
        on_resize(boss, window, data)


def on_close(boss, window, data):
    _pending.pop(window.os_window_id, None)
    _applied.pop(window.os_window_id, None)
