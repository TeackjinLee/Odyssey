# ODYSSEY — 오디세우스의 귀환 (Godot 4)

호메로스 《오디세이아》를 바탕으로 한 2.5D 쿼터뷰 액션 RPG. 오디세우스를 조종하고 부하를 지휘하며
6개 챕터의 신화 속 사건을 겪는다.

| 문서 | 내용 |
|---|---|
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | 게임 기획 (6챕터) |
| [docs/ROADMAP.md](docs/ROADMAP.md) | 개발 계획 — 마일스톤·다음 할 일 |
| [docs/ART_PLAN.md](docs/ART_PLAN.md) | 화풍 규칙·크기 규격·전체 그림 목록과 상태 |
| [docs/sprite_request/](docs/sprite_request/README.md) | 이미지 요청 — 오디세우스 차림·요청 키트·요청 묶음·병사/환경/UI 프롬프트 |
| [docs/references/](docs/references/README.md) | 직접 모은 참고 이미지 |
| [docs/maps/](docs/maps/CH1_TROY.md) | 맵 설계: 챕터 1 맵(개편 반영)과 배치도(`tools/gen_map_plan.py`), 챕터 2 맵·항해 모드([CH2_ISMAROS.md](docs/maps/CH2_ISMAROS.md)), 챕터 3 동굴([CH3_CYCLOPS.md](docs/maps/CH3_CYCLOPS.md)) |
| [docs/NUTRITION.md](docs/NUTRITION.md) | 영양(탄수화물·단백질·지방)·채집·사냥·낚시·배의 식량 창고 — 모든 챕터 공통 |

현재 **CHAPTER 1 — 트로이의 목마**를 처음부터 엔딩까지, **CHAPTER 2 — 귀환의 시작**(항해 모드 기반: 이스마로스 약탈과 탈출),
**CHAPTER 3 — 외눈박이 거인**(폴리페모스의 동굴: 시야 피하기·포도주·말뚝·양 밑 탈출)을 끝까지 플레이할 수 있다. 챕터 1을 깨면 결과 화면의 "다음 챕터"로 넘어가고 영양·살아남은 부하를 이어받는다.
진행은 체크포인트마다 저장되어 타이틀의 "이어 하기"로 이어서 한다.

## 실행

Godot 4.7 이상(`brew install --cask godot`). 이 폴더에서:

```bash
godot --path .                # 타이틀 화면부터
godot --path . -- --play      # 바로 챕터 1
godot --path . -- --chapter=2 # 바로 챕터 2 (챕터 1을 깬 적이 없으면 기본 영양·부하 셋)
godot --path . -- --chapter=3 # 바로 챕터 3 (--start=cave|sleep|blind|ending)
godot -e --path .             # 에디터로 열기
```

처음 한 번은 그림을 가져오도록 `godot --headless --path . --import`를 실행해 두면 첫 실행이 빠르다.

## 조작

| 키 | 동작 |
|---|---|
| WASD | 이동 (Shift 달리기, 스태미나 소모) |
| Z / 좌클릭 | 검 3연타. 공격 중에 누른 입력은 0.4초 기억했다가 다음 타로 잇는다 |
| F | 강공격 — 방패 막기를 뚫고 크게 밀어냄 (스태미나 25, 1.2초 쿨타임) |
| K / 우클릭 | 방패 막기. 막기 시작 0.2초 안에 맞으면 패링(공격자 경직) |
| Space | 구르기 (무적 0.28초, 공격 후딜을 끊을 수 있음) |
| Q | 검 ↔ 활. 활은 공격 키(Z/좌클릭)를 누르고 있다가 놓으면 발사(오래 당길수록 강함) |
| E | 대화·조사. 쓰러진 부하 일으키기·포로 풀기·불 지르기는 길게, 권양기는 누르고 있는 동안만 돈다. 적 뒤에서 조용히 처치, 횃불대 옆에서 횃불 끄기 |
| R | 전투의 함성 — 주변 아군 회복과 8초 공격력 증가, 가까운 적 경직 (20초) |
| C | 미끼 던지기 — 조준한 쪽(최대 170px)으로 돌멩이, 떨어진 곳 둘레의 보초가 살피러 간다(알아채지는 않음, 6초) |
| 1 2 3 4 | 부대 명령: 따라오기 · 위치 사수 · 집중 공격(조준한 적) · 후퇴·집결 |
| 5 | 부대 특수 명령(조준한 곳, 18초): 검병 방패벽(5초간 제자리에서 앞쪽 화살·공격을 막음) · 창병 창 던지기 · 궁병 일제 사격(원 안 화살비, 무기고를 태웠으면 불화살) |
| F1 / Tab | 조작법 |
| Esc | 일시정지 메뉴: 계속하기 · 설정(음량·전체 화면·키 바꾸기) · 체크포인트에서 다시 · 처음부터 · 타이틀로 |
| 방향키·WASD + Enter/E | 메뉴·결과 화면 버튼 고르기·누르기. 대화는 E / Space / Z / 클릭으로 넘김 |

