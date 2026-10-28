"""Builds every app icon from the artwork in design/.

    python -I tools/make_icons.py [--sheet contact-sheet.png]

Needs Pillow. Reads design/icon-artwork.png (colour, transparent) and
design/icon-mono.png (white silhouette), and overwrites the Android, iOS, web
and assets/ icons in place. --sheet also renders a preview of the main icons.
"""

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
DESIGN = ROOT / 'design'
RES = ROOT / 'android/app/src/main/res'
IOS = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
WEB = ROOT / 'web'

# Diagonal background, fitted to the reference mock-up.
TOP_LEFT = (0xDD, 0x77, 0x3D)
BOTTOM_RIGHT = (0xDC, 0x3A, 0x2A)

# Distance from the centre to the artwork's farthest pixel, as a fraction of
# the icon's size. For the adaptive layers the safe zone allows 0.30 (they are
# clipped there), but 0.26 gives about the same proportion as TILE_R within
# the 72dp of 108dp that a launcher shows.
ANDROID_R = 0.26
TILE_R = 0.38  # iOS, Play, web tiles
FAVICON_R = 0.45  # larger, so the bowl still reads at 16 and 32 px
MASKABLE_R = 0.36  # web maskable: the safe zone is 0.40
TILE_CORNER = 0.22  # rounded tiles' corner radius
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


class Source:
    """An RGBA image with the centre and radius of its visible content."""

    def __init__(self, image):
        alpha = image.getchannel('A')
        left, top, right, bottom = alpha.point(lambda v: 255 if v > 8 else 0).getbbox()
        self.cx, self.cy = (left + right) / 2, (top + bottom) / 2
        px = alpha.load()
        self.radius = max(
            math.hypot(x + 0.5 - self.cx, y + 0.5 - self.cy)
            for y in range(top, bottom)
            for x in range(left, right)
            if px[x, y] > 8
        )
        # Pad so any crop box below stays inside the image.
        pad = max(image.size)
        self.image = Image.new('RGBA', (image.width + 2 * pad, image.height + 2 * pad))
        self.image.paste(image, (pad, pad))
        self.cx += pad
        self.cy += pad

    def placed(self, size, r):
        """The content centred on a transparent size x size canvas, its
        farthest pixel r * size from the centre."""
        half = self.radius / r / 2
        box = (self.cx - half, self.cy - half, self.cx + half, self.cy + half)
        return self.image.resize((size, size), Image.LANCZOS, box=box)

    def fitted(self, size, inner):
        """The content's bounding box centred and scaled to fit inner px."""
        bbox = self.image.getchannel('A').getbbox()
        crop = self.image.crop(bbox)
        k = inner / max(crop.size)
        w, h = max(1, round(crop.width * k)), max(1, round(crop.height * k))
        out = Image.new('RGBA', (size, size))
        out.paste(crop.resize((w, h), Image.LANCZOS), ((size - w) // 2, (size - h) // 2))
        return out


def load_artwork():
    return Source(Image.open(DESIGN / 'icon-artwork.png').convert('RGBA'))


def load_mono():
    """The silhouette as pure white with a clean alpha: the source is grainy."""
    alpha = Image.open(DESIGN / 'icon-mono.png').convert('RGBA').getchannel('A')
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.5)).point(lambda v: 255 if v >= 128 else 0)
    alpha = alpha.filter(ImageFilter.MedianFilter(5))
    image = Image.new('RGBA', alpha.size, (255, 255, 255, 0))
    image.putalpha(alpha)
    return Source(image)


def gradient(size):
    steps = 2 * size - 1
    colours = [
        tuple(round(a + (b - a) * i / max(1, steps - 1)) for a, b in zip(TOP_LEFT, BOTTOM_RIGHT))
        for i in range(steps)
    ]
    image = Image.new('RGB', (size, size))
    image.putdata([colours[x + y] for y in range(size) for x in range(size)])
    return image


def rounded_mask(size, inset=0.0, corner=TILE_CORNER):
    scale = 4
    big = Image.new('L', (size * scale, size * scale))
    edge = inset * size * scale
    side = size * scale - 2 * edge
    ImageDraw.Draw(big).rounded_rectangle(
        (edge, edge, size * scale - edge - 1, size * scale - edge - 1),
        radius=corner * side,
        fill=255,
    )
    return big.reduce(scale)


