# 폴리페모스 상태 동작 요청 — 취함·눈 부상·더듬기·잠듦

챕터 3에서 지금은 대기 그림을 기울이거나(취함) 눕혀(잠듦) 쓰는 자리를 채울 그림이다. 구현은 [CH3_CYCLOPS.md](../../../../maps/CH3_CYCLOPS.md),
거인 코드는 `scripts/actors/cyclops.gd`. 앞서 받은 [대기·걷기](../motion/README.md)·[곤봉·움켜잡기](../combat/README.md)와 같은 규격이다.

## 요청 네 장

| 폴더 | 동작 | 격자 | 게임에서 쓰는 곳 |
|---|---|---|---|
| `drunk/` | 취한 비틀걸음 6프레임·반복 | 6열×5행(E SE S NE N), 칸 384×512 | 포도주를 마시고 침상으로 갈 때(`Mode.DRUNK`) |
| `eye_wound/` | 눈을 찔린 반응 6프레임·한 번 | 같음 | 눈 찌르기 직후(`_blinded` 시작) |
| `grope/` | 눈 먼 채 더듬기 6프레임·반복 | 같음 | 입구로 갈 때(`Mode.BLIND`), 양 등을 더듬을 때 |
| `sleep/` | 누워 숨쉬기 4프레임·반복 | 4열×2행, 칸 576×512(1행 반듯이, 2행 옆으로 웅크림) | 침상 위(`Mode.SLEEP`), 뒤척일 때 2행 |

서쪽 세 방향은 앞서처럼 좌우 반전한다. 잠듦은 침상 방향 하나만 쓰므로 방향 줄이 없다.

## 요청하는 법

- 첨부: `../results/polyphemus_base.png`(기본 5방향). 프롬프트는 `prompt.txt` 하나를 통째로 붙인다. 한 장씩 따로 요청한다.
- Codex로 받을 때(godot/ 안에서), 예:

```bash
tools/codex_image.sh -i docs/sprite_request/ch3_kit/polyphemus/results/polyphemus_base.png "$(cat docs/sprite_request/ch3_kit/polyphemus/states/drunk/prompt.txt) Save the PNG to docs/sprite_request/ch3_kit/polyphemus/states/results/drunk.png"
```

- 받은 그림은 `results/<폴더 이름>.png`로 둔다(`drunk.png`·`eye_wound.png`·`grope.png`·`sleep.png`).

## 받은 뒤 확인

- 외눈: 취함은 반쯤 감긴 호박색 눈, 눈 부상·더듬기는 검붉은 상처(호박색 홍채가 없어야 함), 잠듦은 감긴 눈.
- 눈 부상·더듬기에는 곤봉이 없어야 하고, 취함·잠듦에는 오른손 곤봉이 남아 있어야 한다.
- 몸 크기: 서 있는 키 230px(칸 안)로 기존 시트와 같은 배율이 나오는지. 잠듦은 몸 길이 약 330px.
- 피·고어 없음, 글자(Z 등)·바닥·그림자 없음, 칸 경계를 넘는 머리카락·손끝 없음.
- 묶기는 `tools/pack_polyphemus_combat.py`처럼 빈 줄을 찾아 자르는 방식으로 새로 만들고(`pack_polyphemus_states.py`), 게임 시트 `assets/sprites/polyphemus_states.*`로 넣는다.
