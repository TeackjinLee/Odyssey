#!/bin/zsh
# 9개 요청을 동시에 돌린다(모델 Sol, 추론 medium). 끝나면 폴더별 생성 그림 경로를 출력.
cd "$(dirname "$0")"
for d in attack1_* attack2_* attack3_* heavy_*(/); do
  (cd $d && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i pose.png -i guide.png - < prompt.txt > ../$d.log 2>&1) &
done
wait
for f in *.log; do echo "${f%.log} $(grep -o "/Users[^ ]*generated_images[^ ]*\.png" $f | tail -1)"; done
