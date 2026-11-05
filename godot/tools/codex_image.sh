#!/bin/zsh
# 그림 요청용 Codex 실행 — 모델·추론은 여기 한 곳에서 정한다. 뒤의 인자는 codex exec에 그대로 넘긴다.
# Codex는 요청 글을 내장 그림 도구에 넘기고 경로만 답하므로 추론은 low로 충분하다(그림 질은 그림 도구가 정함).
# 한 번만 바꿀 때: CODEX_MODEL=… CODEX_EFFORT=medium ./run.sh
exec codex exec -m "${CODEX_MODEL:-gpt-6.1-sol}" -c model_reasoning_effort="${CODEX_EFFORT:-low}" "$@"
