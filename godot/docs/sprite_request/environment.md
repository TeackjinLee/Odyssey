# 환경 그림 요청

환경은 소품 여러 개를 **어두운 단색 배경 한 장**에 띄엄띄엄 받고, `tools/gen_env_from_sheet.py`가 상자 좌표(`ITEMS`)로 잘라 쓴다.
새 시트를 받으면 그림마다 상자 좌표·발자국 칸 수를 스크립트에 더해야 한다(Claude에게 "잘라서 넣어 줘"라고 하면 된다).
공통 규칙·검사표는 [README.md](README.md), 목록·상태는 [../ART_PLAN.md](../ART_PLAN.md) §4.4.

- 늘 같이 첨부: `assets/source/troy_env.webp` (화풍·크기 기준 — 바닥 칸 한 개가 64×32px)
- Codex로 돌릴 요청 묶음(`prompt.txt`·첨부·`run.sh`)은 [env_requests/](env_requests/README.md) — 이 문서를 고치면 `python3 tools/env_request.py .`로 다시 만든다

## 0. 진행 상태

| 그림 | 받을 이름 | 상태 |
|---|---|---|
| 성벽·성탑·성문·집 4채·목마·소품·바닥 6종 | `troy_env.webp` | ✅ |
| 불꽃·연기 | `troy_fire.webp` | ✅ |
| 꺼진 횃불대 | (`torch_post`를 가공) | ✅ |
| 경보 종·권양기·화로·그리스 깃발·화살 + 무기고·시장 소품 | `troy_extra.webp` | 다음 (§1) |
| 신전·분수·종탑·좌판·사자상·사다리·반 높이 성벽 (맵 개편) | `troy_city.webp` | ✅ 안내 그림판 `env_requests/city_redraw`로 받음 |
| 바다·해안·부두·배·나무 (맵 개편) | `troy_coast.webp` | ✅ 안내 그림판 `env_requests/coast_redraw`로 받음 (바다 타일은 셰이더가 대신) |

---

## 1. 트로이 추가 소품 (한 장) — 받을 이름 `troy_extra.webp`

첨부: `troy_env.webp`. Row 1이 꼭 필요한 것(지금 임시 그림), Row 2는 챕터 1 잠입 맵에 쓰는 것, Row 3·4는 있으면 좋은 것 —
결과가 복잡해지면 뒤쪽 줄을 지우고 요청한다.

```
Pixel art isometric game props sprite sheet, matching EXACTLY the style, outline, palette, lighting (from the upper left)
and pixel density of the attached reference image (isometric Greek city of Troy at night, one floor tile = 64x32 px).
Solid flat dark background #282B35. Every item separated by empty space. No text, no labels, no grid lines, no shadows on the ground.
2:1 isometric view (camera looks down about 30 degrees), no perspective.

Row 1:
- An ALARM BELL stand: two wooden posts with a crossbar, a bronze bell hanging in the middle with a rope, on a small stone base,
  about 30x58 px, standing on one floor tile.
- A wooden city-gate WINCH: a heavy horizontal wooden drum on two thick posts with a big four-spoke crank wheel on its side,
  thick rope wound on the drum, about 46x50 px, standing on one floor tile.
- A bronze BRAZIER on three legs, a shallow bowl full of glowing red-orange coals (no tall flames; flames are added by the game),
  about 30x31 px.
- A tall cloth BANNER on a wooden pole, teal-blue cloth with a white owl emblem (the Greek side), same size and shape as the
  red Trojan banner in the reference, about 32x70 px.
- One flying ARROW drawn horizontally pointing RIGHT: thin wooden shaft, bronze head, white feather fletching, about 24x5 px.

Row 2 (stealth map props, each standing on one floor tile unless noted):
- A small ARMORY STORE: a lean-to wooden shed roof over stacked spears, shields and amphorae against a wall, about 2x1 floor tiles.
- The same armory store BURNT: charred black planks, collapsed roof, glowing embers (no tall flames; flames are added by the game).
- A MARKET STALL with a striped cloth awning and baskets of fruit, about 2x1 floor tiles.
- A tall PILE OF SACKS AND CRATES that an archer can stand on, about 1 floor tile, about 60 px tall.
- A wooden POST with loose ropes on the ground around it (where a prisoner was tied).

Row 3 (optional):
- The same city gate as in the reference in 3 states side by side: closed, half open (doors swung inward a little), fully open
  (dark passage visible), each the same size as the reference gate.

Row 4 (optional, flat ground decals that lie on one floor tile, 64x32 diamond shape):
- a black scorch mark with a few glowing embers, a broken round bronze shield lying flat, a dropped spear lying on the ground,
  three arrows stuck in the ground.
```

---

## 2. 불 효과 (받음, 다시 받을 때) — 받을 이름 `troy_fire.webp`

첨부: `troy_env.webp`. 받으면 `python3 tools/gen_env_from_sheet.py .` (`FIRE_ROW`·`SMOKE_ROW`·`FIRE_K`).

