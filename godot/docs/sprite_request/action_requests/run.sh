#!/bin/zsh
# 모든 요청을 동시에 돌린다. 끝나면 각 폴더의 로그에서 생성된 그림 경로를 찾는다.
cd "$(dirname "$0")"
(cd idle_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../idle_E-SE-Sa.log 2>&1) &
(cd idle_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../idle_NE-Na.log 2>&1) &
(cd hit_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../hit_E-SE-Sa.log 2>&1) &
(cd hit_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../hit_NE-Na.log 2>&1) &
(cd block_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../block_E-SE-Sa.log 2>&1) &
(cd block_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../block_NE-Na.log 2>&1) &
(cd dodge_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../dodge_E-SE-Sa.log 2>&1) &
(cd dodge_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../dodge_NE-Na.log 2>&1) &
(cd bow_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../bow_E-SE-Sa.log 2>&1) &
(cd bow_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../bow_NE-Na.log 2>&1) &
(cd death_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../death_E-SE-Sa.log 2>&1) &
(cd death_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../death_NE-Na.log 2>&1) &
(cd interact_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../interact_E-SE-Sa.log 2>&1) &
(cd interact_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../interact_NE-Na.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
