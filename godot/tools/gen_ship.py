#!/usr/bin/env python3
"""그려 받은 배 8방향 그림 → assets/sprites/<이름>_sail.png·_furl.png + .json (ship.gd가 읽음).

받는 것: assets/source/<이름>_sail.webp(돛 폄)·<이름>_furl.webp(돛 접음), 1536×1024, 칸 384×512 4열×2줄,
  윗줄 N NE E SE / 아랫줄 S SW W NW = 뱃머리가 그 화면 방향을 향함. 마젠타 배경.
칸마다 그림만 남기고 잘라 한 줄로 붙이고, 칸마다 rect(시트 안 위치)·선체 폭·선체 가운데 x·바닥 y를 적는다.
선체 = 그림 아래쪽 35%(돛·돛대가 없는 부분). ship.gd는 그 폭을 코드가 그리던 선체 폭에 맞춰 줄이고 바닥을 물 높이에 둔다.
사용: python3 tools/gen_ship.py <godot 프로젝트 폴더> <이름>      예) cicones_boat
  5칸 원본(1536×1024, 칸 512×512 3열×2줄: 윗줄 E SE S / 아랫줄 NE N, 오른쪽 아래 칸은 비움)도 읽는다 — 오른쪽 아래가
  비었으면 5칸으로 보고 SW W NW는 SE E NE를 뒤집는다. 한 배를 한 배율로 그려 온 그림이라 json에 동(E) 칸 선체 길이 len을 적고,
  ship.gd는 모든 방향에 그 한 배율을 쓴다(방향마다 선체 폭에 맞추면 돌 때 크기가 들쭉날쭉해서).
     python3 tools/gen_ship.py <폴더> <이름> --hull   (갤리선: 선체만 16방향 + 돛 천)
       assets/source/<이름>_hull_a.webp(E ESE SE / SSE S ENE)·_hull_b.webp(NE NNE N), 칸 512×512 — 요청 안내 그림
       (docs/sprite_request/ch2_kit/ship/make_hull_guide.py)대로 칸마다 배 한가운데(물 높이)가 (256, 300), 격자 1칸 = 화면 (66, 33).
       서쪽 일곱은 동쪽을 뒤집는다 → <이름>_hull.png/.json(방향 16: 동부터 시계 방향, 칸마다 rect·ax·ay).
       돛 천: <이름>_sail.webp 남쪽 칸(정면으로 본 돛)에서 빨강·크림 부분만 잘라 <이름>_cloth.png — ship.gd가 돛대·돛을 코드로 그릴 때 씀.
     python3 tools/gen_ship.py <폴더> <이름> --compose <앞 8칸 그림> <뒤 3칸 그림> <sail|furl>
       8칸을 다 맞게 그려 오지 못했을 때: 앞 그림에서 남(왼쪽 아래 칸)·남동(오른쪽 위 칸)만, 뒤 그림(1536×1024, 왼쪽부터 3척)에서
       북·북동·동을 쓰고 남서·서·북서는 남동·동·북동을 좌우로 뒤집어 assets/source/<이름>_<종류>.webp(8칸)를 만든다
       뒤 그림 자리에 - = 임시: 북은 남을 180도 돌리고, 북동·동은 앞 그림 셋째 칸(뱃머리가 거의 오른쪽)을 쓴다
"""
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from gen_hero import is_bg  # noqa: E402

ORDER = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
DIRS = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]   # 게임 방향 번호(0 동부터 시계 방향)
HULL = 0.35


FIVE = ["E", "SE", "S", "NE", "N"]


def clear(c):
    """배경을 투명으로 바꾸고 그림만 남게 자른다(빈 칸이면 None)."""
    px = c.load()
    for y in range(c.height):
        for x in range(c.width):
            r, g, b, a = px[x, y]
            if is_bg(px[x, y]):
                px[x, y] = (0, 0, 0, 0)
            elif min(r, b) - g > 40:   # 가는 밧줄에 배경 마젠타가 섞인 픽셀 → 밧줄 갈색으로
                px[x, y] = (min(r, g + 50), g, min(b, g), a)
    bb = c.getbbox()
    return c.crop(bb) if bb else None


def is_five(src):
    return src.width == 1536 and clear(src.crop((1024, 512, 1536, 1024)).convert("RGBA")) is None


