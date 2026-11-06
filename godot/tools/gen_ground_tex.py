#!/usr/bin/env python3
"""이음매 없는 바닥 무늬(그려 받은 1장, 4×4 블록 픽셀아트) → assets/env/ground_<이름>.png (게임 px, 반복해서 깖).

챕터 2처럼 레벨이 soft_coast면 water.gdshader가 그 종류 칸을 칸 그림 대신 이 무늬로 월드 좌표에 깐다 → 칸 테두리가 안 보인다.
요청 묶음: docs/sprite_request/env_requests/ch2_sand_tex/(모래)·ch2_ground_tex/(풀·흙)

    python3 tools/gen_ground_tex.py .
"""
import sys
from pathlib import Path

from PIL import Image

# 원본 → (출력 이름, 블록 크기 = 원본 px / 게임 px)
SOURCES = {"ground_sand_shore.png": ("ground_sand.png", 4), "ground_grass_dry.png": ("ground_grass.png", 4),
           "ground_dirt_path.png": ("ground_dirt.png", 4)}


def main(root: str) -> None:
    r = Path(root)
    for src, (dst, block) in SOURCES.items():
        p = r / "assets/source" / src
        if not p.exists():
            print("없음:", p)
            continue
        im = Image.open(p).convert("RGB")
        n = round(im.width / block)
        # 블록 가운데 색을 뽑는다(가장자리 흐림 없이). 원본이 이음매 없으니 n×n도 이음매 없음
        out = im.resize((n, round(im.height / block)), Image.NEAREST, reducing_gap=None)
        out.save(r / "assets/env" / dst)
        print(dst, out.size)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
