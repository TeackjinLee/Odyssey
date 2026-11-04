# 챕터 2 폭풍 그림 요청 묶음 (Codex·직접 받기)

폭풍 구간(`chapter2_ismaros.gd` 폭풍)이 코드로 그린 임시 화면이라 밋밋하다 — 바다는 소음 줄무늬, 비는 가는 선.
그림 넷을 받아 바꾼다. 다시 만들기: `python3 tools/storm_request.py .` (godot 폴더에서, 게임 화면 png는 덮어쓰지 않는다)

| 폴더 | 받을 이름 | 내용 | 첨부(순서대로) | 쓰는 곳 |
|---|---|---|---|---|
| `storm_mood` | `storm_mood.png` | **목표 장면** — 같은 카메라로 본 폭풍 바다(UI 없음) | `style_env.png`, `game_storm_now.png` | 색·밝기 기준. 셰이더·비·번개 색을 여기에 맞춘다 → `docs/references/mood/` |
| `sea_storm` | `sea_storm.png` | 거친 바다 **이음매 없는 무늬** 1024² | `style_env.png`, `game_storm_now.png` | `water.gdshader`가 월드 좌표로 깔고 두 겹으로 흘린다 |
| `sea_calm` | `sea_calm.png` | 잔잔한 밤바다 무늬 1024² (같은 바다) | `style_env.png`, `game_calm_now.png` | 평소 바다. 폭풍 세기(storm 0~1)에 따라 calm → storm으로 섞는다 |
| `storm_fx` | `storm_fx.png` | 폭풍 이펙트 시트(칸 자리 = `guide.png`) | `style_fx.png`, `storm_fx/guide.png` | 아래 표 |

`storm_fx` 칸(받은 그림 픽셀, 게임에서는 반 크기):

| 이름 | 프레임 | 칸 | 쓰는 곳 |
|---|---|---|---|
| `wave_crash` | 6 | 224×224 | 파도가 뱃전을 칠 때 맞은 쪽에(왼쪽에서 오는 그림, 반대쪽은 뒤집기) |
| `whitecap_a`·`_b` | 4·4 | 160×80 | 카메라 둘레 바다에 흩어져 부서지는 파도머리 |
| `bow_spray` | 4 | 192×112 | 배가 빠를 때 뱃머리 물보라 |
| `rain_splash` | 6 | 64×32 | 빗방울이 바다에 떨어지는 자리 |
| `lightning` | 3종 | 160×416 | 번개 칠 때 화면 위쪽 아무 데나(지금은 화면 번쩍임만) |
| `foam_streak` | 2종 | 384×96 | 바람 방향으로 흘러가는 거품 띠 |
| `spray_drift` | 4 | 192×96 | 바람에 날리는 물안개 |
| `rain_streak` | 6종 | 32×128 | 지금의 선 빗줄기를 바꾼다 |

> ✅ 넷 다 받아 넣음 — 원본 `assets/source/sea_storm`·`sea_calm`·`storm_fx.webp`, 목표 장면 `docs/references/mood/ch2_storm__target.webp`, 변환 `python3 tools/gen_storm.py .`

## 받는 법

- **Codex로 한꺼번에**: `./run.sh` (하나만: `./run.sh sea_storm`) → 끝나면 요청마다 생성된 그림 경로가 찍힌다.
- **직접**: 폴더의 `prompt.txt` 전체를 붙여 넣고, 표의 첨부를 **순서대로** 붙인다. `guide_labeled.png`(이름표 판)는 **붙이지 않는다**.
- 후보는 1장씩. 마음에 드는 것을 표의 "받을 이름"으로 `assets/source/`에 넣고 Claude에게 "폭풍 그림 넣어 줘".

## 검사

- `storm_mood`: 카메라가 게임과 같은가(수평선·하늘이 없고 위에서 비스듬히), UI·글자가 없는가, 배·부서지는 파도가 어두운 바다에서 보이는가.
- `sea_*`: 2×2로 이어 붙여 봐서 이음매가 보이지 않는가(조금 보이면 Claude가 고친다), 한쪽만 밝거나 어둡지 않은가, 물건이 없는가.
  둘이 같은 바다처럼 보이는가(색 계열·점 크기).
- `storm_fx`: `guide.png`와 겹쳐서 칸 안에 들어오는가, 배경이 단색 `#282B35`인가, 칸끼리 넘치지 않는가, 배를 그려 넣지 않았는가.
