"""App icons for the separate native editors: each environment's VRAVIO glyph (assets/<kind>.svg)
on a dark rounded tile, written under the file names its upstream app embeds
(upstream/<repo>/assets/app-icon/...).

    python scripts/native-icons.py <kind> <repo> <out-dir>

Needs rsvg-convert (librsvg) and Pillow.
"""
import io
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

kind, repo, out = sys.argv[1], sys.argv[2], Path(sys.argv[3])
root = Path(__file__).resolve().parent.parent
svg = root / 'assets' / f'{kind}.svg'
app_id = f'ai.storyteller.{repo}'


def glyph(size):
    png = subprocess.run(['rsvg-convert', '-w', str(size), '-h', str(size), str(svg)], check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(png)).convert('RGBA')


def tile(size, margin=0.0):
    """The glyph at 64 % of a dark rounded square; `margin` leaves macOS's transparent border."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    inner = round(size * (1 - 2 * margin))
    off = (size - inner) // 2
    square = Image.new('RGBA', (inner, inner), (0, 0, 0, 0))
    ImageDraw.Draw(square).rounded_rectangle([0, 0, inner - 1, inner - 1], radius=round(inner * 0.22), fill=(24, 24, 28, 255))
    g = glyph(round(inner * 0.64))
    square.alpha_composite(g, ((inner - g.width) // 2, (inner - g.height) // 2))
    img.alpha_composite(square, (off, off))
    return img


out.mkdir(parents=True, exist_ok=True)
full = tile(1024)
mac = tile(1024, margin=0.1)  # Apple's 824/1024 body grid
mac.save(out / f'{repo}-1024.png')
mac.resize((512, 512), Image.LANCZOS).save(out / f'{repo}-macos-512.png')
mac.save(out / f'{repo}.icns', sizes=[(16, 16), (32, 32), (64, 64), (128, 128), (256, 256), (512, 512), (1024, 1024)])
full.save(out / f'{repo}.ico', sizes=[(s, s) for s in (16, 20, 24, 32, 40, 48, 64, 128, 256)])
for s in (16, 24, 32, 48, 64, 128, 256, 512):
    d = out / 'hicolor' / f'{s}x{s}' / 'apps'
    d.mkdir(parents=True, exist_ok=True)
    tile(s).save(d / f'{app_id}.png')
print(f'{kind}: icons for {repo} in {out}')
