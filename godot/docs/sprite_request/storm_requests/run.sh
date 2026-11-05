#!/bin/zsh
# 폭풍 그림 요청 넷을 Codex로 동시에 돌린다. 하나만: ./run.sh sea_storm
cd "$(dirname "$0")"
want=("$@")
[[ ${#want} -eq 0 || ${want[(Ie)]storm_mood} -gt 0 ]] && (cd storm_mood && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../style_env.png -i ../game_storm_now.png - < prompt.txt > ../storm_mood.log 2>&1) &
[[ ${#want} -eq 0 || ${want[(Ie)]sea_storm} -gt 0 ]] && (cd sea_storm && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../style_env.png -i ../game_storm_now.png - < prompt.txt > ../sea_storm.log 2>&1) &
[[ ${#want} -eq 0 || ${want[(Ie)]sea_calm} -gt 0 ]] && (cd sea_calm && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../style_env.png -i ../game_calm_now.png - < prompt.txt > ../sea_calm.log 2>&1) &
[[ ${#want} -eq 0 || ${want[(Ie)]storm_fx} -gt 0 ]] && (cd storm_fx && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../style_fx.png -i guide.png - < prompt.txt > ../storm_fx.log 2>&1) &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
