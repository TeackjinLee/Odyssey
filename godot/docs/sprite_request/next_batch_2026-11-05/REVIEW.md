# 생성 후보 4장 검수 기록

2026-11-05, 내장 imagegen으로 각 요청 1장씩 생성했다. 프롬프트·첨부·셀 좌표는 각 요청 폴더와 `manifest.json`에 있다. **게임에 적용하지 않은 후보**이며 아래 문제가 있어 바로 잘라 넣지 않는다.

| 결과 | 확인한 것 | 보완할 것 |
|---|---|---|
| `results/lotus_props.png` | 1536×1024, 4×2 소품 8개 구분됨 | 배경 모서리가 (42,46,55) 등으로 달라 순수 `#282B35`가 아님. 배경 재요청 또는 변환기의 배경 분리 검수 필요. 나무·과일 등은 게임 크기로 축소할 때 개별 배율 지정 |
| `results/harbor_props.png` | 1536×1024, 4×2 소품 8개 구분됨 | 배경 모서리가 (41,45,54) 등으로 달라 단색 아님. 밧줄·계선주 등이 크게 그려져 게임 크기로 맞춰야 함. 승선판을 밟는 지형으로 쓰려면 소품 배치와 충돌 별도 설계 |
| `results/throw_E-SE-Sa.png` | 1536×1024, 4프레임×3방향. 투구·망토·방패·등의 활 유지, 칼집 있음 | SE 몸 돌림이 얕고 손·발 기준점이 프레임마다 달라질 수 있음. 게임 크기에서 방향과 손 추적 확인 필요 |
| `results/throw_NE-Na.png` | 1536×1024, 아래 한 줄 빈 마젠타, 4프레임×2방향 | NE 첫 칸은 돌을 든 팔과 다음 칸의 팔 연결이 어색함. N 줄도 완전한 뒷모습보다 옆으로 돌아 있음. **해당 방향 재요청 필요** |

재요청할 때 기존 결과와 같은 폴더의 pose.png를 함께 첨부하고, 다음 보정 문구를 해당 prompt.txt 뒤에 붙인다.

환경 두 장:

> Change only the background: every non-sprite pixel must be the exact same RGB(40,43,53), hex #282B35. Remove the subtle gradient and texture. Keep all eight props, their placement, pixel art and canvas size unchanged.

돌 던지기 NE·N:

> Fix only facing and anatomical continuity. Row1 is BACK-RIGHT facing screen upper-right: RIGHT arm winds back holding the stone in frames1-2, then releases in frame3 and follows through in frame4. The LEFT forearm keeps the same strapped shield in ALL frames. Row2 must be TRUE NORTH, straight back view, no face or side profile in any frame; throw directly away from camera. Match pose.png. Keep bottom row empty magenta. No extra limbs, no arm swapping.

검수 완료 전 `candidate`를 `integrated`로 바꾸지 않는다.
