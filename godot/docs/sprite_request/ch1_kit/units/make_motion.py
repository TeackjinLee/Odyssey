#!/usr/bin/env python3
"""적·동료 병사 동작 요청 폴더를 한 번에 만든다(트로이 검병과 같은 흐름).
기본 8방향 요청 글(<이름>.txt)의 인물 설명으로 <이름>_motion.txt를 만들고, motion_request.py로 폴더를 만든 뒤
armed_patch.py로 무기 든 병사 문구로 바꾼다. 창병은 찌르기, 궁수는 활, 대장 강공격은 방향마다 한 장(3×2칸)으로 받는다.
사용: python3 make_motion.py <이름> [<이름> ...]   (godot/ 안에서)
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


def main(names):
    import importlib.util
    spec = importlib.util.spec_from_file_location("mr", ROOT / "tools/motion_request.py")
    mr = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mr)
    mr.GROUPS["heavy"] = [["E"], ["SE"], ["S"], ["NE"], ["N"]]
    for name in names:
        kind = name.split("_")[1]
        (HERE / f"{name}_motion.txt").write_text(motion_text(name) + "\n")
        out = HERE / name
        anims = ANIMS[kind].split(",") + (["heavy"] if kind == "captain" else [])
        mr.main(ROOT / f"assets/source/{name}_8dir.webp", HERE / f"{name}_motion.txt", out, anims, 1)
        for job in sorted(out.iterdir()):
            if (job / "prompt.txt").exists():
                armed_patch.patch(job)
                if kind == "archer":
                    tweak(job, kind)
                armed_patch.unitize(job)
                tweak(job, kind)
                assert "star shield" not in (job / "prompt.txt").read_text() or kind == "archer", job


if __name__ == "__main__":
    main(sys.argv[1:])
