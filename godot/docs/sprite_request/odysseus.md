# 오디세우스 그림 — 어디에 무엇이 있나

오디세우스 그림 요청은 여러 곳에 나뉘어 있다. 이 문서는 진행 상태와 길잡이만 담는다.
차림 규칙과 결정 기록은 [OUTFIT.md](OUTFIT.md), 요청 방식(안내 그림·한도 아끼기·받아 본 교훈)은 [motion_kit/README.md](motion_kit/README.md).

## 진행 상태 — 새 차림(치비 전투 갑옷, 맨머리·망토 없음)

| 그림 | 프레임 | 어디서 요청 | 원본 (`assets/source/`) | 상태 |
|---|---|---|---|---|
| 기본 8방향 | 1 | OUTFIT.md §1 | `odysseus_8dir.webp` | ✅ |
| walk 걷기 | 12 | OUTFIT.md §2 + `motion_kit/` | `odysseus_walk_<방향>.webp` → `_8dir` | ✅ |
| run 달리기 | 12 | OUTFIT.md §3 + `motion_kit/` | `odysseus_run_<방향>.webp` → `_8dir` | ✅ |
| attack1 가로 베기 | 4 | [attack_requests/](attack_requests/README.md) 2장 | `odysseus_attack1_<방향>.webp` | **요청 준비됨** (게임엔 옛 망토 그림) |
| attack2 되베기 | 4 | attack_requests/ 2장 | `odysseus_attack2_<방향>.webp` | **요청 준비됨** (옛 그림) |
| attack3 내려찍기 | 5 | attack_requests/ 2장 | `odysseus_attack3_<방향>.webp` | **요청 준비됨** (옛 그림) |
| heavy 회전 베기 | 6 | attack_requests/ 3장 | `odysseus_heavy_<방향>.webp` | **요청 준비됨** (옛 그림) |
| idle 숨쉬기 | 4 | [action_requests/](action_requests/README.md) 2장 | `odysseus_idle_<방향>.webp` | 요청 준비됨 (지금은 기준 포즈 변형) |
| hit 피격 | 2 | action_requests/ 2장 | `odysseus_hit_<방향>.webp` | 요청 준비됨 |
| death 쓰러짐 | 5 | action_requests/ 2장 | `odysseus_death_<방향>.webp` | 요청 준비됨 |
| block 방패 막기 | 2 | action_requests/ 2장 | `odysseus_block_<방향>.webp` | 요청 준비됨 |
| dodge 구르기 | 4 | action_requests/ 2장 | `odysseus_dodge_<방향>.webp` | 요청 준비됨 |
| bow 활 당겨 쏘기 | 4 | action_requests/ 2장 | `odysseus_bow_<방향>.webp` | 요청 준비됨 |
| interact 권양기·불 붙이기 | 4 | action_requests/ 2장 | `odysseus_interact_<방향>.webp` | 요청 준비됨 |
| 머리 장식: 코린트 투구 | 방향당 1 | OUTFIT.md "정한 것" (프롬프트는 아직) | — | ⬜ |
| 망토 | 방향당 1 | OUTFIT.md "정한 것" (프롬프트는 아직) | — | ⬜ |
| 항해복·거지 변장 | — | 챕터 2·6 때 | — | ⬜ |
| HUD 초상화 (맨머리 일러스트) | 1 | — | `odysseus_portrait.jpg` | ✅ |
| 무기: 검·방패 4면·활 | — | 아래 §무기 | `weapons.webp` | 🟡 (임시) |

받는 순서: **공격 9장 → 나머지 14장(idle·hit·death부터) → 투구·망토 레이어 → 무기**.
공격이 아직 옛 그림이라 칠 때 망토 두른 옛 모습이 섞여 나오므로 공격이 가장 급하다.

## 받은 뒤 넣는 법 (공격·나머지 동작 공통)

```bash
python3 tools/split_rows.py results/<요청>.png <동작> E,SE,S .     # 또는 NE,N
python3 tools/pack_strip.py . <동작> <열 수> 1                     # 5방향 → 8방향 한 장(서쪽은 뒤집기)
python3 tools/gen_hero.py .
```

- 공격은 `gen_hero.py`의 `ATTACK_HANDS`·`ATTACK_LEFT`에 주먹 위치를 찍는다(동·남동·남·북동·북)
- 나머지 동작도 같은 방식으로 손 위치를 찍고 `.json`의 `drawn`에 넣어야 무기가 손에 붙는다. `pack_strip.py`의
  `FLIGHT`·`HEAD_SCALE`에 넣을지(뜬 높이 살림·머리 크기 맞춤)는 동작마다 정한다 — dodge·death는 키가 크게 변하므로 `HEAD_SCALE` 쪽이 맞다
- `godot --path . -- --showcase --anim=<동작>`으로 8방향을 보고, `--auto`로 챕터 1이 그대로 클리어되는지 본다

## 무기 (한 장) — 받을 이름 `weapons.webp`

첨부: `assets/source/odysseus_8dir.webp` (화풍·크기 기준). 받으면 잘라서 `assets/weapons/`에 넣고 `weapons.json`의 `grip`(손이 쥐는 점)을
다시 찍는다. 규칙은 `tools/gen_weapons.py` 머리말: 검은 날 끝이 위, 방패 4면(앞면·비스듬히(앞면이 오른쪽)·옆·뒷면), 활은 세워서 등이 오른쪽.

```
Pixel art game item sprites for the CHIBI Greek hero in the attached "odysseus_8dir.webp", matching its outline thickness,
shading and pixel density EXACTLY. Item sizes relative to that character (he is about 340px tall in each cell).
Solid flat magenta background #FF00FF, no shadow, no text, every item separated with empty space.
1) Short chunky bronze leaf-blade sword (xiphos) with a leather-wrapped grip, standing perfectly vertical, tip pointing UP, about 150px long.
2) Round bronze-rimmed Greek shield (aspis), about 150px across, crimson face with a bronze rim and a simple gold owl emblem,
   in 4 views side by side: front face; three-quarter view turned so the face looks to the right; edge-on side view;
   back side showing the wooden inside and the arm strap.
3) Greek recurve bow, standing vertical, string on the left, about 180px tall, plus the same bow fully drawn.
Chunky, readable shapes that fit the chibi proportions. 2D pixel art, crisp 1px dark outline, no anti-aliasing blur.
```

## 옛 차림 (보관)

망토 두른 옛 차림 시절의 8방향 한 장 프롬프트와 배치 그림은 [archive_caped/](archive_caped/)에 있다(`PROMPTS.md`·`ATTACK_PROMPTS.md`).
같은 시절의 걷기 동영상 실험은 [VIDEO_PROMPTS.md](VIDEO_PROMPTS.md).