def square(art, size, r):
    """Opaque full-bleed gradient with the artwork."""
    image = gradient(size).convert('RGBA')
    image.alpha_composite(art.placed(size, r))
    return image.convert('RGB')


def tile(art, size, r=TILE_R, inset=0.0):
    """Rounded gradient tile with the artwork, on transparency. inset is the
    margin around the tile; r is relative to the tile."""
    image = gradient(size).convert('RGBA')
    margin = round(inset * size)
    inner = size - 2 * margin
    image.alpha_composite(art.placed(inner, r), (margin, margin))
    image.putalpha(rounded_mask(size, inset))
    return image


def clip_circle(image, r):
    """Clears every pixel whose centre is more than r * size from the centre."""
    size = image.width
    mask = Image.new('L', image.size)
    limit = r * size
    c = size / 2
    mask.putdata([
        255 if math.hypot(x + 0.5 - c, y + 0.5 - c) <= limit else 0
        for y in range(size)
        for x in range(size)
    ])
    alpha = Image.composite(image.getchannel('A'), Image.new('L', image.size), mask)
    image.putalpha(alpha)
    return image


def white(image):
    """Pure white RGB, keeping only the alpha."""
    out = Image.new('RGBA', image.size, (255, 255, 255, 0))
    out.putalpha(image.getchannel('A'))
    return out


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print(path.relative_to(ROOT), image.size, image.mode)


def save_ico(art, path):
    frames = [tile(art, s, FAVICON_R) for s in (48, 32, 16)]
    frames[0].save(path, format='ICO', sizes=[f.size for f in frames], append_images=frames[1:])
    print(path.relative_to(ROOT), [f.size for f in frames])


def android(art, mono):
    for name, d in DENSITIES.items():
        folder = RES / f'mipmap-{name}'
        layer = round(108 * d)
        save(gradient(layer), folder / 'ic_launcher_background.png')
        save(clip_circle(art.placed(layer, ANDROID_R), 0.30), folder / 'ic_launcher_foreground.png')
        save(white(clip_circle(mono.placed(layer, ANDROID_R), 0.30)), folder / 'ic_launcher_monochrome.png')
        save(tile(art, round(48 * d), inset=2 / 48), folder / 'ic_launcher.png')
        icon = round(24 * d)
        save(white(mono.fitted(icon, 20 * d)), RES / f'drawable-{name}' / 'ic_notification.png')


def ios(art):
    contents = json.loads((IOS / 'Contents.json').read_text())
    for entry in contents['images']:
        points = float(entry['size'].split('x')[0])
        size = round(points * int(entry['scale'].rstrip('x')))
        save(square(art, size, TILE_R), IOS / entry['filename'])


def web(art):
    save(tile(art, 32, FAVICON_R), WEB / 'favicon.png')
    save_ico(art, WEB / 'favicon.ico')
    save(square(art, 180, TILE_R), WEB / 'apple-touch-icon.png')
    for size in (192, 512):
        save(tile(art, size), WEB / f'icons/Icon-{size}.png')
        save(square(art, size, MASKABLE_R), WEB / f'icons/Icon-maskable-{size}.png')


def assets(art):
    # Only icon-192.png is used (AppLogoMark); the rest of assets/web is not.
    save(tile(art, 192), ROOT / 'assets/web/icon-192.png')
    save(square(art, 512, TILE_R), ROOT / 'assets/android/play_store_512.png')


