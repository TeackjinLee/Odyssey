# 챕터 1 인물 그림 요청 (병사·보스·NPC)

순서: 인물마다 **① 기본 8방향 한 장** → 게임에 넣어 색·크기 확인 → **② 동작마다 한 장에 여러 방향**.
목록·필요 동작·대체 규칙은 [../ART_PLAN.md](../ART_PLAN.md) §4.2, 공통 규칙·검사표는 [README.md](README.md).

오디세우스와 같은 점·다른 점
- **같은 치비 화풍**(약 3등신, 큰 머리, 짧고 굵은 팔다리). 기본 시트 규격도 같다: 1536×1024, 칸 384×512, 윗줄 N NE E SE / 아랫줄 S SW W NW
- 방향은 S SE E NE N 다섯만 동작을 받고 서쪽 셋은 뒤집는다 (`pack_strip.py`와 같은 규칙)
- **무기를 그림에 같이 그린다** (병사는 무기 레이어가 없다) — 그래서 오디세우스용 요청 글(맨손)은 그대로 못 쓰고 아래 틀을 쓴다
- 오디세우스 그림은 **화풍 기준으로만** 첨부한다. 진홍색은 오디세우스의 포인트이므로 병사에게 넓은 붉은 면적 금지

## 1. 인물 설명 (프롬프트의 `[CHARACTER]` 자리에 넣는다)

> 팀 색은 ART_PLAN §1.3의 **제안**이다(그리스 = 청록·흰 볏, 트로이 = 짙은 자주·초승달 방패). 바꾸려면 여기부터 고친다.

| 시트 이름 | 인물 | 기본 시트 키 | 게임 안 키 |
|---|---|---|---|
| `greek_sword` | 그리스 검병 (부하, 정찰병 테르산드로스도 이 시트) | ~320px | ~48px |
| `greek_spear` | 그리스 창병 (부하) | ~320px | ~48px |
| `greek_archer` | 그리스 궁병 (부하) | ~310px | ~47px |
| `trojan_sword` | 트로이 검병 (경보병도 겸함) | ~320px | ~48px |
| `trojan_spear` | 트로이 창병 | ~320px | ~48px |
| `trojan_archer` | 트로이 궁수 | ~310px | ~47px |
| `trojan_captain` | 수비대장 아게노르 (보스) | ~370px | ~56px |
| `sinon` | 첩자 시논 (NPC) | ~310px | ~47px |

**greek_sword**
```
an Achaean (Greek) infantry SWORDSMAN, loyal soldier of Odysseus, drawn as a cute stocky CHIBI (about 3 heads tall: big head,
compact torso, short thick arms and legs). Young face with a short beard. Bronze Corinthian helmet with cheek guards and a short WHITE
horsehair crest, linen-and-bronze cuirass, short TEAL-BLUE cloak to the waist, teal tunic skirt, bronze greaves, sandals.
Right hand: short bronze leaf-blade sword. Left arm: round bronze-rimmed shield painted TEAL with a white owl emblem.
A little smaller and leaner than Odysseus.
```

**greek_spear**
```
an Achaean (Greek) SPEARMAN, loyal soldier of Odysseus, drawn as a cute stocky CHIBI (about 3 heads tall).
Bronze Corinthian helmet with a short WHITE horsehair crest, linen-and-bronze cuirass, short TEAL-BLUE cloak, teal tunic skirt,
bronze greaves, sandals. Right hand: a long wooden spear with a bronze leaf head, about 1.5 times his height, held upright.
Left arm: round shield painted TEAL with a white owl emblem.
```

**greek_archer**
```
an Achaean (Greek) ARCHER, loyal soldier of Odysseus, drawn as a cute slim CHIBI (about 3 heads tall).
No helmet: curly dark hair with a teal headband. Light brown leather vest over a TEAL tunic, leather bracers, sandals,
quiver of white-fletched arrows on his back. Left hand: a wooden recurve bow. No shield.
```

