# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트

ODYSSEY — 오디세우스의 귀환. 《오디세이아》 바탕의 2.5D 쿼터뷰 픽셀아트 액션 RPG(잠입·부하 지휘 + 6챕터).
**개발 대상은 Godot 4 버전 `godot/`이다.** 루트의 `src/`·`index.html`·`public/`은 이전 웹 시제품(TypeScript + Three.js)으로
보관만 한다 — 요청이 없으면 고치지 않는다(설명은 `docs/legacy-web/`).

문서·주석·UI 문구·커밋 메시지는 한국어로 쓴다. 커밋 메시지 형식은 `feat : …`/`fix : …`/`docs : …`.
이 폴더는 자체 git 저장소다(상위 `~/study` 저장소 안에 있지만 따로 관리).

## 문서 지도

| 문서 | 내용 |
|---|---|
| `godot/README.md` | 실행·조작·챕터 1 진행·코드 구조·그림 교체 규칙(시트 `.json` 형식) — 코드 작업 전에 읽는다 |
| `godot/docs/GAME_DESIGN.md` | 6챕터 기획, 조작감 원칙, 지킬 것 |
| `godot/docs/ROADMAP.md` | 마일스톤·다음 할 일·완료 기준 |
| `godot/docs/ART_PLAN.md` | 화풍 규칙·크기 규격·전체 그림 목록(ID·상태)·요청 순서 |
| `godot/docs/sprite_request/` | 그림 요청: 오디세우스 차림(`OUTFIT.md`), 요청 키트(`motion_kit/`), 요청 묶음(`attack_requests/`·`action_requests/`), 병사·환경·UI 프롬프트 |
| `godot/docs/references/` | 사용자가 준 참고 이미지와 `INDEX.md` |
| `godot/docs/maps/` | 맵 설계(챕터 1 개편안 `CH1_TROY.md`, 배치도는 `tools/gen_map_plan.py`) |

## 명령 (godot/ 안에서)

```bash
godot --path .                                          # 타이틀부터
godot --path . -- --play                                # 바로 챕터 1
godot --headless --path . --import                      # 그림 가져오기(처음 한 번)
godot --headless --path . -- --auto --quit-after=220    # 봇이 챕터 1을 끝까지 → REPORT(JSON). step 4·capture 100이면 클리어
godot --headless --path . -- --auto=stealth --quit-after=300   # 잠입 봇, alarms 0이어야 함
godot --path . -- --showcase --anim=walk                # 무기 든 오디세우스 8방향 확인
godot --path . -- --start=gate --shot=/tmp/a.png --shot-at=5   # 화면 저장 (--start=winch도 있음)
python3 tools/gen_hero.py .                             # 오디세우스 원본 → assets/sprites/odysseus.*
python3 tools/motion_request.py <기본 시트> <인물.txt> <출력> <동작들> 1   # 이미지 요청 폴더 만들기
python3 tools/split_rows.py <받은 그림> <동작> E,SE,S .  # 여러 방향 한 장 → 방향별 파일
python3 tools/pack_strip.py . <동작> <열> <줄>          # 방향별 → 8방향 한 장
```

테스트 프레임워크는 없다. 변경 확인은 `--auto` 봇 클리어(일반·잠입)와 직접 플레이·`--shot` 화면 저장으로 한다.

## 핵심 규칙 (자세한 것은 godot/README.md)

- 기준 해상도 640×360, 정수배 확대, 픽셀 필터 nearest. 바닥 칸 64×32 마름모(2:1), 위치는 화면(월드) 좌표, 인물은 발 밑.
- 로직과 그림 분리: AI·판정은 `scripts/`, 생김새는 `assets/`의 그림 + `.json`이 전부. 그림을 바꿀 때 코드는 고치지 않는 게 원칙.
- 캐릭터 시트: 한 줄 = 한 방향(0 동 1 남동 2 남 3 남서 4 서 5 북서 6 북 7 북동), 열 = 동작 프레임. `.json`에 `frame`·`anchor`·동작별 `start`/`frames`/`fps`/`loop`.
- 그려 받은 원본은 `assets/source/`에 두고 `tools/`의 변환 스크립트로 `assets/sprites/`·`assets/env/`를 만든다. 생성물을 손으로 고치지 않는다.
- 오디세우스는 치비 새 차림(맨머리·망토 없음 몸 + 투구·망토 레이어 예정, `docs/sprite_request/OUTFIT.md`). 방향은 S SE E NE N만 받고 서쪽 셋은 뒤집는다.
- 새 챕터는 `IsoLevel`을 상속해 `build()`/`start()`를 만든다.

## 그림 작업 흐름

1. `ART_PLAN.md`에서 다음 항목(ID)을 고른다 → `sprite_request/`의 해당 요청 묶음·프롬프트를 사용자에게 준다.
2. 받은 그림을 검사(`sprite_request/README.md`) → `assets/source/`에 이름 규칙대로 저장.
3. `split_rows.py`·`pack_strip.py`·`gen_hero.py` 등 변환 → `--showcase`·`--auto`로 확인.
4. `ART_PLAN.md`의 상태를 ✅로, 끝난 작업은 `ROADMAP.md` 체크박스를 고친다.

사용자가 참고 이미지를 주면 `godot/docs/references/<분류>/`에 저장하고 `references/INDEX.md`에 한 줄 적는다.
