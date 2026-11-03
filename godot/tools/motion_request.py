#!/usr/bin/env python3
"""다른 캐릭터의 걷기·달리기 12프레임과 공격 4종을 Codex에 요청할 폴더를 만든다(docs/sprite_request/motion_kit/README.md).

걷기·달리기는 방향(S SE E NE N)마다 <출력>/<동작>_<방향><a|b>/, 공격은 한 장에 여러 방향(줄)을 받는 <동작>_<방향-방향…><a|b>/ 에 pose.png·guide.png·prompt.txt를 두고, 한 번에 돌리는 run.sh도 쓴다.
 - pose.png: 기본 8방향 시트(칸 384×512, 윗줄 N NE E SE / 아랫줄 S SW W NW)에서 그 방향 칸을 잘라 낸 그림
 - guide.png: motion_kit/guides/<동작>12_<방향>.png (걷기·달리기, tools/walk_guide.py) 또는 <공격>_<방향>.png (tools/attack_guide.py)
 - prompt.txt: motion_kit/<동작>12_prompt.txt(공격은 attack_prompt.txt)의 빈칸을 채운 것
사용: python3 tools/motion_request.py <기본 8방향 시트> <인물 설명.txt> <출력 폴더> [walk|run|attack1|attack2|attack3|heavy|both|all, 쉼표로 여럿도 가능] [후보 수=2]
  both = walk+run, all = walk+run+공격 4종
받은 그림은 assets/source/<캐릭터>_<동작>_<방향>.webp로 두고 tools/pack_strip.py로 묶는다.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

MODEL = "gpt-6.1-sol"   # Codex 모델(설정 파일 기본값 대신 고정)
KIT = Path(__file__).resolve().parent.parent / "docs/sprite_request/motion_kit"
CELL = {"N": (0, 0), "NE": (0, 1), "E": (0, 2), "SE": (0, 3), "S": (1, 0)}   # (줄, 열)
VERB = {"walk": "walking", "run": "running"}
SHORT = {"S": "SOUTH (front), facing the viewer", "SE": "SOUTH-EAST (front-right), three-quarter front view toward the lower-right",
         "E": "EAST, right side profile toward the right", "NE": "NORTH-EAST (back-right), we see his back and right side, toward the upper-right",
         "N": "NORTH (back), we see only his back, away from the viewer"}
# 공격: 프레임 수, 격자(열×줄), 이름, 프레임별 동작 글, 서 있는 키
ATTACKS = {
    "attack1": (4, (2, 2), "fast HORIZONTAL SLASH, sword swung with the right hand", """- Frame 1 wind-up: right fist pulled back beside his right hip/shoulder, torso twisted right, weight on the back foot.
- Frame 2 swing: short step forward with the left foot, right arm sweeping forward at chest height, torso turning.
- Frame 3 follow-through: right arm fully extended across his body to his LEFT side, torso twisted left.
- Frame 4 recovery: back toward a ready stance, right fist in front of the body."""),
    "attack2": (4, (2, 2), "BACKHAND SLASH, the return swing after a first slash, right hand", """- Frame 1 wind-up: right fist low on his LEFT side near the left hip, torso twisted left.
- Frame 2 swing: right arm sweeping forward and upward, torso turning back to the right.
- Frame 3 follow-through: right arm extended high out to his RIGHT side at shoulder height, torso twisted right.
- Frame 4 recovery: back toward a ready stance, right fist in front of the body."""),
    "attack3": (5, (3, 2), "powerful OVERHEAD CHOP, combo finisher, right hand", """- Frame 1 rise: right fist lifting up past the shoulder, body straightening, slight lean back.