**trojan_sword**
```
a TROJAN SWORDSMAN (enemy), drawn as a cute stocky CHIBI (about 3 heads tall). Tall bronze helmet with a forward-curving crest
dyed DEEP PURPLE. Bronze scale-armor shirt over a DEEP PURPLE tunic with gold trim, short purple cloak, bronze greaves, boots.
Right hand: a curved bronze short sword. Left arm: a crescent-shaped (pelta) wicker shield with a bronze rim.
Clearly different silhouette from the Greeks (tall curved crest, crescent shield).
```

**trojan_spear**
```
a TROJAN SPEARMAN (enemy), drawn as a cute stocky CHIBI (about 3 heads tall). Tall bronze helmet with a forward-curving crest dyed
DEEP PURPLE, bronze scale-armor shirt over a DEEP PURPLE tunic with gold trim, short purple cloak, bronze greaves, boots.
Right hand: a long spear with a bronze head, about 1.5 times his height. Left arm: crescent-shaped (pelta) wicker shield with a bronze rim.
```

**trojan_archer**
```
a TROJAN ARCHER (enemy) in Anatolian style, drawn as a cute slim CHIBI (about 3 heads tall). Soft DEEP PURPLE Phrygian cap
(pointed tip bent forward), purple tunic with gold zigzag trim, patterned leggings, leather boots, quiver hanging at the hip.
Left hand: a short composite bow. No shield, no armor.
```

**trojan_captain**
```
AGENOR, captain of the Trojan gate guard (boss), drawn as a big stocky CHIBI (about 3 heads tall, clearly taller and broader than
the soldiers). Older warrior with a grey-streaked beard. Ornate gilded bronze helmet with a very tall DEEP PURPLE plume,
gold-trimmed bronze scale armor, long DEEP PURPLE cloak, bronze greaves. Right hand: a heavy bronze sword.
Left arm: a large round bronze shield with a gold horse emblem, a curved bronze war horn hanging at his belt. Proud, imposing stance.
```

**sinon**
```
SINON, a Greek spy pretending to be a beaten deserter, drawn as a cute slim CHIBI (about 3 heads tall). Messy dark hair,
short scruffy beard, bruised face, torn and dirty undyed cream tunic, barefoot, loose rope hanging from both wrists.
No weapon, no armor. Sly but pitiful look.
```

---

## 2. ① 기본 8방향 — 첨부 `layouts/turnaround_4x2.png` + `assets/source/odysseus_8dir.webp`

받을 이름: `assets/source/<시트 이름>_8dir.webp`. `[CHARACTER]`를 §1의 설명으로, `[HEIGHT]`를 기본 시트 키로 바꾼다.

```
Pixel art 8-direction CHARACTER SHEET of a NEW character for an isometric Greek action RPG:
[CHARACTER]

References:
- "odysseus_8dir.webp": copy EXACTLY its chibi proportions, art style, outline thickness, shading, palette warmth and pixel density —
  but this is a DIFFERENT person: do NOT copy Odysseus's face, beard, armor or crimson colors.
- "turnaround_4x2.png": copy the grid. The grey silhouettes only show size, facing and foot position; replace them with the character.

Layout (very important):
- ONE image 1536x1024, 4 columns x 2 rows, each cell 384x512, no gaps.
- Top row left to right: NORTH (back), NORTH-EAST (back-right), EAST (right side), SOUTH-EAST (front-right).
- Bottom row left to right: SOUTH (front), SOUTH-WEST (front-left), WEST (left side), NORTH-WEST (back-left).
- Standing battle-ready idle pose holding the weapon, same pose in every direction, character centered in each cell,
  about [HEIGHT] tall, feet on the same baseline near the bottom of every cell, same scale in every cell.

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, NO labels, no text.
- 2D pixel art, crisp 1px dark outline, hard pixel clusters, no anti-aliasing blur, no smooth gradients.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees).
- The weapon and shield are drawn as part of the character and stay inside the cell.
```

---

## 3. ② 동작 — 한 장에 3방향(E·SE·S) 또는 2방향(NE·N)

첨부: `pose.png` = 그 인물 기본 시트에서 그 방향 칸들을 왼→오로 이어 붙인 그림.
`python3 tools/motion_request.py <인물>_8dir.webp <설명.txt> <출력> idle 1`로 만들면 `pose.png`가 같은 방식으로 생긴다
(그 `prompt.txt`는 맨손 규칙이라 쓰지 말고 아래 틀을 쓴다).
받으면 `split_rows.py … --sheet=<시트>`로 방향별로 자르고 `pack_strip.py . <동작> … --sheet=<시트>`로 묶는다.

