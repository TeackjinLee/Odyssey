#!/usr/bin/env python3
"""걷기 8방향을 한 장으로 요청할 때 첨부할 배치 그림을 만든다.

8줄(방향) × 6칸(프레임), 칸 256×256, 마젠타 배경, 발은 칸 아래쪽 같은 기준선.
각 줄 첫 칸에 그 방향의 기준 포즈(원본 odysseus_8dir), 나머지 칸은 흐린 자리 표시.
왼쪽 여백에 방향 이름, 위 여백에 프레임 번호(시트 밖이라 그림에는 섞이지 않게).

출력: docs/sprite_request/walk8_layout.png
사용: python3 tools/gen_walk_request.py <godot 프로젝트 폴더>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from gen_hero import cut_cells  # noqa: E402

CELL = 256
COLS = 6
CHAR_H = 200
BASE_Y = 236
MARGIN_L, MARGIN_T = 220, 48
# 요청 그림의 줄 순서(남에서 시계 방향) → 게임 방향 번호
ROWS = [("S  front", 2), ("SE  front-right", 1), ("E  right", 0), ("NE  back-right", 7),
        ("N  back", 6), ("NW  back-left", 5), ("W  left", 4), ("SW  front-left", 3)]
MAGENTA = (255, 0, 255, 255)


def font(size):
    for p in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()


def main(root):
    cells = cut_cells(Image.open(root / "assets/source/odysseus_8dir.webp"))
    W, H = MARGIN_L + CELL * COLS, MARGIN_T + CELL * len(ROWS)
    im = Image.new("RGBA", (W, H), (255, 255, 255, 255))
    dr = ImageDraw.Draw(im)
    f, fs = font(26), font(22)
    for c in range(COLS):
        dr.text((MARGIN_L + c * CELL + CELL // 2 - 30, 12), f"frame {c + 1}", fill=(40, 40, 40), font=fs)
    for r, (label, d) in enumerate(ROWS):
        y0 = MARGIN_T + r * CELL
        dr.text((14, y0 + CELL // 2 - 14), label, fill=(20, 20, 20), font=f)
        cell, foot, height = cells[d]
        k = CHAR_H / height
        pose = cell.resize((round(cell.width * k), round(cell.height * k)), Image.LANCZOS)
        for c in range(COLS):
            x0 = MARGIN_L + c * CELL
            dr.rectangle((x0, y0, x0 + CELL - 1, y0 + CELL - 1), fill=MAGENTA, outline=(255, 255, 255), width=2)
            p = pose if c == 0 else Image.blend(Image.new("RGBA", pose.size, (0, 0, 0, 0)), pose, 0.22)
            im.paste(p, (round(x0 + CELL / 2 - foot[0] * k), round(y0 + BASE_Y - foot[1] * k)), p)
            dr.line((x0 + 16, y0 + BASE_Y, x0 + CELL - 16, y0 + BASE_Y), fill=(255, 255, 255), width=1)
    out = root / "docs/sprite_request/walk8_layout.png"
    im.convert("RGB").save(out)
    print(out, im.size)


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
