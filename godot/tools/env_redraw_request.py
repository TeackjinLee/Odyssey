#!/usr/bin/env python3
"""임시 그림 다시 그려 받기 요청 묶음: 맵 개편 때 생성기로 만든 임시 그림(gen_env_extra.py)을
자리·크기 안내 그림(guide.png)으로 놓고, Codex에게 troy_env 화풍으로 같은 자리에 다시 그려 달라고 한다.

    python3 tools/env_redraw_request.py .                  # 아직 받지 않은 시트만(지금은 extra_redraw)
    python3 tools/env_redraw_request.py . extra_redraw     # 고른 시트만

출력: docs/sprite_request/env_requests/<city_redraw|extra_redraw|coast_redraw>/
  - prompt.txt          붙여 넣을 프롬프트
  - guide.png           두 번째로 붙일 그림(이름 없음, 1536×1024)
  - guide_labeled.png   사람이 보는 이름표 판(붙이지 않는다)
  - boxes.json          받은 그림에서 자를 상자 [x0, y0, x1, y1]·발자국·배율 (gen_env_from_sheet.py ITEMS 형식으로 옮겨 쓴다)
그리고 env_requests/run_redraw.sh (둘을 Codex로 동시에 돌린다).
안내 그림 배율은 게임 픽셀 × 1/0.68 — troy_env 시트와 같은 크기(바닥 한 칸이 약 94×47).
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

BG = (40, 43, 53, 255)
SCALE = 1 / 0.68
W, H = 1536, 1024
CODEX = '"$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh'   # 모델·추론은 tools/codex_image.sh에서

# 줄마다 (바닥 기준선 y, [(이름, 설명)]) — 왼쪽에서 오른쪽 순서
SHEETS = {
    "city_redraw": {
        "out": "troy_city.webp",
        "rows": [
            (380, ["temple", "bell_tower", "fountain"]),
            (700, ["steps", "lion", "stall_red", "stall_white", "column_broken", "ladder", "pot"]),
        ],
        "floors": [],
    },
    "extra_redraw": {
        "out": "troy_extra.webp",
        "rows": [
            (300, ["alarm_bell", "winch", "brazier", "banner_greek", "torch_post_off", "gate_open"]),
            (590, ["house_a_burnt", "house_b_burnt", "house_c_burnt", "house_d_burnt"]),
            (900, ["armory", "armory_burnt", "sacks"]),
        ],
        "floors": [],
    },
    "coast_redraw": {
        "out": "troy_coast.webp",
        "rows": [
            (430, ["galley", "boat", "pier_post", "rock"]),
            (800, ["cypress", "pine", "olive", "bush"]),
        ],
        "floors": ["water", "sand", "planks"],
    },
}
# 안내 그림에 쓸 임시 그림이 없는 것: 비슷한 그림의 윤곽만 단색으로 칠해 자리·크기만 잡는다(새로 그릴 칸)
STAND_IN = {"olive": "pine", "bush": "rock", "armory": "cart", "armory_burnt": "cart", "sacks": "crate"}
# 대신 쓴 윤곽을 이만큼 키워 새 그림의 크기를 잡는다
STAND_IN_SCALE = {"armory": 1.35, "armory_burnt": 1.35, "sacks": 1.3}
STAND_IN_COLOR = (92, 104, 88)

DESC = {
    "temple": "Greek TEMPLE of Athena on a raised marble platform, six front columns, red tiled pediment roof, "
              "two red banners with a gold emblem hung between the front columns (footprint 3x3 tiles)",
    "bell_tower": "wooden BELL TOWER: four tall posts, two cross-braced floors, small red tiled roof, a bronze bell hanging "
                  "under the roof, a ladder up one side, stone-paved base (footprint 2x2 tiles)",
    "fountain": "round stone FOUNTAIN with a two-tier basin and dark blue night water (footprint 2x2 tiles)",
    "steps": "a block of wide marble STEPS (three steps going up toward the upper right, one tile)",
    "lion": "seated stone LION statue on a square base, facing lower left (one tile)",
    "stall_red": "MARKET STALL: wooden counter with baskets of fruit and jars, RED and WHITE striped cloth awning (one tile)",
    "stall_white": "the same market stall with a BLUE and WHITE striped awning and different goods (one tile)",
    "column_broken": "BROKEN marble COLUMN: standing lower half with a jagged top, fallen drum pieces beside it (one tile)",
    "ladder": "wooden LADDER leaning to the right, rope-tied rungs (to lean against the Trojan horse)",
    "pot": "clay POT with a small green plant",
    "galley": "Greek GALLEY ship with one mast, square sail with red and cream stripes, a row of oars, "
              "dark wooden hull, bow pointing to the upper right (footprint 5x2 tiles)",
    "boat": "small wooden rowing BOAT, bow to the upper right, two oars inside (footprint 2x1 tiles)",
    "pier_post": "wooden dock POST, weathered, a rope tied around it",
    "rock": "grey SEA ROCK, a few boulders",
    "cypress": "tall thin dark green CYPRESS tree",
    "pine": "Mediterranean umbrella PINE tree",
    "olive": "OLIVE tree with a twisted grey trunk and silver-green leaves (its placeholder is a flat grey-green silhouette: "
             "draw a new tree in that space)",
    "bush": "low round green BUSH (its placeholder is a flat grey-green silhouette: draw a new bush in that space)",
    "alarm_bell": "ALARM BELL stand: two wooden posts with a crossbar, a bronze bell hanging in the middle with a rope, "
                  "on a small stone base (one tile)",
    "winch": "wooden city-gate WINCH: a heavy horizontal wooden drum on two thick posts, a big four-spoke crank wheel on its side, "
             "thick rope wound on the drum (one tile)",
    "brazier": "bronze BRAZIER on three legs, a shallow bowl of glowing red-orange coals (no tall flames: the game adds them)",
    "banner_greek": "tall cloth BANNER on a wooden pole, TEAL-BLUE cloth with a white owl emblem (the Greek side), "
                    "same shape as the red Trojan banner in the first image",
    "torch_post_off": "the same wooden TORCH POST as in the first image but UNLIT: a black burnt-out torch head, a thin wisp of smoke",
    "gate_open": "the same CITY GATE as in the first image but OPEN: the wooden doors swung inward, a dark passage visible "
                 "through the arch",
    "house_a_burnt": "the matching house from the first image after a FIRE: charred black beams, half-collapsed red tile roof, "
                     "soot-blackened walls, a few glowing embers (no tall flames: the game adds them)",
    "house_b_burnt": "another matching house from the first image, BURNT the same way (charred, roof partly fallen in, embers)",
    "house_c_burnt": "another matching house from the first image, BURNT the same way",
    "house_d_burnt": "another matching house from the first image, BURNT the same way",
    "armory": "small ARMORY STORE against a city wall: a lean-to wooden shed roof over stacked spears, round shields and amphorae "
              "(footprint 2x1 tiles; its placeholder is a flat silhouette: draw a new item in that space)",
    "armory_burnt": "the same armory store BURNT: charred black planks, collapsed roof, broken spears, glowing embers "
                    "(no tall flames; flat-silhouette placeholder)",
    "sacks": "a tall PILE OF GRAIN SACKS AND CRATES that an archer can stand on top of (one tile; flat-silhouette placeholder)",
}
# 새 그림의 발자국(대신 쓴 그림과 다를 때)
NEW_FOOTPRINT = {"armory": [2, 1], "armory_burnt": [2, 1]}
FLOOR_DESC = {
    "water": "deep night SEA water with small wave highlights",
    "sand": "ROCKY SHORE: grey stones and wet sand",
    "planks": "wooden DOCK planks running toward the upper right",
}

HEAD = """Use your built-in image generation tool to create exactly ONE image from the prompt below. Attached images:
1) troy_env.png = the STYLE reference: isometric Greek city of Troy at night, one floor tile = about 94x47 px in that sheet.
2) guide.png = a LAYOUT GUIDE made of rough placeholder drawings: it shows WHERE each item goes and HOW BIG it is.
Do not write code or edit any files. When the image is generated, reply with its saved file path only.
Make the image 1536x1024 (landscape), the same size as guide.png.

