"""Turns generated recipe photos into the small WebPs the website serves.

    python -I tools/make_recipe_photos.py <folder of images>
    python -I tools/make_recipe_photos.py --placeholders

Needs Pillow. Each image in the folder is named after its recipe id
(pasta-bolognese.png, .jpg or .webp). It is centre-cropped to 4:3, resized
to 640x480 and saved as tools/hosting/recipes/<id>.webp, which
build_hosting.ps1 copies to the website (yumsum.web.app/recipes/<id>.webp).
The app downloads each photo once and keeps it, so none of this goes in
the app itself.

--placeholders draws a plain plate for every recipe in
assets/recipes/recipes.json that has no photo yet.
"""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'tools' / 'hosting' / 'recipes'
RECIPES = ROOT / 'assets' / 'recipes' / 'recipes.json'
SIZE = (640, 480)
QUALITY = 78
MAX_BYTES = 80 * 1024


def crop_to_4_3(image):
    w, h = image.size
    target = 4 / 3
    if w / h > target:
        new_w = round(h * target)
        left = (w - new_w) // 2
        return image.crop((left, 0, left + new_w, h))
    new_h = round(w / target)
    top = (h - new_h) // 2
    return image.crop((0, top, w, top + new_h))


def save(image, recipe_id):
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f'{recipe_id}.webp'
    quality = QUALITY
    while True:
        image.save(path, 'WEBP', quality=quality, method=6)
        size = path.stat().st_size
        if size <= MAX_BYTES or quality <= 50:
            break
        quality -= 6
    print(f'{path.name}: {size // 1024} KB (quality {quality})')


def convert(folder):
    ids = {r['id'] for r in json.loads(RECIPES.read_text(encoding='utf-8'))}
    for source in sorted(folder.iterdir()):
        if source.suffix.lower() not in {'.png', '.jpg', '.jpeg', '.webp'}:
            continue
        if source.stem not in ids:
            print(f'skipped {source.name}: no recipe with that id')
            continue
        image = Image.open(source).convert('RGB')
        save(crop_to_4_3(image).resize(SIZE, Image.LANCZOS), source.stem)


def placeholders():
    for recipe in json.loads(RECIPES.read_text(encoding='utf-8')):
        if (OUT / f"{recipe['id']}.webp").exists():
            continue
        image = Image.new('RGB', SIZE, (0xE9, 0xDC, 0xC8))
        draw = ImageDraw.Draw(image)
        draw.ellipse((170, 90, 470, 390), fill=(0xFB, 0xF6, 0xEE))
        draw.ellipse((215, 135, 425, 345), fill=(0xD9, 0x8B, 0x5A))
        save(image, recipe['id'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', nargs='?', type=Path)
    parser.add_argument('--placeholders', action='store_true')
    args = parser.parse_args()
    if args.placeholders:
        placeholders()
    elif args.folder:
        convert(args.folder)
    else:
        parser.error('give a folder of images, or --placeholders')


if __name__ == '__main__':
    main()
