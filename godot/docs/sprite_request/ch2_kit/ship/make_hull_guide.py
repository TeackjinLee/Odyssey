#!/usr/bin/env python3
"""갤리선 선체 16방향 요청용 안내 그림: 게임의 쿼터뷰(2:1) 투영으로 회색 선체 실루엣을 정확한 각도·크기로 그린다.
칸 512×512, 3열×2줄, 1536×1024 두 장(hull_guide_a: E ESE SE / SSE S ENE, hull_guide_b: NE NNE N).
뱃머리 끝 = 빨간 삼각형, 고물 = 짙은 기둥. 그림을 그리는 쪽은 실루엣 위에 같은 자리·크기·각도로 배를 그린다.
선체 길이:폭 = 4.2:1, 동쪽 칸 선체 길이 ≈ 420px. 사용: python3 make_hull_guide.py (이 폴더에서)
키코네스 배: python3 make_hull_guide.py cicones → cicones_hull_guide_{a,b}.png. 같은 배율(격자 1칸 66px)에 길이 3.3·폭 4:1·갑판 36px
(게임에서 갤리선 3.2 : 키코네스 배 2.3과 같은 비율이라 두 배의 픽셀 밀도가 같다). gen_ship.py의 HULL_GUIDE와 값을 맞춘다."""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).parent
P = 66.0                      # 격자 1칸 = 화면 (P, P/2) — 동쪽(화면 가로) 길이 = L·P·√2
KINDS = {"galley": (4.5, 4.5 / 4.2, 46, ""), "cicones": (3.3, 3.3 / 4.0, 36, "cicones_")}
KIND = sys.argv[1] if len(sys.argv) > 1 else "galley"
L, W, H, PREFIX = KINDS[KIND]  # 선체 길이·폭(격자), 갑판 높이(px), 파일 이름 앞
SHOTS = {"a": ["E", "ESE", "SE", "SSE", "S", "ENE"], "b": ["NE", "NNE", "N"]}
ANG = {"E": 0, "ESE": 22.5, "SE": 45, "SSE": 67.5, "S": 90, "ENE": -22.5, "NE": -45, "NNE": -67.5, "N": -90}


def to_screen(gx, gy):
    return ((gx - gy) * P, (gx + gy) * P / 2)


def grid_dir(screen_deg):
    """화면 방향(도, 아래가 +) → 격자 방향 단위 벡터."""
    sx, sy = math.cos(math.radians(screen_deg)), math.sin(math.radians(screen_deg))
    gx, gy = sx / 2 + sy, -sx / 2 + sy     # to_screen의 역
    n = math.hypot(gx, gy)
    return gx / n, gy / n


def outline(f, r, k, h):
    """갑판(또는 용골) 윤곽: 뾰족한 뱃머리, 둥근 고물."""
    pts = []
    for lx, ly in [(1, 0), (0.75, 0.42), (0.4, 0.5), (-0.4, 0.5), (-0.75, 0.42), (-0.95, 0.2), (-0.95, -0.2),
                   (-0.75, -0.42), (-0.4, -0.5), (0.4, -0.5), (0.75, -0.42)]:
        gx = f[0] * lx * L / 2 * k + r[0] * ly * W * k
        gy = f[1] * lx * L / 2 * k + r[1] * ly * W * k
        x, y = to_screen(gx, gy)
        pts.append((x, y - h))
    return pts


def cell(name):
    im = Image.new("RGB", (512, 512), (255, 0, 255))
    d = ImageDraw.Draw(im)
    f = grid_dir(ANG[name])
    r = (-f[1], f[0])
    c = lambda pts: [(x + 256, y + 300) for x, y in pts]
    keel, deck = c(outline(f, r, 0.88, 0)), c(outline(f, r, 1.0, H))
    for i in range(len(keel)):     # 옆면
        j = (i + 1) % len(keel)
        d.polygon([keel[i], keel[j], deck[j], deck[i]], fill=(120, 120, 128))
    d.polygon(deck, fill=(200, 200, 205), outline=(60, 60, 66))
    bx, by = c([to_screen(f[0] * L / 2, f[1] * L / 2)])[0]
    d.polygon([(bx, by - H - 14), (bx - 9, by - H + 4), (bx + 9, by - H + 4)], fill=(220, 30, 30))
    sx, sy = c([to_screen(-f[0] * L / 2 * 0.95, -f[1] * L / 2 * 0.95)])[0]
    d.rectangle((sx - 4, sy - H - 40, sx + 4, sy - H), fill=(50, 50, 56))
    return im


if __name__ == "__main__":
    for key, names in SHOTS.items():
        out = Image.new("RGB", (1536, 1024), (255, 0, 255))
        for i, n in enumerate(names):
            out.paste(cell(n), (i % 3 * 512, i // 3 * 512))
        out.save(HERE / f"{PREFIX}hull_guide_{key}.png")
    print(f"{PREFIX}hull_guide_a.png · {PREFIX}hull_guide_b.png")
