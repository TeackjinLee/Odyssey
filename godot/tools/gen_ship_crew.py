#!/usr/bin/env python3
"""배 위 사람 작은 시트: 노 젓는 부하(그리스 병사 앉기)·뱃머리의 오디세우스(서기)·키코네스 배의 노꾼·궁수(서기)를 배 크기에 맞게 미리 줄여 둔다.
게임 화면에서 큰 시트를 0.2배쯤으로 nearest로 줄이면 깨져서, 여기서 LANCZOS로 줄여 ship_crew.png/.json을 만든다.
줄 = (시트, 동작), 열 = 방향 0~7 × 프레임. ship.gd가 0.5배로 그린다(canvas_items 2배 화면에서 또렷하게).
사용: python3 tools/gen_ship_crew.py <godot 프로젝트 폴더>"""
import json
import sys
from pathlib import Path

from PIL import Image

K = 0.36
ROWS = [("greek_sword", "sit"), ("greek_spear", "sit"), ("greek_archer", "sit"),
        ("odysseus_ch1", "idle"), ("odysseus_sea", "idle"),
        ("cicones_sword", "idle"), ("cicones_spear", "idle"), ("cicones_archer", "idle")]   # 키코네스 배: 노꾼(위만 그려 앉은 듯)·궁수


def build(root):
    fs = round(192 * K)
    out, meta, rows = [], {"frame": fs, "anchor": [96 * K, 180 * K], "rows": {}}, []
    for sheet, anim in ROWS:
        p = root / f"assets/sprites/{sheet}.png"
        if not p.exists():
            continue
        m = json.loads((root / f"assets/sprites/{sheet}.json").read_text())
        if anim not in m["anims"]:
            continue
        a = m["anims"][anim]
        sh = Image.open(p).convert("RGBA")
        k = m.get("scale", 0.5) / 0.5      # 시트 배율이 0.5가 아닌 인물도 같은 키로
        line = Image.new("RGBA", (fs * 8 * a["frames"], fs), (0, 0, 0, 0))
        for d in range(8):
            for i in range(a["frames"]):
                c = sh.crop(((a["start"] + i) * 192, d * 192, (a["start"] + i) * 192 + 192, d * 192 + 192))
                c = c.resize((round(192 * K * k),) * 2, Image.LANCZOS)
                line.paste(c, ((d * a["frames"] + i) * fs + (fs - c.width) // 2, fs - c.height))
        meta["rows"][sheet] = {"row": len(rows), "frames": a["frames"], "fps": a["fps"]}
        rows.append(line)
    img = Image.new("RGBA", (max(r.width for r in rows), fs * len(rows)), (0, 0, 0, 0))
    for i, r in enumerate(rows):
        img.paste(r, (0, i * fs))
    img.save(root / "assets/sprites/ship_crew.png")
    (root / "assets/sprites/ship_crew.json").write_text(json.dumps(meta))
    print("ship_crew 시트 생성:", ", ".join(meta["rows"]))


if __name__ == "__main__":
    build(Path(sys.argv[1]))
