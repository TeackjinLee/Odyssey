#!/usr/bin/env python3
"""그려 받은 동물 원본 → assets/sprites/animal_<종류>.png/.json (ART_PLAN C-ANI-*, docs/sprite_request/animal_kit/).

원본(assets/source/):
  animal_<종류>_move.webp  6열×4줄(칸 256): 걷기 SE · 걷기 NE · 달아나기 SE · 달아나기 NE
  animal_<종류>_idle.webp  6열×4줄(칸 256): 쉬기 SE · 쉬기 NE · 쓰러짐 SE · 쓰러짐 NE
  animal_<종류>_8dir.webp  기본 8방향(생김새 기준 — 시트에는 안 씀)
시트: 줄 0 = 남동(SE), 줄 1 = 북동(NE) — 서쪽은 animal.gd가 좌우로 뒤집는다. 열 = 동작 프레임.
사용: python3 tools/gen_animal.py . [종류 ...]   (godot/ 안에서, 종류를 빼면 원본이 있는 것 전부)
"""
import json
import sys
from pathlib import Path

from PIL import Image

# 게임 안 키(px, 오디세우스 52) — 시트는 두 배로 그리고 scale 0.5로 그린다
HEIGHT = {"chicken": 18, "goat": 28, "sheep": 30, "boar": 30, "deer": 44}
SCALE = 0.5
COLS, ROWS = 6, 4
# (동작, 원본, 원본의 SE 줄, NE 줄, fps, loop)
ANIMS = [
    ("idle", "idle", 0, 1, 5, True),
    ("walk", "move", 0, 1, 10, True),
    ("run", "move", 2, 3, 16, True),
    ("death", "idle", 2, 3, 9, False),
]
# 잘못 그려 온 줄 대신 쓸 줄: 종류 → {(동작, 시트 줄): 원본 줄}
# 염소 북동 쓰러짐은 첫 두 칸에 날개가, 양 북동 쓰러짐은 끝까지 눕지 않게 그려 와서 남동 줄을 씀
ROW_FIX = {"goat": {("death", 1): 2}, "sheep": {("death", 1): 2}}


def is_bg(c):
    r, g, b = c[:3]
    return r > 150 and b > 150 and g < 120 and abs(r - b) < 70


def cells(src):
    """원본 한 장 → [줄][열] 배경을 지운 RGBA 칸."""
    cw, ch = src.width // COLS, src.height // ROWS
    out = []
    for r in range(ROWS):
        row = []
        for c in range(COLS):
            cell = src.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)).convert("RGBA")
            px = cell.load()
            for y in range(ch):
                for x in range(cw):
                    if is_bg(px[x, y]):
                        px[x, y] = (0, 0, 0, 0)
            row.append(cell)
        out.append(row)
    return out


def shrink(cell, k):
    small = cell.resize((max(1, round(cell.width * k)), max(1, round(cell.height * k))), Image.LANCZOS)
    px = small.load()
    for y in range(small.height):
        for x in range(small.width):
            r, g, b, a = px[x, y]
            if a < 140:
                px[x, y] = (0, 0, 0, 0)
            elif r > g + 70 and b > g + 70:   # 남은 마젠타 테두리
                px[x, y] = (40, 20, 20, 255)
            else:
                px[x, y] = (min(255, round(r * 255 / a)), min(255, round(g * 255 / a)), min(255, round(b * 255 / a)), 255)
    return small


def foot(cell):
    """발 기준점: 그림 맨 아래, 아래쪽 12%의 가운데."""
    bb = cell.getbbox()
    low = cell.crop((0, bb[3] - max(2, int((bb[3] - bb[1]) * 0.12)), cell.width, bb[3])).getbbox()
    return (low[0] + low[2]) / 2, bb[3]


def build(root, kind):
    src = {n: cells(Image.open(root / f"assets/source/animal_{kind}_{n}.webp")) for n in ("move", "idle")}
    stand = sorted(c.getbbox()[3] - c.getbbox()[1] for c in src["move"][0])
    k = HEIGHT[kind] / SCALE / stand[len(stand) // 2]
    side = round(src["move"][0][0].width * k * 1.3)
    frame = (side, side)
    anchor = (side // 2, side - 3)
    total = sum(COLS for _ in ANIMS)
    sheet = Image.new("RGBA", (frame[0] * total, frame[1] * 2), (0, 0, 0, 0))
    anims, col = {}, 0
    for name, file, se, ne, fps, loop in ANIMS:
        for d, row in enumerate((se, ne)):
            line = src[file][ROW_FIX.get(kind, {}).get((name, d), row)]
            # 줄 안에서 발 x는 가운데값 하나로(걸을 때 몸이 좌우로 떨지 않게), 발 y는 칸마다(땅에 붙게)
            xs = sorted(foot(c)[0] for c in line)
            fx = xs[len(xs) // 2]
            for i, cell in enumerate(line):
                small = shrink(cell, k)
                fy = foot(cell)[1]
                fr = Image.new("RGBA", frame, (0, 0, 0, 0))   # 칸 밖으로 넘친 것은 잘린다(옆 칸 침범 없음)
                fr.paste(small, (round(anchor[0] - fx * k), round(anchor[1] - fy * k)), small)
                sheet.paste(fr, ((col + i) * frame[0], d * frame[1]))
        anims[name] = {"start": col, "frames": COLS, "fps": fps, "loop": loop}
        col += COLS
    sheet.save(root / f"assets/sprites/animal_{kind}.png")
    meta = {"frame": list(frame), "anchor": list(anchor), "dirs": 2, "scale": SCALE, "anims": anims}
    (root / f"assets/sprites/animal_{kind}.json").write_text(json.dumps(meta))
    print(f"animal_{kind}: 칸 {frame}, 키 {HEIGHT[kind]}px, 축소 {k:.3f}")


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    kinds = sys.argv[2:] or [k for k in HEIGHT if (root / f"assets/source/animal_{k}_move.webp").exists()]
    for kind in kinds:
        build(root, kind)


if __name__ == "__main__":
    main()
