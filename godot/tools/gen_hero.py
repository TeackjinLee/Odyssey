#!/usr/bin/env python3
"""그려 받은 8방향 캐릭터 그림(마젠타 배경, 한 장에 4×2) → 게임용 스프라이트 시트.

원본 칸 순서(odysseus_8dir): 윗줄 북·북동·동·남동 /아랫줄 남·남서·서·북서.
포즈가 하나뿐이라 동작은 그 포즈를 기울이고(전단)·눌렀다 펴고·회전해서 만든다.
무기는 그리지 않는다 — 게임이 손 위치(.json의 hands)에 무기 그림을 따로 겹쳐 그린다.

출력(assets/sprites/): <이름>.png + .json (gen_characters.py와 같은 시트 규칙 + scale·hands)
  hands[동작][프레임][방향] = [오른손 x, y, 왼손 x, y]  (프레임 안 픽셀 좌표)

사용: python3 gen_hero.py <godot 프로젝트 폴더>
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
    6: (300, 312, 112, 312), 7: (256, 322, 130, 300), 0: (187, 332, 215, 315), 1: (125, 305, 250, 275),
    2: (120, 286, 290, 286), 3: (121, 282, 251, 292), 4: (150, 305, 172, 322), 5: (250, 290, 110, 288),
}

ANIMS = [
    ("idle", 4, 5, True), ("walk", 6, 10, True), ("run", 6, 13, True),
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
# odysseus_<동작>_8dir.webp: 마젠타 배경, 6열(프레임) × 8줄(방향 남→남동→동→북동→북→북서→서→남서)
STRIP_ROWS = [2, 1, 0, 7, 6, 5, 4, 3]
# 첫 프레임의 오른손·왼손 주먹 중심(받은 그림의 칸 안 픽셀). 가려진 손은 몸 쪽으로 어림
STRIP_HANDS = {
    "walk": {2: (40, 143, 120, 143), 1: (56, 143, 116, 132), 0: (93, 147, 88, 140), 7: (106, 147, 80, 135),
             6: (123, 142, 32, 146), 5: (70, 135, 45, 144), 4: (60, 132, 56, 139), 3: (42, 129, 114, 151)},
    "run": {2: (60, 123, 118, 125), 1: (60, 130, 126, 107), 0: (114, 115, 79, 137), 7: (119, 128, 95, 120),
            6: (123, 112, 33, 112), 5: (50, 105, 26, 112), 4: (50, 132, 34, 122), 3: (31, 117, 77, 129)},
}
STRIP_SWING = {"walk": 3.0, "run": 6.0}   # 팔 흔들림(원본 픽셀): 손 위치를 프레임마다 앞뒤로


def strip_frames(root, anim, k=None):
    """그려 받은 동작 줄 → {방향: [(FRAME 그림, [손 4값]), ...]}, 배율. 없으면 None.
    가로 위치는 머리 중심, 세로는 그 줄에서 가장 낮은 발을 ANCHOR에 맞춘다(뛸 때 뜨는 높이는 그대로)."""
    path = root / f"assets/source/odysseus_{anim}_8dir.webp"
    if not path.exists():
        return None, k
    src = Image.open(path).convert("RGB")
    cw, ch = src.width / 6, src.height / 8
    cells = {}
    for row, d in enumerate(STRIP_ROWS):
        for col in range(6):
            cell = src.crop((round(col * cw), round(row * ch), round((col + 1) * cw), round((row + 1) * ch))).convert("RGBA")
            px = cell.load()
            for y in range(cell.height):
                for x in range(cell.width):
                    if is_bg(px[x, y]):
                        px[x, y] = (0, 0, 0, 0)
            cells[d, col] = cell
    if k is None:
        hs = sorted(c.getbbox()[3] - c.getbbox()[1] for c in cells.values())
        k = TARGET_H / hs[len(hs) // 2]
    out = {}
    for d in range(8):
        base = max(cells[d, c].getbbox()[3] for c in range(6))
        fx, fy = math.cos(math.radians(d * 45)), math.sin(math.radians(d * 45)) * 0.5
        h0 = STRIP_HANDS[anim][d]
        frames = []
        for col in range(6):
            cell = cells[d, col]
            bb = cell.getbbox()
            head = cell.crop((0, bb[1], cell.width, bb[1] + int((bb[3] - bb[1]) * 0.15))).getbbox()
            hx = (head[0] + head[2]) / 2
            if col == 0:
                hx0 = hx
            frame, _, (ox, oy) = to_pose(cell, (hx, base), 0, k)
            sw = STRIP_SWING[anim] * (math.cos(2 * math.pi * col / 6) - 1)
            r = (h0[0] + (hx - hx0) + fx * sw, h0[1] + fy * sw)
            l = (h0[2] + (hx - hx0) - fx * sw, h0[3] - fy * sw)
            hands = [round(r[0] * k + ox, 1), round(r[1] * k + oy, 1), round(l[0] * k + ox, 1), round(l[1] * k + oy, 1)]
            frames.append((frame, hands))
        out[d] = frames
    return out, k


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


def build(root):
    src = Image.open(root / "assets/source/odysseus_8dir.webp").convert("RGB")
    cells = cut_cells(src)
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
    for anim in ("walk", "run"):
        strips[anim], k = strip_frames(root, anim, k)
    total = sum(a[1] for a in ANIMS)
    sheet = Image.new("RGBA", (FRAME * total, FRAME * 8), (0, 0, 0, 0))
    meta = {"frame": [FRAME, FRAME], "anchor": list(ANCHOR), "dirs": 8, "scale": DISPLAY_SCALE, "anims": {}, "hands": {}}
    col = 0
    for anim, n, fps, loop in ANIMS:
        meta["anims"][anim] = {"start": col, "frames": n, "fps": fps, "loop": loop}
        meta["hands"][anim] = []
        for i in range(n):
            row_hands = []
            for d in range(8):
                if strips.get(anim):
                    img, h = strips[anim][d][i % 6]
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
    sheet.save(out / "odysseus.png")
    (out / "odysseus.json").write_text(json.dumps(meta, ensure_ascii=False))
    if (root / PORTRAIT_SRC).exists():
        make_portrait(root)
    else:
        # 초상화: 남쪽 포즈 머리
        cell, foot, height = cells[2]
        bb = cell.getbbox()
        head_w = int(height * 0.36)
        cx = (bb[0] + bb[2]) // 2
        crop = cell.crop((cx - head_w // 2, bb[1] - 4, cx + head_w // 2, bb[1] - 4 + head_w))
        crop.resize((40, 40), Image.LANCZOS).save(root / "assets/ui/portrait_odysseus.png")
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
    build(Path(sys.argv[1]))
    print("odysseus 시트 생성")
