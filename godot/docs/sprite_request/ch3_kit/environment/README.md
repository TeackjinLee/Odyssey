# 폴리페모스 동굴 환경 스프라이트

[동굴 배치](../../../maps/CH3_CYCLOPS_CONCEPT.md)를 조립할 바닥·벽·울타리·생활 소품 후보다. 앞서 만든 [퍼즐 소품](../props/README.md)과 별도 묶음이다. 내장 imagegen으로 두 장을 생성했고, 구조물 시트에는 흰 배경을 실제 투명 배경으로 제거하는 후속 편집을 요청했다.

## 구성

| 묶음 | 내용 |
|---|---|
| 바닥 12종 | 동굴 돌바닥 4변형, 먼지 낀 바닥 4변형, 짚이 흩어진 바닥 4변형 |
| 벽 6종 | NE·NW 직선 벽, 같은 방향 균열 벽, 안쪽·바깥쪽 모서리 |
| 엄폐물 2종 | 낮은 바위, 석순 묶음 |
| 울타리 2종 | NE·NW 방향 양 우리 울타리(우리 문은 기존 퍼즐 소품) |
| 생활 소품 2종 | 치즈 선반, 우유 항아리·그릇 |

원본: `results/cave_floor.png`, `results/cave_structures.png`. 요청문: `floor/prompt.txt`, `structures/prompt.txt`. 참조는 `docs/references/environment/ch3_cyclops__cave-layout.png`다.

[바닥 원본](results/cave_floor.png) · [구조물 원본](results/cave_structures.png) · [전체 PNG ZIP](cave_environment_sprites.zip) · [검수 기록](REVIEW.md)

## 자르기

저장소 루트에서:

```bash
python3 godot/tools/split_cave_environment.py godot/docs/sprite_request/ch3_kit/environment/results/cave_floor.png godot/docs/sprite_request/ch3_kit/environment/results/cave_structures.png godot/docs/sprite_request/ch3_kit/environment/sprites
```

- `sprites/tiles/`: 64×32 바닥 PNG 12개.
- `sprites/floor_atlas.png`: 256×96, 4열×3행 바닥 아틀라스.
- `sprites/props/`: 벽·모서리·바위·석순·울타리·치즈·우유 PNG 12개.
- `sprites/environment.json`: 원본 경계·크기·기준점과 `candidate`, `seams_verified=false`, `game_registered=false` 상태.
- `cave_environment_sprites.zip`: 원본 두 장과 개별 스프라이트·메타데이터 묶음.

원본 알파를 보존하고 nearest로 줄인다. 배경색을 코드로 지우지 않는다. 불투명 중심부로 경계를 찾기 때문에 원본의 희미한 외곽 픽셀은 잘릴 수 있다. 방향 짝은 공통 크롭·크기로 출력하지만, 실제 연결점까지 자동 정렬하는 기능은 아니다.

## 적용 전 검수

1. **바닥 이음매**: 4변형을 섞어 반복 배치하고 어두운 틈·밝은 줄·반복 무늬를 확인한다. 이미지 생성만으로 완전 무봉제를 보장하지 않는다. 짚·돌·먼지 사이 전환 전용 타일은 아직 없다.
2. **벽 연결**: NE/NW·모서리를 붙여 높이·접점·발자국을 맞춘다. 전체 그림 바닥 끝을 기준으로 잡은 anchor와 그리드 벽 연결점은 다르다. 그림의 넓이를 보고 충돌 셀을 자동 추정하지 않는다.
3. **울타리**: 기존 문 스프라이트와 기둥 높이·밧줄 색·경첩 방향을 맞춘다. 새 울타리 64px 폭과 기존 문112px 폭은 검토용이므로 실제 칸 규격 확정 후 조정한다.
4. **투명도**: 원본 RGBA의 가장자리·그림자·작은 틈을 어둡고 밝은 바닥에 올려 확인한다.

3장 게임은 아직 구현 전이다. 이 후보를 `assets/env/env.json`에 자동 합치지 않고 기존 1·2장 환경도 바꾸지 않는다. 다음 인물 작업은 폴리페모스 기본 방향 시트다.
