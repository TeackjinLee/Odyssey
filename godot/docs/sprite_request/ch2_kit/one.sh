#!/bin/zsh
# 요청 폴더 하나를 Codex로 돌린다: one.sh <단위>/<요청>
cd "$(dirname "$0")/$1" || exit 1
imgs=(-i pose.png); [ -f guide.png ] && imgs+=(-i guide.png)
codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only $imgs - < prompt.txt > ../${1:t}.log 2>&1
