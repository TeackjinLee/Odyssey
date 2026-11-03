#!/usr/bin/env python3
"""챕터 1 맵 배치도: 지금 맵과 개편안(docs/maps/CH1_TROY.md)을 아이소 격자로 나란히 그린다.

    python3 tools/gen_map_plan.py .        → docs/maps/ch1_layout.png

게임과 같은 방향(x는 화면 오른쪽 아래, y는 왼쪽 아래)으로 칸마다 구역 색을 칠하고 번호를 붙인다.
구역 사각형은 scripts/world/chapter1_troy.gd의 fill()·소품 자리를 옮겨 적은 것(지금)과 개편안(제안).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

TW, TH = 16, 8  # 칸 하나의 아이소 크기(그림용)

COL = {
    "out": (88, 110, 70), "wall": (190, 175, 145), "gate": (230, 120, 40), "plaza": (150, 150, 165),
    "road": (120, 115, 105), "dirt": (140, 115, 85), "ash": (85, 80, 80), "house": (165, 70, 55),
    "fire": (240, 110, 30), "market": (215, 70, 90), "temple": (235, 225, 190), "fountain": (70, 150, 220),
    "horse": (120, 80, 40), "sea": (40, 90, 170), "dock": (150, 105, 60), "tree": (50, 120, 70),
    "block": (60, 60, 60), "rock": (110, 105, 100),
}


def cur_zones():
    """지금 맵 (chapter1_troy.gd build())."""
    W, H = 36, 50
    z = []
    z += [("out", 0, 0, 36, 3), ("out", 0, 0, 2, 50)]
    z += [("plaza", 12, 4, 13, 6), ("dirt", 3, 10, 31, 3), ("road", 16, 13, 5, 26), ("dirt", 3, 13, 4, 35),
          ("market", 27, 13, 6, 26), ("ash", 6, 22, 10, 4), ("ash", 21, 22, 6, 4), ("plaza", 7, 38, 26, 10)]
    z += [("house", 7, 13, 9, 9), ("house", 7, 26, 9, 12), ("house", 21, 13, 6, 9), ("house", 21, 26, 6, 12),
          ("house", 33, 13, 2, 25), ("house", 3, 4, 8, 6), ("house", 26, 4, 8, 6)]
    z += [("wall", 2, 3, 34, 1), ("wall", 2, 3, 1, 47), ("gate", 17, 3, 2, 1)]
    z += [("block", 35, 3, 1, 47), ("block", 3, 49, 33, 1), ("horse", 19, 42, 2, 2)]
    labels = [("1", 18, 6.5), ("2", 18, 11), ("3", 4.5, 30), ("4", 18, 30), ("5", 30, 30), ("6", 11, 23.5),
              ("7", 20, 45)]
    return W, H, z, labels


def new_zones():
    """개편안 (docs/maps/CH1_TROY.md §3)."""
    W, H = 42, 50
    z = []
    z += [("out", 0, 0, 37, 3), ("out", 0, 0, 2, 50), ("tree", 0, 0, 1, 50), ("tree", 4, 0, 6, 1)]
    z += [("sea", 37, 0, 5, 50), ("rock", 36, 0, 1, 33), ("rock", 36, 46, 1, 4)]
    z += [("plaza", 12, 4, 13, 6), ("dirt", 3, 10, 31, 3), ("road", 16, 13, 5, 26), ("dirt", 3, 13, 4, 35),
          ("dirt", 27, 13, 7, 26), ("plaza", 7, 38, 26, 10)]
    z += [("house", 7, 13, 9, 8), ("house", 7, 27, 9, 11), ("house", 21, 13, 6, 8), ("house", 21, 27, 6, 11),
          ("house", 3, 4, 8, 6)]
    z += [("tree", 3, 16, 1, 2), ("tree", 3, 33, 1, 2), ("tree", 6, 19, 1, 1), ("tree", 6, 36, 1, 1)]
    z += [("temple", 26, 4, 9, 6), ("plaza", 27, 8, 5, 2)]
    z += [("plaza", 12, 21, 13, 6), ("fountain", 17, 23, 2, 2), ("market", 13, 21, 3, 2), ("market", 21, 25, 3, 2)]
    z += [("fire", 28, 13, 6, 10), ("ash", 27, 22, 7, 2), ("market", 28, 25, 5, 12)]
    z += [("dock", 37, 33, 3, 2), ("dock", 37, 38, 4, 2), ("dock", 37, 43, 3, 2), ("dock", 36, 33, 1, 13)]
    z += [("wall", 2, 3, 34, 1), ("wall", 2, 3, 1, 47), ("wall", 35, 3, 1, 47), ("wall", 2, 49, 34, 1),
          ("gate", 17, 3, 2, 1), ("gate", 35, 39, 1, 1), ("horse", 9, 41, 2, 2), ("wall", 13, 4, 2, 2)]
    labels = [("1", 18, 6.5), ("2", 18, 11), ("3", 4.5, 30), ("4", 18, 30), ("5", 31, 18), ("6", 18, 24),
              ("7", 20, 45), ("8", 30, 6), ("9", 30, 31), ("10", 38.5, 39), ("11", 13.5, 4.5)]
    return W, H, z, labels


def iso(x, y, ox, oy):
    return ox + (x - y) * TW / 2, oy + (x + y) * TH / 2


def draw_map(W, H, zones, labels, title, font, small):
    w = int((W + H) * TW / 2) + 40
    h = int((W + H) * TH / 2) + 70
    im = Image.new("RGB", (w, h), (28, 30, 38))
    d = ImageDraw.Draw(im)
    ox, oy = H * TW / 2 + 20, 50
    grid = [["plaza"] * W for _ in range(H)]
    for kind, x0, y0, ww, hh in zones:
        for y in range(y0, min(H, y0 + hh)):
            for x in range(x0, min(W, x0 + ww)):
                grid[y][x] = kind
    for y in range(H):
        for x in range(W):
            c = COL[grid[y][x]]
            pts = [iso(x, y, ox, oy), iso(x + 1, y, ox, oy), iso(x + 1, y + 1, ox, oy), iso(x, y + 1, ox, oy)]
            d.polygon(pts, fill=c, outline=tuple(max(0, v - 25) for v in c))
    for text, gx, gy in labels:
        px, py = iso(gx, gy, ox, oy)
        r = 9
        d.ellipse([px - r, py - r, px + r, py + r], fill=(255, 255, 255), outline=(0, 0, 0))
        tb = d.textbbox((0, 0), text, font=small)
        d.text((px - (tb[2] - tb[0]) / 2, py - (tb[3] - tb[1]) / 2 - tb[1]), text, fill=(0, 0, 0), font=small)
    d.text((14, 10), title, fill=(240, 240, 240), font=font)
    return im


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    fp = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
    font = ImageFont.truetype(fp, 20) if os.path.exists(fp) else ImageFont.load_default()
    small = ImageFont.truetype(fp, 12) if os.path.exists(fp) else ImageFont.load_default()
    a = draw_map(*cur_zones(), "지금 (36×50)", font, small)
    b = draw_map(*new_zones(), "개편안 (42×50, 오른쪽 아래 바다)", font, small)
    legend = [("성벽", "wall"), ("성문", "gate"), ("광장", "plaza"), ("대로", "road"), ("흙길", "dirt"), ("집", "house"),
              ("불타는 집", "fire"), ("시장", "market"), ("신전", "temple"), ("분수", "fountain"), ("목마", "horse"),
              ("바다", "sea"), ("부두", "dock"), ("나무", "tree"), ("바위", "rock"), ("성 밖", "out"), ("막힘", "block"),
              ("잿더미", "ash")]
    lh = 40
    out = Image.new("RGB", (a.width + b.width, max(a.height, b.height) + lh), (28, 30, 38))
    out.paste(a, (0, 0))
    out.paste(b, (a.width, 0))
    d = ImageDraw.Draw(out)
    x = 14
    y = out.height - lh + 10
    for name, k in legend:
        d.rectangle([x, y, x + 16, y + 16], fill=COL[k])
        d.text((x + 20, y), name, fill=(230, 230, 230), font=small)
        x += 30 + int(d.textlength(name, font=small))
    path = os.path.join(root, "docs/maps/ch1_layout.png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out.save(path)
    print(path, out.size)


if __name__ == "__main__":
    main()
