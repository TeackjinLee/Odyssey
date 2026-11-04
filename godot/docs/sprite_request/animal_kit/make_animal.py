#!/usr/bin/env python3
"""동물·음식 그림 요청 묶음(ART_PLAN C-ANI-*)을 만든다: 참고 그림 3장, 요청 글(prompts/*.txt), 복사용 index.html.
사람이 ChatGPT에 직접 넣는다 — index.html을 열어 요청마다 붙일 그림을 끌어다 놓고 요청 글을 복사한다.
받은 그림은 received/<저장 이름>으로 둔다.
사용: python3 docs/sprite_request/animal_kit/make_animal.py   (godot/ 안에서)
"""
import html
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
STYLE = HERE.parent / "ch2_kit" / "style_ref.png"
MAGENTA = (255, 0, 255)

# 종류: 이름, 게임 안 키(px, 오디세우스 52), 생김새
ANIMALS = {
    "chicken": ("닭", 16, "an ancient Mediterranean ROOSTER: plump round body, rust-red and golden-brown feathers, cream neck hackles, "
                "a tall bright red comb and wattles, yellow beak and legs, a dark glossy green-black sickle tail curving up"),
    "goat": ("염소", 28, "a Greek mountain GOAT: shaggy long coat in cream with patches of warm brown, a darker brown stripe down the back, "
             "long curved horns sweeping backward, a pointed chin beard, small upright ears, thin legs with dark hooves"),
    "sheep": ("양", 30, "an ancient Greek SHEEP: a round fluffy body of off-white wool in chunky curled clumps, "
              "a dark charcoal-brown face and legs, small floppy ears, small curled horns, a short woolly tail"),
    "boar": ("멧돼지", 30, "a WILD BOAR: heavy front-loaded body, coarse dark brown-black bristly hair, a stiff bristle ridge along the spine, "
             "a long snout with a pink-grey disc nose, curved WHITE TUSKS, small fierce eyes, short legs, a thin tufted tail"),
    "deer": ("사슴", 44, "a RED DEER STAG: slender reddish-brown body, a pale cream rump patch and belly, a darker neck mane, "
             "tall branching ANTLERS with several points, large ears, long thin legs with dark hooves, a short tail"),
}

FOODS = [  # 4×3 칸, 왼쪽 위부터
    ("meat", "a raw MEAT haunch on a white bone (red meat, a rim of cream fat)"),
    ("fish", "a whole silver-grey SEA BREAM fish lying on its side, gold stripe on the head"),
    ("bob", "a FISHING FLOAT: a small cork float, red top half and white bottom half, a thin line going up"),
    ("fig", "a small pile of three purple FIGS and a bunch of dark purple GRAPES"),
    ("bread", "a round flat BARLEY BREAD loaf, golden-brown crust with a cross cut on top"),
    ("olive", "a short OLIVE twig with silver-green leaves and six dark green and black OLIVES"),
    ("berry", "a wild BRAMBLE sprig with green leaves and red-and-dark-red RASPBERRIES"),
    ("nuts", "a small pile of pine nuts and brown ALMONDS in their shells"),
    ("honey", "a piece of golden HONEYCOMB dripping honey"),
    ("lotus", "a thorny LOTUS-tree twig (Ziziphus) with glossy reddish-brown date-like LOTUS FRUITS and a faint dreamy pale glow"),
    ("cheese", "a round white SHEEP'S-MILK CHEESE wheel with a wedge cut out, on a small woven reed mat"),
    ("bowl", "a clay BOWL of cooked barley porridge (a ration), terracotta with a black meander band"),
]

STYLE_RULES = """Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, NO labels, no text, no numbers.
- Crisp 2D pixel art matching style_ref.png: 1px dark outline, hard pixel clusters, stepped highlights, no anti-aliasing blur, the same warm Greek palette and rendering quality.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees), like style_ref.png."""

STYLE_NOTE = ("style_ref.png = ONLY the pixel style, outline, shading, palette and the isometric camera angle to copy. "
              "Its character (Odysseus) is NOT to be drawn.")


def font(n):
    for p in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial.ttf"):
        if Path(p).exists():
            return ImageFont.truetype(p, n)
    return ImageFont.load_default()


