# 오디세우스 8방향 걷기 — 동영상 생성기 요청 프롬프트

## 한 동영상에 8방향 다 (먼저 이것부터)

첨부: `docs/sprite_request/video/start_8dir.png` (1920×1080, 4열×2줄 — 윗줄 S·SE·E·NE, 아랫줄 N·NW·W·SW).
화면 비율 16:9, 길이는 가장 짧게. 받은 동영상은 `assets/source/video/odysseus_walk_8dir.mp4`.
여덟 명 중 몸이 돌아가거나 칸을 벗어난 방향만 아래 방향별 프롬프트로 다시 받는다.

```
Animate the attached image exactly as it is. It shows the SAME pixel art game character (Odysseus, Greek hero with a red cape)
eight times in a 4x2 grid, each copy facing a different direction:
top row left to right: SOUTH (front view), SOUTH-EAST (front-right), EAST (right side), NORTH-EAST (back-right);
bottom row left to right: NORTH (back view), NORTH-WEST (back-left), WEST (left side), SOUTH-WEST (front-left).

- ALL EIGHT copies walk IN PLACE at the same time, in sync, like on treadmills.
- Each copy keeps exactly the facing direction it has in the image for the whole video; nobody turns or rotates.
- Each copy stays in its own spot: feet on the same ground line, never moving across the frame, never overlapping a neighbor.
- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text, no grid lines.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield. Do not add or remove characters.
```

## 방향마다 한 편씩 (한 동영상이 안 될 때)

동영상 생성기에 방향마다 한 번씩 요청한다. 시작 그림 한 장을 첨부하고 아래 프롬프트 하나를 통째로 붙여 넣는다.
받은 동영상은 `assets/source/video/odysseus_walk_<방향>.mp4`로 둔다(프레임을 뽑아 시트로 만든다).

| 방향 | 첨부할 시작 그림 |
|---|---|
| S | `docs/sprite_request/video/start_S.png` |
| SE | `docs/sprite_request/video/start_SE.png` |
| E | `docs/sprite_request/video/start_E.png` |
| NE | `docs/sprite_request/video/start_NE.png` |
| N | `docs/sprite_request/video/start_N.png` |
| NW | `docs/sprite_request/video/start_NW.png` |
| W | `docs/sprite_request/video/start_W.png` |
| SW | `docs/sprite_request/video/start_SW.png` |

- 시작 그림 다시 만들기: `python3 tools/gen_video_request.py .` (1024×1024, 마젠타 바탕, 발 높이 같음)
- 화면 비율은 1:1, 길이는 가장 짧게(2~4초). 몸 방향이 돌아가거나 카메라가 움직이면 다시 뽑는다

## S

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing SOUTH - toward the camera (front view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```

## SE

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing SOUTH-EAST - toward the bottom-right of the screen (front-right three-quarter view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```

## E

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing EAST - toward the right side of the screen (right side view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```

## NE

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing NORTH-EAST - toward the top-right of the screen (back-right three-quarter view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```

## N

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing NORTH - away from the camera (back view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```

## NW

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing NORTH-WEST - toward the top-left of the screen (back-left three-quarter view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```

## W

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing WEST - toward the left side of the screen (left side view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```

## SW

```
Animate the attached image exactly as it is: a pixel art game character (Odysseus, Greek hero with red cape) walking IN PLACE, facing SOUTH-WEST - toward the bottom-left of the screen (front-left three-quarter view).
Keep his facing direction exactly as in the image for the whole video; he never turns.

- Seamless looping walk cycle: 2 full steps (right foot, then left foot) in about 1 second, last frame flows back into the first.
- Walk in place on a treadmill: feet stay on the same ground line, the character stays centered and does not move across the frame.
- Natural relaxed walk: arms swing opposite to the legs with closed fists, slight body bob, the red cape sways gently.
- LOCKED camera: no camera movement, no zoom, no pan, no rotation, no perspective change.
- Keep the flat solid magenta background #FF00FF unchanged in every frame. No shadow, no ground, no floor, no particles, no text.
- Keep the 2D pixel art look, his face, proportions, colors and dark outline exactly like the image. No motion blur, no smoothing into 3D.
- Empty hands: no weapons, no shield.
```