**조준**: 마우스를 움직이거나 누르면 마우스 쪽을 노린다. Z·K·방향키를 누르면 키보드 조준으로 바뀌어,
이동 방향(서 있으면 바라보는 방향)으로 노리고 그쪽 가까운 적(검 60px·70°, 활·부대 명령 320px·40°이고 가로막히지 않은 적)에
맞춘다. 맞춘 적 발밑에 붉은 고리가 뜬다. WASD·F는 둘 다에서 쓰므로 조준 방식을 바꾸지 않는다(`player.gd`의 `KEY_AIM_KEYS` + 공격·방패 키).

**설정·키 바꾸기**: Esc → 설정(타이틀의 "설정 · 키 바꾸기"도 같은 화면). 음량은 전체·음악·효과음 세 가지(10% 단위, 오디오 버스
Master/Music/SFX), 전체 화면, 키 바꾸기(동작을 누르고 새 키, Esc 취소, "키 기본값으로"). 바꾼 키는 하단 슬롯·조작법(F1)에 그대로 보이고,
튜토리얼 안내 글은 기본 키로 적혀 있다. 위 표의 키는 기본값이다.

**공격 범위**: 공격하는 동안 바닥에 실제 판정 모양을 그린다(`player.gd`의 `draw_reach`, `Combat.melee`와 같은 계산).
검은 땅 거리 reach+5 안의 부채꼴(가로 베기·되베기 150°/27, 내려찍기 120°/31, 회전 베기(강공격 F) 220°/35, 주황) +
발밑 9px. 판정 전에는 안쪽이 차오르고 맞는 순간 번쩍인다. 활은 당기는 동안 지금 놓으면 날아갈 길(속도×1.4초, 벽에서 끊김)과
맞는 폭을 그린다. 5초 동안 맞지 않으면 체력이 조금씩 찬다.

**잠입**: 알아채기 전의 적은 바닥에 그려진 앞쪽 부채꼴로 오디세우스만 본다(진한 안쪽 = 어둠에서도 보이는 거리,
옅은 바깥 = 횃불·불빛 안에서 보이는 거리, 밝기는 `iso_level.gd`의 `light_at`). 보이면 머리 위 "?"가 차고, 다 차면 "!"와 함께
알아채 주변 150px 동료에게 알린다. 달리는 발소리·검 휘두르는 소리도 의심을 채운다. 알아채기 전에 화살을 맞으면 한 발에 쓰러진다.
꺼진 횃불을 본 적은 가서 다시 켠다. 부하는 알아챈 적에게만 먼저 덤빈다(집중 공격 명령은 예외).

## 챕터 1 진행

맵은 48×50칸(성 안 33×45 + 오른쪽 바다), 네 변이 성벽이다(화면 앞쪽 두 변은 오디세우스를 가리면 반투명).
위(북)부터 성문 광장(서쪽 나무 종탑, 동쪽 언덕의 아테나 신전) · 북쪽 가로 · 세 갈래 길(횃불 늘어선 대로, 어두운 서쪽 뒷골목,
위쪽은 불타는 구역·아래쪽은 시장인 동쪽 길 — 불빛이 밝아 빠르지만 들키기 쉽다) · 가운데 분수 광장 · 목마 광장(목마는 서쪽, 옆에 사다리).
시장 남쪽 골목 끝의 **바다 문**을 나가면 부두와 갤리선이 있다. 자세한 배치는 [docs/maps/CH1_TROY.md](docs/maps/CH1_TROY.md).

1. **튜토리얼(목마 광장)** — 화면 아래 튜토리얼 카드가 한 번에 하나씩 할 일을 알려 주고, 해내면 ✓로 바뀐다
   (해당 하단 슬롯이 깜빡임). 이동 → 첩자 **시논**에게 말 걸기 → 연습 1 졸고 있는 보초 뒤에서 E 조용히 처치
   (들키면 검 3연타 안내로 바뀜) → 연습 2 보초 옆 횃불 끄기 → 연습 3 활로 쏘기 → 시논이 세 갈래 길·골라서 하는 목표를 알려 줌.
   그 뒤로는 처음 겪는 일마다 카드: 미끼 던지기 · 의심(?) · 첫 전투(연타·막기/패링·구르기·강공격) · 부하 합류(부대 명령·집중 공격·특수 명령·함성) ·
   보스 패링 · 권양기 · 거점 사수
2. 세 갈래 중 하나로 **몰래** 북쪽 가로까지 가서, 갈래 끝의 꺼진 횃불에 불을 붙여 **신호** → 부하 셋 합류.
   들키면 경보병이 갈래마다 하나 있는 **경보 종**으로 뛰고, 치기 전에 쓰러뜨리면 그만, 울리면 주변이 모두 알아채고 성문 경비가 2명 는다
   골라서 하는 목표(미니맵의 하늘색 빈 원): 바다 문 밖 부두 끝에 묶인 **정찰병**(보초 하나가 지킴)을 풀면 부하 +1,
   뒷골목 성벽 밑(화로 불빛 안) **무기고**에 불을 지르면 마지막 반격에 궁수가 없다
3. 성문 앞 광장의 **경비대** 6명(+경보마다 2명) 처치 — 수비대장 아게노르(보스 체력바).
   1페이즈는 3연타 → 내려찍기(크게 붉게 깜빡임, 막는 순간 패링하면 2초 무방비). 체력 절반 이하면 둘레를 방패로 밀쳐낸 뒤
   뿔나팔로 검병 둘을 부르고 방패 돌진(바닥의 붉은 띠로 예고, 옆으로 피함 — 벽에 박히면 2초 무방비)을 섞는다
