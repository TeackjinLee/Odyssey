#!/usr/bin/env python3
"""적·동료 병사 동작 요청 폴더를 한 번에 만든다(트로이 검병과 같은 흐름).
기본 8방향 요청 글(<이름>.txt)의 인물 설명으로 <이름>_motion.txt를 만들고, motion_request.py로 폴더를 만든 뒤
armed_patch.py로 무기 든 병사 문구로 바꾼다. 창병은 찌르기, 궁수는 활, 대장 강공격은 방향마다 한 장(3×2칸)으로 받는다.
사용: python3 make_motion.py [--anims=run,block,portrait] <이름> [<이름> ...]   (godot/ 안에서)
  --anims: 처음 받은 동작 대신 그 동작만 더 만든다(portrait = HUD 초상화 요청 units/portrait/<이름>)
"""
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE.parent))
import armed_patch  # noqa: E402

ANIMS = {"sword": "walk,attack1,attack2,hit,death", "spear": "walk,attack1,attack2,hit,death",
         "archer": "walk,bow,hit,death", "captain": "walk,attack1,attack2,attack3,hit,death"}
THRUST = ("- His weapon is a LONG SPEAR: every strike is a straight THRUST of the spear tip toward the facing direction "
          "(both hands may guide the shaft), the spear stays fully inside the cell. The trail is a straight streak along the thrust, not a crescent.")
ARCHER = ("- WEAPONS EXACTLY LIKE pose.png in EVERY frame: his bow (exactly as in pose.png) held in the LEFT fist, the quiver on his back. "
          "NO shield, NO sword.")
ARCHER_BOW = ("- He holds his bow (exactly as in pose.png) in the LEFT fist with an arrow nocked on the string from frame 1 to 3; "
              "frame 4 the arrow has left. The quiver stays on his back. NO shield, NO sword. Draw the bow and string crisply, never cut off.")
HEAVY_LAYOUT = ("- ONE image 1536x1024, 3 columns x 2 rows, every cell 512x512: frames 1-3 in the top row, frames 4-6 in the bottom row "
                "(guide.png shows the same 6 frames in one row, left to right), no gaps. \n"
                "- All 6 cells show the SAME facing, frames in reading order (left to right, then the second row).")
HEAVY_KEEP = "- The whirlwind trail and the weapon must stay FULLY INSIDE each 512x512 cell, never crossing into the neighbouring cell or touching the cell edge."
BIG = "about 290px tall"


def motion_text(name):
    t = (HERE / f"{name}.txt").read_text()
    s = re.search(r"Draw an? (.*?)\n", t).group(1)
    s = s.replace("like the reference but", "exactly like pose.png,").replace("like the reference", "exactly like pose.png")
    return "A " + s


def tweak(job: Path, kind: str):
    p = job / "prompt.txt"
    t = p.read_text()
    anim = job.name.split("_")[0]
    if kind == "archer":
        t = t.replace(armed_patch.BOW, ARCHER_BOW)
        t = t.replace(armed_patch.ACTION_HANDS["death"], ARCHER.replace("held in the LEFT fist", "slipping from the LEFT fist and lying beside him in the last frames"))
        t = t.replace(armed_patch.ARMED, ARCHER)
    t = t.replace("the bronze sword slipping", "his weapon slipping")
    if kind == "spear" and anim.startswith("attack"):
        t = t.replace("- Do NOT draw the stick lines", THRUST + "\n- Do NOT draw the stick lines")
    if kind == "captain":
        t = t.replace(BIG, "as tall as in pose.png (a big captain)")
        if anim == "heavy":
            t = re.sub(r"- ONE image 1536x1024, 6 columns x 2 rows.*?\n(- .*?\n)?", HEAVY_LAYOUT + "\n", t, count=1)
            t = t.rstrip("\n") + "\n" + HEAVY_KEEP + "\n"
    p.write_text(t)


PORTRAIT = """Use your built-in image generation tool to create exactly ONE image from the prompt below. Attached image:
1) pose.png = the character to portray, seen from the front (copy his face, headgear and armor colors EXACTLY).
Do not write code or edit any files. When the image is generated, reply with its saved file path only.

A square 1024x1024 pixel-art CHARACTER PORTRAIT for a game HUD: head and shoulders of the character in pose.png:
__CHARACTER__
Three-quarter view facing slightly to the right, __MOOD__ expression, the headgear exactly as in pose.png (face fully visible; a tall crest may be cut by the top edge), armor and shoulders visible at the bottom.
The face fills most of the image (it will be shrunk to 22x22 pixels, so the face must be BIG and readable).
Background: flat dark charcoal blue #252C34. Crisp pixel art, chunky readable pixel clusters, 1px dark outline, no text, no frame, no border.
"""


def portrait(name):
    """HUD 초상화 요청 폴더(units/portrait/<이름>): 기본 시트의 남쪽 칸을 pose.png로."""
    from PIL import Image
    job = HERE / "portrait" / name
    job.mkdir(parents=True, exist_ok=True)
    Image.open(ROOT / f"assets/source/{name}_8dir.webp").convert("RGB").crop((0, 512, 384, 1024)).save(job / "pose.png")
    mood = "loyal determined" if name.startswith("greek") else "stern hostile"
    (job / "prompt.txt").write_text(PORTRAIT.replace("__CHARACTER__", motion_text(name)).replace("__MOOD__", mood))


def main(names, only=None):
    import importlib.util
    spec = importlib.util.spec_from_file_location("mr", ROOT / "tools/motion_request.py")
    mr = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mr)
    mr.GROUPS["heavy"] = [["E"], ["SE"], ["S"], ["NE"], ["N"]]
    for name in names:
        kind = name.split("_")[1]
        if not (HERE / f"{name}_motion.txt").exists():
            (HERE / f"{name}_motion.txt").write_text(motion_text(name) + "\n")
        out = HERE / name
        anims = ANIMS[kind].split(",") + (["heavy"] if kind == "captain" else [])
        if only:   # 나중에 더 받는 동작(달리기·막기·초상화). 막기는 방패 든 병사만
            anims = [a for a in only if a != "block" or kind != "archer"]
            if "portrait" in anims:
                portrait(name)
                anims.remove("portrait")
            if not anims:
                continue
        mr.main(ROOT / f"assets/source/{name}_8dir.webp", HERE / f"{name}_motion.txt", out, anims, 1)
        for job in sorted(out.iterdir()):
            if (job / "prompt.txt").exists() and (not only or job.name.split("_")[0] in anims):
                armed_patch.patch(job)
                if kind == "archer":
                    tweak(job, kind)
                armed_patch.unitize(job)
                tweak(job, kind)
                assert "star shield" not in (job / "prompt.txt").read_text() or kind == "archer", job


if __name__ == "__main__":
    a = sys.argv[1:]
    only = a.pop(0)[len("--anims="):].split(",") if a and a[0].startswith("--anims=") else None
    main(a, only)
