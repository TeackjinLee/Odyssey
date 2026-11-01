#!/usr/bin/env python3
"""그려 받은 환경 그림 한 장(assets/source/troy_env.webp, 어두운 단색 배경) → 게임 환경 그림.

gen_environment.py가 만든 env.json을 읽고, 받은 그림에 있는 것만 덮어쓴다
(불꽃·연기·그림자·화살·권양기·화로는 생성기 그림 그대로).
- 집마다 불탄 모습(<집>_burnt: 지붕 그을림, 지붕 위 불꽃 자리 fire_spots)도 만든다
- 소품: 칸 범위(SRC_X·SRC_Y)로 잘라 배경을 지우고 K배 축소, 기준점은 발자국 중심
- 바닥: 4열×6줄 마름모를 64×32로 맞춰 floor_atlas.png로

사용: python3 tools/gen_environment.py . && python3 tools/gen_env_from_sheet.py .
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

BG = np.array([40, 43, 53])
K = 0.68                # 소품 축소 배율(성탑 한 칸 폭이 타일 64px쯤)
# 이름: (x 범위, y 범위, 발자국[칸], 배율)
ITEMS = {
    "wall": ((8, 105), (0, 200), (1, 1), K),
    "tower": ((117, 215), (0, 200), (1, 1), K),
    "gate_closed": ((226, 324), (0, 200), (1, 1), K),
    "house_a": ((443, 654), (0, 200), (2, 2), K),
    "house_b": ((664, 925), (0, 200), (3, 2), K),
    "house_c": ((936, 1196), (0, 200), (2, 3), K),
    "house_d": ((1204, 1416), (0, 200), (2, 2), K),
    "horse": ((1473, 1706), (0, 240), (4, 2), 0.9),
    "crate": ((1744, 1805), (0, 200), (1, 1), K),
    "barrel": ((1816, 1855), (0, 200), (1, 1), K),
    "torch_post": ((1865, 1896), (0, 200), (1, 1), K),
    "amphora": ((1905, 1951), (0, 200), (1, 1), K),
    "column": ((8, 77), (200, 360), (1, 1), K),
    "banner_troy": ((82, 130), (200, 360), (1, 1), K),
    "rubble": ((132, 200), (200, 360), (1, 1), K),
    "spear_rack": ((211, 278), (200, 360), (1, 1), K),
    "cart": ((289, 392), (200, 360), (1, 1), K),
}
# 바닥 그림 줄 → 게임 바닥 이름 (env.json floor_atlas.rows 순서로 다시 쌓는다)
FLOOR_SRC = {"cobble": 0, "plaza": 1, "dirt": 2, "road": 3, "grass": 4, "ash": 5}
FLOOR_BOX = (8, 369, 376, 650)
TILE = (64, 32)


def mask_of(a):
    a = a.astype(int)
    d = np.abs(a - BG).sum(2)
    # 배경과 조금 다른 어두운 푸른빛(그림자·압축 잡음)은 배경으로, 어두운 나무(붉은빛)는 남긴다
    bluish_dark = (a[..., 2] >= a[..., 0]) & (a.max(2) < 90)
    return (d > 48) | ((d > 30) & ~bluish_dark)


def cut(src, xr, yr):
    """범위 안 그림을 배경 없는 RGBA로 (남는 여백은 잘라냄)."""
    a = src[yr[0]:yr[1], xr[0]:xr[1]]
    m = mask_of(a)
    ys, xs = np.nonzero(m)
    a, m = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1], m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    rgba = np.dstack([a, (m * 255)]).astype(np.uint8)
    return Image.fromarray(rgba)


def shrink(img, k):
    """축소하고 반투명 가장자리를 0/255로 (픽셀아트 테두리 유지)."""
    small = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))), Image.LANCZOS)
    a = np.asarray(small).copy()
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    return Image.fromarray(a)


def anchor_of(img, fp, name):
    """발자국 중심: 가장 아래 점(앞 꼭짓점)에서 (16(a-b), 8(a+b)) 위."""
    a = np.asarray(img)[..., 3] > 0
    if name == "horse":
        return [img.width // 2, img.height - 38]
    ys, xs = np.nonzero(a)
    by = ys.max()
    bx = xs[ys >= by - 1].mean()
    fa, fb = fp
    return [round(bx - 16 * (fa - fb)), round(by - 8 * (fa + fb))]


def open_gate(img):
    """닫힌 문 그림의 나무 문짝을 어두운 통로로 바꿔 열린 문을 만든다."""
    a = np.asarray(img).copy()
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    wood = (a[..., 3] > 0) & (r > b + 45) & (r > g + 15) & (r < 200)
    h, w = wood.shape
    wood[: h // 3] = False
    # 큰 덩어리(문짝)만 골라 줄 단위로 양끝 사이를 채운다
    fill = np.zeros_like(wood)
    seen = np.zeros_like(wood)
    for sy, sx in zip(*np.nonzero(wood)):
        if seen[sy, sx]:
            continue
        stack, comp = [(sy, sx)], []
        seen[sy, sx] = True
        while stack:
            y, x = stack.pop()
            comp.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and wood[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        if len(comp) < 60:
            continue
        rows = {}
        for y, x in comp:
            lo, hi = rows.get(y, (x, x))
            rows[y] = (min(lo, x), max(hi, x))
        for y, (lo, hi) in rows.items():
            fill[y, lo:hi + 1] = True
    # 오른쪽 문짝은 어두워서 잘 안 잡힌다: 앞 모서리(맨 아래 점)를 축으로 왼쪽 문을 뒤집어 쓴다
    mid = int(round(np.nonzero(a[..., 3].any(0))[0].mean()))
    left = fill[:, :mid].copy()
    n = min(mid, w - mid)
    fill[:, mid:mid + n] = left[:, ::-1][:, :n]
    fill[:, mid - 3:mid + 3] = False   # 앞 모서리 기둥은 남긴다
    fill &= a[..., 3] > 0
    a[fill, :3] = (22, 18, 20)
    return Image.fromarray(a)


def greek_banner(img):
    """트로이 깃발(빨강) → 아카이아 깃발(파랑): 붉은 픽셀의 R·B를 바꾼다."""
    a = np.asarray(img).copy()
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    red = (r > g + 40) & (r > b + 40) & (g < 120)
    a[red, 0], a[red, 2] = b[red], r[red]
    return Image.fromarray(a)


def shift_or(m, n):
    """m을 상하좌우 n px 넓힌다."""
    out = m.copy()
    for _ in range(n):
        g = out.copy()
        g[1:] |= out[:-1]
        g[:-1] |= out[1:]
        g[:, 1:] |= out[:, :-1]
        g[:, :-1] |= out[:, 1:]
        out = g
    return out


def roof_mask(a):
    """지붕 기와(R이 G보다 훨씬 큰 붉은 색)의 큰 덩어리들 중 그림 위쪽 절반에 있는 것(양쪽 지붕면).
    벽에 걸린 깃발은 아래쪽이라 빠진다."""
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    tile = (a[..., 3] > 0) & (r > g + 50) & (r > b + 70)
    # 기와 사이 어두운 줄눈으로 끊긴 기와를 한 덩어리로: 2px 넓혔다 줄인다
    tile = ~shift_or(~shift_or(tile, 2), 2)
    h, w = tile.shape
    seen = np.zeros_like(tile)
    m = np.zeros_like(tile)
    for sy, sx in zip(*np.nonzero(tile)):
        if seen[sy, sx]:
            continue
        stack, comp = [(sy, sx)], []
        seen[sy, sx] = True
        while stack:
            y, x = stack.pop()
            comp.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and tile[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        ys, xs = zip(*comp)
        if len(comp) >= 300 and np.mean(ys) < h * 0.5:
            m[list(ys), list(xs)] = True
    stone = (r - g < 45) & (g > 60)    # 돌벽(횃불에 비쳐 누렇게 보이는 것 포함)
    return m & ~stone & (a[..., 3] > 0)


def burnt_house(img, anchor):
    """불타는 집: 지붕을 그을린 색으로, 군데군데 달아오른 틈. 지붕 위 불꽃 자리(기준점 기준)도 돌려준다."""
    a = np.asarray(img).copy()
    roof = roof_mask(a)
    rnd = np.random.default_rng(7)
    h, w = roof.shape
    # 큰 얼룩(4px 칸) 단위로 그을림 정도를 달리한다
    blot = rnd.random((h // 4 + 1, w // 4 + 1)).repeat(4, 0).repeat(4, 1)[:h, :w]
    k = np.where(blot > 0.35, 0.32, 0.55)[..., None]
    rgb = a[..., :3].astype(float)
    char = rgb * k * np.array([1.0, 0.8, 0.75])
    a[roof, :3] = char[roof].astype(np.uint8)
    # 달아오른 틈: 기와 줄을 따라 2~3px 가로 줄
    for _ in range(int(roof.sum() * 0.004)):
        y, x = rnd.integers(0, h), rnd.integers(0, w - 3)
        if roof[y, x:x + 3].all():
            a[y, x:x + rnd.integers(2, 4), :3] = (236, 104, 30)
    # 불꽃 자리: 지붕을 x로 다섯 등분한 칸마다 그 칸 지붕의 위쪽 1/3 지점
    ys, xs = np.nonzero(roof)
    spots = []
    for q in (0.15, 0.38, 0.62, 0.85):
        x = int(np.quantile(xs, q))
        col = ys[np.abs(xs - x) <= 2]
        y = int(col.min() + (col.max() - col.min()) * 0.35)
        spots.append([x - anchor[0], y - anchor[1]])
    return Image.fromarray(a), spots


def floor_atlas(src, rows, variants):
    x0, y0, x1, y1 = FLOOR_BOX
    cw, ch = (x1 - x0) / 4, (y1 - y0) / 6
    tw, th = TILE
    yy, xx = np.mgrid[0:th, 0:tw]
    diamond = (np.abs(xx + 0.5 - tw / 2) / (tw / 2) + np.abs(yy + 0.5 - th / 2) / (th / 2)) <= 1.0
    atlas = Image.new("RGBA", (tw * variants, th * len(rows)), (0, 0, 0, 0))
    for ri, name in enumerate(rows):
        sr = FLOOR_SRC[name]
        for v in range(variants):
            c = src[round(y0 + sr * ch):round(y0 + (sr + 1) * ch), round(x0 + v * cw):round(x0 + (v + 1) * cw)]
            m = mask_of(c)
            ys, xs = np.nonzero(m)
            c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
            # 가장자리 틈이 안 보이게 살짝 크게 맞춘 뒤 마름모로 자른다
            big = Image.fromarray(c.astype(np.uint8)).resize((tw + 4, th + 2), Image.LANCZOS)
            t = np.asarray(big)[1:th + 1, 2:tw + 2]
            tile = np.dstack([t, diamond * 255]).astype(np.uint8)
            atlas.paste(Image.fromarray(tile), (v * tw, ri * th))
    return atlas


def main(root):
    out = root / "assets/env"
    meta = json.loads((out / "env.json").read_text())
    src = np.asarray(Image.open(root / "assets/source/troy_env.webp").convert("RGB"))
    for name, (xr, yr, fp, k) in ITEMS.items():
        img = shrink(cut(src, xr, yr), k)
        variants = [(name, img)]
        if name == "gate_closed":
            variants.append(("gate_open", open_gate(img)))
        if name == "banner_troy":
            variants.append(("banner_greek", greek_banner(img)))
        for n, im in variants:
            im.save(out / f"{n}.png")
            meta["props"][n] = {"file": f"{n}.png", "anchor": anchor_of(im, fp, n), "footprint": list(fp),
                                "size": [im.width, im.height]}
        if name.startswith("house_"):
            anchor = meta["props"][name]["anchor"]
            im, spots = burnt_house(img, anchor)
            im.save(out / f"{name}_burnt.png")
            meta["props"][f"{name}_burnt"] = dict(meta["props"][name], file=f"{name}_burnt.png", fire_spots=spots)
    fa = meta["floor_atlas"]
    floor_atlas(src, fa["rows"], fa["variants"]).save(out / fa["file"])
    (out / "env.json").write_text(json.dumps(meta, ensure_ascii=False))
    print("환경 그림 교체:", ", ".join(ITEMS))


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