4. **권양기**를 E를 누르고 있는 동안만 돌려(12초) 성문 개방. 손을 떼면 다시 내려가고(초당 4%), 15%·55%에서 트로이군이
   몰려오므로(두 번째엔 궁수도) 2(위치 사수)로 부하를 곁에 세워 둔다
5. **트로이 함락** — 성문이 열리면 「아카이아 대군 입성」: 선봉 4명에 이어 대군 24명이 성문 밖에서 줄지어 들어와
   북쪽 가로·세 갈래 입구에 자리 잡고, 불이 도시로 번진다(집 10채). 붉은 원(성문 거점)을 **사수** — 원 안에 적이 있으면
   점령 정지. 트로이군은 세 갈래에서 한꺼번에 반격 4파 + 파마다 정해진 수만큼 더 몰려온다(물결):
   방패벽(F 강공격으로 부숨) → 짐더미·신전 계단 위 궁수 → 권양기 돌격병(4초 붙으면 성문이 닫혀 점령이 멈추고 5초 돌려 다시 엶) →
   **트로이 왕자 데이포보스**의 총공세(보스: 아게노르처럼 패링·뿔나팔·방패 돌진). 왕자가 살아 있으면 점령이 95%에서 멈추고,
   쓰러뜨리면 남은 트로이군이 무너진다. 2파부터 파마다 오디세우스 체력 50 회복·함성 쿨타임 초기화
6. **엔딩** — 화면이 어두워졌다 밝아지면 바다 문 밖 부두. 불타는 트로이를 뒤로 부하들과 대화 → 부두를 따라 걸어 갤리선에 오름 →
   배가 바다로 나아가고 자막 세 줄 → 「CHAPTER 2 귀환의 시작」 예고. E / Space / 클릭으로 건너뛴다(`chapter1_troy.gd`의 `_play_ending`)
7. 클리어 화면 — 시간·처치(조용히)·들킨 횟수·경보·부하가 쓰러진 횟수·체크포인트에서 다시 한 횟수·골라서 하는 목표.
   경보 0이면 칭호 「밤의 그림자」, 한 번도 안 들키면 「보이지 않는 자」. 타이틀의 챕터 이름 옆에 ✓

## 챕터 2 진행 (항해 모드 기반)

맵은 64×104칸, 거의 바다다. 위쪽(y 0~55)은 오른쪽 위가 키코네스족의 땅 **이스마로스**, 가운데 작은 섬과 암초들.
아래쪽(y 58~)은 폭풍에 밀려 닿는 **로토스 섬**. 자세한 것은 [docs/maps/CH2_ISMAROS.md](docs/maps/CH2_ISMAROS.md).

1. **항해** — 오디세우스는 갤리선을 몬다(몸은 배 위에 숨고 배가 키를 받는다). W/S 노 단계(뒤로·멈춤·천천히·힘껏 — 힘껏은
   노꾼 힘을 쓴다), A/D 키(느리면 잘 안 돎), Shift 돛(바람을 등지면 빨라지고 맞바람에 펴면 밀림). 해안·암초에 빠르게 부딪히면 선체가 상한다.
   오른쪽 위 배 칸: 선체·노 단계·노꾼 힘·돛·바람 나침반·식량 창고·부하 배부름·항해 하루. 하단 슬롯도 배 조작으로 바뀐다
2. **상륙** — 해안 표시에 배를 멈추고 E. 부하 셋(챕터 1에서 정찰병을 구했으면 넷)과 내린다
3. **약탈** — 키코네스 마을의 곡식 창고 셋을 길게 E로 턴다(창고 하나 = 식량 5몫). 양·염소·닭, 올리브·산딸기·무화과·잣.
   음식은 **길게 E = 오디세우스가 먹기, 짧게 E = 배 창고에 넣기**
4. **반격** — 마지막 창고를 털면 새벽, 해안 양쪽에서 먼저, 이어 내륙에서 두 번 키코네스족이 몰려온다(마지막엔 전사장 — 보스).
   해안의 배 앞에서 E를 4초 길게 눌러 **배를 띄운다**(맞으면 끊김 — 2 위치 사수로 부하를 곁에). 260px보다 멀리 쓰러진 부하는 두고 간다
5. **탈출** — 제우스의 북풍이 남쪽으로 세게 분다. 해안에서 떠난 키코네스 배 셋이 쫓아와 화살을 쏜다. 갑판의 궁병·창병이 맞쏘고,
   힘껏 저어 뱃머리로 들이받으면 크게 부서진다. 화면 아래쪽 먼바다(57~63, 49~55)에 닿으면 탈출
6. **폭풍** — 비·번개 속에서 32초를 버틴다. 파도는 바람 쪽에서 오니 뱃머리나 고물로 받는다(옆구리로 맞으면 선체·부하가 크게 다침,
   목표 표시를 따라가면 바람을 등진다). 노는 파도에 휩쓸려 느리고, 돛을 펴 두면 찢어진다. 버티면 여러 날 밀려 다닌다(식량 창고에서 사흘 치). 남쪽 로토스 섬 앞바다에서 깬다
