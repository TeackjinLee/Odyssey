# ODYSSEY 아트 계획

게임에 들어가는 모든 그림의 규칙·크기·목록·진행 상태. 그림을 요청하거나 바꾸기 전에 본다.
요청 방법은 [sprite_request/](sprite_request/README.md), 오디세우스 차림 결정은 [sprite_request/OUTFIT.md](sprite_request/OUTFIT.md),
직접 모은 참고 이미지는 [references/](references/README.md), 시트 `.json` 형식은 [../README.md](../README.md) §그림 바꾸기.

---

## 1. 화풍 규칙 (모든 그림 공통)

### 1.1 그리는 법

- 2D 픽셀아트, 2:1 아이소메트릭(위에서 약 30° 내려다봄), 원근 없음
- **인물은 치비(약 3등신)**: 큰 머리, 짧고 굵은 팔다리, 큰 주먹·발. 기준은 `assets/source/odysseus_8dir.webp`(2026-11-03 새 차림)
- 환경 기준은 `assets/source/troy_env.webp` — 건물·소품은 치비가 아닌 보통 비율
- 1px 어두운 외곽선, 단단한 픽셀 덩어리. 안티에일리어싱 흐림·부드러운 그러데이션·모션 블러·속도선 없음
- 빛은 왼쪽 위에서 (지금 받은 그림 기준). 그림자는 **그리지 않는다** — 게임이 발밑에 `shadow.png`를 깐다
- 배경: 캐릭터·무기·UI = 마젠타 단색 `#FF00FF` / 환경·이펙트 = 어두운 단색 `#282B35` (변환 스크립트가 지운다)
- 그림 안에 글자·격자·번호·서명 없음
- 인물 방향은 S SE E NE N 다섯만 받고 서쪽 셋(W NW SW)은 좌우로 뒤집는다
- 무기
  - **오디세우스**: 맨손(쥔 주먹)으로 그린다. 검·방패·활은 게임이 손 위치에 붙인다(`weapon_layer.gd`). 투구·망토도 따로 겹친다(OUTFIT.md)
  - **병사·NPC·보스**: 무기를 그림에 같이 그린다(무기 레이어 없음)

### 1.2 색

| 용도 | 색 | 메모 |
|---|---|---|
| 공통 하이라이트 | 청동·금 `#d4a853` ~ `#fbbf24` | 갑옷·장식 |
| 공통 그림자 톤 | 청록 `#0d2b36` ~ `#134e4a` | 어두운 면을 검정 대신 청록 쪽으로 |
| 오디세우스 포인트 | 진홍 (천 앞자락·망토) | 어떤 옷이든 하나 이상 남긴다(OUTFIT.md). **다른 인물에게 넓은 붉은 면적 금지** |
| 그리스 편(부하) | 청록 망토·청록 방패 + 흰 볏 | §1.3 제안 |
| 트로이 편(적) | 짙은 자주(보라) + 금 장식 | §1.3 제안. 트로이 깃발 소품은 이미 붉은색인데 소품이라 괜찮다 |

챕터별 분위기 색

| 챕터 | 분위기 | 주조색 | 강조색 |
|---|---|---|---|
| 1 트로이 | 불타는 밤, 빛과 그림자 잠입 | 남색·회청 돌 | 주황 불빛 |
| 2 에게해 | 맑은 낮 바다 | 하늘색·모래색 | 흰 돛 |
| 3 동굴 | 습한 어둠 | 회갈 바위 | 횃불 주황, 거인의 눈 금색 |
| 4 키르케 | 마법의 숲 | 짙은 초록 | 보라 마법빛 |
| 5 세이렌 | 안개 바다 | 회청·은 | 세이렌 청자색 |
| 6 이타카 | 새벽 궁전 | 대리석 흰색 | 금·살구색 아침 햇살 |

### 1.3 팀 구분 제안 (확정 전)

부하와 적이 섞여 싸우고, 잠입 중엔 어두운 곳에서 봐야 하므로 실루엣과 색으로 바로 구분돼야 한다.

| | 그리스 (부하) | 트로이 (적) |
|---|---|---|
| 투구 | 코린트식 청동 투구 + 짧은 **흰** 말총 볏 | 앞으로 굽은 높은 볏 청동 투구 + **자주** 볏 |
| 몸 | 아마포+청동 흉갑, 청록 짧은 망토 | 청동 비늘 갑옷, 자주 튜닉·망토, 금 테두리 |
| 방패 | 둥근 방패, 청록 바탕 + 흰 올빼미 문양(아테나) | 초승달 모양 버들가지 방패(펠타), 청동 테 |
| 궁수 | 머리띠, 가죽 조끼, 등에 화살통 | 부드러운 프리기아 모자, 무늬 바지, 허리 화살통 |

