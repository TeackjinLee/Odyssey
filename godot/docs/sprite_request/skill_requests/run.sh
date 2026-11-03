#!/bin/zsh
# 모든 요청을 동시에 돌린다. 끝나면 각 폴더의 로그에서 생성된 그림 경로를 찾는다.
cd "$(dirname "$0")"
(cd throw_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../throw_E-SE-Sa.log 2>&1) &
(cd throw_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../throw_NE-Na.log 2>&1) &
(cd fx_skills && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i layout.png -i style_fire.png -i style_hero.png - < prompt.txt > ../fx_skills.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
