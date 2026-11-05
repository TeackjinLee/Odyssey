#!/usr/bin/env python3
"""기술 이펙트 한 장(fx_skills) 요청용 배치 그림과 받은 그림 자르기.

    python3 tools/fx_layout.py draw <출력 폴더> [묶음]          → layout.png(생성기에 첨부) + layout_labeled.png(사람용 설명)
    python3 tools/fx_layout.py cut <받은 그림> <출력 폴더> [묶음]  → 항목마다 가로 띠 png(게임 크기, 배경 투명)

묶음: skills(기본, 기술 이펙트·아이콘) · combat(전투 이펙트 F-hit·parry·block·dust·shout·takedown → fx.gd가 쓰는 .json도 쓴다)

한 장은 1536×1024, 배경 #282B35. 칸 배치는 아래 ITEMS 하나로 정한다(그림·자르기·프롬프트가 같은 값을 쓴다).
배치 그림의 회색 도형은 "이 칸에 이런 모양·크기로"를 알려 주는 자리표시일 뿐이다 — 생성기가 그대로 따라 그리지 않게
프롬프트에서 "회색 자리표시를 완성된 그림으로 바꿔라, 칸 테두리는 그리지 마라"라고 말한다.
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1536, 1024
BG = (0x28, 0x2B, 0x35)
EDGE = (0x36, 0x3A, 0x47)
GRAY = (0x74, 0x79, 0x88)
LIGHT = (0x9A, 0x9F, 0xAE)

# 이름, 칸 왼쪽 위(x, y), 칸 크기(w, h), 프레임 수, 게임 크기(w, h), 설명
ITEMS = [
    ("volley", (0, 0), (256, 192), 6, (128, 96), "일제 사격 화살비"),
    ("volley_fire", (0, 192), (256, 192), 6, (128, 96), "불화살 화살비"),
    ("decoy_stone", (0, 384), (128, 128), 4, (32, 32), "미끼 돌멩이 회전"),
    ("decoy_dust", (512, 384), (128, 128), 4, (32, 32), "돌멩이 떨어질 때 흙먼지", 12),
    ("javelin", (1024, 384), (256, 128), 2, (64, 32), "날아가는 창 · 땅에 꽂힌 창"),
    ("shield_glint", (0, 512), (256, 256), 4, (64, 64), "방패벽 번쩍임", 10),
    ("arrows_stuck", (1024, 512), (256, 256), 2, (64, 64), "땅에 꽂힌 화살 · 불붙은 화살"),
    ("skill_icons", (0, 768), (256, 256), 6, (48, 48), "아이콘: 미끼·방패벽·창·일제 사격·함성·부대 명령"),
]


# 전투 이펙트(ui_fx.md §1). 마지막 값은 fps — cut이 fx.gd용 <이름>.json도 쓴다
COMBAT = [
    ("hit", (0, 0), (192, 192), 4, (48, 48), "타격 불꽃", 18),
    ("block", (768, 0), (192, 192), 3, (48, 48), "방패에 막힘 불꽃(오른쪽으로 튐)", 16),
    ("parry", (0, 192), (256, 256), 4, (64, 64), "패링 섬광", 16),
    ("takedown", (0, 448), (192, 192), 4, (48, 48), "조용한 처치", 14),
    ("dust", (0, 640), (256, 128), 5, (64, 32), "구르기·착지 먼지", 14),
    ("shout", (0, 768), (256, 128), 6, (192, 96), "전투의 함성 고리(바닥 타원)", 14),
]
# UI(ui_fx.md §2·§3·§5). 아이콘은 한 칸씩 이름을 따로 둔다(ui_<이름>.png 한 장씩)
UI_ICONS = [["sword", "bow", "heavy", "block", "dodge", "aim"],
            ["follow", "hold", "focus", "retreat", "interact", "sneak"],
            ["suspect", "alert", "checkpoint", "oar", "sail", "rudder"]]
UI = [("icon_" + n, (c * 256, r * 256), (256, 256), 1, (24, 24), n) for r, row in enumerate(UI_ICONS) for c, n in enumerate(row)] + [
    ("cursor", (0, 768), (256, 256), 1, (16, 16), "조준 커서"),
    ("icon_land", (256, 768), (256, 256), 1, (24, 24), "상륙"),
    ("badge_shadow", (512, 768), (512, 256), 1, (128, 64), "칭호 배지 1"),
    ("badge_unseen", (1024, 768), (512, 256), 1, (128, 64), "칭호 배지 2"),
]
# HUD 틀. hud.gd가 9칸 나누기(StyleBoxTexture)로 늘려 쓰므로 게임 크기는 테두리 두께(2~4px·대화창12px)에 맞춘다
FRAMES = [
    ("logo", (0, 0), (1536, 384), 1, (256, 64), "타이틀 로고"),
    ("bar_hp", (0, 400), (800, 96), 1, (160, 19), "체력 바 틀"),
    ("bar_stamina", (0, 512), (800, 64), 1, (160, 12), "스태미나 바 틀"),
    ("slot", (880, 400), (136, 136), 1, (34, 34), "기술 슬롯 틀"),
    ("nameplate", (1056, 400), (480, 90), 1, (128, 24), "이름표"),
    ("dialogue", (18, 800), (1500, 186), 1, (500, 62), "대화창"),
]
# fx.gd 기준점(발 밑 등). 없으면 칸 가운데
ANCHOR = {"dust": (32, 23), "decoy_dust": (16, 23), "shield_glint": (32, 40)}
SETS = {"skills": ITEMS, "combat": COMBAT, "ui": UI, "frames": FRAMES}


def cells(item):
    name, (x0, y0), (cw, ch), n = item[:4]
    return [(x0 + i * cw, y0, cw, ch) for i in range(n)]


def ell(d, cx, cy, rx, ry, **kw):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], **kw)


def arrow(d, x, y, length=26, slant=(0.35, 1.0), col=GRAY, w=3):
    n = math.hypot(*slant)
    dx, dy = slant[0] / n * length, slant[1] / n * length
    d.line([x - dx, y - dy, x, y], fill=col, width=w)
    d.polygon([(x, y + 6), (x - 4, y - 2), (x + 4, y - 2)], fill=col)


def placeholder(d, name, i, x, y, cw, ch):
    cx, cy = x + cw // 2, y + ch // 2
    if name == "hit":
        r = [18, 34, 44, 50][i]
        for k in range(8):
            a = k * math.pi / 4
            r0 = 0 if i < 2 else r * 0.55
            d.line([cx + r0 * math.cos(a), cy + r0 * math.sin(a), cx + r * math.cos(a), cy + r * math.sin(a)], fill=LIGHT if i < 2 else GRAY, width=6 - i)
        if i < 2:
            ell(d, cx, cy, 14 + i * 8, 14 + i * 8, fill=LIGHT)
    elif name == "block":
        for k in range(6):
            a = -0.7 + k * 0.28
            l = 30 + i * 20
            d.line([cx - 30, cy, cx - 30 + l * math.cos(a), cy + l * math.sin(a)], fill=LIGHT if i == 0 else GRAY, width=4 - i)
    elif name == "parry":
        r = [30, 55, 80, 95][i]
        ell(d, cx, cy, r, r, outline=LIGHT if i < 2 else GRAY, width=8 - i * 2)
        for k in range(4):
            a = k * math.pi / 2 + math.pi / 4
            d.line([cx + r * math.cos(a), cy + r * math.sin(a), cx + (r + 25) * math.cos(a), cy + (r + 25) * math.sin(a)], fill=LIGHT, width=4)
    elif name == "takedown":
        d.arc([cx - 60, cy - 60, cx + 60, cy + 60], 200 + i * 20, 320 + i * 20, fill=GRAY, width=12 - i * 2)
        for k in range(i + 1):
            ell(d, cx + 40 - k * 25, cy - 40 + k * 10, 4, 4, fill=LIGHT)
    elif name == "dust":
        w = 40 + i * 20
        for k in (-1, 0, 1):
            ell(d, cx + k * w * 0.6, cy + 30, w * 0.5, 18 - i * 2, outline=GRAY, width=3 if i < 3 else 1)
    elif name == "shout":
        rx = 30 + i * 18
        ell(d, cx, cy, rx, rx / 2, outline=LIGHT if i < 3 else GRAY, width=max(1, 8 - i))
    elif name.startswith("icon_") or name == "cursor":
        if name != "cursor":
            d.rounded_rectangle([x + 28, y + 28, x + cw - 28, y + ch - 28], 24, outline=GRAY, width=4)
            ell(d, cx, cy, 55, 55, fill=GRAY)
        else:
            ell(d, cx, cy, 70, 70, outline=GRAY, width=8)
            for a in range(4):
                t = a * math.pi / 2
                d.line([cx + 50 * math.cos(t), cy + 50 * math.sin(t), cx + 100 * math.cos(t), cy + 100 * math.sin(t)], fill=GRAY, width=8)
    elif name.startswith("badge"):
        d.rounded_rectangle([x + 40, y + 50, x + cw - 40, y + ch - 50], 40, fill=GRAY)
        ell(d, cx, cy, 70, 70, fill=LIGHT)
    elif name == "logo":
        d.rounded_rectangle([x + 200, y + 80, x + cw - 200, y + ch - 80], 30, fill=GRAY)
    elif name.startswith("bar_") or name in ("nameplate", "dialogue", "slot"):
        t = 8 if name != "dialogue" else 12
        d.rectangle([x + 6, y + 6, x + cw - 7, y + ch - 7], outline=GRAY, width=t)
    elif name.startswith("volley"):
        gy = y + ch - 40
        ell(d, cx, gy, 100, 40, outline=GRAY, width=2)
        spots = [(-60, -10), (-25, 15), (10, -20), (45, 5), (70, -12), (-10, 0), (30, 22), (-45, 20)]
        if i < 4:   # 떨어지는 중: 위에서 비스듬히
            k = i / 3.0
            for sx, sy in spots:
                arrow(d, cx + sx - 30 * (1 - k), gy + sy - 95 * (1 - k))
        elif i == 4:   # 꽂히는 순간: 흙 튐
            for sx, sy in spots:
                d.line([cx + sx, gy + sy, cx + sx - 6, gy + sy - 22], fill=GRAY, width=3)
                ell(d, cx + sx, gy + sy, 7, 3, outline=LIGHT, width=2)
        else:   # 꽂혀 있음
            for sx, sy in spots:
                d.line([cx + sx, gy + sy, cx + sx - 6, gy + sy - 22], fill=GRAY, width=3)
        if name == "volley_fire":
            for sx, sy in spots[:5]:
                ell(d, cx + sx - (30 * (1 - i / 3.0) if i < 4 else 6), gy + sy - (95 * (1 - i / 3.0) if i < 4 else 22) - 6, 5, 7, fill=LIGHT)
    elif name == "decoy_stone":
        ell(d, cx, cy, 14, 11, fill=GRAY)
        a = i * math.pi / 2
        d.line([cx, cy, cx + 10 * math.cos(a), cy + 8 * math.sin(a)], fill=BG, width=3)
    elif name == "decoy_dust":
        r = 16 + i * 12
        ell(d, cx, cy + 30, r, r * 0.45, outline=GRAY, width=3 if i < 3 else 1)
        if i == 0:
            ell(d, cx, cy + 22, 8, 6, fill=GRAY)
    elif name == "javelin":
        if i == 0:
            d.line([x + 30, cy, x + cw - 40, cy], fill=GRAY, width=5)
            d.polygon([(x + cw - 20, cy), (x + cw - 44, cy - 9), (x + cw - 44, cy + 9)], fill=GRAY)
        else:
            d.line([cx - 50, cy - 40, cx + 10, cy + 30], fill=GRAY, width=5)
            ell(d, cx + 14, cy + 34, 22, 8, outline=GRAY, width=2)
    elif name == "shield_glint":
        d.arc([cx - 70, cy - 80, cx + 70, cy + 80], 200, 340, fill=GRAY, width=8)
        k = [0.3, 1.0, 0.7, 0.3][i]
        s = 30 * k
        d.line([cx - s, cy - 60, cx + s, cy - 60], fill=LIGHT, width=3)
        d.line([cx, cy - 60 - s, cx, cy - 60 + s], fill=LIGHT, width=3)
    elif name == "arrows_stuck":
        ell(d, cx, cy + 50, 60, 20, outline=GRAY, width=2)
        for sx in (-30, 0, 28):
            d.line([cx + sx, cy + 50, cx + sx - 14, cy - 10], fill=GRAY, width=4)
            if i == 1:
                ell(d, cx + sx - 14, cy - 18, 8, 12, fill=LIGHT)
    elif name == "skill_icons":
        d.rounded_rectangle([x + 28, y + 28, x + cw - 28, y + ch - 28], 24, outline=GRAY, width=4)
        if i == 0:    # 미끼: 손에 든 돌
            ell(d, cx, cy, 30, 24, fill=GRAY)
        elif i == 1:  # 방패벽: 둥근 방패 셋
            for k in (-50, 0, 50):
                ell(d, cx + k, cy, 30, 40, outline=GRAY, width=6)
        elif i == 2:  # 창
            d.line([cx - 70, cy + 60, cx + 60, cy - 60], fill=GRAY, width=8)
        elif i == 3:  # 화살비
            for k in (-50, -15, 20, 55):
                arrow(d, cx + k, cy + 40, 70, (0.3, 1.0), GRAY, 6)
        elif i == 4:  # 함성: 투구와 소리
            d.pieslice([cx - 45, cy - 50, cx + 45, cy + 40], 180, 360, fill=GRAY)
            for r in (60, 80):
                d.arc([cx - r, cy - r, cx + r, cy + r], 300, 60, fill=GRAY, width=5)
        else:         # 부대 명령: 깃발
            d.line([cx - 40, cy + 70, cx - 40, cy - 70], fill=GRAY, width=7)
            d.polygon([(cx - 40, cy - 70), (cx + 60, cy - 45), (cx - 40, cy - 20)], fill=GRAY)


def draw(out_dir, items=ITEMS):
    os.makedirs(out_dir, exist_ok=True)
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    for it in items:
        for i, (x, y, cw, ch) in enumerate(cells(it)):
            d.rectangle([x, y, x + cw - 1, y + ch - 1], outline=EDGE)
            placeholder(d, it[0], i, x, y, cw, ch)
    im.save(os.path.join(out_dir, "layout.png"))
    lab = im.copy()
    d = ImageDraw.Draw(lab)
    fp = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
    font = ImageFont.truetype(fp, 15) if os.path.exists(fp) else ImageFont.load_default()
    for it in items:
        name, (x0, y0), (cw, ch), n, game, desc = it[:6]
        d.rectangle([x0, y0, x0 + cw * n - 1, y0 + ch - 1], outline=(255, 200, 80), width=3)
        d.text((x0 + 6, y0 + 4), f"{name} {n}칸 {cw}×{ch}→{game[0]}×{game[1]}", fill=(255, 220, 120), font=font)
        d.text((x0 + 6, y0 + 22), desc, fill=(255, 220, 120), font=font)
    lab.save(os.path.join(out_dir, "layout_labeled.png"))
    print(out_dir, "layout.png, layout_labeled.png")


def cut(src, out_dir, items=ITEMS, tol=26):
    os.makedirs(out_dir, exist_ok=True)
    im = Image.open(src).convert("RGB").resize((W, H), Image.LANCZOS)
    for it in items:
        name, _, _, n, (gw, gh) = it[:5]
        strip = Image.new("RGBA", (gw * n, gh), (0, 0, 0, 0))
        for i, (x, y, cw, ch) in enumerate(cells(it)):
            c = im.crop((x, y, x + cw, y + ch)).convert("RGBA")
            px = c.load()
            for yy in range(ch):
                for xx in range(cw):
                    r, g, b, _ = px[xx, yy]
                    if abs(r - BG[0]) + abs(g - BG[1]) + abs(b - BG[2]) < tol:
                        px[xx, yy] = (0, 0, 0, 0)
            small = c.convert("RGBa").resize((gw, gh), Image.LANCZOS).convert("RGBA")
            sp = small.load()
            for yy in range(gh):
                for xx in range(gw):
                    r, g, b, a = sp[xx, yy]
                    sp[xx, yy] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
            strip.paste(small, (i * gw, 0))
        p = os.path.join(out_dir, name + ".png")
        strip.save(p)
        if len(it) > 6:   # fx.gd용 json
            with open(os.path.join(out_dir, name + ".json"), "w") as f:
                json.dump({"frame": [gw, gh], "frames": n, "fps": it[6], "anchor": list(ANCHOR.get(name, (gw / 2, gh / 2)))}, f)
        print(p, strip.size)


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "draw":
        draw(sys.argv[2], SETS[sys.argv[3] if len(sys.argv) > 3 else "skills"])
    elif len(sys.argv) >= 4 and sys.argv[1] == "cut":
        cut(sys.argv[2], sys.argv[3], SETS[sys.argv[4] if len(sys.argv) > 4 else "skills"])
    else:
        print(__doc__)
