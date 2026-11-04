#!/usr/bin/env python3
"""다시 그려 받은 환경 그림(troy_city·troy_coast) → 임시 그림 덮어쓰기. gen_env_extra.py가 마지막에 부른다.

받은 그림은 안내 그림판(docs/sprite_request/env_requests/<city|coast>_redraw/guide.png)과 같은 자리에 그려져 있다.
- 자르기: 배경이 아닌 덩어리를 찾고, 덩어리 중심이 그 그림 상자(boxes.json, 여유 MARGIN)에 든 것을 모은다
  → 분수 물방울처럼 떨어진 조각도 같이 들어온다
- 크기: 0.68배 (troy_env와 같은 배율). 안내 상자보다 크게 그려 온 것은 상자에 맞게 더 줄인다(FIT_TOL)
- 기준점: 안내 그림판의 임시 그림에서 '가장 아래 점 → 기준점' 높이와 '폭 가운데 → 기준점' 가로 거리를 재서 새 그림에 똑같이 붙인다
  (나무는 줄기 밑, 건물은 발자국 중심 — 임시 그림 기준점을 그대로 물려받는다)
- 바닥: 마름모 하나씩 잘라 64×32로 줄이고 floor_atlas.png의 water·sand·planks 줄을 바꾼다
- 안내 그림판에 없던 새 그림(올리브·덤불)은 env.json에 새 항목으로 더한다(기준점: 줄기 밑)

    python3 tools/gen_env_extra.py .      (끝에서 이 스크립트의 apply를 부른다)
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from gen_env_from_sheet import BG, shrink  # noqa: E402

K = 0.68
MARGIN = 36
SHEETS = {"city_redraw": "troy_city.webp", "coast_redraw": "troy_coast.webp"}
# 안내 그림판에 단색 윤곽만 있던 새 그림: 기준점은 가장 아래 점에서 이만큼 위
NEW_ITEMS = {"olive": 3, "bush": 6}
# 게임에서 쓰는 이름이 다른 것
RENAME = {}
# 크기: 안내 그림판 상자보다 FIT_TOL배 넘게 크게 그려진 것은 상자에 맞게 더 줄인다(작은 소품이 1.5배쯤 커져 온다).
# 나무·사다리는 임시 그림 폭이 좁아서 높이만 맞춘다
FIT_TOL = 1.1
HEIGHT_ONLY = {"cypress", "pine", "olive", "bush", "ladder"}
# 기준점 손보기(게임 px): 갤리선은 고물(뒤)이 길게 그려져 아래 부두 말뚝을 덮으니 그림을 오른쪽으로 옮긴다
ANCHOR_NUDGE = {"galley": (-18, 0)}


def mask_of(a):
    """배경이 고른 단색이라 문턱을 낮게 잡는다(어두운 사이프러스 잎이 지워지지 않게). 잡음은 덩어리 크기로 거른다."""
    return np.abs(a.astype(int) - BG).sum(2) > 20


def components(mask):
    """4방향 이웃 덩어리 번호(0 = 배경). scipy 없이 줄 단위 합치기."""
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32)
    parent = [0]

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for y in range(h):
        row = mask[y]
        xs = np.nonzero(row)[0]
        if len(xs) == 0:
            continue
        # 줄 안에서 이어진 구간
        breaks = np.nonzero(np.diff(xs) > 1)[0]
        starts = np.r_[xs[0], xs[breaks + 1]]
        ends = np.r_[xs[breaks], xs[-1]]
        for s, e in zip(starts, ends):
            above = lab[y - 1, s:e + 1] if y > 0 else np.array([], np.int32)
            ids = {find(int(v)) for v in above[above > 0]}
            if ids:
                root = min(ids)
                for i in ids:
                    parent[i] = root
            else:
                root = len(parent)
                parent.append(root)
            lab[y, s:e + 1] = root
    roots = np.array([find(i) for i in range(len(parent))], np.int32)
    return roots[lab]


def lowest_point(alpha):
    ys, xs = np.nonzero(alpha)
    by = ys.max()
    return float(xs[ys >= by - 1].mean()), float(by)


def cut_items(sheet, guide, boxes):
    a = np.asarray(sheet.convert("RGB"))
    m = mask_of(a)
    lab = components(m)
    ids, counts = np.unique(lab[lab > 0], return_counts=True)
    cy = {}
    for i, c in zip(ids, counts):
        if c < 6:
            continue
        ys, xs = np.nonzero(lab == i)
        cy[i] = (xs.mean(), ys.mean(), xs.min(), ys.min(), xs.max(), ys.max())
    g = np.asarray(guide.convert("RGB"))
    gm = mask_of(g)
    out = {}
    for name, b in boxes.items():
        if "floor" in b:
            continue
        x0, y0, x1, y1 = b["box"]
        pick = [i for i, (mx, my, *_r) in cy.items()
                if x0 - MARGIN <= mx <= x1 + MARGIN and y0 - MARGIN <= my <= y1 + MARGIN]
        if not pick:
            raise SystemExit(f"{name}: 받은 그림에서 못 찾음")
        sel = np.isin(lab, pick)
        ys, xs = np.nonzero(sel)
        bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        rgba = np.dstack([a[by0:by1, bx0:bx1], sel[by0:by1, bx0:bx1] * 255]).astype(np.uint8)
        img = Image.fromarray(rgba)
        # 안내 그림판의 임시 그림: 가장 아래 점과 기준점(시트 좌표)
        if "size_game" in b:
            gsel = np.zeros_like(gm)
            gsel[y0:y1, x0:x1] = gm[y0:y1, x0:x1]
            glx, gly = lowest_point(gsel)
        else:
            glx = gly = None
        out[name] = (img, (bx0, by0), (glx, gly))
    return out


def floor_tiles(sheet, boxes):
    a = np.asarray(sheet.convert("RGB"))
    m = mask_of(a)
    tiles = {}
    for name, b in boxes.items():
        if "floor" not in b:
            continue
        x0, y0, x1, y1 = b["box"]
        sx0, sy0, sx1, sy1 = x0 - 12, y0 - 10, x1 + 12, y1 + 10
        sub = m[sy0:sy1, sx0:sx1]
        ys, xs = np.nonzero(sub)
        # 마름모 바깥 테두리(어두운 선)가 이어 붙였을 때 줄로 보이지 않게 가로 3px·세로 2px 안쪽으로 자른다
        crop = Image.fromarray(a[sy0 + ys.min() + 2:sy0 + ys.max() - 1, sx0 + xs.min() + 3:sx0 + xs.max() - 2])
        t = crop.resize((64, 32), Image.LANCZOS).convert("RGBA")
        px = np.asarray(t).copy()
        yy, xx = np.mgrid[0:32, 0:64]
        inside = np.abs(xx - 31.5) / 32.5 + np.abs(yy - 15.5) / 16.5 <= 1.0
        px[..., 3] = np.where(inside, 255, 0)
        tiles[(b["floor"], b["variant"])] = Image.fromarray(px)
    return tiles


def apply(root):
    root = Path(root)
    env = root / "assets/env"
    req = root / "docs/sprite_request/env_requests"
    meta = json.loads((env / "env.json").read_text())
    done = []
    for folder, src_name in SHEETS.items():
        src = root / "assets/source" / src_name
        if not src.exists():
            continue
        boxes = json.loads((req / folder / "boxes.json").read_text(encoding="utf-8"))["items"]
        sheet = Image.open(src)
        guide = Image.open(req / folder / "guide.png")
        for name, (img, (ox, oy), (glx, gly)) in cut_items(sheet, guide, boxes).items():
            b = boxes[name]
            gw, gh = b["box"][2] - b["box"][0] - 16, b["box"][3] - b["box"][1] - 20
            fit = min(1.0, FIT_TOL * gh / img.height)
            if name not in HEIGHT_ONLY:
                fit = min(fit, FIT_TOL * gw / img.width)
            k = K * fit
            small = shrink(img, k)
            alpha = np.asarray(small)[..., 3] > 0
            lx, ly = lowest_point(alpha)
            game = RENAME.get(name, name)
            if name in NEW_ITEMS:
                anchor = [round(lx), round(ly - NEW_ITEMS[name])]
                fp = [1, 1]
            else:
                old = meta["props"][game]
                # 임시 그림 기준점(시트 좌표) = 상자 왼쪽 위 여백(8, 12) + 기준점 × 1/0.68
                gx0 = b["box"][0] + 8
                gy_top = b["box"][3] - 8 - round(old["size"][1] / K)
                ax = gx0 + old["anchor"][0] / K
                ay = gy_top + old["anchor"][1] / K
                # 가로는 그림 폭 가운데 기준(모양이 달라 가장 아래 점이 옮겨 가도 흔들리지 않게), 세로는 가장 아래 점 기준
                gcx = gx0 + old["size"][0] / K / 2
                anchor = [round(small.width / 2 + (ax - gcx) * k), round(ly + (ay - gly) * k)]
                fp = old.get("footprint", [1, 1])
            nx, ny = ANCHOR_NUDGE.get(name, (0, 0))
            anchor = [anchor[0] + nx, anchor[1] + ny]
            small.save(env / f"{game}.png")
            entry = dict(meta["props"].get(game, {}))
            entry.update({"file": f"{game}.png", "anchor": anchor, "footprint": fp, "size": [small.width, small.height]})
            meta["props"][game] = entry
            done.append(game)
        tiles = floor_tiles(sheet, boxes)
        if tiles:
            fa = meta["floor_atlas"]
            atlas = Image.open(env / fa["file"]).convert("RGBA")
            for (kind, v), t in tiles.items():
                r = fa["rows"].index(kind)
                atlas.paste(t, (v * 64, r * 32))
            atlas.save(env / fa["file"])
            done.append("바닥 " + "·".join(sorted({k for k, _ in tiles})))
    (env / "env.json").write_text(json.dumps(meta, ensure_ascii=False))
    if done:
        print("다시 그려 받은 그림:", ", ".join(done))


if __name__ == "__main__":
    # 임시 그림의 기준점을 물려받으므로 늘 gen_env_extra.py부터(그 끝에서 apply를 부른다)
    from gen_env_extra import main
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
