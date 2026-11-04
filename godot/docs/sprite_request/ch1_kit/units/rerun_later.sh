#!/bin/zsh
# Codex 한도가 풀린 뒤(오후 2시 5분) 그림이 안 나온 요청을 다시 돌린다
cd "$(dirname "$0")"
while [ $(date +%H%M) -lt 1405 ]; do sleep 60; done
./run_all.sh > run_all_results.txt 2>&1
