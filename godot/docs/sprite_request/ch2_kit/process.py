#!/usr/bin/env python3
"""받은 2장 동작 그림을 모아 시트로 만든다(ch1_kit/README.md의 흐름을 한 번에).
1) collect: 로그에 그림 경로가 나온 요청을 results/<이름>/<요청>.png로 모으고, 검사용 모아 보기 contact_<이름>.png를 만든다
2) pack: 방향별 원본(assets/source/<이름>_<동작>_<방향>.webp)으로 자르고 묶어 gen_hero.py로 시트를 만든다
   (…b로 다시 받은 요청이 있으면 그것을 쓴다)
사용: python3 docs/sprite_request/ch2_kit/process.py collect|pack <이름>[:동작,…] …   (godot/ 안에서)
  <이름>:동작 = 그 동작만(1장 그리스 병사의 앉기처럼 나중에 더 받은 것). 그림은 2장 키트, 없으면 ch1_kit/units에서 찾는다
"""
import os
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
# 동작 → (격자 열, 줄, 프레임 수)
GRID = {"walk": (4, 3, 12), "run": (4, 3, 12), "attack1": (4, 1, 4), "attack2": (4, 1, 4), "attack3": (5, 1, 5),
        "heavy": (3, 2, 6), "hit": (2, 1, 2), "death": (5, 1, 5), "bow": (4, 1, 4), "block": (2, 1, 2), "interact": (4, 1, 4),
        "idle": (4, 1, 4), "dodge": (4, 1, 4), "sit": (4, 1, 4), "downed": (1, 1, 1)}
DOWNED = ["S", "SE", "E", "NE", "N"]


def kit(name):
    return HERE if (HERE / name).is_dir() else HERE.parent / "ch1_kit/units"


def done(name):
    """요청 이름 → 받은 그림 경로. 같은 요청을 a·b·c로 다시 받았으면 마지막 것."""
    k = kit(name)
    best = {}
    for log in sorted((k / name).glob("*.log")):
        m = re.findall(r"/Users[^ ]*generated_images[^ ]*\.png", log.read_text(errors="ignore"))
        if m:
            best[re.sub(r"[a-z]$", "", log.stem)] = (log.stem, m[-1])
    # 사람이 직접 받아 둔 그림(make_manual.py의 manual_results/<이름>__<요청>.png)이 있으면 그것
    for f in sorted((HERE / "manual_results").glob(f"{name}__*.png")):
        base = f.stem.split("__", 1)[1]
        best[base] = (base + "m", str(f))
    return best


def collect(name, only=None):
    out = HERE / "results" / name
    out.mkdir(parents=True, exist_ok=True)
    jobs = {b: j for b, j in done(name).items() if not only or b.split("_")[0] in only}
    thumbs = []
    for base, (job, src) in sorted(jobs.items()):
        im = Image.open(src).convert("RGB")
        im.save(out / f"{job}.png")
        t = im.resize((im.width * 300 // im.height, 300))
        ImageDraw.Draw(t).text((4, 4), job, fill=(255, 255, 255))
        thumbs.append(t)
    if thumbs:
        cols = 4
        w = max(t.width for t in thumbs)
        sheet = Image.new("RGB", (w * cols, 300 * ((len(thumbs) + cols - 1) // cols)), (40, 40, 40))
        for i, t in enumerate(thumbs):
            sheet.paste(t, (i % cols * w, i // cols * 300))
        sheet.save(HERE / "results" / f"contact_{name}.png")
    print(name, len(jobs), "받음")


def pack(name, only=None):
    src_dir = ROOT / "assets/source"
    env = {**os.environ, "SPRITE_CHAR": name}
    anims = set()
    for base, (job, png) in sorted(done(name).items()):
        anim = base.split("_")[0]
        if anim == "portrait" or (only and anim not in only):
            continue
        dirs = base.split("_", 1)[1]
        img = HERE / "results" / name / f"{job}.png"
        anims.add(anim)
        if anim in ("walk", "run", "heavy"):
            Image.open(img).convert("RGB").save(src_dir / f"{name}_{anim}_{dirs}.webp", lossless=True)
        elif anim == "downed":
            im = Image.open(img).convert("RGB")
            for i, d in enumerate(DOWNED):
                im.crop((i % 3 * 512, i // 3 * 512, i % 3 * 512 + 512, i // 3 * 512 + 512)).save(src_dir / f"{name}_downed_{d}.webp", lossless=True)
        else:
            subprocess.run([sys.executable, "tools/split_rows.py", str(img), anim, dirs.replace("-", ","), "."], cwd=ROOT, env=env, check=True)
    portrait = HERE / "results" / name / "portrait.png"
    if not portrait.exists():
        portrait = HERE / "results" / "portrait" / f"{name}.png"
    if portrait.exists():
        Image.open(portrait).convert("RGB").resize((1024, 1024), Image.LANCZOS).save(src_dir / f"{name}_portrait.webp", lossless=True)
    big = name in ("trojan_captain", "cicones_chief")
    for anim in sorted(anims):
        cols, rows, n = GRID[anim]
        h = (420 if big else 410) if anim == "heavy" else 305 if big else 320
        subprocess.run([sys.executable, "tools/pack_strip.py", ".", anim, str(cols), str(rows), str(n)], cwd=ROOT,
                       env={**env, "SPRITE_SRC_H": str(h)}, check=True, stdout=subprocess.DEVNULL)
    subprocess.run([sys.executable, "tools/gen_hero.py", ".", name], cwd=ROOT, check=True)


if __name__ == "__main__":
    step, names = sys.argv[1], sys.argv[2:]
    for n in names:
        name, _, only = n.partition(":")
        (collect if step == "collect" else pack)(name, only.split(",") if only else None)