7. **로토스 섬** — 북쪽 해안에 배를 대고 내리면 뒤쪽 부하 둘이 정찰을 떠나 로토스 열매를 먹고 **고향을 잊는다**(명령을 듣지 않고 앉아 있음).
   다가가 길게 E로 붙잡으면 묶인 채 따라온다. 다른 부하도 열매 곁(120px)에 5초 넘게 있으면 끌려가 먹는다 — 해안에서 2 위치 사수로 세워 두고 혼자 가는 게 정답.
   로토스 열매는 배 창고에 넣지 못하고, 오디세우스가 먹으면 16초 동안 걸음이 흐트러지고 목표 표시가 사라진다. 로토파고스(분홍빛 섬사람)는 말을 걸면 열매를 권한다
8. **출항** — 해안의 배 앞에서 길게 E(2초). 고향을 잊은 채 남은 부하는 섬에 남는다. 섬에서 멀리(22칸) 벗어나면 클리어 — 하루가 지나 부하가 창고에서 먹는다.
   이스마로스와 로토스 섬에서 부하를 하나도 잃지 않으면 칭호 「아무도 두고 오지 않은 자」

**식량 창고**: 항해 하루(배 위 50초)마다 부하가 1몫씩 먹는다. 모자라면 배부름이 줄고, 50 아래면 부하의 회복·공격력(갑판 사격 포함)이 준다.
챕터 2 체크포인트: 상륙 · 반격 시작 · 출항 · 폭풍 · 로토스 섬.

**체크포인트**: 잠입 시작(시논 대화 뒤) · 부하 합류 · 권양기 앞. 쓰러지면 "체크포인트에서 다시"로 그 단계부터 하고,
골라서 하는 목표(정찰병·무기고)와 경보로 는 경비는 그대로, 기록은 체크포인트 때 값으로 돌아간다(`chapter1_troy.gd`의 `restore_checkpoint`).

**저장**: 체크포인트가 생기거나 골라서 하는 목표를 이루면 `user://save.json`(깬 챕터·마지막 체크포인트)에 쓰고,
게임을 껐다 켜면 타이틀 맨 위 "이어 하기"로 그 자리부터 한다. 설정은 `user://settings.json`.
macOS에서 `user://`는 `~/Library/Application Support/Godot/app_userdata/ODYSSEY - 오디세우스의 귀환/`. 검증용 봇(`--auto`)은 파일을 쓰지 않는다.

## 구조

```
project.godot          640×360 기준, canvas_items 확대, 픽셀 필터(nearest)
scenes/main.tscn       → scripts/main.gd (타이틀·챕터 시작·재시작·검증용 인자)
scripts/
  autoload/game.gd     입력 키 등록, 히트스톱·화면 흔들림, HUD로 가는 신호, 통계, 설정·저장(음량 버스·전체 화면·키 바꾸기·진행)
  world/
    iso.gd             격자↔화면 좌표, 8방향
    asset_library.gd   스프라이트 시트·환경 그림 읽기(.json 규칙)
    iso_level.gd       챕터 공통 틀: 타일, 막힌 칸(충돌+A*), 소품, 깊이 정렬, 가림 투명화, 조명, 카메라
    chapter1_troy.gd   챕터 1 맵·인물 배치·퀘스트 단계·상황별 음악/환경음(_update_audio)
    chapter2_ismaros.gd 챕터 2 바다 맵·상륙/약탈/반격/승선/탈출·폭풍·로토스 섬·바다 길찾기(sea_path)·바람
    storm_fx.gd       폭풍 화면 효과(빗줄기·번개, 화면 좌표)
    sea_fx.gd         폭풍 바다 이펙트(파도머리·빗방울·거품 띠·물안개·뱃머리 물보라·뱃전 파도, 월드 좌표)
    ship.gd            배(Ship): 관성 이동·노 단계·돛·바람·키·암초 충돌·들이받기·갑판 사격·적 배 AI·봇, 임시 그림
    rations.gd         배의 식량 창고와 부하 배부름(항해 하루마다 먹음) — docs/NUTRITION.md §7
    food_source.gd     먹을 것이 있는 지점(채집·고기·낚시터) — 음식 값은 data/food.json
    lines.gd           챕터 글 읽기(Lines): data/dialogue/<챕터>.json의 대사·튜토리얼 카드·목표·알림·이름
    squad.gd           부대 명령과 진형(넓으면 V자, 좁으면 한 줄)
    interactable.gd    E로 쓰는 지점
  actors/
    actor.gd           공통: 체력·스태미나, 피격·방어·패링·경직, 8방향 애니메이션, 길찾기 이동
    player.gd          오디세우스 조작 (+ 검증용 자동 플레이 봇)
    companion.gd       부하 AI (검병·창병·궁병, 쓰러짐·부활)
    enemy.gd           트로이 병사 AI (검병·창병·궁수·수비대장)
    npc.gd             대화 인물
    nutrition.gd       영양(탄수화물·단백질·지방) 규칙·수치 — docs/NUTRITION.md
    animal.gd          사냥감(닭·염소…): 달아나고 놀라면 울고, 잡으면 고기를 남김
  combat/              판정(combat.gd), 화살, 이펙트(fx.gd — 그림 이펙트가 있으면 그림), 기술 효과(skills.gd: 미끼·일제 사격)
  audio/sfx.gd         효과음: assets/audio/sfx 파일이 있으면 파일(변형 무작위), 없으면 코드 합성. at()은 거리로 줄임
  audio/bgm.gd         배경 음악 교차 페이드·짧은 곡(승리·패배)·환경음 층
  ui/hud.gd            HUD 전부 (+ 연출용 검은 띠·자막·페이드). 틀 그림은 assets/ui/frames/를 9칸으로 늘려 그림
  ui/pause_menu.gd     일시정지 메뉴(Esc)와 설정 화면(타이틀에서도 씀)
data/food.json         음식 표(탄·단·지, 먹는 횟수, 다시 열리는 시간)
data/dialogue/common.json 모든 챕터가 같이 쓰는 글(영양 안내 등)
data/dialogue/ch2.json 챕터 2 글
data/dialogue/ch1.json 챕터 1 글 — 대사·튜토리얼 카드·목표·알림. 글 속 {동작}(예: {interact})은 지금 묶인 키로 보인다
assets/                생성된 임시 그림 (sprites/, env/, ui/) · 소리 (audio/sfx·amb·music)
tools/                 임시 그림·소리 생성기 (Python + Pillow·numpy, 소리는 ffmpeg)
```

