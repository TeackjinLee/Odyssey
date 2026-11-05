#!/bin/zsh
# 환경 시트 요청을 동시에 돌린다. 끝나면 각 로그에서 생성된 그림 경로를 찾는다.
cd "$(dirname "$0")"
(cd troy_extra && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../troy_env.png - < prompt.txt > ../troy_extra.log 2>&1) &
(cd troy_city && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../troy_env.png -i ../city_layout.png - < prompt.txt > ../troy_city.log 2>&1) &
(cd troy_coast && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../troy_env.png -i ../city_layout.png - < prompt.txt > ../troy_coast.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