def cut(src):
    if is_five(src):
        cells = {d: clear(src.crop((i % 3 * 512, i // 3 * 512, i % 3 * 512 + 512, i // 3 * 512 + 512)).convert("RGBA"))
                 for i, d in enumerate(FIVE)}
        flip = lambda im: im.transpose(Image.FLIP_LEFT_RIGHT)
        cells.update({"SW": flip(cells["SE"]), "W": flip(cells["E"]), "NW": flip(cells["NE"])})
        return cells, True
    cells = {}
    for i, d in enumerate(ORDER):
        c = src.crop((i % 4 * 384, i // 4 * 512, i % 4 * 384 + 384, i // 4 * 512 + 512)).convert("RGBA")
        px = c.load()
        for y in range(c.height):
            for x in range(c.width):
                if is_bg(px[x, y]):
                    px[x, y] = (0, 0, 0, 0)
        cells[d] = c.crop(c.getbbox())
    return cells, False


def hull(c):
    a = c.getchannel("A")
    top = int(c.height * (1 - HULL))
    bb = a.crop((0, top, c.width, c.height)).getbbox()
    return bb[2] - bb[0], (bb[0] + bb[2]) / 2


def build(root, name):
    for kind in ("sail", "furl"):
        cells, five = cut(Image.open(root / f"assets/source/{name}_{kind}.webp").convert("RGB"))
        w = sum(c.width for c in cells.values())
        sheet = Image.new("RGBA", (w, max(c.height for c in cells.values())), (0, 0, 0, 0))
        meta, x = {"dirs": []}, 0
        for d in DIRS:
            c = cells[d]
            sheet.paste(c, (x, 0))
            hw, hx = hull(c)
            meta["dirs"].append({"rect": [x, 0, c.width, c.height], "hull_w": hw, "hull_x": hx, "bottom": c.height})
            x += c.width
        if five:
            meta["len"] = hull(cells["E"])[0]
        sheet.save(root / f"assets/sprites/{name}_{kind}.png")
        (root / f"assets/sprites/{name}_{kind}.json").write_text(json.dumps(meta))
    print(f"{name} 배 시트 생성")


def trim(c):
    c = c.convert("RGBA")
    px = c.load()
    for y in range(c.height):
        for x in range(c.width):
            if is_bg(px[x, y]):
                px[x, y] = (255, 0, 255, 0)
    return c.crop(c.getbbox())


def spans(im, n):
    """그림이 칸 경계를 넘어 그려 올 때가 있어, 배경만 있는 세로줄로 나눠 넓은 n개를 왼쪽부터 돌려준다."""
    px = im.load()
    cols = [any(not is_bg(px[x, y]) for y in range(0, im.height, 2)) for x in range(im.width)] + [False]
    runs, st = [], None
    for x, c in enumerate(cols):
        if c and st is None:
            st = x
        elif not c and st is not None:
            runs.append((st, x))
            st = None
    return sorted(sorted(runs, key=lambda r: r[0] - r[1])[:n])


def compose(root, name, front, back, kind):
    f = Image.open(front).convert("RGB")
    cell = lambda im, x, y, w, h: trim(im.crop((x, y, x + w, y + h)))
    got = {"S": cell(f, 0, 512, 384, 512), "SE": cell(f, 1152, 0, 384, 512)}
    if back == "-":
        got.update({"N": got["S"].rotate(180), "NE": cell(f, 768, 0, 384, 512), "E": cell(f, 768, 0, 384, 512)})
    else:
        b = Image.open(back).convert("RGB")
        got.update(zip(("N", "NE", "E"), (cell(b, x0, 0, x1 - x0, b.height) for x0, x1 in spans(b, 3))))
    flip = lambda im: im.transpose(Image.FLIP_LEFT_RIGHT)
    got.update({"SW": flip(got["SE"]), "W": flip(got["E"]), "NW": flip(got["NE"])})
    out = Image.new("RGB", (1536, 1024), (255, 0, 255))
    for i, d in enumerate(ORDER):
        c = got[d]
        k = min(1.0, 376 / c.width, 504 / c.height)   # 칸(384×512)에 들어가게만 줄인다 — 크기는 ship.gd가 선체 폭으로 맞춘다
        if k < 1.0:
            c = c.resize((int(c.width * k), int(c.height * k)), Image.NEAREST)
        x, y = i % 4 * 384 + (384 - c.width) // 2, i // 4 * 512 + 508 - c.height
        out.paste(c, (x, y), c)
    out.save(root / f"assets/source/{name}_{kind}.webp", lossless=True)


HULL16 = ["E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N", "NNE", "NE", "ENE"]
HULL_SHOTS = {"a": ["E", "ESE", "SE", "SSE", "S", "ENE"], "b": ["NE", "NNE", "N"]}
MIRROR = {"SSW": "SSE", "SW": "SE", "WSW": "ESE", "W": "E", "WNW": "ENE", "NW": "NE", "NNW": "NNE"}
GUIDE = {"px": 66, "len": 4.5, "wid": 4.5 / 4.2, "deck": 46, "ax": 256, "ay": 300}


def build_hull(root, name):
    got = {}
    for key, names in HULL_SHOTS.items():
        src = Image.open(root / f"assets/source/{name}_hull_{key}.webp").convert("RGBA")
        for i, d in enumerate(names):
            c = src.crop((i % 3 * 512, i // 3 * 512, i % 3 * 512 + 512, i // 3 * 512 + 512))
            px = c.load()
            for y in range(512):
                for x in range(512):
                    r, g, b, a = px[x, y]
                    if is_bg(px[x, y]):
                        px[x, y] = (0, 0, 0, 0)
                    elif min(r, b) - g > 30:   # 가장자리에 섞인 마젠타 → 나무 갈색
                        px[x, y] = (min(r, g + 50), g, min(b, g), a)
            bb = c.getbbox()
            got[d] = (c.crop(bb), GUIDE["ax"] - bb[0], GUIDE["ay"] - bb[1])
    for d, m in MIRROR.items():
        c, ax, ay = got[m]
        got[d] = (c.transpose(Image.FLIP_LEFT_RIGHT), c.width - ax, ay)
    sheet = Image.new("RGBA", (sum(got[d][0].width for d in HULL16), max(g[0].height for g in got.values())), (0, 0, 0, 0))
    meta, x = dict(GUIDE, dirs=[]), 0
    for d in HULL16:
        c, ax, ay = got[d]
        sheet.paste(c, (x, 0))
        meta["dirs"].append({"rect": [x, 0, c.width, c.height], "ax": ax, "ay": ay})
        x += c.width
    sheet.save(root / f"assets/sprites/{name}_hull.png")
    (root / f"assets/sprites/{name}_hull.json").write_text(json.dumps(meta))
    # 돛 천: 5칸 돛 그림의 남쪽 칸(정면) — 빨간 픽셀의 경계 상자
    s = Image.open(root / f"assets/source/{name}_sail.webp").convert("RGB").crop((1024, 0, 1536, 512))
    px = s.load()
    xs, ys = [], []
    for y in range(512):
        for x in range(512):
            r, g, b = px[x, y]
            if r > 110 and r > g * 1.7 and r > b * 1.7:   # 빨간 줄(양 끝 줄이 빨강이라 이것만으로 돛 경계가 나온다)
                xs.append(x)
                ys.append(y)
    # 선체에도 붉은 갈색이 있어 줄마다 빨강이 넉넉한(돛 폭의 20% 넘는) 줄만 돛으로 본다
    x0, x1 = min(xs), max(xs)
    rows = {}
    for y in ys:
        rows[y] = rows.get(y, 0) + 1
    sail_rows = [y for y, n in rows.items() if n > (x1 - x0) * 0.2]
    cloth = s.crop((x0, min(sail_rows), x1 + 1, max(sail_rows) + 1))
    cloth.save(root / f"assets/sprites/{name}_cloth.png")
    print(f"{name} 선체 16방향·돛 천 생성")


if __name__ == "__main__":
    if "--hull" in sys.argv:
        build_hull(Path(sys.argv[1]), sys.argv[2])
        sys.exit()
    if "--compose" in sys.argv:
        a = sys.argv[sys.argv.index("--compose") + 1:]
        compose(Path(sys.argv[1]), sys.argv[2], a[0], a[1], a[2])
        print(f"{sys.argv[2]}_{a[2]} 8칸 원본 생성")
        sys.exit()
    build(Path(sys.argv[1]), sys.argv[2])
