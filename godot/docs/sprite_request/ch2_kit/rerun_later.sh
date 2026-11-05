#!/bin/zsh
# Codex 한도가 풀린 뒤(로그의 resets_at) 남은 요청을 다시 보낸다: rerun_later.sh <유닉스 시각>
cd "$(dirname "$0")"
while [ $(date +%s) -lt $1 ]; do sleep 60; done
./run_all.sh
