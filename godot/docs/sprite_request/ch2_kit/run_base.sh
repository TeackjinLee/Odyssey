#!/bin/zsh
# 2장 기본 그림 6장을 동시에 받는다: 키코네스 4종·항해복 오디세우스(기본 8방향), 아가멤논 전령 초상화
cd "$(dirname "$0")"
go() { "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only "${@:2}" - < $1.txt > $1.log 2>&1 }
for n in cicones_sword cicones_spear cicones_archer cicones_chief; do go $n -i style_ref.png & done
go odysseus_sea -i style_ref.png -i sea_costume.png &
go herald -i portrait_ref.png -i style_ref.png &
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
