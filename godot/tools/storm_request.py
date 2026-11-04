#!/usr/bin/env python3
"""챕터 2 폭풍 그림 요청 묶음(Codex·직접 받기): 목표 장면 1 · 바다 무늬 2(폭풍·잔잔) · 폭풍 이펙트 시트 1.

    python3 tools/storm_request.py .        # godot 폴더에서

출력: docs/sprite_request/storm_requests/
  - style_env.png · style_fx.png       화풍 기준(assets/source/troy_env·troy_fire를 png로)
  - game_storm_now.png · game_calm_now.png   지금 게임 화면(HUD 없음) — 카메라 각도·크기 기준.
        다시 찍기: godot --path . -- --chapter=2 --start=storm --nohud --shot=<경로> --shot-at=9
                   (잔잔한 바다는 --start=lotus --shot-at=4). 이 스크립트는 덮어쓰지 않는다
  - <요청>/prompt.txt                  붙여 넣을 프롬프트
  - storm_fx/guide.png                 이펙트 칸 자리 안내(이름 없음) · guide_labeled.png(사람용, 붙이지 않는다)
  - storm_fx/boxes.json                받은 그림에서 자를 칸 [x0, y0, x1, y1] (프레임마다)
  - run.sh                             넷을 Codex로 동시에 돌린다
이펙트 칸은 게임 픽셀 × 2로 받는다(받으면 반으로 줄인다). 바다 무늬도 그림 한 점 = 2×2 픽셀로 받는다.
"""
import json
import math
import os
import random
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont

BG = (40, 43, 53, 255)
W, H = 1536, 1024
MODEL = "gpt-6.1-sol"
GAP = 16

HEAD = """Use your built-in image generation tool to create exactly ONE image from the prompt below.
Do not write code or edit any files. When the image is generated, reply with its saved file path only.
"""

# 이펙트 시트: 줄마다 [(이름, 프레임 수, 칸 w, 칸 h, 설명)] — 한 줄에 여러 묶음, 왼쪽부터
FX_ROWS = [
    (32, [("wave_crash", 6, 224, 224,
           "WAVE CRASH against a ship's side, 6 frames: a dark blue-green wave rises from the lower LEFT of the cell, "
           "curls over with a white foam lip, smashes upward into a tall burst of white and pale-blue spray and droplets "
           "that leans to the right, then the spray falls and scatters into small drops. The ship is NOT drawn, only the water.")]),
    (296, [("whitecap_a", 4, 160, 80,
            "WHITECAP, 4 looping frames: a short breaking wave crest seen from above at the game angle: a dark wave hump "
            "with a white foam lip that curls, breaks into foam and fades back. Wide and flat (2:1)."),
           ("whitecap_b", 4, 160, 80,
            "WHITECAP variant B, 4 looping frames: a longer crest that breaks from left to right, leaving a trail of foam.")]),
    (416, [("bow_spray", 4, 192, 112,
            "BOW SPRAY, 4 frames: a fan of white spray and droplets thrown up and to the right, as a ship's bow cuts "
            "through a wave (the ship is not drawn)."),
           ("rain_splash", 6, 64, 32,
            "RAIN SPLASH on water, 6 frames, tiny: a droplet hits, a small crown splash, then a flat 2:1 ring that widens and fades.")]),
    (568, [("lightning", 3, 160, 416,
            "LIGHTNING BOLT, 3 different bolts (not an animation): tall jagged white bolts with a thin violet-blue edge and "
            "a few short forks, from the top of the cell down to the bottom, no glow halo baked in.")]),
]
# 번개 오른쪽 빈자리(568~984)에 쌓는 줄 — x는 번개 다음부터
FX_SIDE = [
    (568, [("foam_streak", 2, 384, 96,
            "FOAM STREAK, 2 variants: long ragged streaks and patches of white foam floating on the sea surface, "
            "stretched horizontally, broken into lace-like pieces with small holes.")]),
    (704, [("spray_drift", 4, 192, 96,
            "WIND SPRAY, 4 frames: a thin sheet of wind-blown sea spray blowing from left to right, wispy dotted mist that "
            "appears, streams across and thins out.")]),
    (840, [("rain_streak", 6, 32, 128,
            "RAIN STREAKS, 6 variants: single slanted rain streaks (leaning a little to the left at the bottom), "
            "pale blue-white, some longer, some broken into two.")]),
]