```
Pixel art fire effect sprite sheet matching the style, outline and pixel density of the attached reference image
(isometric Greek city of Troy at night). Solid flat dark background #282B35, no text, no grid lines.
Row 1: LARGE roof fire loop, 8 frames, each in a 64x96 cell, flame base on the cell bottom, ragged asymmetric flame tongues,
       dark red outer edge, orange body, small yellow core (not a white blob), loopable.
Row 2: SMALL fire loop, 8 frames, each in a 32x48 cell, same style.
Row 3: SMOKE puff, 6 frames, each 48x48, dark grey-brown puff growing and fading (last frame sparse pixels).
Row 4: 6 single ember sparks (2-4px) and a charred/burnt roof-tile overlay patch about 96x48 (black-brown scorched tiles with glowing cracks).
2D pixel art, crisp 1px dark outline on flames, no anti-aliasing blur, no glow halo baked in.
```

---

## 3. 트로이 도시 건물 (한 장) — 받을 이름 `troy_city.webp`

챕터 1 맵 개편([../maps/CH1_TROY.md](../maps/CH1_TROY.md))용. 첨부 두 장:
`troy_env.webp`(화풍·크기 기준)와 `docs/references/environment/ch1_troy__city-layout.webp`(건물 모양·재질 참고만).

```
Pixel art isometric game buildings and props sprite sheet, matching EXACTLY the style, outline, palette, lighting (from the upper left)
and pixel density of the FIRST attached image (isometric Greek city of Troy at night, one floor tile = 64x32 px).
Use the SECOND attached image only as a reference for the SHAPES and MATERIALS of the buildings (light sandstone walls,
red clay roof tiles, red banners with a gold emblem); do NOT copy its sunset lighting or its painting style.
Night colors: blue-grey stone, warm orange light only where there are torches.
Solid flat dark background #282B35. Every item separated by empty space. No text, no labels, no grid lines, no shadows on the ground.
2:1 isometric view (camera looks down about 30 degrees), no perspective.

Row 1 (big landmarks):
- A Greek TEMPLE of Athena on a raised stone platform: six front columns, red tiled pediment roof, two red banners between columns,
  a wide flight of stone steps in front, footprint about 3x3 floor tiles.
- A round stone FOUNTAIN with a two-tier basin and blue water, footprint 2x2 floor tiles.
- A wooden BELL TOWER: four tall posts, a small roofed platform on top with a bronze bell, a ladder on one side,
  footprint 2x2 floor tiles, about 130 px tall.

Row 2 (props, one floor tile each unless noted):
- A seated stone LION statue on a square base (draw it once; the game mirrors it).
- A MARKET STALL with a RED and WHITE striped cloth awning, wooden counter with baskets and jars, 2x1 floor tiles.
- The same market stall with a plain RED awning.
- A wooden LADDER leaning to the right (to lean against the Trojan horse), about 70 px tall.
- A BROKEN marble COLUMN: standing lower half with a jagged top, plus the fallen drum pieces beside it.

Row 3 (wall parts, same stone and size as the wall in the first image):
- A RED cloth BANNER with a gold emblem hanging flat on a wall face, about 20x40 px, drawn for the left-facing wall face
  (the game mirrors it for the right face).
- A LOW city wall segment: the same wall as in the first image but only HALF its height, in both directions
  (running to the lower right, and running to the lower left), plus a half-height corner tower.
```

---

## 4. 트로이 해안·나무 (한 장) — 받을 이름 `troy_coast.webp`

첨부는 §3과 같다. 바닥 타일은 64×32 마름모 한 칸에 꼭 맞게, 서로 이어 붙여도 이음매가 안 보이게.

```
Pixel art isometric game tiles and props sprite sheet, matching EXACTLY the style, outline, palette, lighting
and pixel density of the FIRST attached image (isometric Greek city of Troy at night, one floor tile = 64x32 px).
Use the SECOND attached image only as a reference for the harbor, rocks, trees and ships; do NOT copy its sunset lighting.
Night colors: deep blue sea, moonlit highlights, warm orange only on torches.
Solid flat dark background #282B35. Every item separated by empty space. No text, no labels, no grid lines.
2:1 isometric view, no perspective.

Row 1 (floor tiles, each exactly one 64x32 diamond, seamless when tiled):
- 4 variants of deep night SEA water with small wave highlights.
- 4 variants of ROCKY SHORE (grey rocks with white foam on the water side).
- 4 variants of wooden DOCK planks.
- 4 variants of a round MOSAIC stone floor (pieces of one large circle pattern: center, edge, edge, plain).

Row 2 (props):
- A wooden dock POST sticking out of the water, about 12x40 px.
- A Greek GALLEY ship with one mast and a square sail with a dark horse emblem, seen from the side at the isometric angle,
  footprint about 5x2 floor tiles.
- A small rowing BOAT, footprint about 2x1 floor tiles.
- 3 sizes of grey sea ROCKS.

Row 3 (plants, each standing on one floor tile):
- A tall thin dark green CYPRESS tree about 80 px tall, an OLIVE tree with a twisted trunk about 70 px tall,
  a PINE tree about 80 px tall, a clay POT with flowers about 24 px tall, a low green BUSH.
```

---

## 5. 다음 챕터 (그때 채운다)

챕터 2부터는 `troy_env`처럼 챕터마다 기준 한 장(`<챕터>_env.webp`: 바닥 타일 + 큰 건물 + 소품)을 먼저 받아 화풍을 잡고,
그다음 소품·애니메이션을 받는다. 무엇이 필요한지는 ART_PLAN §4.7.
