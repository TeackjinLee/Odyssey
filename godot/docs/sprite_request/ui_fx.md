# 이펙트·UI 그림 요청

목록·상태는 [../ART_PLAN.md](../ART_PLAN.md) §4.5·§4.6, 공통 규칙·검사표는 [README.md](README.md).
이펙트는 받은 한 장에서 이펙트마다 프레임 줄을 잘라 `assets/fx/<이름>.png`(가로로 늘어놓은 프레임) + `<이름>.json`으로 두면 `fx.gd`가 바로 쓴다
(이름 hit·block·parry·dust·shout·takedown·decoy_dust, json 형식은 godot/README.md "그림 바꾸기"). UI 그림은 아직 `hud.gd`에 경로를 더해야 한다.

## 0. 진행 상태

| 그림 | 받을 이름 | 상태 |
|---|---|---|
| 전투 이펙트 한 장 | `fx_combat.webp` | §1 |
| UI 아이콘 한 장 | `ui_icons.png` | §2 |
| HUD 틀·대화창 틀 | `ui_frames.png` | §3 |
| 부하·NPC·보스 초상화 | `<시트 이름>_portrait.jpg` | §4 |
| 타이틀 로고 | `ui_logo.png` | §5 |

---

## 1. 전투 이펙트 (한 장) — 받을 이름 `fx_combat.webp`

첨부: `assets/source/odysseus_8dir.webp` + `assets/source/troy_fire.webp` (이펙트 화풍 기준)

```
Pixel art combat effects sprite sheet for an isometric action game, matching the outline style, palette and pixel density
of the attached references (the fire sheet and the chibi Odysseus character). Solid flat dark background #282B35.
Each row is one effect, frames left to right, every frame in its own cell of the given size, no gaps, no text, no grid lines.

Row 1: HIT SPARK, 4 frames, 48x48 cells: a bright white-yellow star burst with orange edges, growing then breaking into sparks.
Row 2: PARRY FLASH, 4 frames, 64x64 cells: a sharp white-gold ring flash with four short light rays, expanding and fading.
Row 3: SHIELD BLOCK SPARKS, 3 frames, 48x48 cells: a fan of small orange-yellow metal sparks spraying to one side (to the right).
Row 4: DUST PUFF, 5 frames, 64x32 cells: a low flat cloud of grey-brown dust hugging the ground, spreading sideways and fading.
Row 5: WAR CRY RING, 6 frames, 192x96 cells: a flat isometric ellipse ring on the ground (2:1), golden-orange,
       expanding from small to the full cell and thinning out.
Row 6: STEALTH TAKEDOWN, 4 frames, 48x48 cells: a quick dark-blue crescent swipe with a few white star sparks, fading.

2D pixel art, crisp pixels, no anti-aliasing blur, no soft glow halo baked in, no blood.
```

---

## 2. UI 아이콘 (한 장) — 받을 이름 `ui_icons.png`

게임 안 24×24 → 4배(96×96 칸)로 받아 변환 때 48×48로 줄인다. 첨부: `assets/source/odysseus_8dir.webp`.

```
Pixel art game UI icon set, ancient Greek theme, matching the palette (bronze, gold, teal, crimson) and pixel style of the
attached chibi character sheet. 12 icons in TWO rows of 6, every icon centered in its own 96x96 cell, no gaps (whole image 576x192).
Solid flat magenta background #FF00FF, crisp 1px dark outline, no text, no letters, no numbers.

Row 1: 1 bronze leaf-blade sword (diagonal), 2 recurve bow with an arrow (diagonal), 3 war cry: a bronze helmet with sound waves,
4 "follow me": a pointing bronze gauntlet, 5 "hold position": a round shield planted with a spear behind it,
6 "focus attack": a red target ring with a spear tip.
Row 2: 7 "retreat": a curved arrow pointing back over a shield, 8 interact: an open hand,
9 suspicion: a yellow question mark on a small dark round badge, 10 alerted: a red exclamation mark on a small dark round badge,
11 checkpoint: a small lit bronze brazier, 12 sneak: a hooded eye half closed.
```

---

## 3. HUD 틀·대화창 틀 (한 장) — 받을 이름 `ui_frames.png`

대화창 틀은 9칸으로 잘라 늘려 쓴다(모서리 4·변 4·가운데 1).

```
Pixel art game UI frames, ancient Greek theme, bronze and dark teal, meander (Greek key) pattern trim,
matching the pixel style of the attached "odysseus_8dir.webp". Solid flat magenta background #FF00FF, no text.
Items separated with space:
1 a horizontal health bar frame 200x24 (empty inside, dark), 2 the same frame for the stamina bar 200x16,
3 a square skill slot frame 48x48 (empty inside), 4 a round minimap border ring 128x128 (empty inside, transparent center),
5 a dialogue box 384x96: dark teal panel with a bronze meander border; corners must be decorative and the straight edges
  must be repeatable so the box can be stretched, 6 a small name plate 128x24 in the same style.
```

---

## 4. 초상화 — 받을 이름 `<시트 이름>_portrait.jpg`

첨부: `assets/source/odysseus_portrait.jpg` (초상화 화풍 기준) + 그 인물의 `<시트 이름>_8dir` 기준 모습.
받으면 `gen_hero.py`의 `make_portrait`처럼 얼굴 상자를 잘라 80×80으로 만든다.

```
Bust portrait illustration of the character shown in the attached sprite sheet "<sheet name>_8dir":
[CHARACTER — soldiers.md §1의 설명]
Same painting style, lighting, framing and level of detail as the attached "odysseus_portrait.jpg".
Head and shoulders, three-quarter view facing slightly left, plain pure white background, no text.
```

---

## 5. 타이틀 로고 — 받을 이름 `ui_logo.png`

```
Pixel art game title logo "ODYSSEY", ancient Greek style capital letters carved in weathered bronze with gold highlights,
a thin red cape-like ribbon behind the letters and a small Greek meander line under them. About 640x200.
Solid flat magenta background #FF00FF, crisp pixel edges, no other text.
```

한글 부제("오디세우스의 귀환")는 그림으로 받지 않고 게임 글꼴(ART_PLAN §4.6 `U-font`)로 쓴다.