def layout():
    boxes = {}
    descs = []
    for y, groups in FX_ROWS:
        x = 56
        for name, n, cw, ch, desc in groups:
            boxes[name] = []
            for i in range(n):
                boxes[name].append([x, y, x + cw, y + ch])
                x += cw + GAP
            x += GAP * 3
            descs.append((name, n, cw, ch, desc))
            assert boxes[name][-1][2] <= W - GAP, (name, boxes[name][-1])
    lx = boxes["lightning"][-1][2] + GAP * 4
    for y, groups in FX_SIDE:
        x = lx
        for name, n, cw, ch, desc in groups:
            boxes[name] = []
            for i in range(n):
                boxes[name].append([x, y, x + cw, y + ch])
                x += cw + GAP
            descs.append((name, n, cw, ch, desc))
            assert boxes[name][-1][2] <= W - GAP and boxes[name][-1][3] <= H - GAP, (name, boxes[name][-1])
    return boxes, descs


# ---------- 자리 안내용 대충 그림 (Codex가 칸 자리·크기·프레임 흐름만 보게) ----------
DEEP = (24, 52, 78, 255)
MIDW = (46, 92, 120, 255)
FOAM = (226, 236, 242, 255)
PALE = (150, 196, 222, 255)
VIOLET = (150, 140, 230, 255)


def blob(d, cx, cy, rx, ry, col):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)


