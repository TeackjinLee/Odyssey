# 폴리페모스 곤봉 내려치기·움켜잡기

기본5방향·대기 시트를 참조해 코덱스(내장 imagegen)로 받은 공격 동작 후보다. 두 동작 모두 6프레임, E·SE·S·NE·N 다섯 줄로 받고 서쪽3방향은 좌우 반전한다. 게임에는 아직 등록하지 않았다.

| 동작 | 프레임·재생 | 내용 |
|---|---|---|
| club_slam | 6프레임·6fps·한 번 | 준비 → 뒤로 감기 → 머리 위 예고(3) → 내려침(4) → 바닥 충격(5) → 복귀 |
| grab | 6프레임·6fps·한 번 | 준비 → 왼손 당김 → 뻗기 → 완전 뻗음(4) → 주먹 쥠(5) → 끌어당김 |

요청은 `club_slam/prompt.txt`, `grab/prompt.txt`. 원본은 요청2304×2560과 달리 1190×1322로 왔다.

## 결과 파일

[곤봉 GIF](sprites/preview/club_slam.gif) · [움켜잡기 GIF](sprites/preview/grab.gif) · [전체 ZIP](polyphemus_combat_sprites.zip) · [검수 기록](REVIEW.md)

- `results/club_slam.png`, `results/grab.png`: 받은 원본.
- `sprites/directions/`: 동작별8방향 가로 띠PNG16개.
- `sprites/polyphemus_combat.png`: 3840×2560, 열0~5곤봉·열6~11움켜잡기, 행E·SE·S·SW·W·NW·N·NE.
- `sprites/polyphemus_combat.json`: 칸320×320, 기준점159.5·292, scale1(대기·걷기 시트와 같음), 두 동작 반복 없음.
- `sprites/review.json`: 원본 경계·배율·바닥 기준·미검증 항목, 추천 판정 프레임(0부터 3·4).

다시 묶기(저장소 루트):

```bash
python3 godot/tools/pack_polyphemus_combat.py godot/docs/sprite_request/ch3_kit/polyphemus/combat/results/club_slam.png godot/docs/sprite_request/ch3_kit/polyphemus/combat/results/grab.png godot/docs/sprite_request/ch3_kit/polyphemus/combat/sprites
```

원본은 인물이 균등 격자선을 넘어(첫 줄 발이 둘째 줄 칸에 걸침) 균등 분할로 자르면 이웃 칸 조각이 섞인다. 그래서 명목 격자선 ±60px 안의 빈 줄을 찾아 자르고, 빈 줄이 없으면 멈춘다. 알파128 미만의 붉은·초록 매트 잔여는 알파0으로 지운다.

배율은 각 방향 첫 준비 자세 높이를 약156px로 맞춰 정한다(머리 위 곤봉 높이로 몸이 줄지 않게). 방향별 바닥은 첫 프레임 발 높이로 고정한다.

## 남은 확인

- 곤봉 끝·손의 판정 지점(프레임 3·4), 공격 범위와 예고 시간.
- 반전된 서쪽은 곤봉 손이 왼손이 된다. 엄격한 좌우가 필요하면 서쪽도 따로 받는다.
- 3장 거인AI·충돌은 미구현이라 `assets/sprites/`에 넣지 않았다.

다음 동작은 포효·취함·잠듦·눈 부상이다.
