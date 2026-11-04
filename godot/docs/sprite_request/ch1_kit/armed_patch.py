#!/usr/bin/env python3
"""motion_request.py가 만든 요청 폴더의 prompt.txt를 '무기 든 1장 오디세우스'용으로 고친다.
맨손 문구를 칼·별 방패·등의 활을 든 문구로 바꾸고, 공격에는 베기 효과(궤적)를 넣어 역동적으로 그리게 한다.
사용: python3 armed_patch.py <요청 폴더> [unit]
  unit: 병사(적·동료)용 — 오디세우스 전용 문구(별 방패·등의 활)를 pose.png의 무기·방패로 바꾼다
"""
import re
import sys
from pathlib import Path

ARMED = ("- WEAPONS EXACTLY LIKE pose.png in EVERY frame: the bronze sword GRIPPED INSIDE the RIGHT fist (fingers around the hilt, "
         "the blade continues the forearm), the round bronze star shield STRAPPED on the LEFT forearm (moves with that arm, never in "
         "front of the face, never floating), the bow and quiver stay slung on his back. The red cape and the helmet crest follow the motion.")
SHEATHED = ("- In this action the sword is NOT in his hand (it hangs in a scabbard at his left hip); the star shield stays strapped on the "
            "LEFT forearm, the quiver stays on his back.")
BOW = ("- He holds the wooden recurve BOW in the LEFT fist (taken from his back), with a white-fletched arrow nocked on the string from "
       "frame 1 to 3; frame 4 the arrow has left. The sword hangs in a scabbard at his left hip, the star shield is slung on his back "
       "next to the quiver. Draw the bow and string crisply, never cut off.")
FX = ("- DYNAMIC ATTACK with a strong EFFECT: big wind-up, explosive strike, the cape and crest whip with the swing, deep lunge.\n"
      "  In the striking frames draw a bold pixel-art SLASH TRAIL following the sword tip path: a thick crescent arc with a white core, "
      "pale gold edge and a thin cyan outer rim, solid opaque pixels (no blur, no transparency, no glow haze), tapering at both ends, "
      "drawn BEHIND the sword blade, fully inside the cell. A few sharp spark pixels at the arc's leading end. Wind-up and recovery frames have "
      "no trail or only a fading thin tail. No dust, no text.")
HEAVY_FX = FX.replace("a thick crescent arc", "a wide almost full-circle WHIRLWIND arc around his body (spin slash)")

ACTION_HANDS = {"walk": ARMED, "run": ARMED, "idle": ARMED, "hit": ARMED, "block": ARMED.replace(
    "(moves with that arm, never in front of the face, never floating)", "(here RAISED in front of the chest toward the facing direction to block)"),
    "dodge": ARMED.replace("(moves with that arm, never in front of the face, never floating)", "(tucked against the body during the roll)"),
    "death": ARMED.replace("GRIPPED INSIDE the RIGHT fist (fingers around the hilt, the blade continues the forearm)",
                           "slipping from the RIGHT fist and lying beside him in the last frames"),
    "interact": SHEATHED, "throw": SHEATHED, "bow": BOW}


def patch(job: Path):
    p = job / "prompt.txt"
    t = p.read_text()
    anim = job.name.split("_")[0]
    t = t.replace("NO cape, NO helmet.", "")
    t = t.replace("(the bow itself is added by the game)", "with the real bow and arrow")
    t = t.replace("(leave room in front of the forearm, the game adds the shield)", "")
    t = t.replace("(the crank is NOT drawn)", "(the crank is NOT drawn, only his hands gripping the air)")
    if anim in ("attack1", "attack2", "attack3", "heavy"):
        t = t.replace("- Do NOT draw the stick lines, circles, numbers or ground line of the guide, and no slash trail, no effect lines, no dust.",
                      "- Do NOT draw the stick lines, circles, numbers or ground line of the guide.\n" + (HEAVY_FX if anim == "heavy" else FX))
        t = re.sub(r"- EMPTY HANDS: no sword, no shield, no bow\..*?strapped on\.\n?", ARMED + "\n", t, flags=re.S)
    else:
        t = t.replace("- No effect lines, no dust, no blood, no props.", "- No effect lines, no dust, no blood.")
        t = re.sub(r"- (EMPTY HANDS|NO sword).*?(\n(?!  )|$)", ACTION_HANDS.get(anim, ARMED) + "\n", t, count=1, flags=re.S)
    assert "EMPTY HANDS" not in t, job
    p.write_text(t)


def unitize(job: Path):
    p = job / "prompt.txt"
    t = p.read_text()
    t = t.replace("the bronze sword GRIPPED", "his weapon (exactly as in pose.png) GRIPPED").replace("the round bronze star shield", "his shield (exactly as in pose.png)")
    t = t.replace(", the bow and quiver stay slung on his back", "").replace(" The red cape and the helmet crest follow the motion.", "")
    t = t.replace("the sword tip path", "the weapon tip path").replace("drawn BEHIND the sword blade", "drawn BEHIND the weapon")
    p.write_text(t)


if __name__ == "__main__":
    for job in sorted(Path(sys.argv[1]).iterdir()):
        if (job / "prompt.txt").exists():
            patch(job)
            if len(sys.argv) > 2 and sys.argv[2] == "unit":
                unitize(job)
            print("고침", job.name)