def draw_cell(d, name, i, n, box, rnd):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    t = i / max(1, n - 1)
    if name == "wave_crash":
        base = y1 - 10
        rise = [0.3, 0.6, 0.9, 1.0, 0.7, 0.35][i]
        top = base - h * 0.5 * rise
        lip = x0 + w * (0.35 + 0.2 * min(1.0, rise))
        # 왼쪽 아래에서 솟아 오른쪽으로 말리는 물마루(몸통), 위에 흰 거품 입술
        body = [(x0 + 8, base), (x0 + w * 0.15, base - h * 0.12 * rise), (lip - w * 0.12, top + 6),
                (lip, top), (lip + w * 0.08, top + h * 0.08), (lip + w * 0.02, top + h * 0.14),
                (x0 + w * 0.7, base - 4), (x0 + w * 0.85, base)]
        d.polygon(body, fill=DEEP)
        d.polygon([(lip - w * 0.1, top + 8), (lip, top), (lip + w * 0.06, top + h * 0.06), (lip - w * 0.02, top + h * 0.1)],
                  fill=MIDW)
        if i >= 1:
            d.ellipse([lip - w * 0.06, top - 6, lip + w * 0.09, top + 8], fill=FOAM)
        if i >= 2:
            spread = [0, 0, 0.35, 0.75, 1.0, 0.9][i]
            fall = max(0, i - 3) * 22
            for k in range(int(45 * spread)):
                a = rnd.uniform(-2.2, -0.4)
                r = rnd.uniform(0.15, 1.0) * h * 0.6 * spread
                px = lip + math.cos(a) * r * 0.9
                py = top + math.sin(a) * r + fall
                sz = rnd.choice([3, 4, 6])
                d.rectangle([px, py, px + sz, py + sz], fill=rnd.choice([FOAM, PALE]))
    elif name.startswith("whitecap"):
        cx, cy = x0 + w * 0.5, y0 + h * 0.6
        blob(d, cx, cy, w * 0.38, h * 0.22, DEEP)
        k = [0.4, 1.0, 0.8, 0.3][i]
        long = 0.32 if name.endswith("b") else 0.2
        blob(d, cx - w * 0.05 + (i * 6 if name.endswith("b") else 0), cy - h * 0.12, w * long * k + 4, h * 0.08 * k + 2, FOAM)
    elif name == "bow_spray":
        k = [0.3, 0.8, 1.0, 0.6][i]
        for j in range(int(30 * k) + 4):
            a = rnd.uniform(-1.4, -0.1)
            r = rnd.uniform(0.2, 1.0) * w * 0.5 * k
            px, py = x0 + 20 + math.cos(a) * r, y1 - 16 + math.sin(a) * r * 0.6
            s = rnd.choice([3, 4])
            d.rectangle([px, py, px + s, py + s], fill=rnd.choice([FOAM, PALE]))
    elif name == "rain_splash":
        cx, cy = x0 + w / 2, y0 + h * 0.62
        if i < 2:
            d.rectangle([cx - 1, cy - 8 + i * 6, cx + 1, cy - 4 + i * 6], fill=FOAM)
        else:
            r = 6 + (i - 2) * 6
            d.ellipse([cx - r, cy - r / 2, cx + r, cy + r / 2], outline=PALE if i < 5 else MIDW, width=2)
    elif name == "lightning":
        x = x0 + w * rnd.uniform(0.35, 0.65)
        y = y0 + 4
        pts = [(x, y)]
        while y < y1 - 10:
            y += rnd.uniform(18, 40)
            x = min(x1 - 12, max(x0 + 12, x + rnd.uniform(-26, 26)))
            pts.append((x, min(y, y1 - 6)))
            if rnd.random() < 0.18:
                fx, fy = x + rnd.choice([-1, 1]) * 40, y + 50
                d.line([(x, y), (fx, fy)], fill=VIOLET, width=3)
        d.line(pts, fill=VIOLET, width=7)
        d.line(pts, fill=FOAM, width=3)
    elif name == "foam_streak":
        for j in range(26):
            px = x0 + 10 + rnd.uniform(0, w - 40)
            py = y0 + h * 0.5 + rnd.uniform(-1, 1) * h * 0.25 * (1 - abs(px - x0 - w / 2) / w)
            blob(d, px, py, rnd.uniform(6, 22), rnd.uniform(2, 5), FOAM if j % 3 else PALE)
    elif name == "spray_drift":
        k = [0.3, 1.0, 0.9, 0.4][i]
        for j in range(int(50 * k)):
            px = x0 + rnd.uniform(0, w * (0.4 + 0.6 * t + 0.0001))
            py = y0 + h * 0.5 + rnd.uniform(-1, 1) * h * 0.3
            d.rectangle([px, py, px + 2, py + 2], fill=PALE)
    elif name == "rain_streak":
        ln = rnd.uniform(0.5, 0.95) * h
        sx = x0 + w * 0.65
        d.line([(sx, y0 + 6), (sx - ln * 0.18, y0 + 6 + ln)], fill=PALE, width=3)


def make_guide(boxes, out_dir):
    rnd = random.Random(7)
    img = Image.new("RGBA", (W, H), BG)
    for name, cells in boxes.items():
        for i, b in enumerate(cells):
            layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            draw_cell(ImageDraw.Draw(layer), name, i, len(cells), b, rnd)
            img.alpha_composite(layer.crop(b), (b[0], b[1]))   # 칸 밖으로 넘친 것은 자른다
    img.convert("RGB").save(os.path.join(out_dir, "guide.png"))
    lab = img.copy()
    dl = ImageDraw.Draw(lab)
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    for name, cells in boxes.items():
        for i, b in enumerate(cells):
            dl.rectangle(b, outline=(255, 80, 200, 255), width=1)
        dl.text((cells[0][0] + 2, cells[0][1] + 2), name, fill=(255, 230, 120, 255), font=font)
    lab.convert("RGB").save(os.path.join(out_dir, "guide_labeled.png"))


# ---------- 프롬프트 ----------
STYLE = """Style: 2D pixel art, crisp hard-edged pixels, no anti-aliasing blur, no soft airbrush glow, no photo texture,
limited palette, matching the outline, palette and pixel density of the attached style reference."""

