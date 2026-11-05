#!/bin/zsh
# 모든 요청을 동시에 돌린다. 끝나면 각 폴더의 로그에서 생성된 그림 경로를 찾는다.
cd "$(dirname "$0")"
(cd interact_E-SE-Sa && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../interact_E-SE-Sa.log 2>&1) &
(cd interact_NE-Na && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../interact_NE-Na.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
