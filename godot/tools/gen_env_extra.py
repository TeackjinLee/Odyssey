#!/usr/bin/env python3
"""챕터 1 맵 개편용 임시 환경 그림 (troy_city·troy_coast 그림을 받기 전까지 쓰는 생성기 그림).

gen_environment.py · gen_env_from_sheet.py 뒤에 돌린다. env.json에 항목을 더하고 floor_atlas.png에 바닥 줄을 붙인다.
여러 번 돌려도 같은 결과(이미 있는 줄·항목은 바꿔 쓴다).

    python3 tools/gen_environment.py . && python3 tools/gen_env_from_sheet.py . && python3 tools/gen_env_extra.py .

- 바닥: water(바다, 막힘) · sand(바위 해안) · planks(나무 부두)
- 소품: temple(3×3 아테나 신전) · steps(신전 계단) · lion(사자상) · fountain(2×2 분수) · stall_red/stall_white(차양 좌판)
        bell_tower(2×2 나무 종탑) · ladder(목마 사다리) · column_broken(부러진 기둥) · cypress · pine · pot(화분)
        rock · galley(5×2 갤리선) · boat(2×1 작은 배) · pier_post(부두 말뚝)
다시 그려 받은 그림(assets/source/troy_city.webp·troy_coast.webp)이 있으면 마지막에 gen_env_redraw.py가 잘라 같은 이름으로 덮어쓴다
(임시 그림의 기준점을 물려받으므로 이 스크립트를 먼저 돌려야 한다).
"""
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from gen_environment import (P, Sheet, col, h2, tex_brick, tex_flag, tex_plank, tex_plaster, tex_roof, tex_solid,  # noqa: E402
                             STONE, STONE_TOP, WOOD, WOOD_DARK)

MARBLE = (214, 206, 186)
MARBLE_TOP = (232, 226, 210)
TERRACOTTA = (168, 84, 52)
GREEN = (46, 78, 50)
GREEN_DARK = (30, 54, 38)

EXTRA_FLOORS = [("water", (34, 62, 104)), ("sand", (118, 108, 92)), ("planks", (120, 86, 54))]


