#!/bin/zsh
# jobs/<동작>_<방향>.txt 마다 Codex 그림 요청(첨부: 기본 시트 + 그 방향 그림). 결과는 results/<동작>_<방향>.png. 이미 있으면 건너뜀.
cd "$(dirname "$0")"
tool="$(git rev-parse --show-toplevel)/godot/tools/codex_image.sh"
one() {
  j=$1; n=${j:t:r}; d=${n##*_}
  [ -f results/$n.png ] && return
  ref=ref/base_$d.png; [ -f $ref ] || ref=ref/base_S.png
  $tool --skip-git-repo-check -s read-only -i results/base.png -i $ref - < $j > jobs/$n.log 2>&1
  p=$(grep -o "/Users[^ )]*generated_images[^ )]*\.png" jobs/$n.log | tail -1)
  [ -n "$p" ] && cp "$p" results/$n.png && echo "$n ok" || echo "$n 없음"
}
typeset -fx one 2>/dev/null
for j in ${@:-jobs/*.txt}; do
  while [ $(jobs -r | wc -l) -ge ${PAR:-6} ]; do sleep 2; done
  one $j &
done
wait
