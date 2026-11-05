#!/bin/zsh
# 키코네스 배 선체 16방향 요청: a(6방향) → 받은 그림을 received/cicones_hull_a.png로 → b(3방향, a를 같이 붙임)
cd "$(dirname "$0")" || exit 1
T="$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh
grab() { local p=$(grep -E '^/.*\.png$' "$1" | tail -1); [ -n "$p" ] && cp "$p" "received/$2" && echo "received/$2"; }
if [ ! -f received/cicones_hull_a.png ]; then
  $T --skip-git-repo-check -s read-only -i cicones_hull_guide_a.png -i cicones_design_ref.png - < cicones_hull_a.txt > cicones_hull_a.log 2>&1
  grab cicones_hull_a.log cicones_hull_a.png || { echo "a 실패: cicones_hull_a.log"; exit 1; }
fi
$T --skip-git-repo-check -s read-only -i cicones_hull_guide_b.png -i cicones_design_ref.png -i received/cicones_hull_a.png - < cicones_hull_b.txt > cicones_hull_b.log 2>&1
grab cicones_hull_b.log cicones_hull_b.png || { echo "b 실패: cicones_hull_b.log"; exit 1; }
