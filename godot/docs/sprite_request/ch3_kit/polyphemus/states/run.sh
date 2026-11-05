#!/bin/zsh
# 네 동작을 Codex로 동시에 요청한다(첨부: 기본 5방향 시트). 끝나면 로그에서 그림 경로를 찾아 results/<이름>.png로 복사한다.
cd "$(dirname "$0")"
top="$(git rev-parse --show-toplevel)"
for j in drunk eye_wound grope sleep; do
  (cd $j && "$top"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i ../../results/polyphemus_base.png - < prompt.txt > ../$j.log 2>&1) &
done
wait
for j in drunk eye_wound grope sleep; do
  p=$(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $j.log | tail -1)
  echo "$j ${p:-없음}"
  [ -n "$p" ] && cp "$p" results/$j.png
done
