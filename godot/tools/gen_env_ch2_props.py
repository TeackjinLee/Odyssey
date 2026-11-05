#!/usr/bin/env python3
"""챕터 2 로토스 섬·항구 소품 두 장 → assets/env/<이름>.png + env.json 항목.

    python3 tools/gen_env_ch2_props.py .

환경 변환 순서의 맨 끝(gen_env_redraw 다음)에 돌린다. 원본: assets/source/env_lotus_props.png·env_harbor_props.png
(요청 묶음 docs/sprite_request/next_batch_2026-11-05/, 1536×1024, 4열×2행, 칸 384×512).
받은 그림의 배경이 #282B35 단색이 아니고 미세한 얼룩이 있어서, 칸 테두리에서 시작해 이웃 색이 비슷한 곳만 지운다(채우기).
"""
import json
import os
import sys
from collections import deque

from PIL import Image

# 이름, 게임 가로 폭(px) — 올리브(86)·덤불(59)·상자(41)·암포라(31)와 맞춘다
SHEETS = {
    "env_lotus_props.png": [("lotus_tree_fruit", 90), ("lotus_tree_flower", 90), ("lotus_tree_picked", 90), ("lotus_bush", 56),
                            ("lotus_basket", 28), ("lotus_fruit_cluster", 22), ("lotus_flower_patch", 40), ("lotus_reeds", 40)],
    "env_harbor_props.png": [("harbor_net", 46), ("harbor_rope", 30), ("harbor_bollard", 22), ("harbor_fish_basket", 34),
                             ("harbor_amphorae", 46), ("harbor_cargo", 44), ("harbor_ramp", 56), ("harbor_oars", 44)],
}
CW, CH = 384, 512
TOL = 30


def clear_bg(c):
    w, h = c.size
    px = c.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0, px[x, 0])); q.append((x, h - 1, px[x, h - 1]))
    for y in range(h):
        q.append((0, y, px[0, y])); q.append((w - 1, y, px[w - 1, y]))
    while q:
        x, y, ref = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y * w + x]:
            continue
        r, g, b, _ = px[x, y]
        if abs(r - ref[0]) + abs(g - ref[1]) + abs(b - ref[2]) > TOL or max(r, g, b) > 80:
            continue
        seen[y * w + x] = 1
        px[x, y] = (0, 0, 0, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q.append((x + dx, y + dy, (r, g, b)))


def bg_like(r, g, b):
    return max(r, g, b) < 75 and b >= r + 6 and b >= g + 3      # 남색 배경(#282B35 언저리), 갈색·검은 외곽선은 아님


def clear_holes(c, min_size=30):
    """가지·난간 사이에 갇힌 배경 덩어리(min_size px 이상)도 지운다."""
    w, h = c.size
    px = c.load()
    seen = bytearray(w * h)
    for sy in range(h):
        for sx in range(w):
            if seen[sy * w + sx]:
                continue
            r, g, b, a = px[sx, sy]
            if a == 0 or not bg_like(r, g, b):
                continue
            comp, q = [], deque([(sx, sy)])
            seen[sy * w + sx] = 1
            while q:
                x, y = q.popleft()
                comp.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                        r, g, b, a = px[nx, ny]
                        if a and bg_like(r, g, b):
                            seen[ny * w + nx] = 1
                            q.append((nx, ny))
            if len(comp) >= min_size:
                for x, y in comp:
                    px[x, y] = (0, 0, 0, 0)


def main(root):
    env = os.path.join(root, "assets/env")
    meta = json.load(open(os.path.join(env, "env.json")))
    for sheet, items in SHEETS.items():
        im = Image.open(os.path.join(root, "assets/source", sheet)).convert("RGBA").resize((1536, 1024), Image.LANCZOS)
        for i, (name, gw) in enumerate(items):
            x, y = (i % 4) * CW, (i // 4) * CH
            c = im.crop((x, y, x + CW, y + CH))
            clear_bg(c)
            clear_holes(c)
            c = c.crop(c.getbbox())
            gh = max(1, round(c.height * gw / c.width))
            s = c.convert("RGBa").resize((gw, gh), Image.LANCZOS).convert("RGBA")
            sp = s.load()
            for yy in range(gh):
                for xx in range(gw):
                    r, g, b, a = sp[xx, yy]
                    sp[xx, yy] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
            s = s.crop(s.getbbox())
            s.save(os.path.join(env, name + ".png"))
            # 기준점: 가장 아래 불투명 줄의 가운데, 조금 위(gen_env_redraw와 같은 규칙)
            bottom = max(yy for yy in range(s.height) for xx in range(s.width) if s.getpixel((xx, yy))[3])
            xs = [xx for xx in range(s.width) if s.getpixel((xx, bottom))[3]]
            meta["props"][name] = {"file": name + ".png", "anchor": [round(sum(xs) / len(xs)), max(0, bottom - 3)],
                                   "footprint": [1, 1], "size": [s.width, s.height]}
            print(name, s.size)
    json.dump(meta, open(os.path.join(env, "env.json"), "w"), ensure_ascii=False)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
