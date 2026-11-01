#!/usr/bin/env python3
"""임시 무기 그림 (오디세우스 시트와 같은 밀도: 캐릭터 키 104px 기준).

그려 받은 무기로 바꿀 때 지킬 규칙 (assets/weapons/weapons.json):
  - 검·창: 날 끝이 위를 향하게 똑바로 세워 그린다. grip = 손이 쥐는 지점(그림 픽셀 좌표)
  - 방패: 정면(front)·비스듬히(three_quarter, 앞면이 오른쪽을 봄)·옆(side)·뒷면(back) 네 장. grip = 팔에 걸리는 중심
  - 활: 활대가 위아래로 서고 등(바깥쪽)이 오른쪽을 향하게. grip = 줌통
  - 배경은 투명. 크기가 달라도 grip만 맞으면 된다

사용: python3 gen_weapons.py <godot 프로젝트 폴더>
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

OUT = (24, 14, 10, 255)


def outline(img):
    src = img.copy().load()
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3]:
                    px[x, y] = OUT
                    break


def sword():
    img = Image.new("RGBA", (13, 50), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 잎사귀 모양 청동 날 (크시포스)
    d.polygon([(6, 1), (9, 10), (9, 30), (8, 36), (4, 36), (3, 30), (3, 10)], fill=(214, 168, 84, 255))
    d.line([(6, 3), (6, 35)], fill=(250, 226, 150, 255))
    d.line([(4, 12), (4, 34)], fill=(160, 112, 50, 255))
    d.rectangle([1, 37, 11, 38], fill=(196, 150, 60, 255))  # 날밑
    d.rectangle([5, 39, 7, 45], fill=(92, 52, 30, 255))     # 손잡이
    d.ellipse([3, 45, 9, 49], fill=(204, 160, 70, 255))     # 자루끝
    outline(img)
    return img, [6, 42]


def shield_views():
    views = {}
    R = 17
    size = R * 2 + 4
    rim, face, emblem, back = (150, 100, 40), (196, 146, 62), (150, 32, 30), (120, 82, 48)
    for name, kx in (("front", 1.0), ("three_quarter", 0.62), ("side", 0.24), ("back", 1.0)):
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        cx, cy = size / 2, size / 2
        rx = R * kx
        if name == "back":
            d.ellipse([cx - rx, cy - R, cx + rx, cy + R], fill=back + (255,))
            d.ellipse([cx - rx + 2, cy - R + 2, cx + rx - 2, cy + R - 2], outline=rim + (255,))
            d.rectangle([cx - 6, cy - 2, cx + 6, cy + 1], fill=(70, 46, 30, 255))  # 손잡이 끈
        elif name == "side":
            d.ellipse([cx - rx, cy - R, cx + rx, cy + R], fill=rim + (255,))
            d.ellipse([cx - rx + 2, cy - R + 2, cx + rx, cy + R - 2], fill=face + (255,))
        else:
            d.ellipse([cx - rx, cy - R, cx + rx, cy + R], fill=rim + (255,))
            d.ellipse([cx - rx + 2, cy - R + 2, cx + rx - 2, cy + R - 2], fill=face + (255,))
            d.ellipse([cx - rx * 0.4, cy - R * 0.4, cx + rx * 0.4, cy + R * 0.4], fill=emblem + (255,))
            d.arc([cx - rx + 4, cy - R + 4, cx + rx - 4, cy + R - 4], 200, 290, fill=(240, 200, 120, 255))
            if name == "three_quarter":
                d.ellipse([cx + rx - 3, cy - R + 3, cx + rx, cy + R - 3], fill=rim + (255,))
        outline(img)
        views[name] = img
    return views, [size // 2, size // 2]


def bow():
    img = Image.new("RGBA", (16, 54), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.arc([-14, 2, 12, 52], -70, 70, fill=(120, 74, 38, 255), width=3)
    d.line([(3, 4), (3, 50)], fill=(232, 226, 210, 255))
    d.rectangle([9, 23, 12, 31], fill=(70, 46, 30, 255))
    outline(img)
    return img, [10, 27]


def main():
    out = Path(sys.argv[1]) / "assets/weapons"
    out.mkdir(parents=True, exist_ok=True)
    meta = {"scale": 0.5}
    img, grip = sword()
    img.save(out / "sword.png")
    meta["sword"] = {"file": "sword.png", "grip": grip}
    views, grip = shield_views()
    meta["shield"] = {"views": {}, "grip": grip}
    for k, v in views.items():
        v.save(out / f"shield_{k}.png")
        meta["shield"]["views"][k] = f"shield_{k}.png"
    img, grip = bow()
    img.save(out / "bow.png")
    meta["bow"] = {"file": "bow.png", "grip": grip}
    (out / "weapons.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))
    print("무기", list(meta))


if __name__ == "__main__":
    main()
