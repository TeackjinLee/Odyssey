#!/usr/bin/env python3
"""그리스 노꾼 노 젓기(그려 받은 4열×5줄, 칸 384×204, 마젠타 배경) → assets/sprites/greek_rower.png/.json (192 칸 8방향, 동작 row 4장).

받은 줄 = E·SE·S·NE·N, 서쪽 셋(SW·W·NW)은 SE·E·NE를 좌우로 뒤집는다. 크기는 앉은 키가 TARGET_H(그리스 병사 sit와 비슷)가 되게,
줄마다 네 장에 같은 배율·같은 위치를 써서 엉덩이·발이 움직이지 않게 한다(발 밑 = 기준점 y 181).
ship.gd가 노의 위상에 맞춰 프레임을 고른다(뻗기 → 당기기 시작 → 끝까지 당김 → 돌아오기). 요청 묶음: sprite_request/supplement_2026-11-05/greek_row/

    python3 tools/gen_rower.py . && python3 tools/gen_ship_crew.py .
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SRC = "assets/source/greek_rower_row.png"
CELL = (384, 204)
TARGET_H = 74
FOOT_Y = 181
ORDER = ["E", "SE", "S", "NE", "N"]
# 게임 방향 0 동 1 남동 2 남 3 남서 4 서 5 북서 6 북 7 북동 → (받은 줄, 뒤집기)
DIRS = [("E", False), ("SE", False), ("S", False), ("SE", True), ("E", True), ("NE", True), ("N", False), ("NE", False)]


def key(im):
    a = np.asarray(im.convert("RGBA")).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    bg = (r > 150) & (b > 150) & (g < 110) & (np.abs(r - b) < 90)
    a[..., 3] = np.where(bg, 0, 255)
    # 가장자리의 분홍 번짐을 어둡게(테두리 색)
    edge = (r > 140) & (b > 120) & (g < 120) & ~bg
    a[edge, 0:3] = [40, 28, 30]
    return Image.fromarray(a.astype(np.uint8))


def main(root):
    r = Path(root)
    src = key(Image.open(r / SRC))
    cells = {}
    for ri, name in enumerate(ORDER):
        frames = [src.crop((c * CELL[0], ri * CELL[1], (c + 1) * CELL[0], (ri + 1) * CELL[1] - 4)) for c in range(4)]
        for f in frames:   # 칸 맨 위로 넘어온 윗줄 발끝 조각 지우기(인물 머리는 그 아래에 있다)
            f.paste((0, 0, 0, 0), (0, 0, CELL[0], 16))
        boxes = [f.getbbox() for f in frames]
        x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
        x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
        k = TARGET_H / max(b[3] - b[1] for b in boxes)
        # 기준 가로: 첫 장의 아래쪽 20px(발·엉덩이) 가운데
        f0 = np.asarray(frames[0])[..., 3]
        low = f0[boxes[0][3] - 20:boxes[0][3]]
        xs = np.nonzero(low.any(0))[0]
        cx = (xs[0] + xs[-1]) / 2.0
        out = []
        for f in frames:
            u = f.crop((x0, y0, x1, y1))
            u = u.resize((max(1, round(u.width * k)), max(1, round(u.height * k))), Image.LANCZOS)
            cell = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
            cell.alpha_composite(u, (round(96 - (cx - x0) * k), round(FOOT_Y - (y1 - y0) * k)))
            a = np.asarray(cell).copy(); a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
            out.append(Image.fromarray(a))
        cells[name] = out
    sheet = Image.new("RGBA", (192 * 4, 192 * 8), (0, 0, 0, 0))
    for d, (name, flip) in enumerate(DIRS):
        for i, c in enumerate(cells[name]):
            sheet.paste(c.transpose(Image.FLIP_LEFT_RIGHT) if flip else c, (i * 192, d * 192))
    sheet.save(r / "assets/sprites/greek_rower.png")
    meta = {"frame": [192, 192], "anchor": [96, FOOT_Y], "dirs": 8, "scale": 0.5,
            "anims": {"row": {"start": 0, "frames": 4, "fps": 4, "loop": True}}}
    (r / "assets/sprites/greek_rower.json").write_text(json.dumps(meta))
    print("greek_rower 시트:", sheet.size)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
