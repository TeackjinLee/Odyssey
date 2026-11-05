#!/bin/zsh
# 요청 폴더 하나를 Codex로 돌린다: one.sh <단위>/<요청>
cd "$(dirname "$0")/$1" || exit 1
imgs=(-i pose.png); [ -f guide.png ] && imgs+=(-i guide.png)
"$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only $imgs - < prompt.txt > ../${1:t}.log 2>&1
