#!/usr/bin/env python3
"""방향마다 따로 받은 동작 그림(한 장에 프레임 격자) → gen_hero.py가 읽는 8방향 한 장.

받는 것: assets/source/odysseus_<동작>_<방향>.webp(또는 .png), 방향은 S SE E NE N 다섯.
  마젠타 배경, 프레임은 읽는 순서(왼→오, 위→아래)로 COLS×ROWS 격자.
서·북서·남서는 동·북동·남동 줄을 좌우로 뒤집어 만든다(손 위치는 gen_hero.py의 STRIP_MIRROR).
방향마다 따로 그려 받아 크기가 조금씩 다르므로, 방향마다 키(가운데값)를 CHAR_H로 맞추고
프레임마다 발을 같은 기준선에 둔다(걷기는 늘 한 발이 땅에 닿아 있다).
달리기(FLIGHT)는 두 발이 다 뜨는 장면이 있으므로 받은 칸에서 그 방향의 가장 낮은 발보다 떠 있는 만큼을 살리고,
다리를 접고 펴는 만큼 키가 달라지므로 키는 맞추지 않는다.
공격(HEAD_SCALE)은 웅크리고 팔을 들어 키가 크게 달라지므로 키 대신 머리 폭(가운데값)을 걷기 시트의 같은 방향 머리 폭에 맞추고,
발이 뜬 만큼을 살린다. 프레임 수가 격자 칸 수보다 적으면(5장을 3×2 칸에 받을 때) 앞에서 그 수만큼만 쓴다.

출력: assets/source/odysseus_<동작>_8dir.webp (줄 = 남→남동→동→북동→북→북서→서→남서, 칸 CELL×CELL)
사용: python3 tools/pack_strip.py <godot 프로젝트 폴더> <동작> [격자 열 수] [격자 줄 수] [프레임 수]
"""
import os
import sys
from pathlib import Path

from PIL import Image

CHAR = os.environ.get("SPRITE_CHAR", "odysseus")   # 다른 캐릭터·옷: SPRITE_CHAR=odysseus_ch1
# 받은 그림의 서 있는 키(px)가 동작마다 같게 그려졌으면(요청 글에 키를 정해 둔 경우) SPRITE_SRC_H로 주면
# 모든 동작·방향을 같은 배율(CHAR_H / 그 키)로 줄인다 — 볏 달린 투구처럼 머리 폭이 자세마다 달라 머리 폭 맞춤이 어긋날 때
SRC_H = float(os.environ.get("SPRITE_SRC_H", "0"))

sys.path.insert(0, str(Path(__file__).parent))
from gen_hero import is_bg  # noqa: E402

CELL = 320      # 강공격 회오리·쓰러진 몸처럼 넓은 장면이 옆 칸에 묻어나지 않게
CHAR_H = 216
BASE_Y = 296
FIT_TOL = 0.01
DRAWN = ["S", "SE", "E", "NE", "N"]
# 웅크리거나 구르거나 쓰러지는 동작도 키가 크게 달라지므로 머리 폭으로 맞추고 뜬 높이를 살린다
FLIGHT = {"run", "attack1", "attack2", "attack3", "heavy", "dodge", "hit", "block", "bow", "death", "idle"}
HEAD_SCALE = {"attack1", "attack2", "attack3", "heavy", "dodge", "hit", "block", "bow", "death", "idle"}
# 8방향 한 장의 줄 순서 → (받은 방향, 좌우 뒤집기)
ROWS = [("S", False), ("SE", False), ("E", False), ("NE", False), ("N", False),
        ("NE", True), ("E", True), ("SE", True)]
MAGENTA = (255, 0, 255)


def load(root, anim, d):
    for ext in ("webp", "png"):
        p = root / f"assets/source/{CHAR}_{anim}_{d}.{ext}"
        if p.exists():
            return Image.open(p).convert("RGB")
    sys.exit(f"없음: assets/source/{CHAR}_{anim}_{d}.webp")


def frames(src, cols, rows):
    """격자 칸마다 배경을 지운 인물만 잘라 낸 (RGBA, 칸 안 발끝 y) 목록(읽는 순서)."""
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
            box = main_box(cell)
            out.append((cell.crop(box), box[3]))
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


