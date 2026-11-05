#!/usr/bin/env python3
"""환경 그림 요청 묶음 만들기: docs/sprite_request/environment.md의 프롬프트 블록 → env_requests/<시트>/prompt.txt + run.sh

    python3 tools/env_request.py .

environment.md에서 "받을 이름 `<시트>.webp`" 제목 아래 첫 코드 블록을 프롬프트로 쓴다(이미 받은 troy_fire는 뺀다).
첨부 그림은 png로 바꿔 env_requests/에 한 번만 둔다: troy_env.png(화풍 기준), city_layout.png(챕터 1 참고 지도).
"""
import os
import re
import sys

from PIL import Image

SHEETS = {
    # 시트 이름: 첨부(순서대로 FIRST, SECOND …)
    "troy_extra": ["troy_env.png"],
    "troy_city": ["troy_env.png", "city_layout.png"],
    "troy_coast": ["troy_env.png", "city_layout.png"],
}
ATTACH = {
    "troy_env.png": ("assets/source/troy_env.webp",
                     "the STYLE reference: isometric Greek city of Troy at night, one floor tile = 64x32 px"),
    "city_layout.png": ("docs/references/environment/ch1_troy__city-layout.webp",
                        "a reference picture of the whole city, for building SHAPES and MATERIALS only"),
}
CODEX = '"$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh'   # 모델·추론은 tools/codex_image.sh에서


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    doc = open(os.path.join(root, "docs/sprite_request/environment.md"), encoding="utf-8").read()
    out = os.path.join(root, "docs/sprite_request/env_requests")
    os.makedirs(os.path.join(out, "results"), exist_ok=True)
    for name, (src, _) in ATTACH.items():
        Image.open(os.path.join(root, src)).convert("RGB").save(os.path.join(out, name))
    lines = ["#!/bin/zsh", "# 환경 시트 요청을 동시에 돌린다. 끝나면 각 로그에서 생성된 그림 경로를 찾는다.", 'cd "$(dirname "$0")"']
    for sheet, files in SHEETS.items():
        m = re.search(r"받을 이름 `" + sheet + r"\.webp`.*?```\n(.*?)```", doc, re.S)
        if not m:
            raise SystemExit(f"environment.md에 {sheet} 프롬프트가 없다")
        head = ["Use your built-in image generation tool to create exactly ONE image from the prompt below. Attached image"
                + ("s:" if len(files) > 1 else ":")]
        for i, f in enumerate(files):
            head.append(f"{i + 1}) {f} = {ATTACH[f][1]}.")
        head.append("Do not write code or edit any files. When the image is generated, reply with its saved file path only.")
        head.append("Make the image 1536x1024 (landscape).")
        d = os.path.join(out, sheet)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "prompt.txt"), "w", encoding="utf-8") as fp:
            fp.write("\n".join(head) + "\n\n" + m.group(1))
        imgs = " ".join(f"-i ../{f}" for f in files)
        lines.append(f"(cd {sheet} && {CODEX} --skip-git-repo-check -s read-only {imgs} - < prompt.txt"
                     f" > ../{sheet}.log 2>&1) &")
        print(d)
    lines += ["wait", 'for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\\.png" $f | tail -1)"; done']
    rs = os.path.join(out, "run.sh")
    with open(rs, "w") as fp:
        fp.write("\n".join(lines) + "\n")
    os.chmod(rs, 0o755)
    print(rs)


if __name__ == "__main__":
    main()
