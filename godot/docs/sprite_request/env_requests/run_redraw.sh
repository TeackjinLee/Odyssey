#!/bin/zsh
# 임시 그림 다시 그려 받기(city_redraw·coast_redraw)를 동시에 돌린다.
cd "$(dirname "$0")"
(cd city_redraw && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i ../troy_env.png -i guide.png - < prompt.txt > ../city_redraw.log 2>&1) &
(cd coast_redraw && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i ../troy_env.png -i guide.png - < prompt.txt > ../coast_redraw.log 2>&1) &
wait
for f in city_redraw.log coast_redraw.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
