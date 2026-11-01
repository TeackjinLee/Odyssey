# ODYSSEY — 오디세우스의 귀환 (Godot 4)

호메로스 《오디세이아》를 바탕으로 한 2.5D 쿼터뷰 액션 RPG. 오디세우스를 조종하고 부하를 지휘하며
6개 챕터의 신화 속 사건을 겪는다. 기획 전체는 [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)에 있다.

현재 **CHAPTER 1 — 트로이의 목마**를 처음부터 끝까지 플레이할 수 있다.

## 실행

Godot 4.7 이상(`brew install --cask godot`). 이 폴더에서:

```bash
godot --path .                # 타이틀 화면부터
godot --path . -- --play      # 바로 챕터 1
godot -e --path .             # 에디터로 열기
```

처음 한 번은 그림을 가져오도록 `godot --headless --path . --import`를 실행해 두면 첫 실행이 빠르다.

## 조작

| 키 | 동작 |
|---|---|
| WASD | 이동 (Shift 달리기, 스태미나 소모) |
| 좌클릭 / J | 검 3연타. 공격 중에 누른 입력은 0.4초 기억했다가 다음 타로 잇는다 |
| F | 강공격 — 방패 막기를 뚫고 크게 밀어냄 (스태미나 25, 1.2초 쿨타임) |
| 우클릭 / K | 방패 막기. 막기 시작 0.2초 안에 맞으면 패링(공격자 경직) |
| Space | 구르기 (무적 0.28초, 공격 후딜을 끊을 수 있음) |
| Q | 검 ↔ 활. 활은 누르고 있다가 놓으면 발사(오래 당길수록 강함) |
| E | 대화·조사. 권양기·쓰러진 부하 일으키기는 길게 누름 |
| R | 전투의 함성 — 주변 아군 회복과 8초 공격력 증가, 가까운 적 경직 (20초) |
| 1 2 3 4 | 부대 명령: 따라오기 · 위치 사수 · 집중 공격(마우스 근처 적) · 후퇴·집결 |
| F1 / Tab | 조작법 |

조준은 마우스 방향이다. 5초 동안 맞지 않으면 체력이 조금씩 찬다.

## 챕터 1 진행

1. 목마 옆 첩자 **시논**과 대화
2. 대로의 트로이 **순찰대** 3명 처치 (전투 튜토리얼)
3. 성문 앞 광장의 **경비대** 6명 처치 — 수비대장 아게노르(보스 체력바)
4. **권양기**를 길게 돌려 성문 개방 → 아카이아 증원군 4명 입장
5. 붉은 원(성문 거점)을 **사수** — 트로이군 반격 3파, 원 안에 적이 있으면 점령 정지
6. 클리어 화면

## 구조

```
project.godot          640×360 기준, canvas_items 확대, 픽셀 필터(nearest)
scenes/main.tscn       → scripts/main.gd (타이틀·챕터 시작·재시작·검증용 인자)
scripts/
  autoload/game.gd     입력 키 등록, 히트스톱·화면 흔들림, HUD로 가는 신호, 통계
  world/
    iso.gd             격자↔화면 좌표, 8방향
    asset_library.gd   스프라이트 시트·환경 그림 읽기(.json 규칙)
    iso_level.gd       챕터 공통 틀: 타일, 막힌 칸(충돌+A*), 소품, 깊이 정렬, 가림 투명화, 조명, 카메라
    chapter1_troy.gd   챕터 1 맵·인물 배치·퀘스트 단계
    squad.gd           부대 명령과 진형(넓으면 V자, 좁으면 한 줄)
    interactable.gd    E로 쓰는 지점
  actors/
    actor.gd           공통: 체력·스태미나, 피격·방어·패링·경직, 8방향 애니메이션, 길찾기 이동
    player.gd          오디세우스 조작 (+ 검증용 자동 플레이 봇)
    companion.gd       부하 AI (검병·창병·궁병, 쓰러짐·부활)
    enemy.gd           트로이 병사 AI (검병·창병·궁수·수비대장)
    npc.gd             대화 인물
  combat/              판정(combat.gd), 화살, 이펙트(fx.gd), 합성 효과음(sfx.gd)
  ui/hud.gd            HUD 전부
assets/                생성된 임시 그림 (sprites/, env/, ui/)
tools/                 임시 그림 생성기 (Python + Pillow)
```

### 핵심 규칙

- **좌표**: 모든 위치는 화면(월드) 좌표, 인물 위치는 발 밑. 격자 칸은 64×32 마름모(2:1).
  `Iso.grid_to_world(Vector2(x, y))`로 변환한다. 격자 x는 화면 오른쪽 아래, y는 왼쪽 아래 방향.
- **깊이 정렬**: `IsoLevel.world`는 y-sort. 소품은 발자국 중심, 인물은 발 위치의 y로 앞뒤가 정해진다.
  오디세우스 앞을 가리는 건물·성벽은 반투명해진다.
- **충돌·길찾기**: 막힌 칸은 마름모 충돌 + `AStarGrid2D`. 직선으로 갈 수 있으면 곧장, 막히면 A*.
  인물끼리는 물리 충돌 대신 서로 밀어내기(좁은 길에서 끼지 않게).
- **로직과 그림 분리**: AI·판정은 스크립트, 생김새는 `assets/`의 그림과 `.json`이 전부다.

## 그림 바꾸기 (임시 → 실제 픽셀아트)

지금 그림은 `tools/`의 생성기로 만든 임시 그림이다. 같은 규칙만 지키면 코드 수정 없이 바뀐다.

- **캐릭터** `assets/sprites/<이름>.png` + `<이름>.json`
  - 한 줄 = 한 방향: 0 동(→) 1 남동 2 남(↓) 3 남서 4 서 5 북서 6 북 7 북동
  - 열 = 동작 프레임을 이어 붙임. `.json`에 동작별 `start`(시작 열)·`frames`·`fps`·`loop`
  - 동작: idle walk run attack1 attack2 attack3 heavy block bow hit dodge death interact downed
  - `frame`(한 칸 크기)과 `anchor`(발 위치)를 `.json`에 적는다. 크기는 64×64가 아니어도 된다
- **환경** `assets/env/env.json`의 `props`: 소품마다 `file`·`anchor`(발자국 중심 지점)·`footprint`(칸 수)
- **바닥** `assets/env/floor_atlas.png`: 64×32 마름모, 줄 = cobble plaza dirt grass road ash, 열 = 변형 4개

다시 생성: `python3 tools/gen_characters.py .` / `python3 tools/gen_environment.py .`

## 검증용 실행 인자

```bash
godot --headless --path . -- --auto --quit-after=170   # 봇이 챕터 1을 끝까지 진행하고 결과(JSON) 출력
godot --path . -- --start=gate --shot=/tmp/a.png --shot-at=5   # 성문 앞에서 시작, 5초 뒤 화면 저장
```

`--god`(무적), `--play`(타이틀 건너뛰기)도 있다. `REPORT`의 `step`이 4이고 `capture`가 100이면 클리어다.

## 수치 조정

- 오디세우스 공격·스태미나: `player.gd`의 `SWORD_COMBO`·`HEAVY`·`SKILL_CD`
- 부하: `companion.gd`의 `ROLES` / 트로이 병사: `enemy.gd`의 `KINDS`, 동시에 근접 공격하는 적 수 `MAX_ATTACKERS`
- 거점 점령 속도·반격 시점: `chapter1_troy.gd`의 `_update_capture()`·`_send_wave()`