### 글 고치기

대사·튜토리얼 카드·목표·알림은 `data/dialogue/ch1.json`에 있다(코드는 `Lines.t("tut.move")`·`Lines.say("sinon_intro")`로 읽음).
키 이름은 글에 직접 쓰지 말고 `{동작}`으로 적는다 — `{interact}` `{attack}` `{block}` `{dodge}` `{heavy}` `{switch_weapon}` `{skill}`
`{decoy}` `{run}` `{cmd_follow}`…`{cmd_special}` `{move_up}` 등(`game.gd`의 `KEYS`·`REBIND`). 키를 바꾸면 화면에 바로 바뀐 키로 보인다.
`%d`·`%s`는 코드가 넣는 수·글이니 지우지 않는다.

### 소리

바다 무늬·폭풍 이펙트: 받은 `assets/source/sea_storm`·`sea_calm`·`storm_fx.webp` → `python3 tools/gen_storm.py .` → `assets/env/sea_*.png`·`assets/fx/storm_*`
(요청 묶음 `docs/sprite_request/storm_requests/`, 칸 좌표는 그 안 `storm_fx/boxes.json`). 바다 무늬가 없으면 셰이더 줄무늬로 그린다.

모든 소리는 `tools/gen_audio.py`가 합성한다(녹음·외부 소리 없음): `python3 tools/gen_audio.py .` (`sfx`·`amb`·`music` 중 골라서도 됨, 음악은 1분쯤).
느낌은 영화 《오디세이》(2026, 루드비히 고란손 음악)처럼 — 오케스트라 없이 고대 악기(리라·아울로스·청동 징·두드린 쇠붙이),
그 소리를 일그러뜨린 신시, 말 없는 목소리·합창. 선율·화성은 이 게임용으로 새로 만든 것이다.

- 효과음 `assets/audio/sfx/<이름>.wav`(변형은 `_1`…`_n`): swing·swing_heavy·hit·hit_heavy·block·parry·bow·arrow_hit·cry·shout·death·step·
  bell·horn·gate·winch·ui·ui_ok·checkpoint·alert·takedown·torch_out·torch_on·fire_burst·stone·switch·eat·cluck·bleat·splash·oar·ram·thunder·wave
- 환경음 `assets/audio/amb/`: wind(늘) · fire(성문이 열리면 크게) · sea(동쪽 해안에 가까울수록) · battle(성문 사수 동안) · rain(챕터 2 폭풍)
- 음악 `assets/audio/music/`: theme(타이틀) · stealth(잠입) · battle(들켜 싸울 때, 권양기) · siege(성문 사수) · ending(출항) · victory · defeat
  — 들키면 전투 곡으로 바뀌고 싸움이 끝나고 6초 뒤 잠입 곡으로 돌아간다(`chapter1_troy.gd`의 `_update_audio`)
- 녹음·작곡한 소리로 바꾸려면 **같은 이름**의 `.wav`/`.ogg`를 덮어쓰면 된다(코드 수정 없음). 파일이 없으면 효과음은 코드 합성음, 음악은 조용히 넘어간다
- 크기: 효과음은 부르는 곳의 dB, 음악은 `bgm.gd`의 `MUSIC_DB`, 환경음은 `_update_audio`의 0~1 값

### 영상

