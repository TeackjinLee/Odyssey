#!/usr/bin/env python3
"""그려 받은 8방향 캐릭터 그림(마젠타 배경, 한 장에 4×2) → 게임용 스프라이트 시트.

원본 칸 순서(odysseus_8dir): 윗줄 북·북동·동·남동 /아랫줄 남·남서·서·북서.
포즈가 하나뿐이라 동작은 그 포즈를 기울이고(전단)·눌렀다 펴고·회전해서 만든다.
무기는 그리지 않는다 — 게임이 손 위치(.json의 hands)에 무기 그림을 따로 겹쳐 그린다.

출력(assets/sprites/): <이름>.png + .json (gen_characters.py와 같은 시트 규칙 + scale·hands)
  hands[동작][프레임][방향] = [오른손 x, y, 왼손 x, y]  (프레임 안 픽셀 좌표)

사용: python3 gen_hero.py <godot 프로젝트 폴더> [옷 이름=odysseus]
  옷 이름이 odysseus_sea면 assets/source/odysseus_sea_8dir.webp(+있으면 _walk/_run/_attack…)를 읽어 assets/sprites/odysseus_sea.png/.json을 만든다.
  걷기·달리기·공격 그림이 없는 옷은 기본 8방향 한 장에서 움직임을 만든다(칼 쥔 손 위치만 HANDS_SRC를 쓴다).
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image

FRAME = 128
ANCHOR = (64, 120)
TARGET_H = 104          # 시트 안 캐릭터 키(px). 게임에서는 scale배로 그린다
DISPLAY_SCALE = 0.5     # 640×360 기준 화면에서 키 약 52px, 1280×720 창에서는 시트 픽셀 1:1

# 원본 칸(줄, 열) → 게임 방향 (0 동 1 남동 2 남 3 남서 4 서 5 북서 6 북 7 북동)
CELL_DIR = {(0, 0): 6, (0, 1): 7, (0, 2): 0, (0, 3): 1, (1, 0): 2, (1, 1): 3, (1, 2): 4, (1, 3): 5}

# 원본 칸 안에서 오른손·왼손 주먹 중심 (원본 픽셀, 칸 왼쪽 위 기준). 손을 찾아 눈으로 찍은 값
HANDS_SRC = {
    6: (305, 310, 108, 310), 7: (276, 318, 113, 310), 0: (167, 328, 195, 312), 1: (88, 318, 280, 318),
    2: (100, 288, 312, 288), 3: (98, 283, 271, 293), 4: (158, 284, 182, 296), 5: (268, 283, 78, 293),
}

ANIMS = [
    ("idle", 4, 5, True), ("walk", 12, 18, True), ("run", 12, 26, True),
    ("attack1", 4, 16, False), ("attack2", 4, 16, False), ("attack3", 5, 14, False), ("heavy", 6, 12, False),
    ("block", 2, 6, True), ("bow", 4, 10, False), ("hit", 2, 10, False), ("dodge", 4, 14, False),
    ("death", 5, 9, False), ("interact", 4, 8, True), ("downed", 1, 1, True),
]


def is_bg(c):
    r, g, b = c[:3]
    return r > 150 and b > 150 and g < 120 and abs(r - b) < 70


def cut_cells(src):
    """칸마다 배경을 지운 원본 크기 RGBA와 발 기준점(원본 좌표)."""
    W, H = src.size
    cw, ch = W // 4, H // 2
    out = {}
    for (row, col), d in CELL_DIR.items():
        cell = src.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch)).convert("RGBA")
        px = cell.load()
        for y in range(ch):
            for x in range(cw):
                if is_bg(px[x, y]):
                    px[x, y] = (0, 0, 0, 0)
        bb = cell.getbbox()
        feet = cell.crop((0, bb[3] - int((bb[3] - bb[1]) * 0.12), cw, bb[3])).getbbox()
        foot_x = (feet[0] + feet[2]) / 2
        out[d] = (cell, (foot_x, bb[3]), bb[3] - bb[1])
    return out


# 장비 겹치기: 옷 이름 → (몸 시트 이름, [(장비 이름, 방식), ...]). 장비 그림 assets/source/odysseus_<장비>_gear.webp는 기본 8방향 시트(odysseus_8dir)와
# 같은 칸 배치에서 그 장비만 마젠타 위에 그린 것. 머리를 찾아 프레임마다 머리 위치·폭에 맞춰 붙인다(걷기·달리기·공격 줄에도 같은 방식)
#  방식 "over" = 몸 위에(투구), "cape" = 북·북동·북서에서만 몸 위, 나머지 방향은 몸 뒤(망토·두건). 앞에서부터 차례로 쌓는다
GEAR = {
    "odysseus_helm": ("odysseus", [("helm", "over")]),
    "odysseus_king": ("odysseus", [("cape", "cape"), ("helm", "over")]),
    "odysseus_beggar_hood": ("odysseus_beggar", [("hood", "cape")]),
}
GEAR_CUT = 0.172   # 투구: 앞쪽 방향은 앞 테두리를 머리 맨 위에서 키의 이만큼 아래까지만 남겨 눈·수염이 가려지지 않게
GEAR_CUT_ARC = 0.008   # 자른 선을 가운데가 처지는 호로(키 비율) — 직선이 티 나지 않게
CUT_GEARS = ("helm",)
GEAR_TINT = {"hood": (1.08, 0.94, 0.74)}   # 받은 두건이 보랏빛이라 갈색 쪽으로
BACK_DIRS = (5, 6, 7)


def head_box(cell):
    bb = cell.getbbox()
    head = cell.crop((0, bb[1], cell.width, bb[1] + int((bb[3] - bb[1]) * 0.15))).getbbox()
    return bb, head


def load_gear(root, gear, body):
    """방향 → (장비 RGBA, 기준 머리 가운데 x, 기준 머리 위 y, 기준 머리 폭)."""
    src = Image.open(root / f"assets/source/odysseus_{gear}_gear.webp").convert("RGB")
    base = cut_cells(Image.open(root / f"assets/source/{body}_8dir.webp").convert("RGB"))
    cells = cut_cells(src)
    out = {}
    for d, (cell, _, _) in cells.items():
        if gear in GEAR_TINT:
            t = GEAR_TINT[gear]
            cell.putdata([(min(255, int(r * t[0])), min(255, int(g * t[1])), min(255, int(b * t[2])), a) for r, g, b, a in cell.getdata()])
        height = base[d][2]
        bb, head = head_box(base[d][0])
        hx = (head[0] + head[2]) / 2
        if gear in CUT_GEARS and d not in BACK_DIRS:
            hw = head[2] - head[0]
            for x in range(cell.width):
                t = max(0.0, 1 - ((x - hx) / (hw * 0.5)) ** 2)
                y0 = bb[1] + int((GEAR_CUT + GEAR_CUT_ARC * t) * height)
                for y in range(y0, cell.height):
                    cell.putpixel((x, y), (0, 0, 0, 0))
        out[d] = (cell, hx, bb[1], head[2] - head[0])
    return out


def put_gears(cell, d, gears):
    """cell 위에 장비들을 그 칸의 머리 위치·폭에 맞춰 얹은(또는 몸 뒤에 깐) 새 그림. gears = [(장비 dict, 방식)]."""
    bb, head = head_box(cell)
    hx = (head[0] + head[2]) / 2
    out = cell.copy()
    for g, mode in gears:
        img, hx0, top0, hw0 = g[d]
        s = (head[2] - head[0]) / hw0
        sized = img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)
        layer = Image.new("RGBA", cell.size, (0, 0, 0, 0))
        layer.paste(sized, (round(hx - hx0 * s), round(bb[1] - top0 * s)))
        if mode == "cape" and d not in BACK_DIRS:
            layer.alpha_composite(out)
            out = layer
        else:
            out.alpha_composite(layer)
    return out


def to_pose(cell, foot, height, k=None):
    """원본 칸 → FRAME 크기 포즈 (발이 ANCHOR). 축소 배율도 돌려준다."""
    k = k or TARGET_H / height
    w, h = cell.size
    small = cell.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)
    px = small.load()
    for y in range(small.height):
        for x in range(small.width):
            r, g, b, a = px[x, y]
            if a < 140:
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = (min(255, round(r * 255 / a)), min(255, round(g * 255 / a)), min(255, round(b * 255 / a)), 255) if a < 255 else (r, g, b, 255)
                if r > g + 70 and b > g + 70:  # 남은 마젠타 테두리
                    px[x, y] = (40, 20, 20, 255)
    frame = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    ox, oy = round(ANCHOR[0] - foot[0] * k), round(ANCHOR[1] - foot[1] * k)
    frame.paste(small, (ox, oy), small)
    return frame, k, (ox, oy)


# ── 그려 받은 동작 줄(8방향 한 장) ─────────────────────
# odysseus_<동작>_8dir.webp: 마젠타 배경, 열 = 프레임 × 8줄(방향 남→남동→동→북동→북→북서→서→남서)
# 걷기 18fps = 한 주기(두 걸음) 0.67초 — 옆모습 보폭(한 걸음 약 24px) × 2 ÷ 걷는 속도 72와 맞춰 발이 미끄러지지 않게
STRIP_ROWS = [2, 1, 0, 7, 6, 5, 4, 3]
# 첫 프레임의 오른손·왼손 주먹 중심(받은 그림의 칸 안 픽셀). 가려진 손은 몸 쪽으로 어림
STRIP_HANDS = {
    "walk": {2: (77, 157, 177, 155), 1: (85, 165, 180, 152), 0: (84, 157, 169, 145), 7: (167, 152, 84, 148),
             6: (174, 138, 81, 157)},
    "run": {2: (77, 135, 155, 118), 1: (87, 140, 168, 105), 0: (107, 155, 168, 110), 7: (172, 83, 83, 130),
            6: (170, 83, 70, 137)},
}
# 좌우를 뒤집어 만든 줄(pack_strip.py): 방향 → 뒤집은 원래 방향. 손은 원래 줄의 손을 뒤집고 오른손·왼손을 바꾼다
_MIRROR = {5: 7, 4: 0, 3: 1}
STRIP_MIRROR = {a: _MIRROR for a in ("walk", "run", "attack1", "attack2", "attack3", "heavy")}
STRIP_SWING = {"walk": 3.0, "run": 3.5}   # 팔 흔들림(원본 픽셀): 손 위치를 한 주기 동안 앞뒤로
# 보이는 주먹은 첫 프레임에서부터 프레임마다 그림 조각을 맞춰 따라간다: 방향 → (오른손, 왼손)
STRIP_TRACK = {"walk": {d: (True, True) for d in range(8)}, "run": {d: (True, True) for d in range(8)}}
TRACK_R, TRACK_SEARCH = 5, 7   # 맞출 조각 반지름, 다음 프레임에서 찾는 범위(원본 픽셀)


def track_hand(cells, start):
    """칸들(같은 방향, 프레임 순)에서 start 점의 그림 조각을 앞 프레임 → 다음 프레임으로 따라간 위치들."""
    import numpy as np
    arr = [np.asarray(c, dtype=float) for c in cells]
    pts = [start]
    r = TRACK_R
    for i in range(1, len(arr)):
        x, y = (round(v) for v in pts[-1])
        a, b = arr[i - 1], arr[i]
        tpl = a[y - r:y + r + 1, x - r:x + r + 1]
        best, bp = None, (x, y)
        for dy in range(-TRACK_SEARCH, TRACK_SEARCH + 1):
            for dx in range(-TRACK_SEARCH, TRACK_SEARCH + 1):
                cx, cy = x + dx, y + dy
                win = b[cy - r:cy + r + 1, cx - r:cx + r + 1]
                if win.shape != tpl.shape:
                    continue
                err = np.abs(win - tpl).mean() + 0.4 * (dx * dx + dy * dy) ** 0.5
                if best is None or err < best:
                    best, bp = err, (cx, cy)
        pts.append(bp)
    return pts

def track_loop(cells, start):
    """돌아가는 동작(걷기·달리기)용: 앞으로만 따라가면 뒤쪽 장면으로 갈수록 한 장씩 어긋남이 쌓이므로,
    마지막 장이 첫 장으로 이어지는 것을 이용해 첫 장에서 거꾸로도 따라가고, 두 결과를 첫 장에서 가까운 쪽에 무게를 둬 섞는다."""
    n = len(cells)
    fwd = track_hand(cells, start)
    back = track_hand([cells[0]] + cells[:0:-1], start)   # 첫 장, 마지막 장, ..., 둘째 장 순서
    out = [fwd[0]]
    for i in range(1, n):
        b = back[n - i]
        w = i / n   # 첫 장에서 멀수록 거꾸로 따라간 쪽을 믿는다
        out.append(((1 - w) * fwd[i][0] + w * b[0], (1 - w) * fwd[i][1] + w * b[1]))
    return out


# 공격 줄: 프레임마다 검을 쥔 주먹(휘두르는 손) 위치, 방패 손은 방향마다 하나 (받은 그림의 칸 안 픽셀, 칸 256).
# 방향 2 S · 1 SE · 0 E · 7 NE · 6 N 다섯 방향만 그려 받고, 나머지 셋(3 4 5)은 STRIP_MIRROR로 좌우를 뒤집어 만든다.
# 그려 받은 그림이 방향마다 다른 손으로 칠 때가 있어 '오른손'이 아니라 '치는 주먹'을 따라간다 (격자를 얹어 눈으로 찍은 값)
ATTACK_HANDS = {
    "attack1": {
        2: [(62, 138), (82, 112), (172, 105), (102, 132)], 1: [(68, 149), (108, 123), (180, 122), (137, 134)],
        0: [(85, 143), (169, 98), (188, 108), (162, 92)], 7: [(150, 100), (184, 115), (193, 105), (167, 128)],
        6: [(183, 152), (174, 99), (70, 109), (172, 119)],
    },
    "attack2": {
        2: [(120, 165), (89, 120), (43, 105), (112, 150)], 1: [(130, 162), (104, 109), (50, 99), (117, 139)],
        0: [(155, 163), (164, 108), (68, 98), (117, 143)], 7: [(163, 165), (189, 155), (193, 127), (172, 150)],
        6: [(175, 190), (179, 141), (193, 126), (167, 161)],
    },
    "attack3": {
        2: [(85, 82), (94, 45), (80, 125), (102, 140), (86, 150)], 1: [(85, 74), (94, 29), (150, 112), (172, 129), (166, 120)],
        0: [(95, 83), (104, 38), (168, 123), (142, 138), (166, 123)], 7: [(170, 57), (159, 22), (178, 137), (172, 167), (166, 137)],
        6: [(170, 56), (154, 26), (188, 108), (182, 161), (191, 101)],
    },
    "heavy": {
        2: [(75, 145), (79, 140), (58, 98), (57, 92), (125, 102), (120, 150)],
        1: [(45, 129), (49, 139), (58, 66), (57, 69), (100, 118), (100, 110)],
        0: [(45, 148), (49, 153), (53, 86), (207, 73), (186, 88), (170, 113)],
        7: [(65, 147), (84, 148), (53, 92), (74, 67), (176, 62), (190, 117)],
        6: [(85, 205), (179, 161), (198, 121), (181, 97), (171, 96), (195, 116)],
    },
}
ATTACK_LEFT = {
    "attack1": {2: (155, 105), 1: (150, 110), 0: (125, 110), 7: (120, 110), 6: (100, 105)},
    "attack2": {2: (172, 130), 1: (170, 130), 0: (165, 150), 7: (120, 150), 6: (90, 160)},
    "attack3": {2: (170, 128), 1: (140, 110), 0: (150, 115), 7: (110, 110), 6: (90, 110)},
    "heavy": {2: (160, 115), 1: (150, 110), 0: (165, 125), 7: (120, 125), 6: (100, 130)},
}

SHOULDER_AT = 0.40   # 칼끝 각도를 잴 때 어깨 높이(키 비율)

# 그림이 어색한 방향은 다른 방향 줄을 가져다 쓴다: 방향 → (가져올 방향, 좌우 뒤집기)
STRIP_REUSE = {}


def strip_hand0(anim, d, cw):
    """첫 프레임 손 위치. 뒤집어 만든 줄은 원래 줄의 손을 칸 폭 cw 기준으로 뒤집고 좌우를 바꾼다."""
    src = STRIP_MIRROR.get(anim, {}).get(d)
    if src is None:
        return STRIP_HANDS[anim][d]
    rx, ry, lx, ly = STRIP_HANDS[anim][src]
    return (cw - lx, ly, cw - rx, ry)


def head_width(cells, cols):
    """첫 프레임들의 머리 폭(가운데값) — 받은 그림마다 다른 캐릭터 크기를 걷기에 맞추는 기준."""
    ws = []
    for d in range(8):
        c = cells[d, 0]
        bb = c.getbbox()
        top = c.crop((0, bb[1], c.width, bb[1] + int((bb[3] - bb[1]) * 0.18))).getbbox()
        ws.append(top[2] - top[0])
    return sorted(ws)[len(ws) // 2]


def strip_frames(root, anim, k=None, cols=6, ref=None, name="odysseus", gear=None):
    """그려 받은 동작 줄 → {방향: [(FRAME 그림, [손 4값]), ...]}, 배율, 머리 폭. 없으면 None.
    가로 위치는 머리 중심, 세로는 그 줄에서 가장 낮은 발을 ANCHOR에 맞춘다(뛸 때 뜨는 높이는 그대로).
    ref = (걷기 배율, 걷기 머리 폭)을 주면 머리 폭 비율로 배율을 맞춘다(공격 그림)."""
    path = root / f"assets/source/{name}_{anim}_8dir.webp"
    if not path.exists():
        return None, k, None
    src = Image.open(path).convert("RGB")
    cw, ch = src.width / cols, src.height / 8
    cells = {}
    for row, d in enumerate(STRIP_ROWS):
        for col in range(cols):
            cell = src.crop((round(col * cw), round(row * ch), round((col + 1) * cw), round((row + 1) * ch))).convert("RGBA")
            px = cell.load()
            for y in range(cell.height):
                for x in range(cell.width):
                    if is_bg(px[x, y]):
                        px[x, y] = (0, 0, 0, 0)
            cells[d, col] = cell
    head_w = head_width(cells, cols)
    if ref is not None:
        k = ref[0] * ref[1] / head_w
    elif k is None:
        hs = sorted(c.getbbox()[3] - c.getbbox()[1] for c in cells.values())
        k = TARGET_H / hs[len(hs) // 2]
    if gear:
        for (d, col), c in list(cells.items()):
            cells[d, col] = put_gears(c, d, gear)
    out = {}
    for d in range(8):
        base = max(cells[d, c].getbbox()[3] for c in range(cols))
        fx, fy = math.cos(math.radians(d * 45)), math.sin(math.radians(d * 45)) * 0.5
        frames = []
        tracked = [None, None]
        if anim in STRIP_TRACK:
            h0 = strip_hand0(anim, d, cw)
            row = [cells[d, c] for c in range(cols)]
            for j, on in enumerate(STRIP_TRACK[anim][d]):
                if on:
                    tracked[j] = track_loop(row, (h0[2 * j], h0[2 * j + 1]))
        for col in range(cols):
            cell = cells[d, col]
            bb = cell.getbbox()
            head = cell.crop((0, bb[1], cell.width, bb[1] + int((bb[3] - bb[1]) * 0.15))).getbbox()
            hx = (head[0] + head[2]) / 2
            if col == 0:
                hx0, top0 = hx, bb[1]
            frame, _, (ox, oy) = to_pose(cell, (hx, base), 0, k)
            if anim in ATTACK_HANDS:
                src_d = STRIP_MIRROR.get(anim, {}).get(d)
                if src_d is None:
                    r, l = ATTACK_HANDS[anim][d][col], ATTACK_LEFT[anim][d]
                else:   # 뒤집어 만든 줄: 원래 줄의 칠 주먹·방패 손을 칸 폭 기준으로 뒤집는다
                    (rx, ry), (lx, ly) = ATTACK_HANDS[anim][src_d][col], ATTACK_LEFT[anim][src_d]
                    r, l = (cw - rx, ry), (cw - lx, ly)
                # 방패 손은 첫 장 위치를 몸(머리)이 움직인 만큼 따라 옮긴다: 내딛고 웅크릴 때 방패가 몸에서 떨어지지 않게
                l = (l[0] + (hx - hx0), l[1] + (bb[1] - top0))
            else:
                h0 = strip_hand0(anim, d, cw)
                sw = STRIP_SWING[anim] * (math.cos(2 * math.pi * col / cols) - 1)
                r = tracked[0][col] if tracked[0] else (h0[0] + (hx - hx0) + fx * sw, h0[1] + fy * sw)
                l = tracked[1][col] if tracked[1] else (h0[2] + (hx - hx0) - fx * sw, h0[3] - fy * sw)
            hands = [round(r[0] * k + ox, 1), round(r[1] * k + oy, 1), round(l[0] * k + ox, 1), round(l[1] * k + oy, 1)]
            if anim in ATTACK_HANDS:
                # 칼끝 각도(도, 화면 좌표): 어깨 → 치는 주먹 방향. 어깨는 머리 가운데 x, 키의 40% 높이로 잡는다
                sx, sy = hx, bb[1] + SHOULDER_AT * (bb[3] - bb[1])
                hands.append(round(math.degrees(math.atan2(r[1] - sy, r[0] - sx)), 1))
            frames.append((frame, hands))
        out[d] = frames
    for d, (src_d, flip) in STRIP_REUSE.get(anim, {}).items():
        out[d] = [(f.transpose(Image.FLIP_LEFT_RIGHT), [FRAME - h[0], h[1], FRAME - h[2], h[3]]) if flip else (f, h)
                  for f, h in out[src_d]]
    return out, k, head_w


# ── 동작 = 포즈 변형 ──────────────────────────────────
def params(anim, i, n, d):
    """프레임 변형: dx, dy, sx, sy, shear(위로 갈수록 바라보는 쪽으로), rot(도, 발 기준)."""
    fx = math.cos(math.radians(d * 45))
    fy = math.sin(math.radians(d * 45))
    u = i / n
    s = math.sin(2 * math.pi * u)
    p = dict(dx=0.0, dy=0.0, sx=1.0, sy=1.0, sh=0.0, rot=0.0)
    if anim == "idle":
        p["sy"] = 1 + 0.012 * s
    elif anim in ("walk", "run"):
        run = anim == "run"
        p["dy"] = -(2.0 if run else 1.0) * abs(math.sin(2 * math.pi * u))
        p["sh"] = (0.09 if run else 0.03) * fx + 0.02 * math.sin(2 * math.pi * u) * fx
        p["sy"] = (0.97 if run else 1.0) + 0.015 * abs(s)
        p["dy"] += (1.5 if run else 0.0) * -fy * 0.3
    elif anim in ("attack1", "attack2", "attack3", "heavy"):
        seq = {
            "attack1": [(-0.05, 0, 1.0), (0.10, 3, 0.98), (0.12, 4, 0.98), (0.05, 2, 1.0)],
            "attack2": [(-0.04, 0, 1.0), (0.09, 3, 0.98), (0.11, 4, 0.98), (0.04, 2, 1.0)],
            "attack3": [(-0.08, -1, 1.02), (-0.10, -1, 1.03), (0.10, 3, 0.96), (0.16, 6, 0.92), (0.10, 4, 0.95)],
            "heavy": [(-0.06, 0, 0.92), (-0.09, -1, 0.9), (0.12, 4, 0.95), (0.16, 6, 0.94), (0.14, 5, 0.95), (0.05, 3, 1.0)],
        }[anim][min(i, n - 1)]
        p["sh"], lunge, p["sy"] = seq[0] * fx, seq[1], seq[2]
        p["dx"], p["dy"] = lunge * fx, lunge * fy * 0.5
    elif anim == "block":
        p["sy"] = 0.96
        p["sh"] = 0.05 * fx
    elif anim == "bow":
        p["sh"] = [-0.02, -0.04, -0.05, 0.03][i] * fx
    elif anim == "hit":
        p["sh"] = (-0.12 if i == 0 else -0.06) * fx
        p["dx"] = (-3 if i == 0 else -1.5) * fx
        p["dy"] = (-3 if i == 0 else -1.5) * fy * 0.5
    elif anim == "dodge":
        sy, sh, mv = [(0.82, 0.22, 3), (0.7, 0.3, 6), (0.78, 0.2, 8), (0.95, 0.06, 9)][i]
        p["sy"], p["sx"], p["sh"] = sy, 1 + (1 - sy) * 0.4, sh * fx
        p["dx"], p["dy"] = mv * fx, mv * fy * 0.5
    elif anim in ("death", "downed"):
        side = -1 if fx > 0.2 else 1
        p["piv"] = 40.0
        if anim == "downed":
            p["rot"], p["dy"] = 82 * side, 18
        else:
            k = [0.08, 0.3, 0.6, 0.92, 1.0][i]
            p["rot"] = 86 * k * side
            p["sy"] = [0.98, 0.94, 0.95, 1.0, 1.0][i]
            p["dy"] = 21 * k * k
    elif anim == "interact":
        p["sy"] = 0.97 + 0.02 * s
        p["sh"] = 0.06 * fx
    return p


def affine(p):
    """포즈 좌표 → 프레임 좌표 함수(손 위치용)와 PIL용 역변환 계수.
    순서: 발 기준 크기 → 전단 → (골반 높이 piv 기준) 회전 → 이동."""
    ax, ay = ANCHOR
    c, s = math.cos(math.radians(p["rot"])), math.sin(math.radians(p["rot"]))
    piv = p.get("piv", 0.0)

    def fwd(x, y):
        x0, y0 = (x - ax) * p["sx"], (y - ay) * p["sy"]
        x0 = x0 - p["sh"] * y0
        y0 += piv
        x1, y1 = x0 * c - y0 * s, x0 * s + y0 * c
        return x1 + ax + p["dx"], y1 - piv + ay + p["dy"]

    o = fwd(0, 0)
    ex = fwd(1, 0)
    ey = fwd(0, 1)
    m00, m10 = ex[0] - o[0], ex[1] - o[1]
    m01, m11 = ey[0] - o[0], ey[1] - o[1]
    det = m00 * m11 - m01 * m10
    i00, i01, i10, i11 = m11 / det, -m01 / det, -m10 / det, m00 / det
    coeffs = (i00, i01, -(i00 * o[0] + i01 * o[1]), i10, i11, -(i10 * o[0] + i11 * o[1]))
    return fwd, coeffs


def build(root, name="odysseus"):
    body, gnames = GEAR.get(name, (name, []))
    src = Image.open(root / f"assets/source/{body}_8dir.webp").convert("RGB")
    cells = cut_cells(src)
    gear = [(load_gear(root, g, body), mode) for g, mode in gnames]
    if gear:
        cells = {d: (put_gears(c, d, gear), foot, h) for d, (c, foot, h) in cells.items()}
    poses, hands0 = {}, {}
    for d, (cell, foot, height) in cells.items():
        pose, k, (ox, oy) = to_pose(cell, foot, height)
        poses[d] = pose
        if d in HANDS_SRC:
            rx, ry, lx, ly = HANDS_SRC[d]
            hands0[d] = [rx * k + ox, ry * k + oy, lx * k + ox, ly * k + oy]
        else:
            hands0[d] = [ANCHOR[0], ANCHOR[1] - 50, ANCHOR[0], ANCHOR[1] - 50]
    strips = {}
    k = None
    n_frames = {a[0]: a[1] for a in ANIMS}
    strips["walk"], k, walk_head = strip_frames(root, "walk", cols=n_frames["walk"], name=body, gear=gear)
    strips["run"], _, _ = strip_frames(root, "run", cols=n_frames["run"], ref=(k, walk_head), name=body, gear=gear)
    for anim in ATTACK_HANDS:
        if strips["walk"]:
            strips[anim], _, _ = strip_frames(root, anim, cols=n_frames[anim], ref=(k, walk_head), name=body, gear=gear)
    total = sum(a[1] for a in ANIMS)
    sheet = Image.new("RGBA", (FRAME * total, FRAME * 8), (0, 0, 0, 0))
    meta = {"frame": [FRAME, FRAME], "anchor": list(ANCHOR), "dirs": 8, "scale": DISPLAY_SCALE, "anims": {}, "hands": {},
            "drawn": [a for a, s in strips.items() if s]}
    col = 0
    for anim, n, fps, loop in ANIMS:
        meta["anims"][anim] = {"start": col, "frames": n, "fps": fps, "loop": loop}
        meta["hands"][anim] = []
        for i in range(n):
            row_hands = []
            for d in range(8):
                if strips.get(anim):
                    img, h = strips[anim][d][i]
                    sheet.paste(img, (FRAME * (col + i), FRAME * d), img)
                    row_hands.append(h)
                    continue
                p = params(anim, i, n, d)
                fwd, coeffs = affine(p)
                img = poses[d].transform((FRAME, FRAME), Image.AFFINE, coeffs, resample=Image.NEAREST)
                sheet.paste(img, (FRAME * (col + i), FRAME * d), img)
                h = hands0[d]
                r = fwd(h[0], h[1])
                l = fwd(h[2], h[3])
                row_hands.append([round(r[0], 1), round(r[1], 1), round(l[0], 1), round(l[1], 1)])
            meta["hands"][anim].append(row_hands)
        col += n
    out = root / "assets/sprites"
    sheet.save(out / f"{name}.png")
    (out / f"{name}.json").write_text(json.dumps(meta, ensure_ascii=False))
    if name == "odysseus" and (root / PORTRAIT_SRC).exists():
        make_portrait(root)
    else:
        # 초상화: 남쪽 포즈 머리
        cell, foot, height = cells[2]
        bb = cell.getbbox()
        head_w = int(height * 0.36)
        cx = (bb[0] + bb[2]) // 2
        crop = cell.crop((cx - head_w // 2, bb[1] - 4, cx + head_w // 2, bb[1] - 4 + head_w))
        crop.resize((40, 40), Image.LANCZOS).save(root / f"assets/ui/portrait_{name}.png")
    return poses


# 그려 받은 오디세우스 일러스트(흰 배경)에서 얼굴만 잘라 초상화로 쓴다
PORTRAIT_SRC = "assets/source/odysseus_portrait.jpg"
PORTRAIT_BOX = (345, 180, 585, 420)   # 원본 픽셀, 정사각형
PORTRAIT_SIZE = 80                    # HUD는 40×40 칸 — 1280×720 창에서 1:1


def make_portrait(root):
    crop = Image.open(root / PORTRAIT_SRC).convert("RGBA").crop(PORTRAIT_BOX)
    w, h = crop.size
    px = crop.load()
    # 테두리에서 이어진 흰 바탕만 투명하게 (얼굴 안의 밝은 부분은 남김)
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for x in (0, w - 1) for y in range(h)]
    seen = set()
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        r, g, b, _ = px[x, y]
        if min(r, g, b) < 225:
            continue
        px[x, y] = (0, 0, 0, 0)
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    crop.resize((PORTRAIT_SIZE, PORTRAIT_SIZE), Image.LANCZOS).save(root / "assets/ui/portrait_odysseus.png")


if __name__ == "__main__":
    outfit = sys.argv[2] if len(sys.argv) > 2 else "odysseus"
    build(Path(sys.argv[1]), outfit)
    print(f"{outfit} 시트 생성")
