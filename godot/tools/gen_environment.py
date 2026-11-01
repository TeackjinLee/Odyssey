#!/usr/bin/env python3
"""환경 픽셀아트 생성기 (임시 에셋): 바닥 타일 아틀라스, 성벽·탑·성문 블록, 집, 트로이 목마, 소품, 불꽃.

격자 1칸 = 64×32 마름모(2:1 아이소메트릭). 화면 좌표 = ((gx-gy)*32, (gx+gy)*16 - z).
소품마다 env.json에 그림 파일, 기준점(발자국 중심이 그림의 어디인지), 발자국 크기(칸)를 적는다.
게임은 이 기준점을 발자국 중심 월드 좌표에 맞춰 놓고, 그 y로 깊이 정렬한다.

사용: python3 gen_environment.py <godot 프로젝트 폴더>
"""
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

OUTLINE = (20, 14, 12, 255)
L_TOP, L_LEFT, L_RIGHT = 1.0, 0.8, 0.6


def P(gx, gy, z):
    return ((gx - gy) * 32.0, (gx + gy) * 16.0 - z)


def h2(*a):
    """정수 몇 개로 0~1 해시."""
    x = 0
    for v in a:
        x = (x * 1000003 + int(v) * 7919 + 12345) & 0xFFFFFFFF
    x ^= x >> 13
    x = (x * 1274126177) & 0xFFFFFFFF
    x ^= x >> 16
    return (x & 0xFFFF) / 65535.0


