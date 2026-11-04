#!/usr/bin/env python3
"""항해복 오디세우스(odysseus_sea)의 모든 동작 요청 폴더를 만든다(1장 오디세우스 ch1_kit과 같은 흐름).
기본 시트 assets/source/odysseus_sea_8dir.webp(칼·별 방패·등의 활을 든 새 그림)를 pose로 쓰고, motion_request.py로 폴더를 만든 뒤
armed_patch.py로 무기 든 문구로 바꾸고 투구·붉은 망토 문구를 항해복(머리띠·청록 짧은 망토) 문구로 바꾼다.
강공격은 방향마다 한 장(3×2칸), 쓰러져 있기는 5방향 한 장, 초상화는 남쪽 칸으로.
사용: python3 docs/sprite_request/ch2_kit/make_sea.py [동작,…]   (godot/ 안에서, 없으면 전부)
"""
import importlib.util
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent / "ch1_kit"))
sys.path.insert(0, str(HERE.parent / "ch1_kit/units"))
import armed_patch  # noqa: E402
import make_motion  # noqa: E402

BASE = ROOT / "assets/source/odysseus_sea_8dir.webp"
OUT = HERE / "odysseus_sea"
ANIMS = "walk,run,attack1,attack2,attack3,heavy,idle,hit,block,dodge,bow,death,interact"
SEA = {
    "The red cape and the helmet crest follow the motion.": "The short blue-green cloak and his curly hair follow the motion.",
    "the cape and crest whip with the swing": "the short cloak and his hair whip with the swing",
    "the red cape": "the short blue-green cloak", "red cape": "short blue-green cloak", "the cape": "the cloak",
    "helmet still on": "the bronze brow band still on", "helmet": "brow band",
}
DOWNED = (HERE.parent / "ch1_kit/extra/downed_all/prompt.txt")
PORTRAIT = """Use your built-in image generation tool to create exactly ONE image from the prompt below. Attached image:
1) pose.png = the hero Odysseus in his sea-voyage clothes, seen from the front (copy his face, hair, brow band and clothes colors EXACTLY).
Do not write code or edit any files. When the image is generated, reply with its saved file path only.

A square 1024x1024 pixel-art CHARACTER PORTRAIT for a game HUD: head and shoulders of the hero in pose.png, three-quarter view facing slightly to the right, determined cunning expression, dark eyebrows, brown eyes, short dark beard, wind-blown curly dark-brown hair with a thin bronze brow band (whole head visible, NO helmet), the short weathered blue-green cloak and the bronze breastplate visible at the bottom.
The face fills most of the image (it will be shrunk to 40x40 pixels, so the face must be BIG and readable).
Background: flat dark charcoal blue #252C34. Crisp pixel art, chunky readable pixel clusters, 1px dark outline, no text, no frame, no border.
"""


def character():
    t = (HERE / "odysseus_sea.txt").read_text()
    s = t.split("Odysseus as a cute stocky CHIBI hero", 1)[1].split("\n\nLayout", 1)[0]
    return ("Odysseus as a cute stocky CHIBI hero" + s).replace("exactly like sea_costume.png", "exactly like pose.png") \
        .replace("exactly like style_ref.png", "exactly like pose.png")


def sea(text):
    for a, b in SEA.items():
        text = text.replace(a, b)
    return text


def cells():
    src = Image.open(BASE).convert("RGB")
    at = {"N": (0, 0), "NE": (0, 1), "E": (0, 2), "SE": (0, 3), "S": (1, 0)}
    return {d: src.crop((c * 384, r * 512, c * 384 + 384, r * 512 + 512)) for d, (r, c) in at.items()}


def downed():
    job = OUT / "downed_all"
    job.mkdir(parents=True, exist_ok=True)
    c = cells()
    strip = Image.new("RGB", (384 * 5, 512))
    for i, d in enumerate(["S", "SE", "E", "NE", "N"]):
        strip.paste(c[d], (i * 384, 0))
    strip.save(job / "pose.png")
    t = DOWNED.read_text()
    old = t.split("Odysseus as a cute stocky CHIBI hero", 1)[1].split("\nKeep his face", 1)[0]
    t = t.replace("Odysseus as a cute stocky CHIBI hero" + old, character().rstrip("\n"))
    (job / "prompt.txt").write_text(sea(t))


def portrait():
    job = OUT / "portrait"
    job.mkdir(parents=True, exist_ok=True)
    cells()["S"].save(job / "pose.png")
    (job / "prompt.txt").write_text(PORTRAIT)


def main(anims):
    (HERE / "odysseus_sea_motion.txt").write_text(character())
    spec = importlib.util.spec_from_file_location("mr", ROOT / "tools/motion_request.py")
    mr = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mr)
    mr.GROUPS["heavy"] = [["E"], ["SE"], ["S"], ["NE"], ["N"]]
    rowed = [a for a in anims if a not in ("downed", "portrait")]
    if rowed:
        mr.main(BASE, HERE / "odysseus_sea_motion.txt", OUT, rowed, 1)
    for job in sorted(OUT.iterdir()):
        anim = job.name.split("_")[0]
        if not (job / "prompt.txt").exists() or anim not in rowed:
            continue
        armed_patch.patch(job)
        p = job / "prompt.txt"
        t = sea(p.read_text())
        if anim == "heavy":   # 회오리가 잘리지 않게 방향마다 3×2칸(칸 512)
            t = make_motion.re.sub(r"- ONE image 1536x1024, 6 columns x 2 rows.*?\n(- .*?\n)?", make_motion.HEAVY_LAYOUT + "\n", t, count=1)
            t = t.rstrip("\n") + "\n" + make_motion.HEAVY_KEEP + "\n"
        p.write_text(t)
    if "downed" in anims:
        downed()
    if "portrait" in anims:
        portrait()


if __name__ == "__main__":
    main(sys.argv[1].split(",") if len(sys.argv) > 1 else ANIMS.split(",") + ["downed", "portrait"])