MOOD = HEAD + """Attached images:
1) style_env.png = the STYLE reference (our isometric night Troy sheet: palette, outline, pixel density).
2) game_storm_now.png = the CURRENT game screen of the storm scene (camera angle, zoom, ship size). It looks flat and cheap:
   the sea is only noise stripes and the rain is thin lines. Make the TARGET LOOK of this same screen, much better.
Make the image 1536x1024 (landscape).

Pixel art game screen mock-up, NO user interface: a violent night storm at sea in ancient Greece, seen from the SAME
2:1 isometric game camera as game_storm_now.png (looking down about 30 degrees, no horizon, no sky visible, only sea surface).
A small Greek galley (one mast, sail furled and lashed to the yard, a row of oars, dark wet wooden hull, about the same size
and place as in game_storm_now.png, bow to the upper right) struggles in the middle. A big wave breaks against its LEFT side
and throws a tall burst of white spray over the deck.
The sea fills the whole frame: heavy rolling swells running diagonally across the screen, deep near-black navy troughs,
steel-blue faces, grey-blue crests with ragged white foam lips, long lace-like foam streaks blown along the wind,
scattered whitecaps breaking, wind-blown spray mist. Slanted rain streaks over everything, small rain splashes on the water.
Big moving shadows of storm clouds darken parts of the sea. A lightning strike far to the upper left lights one patch of the sea
pale cold blue-white for an instant (the light falls on the water, the bolt itself enters from the top edge).
A couple of dark jagged sea rocks with foam around them, like the rocks in game_storm_now.png.
Colors: cold and dark: navy, slate, steel blue, grey-green foam shadows, off-white foam; the only warm color is a tiny
lantern on the ship. Keep it readable: the ship and the breaking waves must stand out from the dark sea.
""" + STYLE + "\nNo text, no letters, no UI, no frame border, no characters' faces close-up."

SEA_COMMON = """Make the image 1024x1024 (square). It is a SEAMLESS TILEABLE TEXTURE: the left edge must continue exactly into the
right edge and the top edge into the bottom edge, so that it can be repeated in a grid without any visible seam.
Seen from the game camera of game_*_now.png: 2:1 isometric, looking down about 30 degrees, NO horizon, NO sky,
so waves look squashed vertically: crests are long horizontally and thin vertically.
Draw it as pixel art at HALF resolution blown up 2x: every art pixel is a clean 2x2 block of image pixels (512x512 art pixels).
Even overall brightness: no light source spot, no vignette, no dark corners, no gradient across the image,
no objects, no ship, no rocks, no land, no foam lines along any edge. Only open water.
""" + STYLE + "\nNo text, no labels, no grid lines."

SEA_STORM = HEAD + """Attached images:
1) style_env.png = the STYLE reference (palette, outline, pixel density).
2) game_storm_now.png = the current game storm screen (camera angle and scale). Its sea (noise stripes) is what this replaces.

Pixel art texture of a ROUGH STORMY SEA SURFACE at night.
""" + SEA_COMMON + """
Content: big rolling swells, about 3 to 4 swell rows across the image, each swell a broad band with a dark near-black navy trough,
a steel-blue face catching dim light, and a ragged grey-white foam crest broken into curling pieces; between them smaller chop,
lace-like foam streaks and bubbles stretched horizontally. Palette of about 8 colors from near-black navy (#0a1220) through
slate and steel blue to off-white foam (#d8e2ea). Busy but readable, foam covers about 15 percent of the surface.
"""

SEA_CALM = HEAD + """Attached images:
1) style_env.png = the STYLE reference (palette, outline, pixel density).
2) game_calm_now.png = the current game sea on a calm night (camera angle and scale). Its sea (noise stripes) is what this replaces.

Pixel art texture of a CALM SEA SURFACE at night under the moon (the same sea as a stormy version, just quiet).
""" + SEA_COMMON + """
Content: gentle low swells, many short soft horizontal ripple lines in deep blue and slate blue, a few thin pale-blue ripple
highlights, very few tiny moonlight glints (2 art pixels wide). No foam. Palette of about 6 colors from deep navy (#131f3a)
to pale blue (#7f9fc4). Quiet and low contrast so ships and islands stand out on it.
"""


