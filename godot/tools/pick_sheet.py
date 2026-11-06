#!/usr/bin/env python3
"""Codex가 한 요청에 여러 장 그렸을 때(다시 그리기) 가장 쓸 만한 장을 고른다.

  python3 tools/pick_sheet.py <열> <줄> <목표 키 px> <출력.png> <후보.png…>

점수(낮을수록 좋음): 배경이 투명하지 않음(+1000), 칸 경계에 닿은 인물(칸마다 +50),
빈 칸(+500), 키가 목표와 다름(칸마다 |차이|/목표 × 100), 칸마다 발 높이가 들쭉날쭉(표준편차 px).
"""
import shutil
import sys
from statistics import pstdev

from PIL import Image


def score(path, cols, rows, target):
    im = Image.open(path).convert('RGBA')
    a = im.getchannel('A')
    w, h = im.size
    s = 0.0
    corners = [a.getpixel((x, y)) for x in (2, w - 3) for y in (2, h - 3)]
    if max(corners) > 16:
        s += 1000
    cw, ch = w / cols, h / rows
    feet = []
    for r in range(rows):
        for c in range(cols):
            box = (round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))
            cell = a.crop(box).point(lambda v: 255 if v >= 128 else 0)
            b = cell.getbbox()
            if b is None:
                s += 500
                continue
            if b[0] <= 1 or b[1] <= 1 or b[2] >= cell.width - 1 or b[3] >= cell.height - 1:
                s += 50
            s += abs((b[3] - b[1]) - target) / target * 100
            feet.append(b[3])
    if len(feet) > 1:
        s += pstdev(feet)
    return s


def main():
    cols, rows, target, out = int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), sys.argv[4]
    cands = sys.argv[5:]
    ranked = sorted((score(p, cols, rows, target), p) for p in cands)
    for sc, p in ranked:
        print(f'{sc:8.1f}  {p}')
    shutil.copy(ranked[0][1], out)


if __name__ == '__main__':
    main()