타이틀에서 챕터를 고르면 `assets/video/ch<n>_intro.ogv`가 있을 때 먼저 튼다(`main.gd`의 `play_intro`, Enter·Esc·E·Space·Z·클릭으로 건너뜀).
원본 `assets/source/video/ch<n>_intro.mp4` → `python3 tools/gen_video.py .` → `.ogv`(Godot는 Theora만 재생, 변환에 Godot 무비 메이커를 쓴다 — 창이 잠깐 뜬다).
챕터 1 오프닝은 실사풍 4컷(`docs/sprite_request/TROY_INTRO_VIDEO.md`)을 이어 붙인 것. 체크포인트·다시 하기·검증 인자(`--play` 등)로 시작하면 틀지 않는다(`--intro`면 튼다).

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
- **이펙트**(있으면) `assets/fx/<이름>.png` + `<이름>.json` — 프레임을 가로로 늘어놓은 한 장.
  json `{"frame": [폭, 높이], "frames": 수, "fps": 초당, "anchor": [x, y](생략하면 가운데), "scale": 1}`.
  이름 = ART_PLAN의 `F-<이름>`: hit · block · parry(맞음·막음·패링 불꽃) · dust(구르기) · shout(함성 고리) · takedown · decoy_dust.
  없으면 지금처럼 코드로 그린다(`fx.gd`의 `anim`·`impact`)
- **병사·NPC** 그려 받은 그림: `assets/source/<시트>_8dir.webp` + 동작 줄 → `SPRITE_CHAR=<시트> SPRITE_SRC_H=320`으로
  `split_rows.py`·`pack_strip.py` → `gen_hero.py` (방법은 `docs/sprite_request/ch1_kit/README.md`)
- **환경** `assets/env/env.json`의 `props`: 소품마다 `file`·`anchor`(발자국 중심 지점)·`footprint`(칸 수)
- **바닥** `assets/env/floor_atlas.png`: 64×32 마름모, 줄 = `env.json`의 `floor_atlas.rows` 순서
  (cobble plaza dirt grass road ash + water sand planks), 열 = 변형 4개. `water`·`sand` 칸은 챕터가 막힌 칸으로 둔다

다시 생성: `python3 tools/gen_characters.py .` / `python3 tools/gen_environment.py . && python3 tools/gen_env_from_sheet.py . && python3 tools/gen_env_extra.py .`

- 맵 개편용 소품·바닥은 `tools/gen_env_extra.py`가 임시 그림을 만든 뒤, 끝에서 `gen_env_redraw.py`가 다시 그려 받은 그림
  (`assets/source/troy_city.webp`·`troy_coast.webp`, 받으면 `troy_extra.webp`도)을 잘라 같은 이름으로 덮어쓴다: temple · steps · lion · fountain · stall_red/white ·
  bell_tower · ladder · column_broken · cypress · pine · olive · bush · pot · rock · galley · boat · pier_post, 바닥 water · sand · planks.
- 챕터 2 로토스 섬·항구 소품(`lotus_*`·`harbor_*`)은 그 다음 `tools/gen_env_ch2_props.py`가 env.json에 더한다(환경을 다시 만들면 끝에 한 번 더 돌린다).
  `troy_extra`(요청 준비됨): alarm_bell · winch · brazier · banner_greek · torch_post_off · gate_open · house_a~d_burnt + 새 그림 armory · armory_burnt · sacks
  (새 그림은 env.json에 더해지기만 하므로 받으면 챕터 배치를 고친다).
  받은 그림은 안내 그림판(`docs/sprite_request/env_requests/<city|extra|coast>_redraw/guide.png`)과 같은 자리라 `boxes.json` 상자로 자르고,
  기준점은 임시 그림의 것을 물려받는다(그래서 늘 `gen_env_extra.py`부터 돌린다)
- **바다**는 칸 그림 대신 셰이더(`scripts/world/water.gdshader`)로 그린다: 월드 좌표라 이음매가 없고, 물결이 흐르고 반짝임이 깜박이며,
  뭍·성벽과 닿는 곳에 거품, 부두(planks) 앞쪽 물에 부두 옆면·그림자. 물 칸 지도는 `iso_level.gd`의 `_apply_floor`가 넣는다
  잔잔한 물은 코드(점무늬 3단 색 + 생겼다 사라지는 물비늘), 거친 물만 `sea_storm.png`. 레벨이 `soft_coast = true`(챕터 2)면 바닥 칸 전부에
  이 셰이더를 씌워 해안선·바닥 종류 경계를 마름모 대신 휜 선으로 그린다(`floor_map` = 칸별 아틀라스 줄·변형).
  모래 칸은 칸 그림 대신 이음매 없는 무늬 `assets/env/ground_sand.png`(`python3 tools/gen_ground_tex.py .`)를 월드 좌표로 깐다.
  배(`ship.gd`): 선체 16방향은 겹치지 않고 한 장씩(경계에서 `HYST`만큼 더 돌아야 바뀜), 흘수선 거품·뱃머리 물결·V자 물결(바다 흐름 따라 떠감)

- 환경은 그려 받은 한 장(`assets/source/troy_env.webp`, 어두운 단색 배경)을 `gen_env_from_sheet.py`가 잘라 덮어쓴다:
  성벽·성탑·성문(열린 문은 문짝을 어둡게)·집 4채·목마·소품·바닥 6종. 그림 위치는 스크립트의 `ITEMS`·`FLOOR_BOX`
- 불타는 집은 `<집>_burnt`(지붕 그을림, `fire_spots` = 지붕 위 불꽃 자리)에 불꽃 여러 개·연기·불티를 얹는다(`iso_level.gd`의 `add_burning_house`)
- 불꽃(8프레임)·연기(6프레임, 입자 하나가 사는 동안 한 번 돎)는 받은 불 그림 `assets/source/troy_fire.webp`을 잘라 쓴다(`FIRE_ROW`·`SMOKE_ROW`·`FIRE_K`).
  그림자·화살·권양기·화로는 아직 `gen_environment.py`의 생성 그림