---

## 2. 크기 규격

비교표: [sprite_request/layouts/scale_chart.png](sprite_request/layouts/scale_chart.png) (`python3 tools/gen_request_layout.py . scale`)

| 대상 | 게임 안 크기 (640×360 논리 px) | 요청할 때 | 변환 후 시트 |
|---|---|---|---|
| 바닥 칸 | 64×32 마름모 | 환경 시트에 1:1 | `floor_atlas.png` 줄 6종 × 변형 4 |
| 오디세우스 | 키 52 | 기본 8방향: 칸 384×512, 키 약 340 / 동작: 칸 384×341 안팎, 키 약 290 | 칸 128, `scale` 0.5 |
| 병사·NPC | 키 약 48 | 기본: 키 약 320 / 동작: 키 약 270 | 칸 128, `scale` 0.5 (오디세우스와 같은 규칙) |
| 수비대장 아게노르 | 키 약 56 | 기본: 키 약 370 | 칸 128, `scale` 0.5 |
| 거대 보스(폴리페모스) | 키 약 150 | 따로 정함 | 따로 정함 |
| 성벽·성탑 | 65×88 / 65×118 | 환경 시트에 1:1 | `assets/env/` |
| 집 | 143~177 × 111~122 | 환경 시트에 1:1 | 발자국 2×2~3×2 칸 |
| 소품 | 20~70 | 환경 시트에 1:1 | 발자국 1칸 |
| HUD 초상화 | 40×40 | 일러스트 한 장(흰 배경) | 80×80 (`gen_hero.py`의 `PORTRAIT_BOX`로 자름) |
| 아이콘 | 24×24 | 칸 96×96 (4배) | 48×48 |

요청 그림은 거의 모두 1536×1024 한 장이다(이미지 생성기의 기본 크기). 열 = 프레임, 줄 = 방향.

---

## 3. 그림 받기 흐름

1. 이 문서 §4에서 다음 항목(ID)을 고른다 (순서는 §5)
2. 요청 묶음 폴더(`attack_requests/`·`action_requests/`)면 `pose.png`(+`guide.png`)와 `prompt.txt`를, 문서 프롬프트면 블록 하나를 통째로 넣는다
3. 받은 그림을 [sprite_request/README.md](sprite_request/README.md) §검사표로 확인 → 틀린 줄(방향)만 다시 요청
4. `results/`나 `assets/source/`에 이름 규칙대로 저장
5. 변환: `split_rows.py`(여러 방향 한 장 → 방향별) → `pack_strip.py`(5방향 → 8방향) → `gen_hero.py` / 환경은 `gen_env_from_sheet.py`
6. `godot --path . -- --showcase --anim=<동작>`과 `--auto`로 확인
7. 이 문서의 상태를 ✅로 바꾸고 커밋

---

## 4. 전체 그림 목록

상태: ✅ 그려 받음 · 📨 요청 묶음 준비됨 · 🟡 임시(생성기·가공 그림) · ⬜ 아직 없음 · ➖ 필요 없음

### 4.1 오디세우스 `C-ODY` — 새 차림(치비 전투 갑옷)

시트 `assets/sprites/odysseus.png` — 8방향, 칸 128. 길잡이 [sprite_request/odysseus.md](sprite_request/odysseus.md)

