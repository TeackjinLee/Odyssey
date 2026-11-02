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
| E | 대화·조사. 쓰러진 부하 일으키기·포로 풀기·불 지르기는 길게, 권양기는 누르고 있는 동안만 돈다. 적 뒤에서 조용히 처치, 횃불대 옆에서 횃불 끄기 |
| R | 전투의 함성 — 주변 아군 회복과 8초 공격력 증가, 가까운 적 경직 (20초) |
| 1 2 3 4 | 부대 명령: 따라오기 · 위치 사수 · 집중 공격(마우스 근처 적) · 후퇴·집결 |
| F1 / Tab | 조작법 |

조준은 마우스 방향이다. 5초 동안 맞지 않으면 체력이 조금씩 찬다.

**잠입**: 알아채기 전의 적은 바닥에 그려진 앞쪽 부채꼴로 오디세우스만 본다(진한 안쪽 = 어둠에서도 보이는 거리,
옅은 바깥 = 횃불·불빛 안에서 보이는 거리, 밝기는 `iso_level.gd`의 `light_at`). 보이면 머리 위 "?"가 차고, 다 차면 "!"와 함께
알아채 주변 150px 동료에게 알린다. 달리는 발소리·검 휘두르는 소리도 의심을 채운다. 알아채기 전에 화살을 맞으면 한 발에 쓰러진다.
꺼진 횃불을 본 적은 가서 다시 켠다. 부하는 알아챈 적에게만 먼저 덤빈다(집중 공격 명령은 예외).

## 챕터 1 진행

맵은 35×50칸, 위(북)부터 성문 광장 · 북쪽 가로 · 세 갈래 길(횃불 늘어선 대로, 어두운 서쪽 뒷골목, 짐더미 쌓인 동쪽 시장) · 목마 광장.

1. 목마 옆 첩자 **시논**과 대화 — 오디세우스 혼자 나와 잠입 규칙을 듣는다(부하는 목마 안에 대기)
2. 세 갈래 중 하나로 **몰래** 북쪽 가로까지 가서, 갈래 끝의 꺼진 횃불에 불을 붙여 **신호** → 부하 셋 합류.
   들키면 경보병이 갈래마다 하나 있는 **경보 종**으로 뛰고, 치기 전에 쓰러뜨리면 그만, 울리면 주변이 모두 알아채고 성문 경비가 2명 는다
3. 성문 앞 광장의 **경비대** 6명(+경보마다 2명) 처치 — 수비대장 아게노르(보스 체력바).
   1페이즈는 3연타 → 내려찍기(크게 붉게 깜빡임, 막는 순간 패링하면 2초 무방비). 체력 절반 이하면 뿔나팔로 검병 둘을 부르고
   방패 돌진(바닥의 붉은 띠로 예고, 옆으로 피함 — 벽에 박히면 2초 무방비)을 섞는다
4. **권양기**를 E를 누르고 있는 동안만 돌려(12초) 성문 개방. 손을 떼면 다시 내려가고(초당 4%), 15%·55%에서 트로이군이
   몰려오므로 2(위치 사수)로 부하를 곁에 세워 둔다 → 아카이아 증원군 4명 입장
5. 붉은 원(성문 거점)을 **사수** — 원 안에 적이 있으면 점령 정지. 반격 3파:
   방패벽(정면은 늘 막음, F 강공격에 방패가 부서짐) → 짐더미 위 궁수(제자리에서 멀리 쏨) →
   권양기 돌격병(권양기 앞에 4초 붙어 있으면 성문이 닫혀 점령이 멈추고, 5초 돌려 다시 열어야 함)
6. 클리어 화면 — 시간·처치(조용히)·들킨 횟수·경보·부하가 쓰러진 횟수·체크포인트에서 다시 한 횟수·골라서 하는 목표.
   경보 0이면 칭호 「밤의 그림자」, 한 번도 안 들키면 「보이지 않는 자」

**체크포인트**: 잠입 시작(시논 대화 뒤) · 부하 합류 · 권양기 앞. 쓰러지면 "체크포인트에서 다시"로 그 단계부터 하고,
골라서 하는 목표(정찰병·무기고)와 경보로 는 경비는 그대로, 기록은 체크포인트 때 값으로 돌아간다(`chapter1_troy.gd`의 `restore_checkpoint`).

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

다시 생성: `python3 tools/gen_characters.py .` / `python3 tools/gen_environment.py . && python3 tools/gen_env_from_sheet.py .`

- 환경은 그려 받은 한 장(`assets/source/troy_env.webp`, 어두운 단색 배경)을 `gen_env_from_sheet.py`가 잘라 덮어쓴다:
  성벽·성탑·성문(열린 문은 문짝을 어둡게)·집 4채·목마·소품·바닥 6종. 그림 위치는 스크립트의 `ITEMS`·`FLOOR_BOX`
