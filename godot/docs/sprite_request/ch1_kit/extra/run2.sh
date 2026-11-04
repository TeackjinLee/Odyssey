#!/bin/zsh
cd "$(dirname "$0")"
X="codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium --skip-git-repo-check -s read-only"
(cd portrait && eval $X -i concept.png - < prompt.txt > ../portrait.log 2>&1) &
(cd bow_NEd && eval $X -i pose.png -i side.png - < prompt.txt > ../bow_NEd.log 2>&1) &
cd ../units/trojan_sword
sed -i '' 's/codex exec -m gpt-6.1-sol /codex exec -m gpt-6.1-sol -c model_reasoning_effort=medium /' run.sh
zsh -c "$(grep -E '^\(cd walk_' run.sh | tr '\n' ' ') wait"
zsh -c "$(grep -E '^\(cd (attack|hit|death)' run.sh | tr '\n' ' ') wait"
wait
cd ../..
for f in extra/portrait.log extra/bow_NEd.log units/trojan_sword/*.log; do echo "$(basename ${f%.log}) $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