| ID | 동작 | 프레임 | 상태 | 요청 |
|---|---|---|---|---|
| `C-ODY-base` | 기본 8방향 (맨머리·망토 없음) | 1 | ✅ | OUTFIT.md §1 |
| `C-ODY-walk` | 걷기 | 12 | ✅ | OUTFIT.md §2 |
| `C-ODY-run` | 달리기 | 12 | ✅ | OUTFIT.md §3 |
| `C-ODY-attack1` | 가로 베기 | 4 | 📨 (게임엔 옛 망토 그림) | `attack_requests/` 2장 |
| `C-ODY-attack2` | 되베기 | 4 | 📨 (옛 그림) | `attack_requests/` 2장 |
| `C-ODY-attack3` | 내려찍기 | 5 | 📨 (옛 그림) | `attack_requests/` 2장 |
| `C-ODY-heavy` | 회전 베기 | 6 | 📨 (옛 그림) | `attack_requests/` 3장 |
| `C-ODY-idle` | 숨쉬기 | 4 | 📨 (지금은 기준 포즈 변형) | `action_requests/` 2장 |
| `C-ODY-hit` | 피격 | 2 | 📨 | `action_requests/` 2장 |
| `C-ODY-death` | 쓰러짐 | 5 | 📨 | `action_requests/` 2장 |
| `C-ODY-block` | 방패 막기 | 2 | 📨 | `action_requests/` 2장 |
| `C-ODY-dodge` | 구르기 | 4 | 📨 | `action_requests/` 2장 |
| `C-ODY-bow` | 활 당겨 쏘기 | 4 | 📨 | `action_requests/` 2장 |
| `C-ODY-interact` | 권양기·불 붙이기·풀어 주기 | 4 | 📨 | `action_requests/` 2장 |
| `C-ODY-takedown` | 뒤에서 조용히 처치 | 4 | ⬜ (지금은 attack1로 보임, 있으면 좋음) | — |
| `C-ODY-downed` | (부하 전용 동작) | — | ➖ | — |
| `C-ODY-helmet` | 머리 장식: 이마 위로 올린 코린트 투구 | 방향당 1 | ⬜ | OUTFIT.md "정한 것" — 프롬프트 아직 |
| `C-ODY-cape` | 망토 (정지 그림, 코드로 흔듦) | 방향당 1 | ⬜ | OUTFIT.md "정한 것" — 프롬프트 아직 |
| `C-ODY-sailor` `-beggar` | 항해복·거지 변장 몸 옷 | — | ⬜ | 챕터 2·6 때 |
| `C-ODY-portrait` | HUD 초상화 (맨머리 일러스트) | 1 | ✅ | — |

### 4.2 챕터 1 인물 `C-GRK` `C-TRO` `C-NPC`

지금은 모두 `tools/gen_characters.py`의 임시 그림(칸 64, 옛 비율). 프롬프트 [sprite_request/soldiers.md](sprite_request/soldiers.md)

| ID | 인물 | 시트 이름 | 꼭 필요한 동작 | 있으면 좋은 동작 | 상태 |
|---|---|---|---|---|---|
| `C-GRK-sword` | 그리스 검병 (부하) + 정찰병 테르산드로스 | `greek_sword` | walk attack1 block hit death | idle run attack2 | 🟡 |
| `C-GRK-spear` | 그리스 창병 (부하) | `greek_spear` | walk attack1 block hit death | idle run attack2 | 🟡 |
| `C-GRK-archer` | 그리스 궁병 (부하) | `greek_archer` | walk bow hit death | idle run | 🟡 |
| `C-TRO-sword` | 트로이 검병 (경보병 겸함) | `trojan_sword` | walk run attack1 block hit death interact | idle attack2 | 🟡 |
| `C-TRO-spear` | 트로이 창병 | `trojan_spear` | walk run attack1 block hit death interact | idle attack2 | 🟡 |
| `C-TRO-archer` | 트로이 궁수 | `trojan_archer` | walk run bow hit death | idle interact | 🟡 |
| `C-TRO-captain` | 수비대장 아게노르 (2페이즈 보스) | `trojan_captain` | walk attack1 attack2 attack3 heavy block hit death | idle run horn charge | 🟡 |
| `C-NPC-sinon` | 첩자 시논 | `sinon` (새로) | idle | walk | 🟡 (지금은 궁병 시트를 빌려 씀) |

각 인물마다 먼저 **기본 8방향 1장**(`<시트 이름>_8dir.webp`)을 받고, 동작은 한 장에 3방향(E·SE·S)·2방향(NE·N)씩 받는다.

동작이 빠졌을 때 대체 규칙 (병사 변환 도구가 처리할 것)

| 빠진 동작 | 대신 쓰는 것 |
|---|---|
| idle | 기본 포즈를 눌렀다 펴서 숨쉬기 (지금 방식) |
| run | walk를 fps 13으로 |
| attack2 | attack1 |
| attack3·heavy (일반 병사) | 쓰지 않음 |
| downed (쓰러진 부하) | death 마지막 칸 |
| interact | attack1 첫 두 칸 |
| horn · charge (아게노르) | idle · run |
| dodge | 병사는 쓰지 않음 ➖ |

### 4.3 무기 `W`

`assets/weapons/` + `weapons.json`(그림·`grip`). 지금은 `tools/gen_weapons.py`의 아주 작은 임시 그림. 프롬프트 odysseus.md §무기