### 그려 받은 오디세우스와 무기

- 원본 `assets/source/odysseus_8dir.webp`(마젠타 배경, 4×2 칸) → `python3 tools/gen_hero.py .` →
  `assets/sprites/odysseus.png`(144×144 칸 — 투구 볏·점프가 잘리지 않게 위 여유를 둠, `scale` 0.5로 그려 1280×720 창에서 원본 픽셀 1:1)
- 걷기·달리기는 그려 받은 그림(`assets/source/odysseus_{walk,run}_8dir.webp`, 줄 = 남→남동→…→남서)을 쓴다.
  걷기 12열(18fps), 달리기 12열(한 주기 = 두 걸음, 26fps). 첫 프레임 손 위치는 `gen_hero.py`의 `STRIP_HANDS`.
  둘 다 남·남동·동·북동·북을 방향마다 한 장(4×3 격자)씩 받아(`odysseus_<동작>_<방향>.webp`) `tools/pack_strip.py`가
  크기·발 기준선을 맞추고 머리를 칸 가운데 두어 묶고(걷기는 키가 1% 넘게 튀는 장면만 키를 맞추고, 달리기는 두 발이 뜬 높이를 살림),
  서쪽 셋은 좌우로 뒤집는다(손은 `STRIP_MIRROR`). 요청 프롬프트·안내 그림·예시는 다른 캐릭터용으로 `docs/sprite_request/motion_kit/`에 모아 두었다(요청 폴더는 `tools/motion_request.py`),
  붙이는 움직임 안내 그림은 `tools/walk_guide.py`(달리기는 끝에 `run`)
  걷기·달리기의 보이는 주먹은 그림 조각을 프레임마다 맞춰 따라가고(`STRIP_TRACK`), 가려진 손은 팔 흔들림으로 어림한다
- 공격 4종(attack1·2·3·heavy)도 그려 받은 8방향 한 장(`odysseus_<동작>_8dir.webp`, 열 = 프레임 수)을 쓴다.
  크기는 머리 폭을 걷기에 맞춰 줄이고, 검을 쥔 주먹은 프레임마다 `ATTACK_HANDS`, 방패 손은 `ATTACK_LEFT`.
  `.json`의 `drawn`에 든 공격은 검을 그 주먹에 붙이고 칼끝을 팔 방향(가슴 → 주먹)으로 세운다(`weapon_layer.gd`).
  어색한 방향 줄은 다른 줄을 가져다 쓴다(`STRIP_REUSE`: heavy의 동·서 = 동남, 서는 좌우 뒤집기)
- 나머지 동작은 아직 기준 포즈를 기울이고 눌렀다 펴서 만든다. 받으면 같은 방식으로 바꾼다
  (요청 묶음: `docs/sprite_request/action_requests/` — idle hit death block dodge bow interact, `motion_request.py … rest`)
- 시트 `.json`의 `hands[동작][프레임][방향]`이 오른손·왼손 위치. 원본 손 위치는 `gen_hero.py`의 `HANDS_SRC`
- 무기는 `assets/weapons/`(`weapons.json`: 그림·`grip`) — `scripts/actors/weapon_layer.gd`가 손에 붙인다.
  검은 날 끝이 위로 서게, 방패는 front·three_quarter·side·back 네 장, 활은 세워서. 임시 무기는 `tools/gen_weapons.py`
- HUD 초상화는 그려 받은 일러스트 `assets/source/odysseus_portrait.jpg`(흰 배경)에서 얼굴을 잘라 80×80으로 만든다
  (`gen_hero.py`의 `PORTRAIT_BOX`, 테두리에 이어진 흰 바탕만 투명하게). 파일이 없으면 남쪽 포즈 머리를 쓴다
- 8방향 확인: `godot --path . -- --showcase` (무기를 든 오디세우스 8명이 한 줄로 섬, `--anim=walk`처럼 동작 지정)

## 검증용 실행 인자

```bash
godot --headless --fixed-fps 60 --path . -- --auto --quit-after=420   # 봇이 챕터 1을 끝까지 진행하고 결과(JSON) 출력(들키면 싸워서 지나감)
godot --headless --fixed-fps 60 --path . -- --auto=stealth --quit-after=420   # 잠입 봇: 활·뒤 처치로 지나감, 결과의 alarms가 0이어야 함
godot --path . -- --start=gate --shot=/tmp/a.png --shot-at=5   # 성문 앞에서 시작, 5초 뒤 화면 저장 (--nohud: HUD 없이, 그림 요청 첨부용)
godot --headless --fixed-fps 60 --path . -- --start=winch --auto --quit-after=300   # 권양기 앞에서 시작해 사수까지
godot --path . -- --start=ending                                  # 바로 엔딩(부두 → 출항 → 챕터 2 예고)
godot --path . -- --intro                                         # 챕터 1 오프닝 영상부터(끝나면 챕터 1)
godot --path . -- --play --at=37,38 --god                          # 오디세우스를 그 칸에 옮겨 맵 보기
godot --path . -- --start=gate --menu=settings                    # 설정 화면을 띄운 채로(--menu=pause는 일시정지)
godot --path . -- --continue                                      # 저장된 체크포인트에서 바로 이어 하기
godot --headless --fixed-fps 60 --path . -- --auto --chapter=2 --quit-after=400   # 챕터 2 봇: 항해 → 상륙 → 약탈 → 반격 → 승선 → 탈출 → 폭풍 → 로토스 섬 → 출항
godot --path . -- --chapter=2 --start=landing                     # 챕터 2를 상륙한 뒤부터 (--start=retreat 반격, escape 출항, storm 폭풍, lotus 로토스 섬 앞바다, lotus_land 로토스 섬 상륙)
```

