#!/usr/bin/env python3
"""한 장에 여러 방향(줄)을 받은 그림을 방향별 파일로 자른다(공격 요청 — motion_kit/README.md).
사용: python3 tools/split_rows.py <받은 그림> <동작> <방향,방향,...> <godot 프로젝트 폴더> [한 장의 줄 수]
  방향은 그림의 위→아래 줄 순서. 줄 수 기본값: heavy는 2, 나머지(attack1·2·3, idle hit block dodge bow death interact)는 3(motion_request.py의 ROWS_PER_IMAGE).
저장: assets/source/odysseus_<동작>_<방향>.webp → 이어서 python3 tools/pack_strip.py . <동작> <프레임 수> 1
"""
import sys
from pathlib import Path

from PIL import Image

ROWS = {"attack1": 3, "attack2": 3, "attack3": 3, "heavy": 2,
        "idle": 3, "hit": 3, "block": 3, "dodge": 3, "bow": 3, "death": 3, "interact": 3, "throw": 3}

if __name__ == "__main__":
    src, anim, dirs, root = Image.open(sys.argv[1]).convert("RGB"), sys.argv[2], sys.argv[3].split(","), Path(sys.argv[4])
    rows = int(sys.argv[5]) if len(sys.argv) > 5 else ROWS[anim]
    h = src.height / rows
    for i, d in enumerate(dirs):
        out = root / f"assets/source/odysseus_{anim}_{d}.webp"
        src.crop((0, round(i * h), src.width, round((i + 1) * h))).save(out, lossless=True)
        print(out.relative_to(root))