| ID | 그림 | 상태 |
|---|---|---|
| `W-sword` | 짧고 굵은 청동 검(크시포스), 날 끝이 위로 | 🟡 |
| `W-shield` | 둥근 방패 4면: front·three_quarter·side·back | 🟡 |
| `W-bow` | 활: 평상시·당겼을 때 | 🟡 |

### 4.4 챕터 1 환경 `E-TROY`

원본 `assets/source/troy_env.webp`를 `gen_env_from_sheet.py`가 잘라 쓴다. 프롬프트 [sprite_request/environment.md](sprite_request/environment.md)

| ID | 그림 | 상태 |
|---|---|---|
| `E-TROY-floor` | 바닥 6종(cobble plaza dirt grass road ash) × 변형 4 | ✅ |
| `E-TROY-wall` `-tower` `-gate` | 성벽·성탑·성문(열린 문은 닫힌 문을 어둡게 가공) | ✅ |
| `E-TROY-house` | 집 4채 + 불탄 변형(가공) | ✅ |
| `E-TROY-horse` | 트로이 목마 | ✅ |
| `E-TROY-props` | 상자·통·횃불대·항아리·기둥·트로이 깃발·돌무더기·창 걸이·수레 | ✅ |
| `E-TROY-torch_off` | 꺼진 횃불대 (횃불대를 가공) | ✅ |
| `E-TROY-fire` `-smoke` | 불꽃 8프레임·연기 6프레임 (`troy_fire.webp`) | ✅ |
| `E-TROY-alarm_bell` | 경보 종 | 🟡 |
| `E-TROY-winch` | 성문 권양기 | 🟡 |
| `E-TROY-brazier` | 화로 | 🟡 |
| `E-TROY-banner_greek` | 그리스 깃발 | 🟡 |
| `E-TROY-arrow` | 날아가는 화살 | 🟡 |
| `E-TROY-armory` | 무기고 (지금은 통·창 걸이·상자 묶음) + 불탄 모습 | ⬜ (있으면 좋음) |
| `E-TROY-market` | 시장 좌판·짐더미(궁수가 올라서는 곳) | ⬜ (지금은 상자·통으로 대신) |
| `E-TROY-post` | 정찰병을 묶었던 기둥 | ⬜ (있으면 좋음) |
| `E-TROY-shadow` | 발밑 그림자 | ➖ (코드 그림으로 충분) |
| `E-TROY-gate_anim` | 성문 열림 3단계 | ⬜ (있으면 좋음) |
| `E-TROY-stairs` | 성벽 계단·성벽 위 통로 | ⬜ (M2 높낮이 때) |
| `E-TROY-decal` | 바닥 그을음·부서진 방패·떨어진 창 | ⬜ (있으면 좋음) |

### 4.5 이펙트 `F`

지금은 모두 `scripts/combat/fx.gd`가 도형으로 그린다. 프롬프트 [sprite_request/ui_fx.md](sprite_request/ui_fx.md)

| ID | 이펙트 | 프레임 | 칸 (요청 크기) | 상태 |
|---|---|---|---|---|
| `F-hit` | 타격 불꽃 | 4 | 48×48 | 🟡 |
| `F-parry` | 패링 섬광 | 4 | 64×64 | 🟡 |
| `F-block` | 방패에 막힘 불꽃 | 3 | 48×48 | 🟡 |
| `F-dust` | 구르기·착지 먼지 | 5 | 64×32 | 🟡 |
| `F-shout` | 전투의 함성 고리(납작한 타원) | 6 | 192×96 | 🟡 |
| `F-takedown` | 조용한 처치 | 4 | 48×48 | 🟡 |
| `F-slash` `F-reach` | 베기 궤적·공격 범위 표시 | — | — | ➖ (방향이 자유로워 코드로) |
| `F-telegraph` `F-vision` | 적 공격 예고·잠입 시야 부채꼴 | — | — | ➖ (코드) |

### 4.6 UI `U`

| ID | 그림 | 상태 |
|---|---|---|
| `U-portrait-odysseus` | 오디세우스 초상화 | ✅ |
| `U-portrait-greek` | 부하 초상화 3 (검병·창병·궁병) | 🟡 |
| `U-portrait-sinon` `-agenor` | 시논(대화창)·아게노르(보스 체력바) | ⬜ |
| `U-icons` | 아이콘 12: 검·활·함성·명령 4·상호작용·의심 ?·알아챔 !·체크포인트·잠입 | ⬜ (의심·알아챔은 지금 글자) |
| `U-frames` | 체력·스태미나 바 틀, 슬롯 틀, 미니맵 테두리, 대화창 9칸 틀(뇌문 장식), 이름표 | ⬜ |
| `U-result` | 클리어 화면 칭호 배지 「밤의 그림자」「보이지 않는 자」 | ⬜ (있으면 좋음) |
| `U-logo` | 타이틀 로고 "ODYSSEY" | ⬜ |
| `U-cursor` | 조준 커서 | ⬜ |
| `U-font` | 한글 픽셀 글꼴 (제안: 갈무리 Galmuri, OFL 라이선스) | ⬜ |

