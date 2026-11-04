#!/usr/bin/env python3
"""그려 받은 병사·NPC 그림 → 게임용 스프라이트 시트(오디세우스용 gen_hero.py를 시트 이름만 바꿔 쓰게 일반화).

    python3 tools/gen_soldier.py .                    # 원본이 있는 시트 전부
    python3 tools/gen_soldier.py . trojan_sword       # 하나만

받는 것(assets/source/):
- <시트>_8dir.webp  기본 8방향 한 장(마젠타 배경, 4×2 칸: 윗줄 N NE E SE / 아랫줄 S SW W NW) — 없으면 그 시트는 건드리지 않는다
- <시트>_<동작>_8dir.webp  (있으면) 그려 받은 동작 줄. 방향마다 받은 것을 pack_strip.py --sheet=<시트>로 묶은 것
  (칸 256×256, 줄 = 남→남동→동→북동→북→북서→서→남서)

대체 규칙(그림이 없을 때):
1. 기본 8방향이 없으면 → 지금 시트(gen_characters.py가 그린 임시 인물)를 그대로 둔다
2. 기본 8방향만 있으면 → 모든 동작을 그 포즈를 기울이고·눌렀다 펴고·회전해 만든다(gen_hero.py와 같은 변형)
3. 동작 줄이 있으면 → 그 동작은 그린 그림을 쓴다. 공격·달리기 크기는 걷기 줄(없으면 기본 포즈) 키에 맞춘다

오디세우스와 다른 점: 병사는 무기를 그림에 같이 그리므로 손 위치(hands)를 만들지 않는다.
프레임 수·속도는 지금 병사 시트와 같다(SOLDIER_ANIMS). 그린 줄의 칸 수가 다르면 그린 칸 수를 쓴다.
출력: assets/sprites/<시트>.png + .json (frame 128, scale 0.5 — 1280×720 창에서 시트 픽셀 1:1)
"""
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from gen_hero import ANCHOR, FRAME, affine, cut_cells, is_bg, params, to_pose  # noqa: E402

DISPLAY_SCALE = 0.5
# 시트 안 키(px) = 게임 안 키 × 2 (sprite_request/soldiers.md의 표)
TARGET_H = {"greek_sword": 96, "greek_spear": 96, "greek_archer": 94, "trojan_sword": 96, "trojan_spear": 96,
            "trojan_archer": 94, "trojan_captain": 112, "trojan_prince": 112, "sinon": 94}
SOLDIER_ANIMS = [
    ("idle", 4, 5, True), ("walk", 6, 10, True), ("run", 6, 13, True),
    ("attack1", 4, 16, False), ("attack2", 4, 16, False), ("attack3", 5, 14, False), ("heavy", 6, 12, False),
    ("block", 2, 6, True), ("bow", 4, 10, False), ("hit", 2, 10, False), ("dodge", 4, 14, False),
    ("death", 5, 9, False), ("interact", 4, 8, True), ("downed", 1, 1, True),
]
STRIP_CELL = 256
STRIP_ROWS = [2, 1, 0, 7, 6, 5, 4, 3]


def strip(root, sheet, anim, k):
    """그린 동작 줄 → {방향: [FRAME 그림…]}. 가로는 칸 가운데, 세로는 그 줄 가장 낮은 발을 ANCHOR에. 없으면 None"""
    path = root / f"assets/source/{sheet}_{anim}_8dir.webp"
    if not path.exists():
        return None
    src = Image.open(path).convert("RGB")
    cols = src.width // STRIP_CELL
    out = {}
    for row, d in enumerate(STRIP_ROWS):
        cells = []
        for c in range(cols):
            cell = src.crop((c * STRIP_CELL, row * STRIP_CELL, (c + 1) * STRIP_CELL, (row + 1) * STRIP_CELL)).convert("RGBA")
            px = cell.load()
            for y in range(cell.height):
                for x in range(cell.width):
                    if is_bg(px[x, y]):
                        px[x, y] = (0, 0, 0, 0)
            cells.append(cell)
        base = max(c.getbbox()[3] for c in cells if c.getbbox())
        out[d] = [to_pose(c, (STRIP_CELL / 2, base), 0, k)[0] for c in cells]
    return out


def build(root, sheet):
    base_path = root / f"assets/source/{sheet}_8dir.webp"
    if not base_path.exists():
        return False
    target = TARGET_H.get(sheet, 96)
    cells = cut_cells(Image.open(base_path).convert("RGB"))
    poses = {}
    ks = []
    for d, (cell, foot, height) in cells.items():
        pose, k, _ = to_pose(cell, foot, height, target / max(h for _, _, h in cells.values()))
        poses[d] = pose
        ks.append(k)
    # 그린 동작 줄의 배율: pack_strip.py가 키를 CHAR_H(216)로 맞춰 두었으므로 target/216
    k_strip = target / 216
    strips = {a: strip(root, sheet, a, k_strip) for a, *_ in SOLDIER_ANIMS}
    anims = [(a, len(strips[a][2]) if strips[a] else n, fps, loop) for a, n, fps, loop in SOLDIER_ANIMS]
    total = sum(n for _, n, _, _ in anims)
    img = Image.new("RGBA", (FRAME * total, FRAME * 8), (0, 0, 0, 0))
    meta = {"frame": [FRAME, FRAME], "anchor": list(ANCHOR), "dirs": 8, "scale": DISPLAY_SCALE, "anims": {},
            "drawn": [a for a, s in strips.items() if s]}
    col = 0
    for anim, n, fps, loop in anims:
        meta["anims"][anim] = {"start": col, "frames": n, "fps": fps, "loop": loop}
        for i in range(n):
            for d in range(8):
                if strips[anim]:
                    fr = strips[anim][d][i]
                else:
                    _, coeffs = affine(params(anim, i, n, d))
                    fr = poses[d].transform((FRAME, FRAME), Image.AFFINE, coeffs, resample=Image.NEAREST)
                img.paste(fr, (FRAME * (col + i), FRAME * d), fr)
        col += n
    out = root / "assets/sprites"
    img.save(out / f"{sheet}.png")
    (out / f"{sheet}.json").write_text(json.dumps(meta, ensure_ascii=False))
    print(f"{sheet}: 기본 포즈 + 그린 동작 {meta['drawn'] or '없음'} → assets/sprites/{sheet}.png")
    return True


if __name__ == "__main__":
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    names = sys.argv[2:] or list(TARGET_H)
    done = [n for n in names if build(root, n)]
    if not done:
        print("원본(assets/source/<시트>_8dir.webp)이 있는 병사 시트가 없다 — 지금 시트(gen_characters.py 임시 인물)를 그대로 둔다")
