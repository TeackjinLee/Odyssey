#!/bin/zsh
# 2장 동작 요청(항해복 오디세우스·키코네스 4종)을 10개씩 동시에 돌린다(한도). 이미 그림 경로가 나온 로그는 건너뛴다.
cd "$(dirname "$0")"
for j in */*/; do j=${j%/}; [ -f $j/prompt.txt ] || continue
  grep -q "/Users[^ ]*generated_images[^ ]*\.png" $j.log 2>/dev/null || echo $j
done | xargs -P 10 -n 1 ./one.sh
for f in */*.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done > run_all_results.txt
grep -c "png$" run_all_results.txt; grep -v "png$" run_all_results.txt