def make_size_ref():
    """오디세우스(남쪽 모습)와 동물 키를 같은 비율로 — 크기 감각만 주는 그림."""
    st = Image.open(STYLE).convert("RGB")
    hero = st.crop((0, 512, 384, 1024))             # 아래 줄 첫 칸 = 남쪽
    w, h = 1536, 1024
    im = Image.new("RGB", (w, h), (37, 44, 52))
    d = ImageDraw.Draw(im)
    base = 900
    hero_h = 340                                     # 52px → 340
    hc = hero.crop((40, 40, 344, 470))
    hc = hc.resize((int(hc.width * hero_h / hc.height), hero_h), Image.NEAREST)
    px = hc.load()
    mask = Image.new("L", hc.size, 255)
    mp = mask.load()
    for y in range(hc.height):
        for x in range(hc.width):
            r, g, b = px[x, y]
            if r > 200 and b > 200 and g < 80:
                mp[x, y] = 0
    im.paste(hc, (40, base - hero_h), mask)
    d.text((40, base + 20), "Odysseus 52px", fill=(230, 226, 214), font=font(30))
    x = 40 + hc.width + 40
    for kind, (_, px_h, _) in ANIMALS.items():
        bh = int(hero_h * px_h / 52)
        bw = int(bh * {"chicken": 0.9, "deer": 0.8}.get(kind, 1.0))
        d.rounded_rectangle((x, base - bh, x + bw, base), radius=12, fill=(120, 140, 120), outline=(230, 226, 214), width=3)
        d.text((x, base + 20), f"{kind} {px_h}px", fill=(230, 226, 214), font=font(24))
        x += max(bw, 150) + 30
    d.line((30, base, w - 30, base), fill=(150, 150, 150), width=2)
    d.text((40, 30), "SIZE GUIDE (only for relative size, do not copy the boxes)", fill=(224, 184, 96), font=font(34))
    im.save(HERE / "size_ref.png")


def make_layout(name, rows, cols=6):
    """칸 배치 안내(요청 그림 1536×1024, 칸 256×256)."""
    w, h = 1536, 1024
    cw, ch = w // cols, h // len(rows)
    im = Image.new("RGB", (w, h), MAGENTA)
    d = ImageDraw.Draw(im)
    for r, (label, arrow) in enumerate(rows):
        for c in range(cols):
            x0, y0 = c * cw, r * ch
            d.rectangle((x0 + 2, y0 + 2, x0 + cw - 3, y0 + ch - 3), outline=(255, 255, 255), width=3)
            d.text((x0 + 12, y0 + 10), f"{label} {c + 1}", fill=(255, 255, 255), font=font(24))
            cx, cy = x0 + cw // 2, y0 + ch // 2 + 20
            dx, dy = arrow
            d.line((cx - dx * 50, cy - dy * 50, cx + dx * 50, cy + dy * 50), fill=(40, 40, 40), width=8)
            d.ellipse((cx + dx * 50 - 12, cy + dy * 50 - 12, cx + dx * 50 + 12, cy + dy * 50 + 12), fill=(40, 40, 40))
            d.line((x0 + 30, y0 + ch - 30, x0 + cw - 30, y0 + ch - 30), fill=(255, 255, 255), width=2)
    im.save(HERE / name)


SE, NE = (0.8, 0.45), (0.8, -0.45)
MOVE_ROWS = [("walk SE", SE), ("walk NE", NE), ("run SE", SE), ("run NE", NE)]
IDLE_ROWS = [("idle SE", SE), ("idle NE", NE), ("death SE", SE), ("death NE", NE)]


def head(atts):
    lines = ["Create exactly ONE image from the prompt below. Attached images, in this order:"]
    lines += [f"{i}) {a}" for i, a in enumerate(atts, 1)]
    return "\n".join(lines) + "\n\n"


