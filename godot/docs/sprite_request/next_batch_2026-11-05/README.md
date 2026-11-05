# 다음 스프라이트 요청 묶음 — 2026-11-05

현재 게임 파일과 최근 커밋을 확인해 중복 요청을 뺀 목록이다. 과거 맨손 `odysseus` 요청과 현재 무기 포함 `odysseus_ch1` 요청을 구분한다.

## 지금 받을 것

| 우선순위 | 요청 | 첨부 순서 | 결과 위치 | 용도 |
|---|---|---|---|---|
| 1 | [로토스 섬 소품 8개](lotus_props/prompt.txt) | `lotus_props/layout.png`, `lotus_props/style_ref.png` | `results/lotus_props.png` | 분홍색으로 물들인 올리브나무 대체 후보 |
| 2 | [항구 소품 8개](harbor_props/prompt.txt) | `harbor_props/layout.png`, `harbor_props/style_ref.png` | `results/harbor_props.png` | 그물·밧줄·계선주·물고기 바구니·화물·승선판·노 걸이 |
| 3 | [무기 포함 차림 돌 던지기 E·SE·S](armed_throw/throw_E-SE-Sa/prompt.txt) | 같은 폴더 `pose.png` | `results/throw_E-SE-Sa.png` | 미끼를 던질 때 전용 몸 동작 |
| 4 | [무기 포함 차림 돌 던지기 NE·N](armed_throw/throw_NE-Na/prompt.txt) | 같은 폴더 `pose.png` | `results/throw_NE-Na.png` | 서쪽 세 방향은 좌우 반전으로 제작 |

환경은 1536×1024, 4열×2행, 칸 384×512, 배경 `#282B35`다. `cells.json`은 이름과 자를 칸 좌표를 적은 배치 계약이며 실제 그림의 불투명 영역·발 기준점은 수령 후 따로 확인한다.
돌 던지기는 1536×1024, 4열×3행, 배경 `#FF00FF`다. NE·N 요청의 마지막 줄은 비운다. 칼을 칼집에 넣고 오른손으로만 돌을 던지며 왼팔에는 별 방패를 유지한다.

`results/`의 생성 이미지는 **검수 후보**다. 원본 크기·배경·칸 경계·비율을 확인하기 전 게임에 넣지 않는다. `manifest.json`의 상태도 `prepared`(요청 준비), `candidate`(생성됨·검수 대기), `integrated`(게임 적용·확인 완료)를 구분한다.

## 이미 받은 그림 — 다시 받지 않기

| 항목 | 증거 | 남은 작업 |
|---|---|---|
| 무기 포함 오디세우스 기본·이동·공격·나머지 동작 | `ch1_kit/README.md`, `assets/source/odysseus_ch1_*`, `assets/sprites/odysseus_ch1.json` | 필요한 경우 게임 화면에서 방향·크기 확인. 옛 맨손 23장 재요청 불필요 |
| 1장 병사 7종·시논, 2장 키코네스·로토파고스·동물 | 각 키트와 `assets/source/` | 누락·품질 문제가 관찰될 때만 해당 방향 재요청 |
| 전투·기술 이펙트 | 커밋 `0b3cf14`, `assets/fx/` | 기존 도형 대체 적용됨. 추가 중복 생성 불필요 |
| 트로이 추가 환경 | `../env_requests/results/troy_extra.png` | 받은 상태, 잘라서 기존 환경 교체·맵 검수 필요 |
| UI 아이콘 | `../skill_requests/results/ui_icons.png` | 받은 상태, `fx_layout.py cut … <출력> ui` 후 HUD 연결 필요 |
| HUD 틀 | `../skill_requests/results/frames.png` | 받은 상태, `fx_layout.py cut … <출력> frames` 후 크기·9분할·HUD 연결 검토 |
| 배 선체·바다·폭풍 | `ch2_kit/README.md`, `storm_requests/README.md` | 받은 상태, 회전·항해 체감 점검 우선 |

`ART_PLAN.md`와 `ROADMAP.md`의 오래된 맨손 항목은 현재 플레이 차림의 미수령 목록으로 사용하지 않는다. 항해복 전체 동작은 5장 시점으로 미루고, 해도 UI는 화면 기능과 규격을 먼저 정한 뒤 요청한다.

## 수령 후 작업

1. 환경 시트: 번호·선·배경·칸 침범·픽셀 밀도를 검사한다. 나무와 작은 과일의 상대 크기가 맞는지 확인한다.
2. 검수 통과본만 `assets/source/`에 무손실 원본으로 보관한다. `gen_env_redraw.py` 등 변환 도구에 이름·실제 그림 경계·기준점을 등록한다. 나무는 `chapter2_ismaros.gd`의 올리브 색 변경을 교체해야 한다.
3. 돌 던지기: `SPRITE_CHAR=odysseus_ch1`로 `split_rows.py`·`SPRITE_SRC_H=320 pack_strip.py`를 사용한다. **현재 `gen_hero.py`와 Player에는 throw 몸 애니메이션 연결이 없으므로**, 원본만 넣어 완료 처리하지 않는다. 변환 동작 등록과 `_throw_decoy()`의 재생·복귀 연결이 필요하다.
4. 적용 뒤 Godot 재가져오기·쇼케이스·1장 일반/잠입 및 2장 봇을 확인한다.

재준비: 저장소 루트에서 `python3 godot/tools/prepare_next_sprites.py`. 요청 자료만 만들며 이미지 생성 도구는 실행하지 않는다. 결과 그림이 있으면 먼저 백업하고 manifest 상태를 확인한다. 자동 생성 호출은 내장 imagegen으로 수행했다.