# ── 바닥 ──────────────────────────────────────────────
def floor_rows(variants):
    rows = Image.new("RGBA", (64 * variants, 32 * len(EXTRA_FLOORS)), (0, 0, 0, 0))
    px = rows.load()
    for r, (kind, base) in enumerate(EXTRA_FLOORS):
        for v in range(variants):
            rnd = random.Random(r * 97 + v)
            stones = [(rnd.random(), rnd.random(), rnd.uniform(0.12, 0.24)) for _ in range(5)]
            for y in range(32):
                for x in range(64):
                    sx, sy = x - 32 + 0.5, y + 0.5
                    if abs(sx) / 33 + abs(sy - 16) / 16.5 > 1.0:
                        continue
                    gx = (sx / 32 + sy / 16) / 2
                    gy = (sy / 16 - sx / 32) / 2
                    if kind == "water":
                        # 가로로 긴 물결 줄(화면 기준)과 드문 반짝임
                        w = math.sin(x * 0.35 + y * 1.6 + v * 1.7) + math.sin(x * 0.11 - y * 0.9 + v)
                        k = 0.9 + 0.08 * w
                        c = col(base, k)
                        if w > 1.55:
                            c = col((92, 130, 170), 1.0)
                    elif kind == "sand":
                        k = 0.85 + 0.25 * h2(x // 3, y // 2, v)
                        c = col(base, k)
                        for a, b, s in stones:
                            d = math.hypot(gx - a, gy - b)
                            if d < s:
                                c = col((96, 92, 86), 1.25 - d / s * 0.5)
                    else:
                        # 부두 판자: gy 방향으로 놓인 판자(바다 쪽으로 뻗음)
                        row = int(gx * 6)
                        k = 0.86 + 0.2 * h2(row, v)
                        if (gx * 6) % 1 < 0.1:
                            k = 0.55
                        c = col(base, k * (0.95 + 0.08 * h2(x, y)))
                    px[v * 64 + x, r * 32 + y] = c
    return rows


def add_floors(out, meta):
    fa = meta["floor_atlas"]
    rows = [r for r in fa["rows"] if r not in dict(EXTRA_FLOORS)]
    variants = fa["variants"]
    atlas = Image.open(out / fa["file"]).convert("RGBA")
    base = atlas.crop((0, 0, 64 * variants, 32 * len(rows)))
    extra = floor_rows(variants)
    new = Image.new("RGBA", (64 * variants, 32 * (len(rows) + len(EXTRA_FLOORS))), (0, 0, 0, 0))
    new.paste(base, (0, 0))
    new.paste(extra, (0, 32 * len(rows)))
    new.save(out / fa["file"])
    fa["rows"] = rows + [k for k, _ in EXTRA_FLOORS]


# ── 소품 ──────────────────────────────────────────────
def column(sh, cx, cy, z0, h, r=0.16):
    sh.box(cx - r - 0.05, cy - r - 0.05, z0, 2 * r + 0.1, 2 * r + 0.1, 3, tex_flag(MARBLE_TOP), tex_plaster(MARBLE), tex_plaster(MARBLE))
    sh.cylinder(cx, cy, z0 + 3, r, h - 6, lambda a, v: MARBLE if int(a) % 4 else (176, 168, 150), lambda i, j: MARBLE_TOP + (255,))
    sh.box(cx - r - 0.05, cy - r - 0.05, z0 + h - 3, 2 * r + 0.1, 2 * r + 0.1, 3, tex_flag(MARBLE_TOP), tex_plaster(MARBLE), tex_plaster(MARBLE))


def make_temple(out, meta):
    sh = Sheet(620, 560, 300, 380)
    sh.box(0, 0, 0, 3, 3, 4, tex_flag(MARBLE_TOP), tex_brick(MARBLE), tex_brick(MARBLE))
    sh.box(0.15, 0.15, 4, 2.7, 2.7, 4, tex_flag(MARBLE_TOP), tex_brick(MARBLE), tex_brick(MARBLE))
    # 안쪽 방(어두운 문)
    sh.box(0.7, 0.7, 8, 1.6, 1.6, 50, None, tex_plaster((196, 186, 164)), lambda u, v: (40, 30, 26) if 18 < u < 40 and v < 32 else tex_plaster((196, 186, 164))(u, v))
    pts = [0.35, 1.0, 1.65, 2.3]
    back = [(x, 0.35) for x in pts] + [(0.35, y) for y in pts[1:]]
    front = [(2.65, y) for y in pts] + [(x, 2.65) for x in pts[:-1]]
    for cx, cy in sorted(back, key=lambda p: p[0] + p[1]):
        column(sh, cx, cy, 8, 52)
    for cx, cy in sorted(front, key=lambda p: p[0] + p[1]):
        column(sh, cx, cy, 8, 52)
    sh.box(0.1, 0.1, 60, 2.8, 2.8, 8, tex_flag(MARBLE_TOP), tex_plaster(MARBLE), lambda u, v: (150, 60, 44) if 2 < v < 6 else tex_plaster(MARBLE)(u, v))
    sh.roof(0.1, 0.1, 2.8, 2.8, 68, 20, False, tex_roof((176, 86, 54)), tex_plaster(MARBLE))
    sh.finish((1.5, 1.5, 0), [3, 3], "temple", out, meta)


def make_small(out, meta):
    sh = Sheet(160, 160, 80, 110)
    for i in range(3):
        sh.box(0.05, 0.05 + i * 0.3, 0, 0.9, 0.95 - i * 0.3, 9 - i * 3, tex_flag(MARBLE_TOP), tex_brick(MARBLE), tex_brick(MARBLE))
    sh.finish((0.5, 0.5, 0), [1, 1], "steps", out, meta)

    sh = Sheet(200, 220, 100, 160)
    sh.box(0.15, 0.15, 0, 0.7, 0.7, 14, tex_flag(MARBLE_TOP), tex_brick(MARBLE), tex_brick(MARBLE))
    gold = (196, 162, 92)
    sh.box(0.25, 0.3, 14, 0.5, 0.4, 10, tex_solid(gold), tex_solid(col(gold, 0.85)[:3]), tex_solid(col(gold, 0.75)[:3]))
    sh.box(0.6, 0.32, 22, 0.28, 0.36, 12, tex_solid(gold), tex_solid(col(gold, 0.85)[:3]), tex_solid(col(gold, 0.75)[:3]))
    sh.box(0.56, 0.28, 24, 0.12, 0.44, 12, tex_solid((150, 110, 60)), tex_solid((150, 110, 60)), tex_solid((130, 96, 54)))
    sh.finish((0.5, 0.5, 0), [1, 1], "lion", out, meta)

    sh = Sheet(240, 220, 120, 150)
    sh.cylinder(0.75, 0.6, 0, 0.18, 46, lambda a, v: MARBLE if int(a) % 4 else (176, 168, 150), lambda i, j: (110, 104, 96, 255))
    for x, y, s in ((0.25, 0.75, 0.3), (0.95, 0.25, 0.22), (0.4, 0.3, 0.18)):
        sh.box(x, y, 0, s, s, 6, tex_flag(MARBLE_TOP), tex_plaster(MARBLE), tex_plaster(MARBLE))
    sh.box(0.1, 0.45, 0, 0.6, 0.3, 9, tex_flag(MARBLE_TOP), tex_plaster(MARBLE), tex_plaster(MARBLE))
    sh.finish((0.5, 0.5, 0), [1, 1], "column_broken", out, meta)

    sh = Sheet(160, 160, 80, 110)
    sh.cylinder(0.5, 0.5, 0, 0.2, 12, lambda a, v: TERRACOTTA if int(v) != 9 else (130, 60, 38), lambda i, j: (60, 40, 28, 255))
    for i in range(12):
        a = i / 12 * math.tau
        sh.box(0.5 + 0.12 * math.cos(a) - 0.05, 0.5 + 0.12 * math.sin(a) - 0.05, 12, 0.1, 0.1, 6 + (i % 3) * 3,
               tex_solid(GREEN), tex_solid(GREEN), tex_solid(GREEN_DARK))
    sh.finish((0.5, 0.5, 0), [1, 1], "pot", out, meta)

    sh = Sheet(200, 180, 100, 120)
    rnd = random.Random(11)
    for _ in range(6):
        x, y = rnd.uniform(0.0, 0.5), rnd.uniform(0.0, 0.5)
        s = rnd.uniform(0.3, 0.5)
        sh.box(x, y, 0, s, s, rnd.uniform(8, 20), tex_flag((128, 124, 116)), tex_plaster((104, 100, 94)), tex_plaster((86, 82, 78)))
    sh.finish((0.5, 0.5, 0), [1, 1], "rock", out, meta)

    sh = Sheet(160, 200, 80, 150)
    sh.cylinder(0.5, 0.5, 0, 0.12, 30, lambda a, v: (80, 60, 40) if int(v) % 8 else (56, 42, 28), lambda i, j: (60, 46, 30, 255))
    sh.finish((0.5, 0.5, 0), [1, 1], "pier_post", out, meta)

    # 사다리: 목마 옆구리에 기댄 모습(위가 왼쪽 위로 기움)
    sh = Sheet(200, 260, 100, 200)
    for rail in (0.35, 0.65):
        for j in range(200):
            t = j / 199
            sh.put(P(0.5 - t * 0.55, rail - t * 0.25, t * 74), (110, 76, 44, 255))
            sh.put(P(0.5 - t * 0.55 + 0.02, rail - t * 0.25, t * 74), (90, 60, 34, 255))
    for k in range(1, 9):
        t = k / 9
        for i in range(30):
            u = 0.35 + 0.3 * i / 29
            sh.put(P(0.5 - t * 0.55, u - t * 0.25, t * 74), (130, 92, 54, 255))
    sh.finish((0.5, 0.5, 0), [1, 1], "ladder", out, meta)


def make_trees(out, meta):
    # 사이프러스: 좁고 높은 짙은 초록 원뿔
    sh = Sheet(160, 300, 80, 250)
    sh.box(0.45, 0.45, 0, 0.1, 0.1, 10, None, tex_solid(WOOD_DARK), tex_solid(WOOD_DARK))
    for z in range(8, 92, 2):
        t = (z - 8) / 84
        r = 0.26 * math.sin(min(1.0, t * 1.6) * math.pi / 2) * (1 - t) ** 0.6 + 0.03
        sh.cylinder(0.5, 0.5, z, r, 2, lambda a, v, z=z: col(GREEN, 0.8 + 0.35 * h2(int(a), z)), None)
    sh.finish((0.5, 0.5, 0), [1, 1], "cypress", out, meta)

    # 소나무: 둥근 층 셋
    sh = Sheet(220, 300, 110, 250)
    sh.cylinder(0.5, 0.5, 0, 0.08, 40, lambda a, v: (92, 64, 40), None)
    for z0, r in ((30, 0.55), (50, 0.45), (66, 0.32)):
        for z in range(z0, z0 + 14, 2):
            rr = r * (1 - (z - z0) / 18)
            sh.cylinder(0.5, 0.5, z, rr, 2, lambda a, v, z=z: col((40, 72, 48), 0.75 + 0.4 * h2(int(a * 0.6), z)), None)
    sh.finish((0.5, 0.5, 0), [1, 1], "pine", out, meta)


def make_fountain(out, meta):
    sh = Sheet(320, 280, 160, 190)
    water = lambda i, j: col((70, 120, 170), 0.9 + 0.2 * h2(i // 6, j // 6))
    sh.cylinder(1.0, 1.0, 0, 0.92, 10, lambda a, v: MARBLE if int(v) != 8 else (176, 168, 150), water)
    sh.cylinder(1.0, 1.0, 10, 0.16, 18, lambda a, v: MARBLE, None)
    sh.cylinder(1.0, 1.0, 28, 0.42, 4, lambda a, v: MARBLE, water)
    sh.cylinder(1.0, 1.0, 32, 0.08, 10, lambda a, v: MARBLE, lambda i, j: (150, 190, 220, 255))
    sh.finish((1.0, 1.0, 0), [2, 2], "fountain", out, meta)


def make_stalls(out, meta):
    for name, stripe in (("stall_red", (168, 50, 44)), ("stall_white", (60, 90, 150))):
        sh = Sheet(240, 220, 120, 150)
        sh.box(0.1, 0.25, 0, 0.8, 0.5, 12, tex_plank(WOOD, False), tex_plank(WOOD), tex_plank(WOOD))
        for px_, py_ in ((0.1, 0.2), (0.85, 0.2), (0.1, 0.75), (0.85, 0.75)):
            sh.box(px_, py_, 0, 0.05, 0.05, 30, None, tex_solid(WOOD_DARK), tex_solid(WOOD_DARK))
        for x, c in ((0.2, (190, 150, 60)), (0.45, (150, 60, 40)), (0.65, (110, 140, 60))):
            sh.box(x, 0.35, 12, 0.15, 0.25, 4, tex_solid(c), tex_solid(c), tex_solid(col(c, 0.8)[:3]))
        stripes = lambda s, t: (236, 228, 210) if int(s // 6) % 2 else stripe
        for i in range(120):
            s = i / 119
            for j in range(40):
                t = j / 39
                c = stripes(s * 60, 0)
                sh.put(P(0.0 + 1.0 * s, 0.1 + 0.85 * t, 34 - t * 8), col(c, 0.95 - t * 0.15))
        sh.finish((0.5, 0.5, 0), [1, 1], name, out, meta)


def make_bell_tower(out, meta):
    sh = Sheet(320, 420, 160, 340)
    plank = tex_plank(WOOD)
    sh.box(0.1, 0.1, 0, 1.8, 1.8, 6, tex_flag(STONE_TOP), tex_brick(STONE), tex_brick(STONE))
    for px_, py_ in ((0.25, 0.25), (1.55, 0.25), (0.25, 1.55), (1.55, 1.55)):
        sh.box(px_, py_, 6, 0.2, 0.2, 96, plank, plank, plank)
    for z in (40, 74):
        sh.box(0.2, 0.2, z, 1.6, 1.6, 4, tex_plank(WOOD_DARK, False), tex_plank(WOOD_DARK), tex_plank(WOOD_DARK))
    bronze = (170, 120, 50)
    sh.cylinder(1.0, 1.0, 82, 0.28, 16, lambda a, v: col(bronze, 0.8 + 0.3 * (v / 16)), None)
    sh.box(0.1, 0.1, 102, 1.8, 1.8, 4, tex_plank(WOOD_DARK, False), tex_plank(WOOD_DARK), tex_plank(WOOD_DARK))
    sh.roof(0.1, 0.1, 1.8, 1.8, 106, 22, True, tex_roof((150, 70, 46)), tex_plank(WOOD))
    sh.finish((1.0, 1.0, 0), [2, 2], "bell_tower", out, meta)


def hull(sh, x0, y0, length, width, depth, plank, deck):
    """뱃머리가 +gx 쪽인 배 몸통: 단면을 길이 방향으로 좁혀 가며 쌓는다."""
    steps = int(length * 40)
    for i in range(steps):
        t = i / (steps - 1)
        taper = min(1.0, t * 4, (1 - t) * 3) ** 0.6
        w = width * max(0.2, taper)
        z_lift = 6 * (1 - min(1.0, t * 4, (1 - t) * 3))
        gx = x0 + length * t
        cy = y0 + width / 2
        for j in range(int(depth * 2)):
            v = j / 2
            sh.put(P(gx, cy + w / 2, v + z_lift), col(plank(t * 100, v), 0.8))
        for k in range(12):
            sh.put(P(gx, cy - w / 2 + w * k / 11, depth + z_lift), col(deck, 0.9 + 0.1 * (k % 3 == 0)))


def make_ships(out, meta):
    sh = Sheet(560, 460, 230, 330)
    hull(sh, 0.1, 0.4, 4.8, 1.2, 14, tex_plank((80, 52, 32)), (130, 96, 60))
    # 노
    for i in range(9):
        gx = 0.9 + i * 0.38
        for j in range(30):
            t = j / 29
            sh.put(P(gx - t * 0.1, 1.6 + t * 0.55, 10 - t * 12), (110, 80, 50, 255))
    # 돛대·돛(붉은 줄무늬 아마천)
    sh.box(2.4, 0.95, 14, 0.1, 0.1, 110, None, tex_solid(WOOD_DARK), tex_solid(WOOD_DARK))
    for i in range(140):
        s = i / 139
        for j in range(90):
            t = j / 89
            c = (210, 196, 160) if int(s * 7) % 2 else (168, 70, 50)
            bulge = math.sin(s * math.pi) * 0.12
            sh.put(P(2.45 + bulge, 0.25 + 1.4 * s, 118 - t * 70), col(c, 0.95 - 0.15 * t))
    sh.box(4.4, 0.85, 14, 0.5, 0.3, 14, tex_plank(WOOD_DARK), tex_plank(WOOD_DARK), tex_plank(WOOD_DARK))
    sh.finish((2.5, 1.0, 0), [5, 2], "galley", out, meta)

    sh = Sheet(260, 200, 120, 130)
    hull(sh, 0.1, 0.2, 1.8, 0.6, 8, tex_plank((96, 66, 40)), (130, 96, 60))
    sh.finish((1.0, 0.5, 0), [2, 1], "boat", out, meta)


def main(root):
    out = root / "assets/env"
    meta = json.loads((out / "env.json").read_text())
    add_floors(out, meta)
    props = {}
    make_temple(out, props)
    make_small(out, props)
    make_trees(out, props)
    make_fountain(out, props)
    make_stalls(out, props)
    make_bell_tower(out, props)
    make_ships(out, props)
    meta["props"].update(props)
    (out / "env.json").write_text(json.dumps(meta, ensure_ascii=False))
    print("맵 개편용 임시 그림:", ", ".join(props), "+ 바닥", ", ".join(k for k, _ in EXTRA_FLOORS))
    # 다시 그려 받은 그림(assets/source/troy_city·troy_coast)이 있으면 임시 그림을 덮어쓴다
    from gen_env_redraw import apply
    apply(root)


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