def base_prompt(kind):
    ko, px_h, look = ANIMALS[kind]
    return head([STYLE_NOTE, f"size_ref.png = ONLY how small the {kind} is next to Odysseus in the game (the {kind} box), so you know how simple to keep the details. Still draw it LARGE in every cell. Do not draw the boxes or Odysseus."]) + f"""Pixel art 8-direction ANIMAL SHEET for the same isometric Greek action RPG as style_ref.png (a huntable animal in Homer's Odyssey). Draw {look}.
Natural animal proportions (NOT chibi, NOT cartoon eyes), slightly chunky and readable, the same rendering quality, outline, shading and colour richness as style_ref.png. In the game it is about {px_h} pixels tall, so keep the silhouette simple and bold.

Layout (very important):
- ONE image 1536x1024, 4 columns x 2 rows, each cell 384x512, identical to style_ref.png: the animal the SAME SIZE and position in every cell, feet on the same baseline, the body filling about 70% of the cell width, nothing cut off.
- Top row left to right: NORTH (back, head away from viewer), NORTH-EAST (back-right), EAST (right side, head to the right), SOUTH-EAST (front-right).
- Bottom row left to right: SOUTH (front, head toward viewer), SOUTH-WEST (front-left), WEST (left side, head to the left), NORTH-WEST (back-left).
- Standing calmly on all legs in every cell.
- DEPTH: whatever is on the far side of the body is hidden behind it.

{STYLE_RULES}"""


def motion_prompt(kind, rows, what):
    ko, px_h, look = ANIMALS[kind]
    rows_txt = "\n".join(f"- Row {i}: {t}" for i, t in enumerate(what, 1))
    return head([f"{kind}_base.png = THE animal to draw (design, colours, size, pixel style) — copy it exactly; use its SOUTH-EAST cell for the SE rows and its NORTH-EAST cell for the NE rows.",
                 f"{rows} = ONLY the grid layout and facing arrow of each row (do NOT draw the white lines, the labels or the arrows)."]) + f"""Pixel art ANIMATION SHEET of the same animal as {kind}_base.png ({look}) for an isometric Greek action RPG.

Layout (very important):
- ONE image 1536x1024, 6 columns x 4 rows, each cell 256x256, the animal the SAME SIZE in every cell (as big as possible while nothing is cut off), feet on the same baseline in every cell of a row.
- Each row is one animation, 6 frames from left to right, looping smoothly where it loops.
- SE = facing south-east (head toward the lower-right, front-right of the body visible). NE = facing north-east (head toward the upper-right, back-right of the body visible).
{rows_txt}

{STYLE_RULES}"""


def gait(kind):
    if kind == "chicken":
        return ("walking: strutting, head bobbing forward and back, legs stepping",
                "running away in panic: body leaning forward, wings half spread and flapping, legs a blur of long strides")
    return ("walking slowly: a calm four-legged walk cycle, legs moving in the natural diagonal order",
            "running away in panic: a fast gallop, legs stretched far forward and back, body leaning forward" +
            (", ears back" if kind != "boar" else ", bristles raised"))


def idle(kind):
    return {"chicken": "idle: pecking the ground twice, then lifting the head and looking around",
            "goat": "idle: lowering the head to graze, chewing, lifting the head again",
            "sheep": "idle: grazing with the head down, chewing, a small ear twitch",
            "boar": "idle: rooting the ground with its snout, then lifting the head and sniffing",
            "deer": "idle: lifting the head alert, ears turning, then lowering the head to graze"}[kind]


DEATH = ("death: hit and flinching (frame 1), legs buckling (2-3), falling over onto its side (4-5), "
         "lying still on its side on the ground (6, a little red blood spot under it)")


def food_prompt():
    items = "\n".join(f"- Cell {i}: {d}" for i, (_, d) in enumerate(FOODS, 1))
    return head([STYLE_NOTE]) + f"""Pixel art FOOD ICON SHEET for the same isometric Greek action RPG as style_ref.png: small food objects lying on the ground that the hero picks up and eats (Homer's Odyssey, ancient Greece).

Layout (very important):
- ONE image 1536x1024, 4 columns x 3 rows, each cell 384x341, ONE object centered in each cell, every object filling about 60% of its cell, nothing cut off.
- Cells left to right, top row first:
{items}
- Seen from the same isometric 3/4 top-down angle (camera looks down about 30 degrees), resting on the ground.

{STYLE_RULES}"""