"""

BODY = """Pixel art isometric game {kind} sprite sheet. REDRAW every placeholder in the SECOND image (guide.png) as finished art,
matching EXACTLY the style, outline, palette, lighting (from the upper left) and pixel density of the FIRST image (troy_env.png):
hand-placed pixels, soft stone texture, warm red clay roof tiles, blue-grey night shading, crisp dark outline.
The placeholders are crude flat-shaded drafts: do NOT copy their look, colors or stripes literally; copy only their
POSITION, SIZE, FOOTPRINT (the diamond on the ground) and general SHAPE. Keep each item in the same place and within the
same outline size as its placeholder, so the items can be cut out with the same boxes.
Solid flat dark background #282B35 everywhere else. Every item separated by empty space. No text, no labels, no grid lines,
no shadows on the ground, no new items. 2:1 isometric view (camera looks down about 30 degrees), no perspective.
Night colors: blue-grey stone, deep blue water, warm orange only where there are torches or fire.

{items}
"""


def font(size):
    for p in ("/usr/share/fonts/truetype/nanum/NanumGothic.ttf", "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def load(env, name):
    src = STAND_IN.get(name, name)
    im = Image.open(os.path.join(env, f"{src}.png")).convert("RGBA")
    if name in STAND_IN:
        flat = Image.new("RGBA", im.size, STAND_IN_COLOR + (255,))
        im = Image.composite(flat, Image.new("RGBA", im.size, (0, 0, 0, 0)), im.getchannel("A"))
    k = SCALE * STAND_IN_SCALE.get(name, 1.0)
    return im.resize((round(im.width * k), round(im.height * k)), Image.NEAREST)


def floor_block(env, kinds):
    meta = json.load(open(os.path.join(env, "env.json")))["floor_atlas"]
    atlas = Image.open(os.path.join(env, meta["file"])).convert("RGBA")
    tw, th = round(64 * SCALE), round(32 * SCALE)
    tiles = []
    for k in kinds:
        r = meta["rows"].index(k)
        tiles.append([atlas.crop((v * 64, r * 32, v * 64 + 64, r * 32 + 32)).resize((tw, th), Image.NEAREST)
                      for v in range(4)])
    return tiles, tw, th


def build(root, sheet, spec):
    env = os.path.join(root, "assets/env")
    meta = json.load(open(os.path.join(env, "env.json")))["props"]
    guide = Image.new("RGBA", (W, H), BG)
    boxes, lines = {}, []
    # 바닥: 왼쪽 위에 종류마다 한 줄, 4가지씩 (troy_env 바닥 줄처럼 꼭짓점끼리 닿게)
    y = 40
    if spec["floors"]:
        tiles, tw, th = floor_block(env, spec["floors"])
        lines.append(f"Top-left block, {len(spec['floors'])} rows of FLOOR TILES, 4 variants each, every tile exactly one "
                     f"2:1 diamond of {tw}x{th} px, seamless when tiled (no outline around the diamonds):")
        for i, k in enumerate(spec["floors"]):
            for v in range(4):
                x = 40 + v * (tw + 16)
                guide.alpha_composite(tiles[i][v], (x, y))
                boxes[f"floor_{k}_{v}"] = {"box": [x, y, x + tw, y + th], "floor": k, "variant": v}
            lines.append(f"- row {i + 1}: {FLOOR_DESC[k]}")
            y += th + 24
        lines.append("")
    for ri, (base, names) in enumerate(spec["rows"]):
        ims = [load(env, n) for n in names]
        gap = (W - 80 - sum(i.width for i in ims)) / max(1, len(ims) - 1) if len(ims) > 1 else 0
        gap = min(gap, 90)
        total = sum(i.width for i in ims) + gap * (len(ims) - 1)
        x = (W - total) / 2
        if ri == 0 and spec["floors"]:
            x = max(x, 40 + 4 * (tw + 16) + 40)    # 바닥 칸 오른쪽에서 시작
        lines.append(f"Row {ri + 1} (left to right):")
        for n, im in zip(names, ims):
            src = meta[STAND_IN.get(n, n)]
            x0, y0 = round(x), base - im.height
            guide.alpha_composite(im, (x0, y0))
            fp = NEW_FOOTPRINT.get(n, src.get("footprint", [1, 1]))
            boxes[n] = {"box": [x0 - 8, y0 - 12, x0 + im.width + 8, base + 8], "footprint": fp,
                        "k": round(1 / SCALE, 4), "size_game": src["size"]}
            lines.append(f"- {DESC[n]}, about {im.width}x{im.height} px.")
            x += im.width + gap
        lines.append("")
    if max(b["box"][3] for b in boxes.values()) > H:
        raise SystemExit(f"{sheet}: 그림이 아래로 넘친다")
    kind = "tiles and props" if spec["floors"] else "buildings and props"
    prompt = HEAD + BODY.format(kind=kind, items="\n".join(lines).rstrip() + "\n")
    # 사람이 보는 이름표 판
    lab = guide.copy()
    d = ImageDraw.Draw(lab)
    f = font(18)
    for n, b in boxes.items():
        if n.startswith("floor_") and not n.endswith("_0"):
            continue
        x0, y0, x1, y1 = b["box"]
        d.rectangle((x0, y0, x1, y1), outline=(255, 200, 80, 255), width=1)
        name = b["floor"] if "floor" in b else n
        d.text((x0 + 2, y1 + 2), name, fill=(255, 220, 120, 255), font=f)
    return guide.convert("RGB"), lab.convert("RGB"), boxes, prompt


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    out = os.path.join(root, "docs/sprite_request/env_requests")
    style = os.path.join(out, "troy_env.png")
    if not os.path.exists(style):
        Image.open(os.path.join(root, "assets/source/troy_env.webp")).convert("RGB").save(style)
    run = ["#!/bin/zsh", "# 임시 그림 다시 그려 받기(city_redraw·extra_redraw·coast_redraw)를 동시에 돌린다. 하나만: ./run_redraw.sh extra_redraw",
           'cd "$(dirname "$0")"', 'want=("$@")']
    # 고른 시트만(인자로 이름), 없으면 아직 받지 않은 시트만 — 받은 시트의 안내 그림·boxes.json은 자르기 기준이라 다시 만들지 않는다
    pick = sys.argv[2:] or [s for s, sp in SHEETS.items() if not os.path.exists(os.path.join(root, "assets/source", sp["out"]))]
    for sheet, spec in SHEETS.items():
        d = os.path.join(out, sheet)
        run.append(f"[[ ${{#want}} -eq 0 || ${{want[(Ie)]{sheet}}} -gt 0 ]] && (cd {sheet} && {CODEX} --skip-git-repo-check"
                   f" -s read-only -i ../troy_env.png -i guide.png - < prompt.txt > ../{sheet}.log 2>&1) &")
        if sheet not in pick:
            continue
        os.makedirs(d, exist_ok=True)
        guide, lab, boxes, prompt = build(root, sheet, spec)
        guide.save(os.path.join(d, "guide.png"))
        lab.save(os.path.join(d, "guide_labeled.png"))
        with open(os.path.join(d, "boxes.json"), "w", encoding="utf-8") as fp:
            json.dump({"save_as": spec["out"], "items": boxes}, fp, ensure_ascii=False, indent=1)
        with open(os.path.join(d, "prompt.txt"), "w", encoding="utf-8") as fp:
            fp.write(prompt)
        print(d)
    run += ["wait", 'for f in *_redraw.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\\.png" $f | tail -1)"; done']
    rs = os.path.join(out, "run_redraw.sh")
    with open(rs, "w") as fp:
        fp.write("\n".join(run) + "\n")
    os.chmod(rs, 0o755)
    print(rs)


if __name__ == "__main__":
    main()
