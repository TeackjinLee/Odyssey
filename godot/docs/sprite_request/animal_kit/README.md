# 동물·음식 그림 요청 (ART_PLAN `C-ANI-*`)

사람이 ChatGPT에 직접 넣는다. `index.html`을 브라우저로 열면 요청마다 붙일 그림(끌어다 놓기)·요청 글(복사 단추)·저장 이름이 있다.
요청 글·참고 그림은 `make_animal.py`가 만든다(고칠 때는 스크립트를 고치고 다시 돌린다).

```bash
python3 docs/sprite_request/animal_kit/make_animal.py   # godot/ 안에서
```

## 순서

| 동물 | 1. 기본 8방향 `<종류>_base` | 2. 걷기·달아나기 `<종류>_move` | 3. 쉬기·쓰러짐 `<종류>_idle` |
|---|---|---|---|
| 닭·염소(1장)·양(2·3장)·멧돼지·사슴(4장) | `style_ref.png` + `size_ref.png` | 받은 `_base` + `layout_move.png` | 받은 `_base` + `layout_idle.png` |

- 기본 그림을 먼저 받아 `received/<종류>_base.png`로 저장해야 2·3번에 붙일 수 있다(생김새를 맞추려고).
- 동작 그림은 6열×4줄(칸 256×256): 남동(SE)·북동(NE)만 받는다. 남서·북서는 뒤집고, 지금 `animal.gd`처럼 좌우만 바꿔도 된다.
- 음식 12가지(`food_icons`): 고기·물고기·낚시찌·무화과·보리빵·올리브·산딸기·잣·꿀·로토스 열매·양젖 치즈·죽 그릇, 4열×3줄.
- 받은 그림은 `received/<저장 이름>.png`. 검사는 `../README.md`와 같다(마젠타 배경·칸 넘침·방향).

## 받은 뒤

받은 그림은 `received/`에 두고, 원본은 `assets/source/animal_<종류>_{8dir,move,idle}.webp`로 복사한 뒤:

```bash
python3 tools/gen_animal.py . <종류>   # → assets/sprites/animal_<종류>.png/.json (줄 0 남동 · 1 북동, 동작 idle·walk·run·death)
```

`animal.gd`는 시트가 있으면 그것을 쓰고(서쪽은 좌우 뒤집기), 없으면 코드 그림. 게임 안 키는 `gen_animal.py`의 `HEIGHT`.

| 종류 | 상태 |
|---|---|
| 닭 | ✅ 받음(걷기는 두 번 받아 `chicken_move.webp`를 씀 — `chicken_move_alt.webp`는 남동·북동 구별이 약함) |
| 염소·양·멧돼지·사슴 | ⬜ |