def jobs():
    out = []
    for kind, (ko, _, _) in ANIMALS.items():
        w, r = gait(kind)
        out.append((f"{kind}_base", f"{ko} — 기본 8방향", ["style_ref.png", "size_ref.png"], base_prompt(kind)))
        out.append((f"{kind}_move", f"{ko} — 걷기·달아나기", [f"received/{kind}_base.png", "layout_move.png"],
                    motion_prompt(kind, "layout_move.png", [f"{w}, facing SE", f"{w}, facing NE", f"{r}, facing SE", f"{r}, facing NE"])))
        out.append((f"{kind}_idle", f"{ko} — 쉬기·쓰러짐", [f"received/{kind}_base.png", "layout_idle.png"],
                    motion_prompt(kind, "layout_idle.png", [f"{idle(kind)}, facing SE", f"{idle(kind)}, facing NE",
                                                            f"{DEATH}, facing SE", f"{DEATH}, facing NE"])))
    out.append(("food_icons", "음식 12가지", ["style_ref.png"], food_prompt()))
    return out


def main():
    (HERE / "prompts").mkdir(exist_ok=True)
    (HERE / "received").mkdir(exist_ok=True)
    shutil.copy(STYLE, HERE / "style_ref.png")
    make_size_ref()
    make_layout("layout_move.png", MOVE_ROWS)
    make_layout("layout_idle.png", IDLE_ROWS)
    secs = []
    for i, (name, title, atts, text) in enumerate(jobs(), 1):
        (HERE / "prompts" / f"{name}.txt").write_text(text)
        figs = "".join(f'<figure><img src="{a}" draggable="true" onerror="this.replaceWith(\'(아직 없음 — 앞 요청 결과)\')">'
                       f'<figcaption>{n}) {Path(a).name}</figcaption></figure>' for n, a in enumerate(atts, 1))
        secs.append(f'''<section><h2>{i:02d}. {html.escape(title)}</h2>
<div class="att">{figs}</div>
<p>저장 이름: <code>received/{name}.png</code></p>
<textarea readonly>{html.escape(text)}</textarea><button>요청 글 복사</button>
<label><input type="checkbox"> 받음</label></section>''')
    page = f'''<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>동물·음식 그림 요청</title>
<style>
:root {{ --bg:#16191d; --fg:#e8e2d6; --card:#22262c; --line:#3a3f47; --acc:#e0b860; }}
body {{ background:var(--bg); color:var(--fg); font:14px/1.5 -apple-system,sans-serif; margin:0 auto; max-width:980px; padding:16px; }}
section {{ background:var(--card); border:1px solid var(--line); border-radius:8px; padding:12px 16px; margin:12px 0; }}
section:has(input:checked) {{ opacity:.45; }}
h2 {{ font-size:16px; margin:0 0 8px; color:var(--acc); }}
.att {{ display:flex; gap:12px; flex-wrap:wrap; }}
figure {{ margin:0; }} img {{ max-height:180px; max-width:100%; border:1px solid var(--line); }}
figcaption {{ font-size:12px; }}
textarea {{ width:100%; height:160px; background:#111; color:var(--fg); border:1px solid var(--line); font:12px monospace; }}
button {{ background:var(--acc); border:0; border-radius:4px; padding:4px 10px; cursor:pointer; margin:4px 8px 4px 0; }}
code {{ color:var(--acc); }}
</style></head><body>
<h1>동물·음식 그림 요청 ({len(secs)}개)</h1>
<p>동물마다 <b>기본 8방향을 먼저</b> 받고, 받은 그림을 <code>received/&lt;종류&gt;_base.png</code>로 저장한 뒤 이 쪽을 새로고침하면 다음 요청의 첨부 그림이 보인다.</p>
{"".join(secs)}
<script>
document.querySelectorAll("section button").forEach(b => b.onclick = () => {{
  navigator.clipboard.writeText(b.previousElementSibling.value); b.textContent = "복사됨"; setTimeout(() => b.textContent = "요청 글 복사", 1200);
}});
</script></body></html>'''
    (HERE / "index.html").write_text(page)
    print(f"{len(secs)}개 요청 → {HERE / 'index.html'}")


if __name__ == "__main__":
    main()
