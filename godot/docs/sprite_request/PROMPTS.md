# 오디세우스 스프라이트 요청 프롬프트

이미지 생성기(코덱스 등)에 붙여 넣을 프롬프트. 매번 **[공통]**을 먼저 붙이고 그 아래 **[동작]** 한 줄을 붙인다.
참고 그림 두 장을 같이 첨부한다.

- `odysseus_reference.png` — 8방향 기준 모습(방향 이름 표시)
- `layout_example.png` — 프레임 배치 예시(256×256 칸, 발은 같은 기준선)

## 순서 (중요한 것부터)

한 번에 **한 동작 × 한 방향**(가로 한 줄)씩 받는다. 방향은 S·SE·E·NE·N 다섯만 받고
SW·W·NW는 게임에서 좌우를 뒤집어 쓴다. 무기는 따로 붙이므로 **맨손(쥔 주먹)**으로 그린다.

| 순서 | 동작 | 프레임 | 방향 |
|---|---|---|---|
| 1 | walk 걷기 | 6 | S SE E NE N |
| 2 | run 달리기 | 6 | S SE E NE N |
| 3 | attack1 가로 베기 | 4 | S SE E NE N |
| 4 | attack2 되베기 | 4 | S SE E NE N |
| 5 | attack3 내려찍기 | 5 | S SE E NE N |
| 6 | idle 숨쉬기 | 4 | S SE E NE N |
| 7 | block 방패 막기 | 2 | S SE E NE N |
| 8 | dodge 구르기 | 4 | S SE E NE N |
| 9 | hit 피격 | 2 | S SE E NE N |
| 10 | heavy 강공격 | 6 | S SE E NE N |
| 11 | bow 활 당기기 | 4 | S SE E NE N |
| 12 | death 쓰러짐 | 5 | S SE E NE N |
| 13 | interact 상호작용 | 4 | S SE E NE N |

받은 그림 파일 이름: `odysseus_<동작>_<방향>.png` (예: `odysseus_walk_SE.png`)

## [공통] — 매번 먼저 붙이기

```
Pixel art game sprite sheet of the SAME character as the attached reference image "odysseus_reference.png":
Odysseus, a stocky Greek hero with messy dark-brown hair and a full beard, dark bronze-trimmed muscle cuirass,
cream pleated skirt, gold bracers, bronze greaves, sandals, and a long red cape.
Keep his face, proportions, colors, outline thickness and pixel density EXACTLY like the reference.

Format rules (very important):
- One horizontal strip, frames left to right, laid out like the attached "layout_example.png".
- Every frame is a 256x256 cell, same size, same character scale (about 200px tall when standing).
- Feet always on the same baseline near the bottom of the cell; the character stays centered in the cell
  (in-place animation, no moving across the cell).
- Solid flat magenta background #FF00FF. No shadow, no ground, no grid lines, no text, no frame numbers.
- 2D pixel art, crisp 1px dark outline, no anti-aliasing blur, no motion blur.
- Isometric 3/4 top-down game view (camera looks down about 30 degrees), same as the reference.
- EMPTY HANDS: no sword, no shield, no bow. Right hand is a closed fist as if gripping a sword hilt,
  left forearm held as if a round shield is strapped to it. Hands must stay clearly visible.
```

## [동작] — 하나만 골라 [공통] 아래에 붙이기

방향 단어(`SOUTH (front)` 부분)를 바꿔 다섯 번 요청한다.
`SOUTH (front)` / `SOUTH-EAST (front-right)` / `EAST (right side)` / `NORTH-EAST (back-right)` / `NORTH (back)`

```
Animation: WALK cycle, 6 frames, facing SOUTH (front). Natural relaxed walk, arms swing opposite to legs, cape sways.
```
```
Animation: RUN cycle, 6 frames, facing SOUTH (front). Fast heroic run, body leaning forward, big arm swing, cape flowing behind.
```
```
Animation: ATTACK 1 horizontal sword slash, 4 frames, facing SOUTH (front). Frame 1 right fist pulled back to the right side (wind-up), frame 2-3 right arm sweeps across the body to the left with a step forward, frame 4 recovery.
```
```
Animation: ATTACK 2 backhand slash, 4 frames, facing SOUTH (front). Frame 1 right fist starts low on the left side, frame 2-3 right arm sweeps up and out to the right, frame 4 recovery.
```
```
Animation: ATTACK 3 overhead chop, 5 frames, facing SOUTH (front). Frame 1-2 right fist raised high above the head, frame 3-4 arm chops down hard in front with a lunge and crouch, frame 5 recovery.
```
```
Animation: IDLE breathing, 4 frames, facing SOUTH (front). Ready stance, subtle chest rise and fall, cape barely moving.
```
```
Animation: BLOCK, 2 frames, facing SOUTH (front). Left forearm raised in front of the chest as if holding up a round shield, knees bent, braced; frame 2 slight push.
```
```
Animation: DODGE ROLL, 4 frames, facing SOUTH (front). Quick forward roll: crouch, tuck and roll, come back up to a crouch.
```
```
Animation: HIT reaction, 2 frames, facing SOUTH (front). Flinch backwards, head snapped back, arms out; frame 2 recovering.
```
```
Animation: HEAVY ATTACK spin slash, 6 frames, facing SOUTH (front). Deep wind-up crouch with right fist far back, explosive full-body spin with the right arm extended, finish low.
```
```
Animation: BOW DRAW and shoot, 4 frames, facing SOUTH (front). Frame 1 left arm raised forward as if holding a bow, frame 2-3 right hand pulls a string back to the cheek, frame 4 release with the right hand opening backward.
```
```
Animation: DEATH, 5 frames, facing SOUTH (front). Staggers, drops to the knees, falls backward and lies flat on the ground (last frame lying still).
```
```
Animation: INTERACT turning a winch, 4 frames, facing SOUTH (front). Both hands forward at waist height turning a crank in a circle.
```

## 무기 (따로 요청)

```
Pixel art game item sprites matching the style, outline and pixel density of the attached reference "odysseus_reference.png"
(item sizes relative to a 370px tall character). Solid flat magenta background #FF00FF, no shadow, no text, each item separated with space.
1) Greek bronze leaf-blade sword (xiphos), standing perfectly vertical, tip pointing UP, about 150px long.
2) Round Greek bronze shield (aspis) about 130px across, in 4 views side by side: front face; three-quarter view turned so the face looks to the right;
   edge-on side view; back side showing the wooden inside and arm strap.
3) Greek recurve bow, standing vertical, string on the left, about 170px tall, plus the same bow fully drawn.
```
