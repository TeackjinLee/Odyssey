# 2장 그림 요청 기록

1장 키트(`ch1_kit/`)와 같은 흐름으로 2장 인물·배를 받았다. Codex로 요청하고(모델·추론은 `tools/codex_image.sh` 한 곳 — 기본 Sol·low, 한 번만 바꿀 땐 `CODEX_EFFORT=medium ./run_all.sh`), 받은 그림은 `results/`에 모은다.

## 기본 그림 (`run_base.sh`)

| 이름 | 요청 글 | 붙인 그림 | 원본 |
|---|---|---|---|
| 키코네스 전사·창병·궁수·전사장 | `cicones_*.txt` | `style_ref.png` | `assets/source/cicones_*_8dir.webp` |
| 항해복 오디세우스 | `odysseus_sea.txt` | `style_ref.png`(무기·배치) + `sea_costume.png`(옛 항해복, 옷·얼굴) | `odysseus_sea_8dir.webp` |
| 아가멤논의 전령(초상화만) | `herald.txt` | `portrait_ref.png` + `style_ref.png` | `herald_portrait.webp` |
| 로토파고스(섬사람) | `lotophagi.txt` | `style_ref.png` | `lotophagi_8dir.webp` |

키코네스는 트라키아 차림(여우 털모자·초승달 방패·녹슨 붉은색과 짙은 청록, 전사장은 검은 볏 투구·곰털 깃·긴 낫날)으로
트로이 병사와 구별되게 했다. `enemy.gd`는 제 시트(`assets/sprites/<종류>.png`)가 있으면 트로이 시트 색 바꾸기 대신 그것을 쓴다.
전령은 대화창에만 나와서 기본 시트 없이 초상화만 받았다(`gen_hero.py . herald`가 초상화만 만든다).

## 동작

- **키코네스:** `UNIT_KIT=docs/sprite_request/ch2_kit python3 docs/sprite_request/ch1_kit/units/make_motion.py --anims=… <이름>`.
  전사·창병은 걷기·달리기·공격1·2·막기·피격·쓰러짐, 궁수는 걷기·달리기·활쏘기·피격·쓰러짐,
  전사장은 트로이 대장과 같은 동작(공격3·방향마다 한 장인 강공격·뿔나팔)까지. 종·권양기를 쓰지 않아 병사 상호작용은 받지 않았다.
- **항해복 오디세우스:** `python3 docs/sprite_request/ch2_kit/make_sea.py`가 1장 오디세우스의 모든 동작(쓰러져 있기·초상화 포함) 요청 폴더를
  만들고, `armed_patch.py`의 투구·붉은 망토 문구를 머리띠·청록 짧은 망토 문구로 바꾼다.
- **앉기(`sit`, 로토스를 먹고 멍하게 앉은 부하):** `motion_request.py`에 동작을 더해 1장 그리스 병사 셋에 받았다(`ch1_kit/units/greek_*/sit_*`).
  `gen_hero.py`는 `sit` 원본이 있는 캐릭터에만 이 동작을 붙이고, `companion.gd`는 고향을 잊은 부하가 있으면 그것을 쓴다.
- 돌리기: `run_all.sh`(10개씩, 그림 경로가 나온 요청은 건너뜀). 한도에 걸리면 `rerun_later.sh <유닉스 시각>`이 풀린 뒤 다시 보낸다.
- 묶기: `python3 docs/sprite_request/ch2_kit/process.py collect <이름>` → `results/contact_<이름>.png`로 검사 →
  `process.py pack <이름>`(자르기·묶기·`gen_hero.py`). `<이름>:sit`처럼 동작만 고를 수 있다.

**고친 것:** 키코네스 궁수 활쏘기는 1장처럼 모든 줄이 한쪽을 겨눠 `…b`로 다시 받았다(조준 방향 확인 문구).
북동·북(`bow_NE-Nb`, 추론 low로 시험)도 북동 줄이 또 왼쪽을 겨눠, 그 줄만 칸마다 좌우로 뒤집어 `manual_results/cicones_archer__bow_NE-N.png`로 썼다.
키코네스 창병 피격 한 장은 칸 선이 그려져 와서, 가로·세로로 이어진 검은 선만 마젠타로 지웠다.

## 키코네스 배 (`ship/`)

8방향(뱃머리가 그 화면 방향을 향함) 두 장 — 돛 폄(`cicones_boat_sail.txt`)·돛 접음(`cicones_boat_furl.txt`).
`assets/source/cicones_boat_{sail,furl}.webp` → `python3 tools/gen_ship.py . cicones_boat` → `assets/sprites/cicones_boat_*.png/.json`.
`ship.gd`는 뱃머리 화면 방향에 가장 가까운 칸을 골라 선체 폭을 코드 선체 폭에 맞춰 그린다(노는 코드로 그대로).

**오디세우스의 갤리선:** 1장 끝 배(`galley_design_ref.png`) 디자인으로 다시 받았다. 처음엔 돛까지 그린 8방향(`galley2_*.txt`)이었지만
돌 때 끊겨 보이고 노·사람을 올릴 수 없어, **선체만 16방향**으로 바꿨다 — `make_hull_guide.py`가 게임 투영으로 회색 선체 실루엣을
정확한 각도·크기로 그린 안내 그림(`hull_guide_{a,b}.png`)을 만들고, `hull_a.txt`·`hull_b.txt`(돛 편 그림·앞 장 첨부)로 그 위에 그려 받았다
(`received/hull_{a,b}.png` → `assets/source/odysseus_galley_hull_*.webp`). 돛대·돛(5칸 돛 그림의 정면 돛을 잘라 낸 천)·노 젓기·
노 젓는 부하·뱃머리의 오디세우스는 `ship.gd`가 코드로 그린다(사람 시트는 `tools/gen_ship_crew.py`).
→ `python3 tools/gen_ship.py . odysseus_galley --hull` · `python3 tools/gen_ship_crew.py .` → 그리스 배는 `_ready`에서 그 그림을 읽는다(없으면 코드 그림).
**키코네스 배도 같은 방식:** `python3 make_hull_guide.py cicones`가 더 작은 선체(길이 3.3·폭 4:1·갑판 36px, 같은 배율)의 안내 그림
`cicones_hull_guide_{a,b}.png`을 만들고, `cicones_hull_run.sh`가 `cicones_hull_{a,b}.txt`(디자인은 돛 편 8방향 `cicones_design_ref.png`)로
a → b 순서로 받아 `received/cicones_hull_{a,b}.png`에 둔다 → `assets/source/cicones_boat_hull_{a,b}.webp` → `python3 tools/gen_ship.py . cicones_boat --hull`
(돛 천은 8칸 돛 그림의 남쪽 칸에서). `ship.gd`의 `as_enemy_boat`가 그것을 읽어 노 4쌍·노꾼(키코네스 전사·창병 서기 그림의 윗부분만 — 앉은 듯)·
뱃머리와 고물에 서서 쫓는 배를 보는 궁수 둘·낮은 돛대(`mast_k`)를 코드로 그린다. 선체 그림이 없으면 예전 8방향 그림을 쓴다
(그때는 코드 노·머리 점을 그리지 않는다 — 선체 밖에 떠 보여서). 갤리선 돛 천은 `odysseus_galley_sail.webp`(5칸)에서 자르니 그 원본도 둔다.
