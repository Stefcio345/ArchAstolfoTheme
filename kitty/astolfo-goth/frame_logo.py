#!/usr/bin/env python3
"""Frame a randomly selected Fastfetch logo without modifying the original file.

Cache invalidates if the image is changed. Pillow is preferred, with ImageMagick
or FFmpeg fallback. If none exists, print the original path so Fastfetch works.
"""
import hashlib
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import unicodedata


def text_width(text):
    plain = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", text)
    return sum(0 if unicodedata.combining(c) else
               2 if unicodedata.east_asian_width(c) in ("W", "F") else 1 for c in plain)


def panel_layout(image_size, terminal, lines, start_row=0):
    """Keep image, optional info and the following prompt in disjoint rows."""
    rows, columns, x_pixels, y_pixels = terminal
    rows, columns = max(6, rows), max(1, columns)
    cell_aspect = (y_pixels / rows) / (x_pixels / columns) if min(terminal) > 0 else 2.2
    aspect = image_size[0] / image_size[1]
    available_rows = max(1, rows - start_row - 5)  # divider, gap and two-line prompt
    height = min(13, available_rows)
    width = max(1, min(28, columns - 4, int(height * cell_aspect * aspect)))
    margin = min(8, max(2, columns // 12))
    info_width = max((text_width(line) for line in lines), default=0)
    beside = min(width, columns - 2 * margin - 3 - info_width)
    show_info = columns >= 68 and len(lines) <= available_rows and beside >= 10 and bool(lines)
    if show_info:
        width = beside
    image_rows = min(height, max(1, math.ceil(width / (cell_aspect * aspect))))
    block_rows = max(image_rows, len(lines) if show_info else 0)
    left = max(margin, (columns - width - 3 - info_width) // 2) if show_info else (columns - width) // 2
    return {"image": (left, start_row + (block_rows - image_rows) // 2, width, image_rows),
            "text": (left + width + 3, start_row) if show_info else None,
            "next_row": start_row + block_rows + 1}


def draw_panel(image, start_row, lines=()):
    """Use fixed image placement, then explicitly put the cursor below it."""
    import fcntl
    import struct
    import termios
    from PIL import Image

    try:
        terminal = struct.unpack("HHHH", fcntl.ioctl(sys.stdin.fileno(), termios.TIOCGWINSZ, bytes(8)))
    except (OSError, ValueError):
        terminal = (int(os.environ.get("LINES", 40)), int(os.environ.get("COLUMNS", 80)), 0, 0)
    with Image.open(image) as logo:
        layout = panel_layout(logo.size, terminal, lines, start_row)
    x, y, width, height = layout["image"]
    # Replace only this welcome image, not unrelated terminal graphics.
    print('\x1b_Ga=d,d=I,i=730301\x1b\\', end='', flush=True)
    command = ["kitten", "icat", "--stdin", "no", "--transfer-mode", "file",
               "--image-id", "730301", "--scale-up", "--place", f"{width}x{height}@{x}x{y}"]
    if min(terminal) > 0:
        rows, columns, xp, yp = terminal
        command += ["--use-window-size", f"{columns},{rows},{xp},{yp}"]
    subprocess.run([*command, str(image)], check=True)
    if layout["text"] is not None:
        text_x, text_y = layout["text"]
        for offset, line in enumerate(lines):
            print(f'\x1b[{text_y + offset + 1};{text_x + 1}H{line}', end='')
    print(f'\x1b[0m\x1b[{layout["next_row"] + 1};1H', end='', flush=True)


def display_layout(image: Path, terminal=None) -> tuple[int, int]:
    """Fit the image beside 13 text rows, centering it when space is narrow."""
    import fcntl
    import struct
    import termios
    from PIL import Image

    if terminal is None:
        try:
            terminal = struct.unpack("HHHH", fcntl.ioctl(sys.stdin.fileno(), termios.TIOCGWINSZ, bytes(8)))
        except (OSError, ValueError):
            terminal = (0, 0, 0, 0)
    rows, columns, x_pixels, y_pixels = terminal
    cell_aspect = (y_pixels / rows) / (x_pixels / columns) if min(terminal) > 0 else 2.2
    with Image.open(image) as logo:
        aspect = logo.width / logo.height
    ideal_columns = max(1, int(13 * cell_aspect * aspect))
    available = max(10, columns - 56) if columns else ideal_columns
    fitted = min(ideal_columns, available)
    image_rows = fitted / (cell_aspect * aspect)
    top = max(0, int((13 - image_rows) / 2))
    return fitted, top


def display_columns(image: Path, terminal=None) -> int:
    return display_layout(image, terminal)[0]


def prepare(image: Path, target: Path) -> bool:
    # Pillow is fast, preserves orientation and supports PNG/JPEG/WebP.
    try:
        from PIL import Image, ImageOps
        with Image.open(image) as opened:
            img = ImageOps.exif_transpose(opened).convert('RGBA')
        img.thumbnail((900, 900), Image.Resampling.LANCZOS)
        backdrop = Image.new('RGBA', img.size, '#1A1B1F')
        backdrop.alpha_composite(img)
        img = backdrop.convert('RGB')
        unit = min(img.size)
        gap = max(5, round(unit * 0.012))
        outline = max(1, round(unit * 0.004))
        img = ImageOps.expand(img, border=gap, fill='#1A1B1F')
        img = ImageOps.expand(img, border=outline, fill='#C8859D')
        img.save(target, 'PNG', optimize=True)
        return True
    except ImportError:
        pass
    except Exception as exc:
        print(f'Astolfo: Pillow failed: {exc}', file=sys.stderr)

    # ImageMagick is a fallback on systems without python-pillow.
    magick = shutil.which('magick') or shutil.which('convert')
    if magick:
        args = [magick, str(image), '-auto-orient', '-thumbnail', '900x900>',
                '-background', '#1A1B1F', '-alpha', 'remove', '-alpha', 'off',
                '-bordercolor', '#1A1B1F', '-border', '7',
                '-bordercolor', '#E985A1', '-border', '4', str(target)]
        if subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            return True

    ffmpeg = shutil.which('ffmpeg')
    if ffmpeg:
        filt = 'pad=iw+14:ih+14:7:7:color=0x1A1B1F,pad=iw+22:ih+22:4:4:color=0xE985A1'
        args = [ffmpeg, '-nostdin', '-hide_banner', '-loglevel', 'error', '-y',
                '-i', str(image), '-vf', filt, '-frames:v', '1', str(target)]
        if subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            return True
    return False


def main():
    if len(sys.argv) in (4, 5) and sys.argv[1] == '--panel':
        lines = sys.argv[4].splitlines() if len(sys.argv) == 5 else []
        draw_panel(Path(sys.argv[2]), int(sys.argv[3]), lines)
        return
    if len(sys.argv) == 3 and sys.argv[1] == '--layout':
        print(*display_layout(Path(sys.argv[2])))
        return
    if len(sys.argv) == 3 and sys.argv[1] == '--columns':
        print(display_columns(Path(sys.argv[2])))
        return
    if len(sys.argv) != 2:
        raise SystemExit('Usage: frame_logo.py /path/to/image')
    source = Path(sys.argv[1]).expanduser().resolve()
    if not source.is_file():
        raise SystemExit(f'File not found: {source}')
    st = source.stat()
    version = f'{source}|{st.st_size}|{st.st_mtime_ns}|astolfo-v3'
    name = hashlib.sha256(version.encode()).hexdigest()[:24] + '.png'
    cache = Path(os.environ.get('XDG_CACHE_HOME') or Path.home()/'.cache') / 'astolfo-goth' / 'framed-logos'
    destination = cache / name
    if destination.exists() and destination.stat().st_size > 0:
        print(destination)
        return
    try:
        cache.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_suffix('.tmp.png')
        if prepare(source, temporary) and temporary.exists():
            os.replace(temporary, destination)
            print(destination)
        else:
            temporary.unlink(missing_ok=True)
            print('Astolfo: no image framing backend found. Install python-pillow, imagemagick or ffmpeg.', file=sys.stderr)
            print(source)
    except OSError as exc:
        print(f'Astolfo frame cache: {exc}', file=sys.stderr)
        print(source)

if __name__ == '__main__':
    main()
