#!/bin/zsh
# 임시 그림 다시 그려 받기(city_redraw·extra_redraw·coast_redraw)를 동시에 돌린다. 하나만: ./run_redraw.sh extra_redraw
cd "$(dirname "$0")"
want=("$@")
[[ ${#want} -eq 0 || ${want[(Ie)]city_redraw} -gt 0 ]] && (cd city_redraw && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i ../troy_env.png -i guide.png - < prompt.txt > ../city_redraw.log 2>&1) &
[[ ${#want} -eq 0 || ${want[(Ie)]extra_redraw} -gt 0 ]] && (cd extra_redraw && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i ../troy_env.png -i guide.png - < prompt.txt > ../extra_redraw.log 2>&1) &
[[ ${#want} -eq 0 || ${want[(Ie)]coast_redraw} -gt 0 ]] && (cd coast_redraw && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i ../troy_env.png -i guide.png - < prompt.txt > ../coast_redraw.log 2>&1) &
wait
for f in *_redraw.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
