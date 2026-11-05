#!/usr/bin/env python3
"""챕터 3 동굴 그림을 게임 폴더로 옮긴다(docs/sprite_request/ch3_kit → assets).

- 바닥: environment/sprites/floor_atlas.png → assets/env/cave/floor_atlas.png (줄: cave_stone·cave_dust·cave_straw, 변형 4)
- 소품: environment/sprites/props/*.png, props/sprites/*.png → assets/env/cave/<이름>.png
- assets/env/cave/cave.json: 소품마다 file·anchor·footprint(막는 칸 수, 게임에서 정함)
- 폴리페모스: polyphemus/motion/sprites/polyphemus.png(대기·걷기), combat/sprites/polyphemus_combat.png(곤봉·움켜잡기)
  → assets/sprites/polyphemus*.png·.json (한 줄 = 한 방향 E SE S SW W NW N NE)

godot/ 안에서:  python3 tools/install_cave.py
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KIT = ROOT / "docs/sprite_request/ch3_kit"
ENV = ROOT / "assets/env/cave"
SPR = ROOT / "assets/sprites"

# 소품이 바닥에서 막는 칸(가로 x, 세로 y). 여기 없는 것은 1×1
FOOTPRINT = {
    "wall_ne": [1, 1], "wall_nw": [1, 1], "wall_ne_cracked": [1, 1], "wall_nw_cracked": [1, 1],
    "corner_inner": [1, 1], "corner_outer": [1, 1],
    "cover_rock": [1, 1], "stalagmites": [1, 1], "fence_ne": [1, 1], "fence_nw": [1, 1],
    "cheese_rack": [1, 1], "milk_amphorae": [1, 1],
    "wine_closed": [1, 1], "wine_open": [1, 1], "stake_cold": [2, 1], "stake_hot": [2, 1],
    "hearth_cold": [2, 2], "hearth_lit": [2, 2], "boulder_closed": [3, 2], "boulder_rolled": [3, 2],
    "pen_gate_closed": [1, 2], "pen_gate_open": [1, 2], "giant_bed": [3, 3], "giant_club": [2, 1],
}


def main() -> None:
    ENV.mkdir(parents=True, exist_ok=True)
    shutil.copy(KIT / "environment/sprites/floor_atlas.png", ENV / "floor_atlas.png")
    out = {"floor_atlas": {"file": "floor_atlas.png", "tile": [64, 32], "rows": ["cave_stone", "cave_dust", "cave_straw"], "variants": 4},
           "props": {}}
    env_meta = json.loads((KIT / "environment/sprites/environment.json").read_text())["props"]
    prop_meta = json.loads((KIT / "props/sprites/props.json").read_text())["items"]
    for name, m in env_meta.items():
        src = KIT / "environment/sprites" / m["file"]
        shutil.copy(src, ENV / f"{name}.png")
        out["props"][name] = {"file": f"{name}.png", "anchor": m["anchor"], "footprint": FOOTPRINT.get(name, [1, 1])}
    for name, m in prop_meta.items():
        shutil.copy(KIT / "props/sprites" / m["file"], ENV / f"{name}.png")
        out["props"][name] = {"file": f"{name}.png", "anchor": m["anchor"], "footprint": FOOTPRINT.get(name, [1, 1])}
    (ENV / "cave.json").write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n")
    for src, dst in [("polyphemus/motion/sprites/polyphemus", "polyphemus"),
                     ("polyphemus/combat/sprites/polyphemus_combat", "polyphemus_combat")]:
        shutil.copy(KIT / f"{src}.png", SPR / f"{dst}.png")
        shutil.copy(KIT / f"{src}.json", SPR / f"{dst}.json")
    print("동굴 소품 %d개, 폴리페모스 시트 2장" % len(out["props"]))


if __name__ == "__main__":
    main()
