#!/bin/zsh
# 모든 요청을 동시에 돌린다. 끝나면 각 폴더의 로그에서 생성된 그림 경로를 찾는다.
cd "$(dirname "$0")"
(cd walk_Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../walk_Na.log 2>&1) &
(cd walk_NEa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../walk_NEa.log 2>&1) &
(cd walk_Ea && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../walk_Ea.log 2>&1) &
(cd walk_SEa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../walk_SEa.log 2>&1) &
(cd walk_Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../walk_Sa.log 2>&1) &
(cd attack1_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../attack1_E-SE-Sa.log 2>&1) &
(cd attack1_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../attack1_NE-Na.log 2>&1) &
(cd attack2_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../attack2_E-SE-Sa.log 2>&1) &
(cd attack2_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../attack2_NE-Na.log 2>&1) &
(cd hit_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../hit_E-SE-Sa.log 2>&1) &
(cd hit_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../hit_NE-Na.log 2>&1) &
(cd death_E-SE-Sa && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../death_E-SE-Sa.log 2>&1) &
(cd death_NE-Na && codex exec -m gpt-6.1-sol --skip-git-repo-check -s read-only -i pose.png - < prompt.txt > ../death_NE-Na.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