- Frame 2 peak: right fist raised high ABOVE his head, chest open, back arched, weight on the back foot.
- Frame 3 chop: big lunge forward with the left foot, right arm slamming down in front of him, torso bending forward.
- Frame 4 impact: deep crouch, right fist low in front near knee height.
- Frame 5 recovery: rising back toward a ready stance, right fist in front of the body."""),
    "heavy": (6, (3, 2), "charged SPIN SLASH, one full 360-degree turn, right hand", """- Frame 1 charge: deep crouch, right fist pulled far back behind his right hip, torso twisted right, left arm forward.
- Frame 2 coil: even lower and tighter, weight on the back foot.
- Frame 3 spin start: exploding out of the crouch, right arm extended straight out to the side at waist height, torso turning.
- Frame 4 mid-spin: his back turned toward the camera side of that facing, right arm still extended straight out.
- Frame 5 spin end: facing the original direction again, right arm sweeping across in front at full extension.
- Frame 6 finish: low wide stance, right fist out to his LEFT side."""),
}
READ = {(2, 2): "top row 1-2, bottom row 3-4", (3, 2): "top row 1-3, bottom row (4, 5, 6)"}
FACING = {
    "S": "SOUTH (front) - facing the viewer, {v} straight toward the viewer",
    "SE": "SOUTH-EAST (front-right) - three-quarter front view {v} toward the lower-right",
    "E": "EAST (right side) - side profile {v} to the right",
    "NE": "NORTH-EAST (back-right) - we see his back and right side, {v} toward the upper-right",
    "N": "NORTH (back) - we see only his back, {v} straight away from the viewer",
}
# 방향마다 덧붙이는 말(받아 보니 이 말이 없으면 몸 돌림·키가 장마다 달라졌다)
EXTRA = {
    "S": ("- FRONT VIEW: the lifted leg bends its knee toward the viewer and shows the top of the sandal; the forward foot is slightly lower on screen.\n"
          "  Both fists stay visible beside the body and move up and down as the arms swing. Face looks straight at the viewer in every frame."),
    "SE": "- Keep the SAME three-quarter body turn in all 12 frames: chest and face always turned the same amount toward the lower-right, never turning more to the front.",
    "E": "",
    "NE": ("- Keep the SAME three-quarter back turn in all 12 frames: back and right shoulder always turned the same amount toward the upper-right, "
           "only the side of the beard visible, never turning to a full back or side view."),
    "N": ("- BACK VIEW: the lifted foot shows its sandal sole and the calf bends; the forward foot is slightly higher on screen.\n"
          "  Both fists stay visible beside the body and move up and down as the arms swing. Never show the face.\n"
          "- BIG CLEAR STEPS: the feet are far apart (one clearly higher on screen = forward), the lifted knee bends strongly and the sole is clearly visible. "
          "The body must not look like it glides."),
}


# 공격은 한도를 아끼려고 한 장에 여러 방향(줄)을 받는다: 열 = 프레임, 줄 = 방향. 칸 크기는 걷기와 비슷하게 맞춘다
GROUPS = {"attack1": [["E", "SE", "S"], ["NE", "N"]], "attack2": [["E", "SE", "S"], ["NE", "N"]],
          "attack3": [["E", "SE", "S"], ["NE", "N"]], "heavy": [["E", "SE"], ["S", "NE"], ["N"]]}
ROWS_PER_IMAGE = {"attack1": 3, "attack2": 3, "attack3": 3, "heavy": 2}


def attack_text(tpl, anim, group, character):
    n, _, title, motion = ATTACKS[anim]
    rows = ROWS_PER_IMAGE[anim]
    extras = [f"- {d} row: " + EXTRA[d].replace("all 12 frames", "all frames").lstrip("- ").replace("\n  ", " ").split("\n")[0]
              for d in group if EXTRA[d]]
    grid = f"{n} columns x {rows} rows, every cell {1536 // n}x{1024 // rows}"
    empty = f"The last {rows - len(group)} row(s) stay EMPTY magenta." if len(group) < rows else ""
    return (tpl.replace("__CHARACTER__", character).replace("__NDIR__", str(len(group)))
            .replace("__POSELIST__", ", ".join(SHORT[d].split(",")[0] for d in group))
            .replace("__N__", str(n)).replace("__TITLE__", title).replace("__MOTION__", motion)
            .replace("__ROWLIST__", "\n".join(f"  Row {i + 1}: {SHORT[d]}" for i, d in enumerate(group)))
            .replace("__EXTRA__\n", "\n".join(extras) + "\n" if extras else "")
            .replace("__GRID__", grid).replace("__EMPTY__", empty))


def main(base, character, out, anims, n):
    base = Image.open(base).convert("RGB")
    character = Path(character).read_text().strip()
    out = Path(out)
    lines = ["#!/bin/zsh", "# 모든 요청을 동시에 돌린다. 끝나면 각 폴더의 로그에서 생성된 그림 경로를 찾는다.",
             'cd "$(dirname "$0")"']
    for anim in anims:
        atk = anim in ATTACKS
        tpl = (KIT / ("attack_prompt.txt" if atk else f"{anim}12_prompt.txt")).read_text()
        if atk:
            for group in GROUPS[anim]:
                for v in "abcdefgh"[:n]:
                    job = out / f"{anim}_{'-'.join(group)}{v}"
                    job.mkdir(parents=True, exist_ok=True)
                    poses = [base.crop((CELL[d][1] * 384, CELL[d][0] * 512, (CELL[d][1] + 1) * 384, (CELL[d][0] + 1) * 512)) for d in group]
                    sheet = Image.new("RGB", (384 * len(group), 512))
                    for i, im in enumerate(poses):
                        sheet.paste(im, (i * 384, 0))
                    sheet.save(job / "pose.png")
                    subprocess.run([sys.executable, str(Path(__file__).parent / "attack_guide.py"), str(job / "guide.png"), anim, ",".join(group)], check=True)
                    (job / "prompt.txt").write_text(attack_text(tpl, anim, group, character))
                    lines.append(f"(cd {job.name} && codex exec -m {MODEL} --skip-git-repo-check -s read-only -i pose.png -i guide.png - "
                                 f"< prompt.txt > ../{job.name}.log 2>&1) &")
            continue
        for d, (r, c) in CELL.items():
            for v in "abcdefgh"[:n]:
                job = out / f"{anim}_{d}{v}"
                job.mkdir(parents=True, exist_ok=True)
                base.crop((c * 384, r * 512, (c + 1) * 384, (r + 1) * 512)).save(job / "pose.png")
                (job / "guide.png").write_bytes((KIT / f"guides/{anim}12_{d}.png").read_bytes())
                facing = FACING[d].format(v=VERB[anim])
                extra = EXTRA[d]
                if anim == "run" and d == "N":
                    extra = extra.split("\n- BIG CLEAR")[0]
                (job / "prompt.txt").write_text(tpl.replace("__CHARACTER__", character).replace("__FACING__", facing)
                                                .replace("__EXTRA__\n", extra + "\n" if extra else ""))
                lines.append(f"(cd {job.name} && codex exec -m {MODEL} --skip-git-repo-check -s read-only -i pose.png -i guide.png - "
                             f"< prompt.txt > ../{job.name}.log 2>&1) &")
    lines += ["wait", 'for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\\.png" $f | tail -1)"; done']
    (out / "run.sh").write_text("\n".join(lines) + "\n")
    (out / "run.sh").chmod(0o755)
    jobs = sum(len(GROUPS[a]) if a in ATTACKS else len(CELL) for a in anims) * n
    print(f"{out}: {jobs}개 요청 폴더, 실행은 {out}/run.sh")


if __name__ == "__main__":
    a = sys.argv[1:]
    which = a[3] if len(a) > 3 else "both"
    sets = {"both": ["walk", "run"], "all": ["walk", "run", *ATTACKS]}
    main(a[0], a[1], a[2], sets.get(which, which.split(",")), int(a[4]) if len(a) > 4 else 2)
