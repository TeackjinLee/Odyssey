# 생성 후보 3장 검수

모두 내장 imagegen으로 생성했다. 게임 원본·시트는 덮어쓰지 않았다.

| 후보 | 확인 | 적용 전 남은 일 |
|---|---|---|
| 데이포보스 기본 | 1536×1024, 4×2에 8방향 존재. 검은 가로 볏·사자 방패·비늘 갑옷으로 기존 대장과 구분됨 | 요청보다 키가 크게 그려졌고 방향마다 발 기준점이 다름. 칸별 기준점·기존 보스 대비 배율을 정해야 함. 공격 등 전용 동작은 아직 없음 |
| 데이포보스 초상화 | 새 기본 그림을 참조해 얼굴·투구·검은 볏·보라 갑옷을 유지. 전체 투구가 화면 안에 있음 | 실제 크기 1254×1254(요청 1024²와 다름). 초상화 변환 과정에서 얼굴 중심으로 자르고 80×80·보스 바에서 가독성 확인 필요 |
| 그리스 노꾼 | 1536×1024, 4열×5행. E·SE·S·NE·N 방향, 양손에 음식·무기 없음 | 1·2·4칸의 몸통 자세가 비슷해 앞뒤 기울임이 약함. 셀 경계에 발이 가까운 줄이 있어 자동 균등 자르기 전 실루엣 경계 확인. 배의 노 위상과 손 이동 범위를 맞추기 전 적용하지 않음 |

노꾼 동작을 보정할 때는 원본과 style_ref.webp를 첨부하고 다음 문구를 추가한다.

> Keep the same identity, five row facings and magenta background. Increase ONLY rowing motion: frame1 shoulders reach forward over knees, frame2 torso begins backward pull with elbows bending, frame3 shoulders clearly behind hips and fists at lower ribs, frame4 torso returns halfway forward. Keep hips and both planted feet at exactly the same coordinates in every frame. No head turning within a row. Fit the entire silhouette including feet at least12px inside every384x204cell. No oar or bench. Do not repeat identical poses in frames1,2,4.

다음 동작을 생성할 때 데이포보스 후보가 새로운 캐릭터 기준이다. 아게노르 기본 그림을 디자인 참조로 다시 사용하면 두 보스가 같은 모습으로 돌아가므로, 아게노르는 배치·화풍 참고로만 사용한다.

## 2026-11-06 검수·적용

- **노꾼**: 1차는 1·2·4칸 자세가 같아 위 보정 문구를 붙여 다시 받았다(`greek_row/prompt_v1.txt` → `prompt.txt`, 결과 `results/greek_row_v2.png`).
  동·남동 줄은 뒤로 젖히는 3칸이 뚜렷하고 남·북 줄은 약하지만 읽힌다. `assets/source/greek_rower_row.png` → `tools/gen_rower.py` → `gen_ship_crew.py`로 넣었고,
  `ship.gd`가 노의 위상(노깃이 물에 드는 순간 = 뻗기)에 맞춰 프레임을 고른다. 지상의 앉기 동작은 그대로다.
- **데이포보스 기본·초상화**: 디자인 통과 — 검은 가로 볏·사자 방패·보라 비늘 갑옷으로 아게노르와 한눈에 구분된다. 초상화는 흰 배경이라 빼야 한다.
  기본 8방향은 줄 순서가 요청과 달라 보이니(윗줄 뒷모습) 자를 때 칸마다 방향을 확인한다. 동작이 없어 적용은 미룬다.
