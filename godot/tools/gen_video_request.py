#!/usr/bin/env python3
"""동영상 생성기로 8방향 걷기를 받을 때 방향마다 첨부할 시작 그림을 만든다.

원본 8방향 기준 포즈(odysseus_8dir)를 픽셀 그대로 2배 키워 1024×1024 마젠타 바탕 가운데에,
발은 모든 그림에서 같은 높이(BASE_Y)에 둔다.

출력: docs/sprite_request/video/start_<방향>.png (S SE E NE N NW W SW)
      + start_8dir.png — 한 동영상에 8방향을 다 넣을 때: 1920×1080, 4열×2줄 칸(480×540)에 한 명씩, 발은 칸마다 같은 높이
사용: python3 tools/gen_video_request.py <godot 프로젝트 폴더>
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from gen_hero import cut_cells  # noqa: E402

SIZE = 1024
ZOOM = 2
BASE_Y = 930
MAGENTA = (255, 0, 255, 255)
GRID = (1920, 1080, 4, 2)
GRID_BASE = 500         # 칸 안 발 높이(칸 높이 540)
DIRS = [("S", 2), ("SE", 1), ("E", 0), ("NE", 7), ("N", 6), ("NW", 5), ("W", 4), ("SW", 3)]


def main(root):
    cells = cut_cells(Image.open(root / "assets/source/odysseus_8dir.webp"))
    out = root / "docs/sprite_request/video"
    out.mkdir(parents=True, exist_ok=True)
    for name, d in DIRS:
        cell, foot, _ = cells[d]
        big = cell.resize((cell.width * ZOOM, cell.height * ZOOM), Image.NEAREST)
        im = Image.new("RGBA", (SIZE, SIZE), MAGENTA)
        im.paste(big, (round(SIZE / 2 - foot[0] * ZOOM), round(BASE_Y - foot[1] * ZOOM)), big)
        im.convert("RGB").save(out / f"start_{name}.png")
    W, H, cols, rows = GRID
    cw, ch = W // cols, H // rows
    grid = Image.new("RGBA", (W, H), MAGENTA)
    for i, (name, d) in enumerate(DIRS):
        cell, foot, _ = cells[d]
        x0, y0 = (i % cols) * cw, (i // cols) * ch
        grid.paste(cell, (round(x0 + cw / 2 - foot[0]), round(y0 + GRID_BASE - foot[1])), cell)
    grid.convert("RGB").save(out / "start_8dir.png")
    print(out)


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
