#!/usr/bin/env python3
"""캐릭터 픽셀아트 스프라이트 시트 생성기 (임시 에셋).

간단한 3D 뼈대(골반·가슴·머리·팔다리·무기)를 동작별로 잡고, 쿼터뷰(30°)로 8방향 투영해
64×64 프레임에 1px 외곽선 픽셀아트로 그린다. 8방향이 모두 같은 몸 비율을 갖는 게 목적이다.

시트 규칙(실제 아트로 바꿀 때도 지킨다):
  - 한 줄 = 한 방향. 0=동(오른쪽) 1=남동 2=남(아래) 3=남서 4=서 5=북서 6=북 7=북동
  - 열은 ANIMS 순서대로 이어 붙인다. 발 위치는 프레임의 (32, 55).
  - 같은 이름의 .json에 동작별 시작 열·프레임 수·fps·반복 여부를 적는다.

사용: python3 gen_characters.py <godot 프로젝트 폴더>
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

FRAME = 64
ANCHOR = (32, 55)
ELEV = math.radians(30)
GY_K = math.sin(ELEV)
Z_K = math.cos(ELEV)
CAM = (0.0, math.cos(ELEV), math.sin(ELEV))
OUTLINE = (22, 15, 13, 255)

# 이름, 프레임 수, fps, 반복
ANIMS = [
    ("idle", 4, 5, True),
    ("walk", 6, 10, True),
    ("run", 6, 13, True),
    ("attack1", 4, 16, False),
    ("attack2", 4, 16, False),
    ("attack3", 5, 14, False),
    ("heavy", 6, 12, False),
    ("block", 2, 6, True),
    ("bow", 4, 10, False),
    ("hit", 2, 10, False),
    ("dodge", 4, 14, False),
    ("death", 5, 9, False),
    ("interact", 4, 8, True),
    ("downed", 1, 1, True),
]


# ── 벡터 ──────────────────────────────────────────────
def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def length(a):
    return math.sqrt(dot(a, a))


def norm(a):
    n = length(a)
    return (0.0, 0.0, 1.0) if n < 1e-6 else mul(a, 1.0 / n)


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


def two_bone(a, c, l1, l2, pole):
    """a에서 c로 가는 두 마디의 가운데 관절 위치 (pole 쪽으로 굽힘)."""
    d_vec = sub(c, a)
    d = min(length(d_vec), l1 + l2 - 0.05)
    d = max(d, 0.5)
    dr = norm(d_vec)
    cos_a = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    cos_a = max(-1.0, min(1.0, cos_a))
    sin_a = math.sqrt(1 - cos_a * cos_a)
    p = sub(pole, mul(dr, dot(pole, dr)))
    p = norm(p)
    return add(a, add(mul(dr, l1 * cos_a), mul(p, l1 * sin_a)))


# ── 캐릭터 설정(키트) ─────────────────────────────────
SKIN = (206, 150, 108)
KITS = {
    "odysseus_sword": dict(
        scale=1.12, skin=SKIN, hair=(38, 27, 22), beard=True, helmet="crested",
        helm=(214, 164, 70), crest=(214, 36, 32), armor=(150, 98, 44), tunic=(158, 34, 34),
        cape=(176, 30, 38), greave=(196, 146, 72), sandal=(104, 66, 40),
        weapon="sword", shield=((190, 134, 56), (150, 30, 30), (112, 76, 44)), shield_place="arm",
    ),
    "greek_sword": dict(
        scale=1.0, skin=SKIN, hair=(52, 36, 26), beard=True, helmet="plain",
        helm=(192, 146, 70), crest=(160, 40, 36), armor=(214, 200, 160), tunic=(58, 84, 150),
        cape=None, greave=(184, 140, 72), sandal=(104, 66, 40),
        weapon="sword", shield=((184, 136, 62), (46, 66, 132), (112, 76, 44)), shield_place="arm",
    ),
    "greek_spear": dict(
        scale=1.0, skin=(196, 140, 100), hair=(30, 24, 20), beard=False, helmet="plain",
        helm=(192, 146, 70), crest=(40, 40, 46), armor=(214, 200, 160), tunic=(58, 84, 150),
        cape=None, greave=(184, 140, 72), sandal=(104, 66, 40),
        weapon="spear", shield=((176, 46, 40), (220, 196, 120), (112, 76, 44)), shield_place="arm",
    ),
    "greek_archer": dict(
        scale=0.98, skin=(214, 160, 118), hair=(90, 58, 34), beard=False, helmet="cap",
        helm=(128, 88, 52), crest=None, armor=(126, 92, 58), tunic=(58, 84, 150),
        cape=None, greave=(126, 92, 58), sandal=(104, 66, 40),
        weapon="bow", shield=None, shield_place=None, quiver=True,
    ),
    "trojan_sword": dict(
        scale=1.0, skin=(192, 136, 98), hair=(30, 22, 18), beard=True, helmet="phrygian",
        helm=(116, 116, 132), crest=(226, 184, 52), armor=(84, 74, 96), tunic=(112, 44, 120),
        cape=None, greave=(110, 110, 124), sandal=(70, 50, 36),
        weapon="sword", shield=((44, 38, 50), (210, 166, 60), (90, 64, 40)), shield_place="arm",
    ),
    "trojan_spear": dict(
        scale=1.0, skin=(192, 136, 98), hair=(30, 22, 18), beard=False, helmet="phrygian",
        helm=(116, 116, 132), crest=(226, 184, 52), armor=(84, 74, 96), tunic=(112, 44, 120),
        cape=None, greave=(110, 110, 124), sandal=(70, 50, 36),
        weapon="spear", shield=((112, 44, 120), (226, 184, 52), (90, 64, 40)), shield_place="arm",
    ),
    "trojan_archer": dict(
        scale=0.98, skin=(200, 144, 104), hair=(30, 22, 18), beard=False, helmet="cap_phrygian",
        helm=(150, 44, 96), crest=None, armor=(112, 44, 120), tunic=(112, 44, 120),
        cape=None, greave=(90, 70, 50), sandal=(70, 50, 36),
        weapon="bow", shield=None, shield_place=None, quiver=True,
    ),
    "trojan_captain": dict(
        scale=1.28, skin=(192, 136, 98), hair=(24, 18, 14), beard=True, helmet="crested",
        helm=(214, 172, 74), crest=(236, 232, 220), armor=(214, 168, 70), tunic=(96, 30, 108),
        cape=(96, 30, 108), greave=(214, 168, 70), sandal=(70, 50, 36),
        weapon="sword", shield=((214, 168, 70), (96, 30, 108), (90, 64, 40)), shield_place="arm",
    ),
}
KITS["odysseus_bow"] = dict(KITS["odysseus_sword"], weapon="bow", shield_place="back", quiver=True)


# ── 동작별 자세 ───────────────────────────────────────
def default_pose():
    return dict(
        pelvis=(0, 0, 14), chest=(0, 0, 24), head=(0, 0, 31.5), twist=0.0,
        footL=(0.6, -2.8, 0), footR=(-0.6, 2.8, 0),
        handL=(1.5, -6, 16), handR=(2.5, 6, 16.5),
        wdir=(0.8, 0.25, 0.05), shield="arm", show_weapon=True,
        bow_draw=0.0, cape_sway=0.0, death=False,
    )


SWORD_ATTACKS = {
    "attack1": [
        dict(twist=0.7, handR=(0, 8, 22), wdir=(-0.2, 0.9, 0.4)),
        dict(twist=0.0, handR=(8, 3, 21), wdir=(0.9, 0.3, 0.15), lunge=1.5),
        dict(twist=-0.7, handR=(5, -5, 19), wdir=(0.2, -1, 0.0), lunge=2.2),
        dict(twist=-0.3, handR=(4, 1, 18), wdir=(0.7, -0.2, 0.0), lunge=1.5),
    ],
    "attack2": [
        dict(twist=-0.6, handR=(4, -5, 17), wdir=(0.2, -0.9, -0.4)),
        dict(twist=0.1, handR=(8, 2, 21), wdir=(0.95, 0.1, 0.3), lunge=1.5),
        dict(twist=0.7, handR=(2, 8, 26), wdir=(-0.1, 0.8, 0.6), lunge=2.2),
        dict(twist=0.3, handR=(3, 6, 20), wdir=(0.6, 0.4, 0.3), lunge=1.5),
    ],
    "attack3": [
        dict(twist=0.3, handR=(-1, 4, 32), wdir=(-0.5, 0.1, 0.85), lean=-1),
        dict(twist=0.2, handR=(0, 3, 35), wdir=(-0.9, 0, 0.4), lean=-1.5),
        dict(twist=0.0, handR=(7, 2, 27), wdir=(0.7, 0, 0.7), lunge=2),
        dict(twist=-0.1, handR=(9, 1, 15), wdir=(0.85, 0, -0.5), lunge=3.5, crouch=2, lean=3),
        dict(twist=0.0, handR=(7, 2, 13), wdir=(0.6, 0.2, -0.75), lunge=3, crouch=1.5, lean=2),
    ],
    "heavy": [
        dict(twist=0.9, handR=(-3, 7, 20), wdir=(-0.8, 0.5, 0.3), crouch=2),
        dict(twist=1.1, handR=(-4, 6, 24), wdir=(-0.6, 0.3, 0.75), crouch=2.5),
        dict(twist=-0.2, handR=(9, 3, 20), wdir=(1, 0.1, 0.05), lunge=3),
        dict(twist=-0.9, handR=(5, -6, 18), wdir=(0.3, -1, -0.1), lunge=3.5),
        dict(twist=-1.0, handR=(-1, -7, 17), wdir=(-0.5, -0.8, -0.3), lunge=3),
        dict(twist=-0.3, handR=(3, 4, 18), wdir=(0.8, 0.2, 0.0), lunge=2),
    ],
}

SPEAR_ATTACKS = {
    "attack1": [
        dict(handR=(-3, 5, 23), wdir=(1, 0, -0.08), twist=0.4),
        dict(handR=(6, 4, 22), wdir=(1, -0.05, -0.08), lunge=2, twist=-0.1),
        dict(handR=(10, 3, 21), wdir=(1, -0.08, -0.06), lunge=3, twist=-0.3),
        dict(handR=(3, 5, 22), wdir=(1, 0, 0.0), lunge=1.5),
    ],
    "attack3": [
        dict(handR=(-4, 5, 26), wdir=(1, 0, -0.25), twist=0.5, lean=-1),
        dict(handR=(-5, 5, 27), wdir=(1, 0, -0.2), twist=0.6, lean=-1.5),
        dict(handR=(6, 4, 24), wdir=(1, 0, -0.18), lunge=2.5),
        dict(handR=(11, 3, 21), wdir=(1, -0.05, -0.15), lunge=4, crouch=1.5, lean=2.5),
        dict(handR=(4, 5, 22), wdir=(1, 0, -0.05), lunge=2),
    ],
}
SPEAR_ATTACKS["attack2"] = [dict(f, handR=(f["handR"][0], f["handR"][1], f["handR"][2] - 4)) for f in SPEAR_ATTACKS["attack1"]]
SPEAR_ATTACKS["heavy"] = SPEAR_ATTACKS["attack3"] + [dict(handR=(2, 5, 21), wdir=(0.9, 0.1, 0.3))]


def apply_frame(p, f):
    for k in ("handR", "wdir", "twist", "handL"):
        if k in f:
            p[k] = f[k]
    lunge = f.get("lunge", 0)
    crouch = f.get("crouch", 0)
    lean = f.get("lean", 0)
    p["pelvis"] = (lunge, 0, 14 - crouch)
    p["chest"] = (lunge + lean * 0.6, 0, 24 - crouch * 0.9)
    p["head"] = (lunge + lean, 0, 31.5 - crouch * 0.9)
    p["footL"] = (2.5 + lunge * 0.4, -3.0, 0)
    p["footR"] = (-2.8 + lunge * 0.2, 3.2, 0)


def make_pose(kit, anim, i, n):
    p = default_pose()
    weapon = kit["weapon"]
    u = i / n
    tau = 2 * math.pi

    if weapon == "spear":
        p["handR"] = (1.5, 6, 17)
        p["wdir"] = (0.12, 0.05, 1)
    elif weapon == "bow":
        p["handL"] = (2.5, -5.5, 17)
        p["handR"] = (1, 6, 15.5)

    if anim == "idle":
        b = math.sin(tau * u) * 0.5
        p["chest"] = (0, 0, 24 + b)
        p["head"] = (0, 0, 31.5 + b)
        p["handL"] = add(p["handL"], (0, 0, b * 0.6))
        p["handR"] = add(p["handR"], (0, 0, b * 0.6))
        p["cape_sway"] = 0.3 + b * 0.4
    elif anim in ("walk", "run"):
        run = anim == "run"
        ph = tau * u
        stride, lift = (6.5, 3.2) if run else (4.2, 1.8)
        for side, off in (("footL", 0.0), ("footR", math.pi)):
            a = ph + off
            r = -2.6 if side == "footL" else 2.6
            p[side] = (stride * math.sin(a), r, lift * max(0.0, math.cos(a)))
        bob = (1.0 if run else 0.5) * math.cos(2 * ph)
        lean = 2.6 if run else 0.8
        crouch = 1.0 if run else 0.0
        p["pelvis"] = (0.4 if run else 0, 0, 14 - crouch + bob)
        p["chest"] = (lean, 0, 24 - crouch + bob)
        p["head"] = (lean * 1.25, 0, 31.5 - crouch + bob)
        swing = 4.0 if run else 2.4
        hz = 19 if run else 16
        p["handL"] = (1.5 - swing * math.sin(ph) + lean * 0.6, -6, hz)
        p["handR"] = (2.5 + swing * 0.5 * math.sin(ph) + lean * 0.6, 6, hz + (0 if weapon != "spear" else 1))
        if weapon == "bow":
            p["handL"] = (2.5 + lean * 0.6 - swing * 0.4 * math.sin(ph), -5.5, hz)
        p["twist"] = 0.15 * math.sin(ph)
        p["cape_sway"] = (2.6 if run else 1.0) + 0.6 * math.sin(2 * ph)
        if weapon == "sword":
            p["wdir"] = (0.8, 0.25, 0.1 if run else 0.05)
    elif anim in ("attack1", "attack2", "attack3", "heavy"):
        if weapon == "bow":
            return make_pose(kit, "bow", min(i, 3), 4)
        table = SPEAR_ATTACKS if weapon == "spear" else SWORD_ATTACKS
        frames = table[anim]
        apply_frame(p, frames[min(i, len(frames) - 1)])
        p["handL"] = (4, -3.5, 19)
        p["shield"] = "guard"
        p["cape_sway"] = 1.5
    elif anim == "block":
        sh = 0.4 if i == 1 else 0.0
        p["pelvis"] = (0, 0, 13)
        p["chest"] = (1, 0, 23)
        p["head"] = (1.2, 0, 30.5)
        p["footL"] = (2.5, -3.2, 0)
        p["footR"] = (-2.5, 3.2, 0)
        if kit["shield"]:
            p["handL"] = (5.5 + sh, -1.5, 20)
            p["shield"] = "front"
            p["handR"] = (0, 6.5, 19)
            p["wdir"] = (0.3, 0.3, 0.9) if weapon == "sword" else (0.12, 0.05, 1)
        else:
            p["handR"] = (5, 2, 23)
            p["handL"] = (5, -2, 22)
    elif anim == "bow":
        draw = [0.0, 0.5, 1.0, 0.0][i]
        p["pelvis"] = (0, 0, 14)
        p["chest"] = (0, 0, 24)
        p["head"] = (0.5, 0, 31.5)
        p["twist"] = 0.5
        p["footL"] = (2.5, -3.0, 0)
        p["footR"] = (-2.5, 3.0, 0)
        p["handL"] = (8.5, -1.5, 25) if i > 0 else (6, -3, 22)
        p["handR"] = [(4, 1, 24), (2, 2, 25.5), (-1, 3, 26), (-2, 6.5, 25)][i]
        p["bow_draw"] = draw
        p["force_bow"] = True
    elif anim == "hit":
        k = 1.0 if i == 0 else 0.5
        p["pelvis"] = (-1 * k, 0, 13.5)
        p["chest"] = (-2.5 * k, 0, 23.5)
        p["head"] = (-3.5 * k, 0, 30.3)
        p["handL"] = (-1, -7, 19)
        p["handR"] = (-1, 7.5, 19)
        p["wdir"] = (0.3, 0.6, 0.5)
    elif anim == "dodge":
        fr = [
            dict(pelvis=(2, 0, 10), chest=(6, 0, 16), head=(8.5, 0, 20.5), fl=(4, -3, 0), fr=(-4, 3, 1.5)),
            dict(pelvis=(3, 0, 7), chest=(7, 0, 10), head=(9.5, 0, 12.5), fl=(0, -3, 3), fr=(-3, 3, 4)),
            dict(pelvis=(2, 0, 8), chest=(5, 0, 13), head=(7.5, 0, 16.5), fl=(3, -3, 0), fr=(-1, 3, 2)),
            dict(pelvis=(1, 0, 12), chest=(3, 0, 21), head=(4, 0, 28), fl=(2, -3, 0), fr=(-3, 3, 0)),
        ][i]
        p["pelvis"], p["chest"], p["head"] = fr["pelvis"], fr["chest"], fr["head"]
        p["footL"], p["footR"] = fr["fl"], fr["fr"]
        p["handL"] = add(fr["chest"], (2, -4, -5))
        p["handR"] = add(fr["chest"], (2, 4, -5))
        p["wdir"] = (0.9, 0.1, -0.3)
        p["cape_sway"] = 3.0
    elif anim == "death":
        fr = [
            dict(pelvis=(-1, 0, 13), chest=(-3, 0, 22.5), head=(-4.5, 0, 29), fl=(1, -3, 0), fr=(-1, 3, 0)),
            dict(pelvis=(-1, 0, 8), chest=(-3, 0, 17), head=(-4, 0, 23.5), fl=(3, -3, 0), fr=(1, 3, 0)),
            dict(pelvis=(-2, 0, 5), chest=(-6, 0, 11), head=(-9, 0, 15), fl=(4, -3, 0), fr=(3, 3, 0)),
            dict(pelvis=(-2, 0, 3), chest=(-8.5, 0, 5), head=(-13, 0, 5), fl=(5, -3.5, 0), fr=(4, 3.5, 0)),
            dict(pelvis=(-2, 0, 2.5), chest=(-9, 0, 3), head=(-14, 0, 3), fl=(5, -3.5, 0), fr=(4.5, 3.5, 0)),
        ][i]
        p["pelvis"], p["chest"], p["head"] = fr["pelvis"], fr["chest"], fr["head"]
        p["footL"], p["footR"] = fr["fl"], fr["fr"]
        p["handL"] = add(fr["chest"], (-1, -7, -1 if i > 2 else 0))
        p["handR"] = add(fr["chest"], (-1, 7, -1 if i > 2 else 0))
        p["wdir"] = (0.2, 1, -0.2) if i > 2 else (0.4, 0.8, 0.2)
        p["death"] = i >= 3
        p["cape_sway"] = 0.5
    elif anim == "interact":
        a = tau * u
        p["chest"] = (1.5, 0, 23.5)
        p["head"] = (2, 0, 30.5)
        p["footL"] = (2.5, -3, 0)
        p["footR"] = (-2.5, 3, 0)
        p["handL"] = (7 + math.cos(a), -2.5, 19 + 2 * math.sin(a))
        p["handR"] = (7 + math.cos(a), 2.5, 19 + 2 * math.sin(a))
        p["show_weapon"] = False
        p["shield"] = "back"
    elif anim == "downed":
        p["pelvis"] = (0, 0, 5)
        p["chest"] = (1.5, 0, 13.5)
        p["head"] = (2.5, 0, 19.5)
        p["footL"] = (4, -3, 0)
        p["footR"] = (3.5, 3.5, 0)
        p["handL"] = (5, -5, 2)
        p["handR"] = (4, 6, 3)
        p["wdir"] = (0.3, 1, -0.1)
    if kit.get("shield_place") == "back":
        p["shield"] = "back"
    return p


# ── 그리기 ────────────────────────────────────────────
class Rig:
    def __init__(self, dir_index, scale, anchor):
        a = math.radians(dir_index * 45)
        self.ca, self.sa = math.cos(a), math.sin(a)
        self.s = scale
        self.anchor = anchor

    def ground(self, p):
        f, r, z = p
        return (f * self.ca - r * self.sa, f * self.sa + r * self.ca, z)

    def screen(self, p):
        g = self.ground(p)
        return (self.anchor[0] + g[0] * self.s, self.anchor[1] + (g[1] * GY_K - g[2] * Z_K) * self.s)

    def depth(self, p):
        return dot(self.ground(p), CAM)

    def facing_cam(self):
        return self.sa  # 앞쪽이 화면 아래(카메라 쪽)일수록 큼


class Canvas:
    def __init__(self, rig):
        self.rig = rig
        self.items = []

    def capsule(self, a, b, r, color, bias=0.0, shading=True):
        self.items.append((((self.rig.depth(a) + self.rig.depth(b)) / 2) + bias, "cap", (a, b, r, color, shading)))

    def disc(self, c, r, color, bias=0.0, shading=True):
        self.items.append((self.rig.depth(c) + bias, "disc", (c, r, color, shading)))

    def poly(self, pts, color, bias=0.0, rim=None):
        d = sum(self.rig.depth(p) for p in pts) / len(pts)
        self.items.append((d + bias, "poly", (pts, color, rim)))

    def pixel(self, c, color, bias=0.0):
        self.items.append((self.rig.depth(c) + bias, "px", (c, color)))

    def line(self, a, b, color, bias=0.0):
        self.items.append((((self.rig.depth(a) + self.rig.depth(b)) / 2) + bias, "line", (a, b, color)))

    def render(self, img):
        dr = ImageDraw.Draw(img)
        rig = self.rig
        s = rig.s
        for _, kind, args in sorted(self.items, key=lambda it: it[0]):
            if kind == "cap":
                a, b, r, color, shading = args
                pa, pb = rig.screen(a), rig.screen(b)
                rr = r * s
                if shading and rr >= 1.2:
                    _cap(dr, pa, pb, rr, shade(color, 0.62))
                    _cap(dr, (pa[0] - 0.4, pa[1] - 0.6), (pb[0] - 0.4, pb[1] - 0.6), rr - 0.7, color + (255,))
                else:
                    _cap(dr, pa, pb, rr, color + (255,))
            elif kind == "disc":
                c, r, color, shading = args
                pc = rig.screen(c)
                rr = r * s
                if shading and rr >= 1.5:
                    _disc(dr, pc, rr, shade(color, 0.62))
                    _disc(dr, (pc[0] - 0.5, pc[1] - 0.6), rr - 0.8, color + (255,))
                else:
                    _disc(dr, pc, rr, color + (255,))
            elif kind == "poly":
                pts, color, rim = args
                sp = [rig.screen(p) for p in pts]
                dr.polygon(sp, fill=color + (255,), outline=(rim + (255,)) if rim else None)
            elif kind == "px":
                c, color = args
                x, y = rig.screen(c)
                dr.point((round(x - 0.5), round(y - 0.5)), fill=color + (255,))
            elif kind == "line":
                a, b, color = args
                dr.line([rig.screen(a), rig.screen(b)], fill=color + (255,), width=1)


def _disc(dr, c, r, fill):
    if r < 0.6:
        dr.point((round(c[0]), round(c[1])), fill=fill)
        return
    dr.ellipse([c[0] - r, c[1] - r, c[0] + r - 1, c[1] + r - 1], fill=fill)


def _cap(dr, a, b, r, fill):
    if r < 0.8:
        dr.line([a, b], fill=fill, width=1)
        return
    dr.line([a, b], fill=fill, width=max(1, round(r * 2)))
    _disc(dr, a, r, fill)
    _disc(dr, b, r, fill)


def outline(img):
    px = img.load()
    w, h = img.size
    src = img.copy().load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0 and src[nx, ny] != OUTLINE:
                    px[x, y] = OUTLINE
                    break


def build(kit, pose, rig):
    cv = Canvas(rig)
    p = pose
    pel, chest, head = p["pelvis"], p["chest"], p["head"]
    tw = p["twist"]
    rv = (-math.sin(tw), math.cos(tw), 0)  # 몸통의 오른쪽 방향
    shR = add(chest, add(mul(rv, 5.0), (0, 0, 1.2)))
    shL = add(chest, add(mul(rv, -5.0), (0, 0, 1.2)))
    hipR = add(pel, (0, 2.5, -1))
    hipL = add(pel, (0, -2.5, -1))
    skin = kit["skin"]

    # 다리
    for hip, foot in ((hipL, p["footL"]), (hipR, p["footR"])):
        ankle = add(foot, (0, 0, 1.3))
        knee = two_bone(hip, ankle, 7.0, 7.0, (1, 0, 0.2) if not p["death"] else (0, 0, 1))
        cv.capsule(hip, knee, 2.0, skin)
        cv.capsule(knee, ankle, 1.8, kit["greave"])
        cv.disc(add(foot, (0.9, 0, 0.6)), 1.4, kit["sandal"], shading=False)

    # 치마(프테루게스)와 몸통
    cv.capsule(add(pel, (0, 0, 1.5)), add(pel, (0.3, 0, -3.5)), 3.7, kit["tunic"], bias=0.2)
    cv.capsule(add(pel, (0, 0, 2.0)), chest, 4.2, kit["armor"], bias=0.3)
    cv.capsule(chest, add(head, (0, 0, -3)), 1.5, skin)

    # 망토
    if kit.get("cape"):
        sw = p["cape_sway"]
        bl = add(pel, (-3.2 - sw, -5.2, -8.5))
        br = add(pel, (-3.2 - sw, 5.2, -8.5))
        cv.poly([add(shL, (-1.6, 0, 0)), add(shR, (-1.6, 0, 0)), br, bl], kit["cape"], bias=-0.6, rim=shade(kit["cape"], 0.7)[:3])

    # 화살통
    if kit.get("quiver"):
        top = add(chest, (-3.2, 2.0, 4.5))
        cv.capsule(top, add(chest, (-3.6, -1.5, -7)), 1.4, (110, 72, 40), bias=-0.4)
        cv.pixel(add(top, (0, 0, 1.2)), (230, 230, 220), bias=-0.3)

    # 팔
    for sh, hand, side in ((shL, p["handL"], -1), (shR, p["handR"], 1)):
        elbow = two_bone(sh, hand, 6.3, 6.3, (-0.4, side * 0.7, -0.6))
        cv.disc(sh, 2.0, kit["armor"], bias=0.1)
        cv.capsule(sh, elbow, 1.6, skin)
        cv.capsule(elbow, hand, 1.5, skin)
        cv.disc(hand, 1.3, skin, bias=0.15, shading=False)

    draw_head(cv, kit, head, rig)
    draw_weapon(cv, kit, p, shL, shR, chest)
    return cv


def draw_head(cv, kit, head, rig):
    skin = kit["skin"]
    vis = rig.facing_cam()
    cv.disc(head, 3.9, skin)
    helm = kit["helmet"]
    front = 1.0 if vis > -0.3 else 0.0
    if helm in ("crested", "plain"):
        cv.disc(add(head, (-0.5, 0, 0.9)), 4.3, kit["helm"], bias=0.05)
        if front:
            cv.disc(add(head, (1.9, 0, -0.7)), 2.4, skin, bias=0.3, shading=False)
        if kit["crest"]:
            n = 9 if helm == "crested" else 5
            h = 2.6 if helm == "crested" else 1.6
            for k in range(n):
                t = math.radians(25 + 130 * k / (n - 1))
                c = add(head, (4.4 * math.cos(t), 0, 3.9 + h * math.sin(t)))
                cv.disc(c, 1.5 if helm == "crested" else 1.2, kit["crest"], bias=0.12)
            if helm == "crested":
                cv.capsule(add(head, (-4.2, 0, 4)), add(head, (-6.2, 0, -3.5)), 1.2, kit["crest"], bias=-0.1)
    elif helm == "phrygian":
        cv.disc(add(head, (-0.4, 0, 1.0)), 4.3, kit["helm"], bias=0.05)
        cv.disc(add(head, (1.3, 0, 4.6)), 2.0, kit["helm"], bias=0.1)
        cv.capsule(add(head, (-3.9, 0, 3.4)), add(head, (-0.5, 0, 4.9)), 1.0, kit["crest"], bias=0.11, shading=False)
        if front:
            cv.disc(add(head, (1.9, 0, -0.9)), 2.4, skin, bias=0.3, shading=False)
    elif helm in ("cap", "cap_phrygian"):
        cv.disc(add(head, (-0.7, 0, 1.3)), 3.9, kit["helm"], bias=0.05)
        if helm == "cap_phrygian":
            cv.disc(add(head, (1.0, 0, 4.4)), 1.8, kit["helm"], bias=0.1)
        if front:
            cv.disc(add(head, (1.9, 0, -0.6)), 2.6, skin, bias=0.3, shading=False)
    if kit.get("beard") and vis > -0.5:
        cv.disc(add(head, (2.6, 0, -2.2)), 2.0, kit["hair"], bias=0.7, shading=False)
    if vis > 0.1:
        for side in (-1, 1):
            cv.pixel(add(head, (3.4, side * 1.4, 0.2)), (30, 20, 18), bias=0.9)


def draw_weapon(cv, kit, p, shL, shR, chest):
    weapon = kit["weapon"]
    hand_r, hand_l = p["handR"], p["handL"]
    use_bow = weapon == "bow" or p.get("force_bow")
    if p["show_weapon"]:
        if weapon == "sword":
            d = norm(p["wdir"])
            perp = norm(cross(d, (0, 0, 1))) if abs(d[2]) < 0.95 else (0, 1, 0)
            cv.capsule(add(hand_r, mul(d, -1.6)), add(hand_r, mul(d, 1.2)), 0.6, (90, 50, 30), bias=0.2, shading=False)
            g = add(hand_r, mul(d, 1.6))
            cv.line(add(g, mul(perp, -2.0)), add(g, mul(perp, 2.0)), (222, 178, 70), bias=0.21)
            cv.capsule(add(hand_r, mul(d, 2.0)), add(hand_r, mul(d, 13.0)), 0.8, (214, 214, 206), bias=0.2, shading=False)
            cv.line(add(hand_r, mul(d, 2.5)), add(hand_r, mul(d, 12.0)), (250, 250, 240), bias=0.22)
        elif weapon == "spear":
            d = norm(p["wdir"])
            cv.capsule(add(hand_r, mul(d, -9.0)), add(hand_r, mul(d, 15.0)), 0.6, (118, 80, 46), bias=0.2, shading=False)
            cv.capsule(add(hand_r, mul(d, 15.0)), add(hand_r, mul(d, 18.5)), 0.9, (226, 190, 96), bias=0.21, shading=False)
    if use_bow:
        draw_bow(cv, p, hand_l, hand_r)
    sh = kit.get("shield")
    if not sh:
        return
    place = p["shield"]
    if place == "back" or kit.get("shield_place") == "back":
        c, n = add(chest, (-4.6, 0, -1)), (-1, 0, 0.1)
    elif place == "front":
        c, n = add(hand_l, (1.0, 0, 0)), (1, 0, 0.05)
    elif place == "guard":
        c, n = add(hand_l, (1.2, -0.6, 0)), norm((0.85, -0.5, 0.05))
    else:
        c, n = add(hand_l, (0.4, -1.4, 1.5)), norm((0.25, -1, 0.1))
    draw_shield(cv, sh, c, norm(n))


def draw_shield(cv, colors, c, n):
    front, emblem, back = colors
    rig = cv.rig
    up = (0, 0, 1)
    u = cross(n, up)
    if length(u) < 0.1:
        u = (0, 1, 0)
    u = norm(u)
    v = norm(cross(u, n))
    R = 6.4
    pts = [add(c, add(mul(u, R * math.cos(t)), mul(v, R * math.sin(t)))) for t in (2 * math.pi * k / 18 for k in range(18))]
    facing = dot(rig.ground(n), CAM) > 0
    bias = 0.6 if facing else -0.2
    if facing:
        cv.poly(pts, front, bias=bias, rim=shade(front, 0.55)[:3])
        inner = [add(c, add(mul(u, 2.3 * math.cos(t)), mul(v, 2.3 * math.sin(t)))) for t in (2 * math.pi * k / 10 for k in range(10))]
        cv.poly([add(p, mul(n, 0.3)) for p in inner], emblem, bias=bias + 0.05)
    else:
        cv.poly(pts, back, bias=bias, rim=shade(back, 0.6)[:3])


def draw_bow(cv, p, hand_l, hand_r):
    rig = cv.rig
    fwd = (1, 0, 0)
    up = (0, 0, 1)
    pts = []
    for k in range(9):
        s = -1 + 2 * k / 8
        pts.append(add(hand_l, add(mul(up, s * 8.5), mul(fwd, 2.2 * (1 - s * s) - 0.6))))
    for a, b in zip(pts, pts[1:]):
        cv.capsule(a, b, 0.6, (120, 74, 38), bias=0.3, shading=False)
    draw = p.get("bow_draw", 0.0)
    nock = hand_r if draw > 0 else add(hand_l, (-1.2, 0, 0))
    cv.line(pts[0], nock, (232, 226, 210), bias=0.29)
    cv.line(pts[-1], nock, (232, 226, 210), bias=0.29)
    if draw > 0:
        cv.line(hand_r, add(hand_l, (2.8, 0, 0)), (200, 170, 120), bias=0.31)
        cv.pixel(add(hand_l, (3.2, 0, 0)), (230, 220, 200), bias=0.32)


def render_frame(kit, anim, i, n, dir_index, size=FRAME, anchor=ANCHOR, scale=None):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rig = Rig(dir_index, scale if scale else kit["scale"], anchor)
    pose = make_pose(kit, anim, i, n)
    build(kit, pose, rig).render(img)
    outline(img)
    return img


def make_sheet(name, kit, out_dir):
    total = sum(a[1] for a in ANIMS)
    sheet = Image.new("RGBA", (FRAME * total, FRAME * 8), (0, 0, 0, 0))
    meta = {"frame": [FRAME, FRAME], "anchor": list(ANCHOR), "dirs": 8, "anims": {}}
    col = 0
    for anim, n, fps, loop in ANIMS:
        meta["anims"][anim] = {"start": col, "frames": n, "fps": fps, "loop": loop}
        for i in range(n):
            for d in range(8):
                sheet.paste(render_frame(kit, anim, i, n, d), (FRAME * (col + i), FRAME * d))
        col += n
    sheet.save(out_dir / f"{name}.png")
    (out_dir / f"{name}.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))


def make_portrait(name, kit, out_dir):
    big = render_frame(kit, "idle", 0, 4, 2, size=200, anchor=(100, 230), scale=4.6)
    top = big.getbbox()[1]
    head = big.crop((0, top, 200, top + 70)).getbbox()
    cx = (head[0] + head[2]) // 2
    crop = big.crop((cx - 40, top - 4, cx + 40, top + 76)).resize((40, 40), Image.NEAREST)
    crop.save(out_dir / f"portrait_{name}.png")


def main():
    root = Path(sys.argv[1])
    out = root / "assets" / "sprites"
    out.mkdir(parents=True, exist_ok=True)
    # 그려 받은 기본 8방향(assets/source/<이름>_8dir.webp)이 있는 캐릭터는 gen_hero.py가 시트·초상화를 만든다 — 덮어쓰지 않는다
    drawn = {name for name in KITS if (root / f"assets/source/{name}_8dir.webp").exists()}
    for name, kit in KITS.items():
        if name in drawn:
            print("건너뜀(그려 받은 시트)", name)
            continue
        make_sheet(name, kit, out)
        print("시트", name)
    for name in ("odysseus_sword", "greek_sword", "greek_spear", "greek_archer"):
        if name not in drawn:
            make_portrait(name, KITS[name], root / "assets" / "ui")


if __name__ == "__main__":
    main()
