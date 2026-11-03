#!/bin/zsh
cd "$(dirname "$0")"
(codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i style_ref.png - < greek_sword.txt > greek_sword.log 2>&1) &
(codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i style_ref.png - < greek_spear.txt > greek_spear.log 2>&1) &
(codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i style_ref.png - < greek_archer.txt > greek_archer.log 2>&1) &
(codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i style_ref.png - < trojan_sword.txt > trojan_sword.log 2>&1) &
(codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i style_ref.png - < trojan_spear.txt > trojan_spear.log 2>&1) &
(codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i style_ref.png - < trojan_archer.txt > trojan_archer.log 2>&1) &
(codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i style_ref.png - < trojan_captain.txt > trojan_captain.log 2>&1) &
(cd ../extra/heavy_Eb && codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../heavy_Eb.log 2>&1) &
wait
for f in *.log ../extra/heavy_Eb.log; do echo "$(basename ${f%.log}) $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