- 불타는 집은 `<집>_burnt`(지붕 그을림, `fire_spots` = 지붕 위 불꽃 자리)에 불꽃 여러 개·연기·불티를 얹는다(`iso_level.gd`의 `add_burning_house`)
- 불꽃(8프레임)·연기(6프레임, 입자 하나가 사는 동안 한 번 돎)는 받은 불 그림 `assets/source/troy_fire.webp`을 잘라 쓴다(`FIRE_ROW`·`SMOKE_ROW`·`FIRE_K`).
  그림자·화살·권양기·화로는 아직 `gen_environment.py`의 생성 그림

### 그려 받은 오디세우스와 무기

- 원본 `assets/source/odysseus_8dir.webp`(마젠타 배경, 4×2 칸) → `python3 tools/gen_hero.py .` →
  `assets/sprites/odysseus.png`(128×128 칸, `scale` 0.5로 그려 1280×720 창에서 원본 픽셀 1:1)
- 걷기·달리기는 그려 받은 그림(`assets/source/odysseus_{walk,run}_8dir.webp`, 줄 = 남→남동→…→남서)을 쓴다.
  걷기 6열, 달리기 12열(한 주기 = 두 걸음, 26fps). 첫 프레임 손 위치는 `gen_hero.py`의 `STRIP_HANDS`.
  달리기의 보이는 주먹은 그림 조각을 프레임마다 맞춰 따라가고(`STRIP_TRACK`), 가려진 손과 걷기는 팔 흔들림으로 어림한다
- 공격 4종(attack1·2·3·heavy)도 그려 받은 8방향 한 장(`odysseus_<동작>_8dir.webp`, 열 = 프레임 수)을 쓴다.
  크기는 머리 폭을 걷기에 맞춰 줄이고, 검을 쥔 주먹은 프레임마다 `ATTACK_HANDS`, 방패 손은 `ATTACK_LEFT`.
  `.json`의 `drawn`에 든 공격은 검을 그 주먹에 붙이고 칼끝을 팔 방향(가슴 → 주먹)으로 세운다(`weapon_layer.gd`).
  어색한 방향 줄은 다른 줄을 가져다 쓴다(`STRIP_REUSE`: heavy의 동·서 = 동남, 서는 좌우 뒤집기)
- 나머지 동작은 아직 기준 포즈를 기울이고 눌렀다 펴서 만든다. 받으면 같은 방식으로 바꾼다
  (요청 프롬프트·참고 그림: `docs/sprite_request/`)
- 시트 `.json`의 `hands[동작][프레임][방향]`이 오른손·왼손 위치. 원본 손 위치는 `gen_hero.py`의 `HANDS_SRC`
- 무기는 `assets/weapons/`(`weapons.json`: 그림·`grip`) — `scripts/actors/weapon_layer.gd`가 손에 붙인다.
  검은 날 끝이 위로 서게, 방패는 front·three_quarter·side·back 네 장, 활은 세워서. 임시 무기는 `tools/gen_weapons.py`
- HUD 초상화는 그려 받은 일러스트 `assets/source/odysseus_portrait.jpg`(흰 배경)에서 얼굴을 잘라 80×80으로 만든다
  (`gen_hero.py`의 `PORTRAIT_BOX`, 테두리에 이어진 흰 바탕만 투명하게). 파일이 없으면 남쪽 포즈 머리를 쓴다
- 8방향 확인: `godot --path . -- --showcase` (무기를 든 오디세우스 8명이 한 줄로 섬, `--anim=walk`처럼 동작 지정)

## 검증용 실행 인자

```bash
godot --headless --path . -- --auto --quit-after=220   # 봇이 챕터 1을 끝까지 진행하고 결과(JSON) 출력(들키면 싸워서 지나감)
godot --headless --path . -- --auto=stealth --quit-after=300   # 잠입 봇: 활·뒤 처치로 지나감, 결과의 alarms가 0이어야 함
godot --path . -- --start=gate --shot=/tmp/a.png --shot-at=5   # 성문 앞에서 시작, 5초 뒤 화면 저장
godot --headless --path . -- --start=winch --auto --quit-after=150   # 권양기 앞에서 시작해 사수까지
```

`--god`(무적), `--play`(타이틀 건너뛰기)도 있다. `REPORT`의 `step`이 4이고 `capture`가 100이면 클리어다.

## 수치 조정

- 오디세우스 공격·스태미나: `player.gd`의 `SWORD_COMBO`·`HEAVY`·`SKILL_CD`
- 부하: `companion.gd`의 `ROLES` / 트로이 병사: `enemy.gd`의 `KINDS`, 동시에 근접 공격하는 적 수 `MAX_ATTACKERS`
- 아게노르: `enemy.gd`의 `COMBO_WINDUP`·`OPEN_TIME`·`CHARGE_*`
- 거점 점령 속도·반격 시점: `chapter1_troy.gd`의 `_update_capture()`·`_send_wave()`
- 권양기 시간·내려가는 빠르기: `chapter1_troy.gd`의 `WINCH_TIME`·`REOPEN_TIME`·`CLOSE_TIME`·`WINCH_DROP`
