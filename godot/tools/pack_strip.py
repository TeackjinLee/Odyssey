#!/usr/bin/env python3
"""방향마다 따로 받은 동작 그림(한 장에 프레임 격자) → gen_hero.py가 읽는 8방향 한 장.

받는 것: assets/source/odysseus_<동작>_<방향>.webp(또는 .png), 방향은 S SE E NE N 다섯.
  마젠타 배경, 프레임은 읽는 순서(왼→오, 위→아래)로 COLS×ROWS 격자.
서·북서·남서는 동·북동·남동 줄을 좌우로 뒤집어 만든다(손 위치는 gen_hero.py의 STRIP_MIRROR).
방향마다 따로 그려 받아 크기가 조금씩 다르므로, 방향마다 키(가운데값)를 CHAR_H로 맞추고
프레임마다 발을 같은 기준선에 둔다(걷기는 늘 한 발이 땅에 닿아 있다).

출력: assets/source/odysseus_<동작>_8dir.webp (줄 = 남→남동→동→북동→북→북서→서→남서, 칸 CELL×CELL)
사용: python3 tools/pack_strip.py <godot 프로젝트 폴더> <동작> [격자 열 수] [격자 줄 수]
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from gen_hero import is_bg  # noqa: E402

CELL = 256
CHAR_H = 216
BASE_Y = 244
FIT_TOL = 0.01
DRAWN = ["S", "SE", "E", "NE", "N"]
# 8방향 한 장의 줄 순서 → (받은 방향, 좌우 뒤집기)
ROWS = [("S", False), ("SE", False), ("E", False), ("NE", False), ("N", False),
        ("NE", True), ("E", True), ("SE", True)]
MAGENTA = (255, 0, 255)


def load(root, anim, d):
    for ext in ("webp", "png"):
        p = root / f"assets/source/odysseus_{anim}_{d}.{ext}"
        if p.exists():
            return Image.open(p).convert("RGB")
    sys.exit(f"없음: assets/source/odysseus_{anim}_{d}.webp")


def frames(src, cols, rows):
    """격자 칸마다 배경을 지운 인물만 잘라 낸 RGBA 목록(읽는 순서)."""
    cw, ch = src.width / cols, src.height / rows
    out = []
    for r in range(rows):
        for c in range(cols):
            cell = src.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))).convert("RGBA")
            px = cell.load()
            for y in range(cell.height):
                for x in range(cell.width):
                    if is_bg(px[x, y]):
                        px[x, y] = (0, 0, 0, 0)
            # 칸 테두리에 걸친 이웃 칸 조각을 빼려고 가장 큰 덩어리 둘레만 쓴다
            out.append(cell.crop(main_box(cell)))
    return out


def main_box(cell):
    a = cell.getchannel("A").point(lambda v: 255 if v > 0 else 0)
    w, h = a.size
    cols = [any(a.getpixel((x, y)) for y in range(0, h, 2)) for x in range(w)]
    rows = [any(a.getpixel((x, y)) for x in range(0, w, 2)) for y in range(h)]

    def span(flags):
        best, cur, start = (0, 0), 0, 0
        for i, f in enumerate(flags + [False]):
            if f:
                if cur == 0:
                    start = i
                cur += 1
            elif cur:
                if cur > best[1] - best[0]:
                    best = (start, i)
                cur = 0
        return best
    x0, x1 = span(cols)
    y0, y1 = span(rows)
    return (x0, y0, x1, y1)


def fit(f, k):
    """방향 배율 k로 줄이되, 키가 CHAR_H에서 FIT_TOL 넘게 벗어난 장면(그려 받을 때 칸마다 키가 들쭉날쭉한 것)만
    그 경계로 맞춘다. 발을 기준선에 두므로 키가 튀면 머리가 그만큼 깡충거린다."""
    h = min(max(f.height * k, CHAR_H * (1 - FIT_TOL)), CHAR_H * (1 + FIT_TOL))
    k = h / f.height
    return f.resize((max(1, round(f.width * k)), max(1, round(f.height * k))), Image.LANCZOS)


def head_cx(f):
    """머리(위 30%) 불투명 픽셀의 가로 무게중심. 그림 상자 가운데로 맞추면 다리를 벌릴 때마다 몸이 밀려
    디딘 발이 땅에서 미끄러져 보이므로, 머리를 칸 가운데 두어 그린 발 움직임을 그대로 살린다."""
    a = f.getchannel("A").load()
    xs = [x for y in range(int(f.height * 0.3)) for x in range(f.width) if a[x, y] > 40]
    return sum(xs) / len(xs) if xs else f.width / 2


def main(root, anim, cols=4, rows=3):
    drawn = {}
    for d in DRAWN:
        fr = frames(load(root, anim, d), cols, rows)
        hs = sorted(f.height for f in fr)
        k = CHAR_H / hs[len(hs) // 2]
        drawn[d] = [fit(f, k) for f in fr]
    n = cols * rows
    sheet = Image.new("RGB", (CELL * n, CELL * len(ROWS)), MAGENTA)
    for row, (d, flip) in enumerate(ROWS):
        for i, f in enumerate(drawn[d]):
            if flip:
                f = f.transpose(Image.FLIP_LEFT_RIGHT)
            sheet.paste(f, (i * CELL + CELL // 2 - round(head_cx(f)), row * CELL + BASE_Y - f.height), f)
    out = root / f"assets/source/odysseus_{anim}_8dir.webp"
    sheet.save(out, lossless=True)
    print(out.relative_to(root), sheet.size)


if __name__ == "__main__":
    a = sys.argv[1:]
    main(Path(a[0]), a[1], *(int(v) for v in a[2:4]))