빈칸: `[N]` 프레임 수, `[DIRS]` 줄 목록, `[GRID]` 격자 (3줄이면 `[N] columns x 3 rows, every cell (1536/[N])x341`),
`[EMPTY]` 2방향이면 `The last row stays EMPTY magenta.`, `[ACTION]` 아래 동작 글.

```
Use your built-in image generation tool to create exactly ONE image. Attached: pose.png = the SAME character standing in the facings
listed below, left to right.

Pixel art [N]-frame animation of the SAME character as in "pose.png":
[CHARACTER]
Keep his face, proportions, colors, weapon, outline thickness and pixel density EXACTLY like "pose.png".
In each ROW he keeps facing that row's direction:
[DIRS]

MOTION (the same motion in every row, frames left to right):
[ACTION]
- Diagonal rows keep the SAME three-quarter body turn in every frame. No effect lines, no dust, no blood.

Layout (very important):
- ONE image 1536x1024, [GRID], no gaps. [EMPTY]
- EXACTLY the same character size and head size in every cell of every row, feet on the same ground line near the bottom of every row.
  In-place animation: the hip stays near the cell center.

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, no labels, no text, no frame numbers.
- 2D pixel art, crisp 1px dark outline, no anti-aliasing blur, no motion blur.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees).
- The weapon and shield are drawn in every frame and stay inside the cell.
```

`[DIRS]` 예 (3방향): 
```
  Row 1: EAST, right side profile toward the right
  Row 2: SOUTH-EAST (front-right), three-quarter front view toward the lower-right
  Row 3: SOUTH (front), facing the viewer
```
(2방향: `Row 1: NORTH-EAST (back-right), we see his back and right side` / `Row 2: NORTH (back), we see only his back`)

### 누가 무엇을

| 동작 | 프레임 | 누가 | 메모 |
|---|---|---|---|
| walk | 6 | 모두 | 순찰 |
| idle | 4 | 모두 | 없으면 기본 포즈를 코드로 숨쉬기(지금 방식) |
| run | 6 | 트로이 병사·부하 | 알아챈 뒤 뛰어옴. 없으면 walk를 빠르게 |
| attack1 | 4 | 검병·창병·아게노르 | |
| attack2 | 4 | 검병·창병·아게노르 | 없으면 attack1 |
| attack3 · heavy | 5 · 6 | 아게노르 | 3연타 끝·내려찍기 |
| bow | 4 | 궁병·궁수 | |
| block | 2 | 검병·창병·아게노르 | 방패벽 병사도 이것 |
| hit | 2 | 시논 빼고 모두 | |
| death | 5 | 시논 빼고 모두 | 마지막 칸 = 쓰러진 부하 `downed` |
| interact | 4 | 트로이 병사 | 경보 종 치기·꺼진 횃불 다시 켜기 |
| horn · charge | 4 · 4 | 아게노르 (있으면 좋음) | 뿔나팔 불기, 방패 앞세운 돌진 |

### `[ACTION]` 문구

