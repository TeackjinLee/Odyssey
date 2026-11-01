# 오디세우스 공격 스프라이트 요청 프롬프트 (8방향 한 장)

걷기·달리기처럼 동작 하나를 8방향 한 장으로 받는다. 프롬프트 한 덩어리를 통째로 붙여 넣고 그림 두 장을 첨부한다.
공통 규칙·다른 동작은 `PROMPTS.md`.

| 동작 | 프레임 | 첨부할 배치 그림 | 받은 그림 이름 |
|---|---|---|---|
| attack1 가로 베기 | 4 | `attack8_layout_4.png` | `odysseus_attack1_8dir.png` |
| attack2 되베기 | 4 | `attack8_layout_4.png` | `odysseus_attack2_8dir.png` |
| attack3 내려찍기 | 5 | `attack8_layout_5.png` | `odysseus_attack3_8dir.png` |
| heavy 강공격(회전 베기) | 6 | `walk8_layout.png` | `odysseus_heavy_8dir.png` |

- 늘 같이 첨부: `odysseus_reference.png`
- 배치 그림 다시 만들기: `python3 tools/gen_walk_request.py . 4` (칸 수 4·5, 6은 `walk8_layout.png`)
- 4종 모두 받아 게임에 넣었다(2026-11-01). 다시 받으면 같은 이름으로 `assets/source/`에 두고 `python3 tools/gen_hero.py .`
  — 주먹 위치가 바뀌면 `gen_hero.py`의 `ATTACK_HANDS`도 고친다
- 무기는 게임이 오른손 주먹에 붙여 휘두른다 → **맨손**으로 받고, 주먹이 모든 칸에서 보여야 한다.

## attack1 가로 베기 (4프레임)

```
Pixel art ATTACK sprite sheet of the SAME character as the attached reference "odysseus_reference.png":
Odysseus, a stocky Greek hero with messy dark-brown hair and a full beard, dark bronze-trimmed muscle cuirass,
cream pleated skirt, gold bracers, bronze greaves, sandals, and a long red cape.
Keep his face, proportions, colors, outline thickness and pixel density EXACTLY like the reference.

Layout (very important) - copy the grid of the attached "attack8_layout_4.png" exactly:
- ONE image, 8 rows x 4 columns, every cell 256x256, no gaps. Whole image 1024x2048.
- Each ROW is one facing direction, top to bottom:
  1 SOUTH (front), 2 SOUTH-EAST (front-right), 3 EAST (right side), 4 NORTH-EAST (back-right),
  5 NORTH (back), 6 NORTH-WEST (back-left), 7 WEST (left side), 8 SOUTH-WEST (front-left).
- The first cell of each row in the layout shows his facing for that direction; he attacks toward that facing in the whole row.
- Each COLUMN is one frame of a fast HORIZONTAL SLASH (sword swung with the right hand), left to right:
  1 wind-up: right fist pulled back beside his right hip/shoulder, torso twisted right, weight on the back foot.
  2 swing: short step forward with the left foot, right arm sweeping forward at chest height, torso turning.
  3 follow-through: right arm fully extended across his body to his LEFT side, torso twisted left.
  4 recovery: back toward a ready stance, right fist in front of the body.

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, no labels, no text, no frame numbers.
- 2D pixel art, crisp 1px dark outline, no anti-aliasing blur, no motion blur, no slash trail or effect lines.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees), same as the reference.
- Same character size in every cell (about 200px tall), feet on the same baseline near the bottom of every cell,
  character centered in the cell (in-place animation, does not move across the cell).
- EMPTY HANDS: no sword, no shield, no bow. Right hand a closed fist as if gripping a sword hilt, clearly visible in EVERY cell
  (not hidden behind the body or cape). Left forearm held in front of the chest as if a round shield is strapped on.
```

## attack2 되베기 (4프레임)

```
Pixel art ATTACK sprite sheet of the SAME character as the attached reference "odysseus_reference.png":
Odysseus, a stocky Greek hero with messy dark-brown hair and a full beard, dark bronze-trimmed muscle cuirass,
cream pleated skirt, gold bracers, bronze greaves, sandals, and a long red cape.
Keep his face, proportions, colors, outline thickness and pixel density EXACTLY like the reference.

Layout (very important) - copy the grid of the attached "attack8_layout_4.png" exactly:
- ONE image, 8 rows x 4 columns, every cell 256x256, no gaps. Whole image 1024x2048.
- Each ROW is one facing direction, top to bottom:
  1 SOUTH (front), 2 SOUTH-EAST (front-right), 3 EAST (right side), 4 NORTH-EAST (back-right),
  5 NORTH (back), 6 NORTH-WEST (back-left), 7 WEST (left side), 8 SOUTH-WEST (front-left).
- The first cell of each row in the layout shows his facing for that direction; he attacks toward that facing in the whole row.
- Each COLUMN is one frame of a BACKHAND SLASH (the return swing after a first slash, right hand), left to right:
  1 wind-up: right fist low on his LEFT side near the left hip, torso twisted left.
  2 swing: right arm sweeping forward and upward, torso turning back to the right.
  3 follow-through: right arm extended high out to his RIGHT side at shoulder height, torso twisted right.
  4 recovery: back toward a ready stance, right fist in front of the body.

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, no labels, no text, no frame numbers.
- 2D pixel art, crisp 1px dark outline, no anti-aliasing blur, no motion blur, no slash trail or effect lines.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees), same as the reference.
- Same character size in every cell (about 200px tall), feet on the same baseline near the bottom of every cell,
  character centered in the cell (in-place animation, does not move across the cell).
- EMPTY HANDS: no sword, no shield, no bow. Right hand a closed fist as if gripping a sword hilt, clearly visible in EVERY cell
  (not hidden behind the body or cape). Left forearm held in front of the chest as if a round shield is strapped on.
```