def fx_prompt(descs):
    rows = "\n".join(f"- {name}: {n} cell(s) of {cw}x{ch} px. {desc}" for name, n, cw, ch, desc in descs)
    return HEAD + f"""Attached images:
1) style_fx.png = the STYLE reference for effects (our pixel art fire sheet: outline, palette, pixel density).
2) guide.png = a LAYOUT GUIDE (1536x1024) with rough placeholder drawings: it shows WHERE each effect frame goes and HOW BIG it is.
Make the image 1536x1024 (landscape), the same size as guide.png.

Pixel art storm-at-sea effects sprite sheet for a 2:1 isometric game. REDRAW every placeholder of guide.png as finished
effect art in the SAME place and within the SAME cell size, so each frame can be cut out with the same boxes.
The placeholders are crude: copy only their POSITION, SIZE and the frame-by-frame progression, not their look.
Solid flat dark background #282B35 everywhere else (also inside the cells around the effect). Every frame separated by
empty space, nothing crosses from one cell into the next. Frames of one effect go left to right.

Effects, top to bottom (as in guide.png):
{rows}

Water colors: deep blue-green and steel blue for wave bodies, white and pale cold blue for foam and spray, crisp dark outline
only on the wave bodies (spray and droplets have no outline). Lightning: white core, violet-blue edge.
""" + STYLE + "\nNo text, no labels, no grid lines, no cell borders, no ship, no characters."


README = """# 챕터 2 폭풍 그림 요청 묶음 (Codex·직접 받기)

폭풍 구간(`chapter2_ismaros.gd` 폭풍)이 코드로 그린 임시 화면이라 밋밋하다 — 바다는 소음 줄무늬, 비는 가는 선.
그림 넷을 받아 바꾼다. 다시 만들기: `python3 tools/storm_request.py .` (godot 폴더에서, 게임 화면 png는 덮어쓰지 않는다)

| 폴더 | 받을 이름 | 내용 | 첨부(순서대로) | 쓰는 곳 |
|---|---|---|---|---|
| `storm_mood` | `storm_mood.png` | **목표 장면** — 같은 카메라로 본 폭풍 바다(UI 없음) | `style_env.png`, `game_storm_now.png` | 색·밝기 기준. 셰이더·비·번개 색을 여기에 맞춘다 → `docs/references/mood/` |
| `sea_storm` | `sea_storm.png` | 거친 바다 **이음매 없는 무늬** 1024² | `style_env.png`, `game_storm_now.png` | `water.gdshader`가 월드 좌표로 깔고 두 겹으로 흘린다 |
| `sea_calm` | `sea_calm.png` | 잔잔한 밤바다 무늬 1024² (같은 바다) | `style_env.png`, `game_calm_now.png` | 평소 바다. 폭풍 세기(storm 0~1)에 따라 calm → storm으로 섞는다 |
| `storm_fx` | `storm_fx.png` | 폭풍 이펙트 시트(칸 자리 = `guide.png`) | `style_fx.png`, `storm_fx/guide.png` | 아래 표 |

`storm_fx` 칸(받은 그림 픽셀, 게임에서는 반 크기):

| 이름 | 프레임 | 칸 | 쓰는 곳 |
|---|---|---|---|
| `wave_crash` | 6 | 224×224 | 파도가 뱃전을 칠 때 맞은 쪽에(왼쪽에서 오는 그림, 반대쪽은 뒤집기) |
| `whitecap_a`·`_b` | 4·4 | 160×80 | 카메라 둘레 바다에 흩어져 부서지는 파도머리 |
| `bow_spray` | 4 | 192×112 | 배가 빠를 때 뱃머리 물보라 |
| `rain_splash` | 6 | 64×32 | 빗방울이 바다에 떨어지는 자리 |
| `lightning` | 3종 | 160×416 | 번개 칠 때 화면 위쪽 아무 데나(지금은 화면 번쩍임만) |
| `foam_streak` | 2종 | 384×96 | 바람 방향으로 흘러가는 거품 띠 |
| `spray_drift` | 4 | 192×96 | 바람에 날리는 물안개 |
| `rain_streak` | 6종 | 32×128 | 지금의 선 빗줄기를 바꾼다 |

## 받는 법

- **Codex로 한꺼번에**: `./run.sh` (하나만: `./run.sh sea_storm`) → 끝나면 요청마다 생성된 그림 경로가 찍힌다.
- **직접**: 폴더의 `prompt.txt` 전체를 붙여 넣고, 표의 첨부를 **순서대로** 붙인다. `guide_labeled.png`(이름표 판)는 **붙이지 않는다**.
- 후보는 1장씩. 마음에 드는 것을 표의 "받을 이름"으로 `assets/source/`에 넣고 Claude에게 "폭풍 그림 넣어 줘".

## 검사

- `storm_mood`: 카메라가 게임과 같은가(수평선·하늘이 없고 위에서 비스듬히), UI·글자가 없는가, 배·부서지는 파도가 어두운 바다에서 보이는가.
- `sea_*`: 2×2로 이어 붙여 봐서 이음매가 보이지 않는가(조금 보이면 Claude가 고친다), 한쪽만 밝거나 어둡지 않은가, 물건이 없는가.
  둘이 같은 바다처럼 보이는가(색 계열·점 크기).
- `storm_fx`: `guide.png`와 겹쳐서 칸 안에 들어오는가, 배경이 단색 `#282B35`인가, 칸끼리 넘치지 않는가, 배를 그려 넣지 않았는가.
"""


