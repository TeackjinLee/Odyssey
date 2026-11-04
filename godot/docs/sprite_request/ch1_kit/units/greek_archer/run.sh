#!/bin/zsh
# 모든 요청을 동시에 돌린다. 끝나면 각 폴더의 로그에서 생성된 그림 경로를 찾는다.
cd "$(dirname "$0")"
(cd run_Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../run_Na.log 2>&1) &
(cd run_NEa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../run_NEa.log 2>&1) &
(cd run_Ea && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../run_Ea.log 2>&1) &
(cd run_SEa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../run_SEa.log 2>&1) &
(cd run_Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../run_Sa.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