def col(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


# ── 표면 무늬 ─────────────────────────────────────────
def tex_brick(base):
    def f(u, v):
        row = int(v // 5)
        off = 4 if row % 2 else 0
        bx = int((u + off) // 9)
        if v % 5 < 1 or (u + off) % 9 < 1:
            return col(base, 0.62)
        return col(base, 0.88 + 0.22 * h2(bx, row))
    return f


def tex_plank(base, horizontal=True, w=4):
    def f(u, v):
        a, b = (v, u) if horizontal else (u, v)
        row = int(a // w)
        if a % w < 1:
            return col(base, 0.6)
        seg = int((b + row * 7) // 22)
        if (b + row * 7) % 22 < 1:
            return col(base, 0.7)
        return col(base, 0.86 + 0.2 * h2(row, seg) + 0.06 * h2(int(b), row))
    return f


def tex_plaster(base):
    def f(u, v):
        k = 0.92 + 0.1 * h2(int(u // 2), int(v // 2))
        if v < 4:
            k *= 0.72
        return col(base, k)
    return f


def tex_flag(base):
    def f(u, v):
        bx, by = int(u // 12), int(v // 12)
        if u % 12 < 1 or v % 12 < 1:
            return col(base, 0.65)
        return col(base, 0.9 + 0.16 * h2(bx, by))
    return f


def tex_roof(base):
    def f(s, t):
        row = int(t // 4)
        if t % 4 < 1.2:
            return col(base, 0.62)
        cs = int((s + (row % 2) * 3) // 6)
        if (s + (row % 2) * 3) % 6 < 1:
            return col(base, 0.78)
        return col(base, 0.92 + 0.14 * h2(cs, row))
    return f


def tex_solid(base):
    return lambda u, v: col(base, 1.0)


# ── 그림판 ────────────────────────────────────────────
class Sheet:
    def __init__(self, w=420, h=420, ox=210, oy=300):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.px = self.img.load()
        self.ox, self.oy = ox, oy

    def put(self, p, c):
        x, y = int(math.floor(p[0] + self.ox)), int(math.floor(p[1] + self.oy))
        if 0 <= x < self.img.width and 0 <= y < self.img.height:
            self.px[x, y] = c

    def box(self, x0, y0, z0, w, d, h, top, left, right, top_light=L_TOP):
        """(x0,y0,z0)에서 w×d칸, 높이 h px 상자. 보이는 세 면(위·왼앞·오른앞)을 칠한다."""
        x1, y1, z1 = x0 + w, y0 + d, z0 + h
        # 왼앞면: gy = y1, u는 gx 방향 길이(px), v는 높이
        lu = w * 35.8
        for i in range(int(lu * 1.6) + 2):
            u = i / 1.6
            gx = x0 + w * (u / lu if lu else 0)
            for j in range(int(h * 2) + 1):
                v = j / 2
                c = left(u, v)
                if c:
                    self.put(P(gx, y1, z0 + v), col(c, L_LEFT))
        ru = d * 35.8
        for i in range(int(ru * 1.6) + 2):
            u = i / 1.6
            gy = y1 - d * (u / ru if ru else 0)
            for j in range(int(h * 2) + 1):
                v = j / 2
                c = right(u, v)
                if c:
                    self.put(P(x1, gy, z0 + v), col(c, L_RIGHT))
        if top:
            for i in range(int(w * 72) + 2):
                gx = x0 + w * i / (w * 72)
                for j in range(int(d * 72) + 2):
                    gy = y0 + d * j / (d * 72)
                    c = top((gx - x0) * 35.8, (gy - y0) * 35.8)
                    if c:
                        self.put(P(gx, gy, z1), col(c, top_light))

    def cylinder(self, cx, cy, z0, r, h, side, top):
        """세운 원기둥 (반지름 r칸)."""
        for k in range(int(r * 600) + 8):
            a = math.pi * (k / (r * 600 + 8)) - math.pi * 0.25  # 카메라 쪽 반원
            gx, gy = cx + r * math.cos(a), cy + r * math.sin(a)
            light = 0.62 + 0.38 * max(0.0, math.cos(a - math.pi * 0.75))
            for j in range(int(h * 2) + 1):
                v = j / 2
                self.put(P(gx, gy, z0 + v), col(side(a * 20, v), light))
        if top:
            for i in range(-40, 41):
                for j in range(-40, 41):
                    dx, dy = r * i / 40, r * j / 40
                    if dx * dx + dy * dy <= r * r:
                        self.put(P(cx + dx, cy + dy, z0 + h), top(i, j))

    def roof(self, x0, y0, w, d, z, rise, along_x, tex, gable):
        """박공 지붕. along_x면 용마루가 gx 방향."""
        ov = 0.14
        if along_x:
            ridge_y = y0 + d / 2
            slopes = [
                (lambda s, t: (x0 - ov + (w + 2 * ov) * s, (y0 - ov) + (ridge_y - y0 + ov) * t, z + rise * t), 0.95),
                (lambda s, t: (x0 - ov + (w + 2 * ov) * s, (y0 + d + ov) - (y0 + d + ov - ridge_y) * t, z + rise * t), 0.85),
            ]
            length_s, length_t = (w + 2 * ov) * 35.8, (d / 2 + ov) * 30
            gable_fn = lambda s, t: (x0 + w, y0 + d - d * s, z + rise * (1 - abs(2 * s - 1)) * t)
        else:
            ridge_x = x0 + w / 2
            slopes = [
                (lambda s, t: ((x0 - ov) + (ridge_x - x0 + ov) * t, y0 - ov + (d + 2 * ov) * s, z + rise * t), 0.95),
                (lambda s, t: ((x0 + w + ov) - (x0 + w + ov - ridge_x) * t, y0 - ov + (d + 2 * ov) * s, z + rise * t), 0.72),
            ]
            length_s, length_t = (d + 2 * ov) * 35.8, (w / 2 + ov) * 30
            gable_fn = lambda s, t: (x0 + w * s, y0 + d, z + rise * (1 - abs(2 * s - 1)) * t)
        # 박공벽 먼저(지붕보다 뒤)
        for i in range(160):
            s = i / 159
            for j in range(80):
                t = j / 79
                g = gable_fn(s, t)
                self.put(P(*g), col(gable(s * 60, t * rise), L_LEFT if not along_x else L_RIGHT))
        for fn, light in slopes:
            for i in range(int(length_s * 1.8) + 2):
                s = i / (length_s * 1.8)
                for j in range(int(length_t * 2.4) + 2):
                    t = j / (length_t * 2.4)
                    g = fn(s, t)
                    c = tex(s * length_s, (1 - t) * length_t)
                    if t > 0.96:
                        c = col(c, 0.75)
                    self.put(P(*g), col(c, light))

    def finish(self, anchor_g, footprint, name, out, meta, outline_on=True):
        if outline_on:
            add_outline(self.img)
        bbox = self.img.getbbox()
        img = self.img.crop(bbox)
        ax, ay = P(*anchor_g)
        anchor = [round(ax + self.ox - bbox[0]), round(ay + self.oy - bbox[1])]
        img.save(out / f"{name}.png")
        meta[name] = {"file": f"{name}.png", "anchor": anchor, "footprint": footprint, "size": list(img.size)}


def add_outline(img):
    src = img.copy().load()
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3]:
                    px[x, y] = OUTLINE
                    break


# ── 바닥 타일 ─────────────────────────────────────────
FLOORS = [
    ("cobble", (112, 106, 98)),
    ("plaza", (150, 140, 120)),
    ("dirt", (112, 86, 60)),
    ("grass", (64, 92, 52)),
    ("road", (160, 136, 98)),
    ("ash", (64, 58, 56)),
]


def floor_tiles(out):
    variants = 4
    atlas = Image.new("RGBA", (64 * variants, 32 * len(FLOORS)), (0, 0, 0, 0))
    px = atlas.load()
    for row, (kind, base) in enumerate(FLOORS):
        for var in range(variants):
            rnd = random.Random(row * 31 + var)
            seeds = [(rnd.random(), rnd.random(), 0.85 + 0.25 * rnd.random()) for _ in range(9)]
            for y in range(32):
                for x in range(64):
                    sx, sy = x - 32 + 0.5, y + 0.5
                    if abs(sx) / 32 + abs(sy - 16) / 16 > 1.0:
                        continue
                    gx = (sx / 32 + sy / 16) / 2
                    gy = (sy / 16 - sx / 32) / 2
                    k = 1.0
                    if kind in ("cobble", "ash"):
                        ds = sorted(((min(abs(gx - a), 1 - abs(gx - a)) ** 2 + min(abs(gy - b), 1 - abs(gy - b)) ** 2, m) for a, b, m in seeds))
                        edge = math.sqrt(ds[1][0]) - math.sqrt(ds[0][0])
                        k = ds[0][1] if edge > 0.035 else 0.62
                    elif kind == "plaza":
                        k = 0.95 + 0.08 * h2(int(gx * 2), int(gy * 2), var)
                        if (gx * 2) % 1 < 0.03 or (gy * 2) % 1 < 0.03:
                            k = 0.7
                    elif kind == "grass":
                        k = 0.8 + 0.35 * h2(x // 2, y, var)
                    else:
                        k = 0.86 + 0.2 * h2(x // 2, y // 2, var)
                    if kind == "ash" and h2(x, y, 9) > 0.985:
                        c = (220, 110, 40, 255)
                    else:
                        c = col(base, k * (0.94 + 0.06 * h2(x, y, var + 3)))
                    px[var * 64 + x, row * 32 + y] = c
    atlas.save(out / "floor_atlas.png")
    return {"floor_atlas": {"file": "floor_atlas.png", "tile": [64, 32], "rows": [k for k, _ in FLOORS], "variants": variants}}


# ── 구조물·소품 ───────────────────────────────────────
STONE = (150, 140, 124)
STONE_TOP = (176, 168, 150)
WOOD = (122, 84, 50)
WOOD_DARK = (84, 56, 34)
PLASTER = (206, 190, 160)
ROOF = (170, 78, 52)


def merlons(sh, z, w=1, d=1):
    for gx, gy in ((0, 0), (w - 0.34, 0), (0, d - 0.34), (w - 0.34, d - 0.34), (w / 2 - 0.17, d - 0.34), (w - 0.34, d / 2 - 0.17)):
        sh.box(gx, gy, z, 0.34, 0.34, 9, tex_flag(STONE_TOP), tex_brick(STONE), tex_brick(STONE))


def make_structures(out, meta):
    sh = Sheet()
    sh.box(0, 0, 0, 1, 1, 48, tex_flag(STONE_TOP), tex_brick(STONE), tex_brick(STONE))
    merlons(sh, 48)
    sh.finish((0.5, 0.5, 0), [1, 1], "wall", out, meta)

    sh = Sheet()
    sh.box(0, 0, 0, 1, 1, 76, tex_flag(STONE_TOP), tex_brick((158, 148, 130)), tex_brick((158, 148, 130)))
    for gx, gy in ((0.6, 1.0), (1.0, 0.6)):
        for v in range(40, 56):
            sh.put(P(gx, gy, v), (24, 18, 18, 255))
            sh.put(P(gx + (0.02 if gy == 1.0 else 0), gy - (0.02 if gx == 1.0 else 0), v), (24, 18, 18, 255))
    merlons(sh, 76)
    sh.finish((0.5, 0.5, 0), [1, 1], "tower", out, meta)

    def door_face(u, v):
        if 6 < u < 30 and v < 34:
            if int(v) in (8, 22):
                return (60, 60, 64)
            return tex_plank(WOOD_DARK, horizontal=False, w=5)(u, v)
        return tex_brick(STONE)(u, v)

    sh = Sheet()
    sh.box(0, 0, 0, 1, 1, 48, tex_flag(STONE_TOP), door_face, door_face)
    merlons(sh, 48)
    sh.finish((0.5, 0.5, 0), [1, 1], "gate_closed", out, meta)

    sh = Sheet()
    sh.box(0, 0, 34, 1, 1, 14, tex_flag(STONE_TOP), tex_brick(STONE), tex_brick(STONE))
    merlons(sh, 48)
    sh.finish((0.5, 0.5, 0), [1, 1], "gate_open", out, meta)

    houses = [("house_a", 2, 2, True, PLASTER, ROOF), ("house_b", 3, 2, True, (196, 176, 140), (150, 70, 50)),
              ("house_c", 2, 3, False, (214, 200, 172), (176, 92, 56)), ("house_d", 2, 2, False, (190, 168, 136), (130, 64, 46))]
    for name, w, d, along, wall_c, roof_c in houses:
        sh = Sheet(520, 460, 260, 320)

        def face(u, v, wall_c=wall_c, w=w):
            door_u = 35.8 * w * 0.45
            if door_u < u < door_u + 9 and v < 16:
                return (52, 36, 26)
            if (u % 24) > 14 and (u % 24) < 20 and 18 < v < 25:
                return (40, 30, 26)
            return tex_plaster(wall_c)(u, v)

        sh.box(0, 0, 0, w, d, 34, None, face, face)
        sh.roof(0, 0, w, d, 34, 18, along, tex_roof(roof_c), tex_plaster(wall_c))
        sh.finish((w / 2, d / 2, 0), [w, d], name, out, meta)

    # 트로이 목마
    sh = Sheet(560, 560, 240, 420)
    plank = tex_plank(WOOD)
    plank_d = tex_plank(WOOD_DARK)
    sh.box(0, 0, 0, 4, 2, 7, tex_plank(WOOD_DARK, False), plank_d, plank_d)
    for lx, ly in ((0.55, 0.5), (0.55, 1.15), (2.85, 0.5), (2.85, 1.15)):
        sh.box(lx, ly, 7, 0.32, 0.32, 30, plank, plank, plank)
        sh.box(lx - 0.04, ly - 0.04, 7, 0.4, 0.4, 4, plank_d, plank_d, plank_d)
    sh.box(0.1, 0.88, 26, 0.24, 0.24, 24, plank_d, plank_d, plank_d)
    sh.box(0.35, 0.42, 36, 2.9, 1.16, 20, plank, plank, plank)
    sh.box(0.5, 0.52, 56, 2.5, 0.96, 4, plank, plank, plank)
    for i, (nx, nz) in enumerate(((2.85, 52), (3.05, 62), (3.25, 72), (3.45, 82))):
        sh.box(nx, 0.6, nz, 0.55, 0.8, 14, plank, plank, plank)
        sh.box(nx - 0.08, 0.86, nz + 8, 0.25, 0.28, 10, plank_d, plank_d, plank_d)
    sh.box(3.45, 0.62, 92, 1.0, 0.76, 13, plank, plank, plank)
    sh.box(4.3, 0.66, 88, 0.6, 0.68, 11, plank, plank, plank)
    for ey in (0.66, 1.16):
        sh.box(3.5, ey, 105, 0.18, 0.16, 7, plank_d, plank_d, plank_d)
    for v in range(4):
        sh.put(P(4.0, 1.39, 99 + v * 0.5), (30, 22, 18, 255))
        sh.put(P(4.02, 1.39, 99 + v * 0.5), (30, 22, 18, 255))
    hatch = (1.4, 1.59)
    for i in range(int(0.8 * 60)):
        for v in range(42, 52):
            sh.put(P(hatch[0] + i / 60, hatch[1], v), (46, 30, 20, 255))
    draw = ImageDraw.Draw(sh.img)
    for wx in (0.55, 3.45):
        cx, cy = P(wx, 2.0, 3)
        cx, cy = cx + sh.ox, cy + sh.oy
        draw.ellipse([cx - 9, cy - 9, cx + 8, cy + 8], fill=(70, 48, 30, 255), outline=(36, 24, 16, 255))
        draw.line([cx - 6, cy - 6, cx + 6, cy + 6], fill=(40, 28, 18, 255))
        draw.line([cx - 6, cy + 6, cx + 6, cy - 6], fill=(40, 28, 18, 255))
    sh.finish((2, 1, 0), [4, 2], "horse", out, meta)


def make_props(out, meta):
    sh = Sheet(160, 160, 80, 110)
    sh.box(0.2, 0.2, 0, 0.6, 0.6, 14, tex_plank(WOOD, False), tex_plank(WOOD), tex_plank(WOOD))
    sh.finish((0.5, 0.5, 0), [1, 1], "crate", out, meta)

    sh = Sheet(160, 160, 80, 110)
    sh.cylinder(0.5, 0.5, 0, 0.26, 18, lambda a, v: (96, 64, 38) if int(v) in (3, 14) else (132, 90, 52), lambda i, j: (110, 74, 44, 255))
    sh.finish((0.5, 0.5, 0), [1, 1], "barrel", out, meta)

    sh = Sheet(160, 200, 80, 150)
    sh.box(0.44, 0.44, 0, 0.12, 0.12, 30, None, tex_solid(WOOD_DARK), tex_solid(WOOD_DARK))
    sh.cylinder(0.5, 0.5, 30, 0.16, 4, lambda a, v: (70, 64, 60), lambda i, j: (36, 20, 14, 255))
    sh.finish((0.5, 0.5, 0), [1, 1], "torch_post", out, meta)

    sh = Sheet(160, 160, 80, 110)
    for lx, ly in ((0.3, 0.3), (0.62, 0.3), (0.3, 0.62), (0.62, 0.62)):
        sh.box(lx, ly, 0, 0.08, 0.08, 10, None, tex_solid((60, 56, 54)), tex_solid((60, 56, 54)))
    sh.cylinder(0.5, 0.5, 10, 0.3, 5, lambda a, v: (150, 110, 60), lambda i, j: (40, 22, 14, 255))
    sh.finish((0.5, 0.5, 0), [1, 1], "brazier", out, meta)

    sh = Sheet(200, 260, 100, 200)
    sh.cylinder(0.5, 0.5, 0, 0.24, 58, lambda a, v: (226, 220, 206) if int(a) % 5 else (180, 174, 160), lambda i, j: (230, 226, 214, 255))
    sh.box(0.2, 0.2, 58, 0.6, 0.6, 6, tex_flag((232, 226, 212)), tex_plaster((220, 214, 200)), tex_plaster((220, 214, 200)))
    sh.box(0.15, 0.15, 0, 0.7, 0.7, 4, tex_flag((200, 194, 180)), tex_plaster((200, 194, 180)), tex_plaster((200, 194, 180)))
    sh.finish((0.5, 0.5, 0), [1, 1], "column", out, meta)

    for name, cloth, emblem in (("banner_troy", (110, 40, 120), (226, 184, 52)), ("banner_greek", (40, 70, 140), (232, 220, 190))):
        sh = Sheet(200, 240, 100, 190)
        sh.box(0.46, 0.46, 0, 0.08, 0.08, 64, None, tex_solid(WOOD_DARK), tex_solid(WOOD_DARK))
        for i in range(36):
            for v in range(22, 58):
                u = i / 36
                c = cloth
                if (u - 0.5) ** 2 * 900 + (v - 44) ** 2 < 36:
                    c = emblem
                if v < 24:
                    c = col(cloth, 0.7)[:3]
                sh.put(P(0.54, 0.5 + u * 0.55, v - (u * 2)), c + (255,))
        sh.finish((0.5, 0.5, 0), [1, 1], name, out, meta)

    sh = Sheet(200, 180, 100, 120)
    rnd = random.Random(4)
    for _ in range(9):
        x, y = rnd.uniform(0.0, 0.7), rnd.uniform(0.0, 0.7)
        s = rnd.uniform(0.15, 0.32)
        sh.box(x, y, 0, s, s, rnd.uniform(4, 10), tex_flag(STONE_TOP), tex_brick(STONE), tex_brick(STONE))
    sh.finish((0.5, 0.5, 0), [1, 1], "rubble", out, meta)

    sh = Sheet(220, 220, 110, 150)
    sh.box(0.1, 0.25, 0, 0.8, 0.5, 6, tex_plank(WOOD_DARK, False), tex_plank(WOOD_DARK), tex_plank(WOOD_DARK))
    for px_, py_ in ((0.15, 0.3), (0.75, 0.3)):
        sh.box(px_, py_, 6, 0.12, 0.4, 24, None, tex_plank(WOOD), tex_plank(WOOD))
    sh.box(0.27, 0.38, 20, 0.48, 0.24, 8, tex_solid((150, 140, 120)), tex_plank((150, 110, 60)), tex_plank((150, 110, 60)))
    sh.box(0.82, 0.48, 18, 0.18, 0.06, 3, None, tex_solid((70, 70, 74)), tex_solid((70, 70, 74)))
    sh.box(0.96, 0.48, 12, 0.05, 0.06, 9, None, tex_solid((70, 70, 74)), tex_solid((70, 70, 74)))
    sh.finish((0.5, 0.5, 0), [1, 1], "winch", out, meta)

    sh = Sheet(220, 200, 110, 140)
    sh.box(0.1, 0.2, 8, 1.2, 0.6, 10, tex_plank(WOOD, False), tex_plank(WOOD), tex_plank(WOOD))
    draw = ImageDraw.Draw(sh.img)
    for wx in (0.35, 1.05):
        cx, cy = P(wx, 0.8, 6)
        cx, cy = cx + sh.ox, cy + sh.oy
        draw.ellipse([cx - 6, cy - 6, cx + 5, cy + 5], fill=(70, 48, 30, 255), outline=(36, 24, 16, 255))
    sh.finish((0.7, 0.5, 0), [1, 1], "cart", out, meta)


FIRE_COLORS = ((110, 22, 14), (200, 52, 22), (240, 118, 30), (255, 196, 70), (255, 240, 170))


def make_fx(out, meta):
    # 불꽃: 아래가 넓고 위로 갈수록 좁아지는 몸통에 위로 흐르는 물결(혀)을 깎아 넣고,
    # 세기를 5단계 색으로 나눠 칠한다(바깥 어두운 빨강 테두리, 노란 심지는 작게). 8프레임에 한 바퀴 돈다.
    frames, w, h = 8, 24, 36
    fire = Image.new("RGBA", (w * frames, h), (0, 0, 0, 0))
    px = fire.load()
    for f in range(frames):
        ph = f / frames * math.tau
        for y in range(h):
            t = (h - 3 - y) / (h - 6)            # 0 = 밑동, 1 = 꼭대기
            if t < -0.08 or t > 1:
                continue
            tc = min(max(t, 0.0), 1.0)
            half = 9.5 * (1 - tc) ** 0.7 + 0.6
            sway = math.sin(tc * 4.2 - ph) * 2.6 * tc + math.sin(tc * 9 - ph * 2) * 0.8 * tc
            for x in range(w):
                dx = x + 0.5 - (w / 2 + sway)
                # 위로 흘러가는 물결이 가장자리를 깎아 혀 모양을 만든다
                wave = (math.sin(dx * 0.9 + tc * 11 - ph * 2) + math.sin(-dx * 1.7 + tc * 17 - ph * 3)) * 0.5
                v = 1 - abs(dx) / half - wave * (0.15 + 0.55 * tc) - max(0.0, -t) * 6
                if v <= 0:
                    continue
                v *= 1.15 - tc * 0.55
                lv = 0 if v < 0.16 else 1 if v < 0.38 else 2 if v < 0.62 else 3 if v < 0.86 else 4
                px[f * w + x, y] = FIRE_COLORS[lv] + (255,)
        rnd = random.Random(f * 7 + 3)
        for _ in range(2):                       # 위로 떨어져 나간 불똥
            ex, ey = rnd.randint(6, w - 7), rnd.randint(0, 7)
            px[f * w + ex, ey] = FIRE_COLORS[3] + (255,)
    fire.save(out / "fire.png")
    meta["fire"] = {"file": "fire.png", "frame": [w, h], "frames": frames, "anchor": [w // 2, h - 3]}

    # 연기 한 덩이(입자로 띄워 커지며 흐려짐): 둥근 덩이, 위쪽이 조금 밝다
    sm = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    sp = sm.load()
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 7.5, y - 7.5)
            if d < 7.6:
                g = 78 if math.hypot(x - 6, y - 5.5) < 4.5 else 60
                sp[x, y] = (g, g - 4, g - 8, 255)
    sm.save(out / "smoke.png")
    meta["smoke"] = {"file": "smoke.png", "anchor": [8, 8], "footprint": [1, 1], "size": [16, 16]}

    sh = Image.new("RGBA", (24, 10), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([0, 0, 23, 9], fill=(0, 0, 0, 110))
    sh.save(out / "shadow.png")

    ar = Image.new("RGBA", (16, 5), (0, 0, 0, 0))
    d = ImageDraw.Draw(ar)
    d.line([1, 2, 12, 2], fill=(150, 104, 60, 255))
    d.polygon([(12, 0), (15, 2), (12, 4)], fill=(200, 200, 196, 255))
    d.line([0, 1, 3, 1], fill=(236, 232, 220, 255))
    d.line([0, 3, 3, 3], fill=(236, 232, 220, 255))
    ar.save(out / "arrow.png")


def main():
    root = Path(sys.argv[1])
    out = root / "assets" / "env"
    out.mkdir(parents=True, exist_ok=True)
    meta = floor_tiles(out)
    props = {}
    make_structures(out, props)
    make_props(out, props)
    make_fx(out, props)
    meta["props"] = props
    (out / "env.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))
    print("환경 에셋", len(props), "종")


if __name__ == "__main__":
    main()