def main(root: str) -> None:
    out = os.path.join(root, "docs/sprite_request/storm_requests")
    os.makedirs(out, exist_ok=True)
    for src, dst in (("assets/source/troy_env.webp", "style_env.png"), ("assets/source/troy_fire.webp", "style_fx.png")):
        Image.open(os.path.join(root, src)).convert("RGB").save(os.path.join(out, dst))
    for name in ("game_storm_now.png", "game_calm_now.png"):
        if not os.path.exists(os.path.join(out, name)):
            print("없음(직접 찍어 넣기):", name)
    boxes, descs = layout()
    reqs = {"storm_mood": MOOD, "sea_storm": SEA_STORM, "sea_calm": SEA_CALM, "storm_fx": fx_prompt(descs)}
    for name, text in reqs.items():
        os.makedirs(os.path.join(out, name), exist_ok=True)
        with open(os.path.join(out, name, "prompt.txt"), "w") as f:
            f.write(text)
    fx_dir = os.path.join(out, "storm_fx")
    make_guide(boxes, fx_dir)
    with open(os.path.join(fx_dir, "boxes.json"), "w") as f:
        json.dump({"save_as": "storm_fx.png", "scale": 0.5, "items": boxes}, f, indent=1)
    attach = {
        "storm_mood": "-i ../style_env.png -i ../game_storm_now.png",
        "sea_storm": "-i ../style_env.png -i ../game_storm_now.png",
        "sea_calm": "-i ../style_env.png -i ../game_calm_now.png",
        "storm_fx": "-i ../style_fx.png -i guide.png",
    }
    lines = ["#!/bin/zsh",
             "# 폭풍 그림 요청 넷을 Codex로 동시에 돌린다. 하나만: ./run.sh sea_storm",
             'cd "$(dirname "$0")"', 'want=("$@")']
    for name, a in attach.items():
        lines.append(f'[[ ${{#want}} -eq 0 || ${{want[(Ie)]{name}}} -gt 0 ]] && (cd {name} && codex exec -m {MODEL} '
                     f'--skip-git-repo-check -s read-only {a} - < prompt.txt > ../{name}.log 2>&1) &')
    lines += ["wait",
              'for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\\.png" $f | tail -1)"; done']
    run = os.path.join(out, "run.sh")
    with open(run, "w") as f:
        f.write("\n".join(lines) + "\n")
    os.chmod(run, 0o755)
    with open(os.path.join(out, "README.md"), "w") as f:
        f.write(README)
    print("만듦:", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