## attack3 내려찍기 (5프레임)

```
Pixel art ATTACK sprite sheet of the SAME character as the attached reference "odysseus_reference.png":
Odysseus, a stocky Greek hero with messy dark-brown hair and a full beard, dark bronze-trimmed muscle cuirass,
cream pleated skirt, gold bracers, bronze greaves, sandals, and a long red cape.
Keep his face, proportions, colors, outline thickness and pixel density EXACTLY like the reference.

Layout (very important) - copy the grid of the attached "attack8_layout_5.png" exactly:
- ONE image, 8 rows x 5 columns, every cell 256x256, no gaps. Whole image 1280x2048.
- Each ROW is one facing direction, top to bottom:
  1 SOUTH (front), 2 SOUTH-EAST (front-right), 3 EAST (right side), 4 NORTH-EAST (back-right),
  5 NORTH (back), 6 NORTH-WEST (back-left), 7 WEST (left side), 8 SOUTH-WEST (front-left).
- The first cell of each row in the layout shows his facing for that direction; he attacks toward that facing in the whole row.
- Each COLUMN is one frame of a powerful OVERHEAD CHOP (combo finisher, right hand), left to right:
  1 rise: right fist lifting up past the shoulder, body straightening, slight lean back.
  2 peak: right fist raised high ABOVE his head, chest open, back arched, weight on the back foot.
  3 chop: big lunge forward with the left foot, right arm slamming down in front of him, torso bending forward.
  4 impact: deep crouch, right fist low in front near knee height, cape flying up behind him.
  5 recovery: rising back toward a ready stance, right fist in front of the body.

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, no labels, no text, no frame numbers.
- 2D pixel art, crisp 1px dark outline, no anti-aliasing blur, no motion blur, no slash trail, no dust or impact effects.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees), same as the reference.
- Same character size in every cell (about 200px tall when standing), feet on the same baseline near the bottom of every cell,
  character centered in the cell (in-place animation, does not move across the cell).
- EMPTY HANDS: no sword, no shield, no bow. Right hand a closed fist as if gripping a sword hilt, clearly visible in EVERY cell
  (not hidden behind the body or cape). Left forearm held in front of the chest as if a round shield is strapped on.
```

## heavy 강공격 — 회전 베기 (6프레임)

```
Pixel art HEAVY ATTACK sprite sheet of the SAME character as the attached reference "odysseus_reference.png":
Odysseus, a stocky Greek hero with messy dark-brown hair and a full beard, dark bronze-trimmed muscle cuirass,
cream pleated skirt, gold bracers, bronze greaves, sandals, and a long red cape.
Keep his face, proportions, colors, outline thickness and pixel density EXACTLY like the reference.

Layout (very important) - copy the grid of the attached "walk8_layout.png" exactly:
- ONE image, 8 rows x 6 columns, every cell 256x256, no gaps. Whole image 1536x2048.
- Each ROW is one facing direction, top to bottom:
  1 SOUTH (front), 2 SOUTH-EAST (front-right), 3 EAST (right side), 4 NORTH-EAST (back-right),
  5 NORTH (back), 6 NORTH-WEST (back-left), 7 WEST (left side), 8 SOUTH-WEST (front-left).
- The first cell of each row in the layout shows his facing for that direction; the attack starts and ends facing that direction.
- Each COLUMN is one frame of a charged SPIN SLASH (one full 360-degree turn, right hand), left to right:
  1 charge: deep crouch, right fist pulled far back behind his right hip, torso twisted right, left arm forward.
  2 coil: even lower and tighter, weight on the back foot, cape gathered.
  3 spin start: exploding out of the crouch, right arm extended straight out to the side at waist height, torso turning.
  4 mid-spin: his back turned toward the viewing direction of that row, right arm still extended straight out, cape flaring wide.
  5 spin end: facing the row direction again, right arm sweeping across in front at full extension.
  6 finish: low wide stance, right fist out to his LEFT side, cape settling.

Style rules:
- Solid flat magenta background #FF00FF everywhere. No shadow, no ground, no grid lines, no labels, no text, no frame numbers.
- 2D pixel art, crisp 1px dark outline, no anti-aliasing blur, no motion blur, no slash trail or spin effect lines.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees), same as the reference.
- Same character size in every cell (about 200px tall when standing), feet on the same baseline near the bottom of every cell,
  character centered in the cell (in-place animation, does not move across the cell).
- EMPTY HANDS: no sword, no shield, no bow. Right hand a closed fist as if gripping a sword hilt, clearly visible in EVERY cell
  (not hidden behind the body or cape). Left forearm held as if a round shield is strapped on.
```
