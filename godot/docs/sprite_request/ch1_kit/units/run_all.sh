#!/bin/zsh
# 6종 병사 동작 요청을 10개씩 동시에 돌린다(한도). 이미 그림 경로가 나온 로그는 건너뛴다.
cd "$(dirname "$0")"
for u in greek_sword greek_spear greek_archer trojan_spear trojan_archer trojan_captain; do
  for j in $u/*/; do j=${j%/}; [ -f $j/prompt.txt ] || continue
    grep -q "generated_images" $j.log 2>/dev/null || echo $j; done
done | xargs -P 10 -n 1 ./one.sh
for f in {greek,trojan}_{sword,spear,archer,captain}/*.log(N); do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