### 4.7 영상

| ID | 내용 | 상태 |
|---|---|---|
| `V-troy-intro` | 챕터 1 오프닝 4컷(실사풍, 약 32초) — [TROY_INTRO_VIDEO.md](sprite_request/TROY_INTRO_VIDEO.md) | 요청 문서 준비됨 |

### 4.8 챕터 2~6 미리 보기

챕터를 시작할 때 이 표를 §4.x 상세 목록으로 옮긴다. 인물은 모두 치비.

| 챕터 | 인물 | 환경 | 특별한 그림 |
|---|---|---|---|
| 2 귀환의 시작 | 키코네스 전사·궁수, 오디세우스 **항해복** | 바다 타일(물결 4프레임), 해안, 항구(부두·말뚝·그물), 이스마로스 마을(챕터 1 집 색 바꿈) | **갤리선** 8방향(돛 접힘/펼침, 노 젓기 4프레임), 해도 UI |
| 3 폴리페모스 | **폴리페모스**(대기·걷기·내리치기·움켜잡기·포효·취함·눈 찔림·잠), 양(걷기·풀 뜯기) | 동굴 바닥·벽·종유석, 나무 우리, 치즈 바구니 | 포도주 통, 말뚝(달군 끝), 바위, 양 배 밑 오디세우스 포즈 |
| 4 키르케 | 키르케, 돼지(변신한 부하), 마법 늑대·사자, 헤르메스 | 숲 타일, 궁전, 마법진 | 몰리 약초, 변신 이펙트 |
| 5 세이렌 | 세이렌(날기·노래), 노 젓는 선원, 오디세우스 **항해복** | 거친 바다, 암초, 절벽 | 돛대에 묶인 오디세우스, 밀랍, 안개 덮개 |
| 6 이타카 | 오디세우스 **거지 변장**, 구혼자 3종, 텔레마코스, 에우마이오스, 페넬로페, 개 아르고스 | 궁전 홀 바닥·기둥·식탁 | 도끼 12개, 오디세우스의 활 |

웹 시제품(`docs/legacy-web/SPEC.md`)에서 가져올 연출 아이디어: 폴리페모스의 금빛 외눈 약점과 활 조준선,
세이렌의 청자색 음파 vs 청동 종의 금빛 공명파.

---

## 5. 요청 순서

| 묶음 | 내용 | 장 수 | 어디서 |
|---|---|---|---|
| A | 오디세우스 공격 4종 (새 차림) | 9 | `sprite_request/attack_requests/` |
| B | 오디세우스 나머지: idle → hit → death → block → dodge → bow → interact | 14 | `sprite_request/action_requests/` |
| C | 오디세우스 투구·망토 레이어 (프롬프트부터 만들어야 함) | 2~ | OUTFIT.md |
| D | 무기 3종 | 1 | `sprite_request/odysseus.md` §무기 |
| E | 병사 기본 8방향: 트로이 검병 → 그리스 검병 → 트로이 창병 → 그리스 창병 → 트로이 궁수 → 그리스 궁병 → 아게노르 → 시논 | 8 | `soldiers.md` §2 |
| F | 병사 필수 동작: 인물마다 walk → attack1(또는 bow) → hit → death → block → (트로이) run·interact, 2장씩 | 약 70 | `soldiers.md` §3 |
| G | 환경 추가 한 장 + 이펙트 한 장 + 아이콘 한 장 + HUD 틀 + 부하 초상화 | 5~8 | `environment.md`, `ui_fx.md` |
| H | 병사 나머지 동작(idle·attack2), 아게노르 horn·charge | 약 25 | `soldiers.md` §3 |

A·B·C·D를 받으면 오디세우스는 완성된다. E를 받은 뒤 팀 색이 어두운 화면에서 잘 구분되는지 먼저 게임에 넣어 보고 F로 넘어간다.
한도 때문에 한 번에 10개 안팎씩 나눠 받는다.
