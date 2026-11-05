# 폴리페모스 대기·걷기 애니메이션

기본5방향을 참조해 내장 imagegen으로 제작한 동작 후보다. 대기4프레임, 걷기6프레임을 E·SE·S·NE·N 순서로 받는다. 서쪽3방향은 좌우 반전한다. 게임에는 아직 등록하지 않는다.

| 동작 | 프레임·재생 | 내용 |
|---|---|---|
| idle | 4프레임·4fps·반복 | 발을 고정하고 가슴·어깨·배가 천천히 움직이는 호흡 |
| walk | 6프레임·6fps·반복 | 좌우 지지발을 바꾸는 느린 걸음, 곤봉은 낮게 유지 |

요청은 `idle/prompt.txt`, `walk/prompt.txt`. 기준 그림은 상위 `results/polyphemus_base.png`다. 실제 원본은 요청1536×2048과 다른 크기로 나올 수 있어, 자르기 도구가 실제 폭·높이의 비례 경계를 사용한다. 격자 자체가 어긋난 그림을 자동 교정하는 기능은 아니다.

## 결과 파일

[대기 GIF](sprites/preview/idle.gif) · [걷기 GIF](sprites/preview/walk.gif) · [전체 ZIP](polyphemus_motion_sprites.zip) · [검수 기록](REVIEW.md)

- `results/idle.png`, `results/walk.png`: 최종 채택한 원본 후보.
- `sprites/directions/`: 동작별8방향 가로 띠PNG16개.
- `sprites/polyphemus.png`: 3200×2560, 열0~3대기·열4~9걷기, 행E·SE·S·SW·W·NW·N·NE.
- `sprites/polyphemus.json`: 칸320×320, 기준점159.5·292, scale1, 두 동작 반복 정보.
- `sprites/preview/idle.gif`, `walk.gif`: 다섯 원본 방향을 나란히 재생하는 미리보기. 미리보기 순서는 E·SE·S·NE·N.
- `sprites/review.json`: 원본별 셀·배율·바닥 기준·경계 검수 경고·미검증 상태.
- `polyphemus_motion_sprites.zip`: 원본·PNG·메타데이터·GIF 묶음.

다시 묶기(저장소 루트):

```bash
python3 godot/tools/pack_polyphemus_motion.py godot/docs/sprite_request/ch3_kit/polyphemus/motion/results/idle.png godot/docs/sprite_request/ch3_kit/polyphemus/motion/results/walk.png godot/docs/sprite_request/ch3_kit/polyphemus/motion/sprites
```

한 동작의 모든 방향·프레임에 공통 배율을 쓰고, 한 방향의 바닥 기준을 프레임 전체에 동일하게 적용한다. 프레임마다 크기를 맞추거나 몸 중심을 재정렬하지 않아 호흡·상하 움직임을 보존한다. 목표 몸 높이는약156px다. 걷는 속도·보폭·발 미끄러짐은 게임 배치 검수가 필요하다.

알파를 유지하고 nearest로 줄이며, GIF는 어두운 배경에 합성한다. 원본 RGB에 붉은 잔여색이 있어도 알파0이면 게임에 표시되지 않는다. 경계 검수와 잔여색 검사는 실제 알파를 고려해야 한다.

후속 요청: 두 아틀라스의 붉은/초록 테두리를 정리하는 편집과, 칸마다 인물을75%로 줄여 여백을 확보하는 편집을 요청했다. 단순 격자만으로 잘림이 해소되었다고 단정하지 않고 최종 `review.json`과 PNG를 확인한다.

## 남은 확인

- 원본 방향 간 몸 크기, SE/NE회전각, 발 접지, 루프 마지막→첫 프레임, 낮게 든 곤봉의 흔들림.
- 서쪽 반전 시 양가죽·흉터·곤봉 손의 좌우 변경. 엄격한 비대칭이 필요하면 서쪽도 별도 제작.
- 외눈·손·몸통·곤봉 기준점과 게임 이동 속도. 기본 시트의 눈 높이를 모든 걷기 프레임에 그대로 쓰지 않는다.
- 3장 AI·충돌·상호작용은 아직 없다. 대기/걷기만 있는 이 시트로 기존 다른 보스를 교체하지 않는다.

다음 동작은 곤봉 내려치기·움켜잡기이며, 이후 포효·취함·잠듦·눈 부상으로 이어간다.
