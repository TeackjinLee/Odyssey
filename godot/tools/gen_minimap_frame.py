#!/usr/bin/env python3
"""받은 미니맵 테두리(둥근 고리, 배경·안쪽 마젠타) → assets/ui/frames/minimap.png (게임 크기, 배경 투명).

    python3 tools/gen_minimap_frame.py .

요청 묶음: docs/sprite_request/skill_requests/minimap/. 원본: assets/source/ui_minimap.png.
hud.gd의 미니맵은 반지름 42px 원이다. 고리 안쪽 반지름이 INNER px이 되게 줄인다(지도 가장자리를 1px 덮음).
"""
import os
import sys

from PIL import Image

INNER = 41


def is_bg(r, g, b):
    return r > 180 and b > 180 and g < 110          # 마젠타와 그 언저리


def main(root):
    im = Image.open(os.path.join(root, "assets/source/ui_minimap.png")).convert("RGBA")
    w, h = im.size
    px = im.load()
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            if is_bg(r, g, b):
                px[x, y] = (0, 0, 0, 0)
    x0, y0, x1, y1 = im.getbbox()
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    outer = max(x1 - x0, y1 - y0) / 2
    # 안쪽 반지름: 가운데에서 오른쪽으로 처음 불투명이 나오는 곳
    inner = next(r for r in range(int(outer)) if px[int(cx + r), int(cy)][3] > 0)
    s = INNER / inner
    size = int(round(outer * 2 * s))
    size += size % 2
    half = size / s / 2
    crop = im.crop((int(cx - half), int(cy - half), int(cx + half), int(cy + half)))
    small = crop.convert("RGBa").resize((size, size), Image.LANCZOS).convert("RGBA")
    sp = small.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = sp[x, y]
            sp[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    out = os.path.join(root, "assets/ui/frames/minimap.png")
    small.save(out)
    print(out, small.size, "원본 고리 바깥·안쪽 반지름", round(outer), inner)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
