#!/usr/bin/env python3
"""그림 요청 때 같이 첨부하거나 보고 쓰는 참고 그림을 만든다. 출력은 docs/sprite_request/layouts/.

  turnaround
      새 캐릭터의 **기본 8방향 시트**를 받을 때 첨부하는 배치 그림. 오디세우스 기본 시트와 같은 규격:
      1536×1024, 4칸 × 2줄, 칸 384×512, 윗줄 N NE E SE / 아랫줄 S SW W NW (gen_hero.py·motion_request.py가 읽는 순서).
      칸 안에는 오디세우스 실루엣을 회색으로 흐리게 넣어 크기·방향·발 위치만 알려 준다(생김새는 따라 그리지 않게).
      방향 이름은 그림 위·아래 여백에만 쓴다(받는 그림에는 여백이 없다).
      → layouts/turnaround_4x2.png

  scale
      게임 안 크기 비교표(640×360 기준 논리 픽셀 × 3배). 바닥 칸·오디세우스·성탑·집·목마는 실제 그림,
      아직 없는 인물은 회색 실루엣과 목표 키로 표시.
      → layouts/scale_chart.png

  all
      둘 다

걷기·달리기·공격·나머지 동작 요청은 이 도구가 아니라 tools/motion_request.py가 만든다(docs/sprite_request/motion_kit/README.md).
사용: python3 tools/gen_request_layout.py <godot 프로젝트 폴더> <turnaround|scale|all>
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from gen_hero import cut_cells  # noqa: E402

CW, CH = 384, 512        # 기본 8방향 시트 칸
CHAR_H = 340             # 칸 안 서 있는 키
BASE_Y = 488             # 칸 안 발 기준선
MAGENTA = (255, 0, 255, 255)
# 4×2 기본 시트 배치(gen_hero.CELL_DIR와 같은 순서) — (이름, 게임 방향 번호)
TURN = [[("N  back", 6), ("NE  back-right", 7), ("E  right", 0), ("SE  front-right", 1)],
        [("S  front", 2), ("SW  front-left", 3), ("W  left", 4), ("NW  back-left", 5)]]


def font(size):
    for p in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "C:/Windows/Fonts/arialbd.ttf"):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default(size)


def out_dir(root):
    d = root / "docs/sprite_request/layouts"
    d.mkdir(parents=True, exist_ok=True)
    return d


def hero_cells(root):
    for ext in ("webp", "png"):
        p = root / f"assets/source/odysseus_8dir.{ext}"
        if p.exists():
            return cut_cells(Image.open(p))
    raise SystemExit("assets/source/odysseus_8dir.* 가 없다")


def scaled(cell, foot, height, h):
    k = h / height
    return cell.resize((round(cell.width * k), round(cell.height * k)), Image.LANCZOS), (foot[0] * k, foot[1] * k)


def silhouette(img, rgb=(40, 40, 48), alpha=0.32):
    s = Image.new("RGBA", img.size, rgb + (0,))
    s.putalpha(img.getchannel("A").point(lambda v: round(v * alpha)))
    return s


def turnaround(root):
    cells = hero_cells(root)
    top = bottom = 48
    W, H = CW * 4, top + CH * 2 + bottom
    im = Image.new("RGBA", (W, H), (255, 255, 255, 255))
    dr = ImageDraw.Draw(im)
    f = font(22)
    for r, row in enumerate(TURN):
        y0 = top + r * CH
        for c, (label, d) in enumerate(row):
            x0 = c * CW
            dr.rectangle((x0, y0, x0 + CW - 1, y0 + CH - 1), fill=MAGENTA, outline=(255, 255, 255), width=2)
            pose, foot = scaled(*cells[d], CHAR_H)
            ghost = silhouette(pose)
            im.paste(ghost, (round(x0 + CW / 2 - foot[0]), round(y0 + BASE_Y - foot[1])), ghost)
            dr.line((x0 + 20, y0 + BASE_Y, x0 + CW - 20, y0 + BASE_Y), fill=(255, 255, 255), width=1)
            ty = 12 if r == 0 else top + CH * 2 + 12
            dr.text((x0 + 14, ty), f"{r + 1}-{c + 1}  {label}", fill=(20, 20, 20), font=f)
    out = out_dir(root) / "turnaround_4x2.png"
    im.convert("RGB").save(out)
    print(out, im.size)


def scale_chart(root):
    K = 3                                    # 논리 px → 표의 px
    env = json.loads((root / "assets/env/env.json").read_text())
    cells = hero_cells(root)
    bg, ink, dim = (40, 43, 53, 255), (235, 235, 240), (150, 155, 170)
    items = []                               # (그림, 바닥에 닿는 점, 이름, 크기 글, 키)

    def person(title, h, real=False, rgb=(120, 125, 140), bulk=1.0):
        pose, foot = scaled(*cells[2], h * K)
        if bulk != 1.0:
            pose = pose.resize((round(pose.width * bulk), pose.height), Image.LANCZOS)
            foot = (foot[0] * bulk, foot[1])
        img = pose if real else silhouette(pose, rgb, 0.9)
        items.append((img, foot, title, f"height {h}px" + ("" if real else " (planned)"), h * K))

    def prop(name, title):
        p = env["props"][name]
        img = Image.open(root / "assets/env" / p["file"]).convert("RGBA")
        img = img.resize((img.width * K, img.height * K), Image.NEAREST)
        items.append((img, (p["anchor"][0] * K, p["anchor"][1] * K), title, f"{p['size'][0]}x{p['size'][1]}px",
                      p["anchor"][1] * K))

    atlas = Image.open(root / "assets/env/floor_atlas.png").convert("RGBA")
    tile = atlas.crop((0, 0, 64, 32)).resize((64 * K, 32 * K), Image.NEAREST)
    items.append((tile, (32 * K, 16 * K), "floor tile", "64x32px", 16 * K))
    person("Odysseus", 52, real=True)        # gen_hero: 시트 104px × scale 0.5
    person("soldier", 48, rgb=(70, 120, 125))
    person("Trojan captain", 56, rgb=(110, 70, 120))
    prop("tower", "tower")
    prop("house_a", "house")
    prop("horse", "wooden horse")
    person("Polyphemus (ch3)", 150, rgb=(150, 95, 60), bulk=1.2)

    gap, col_min = 50, 210
    widths = [max(img.width, col_min) for img, *_ in items]
    ground = round(max(foot[1] for _, foot, *_ in items) + 90)
    below = max(img.height - foot[1] for img, foot, *_ in items)
    W = sum(widths) + gap * (len(items) + 1)
    H = ground + round(below) + 90
    im = Image.new("RGBA", (W, H), bg)
    dr = ImageDraw.Draw(im)
    f, fs = font(26), font(19)
    dr.text((24, 18), "ODYSSEY scale chart  -  in-game logical px (640x360 base) x3", fill=ink, font=f)
    dr.line((0, ground, W, ground), fill=(90, 95, 110), width=2)
    x = gap
    for (img, foot, title, sub, tall), w in zip(items, widths):
        cx = x + w // 2
        im.paste(img, (round(cx - img.width / 2), round(ground - foot[1])), img)
        dr.line((cx - 40, ground - tall, cx + 40, ground - tall), fill=(120, 125, 140), width=1)
        dr.text((x, H - 70), title, fill=ink, font=fs)
        dr.text((x, H - 44), sub, fill=dim, font=fs)
        x += w + gap
    out = out_dir(root) / "scale_chart.png"
    im.convert("RGB").save(out)
    print(out, im.size)


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[2] not in ("turnaround", "scale", "all"):
        raise SystemExit(__doc__)
    root, cmd = Path(sys.argv[1]), sys.argv[2]
    if cmd in ("turnaround", "all"):
        turnaround(root)
    if cmd in ("scale", "all"):
        scale_chart(root)
