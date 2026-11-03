# 오디세우스 옷 갈아입히기 (치비 새 디자인)

2026-11-03에 정한 것. 컨셉 10종 시트는 `outfit/concepts_chibi10.webp`(01 클래식 킹을 전투 갑옷 기준으로 씀).

## 정한 것

- 체형: 치비(약 3등신), 얼굴은 컨셉 시트의 얼굴(곱슬 짙은 머리·짧은 수염)로 고정
- 어떤 옷이든 진홍색 포인트를 하나 이상 남긴다. 잔무늬(망토 테두리 문양·찢김·붕대)는 넣지 않는다
- 부위는 세 칸
  - **몸 옷 한 벌**: 맨머리·망토 없이 그린 몸. 기본 8방향 + 그려 받는 동작 6장(걷기·달리기·공격 1~3·강공격)
  - **머리 장식**: 방향당 한 장, 프레임마다 머리 위치에 붙인다
  - **망토**: 방향당 정지 그림 한 장, 코드로 흔들림. 북·북동·북서는 몸 앞, 나머지는 몸 뒤
- 몸 옷 3벌: 전투 갑옷(챕터 1·3·4), 항해복(2·5), 거지 변장(6)
- 머리 장식 기본 짝: 갑옷 = 이마 위로 올린 코린트 투구(볏은 머리 하나 높이 이하), 항해복 = 청동 머리띠, 거지 = 뒤로 젖힌 두건
- 레이어 위치는 몸 그림에서 머리·어깨를 자동으로 찾고, 틀린 프레임·회전 베기 프레임만 표로 고친다
- 부위 그림은 회색(#808080) 몸 실루엣 위에 그 부위만 그려 받고, 스크립트가 회색·마젠타를 지운다
- 적용: 이름 규칙대로 `assets/source/`에 두고 `python3 tools/gen_hero.py .` → 챕터 스크립트에 `outfit = {body, head, cape}`
- HUD 초상화는 지금 맨머리 일러스트 하나

## 순서

1. 전투 갑옷 기본 8방향(맨머리·망토 없음) → `assets/source/odysseus_8dir.webp`
2. 같은 차림 걷기 12프레임, 다섯 방향을 따로 받아 묶기(아래 2)
3. 달리기 12프레임(아래 3), 공격 4종 (`ATTACK_PROMPTS.md`의 인물 설명 두 줄을 아래 [인물]로 바꿔서)
4. 투구·망토 레이어, 코드 작업
5. 항해복·거지 변장은 챕터 2·6을 만들 때

진행(2026-11-03): 1·2를 받아 넣었다. 걷기는 처음 6프레임 8방향 한 장으로 받았다가, 참고 그림(12프레임·다섯 방향)처럼
방향마다 12프레임으로 다시 받아 바꿨다 — 18fps(한 주기 0.67초, 보폭에 맞춤), 머리 높이 흔들림 1px 안, 주먹은 프레임마다 추적.
동·남동·북동·북은 처음 받은 그림이 다리를 늘 벌리거나 거의 안 움직여 땅 위에서 발이 미끄러지고 팔도 가슴 앞에 굳어 있어,
움직임 안내 그림(`motion_kit/guides/walk12_<방향>.png`, `tools/walk_guide.py`: 디딘 발이 한 장마다 같은 만큼 뒤로, 팔은 다리와 반대로)을 붙여 다시 받았다.
남동·북동은 몸 돌림이 장마다 달라져 "12장 모두 같은 만큼 돌린 채"를 덧붙여 한 번 더 받았다.
남·북도 안내 그림을 붙여 다시 받았다(북은 "발을 크게 벌리고 든 발바닥이 보이게"를 덧붙임).
달리기도 같은 방식(아래 3)으로 다섯 방향을 받아 바꿨다. 공격 4종도 새 차림으로 한 장에 여러 방향씩 9장을 받아 바꿨다(방향 S SE E NE N, 서쪽 셋은 뒤집기). 칼 쥔 주먹·방패 손 위치(`gen_hero.py`의 `ATTACK_HANDS`·`ATTACK_LEFT`)는 격자를 얹어 눈으로 찍은 값이라, 게임에서 보고 어긋난 칸을 고친다.

## [인물] — 다른 요청 프롬프트의 인물 설명 대신 쓰기

```
Odysseus as a cute stocky CHIBI hero (about 3 heads tall: oversized head, compact broad torso, short thick arms,
short strong legs, big fists and feet). Mature heroic face, curly dark-brown hair, short dark beard, sharp eyebrows, warm skin.
BARE HEAD (no helmet) and NO CAPE. Polished bronze muscle cuirass with a Greek key band and round gold shoulder clasps,
dark leather pteruges strips with a crimson cloth panel over a cream linen skirt, bronze bracers, bronze greaves, brown strapped sandals.
```

## 1. 전투 갑옷 기본 8방향

첨부: `outfit/concept01_classic_king.png`(갑옷 모양), `outfit/concept02_bare_head.png`(맨머리 얼굴), `odysseus_reference.png`(배치·방향).

```
Pixel art 8-direction CHARACTER SHEET for an isometric Greek action RPG.
Character: Odysseus as a cute stocky CHIBI hero (about 3 heads tall: oversized head, compact broad torso, short thick arms,
short strong legs, big fists and feet). Mature heroic face, curly dark-brown hair, short dark beard, sharp eyebrows, warm skin.
BARE HEAD (no helmet) and NO CAPE. Polished bronze muscle cuirass with a Greek key band and round gold shoulder clasps,
dark leather pteruges strips with a crimson cloth panel over a cream linen skirt, bronze bracers, bronze greaves, brown strapped sandals.

References:
- "concept01_classic_king.png": copy the armor, colors, body proportions and pixel style EXACTLY, but REMOVE the helmet and the cape.
- "concept02_bare_head.png": copy this bare curly head and face.
- "odysseus_reference.png": copy ONLY the grid layout, the 8 facings and the camera angle. Do not copy its old body or costume.

Layout (very important):
- ONE image 1536x1024, 4 columns x 2 rows, each cell 384x512.
- Top row left to right: NORTH (back), NORTH-EAST (back-right), EAST (right side), SOUTH-EAST (front-right).
- Bottom row left to right: SOUTH (front), SOUTH-WEST (front-left), WEST (left side), NORTH-WEST (back-left).
- Standing battle-ready idle pose, character centered in each cell, about 340px tall,
  feet on the same baseline near the bottom of every cell, same scale in every cell.

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, NO labels, no text.
- 2D pixel art, crisp 1px dark outline, hard pixel clusters, no anti-aliasing blur, no smooth gradients.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees).
- EMPTY HANDS: no sword, no shield, no bow. Right hand a closed fist as if gripping a sword hilt,
  left forearm held as if a round shield is strapped on. Both hands clearly visible.
```

## 2. 걷기 12프레임 (방향마다 한 장, 다섯 방향)

다른 캐릭터에도 쓰는 틀·안내 그림·예시는 `motion_kit/`에 모아 두었다(`motion_kit/README.md`, 요청 폴더는 `tools/motion_request.py`로 만든다).

남(S)·남동(SE)·동(E)·북동(NE)·북(N)을 따로 받고, 서쪽 셋은 뒤집어 만든다.
첨부: 1의 기본 8방향에서 그 방향 칸을 잘라 낸 그림(`pose.png`), 움직임 참고 `outfit/walk12_motion_ref.webp`.
다섯 방향 모두 움직임 안내 `motion_kit/guides/walk12_<방향>.png`도 `guide.png`로 붙이고, Motion 대신 아래를 넣는다:
"MOTION: put his legs, feet, arms and fists where guide.png shows them. The standing foot slides steadily BACKWARD every frame,
legs pass each other in frames 3-4 and 9-10. Arms hang down and swing like a pendulum OPPOSITE to the legs, never held up at the chest."
받은 그림: `assets/source/odysseus_walk_<방향>.webp` → `python3 tools/pack_strip.py . walk 4 3` → `python3 tools/gen_hero.py .`
`__FACING__` 자리에 넣을 말: S `SOUTH (front) - facing the viewer` / SE `SOUTH-EAST (front-right) - facing toward the lower-right` /
E `EAST (right side) - side profile walking to the right` / NE `NORTH-EAST (back-right) - we see his back and right side, walking toward the upper-right` /
N `NORTH (back) - we see his back, walking away from the viewer`
대각선은 덧붙임: "Keep the SAME three-quarter body turn in all 12 frames, never turning more to the front (SE) / to a full back or side view (NE)."
모든 방향: "EXACTLY the same character size and head size in every cell of all three rows" (줄마다 키가 달라지면 머리가 깡충거린다).

```
Pixel art 12-frame WALK CYCLE of the SAME character as the attached "pose.png":
Odysseus as a cute stocky CHIBI hero (about 3 heads tall), bare curly dark-brown head, short dark beard,
bronze muscle cuirass, leather pteruges with a crimson panel over a cream skirt, bronze bracers and greaves, sandals. NO cape, NO helmet.
Keep his face, proportions, colors, outline thickness and pixel density EXACTLY like "pose.png", and keep the same facing in every frame:
__FACING__.

Motion: copy the smooth 12-frame walk TIMING of "walk12_motion_ref.webp" (its row for the same facing), but NOT its character.
Each frame changes only a little from the previous one, evenly spaced in-betweens, so the loop plays smoothly.
- Frames 1-6 = one step on the RIGHT leg: 1 right heel contact (legs widest), 2 down (weight on right, body lowest),
  3 and 4 passing (left leg swings past), 5 up (body highest), 6 left leg reaching forward.
- Frames 7-12 = the SAME poses with the LEFT leg (7 left heel contact ... 12 right leg reaching forward). Frame 12 flows back into frame 1.
- Frames 1 and 7, 2 and 8, ... 6 and 12 have the SAME head height. Body bob is small (2-3px).
- Clear natural stride, arms swing opposite to the legs with relaxed closed fists, shoulders turn slightly with the stride.

Layout (very important):
- ONE image 1536x1024, 4 columns x 3 rows, every cell 384x341, no gaps.
- Frames in reading order: top row 1-4, middle row 5-8, bottom row 9-12.
- Same character size in every cell (about 290px tall), feet on the same baseline near the bottom of every cell,
  character centered in the cell (in-place animation, does not move across the cell).

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, no labels, no text, no frame numbers.
- 2D pixel art, crisp 1px dark outline, no anti-aliasing blur, no motion blur.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees).
- EMPTY HANDS: no sword, no shield. Both hands closed fists.
```

## 3. 달리기 12프레임 (방향마다 한 장, 다섯 방향)

걷기(2)와 같은 첨부·배치·뒷손질에 안내 그림만 `python3 tools/walk_guide.py <출력> <방향 값> run`
(`motion_kit/guides/run12_<방향>.png`: 디딤 3장 + 두 발이 다 뜬 3장, 뒷발 차올림, 무릎 높이, 팔꿈치 직각으로 크게 젓기).
받은 그림: `assets/source/odysseus_run_<방향>.webp` → `python3 tools/pack_strip.py . run 4 3` → `python3 tools/gen_hero.py .`
걷기 프롬프트에서 바꾸는 곳: 첫 줄 `12-frame RUN CYCLE (fast sprint)`, `__FACING__`의 walking → running, MOTION을 아래로.
```
- RUNNING, not walking: the upper body leans a little forward, the hair bounces.
- LEGS: only ONE foot touches the ground in frames 1-3 and 7-9 and it slides BACKWARD fast like on a treadmill.
  In frames 4-6 and 10-12 BOTH feet are OFF the ground (flight): the back foot kicks up behind toward the backside,
  the other knee drives up high in front.
- ARMS: elbows bent about 90 degrees, fists pumping hard forward and back OPPOSITE to the legs
  (right knee up in front = right fist back by the hip, left fist forward at chin height). Never stiff, never both fists in front.
- The ground line is at the same height near the bottom of every cell: the standing foot touches it,
  in flight frames the whole body is a few pixels higher.
```
Style에 `no dust, no speed lines`를 더한다.

## 4. 공격 4종 (한 장에 여러 방향)

한도를 아끼려고 방향마다가 아니라 **한 장에 3방향(heavy는 2방향)을 줄로 받는다**(`motion_kit/README.md` "한도 아끼기").
`python3 tools/motion_request.py assets/source/odysseus_8dir.webp motion_kit/odysseus_character.txt <출력 폴더> attack1,attack2,attack3,heavy 1`로
요청 9개(`pose.png`·`guide.png`·`prompt.txt`, 안내 그림은 `tools/attack_guide.py`)를 만든 뒤 `run.sh`를 돌린다.
받은 그림은 `tools/split_rows.py`로 방향별로 자르고 `tools/pack_strip.py . <동작> <프레임 수> 1`로 묶는다.
주먹·방패 손 위치는 `gen_hero.py`의 `ATTACK_HANDS`·`ATTACK_LEFT`(동·남동·남·북동·북 다섯 방향만, 서쪽은 뒤집어 씀).
