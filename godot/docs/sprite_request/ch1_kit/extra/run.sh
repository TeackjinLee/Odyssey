#!/bin/zsh
# 모든 요청을 동시에 돌린다. 끝나면 각 폴더의 로그에서 생성된 그림 경로를 찾는다.
cd "$(dirname "$0")"
(cd heavy_Ea && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../heavy_Ea.log 2>&1) &
(cd heavy_SEa && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../heavy_SEa.log 2>&1) &
(cd heavy_Sa && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../heavy_Sa.log 2>&1) &
(cd heavy_NEa && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../heavy_NEa.log 2>&1) &
(cd heavy_Na && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../heavy_Na.log 2>&1) &
(cd interact_E-SE-Sa && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../interact_E-SE-Sa.log 2>&1) &
(cd interact_NE-Na && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../interact_NE-Na.log 2>&1) &
(cd downed_all && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../downed_all.log 2>&1) &
(cd bow_NE-Nc && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../bow_NE-Nc.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
