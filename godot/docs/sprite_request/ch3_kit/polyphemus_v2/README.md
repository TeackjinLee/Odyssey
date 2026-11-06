# 폴리페모스 다시 그리기 (v2) — 무서운 거인

예전 거인(`../polyphemus/`)은 통통하고 귀여워 무섭지 않았고, 작은 원본을 줄였다 2배로 키워 화질이 뭉개졌다.
v2는 영화 《오디세이》(2026)처럼 무서운 쪽: 잿빛 흉터 살갗, 엉킨 검은 머리, 핏발 선 노란 외눈, 구부정한 큰 몸, 뿌리 달린 올리브 줄기 곤봉.

## 받은 것

- `results/base.png` — 기본 5방향(1536×1024, 칸 512, 위 E·SE·S / 아래 NE·N). 요청 `base/prompt.txt`, 화풍 참고 `hero_style_ref.png`.
- 게임 시트: `python3 tools/pack_polyphemus_hd.py base .` → `assets/sprites/polyphemus.*`
  (idle·idle_shut·idle_wound 세 동작 1프레임, 감은 눈·찔린 눈은 눈 타원을 칠해 만듦 — `EYES` 좌표). 움직임은 `cyclops.gd`의 `_pose`.

## 동작 그림 (2026-11-06 받음 — 51장, 게임 시트에 들어감)

동작 10종 × 5방향 + 잠 1장 = 51장(바위 밀기 push·끌기 pull 추가). 요청 글은 `jobs/<동작>_<방향>.txt`(방향마다 한 장: 6프레임은 3×2 칸 512, 4프레임은 2×2 칸 768×512).

```bash
cd godot/docs/sprite_request/ch3_kit/polyphemus_v2 && PAR=6 ./run_jobs.sh   # 이미 받은 것은 건너뜀, 첨부: base.png + ref/base_<방향>.png
# Codex가 고쳐 그려 여러 장이면 전부 results/cand/에, tools/pick_sheet.py가 투명 배경·칸 안·키로 골라 results/<동작>_<방향>.png (점수는 jobs/*.pick)
cd godot && python3 tools/pack_polyphemus_hd.py v2 .                         # → polyphemus·polyphemus_combat·polyphemus_sleep
```

| 동작 | 프레임 | 쓰는 곳 |
|---|---|---|
| idle | 4 | 지킴·킁킁 |
| walk | 6 | 순찰·쫓기·돌진 |
| roar | 4 | 알아챈 뒤 쫓기 전, 동굴을 막은 뒤 |
| club_slam · grab | 6 | 공격(맞는 순간 = 4번째 장) |
| drunk | 6 | 취해 침상으로 |
| eye_wound | 6 | 눈을 찔린 직후(곤봉 없음) |
| grope | 6 | 날뛰기·입구 지킴(곤봉 없음) |
| push · pull | 6 | 입구 바위 밀어 닫기 · 끌어 열기(곤봉 없음, 바위는 안 그림 — 걷기와 같은 배율) |
| sleep | 2×2 | 1줄 반듯이·2줄 웅크림 |

다시 받은 것: roar_NE(살빛이 초록·옆모습 → 요청 글에 살빛·45도 방향을 못 박음, 버린 것은 `results/rejected/`).
묶을 때 칸을 넘는 동작은 배율을 자동으로 줄인다(roar 0.68 → 0.65). 대기·걷기·취함·더듬기(`steady`)는 방향마다 키를 250으로 같게, 가장 낮은 발을 땅에, 몸통 가운데를 기준점에 맞춘다 — 돌아서거나 걸을 때 커졌다 작아지거나 미끄러지지 않게. 걷기는 8장 느린 걸음 `walk8_*`(4×2, 키 360, 2026-11-06 다시 받음)을 fps 5로 쓴다 — 6장 `walk_*`는 다리가 땅보다 빨라 종종걸음처럼 보여 남겨만 둠. 밀기·끌기는 6장 걷기와 같은 배율 0.66 고정. 포효(`dir_head`)는 높이 든 곤봉·팔을 빼고 잰 몸 키로 방향마다 대기 키에 맞춘다. 받은 뒤 확인: 다섯 방향이 같은 얼굴·크기인지, 외눈(눈 부상·더듬기는 검붉은 상처), 칸 경계에서 잘림(묶을 때 `issues`에 나옴 — `ch3_kit/polyphemus_hd_v2.json`).
동작 그림이 시트에 있으면 `cyclops.gd`가 코드 자세를 끄고 그림을 쓴다. 잠 그림이 생기면 `eye_pos`의 잠든 눈 위치를 화면으로 맞춘다.