def fit(f, k, tol=FIT_TOL):
    """방향 배율 k로 줄이되, 키가 CHAR_H에서 FIT_TOL 넘게 벗어난 장면(그려 받을 때 칸마다 키가 들쭉날쭉한 것)만
    그 경계로 맞춘다. 발을 기준선에 두므로 키가 튀면 머리가 그만큼 깡충거린다."""
    h = min(max(f.height * k, CHAR_H * (1 - tol)), CHAR_H * (1 + tol))
    k = h / f.height
    return f.resize((max(1, round(f.width * k)), max(1, round(f.height * k))), Image.LANCZOS)


def head_cx(f):
    """머리(위 30%) 불투명 픽셀의 가로 무게중심. 그림 상자 가운데로 맞추면 다리를 벌릴 때마다 몸이 밀려
    디딘 발이 땅에서 미끄러져 보이므로, 머리를 칸 가운데 두어 그린 발 움직임을 그대로 살린다."""
    a = f.getchannel("A").load()
    xs = [x for y in range(int(f.height * 0.3)) for x in range(f.width) if a[x, y] > 40]
    return sum(xs) / len(xs) if xs else f.width / 2


def head_w(f):
    """위 18%에서 불투명한 가로 폭 — 머리 폭."""
    a = f.getchannel("A").crop((0, 0, f.width, max(1, int(f.height * 0.18)))).point(lambda v: 255 if v > 40 else 0)
    bb = a.getbbox()
    return bb[2] - bb[0] if bb else 1


def walk_head_widths(root):
    """같은 방향의 걷기 첫 장 머리 폭(공격 크기를 걷기에 맞추는 기준)."""
    path = root / f"assets/source/{CHAR}_walk_8dir.webp"
    if not path.exists():
        sys.exit("공격은 걷기 8방향 시트(odysseus_walk_8dir.webp)를 먼저 묶어 둬야 한다")
    src = Image.open(path).convert("RGB")
    out = {}
    for row, (d, flip) in enumerate(ROWS):
        if flip:
            continue
        cell = src.crop((0, row * CELL, CELL, (row + 1) * CELL)).convert("RGBA")
        px = cell.load()
        for y in range(cell.height):
            for x in range(cell.width):
                if is_bg(px[x, y]):
                    px[x, y] = (0, 0, 0, 0)
        out[d] = head_w(cell.crop(cell.getbbox()))
    return out


def main(root, anim, cols=4, rows=3, n=None):
    drawn, lift = {}, {}
    flight = anim in FLIGHT
    ref_head = walk_head_widths(root) if anim in HEAD_SCALE and not SRC_H else None
    n = n or cols * rows
    for d in DRAWN:
        fr = frames(load(root, anim, d), cols, rows)[:n]
        if SRC_H:
            k = CHAR_H / SRC_H
        elif ref_head:
            ws = sorted(head_w(f) for f, _ in fr)
            k = ref_head[d] / ws[len(ws) // 2]
        else:
            hs = sorted(f.height for f, _ in fr)
            k = CHAR_H / hs[len(hs) // 2]
        drawn[d] = [fit(f, k, 1.0 if flight or SRC_H else FIT_TOL) for f, _ in fr]
        base = max(b for _, b in fr)
        lift[d] = [round((base - b) * k) if flight else 0 for _, b in fr]
    sheet = Image.new("RGB", (CELL * n, CELL * len(ROWS)), MAGENTA)
    for row, (d, flip) in enumerate(ROWS):
        for i, f in enumerate(drawn[d]):
            if flip:
                f = f.transpose(Image.FLIP_LEFT_RIGHT)
            sheet.paste(f, (i * CELL + CELL // 2 - round(head_cx(f)), row * CELL + BASE_Y - lift[d][i] - f.height), f)
    out = root / f"assets/source/{CHAR}_{anim}_8dir.webp"
    sheet.save(out, lossless=True)
    print(out.relative_to(root), sheet.size)


if __name__ == "__main__":
    a = sys.argv[1:]
    main(Path(a[0]), a[1], *(int(v) for v in a[2:5]))