def contact_sheet(path):
    """Previews the generated files roughly as each platform shows them."""
    def load(rel):
        return Image.open(ROOT / rel).convert('RGBA')

    def masked(image, mask):
        out = image.copy()
        out.putalpha(Image.composite(image.getchannel('A'), Image.new('L', image.size), mask))
        return out

    def circle(size):
        big = Image.new('L', (size * 4, size * 4))
        ImageDraw.Draw(big).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
        return big.reduce(4)

    def squircle(size, n=5):
        big = Image.new('L', (size * 4, size * 4))
        c = size * 2
        points = []
        for i in range(720):
            t = 2 * math.pi * i / 720
            x, y = math.cos(t), math.sin(t)
            points.append((c + c * math.copysign(abs(x) ** (2 / n), x), c + c * math.copysign(abs(y) ** (2 / n), y)))
        ImageDraw.Draw(big).polygon(points, fill=255)
        return big.reduce(4)

    def adaptive_visible(rel_bg, rel_fg):
        layer = load(rel_bg)
        layer.alpha_composite(load(rel_fg))
        crop = layer.crop((72, 72, 360, 360))  # the 72dp of 108dp a launcher shows
        return crop.resize((192, 192), Image.LANCZOS)

    xxx = 'android/app/src/main/res/mipmap-xxxhdpi/'
    adaptive = adaptive_visible(xxx + 'ic_launcher_background.png', xxx + 'ic_launcher_foreground.png')

    mono = load(xxx + 'ic_launcher_monochrome.png').crop((72, 72, 360, 360)).resize((192, 192), Image.LANCZOS)
    themed = Image.new('RGBA', (192, 192), (0xD3, 0xEC, 0xD6, 255))
    themed.paste((0x1E, 0x4D, 0x2B, 255), mask=mono.getchannel('A'))

    ios_icon = load('ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon@3x.png')
    play = load('assets/android/play_store_512.png').resize((192, 192), Image.LANCZOS)
    maskable = load('web/icons/Icon-maskable-512.png').resize((192, 192), Image.LANCZOS)

    items = [
        ('Adaptive, circle', masked(adaptive, circle(192))),
        ('Adaptive, squircle', masked(adaptive, squircle(192))),
        ('Legacy 48dp', load(xxx + 'ic_launcher.png')),
        ('Themed', masked(themed, circle(192))),
        ('iOS 180', masked(ios_icon, rounded_mask(180, corner=0.2237))),
        ('Play 512', masked(play, rounded_mask(192, corner=0.2))),
        ('Maskable, circle', masked(maskable, circle(192))),
        ('Web Icon-192', load('web/icons/Icon-192.png')),
    ]

    cell, pad, label_h = 220, 20, 28
    cols = 4
    rows = math.ceil(len(items) / cols)
    strip_h = 200
    sheet = Image.new('RGBA', (cols * cell + pad, rows * (cell + label_h) + strip_h + 2 * pad), (0xEE, 0xEC, 0xE8, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(15)
    for i, (label, image) in enumerate(items):
        x = pad + (i % cols) * cell + (cell - pad - image.width) // 2
        y = pad + (i // cols) * (cell + label_h) + (cell - pad - image.height) // 2
        sheet.alpha_composite(image, (x, y))
        draw.text((pad + (i % cols) * cell, pad + (i // cols) * (cell + label_h) + cell - pad + 4), label, fill=(60, 60, 60), font=font)

    # Status-bar strip with the notification icon, and the favicons.
    top = rows * (cell + label_h) + pad
    draw.rectangle((0, top, sheet.width, top + 110), fill=(0x20, 0x21, 0x24))
    x = pad
    for name in ('mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'):
        icon = load(f'android/app/src/main/res/drawable-{name}/ic_notification.png')
        sheet.alpha_composite(icon, (x, top + 55 - icon.height // 2))
        x += icon.width + 24
    draw.text((x + 10, top + 47), 'Notification icon, mdpi to xxxhdpi', fill=(220, 220, 220), font=font)

    favicon = load('web/favicon.png')
    ico16 = Image.open(WEB / 'favicon.ico')
    ico16.size = (16, 16)
    ico16 = ico16.convert('RGBA')
    y = top + 140
    x = pad
    for bg in ((0xFF, 0xFF, 0xFF, 255), (0x29, 0x2A, 0x2D, 255)):
        draw.rectangle((x - 8, y - 8, x + 72, y + 40), fill=bg)
        sheet.alpha_composite(favicon, (x, y))
        sheet.alpha_composite(ico16, (x + 44, y + 8))
        x += 100
    sheet.alpha_composite(favicon.resize((64, 64), Image.NEAREST), (x, y - 12))
    sheet.alpha_composite(ico16.resize((64, 64), Image.NEAREST), (x + 80, y - 12))
    draw.text((x + 170, y + 8), 'Favicon 32 and 16 (and 4x)', fill=(60, 60, 60), font=font)

    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print('contact sheet:', path)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--sheet', help='also write a preview contact sheet here')
    args = parser.parse_args()

    art = load_artwork()
    mono = load_mono()
    android(art, mono)
    ios(art)
    web(art)
    assets(art)
    if args.sheet:
        contact_sheet(args.sheet)


if __name__ == '__main__':
    main()
