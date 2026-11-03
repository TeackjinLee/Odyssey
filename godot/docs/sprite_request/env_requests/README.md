# 환경 시트 요청 묶음 (Codex·직접 받기)

[../environment.md](../environment.md)의 프롬프트를 그대로 옮긴 요청 3개. 프롬프트를 고쳤으면 다시 만든다(godot 폴더에서):

```bash
python3 tools/env_request.py .
```

| 폴더 | 받을 이름 | 내용 | 첨부 |
|---|---|---|---|
| `troy_extra` | `troy_extra.webp` | 경보 종·권양기·화로·그리스 깃발·화살 + 무기고·좌판·짐더미·기둥 (environment.md §1) | `troy_env.png` |
| `troy_city` | `troy_city.webp` | 신전·분수·종탑·사자상·차양 좌판·사다리·부러진 기둥·벽 깃발·반 높이 성벽 (§3, 맵 개편) | `troy_env.png` + `city_layout.png` |
| `troy_coast` | `troy_coast.webp` | 바다·해안·부두·모자이크 타일, 배·바위·말뚝, 나무·화분 (§4, 맵 개편) | `troy_env.png` + `city_layout.png` |

`troy_env.png`는 `assets/source/troy_env.webp`(화풍 기준), `city_layout.png`는 챕터 1 참고 지도
(`docs/references/environment/ch1_troy__city-layout.webp`)를 png로 바꾼 것이다.

## 받는 법

- **Codex로 한꺼번에**: `./run.sh` → 끝나면 요청마다 생성된 그림 경로가 찍힌다.
- **직접**: 폴더의 `prompt.txt` 전체를 붙여 넣고, 표의 첨부 그림을 **순서대로**(첫째가 화풍 기준) 붙인다.
- 후보는 1장씩. 결과를 `results/<폴더 이름>.png`로 저장하고 검사표([../README.md](../README.md))를 본다 —
  배경이 단색 `#282B35`인가, 소품끼리 떨어져 있는가, 칸 크기(바닥 한 칸 64×32)가 `troy_env`와 맞는가,
  참고 지도의 금빛 조명이 따라 들어오지 않았는가.
- 괜찮으면 `assets/source/<받을 이름>`(무손실 webp)으로 저장하고 Claude에게 "잘라서 넣어 줘" — `gen_env_from_sheet.py`에 상자 좌표를 더한다.