`--fixed-fps 60`(Godot 엔진 인자)을 주면 한 프레임을 늘 1/60초로 치고 실시간을 기다리지 않아 몇 배 빨리 끝난다.
느린 컴퓨터에서 실시간으로 돌리면 프레임이 떨어져 봇이 지는 일이 있으니 봇 검증은 이 인자로 한다.
마지막 대규모 전투에 무작위가 섞여 있으니 봇은 2~3번 돌려 본다.

`--god`(무적, 배도 안 가라앉음), `--play`(타이틀 건너뛰기)도 있다. `REPORT`의 `step`이 4이고 `capture`가 100이면 클리어, `ending`이 true면 엔딩까지 끝난 것이다.
챕터 2는 `ending`이 true면 클리어 — `hull`(선체), `rations`(창고)·`fullness`(배부름)·`day`, `crew`·`lost`(잃은 부하), `looted`, `boats`(남은 적 배),
`step`(7이면 로토스 섬 출항 뒤), `bound`(끌고 온 부하), `lotus_eaten`(오디세우스가 로토스를 먹은 횟수 — 봇은 0이어야 함)도 찍힌다.

## 수치 조정

- 오디세우스 공격·스태미나: `player.gd`의 `SWORD_COMBO`·`HEAVY`·`SKILL_CD`
- 부하: `companion.gd`의 `ROLES` / 트로이 병사: `enemy.gd`의 `KINDS`, 동시에 근접 공격하는 적 수 `MAX_ATTACKERS`
- 아게노르: `enemy.gd`의 `COMBO_WINDUP`·`OPEN_TIME`·`CHARGE_*`·`SHOVE_*`
- 거점 점령 속도·반격 시점: `chapter1_troy.gd`의 `CAPTURE_RATE`·`CAPTURE_CALM`·`_update_capture()`·`_send_wave()`
- 대군·물결: `chapter1_troy.gd`의 `ARMY_SIZE`·`ARMY_INTERVAL`·`ARMY_POSTS`, `TIDE_MIN`·`TIDE_BUDGET`·`TIDE_INTERVAL`, `WAVE_HEAL`·`PRINCE_CAP`,
  왕자 `enemy.gd`의 `KINDS["trojan_prince"]`
- 기술: 미끼 `player.gd`의 `DECOY_CD`·`DECOY_RANGE`, `skills.gd`의 `DECOY_HEAR`·`VOLLEY_*`, 반응 `enemy.gd`의 `lure()`,
  부대 특수 명령 `squad.gd`의 `SPECIAL_CD`, `companion.gd`의 `WALL_TIME`·`JAVELIN_*`
- 튜토리얼 카드: `chapter1_troy.gd`의 `_tut()`(줄에 넣기)·`_tut_once()`(한 번만)·`_tut_urgent()`(바로 띄우기)·`_watch_firsts()`, 그리는 곳 `hud.gd`의 `_draw_tutorial()`
- 권양기 시간·내려가는 빠르기: `chapter1_troy.gd`의 `WINCH_TIME`·`REOPEN_TIME`·`CLOSE_TIME`·`WINCH_DROP`
- 배: `ship.gd`의 `OAR_SPEED`·`SAIL_SPEED`·`ACCEL`·`TURN_RATE`·`TURN_FULL`·`ROW_DRAIN`·`BUMP_*`·`RAM_*`·`DECK_FIRE`, 적 배 `as_enemy_boat()`
- 챕터 2 흐름: `chapter2_ismaros.gd`의 `LAND_SPEED`·`LOOT_UNITS`·`CARRY_DIST`·`COUNTER_*`·`LAUNCH_TIME`·`REEFS`·`BOATS`, 바람 `_wind_base`·`wind_strength`
- 폭풍: `chapter2_ismaros.gd`의 `STORM_TIME`·`STORM_WIND`·`STORM_SPEED`·`SURGE_EVERY`·`SURGE_DMG`·`SURGE_CREW_DMG`·`STORM_REEFS`
- 로토스 섬: `chapter2_ismaros.gd`의 `STORM_DAYS`·`SCOUTS`·`LURE_DIST`·`LURE_TIME`·`LOTUS_TREES`·`LOTUS_EXIT_DIST`, 고향을 잊는 시간 `player.gd`의 `FORGET_TIME`
- 식량 창고: `rations.gd`의 `DAY_LEN`·`FED_GAIN`·`MISS_LOSS`·`HUNGRY`·`START_STORE`
