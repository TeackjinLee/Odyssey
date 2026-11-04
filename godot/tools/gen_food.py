#!/usr/bin/env python3
"""그려 받은 음식 그림 → assets/sprites/food_icons.png/.json (ART_PLAN C-ANI-food, docs/sprite_request/animal_kit/).

원본 assets/source/food_icons.webp: 4열×3줄, 왼쪽 위부터 ITEMS 순서(make_animal.py FOODS와 같음).
시트: 한 줄로 늘어놓은 칸, json의 items[id] = 칸 번호. food_source.gd가 음식 id(고기는 meat, 낚시찌는 bob)로 찾는다.
사용: python3 tools/gen_food.py .   (godot/ 안에서)
"""
import json
import sys
from pathlib import Path

from PIL import Image

ITEMS = ["meat", "fish", "bob", "fig", "bread", "olive", "berry", "nuts", "honey", "lotus", "cheese", "bowl"]
COLS, ROWS = 4, 3
SIZE = 28      # 시트 안 그림의 긴 변(px) — 게임에서는 scale배(14px)
SCALE = 0.5
PAD = 2


def is_bg(c, glow=False):
    r, g, b = c[:3]
    if r > 150 and b > 150 and g < 120 and abs(r - b) < 70:
        return True
    # 로토스 열매 둘레의 분홍 빛(열매는 붉은 갈색이라 파랑이 적다)
    return glow and ((b > g + 40 and r > g + 60) or (r > 170 and b > 140 and r > g + 25 and b > g + 8))


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    src = Image.open(root / "assets/source/food_icons.webp").convert("RGBA")
    cw, ch = src.width // COLS, src.height // ROWS
    cells = []
    for i in range(len(ITEMS)):
        cell = src.crop(((i % COLS) * cw, (i // COLS) * ch, (i % COLS + 1) * cw, (i // COLS + 1) * ch))
        px = cell.load()
        for y in range(ch):
            for x in range(cw):
                if is_bg(px[x, y], ITEMS[i] == "lotus"):
                    px[x, y] = (0, 0, 0, 0)
        cells.append(cell.crop(cell.getbbox()))
    # 모두 같은 배율: 가장 큰 그림의 긴 변이 SIZE
    k = SIZE / max(max(c.size) for c in cells)
    side = SIZE + PAD * 2
    sheet = Image.new("RGBA", (side * len(cells), side), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        small = c.resize((max(1, round(c.width * k)), max(1, round(c.height * k))), Image.LANCZOS)
        px = small.load()
        for y in range(small.height):
            for x in range(small.width):
                r, g, b, a = px[x, y]
                px[x, y] = (0, 0, 0, 0) if a < 140 else (min(255, round(r * 255 / a)), min(255, round(g * 255 / a)), min(255, round(b * 255 / a)), 255)
        # 칸 아래 가운데에 놓는다(바닥에 놓인 물건)
        sheet.paste(small, (i * side + (side - small.width) // 2, side - PAD - small.height), small)
    sheet.save(root / "assets/sprites/food_icons.png")
    meta = {"frame": [side, side], "anchor": [side // 2, side - PAD], "scale": SCALE, "items": {n: i for i, n in enumerate(ITEMS)}}
    (root / "assets/sprites/food_icons.json").write_text(json.dumps(meta))
    print(f"food_icons: {len(ITEMS)}칸, 칸 {side}px, 축소 {k:.3f}")


if __name__ == "__main__":
    main()
