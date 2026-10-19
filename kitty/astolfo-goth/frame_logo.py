#!/usr/bin/env python3
"""Frame a randomly selected Fastfetch logo without modifying the original file.

Cache invalidates if the image is changed. Pillow is preferred, with ImageMagick
or FFmpeg fallback. If none exists, print the original path so Fastfetch works.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys


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
        outline = max(3, round(unit * 0.008))
        img = ImageOps.expand(img, border=gap, fill='#1A1B1F')
        img = ImageOps.expand(img, border=outline, fill='#E985A1')
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
    if len(sys.argv) != 2:
        raise SystemExit('Usage: frame_logo.py /path/to/image')
    source = Path(sys.argv[1]).expanduser().resolve()
    if not source.is_file():
        raise SystemExit(f'File not found: {source}')
    st = source.stat()
    version = f'{source}|{st.st_size}|{st.st_mtime_ns}|astolfo-v2'
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
