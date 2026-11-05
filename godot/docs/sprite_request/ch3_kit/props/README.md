# 동굴 퍼즐 소품 스프라이트

폴리페모스 동굴 [배치 시안](../../../maps/CH3_CYCLOPS_CONCEPT.md)의 핵심 상호작용 소품 12종이다. 내장 imagegen으로 생성했으며 생성 요청은 `prompt.txt`, 전체 시트는 `results/cave_puzzle_atlas.png`다. 3장 게임은 아직 미구현이므로 기존 환경에 자동 등록하지 않는다.

## 구성

| 위치 | PNG 이름 | 상태 |
|---|---|---|
| 1행 1·2열 | `wine_closed`, `wine_open` | 포도주 항아리 닫힘·열림 |
| 1행 3·4열 | `stake_cold`, `stake_hot` | 일반 말뚝·달군 말뚝 |
| 2행 1·2열 | `hearth_cold`, `hearth_lit` | 꺼진 화덕·불붙은 화덕 |
| 2행 3·4열 | `boulder_closed`, `boulder_rolled` | 봉쇄 바위·굴린 바위 |
| 3행 1·2열 | `pen_gate_closed`, `pen_gate_open` | 양 우리 문 닫힘·열림 |
| 3행 3열 | `giant_bed` | 거인 양가죽 침상 |
| 3행 4열 | `giant_club` | 거인 나무 곤봉 |

전체 시트는 1536×1024, 4열×3행, 칸 384×341이며 마지막 1px는 사용하지 않는다. 단색 배경을 지우는 방식 대신 생성 도구에 실제 투명 알파를 요청했다. 첫 결과의 배경 미세 투명도·빛 번짐을 줄이기 위한 후속 편집도 요청했다.

## 개별 PNG와 기준점

[전체 시트](results/cave_puzzle_atlas.png) · [개별 PNG 묶음](cave_puzzle_sprites.zip) · [검수 기록](REVIEW.md). ZIP은 전체 시트와 `sprites/`의 PNG 12개·메타데이터를 포함한다.

저장소 루트에서:

```bash
python3 godot/tools/split_cave_props.py godot/docs/sprite_request/ch3_kit/props/results/cave_puzzle_atlas.png godot/docs/sprite_request/ch3_kit/props/sprites
```

`sprites/`에 개별 투명 PNG와 `props.json`이 생긴다. 원본을 덮어쓰지 않고, 상태 쌍은 같은 합집합 영역으로 자르고 같은 배율·기준점을 쓴다. 픽셀 확대/축소는 nearest, 원본 알파는 유지한다. 알파 128 이상 중심부를 기준으로 경계를 검출하므로 아주 약한 잔여 반투명 픽셀과 실제 실루엣을 구분한다.

목표 폭은 항아리 26px, 말뚝 104px, 화덕 88px, 바위·문 112px, 침상 168px, 곤봉 88px다. 주인공 약 52px·거인 약 156px의 **초기 검토 규격**으로, 게임 화면에서 조정한다. 기준점은 공통 크롭의 가로 중심 기준과 바닥 끝이며 정확한 문 경첩·바위 중심·화덕 열원 좌표는 별도 상호작용 지점이다.

## 적용 전 확인

- 문 두 상태의 경첩·기둥 위치가 실제로 같은지, 바위의 크기·색이 유지되는지 확인한다. 공통 크롭은 위치 차이를 없애는 보정이 아니므로 원본 구조 차이가 있으면 재요청한다.
- `boulder_rolled`은 같은 위치에서의 회전 모습이다. 출구를 열 때는 게임에서 바위를 옆으로 이동시키고 충돌을 갱신해야 한다.
- 불붙은 화덕은 정지 한 장이다. 불·연기는 기존 이펙트를 따로 올려 애니메이션과 조명을 처리한다.
- 말뚝은 바닥 소품이다. 들고 이동·눈 찌르기는 별도의 인물 동작이 필요하다.
- 검수 후보이므로 `props.json`은 기존 `assets/env/env.json`에 합치지 않는다. 바닥 발자국·가림·플레이어 접근 거리를 챕터 3 구현 때 정한다.
