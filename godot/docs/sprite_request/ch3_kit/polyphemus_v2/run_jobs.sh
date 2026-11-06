#!/bin/zsh
# jobs/<동작>_<방향>.txt 마다 Codex 그림 요청(첨부: 기본 시트 + 그 방향 그림). 이미 results/<동작>_<방향>.png가 있으면 건너뜀.
# Codex가 고쳐 그리느라 여러 장을 만들면 전부 results/cand/에 두고 tools/pick_sheet.py가 가장 나은 장을 고른다
# (로그에 경로가 줄여 찍히므로 세션 id로 ~/.codex/generated_images/<id>/에서 찾는다).
cd "$(dirname "$0")"
top="$(git rev-parse --show-toplevel)/godot"
tool="$top/tools/codex_image.sh"
mkdir -p results/cand
one() {
  j=$1; n=${j:t:r}; d=${n##*_}; a=${n%_*}
  [ -f results/$n.png ] && return
  ref=ref/base_$d.png; [ -f $ref ] || ref=ref/base_S.png
  $tool --skip-git-repo-check -s read-only -i results/base.png -i $ref - < $j > jobs/$n.log 2>&1
  sid=$(grep -m1 "^session id:" jobs/$n.log | awk '{print $3}')
  i=0
  for p in ~/.codex/generated_images/$sid/*.png(N); do i=$((i+1)); cp $p results/cand/${n}_$i.png; done
  [ $i -eq 0 ] && { echo "$n 없음"; return; }
  case $a in idle|roar) c=2;; walk8) c=4;; *) c=3;; esac
  [ $a = sleep ] && { c=2; h=160; } || h=380; [ $a = walk8 ] && h=360
  python3 $top/tools/pick_sheet.py $c 2 $h results/$n.png results/cand/${n}_*.png > jobs/$n.pick
  echo "$n ok ($i장 중 고름)"
}
for j in ${@:-jobs/*.txt}; do
  while [ $(jobs -r | wc -l) -ge ${PAR:-6} ]; do sleep 2; done
  one $j &
done
wait