**walk** (6)
```
- A clear marching step: 1 right foot forward contact, 2 down (weight on right), 3 passing, 4 left foot forward contact,
  5 down (weight on left), 6 passing. Frame 6 flows back into frame 1.
- The standing foot slides steadily BACKWARD every frame; the arm without a shield swings opposite to the legs, never frozen.
```
**idle** (4)
```
- 1 ready stance holding the weapon, 2 breathing in (chest and shoulders up 2 pixels), 3 top of the breath, 4 breathing out.
  Loopable, very subtle, the feet never move.
```
**run** (6)
```
- RUNNING: upper body leaning forward. Frames 1-3 one foot on the ground sliding backward fast, frames 4-6 both feet off the ground
  (back foot kicked up, other knee high). Weapon held close, cloak streaming back. Loopable.
```
**attack1 — 검** (4)
```
- 1 wind-up: sword pulled back beside the right shoulder, shield forward. 2 swing: step forward, sword sweeping across at chest height.
  3 follow-through: sword extended to his LEFT side. 4 recovery toward the ready stance.
```
**attack1 — 창** (4)
```
- 1 wind-up: spear drawn back overhand at shoulder height, shield forward. 2 thrust: big step forward, spear driving straight toward
  the facing direction. 3 full extension. 4 recovery: pulling the spear back to the ready stance.
```
**attack2** (4)
```
- Sword: 1 sword low on his LEFT side, 2 sweeping up and out to the right, 3 extended high to his RIGHT side, 4 recovery.
- Spear: 1 spear held low at the hip, 2 low thrust forward, 3 full low extension, 4 recovery.
```
**attack3 — 아게노르** (5)
```
- 1 sword rising past the shoulder, 2 sword raised high above the head, 3 lunge forward chopping down,
  4 deep crouch, sword low in front, cloak flying up, 5 recovery.
```
**heavy — 아게노르 내려찍기** (6) — 게임에서는 앞쪽 바닥에 충격파 원이 퍼지고 화면이 흔들린다
```
- 1 sword lifted high above the head with both hands, shield held aside, 2 rising on his toes, back arched,
  3 leaping forward and smashing the sword down into the ground in front, 4 impact: deep crouch, blade on the ground,
  5 holding the crouch, 6 heavy recovery pulling the sword back up. No dust or shockwave drawn (the game adds them).
```
**bow** (4)
```
- 1 bow raised toward the facing direction, nocking an arrow, 2 drawing the string to the chest, 3 full draw to the jaw, holding,
  4 release, drawing hand snaps back. Arrow visible in frames 1-3 only.
```
**block** (2)
```
- 1 shield raised high in front of the body toward the facing direction, knees bent, weapon pulled back.
  2 the same pose pushed back 3 pixels, absorbing a hit.
```
**hit** (2)
```
- 1 flinch: upper body snapped back away from the facing direction, shield and arms jerked out. 2 recovering halfway to the ready stance.
```
**death** (5)
```
- 1 stagger back, 2 knees buckling, 3 kneeling and tipping backward, 4 hitting the ground on his back,
  5 lying still on his back with the weapon dropped beside him (held frame). Keep the fallen body COMPACT inside the cell.
```
**interact** (4)
```
- Striking an alarm bell / reaching up to light a torch in front of him: 1 weapon arm raised, 2 swinging forward and up,
  3 hitting/touching the point at head height in front, 4 pulling back. Loopable. The bell or torch is NOT drawn.
```
**horn — 아게노르** (4)
```
- 1 shield lowered, left hand bringing a curved bronze war horn to the mouth, 2 chest swelling, leaning back,
  3 blowing hard, head tilted up, 4 lowering the horn.
```
**charge — 아게노르** (4)
```
- Shield-first charge: big round shield held in front with the shoulder behind it, body low and leaning forward, legs pumping.
  1-4 a running loop in this pose.
```

---

## 4. 넣는 법

병사 시트는 아직 생성기 임시 그림(칸 64)이다. 받으면:

1. 기본 8방향 → `assets/source/<시트>_8dir.webp` (예: `trojan_sword_8dir.webp`)
2. 동작 그림(있으면) → `python3 tools/split_rows.py <받은 그림> <동작> <방향들> . --sheet=<시트>` →
   `python3 tools/pack_strip.py . <동작> <열> <줄> [프레임 수] --sheet=<시트>` → `assets/source/<시트>_<동작>_8dir.webp`
3. `python3 tools/gen_soldier.py . <시트>` → `assets/sprites/<시트>.png/.json`(칸 128·`scale` 0.5) → `--auto`로 확인

대체 규칙: 기본 8방향이 없으면 임시 인물을 그대로 둔다. 기본 8방향만 있으면 모든 동작을 그 포즈를 기울이고·눌렀다 펴서 만든다
(그래서 기본 8방향만 받아도 바로 넣어 볼 수 있다). 동작 줄이 있는 동작만 그린 그림을 쓴다.
키(시트 안 px)는 `gen_soldier.py`의 `TARGET_H`(게임 안 키 × 2).
