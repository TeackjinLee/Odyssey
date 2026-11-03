# 그림 요청 (이미지 생성기용)

이미지 생성기(ChatGPT 이미지 생성·Codex 등)에 넣을 프롬프트와 첨부 그림. 무엇을 어떤 순서로 받을지는
[../ART_PLAN.md](../ART_PLAN.md) §4·§5, 받은 그림을 게임에 넣는 법은 [../../README.md](../../README.md) §그림 바꾸기.

## 무엇이 어디에

| 위치 | 내용 |
|---|---|
| [odysseus.md](odysseus.md) | **오디세우스 길잡이** — 동작별 진행 상태, 어느 묶음에서 받는지, 넣는 법, 무기 프롬프트 |
| [OUTFIT.md](OUTFIT.md) | 오디세우스 새 차림(치비) 결정 기록, 기본 8방향·걷기·달리기 프롬프트 |
| [motion_kit/](motion_kit/README.md) | 걷기·달리기·공격 요청 키트: 움직임 안내 그림, 요청 글 틀, 예시, 한도 아끼기, 받아 본 교훈 |
| [attack_requests/](attack_requests/README.md) | 새 차림 공격 4종 요청 9개 (`pose.png`+`guide.png`+`prompt.txt`, `ALL_PROMPTS.txt`) |
| [skill_requests/](skill_requests/README.md) | 기술 그림 3장: 오디세우스 돌 던지기 2장(`pose.png`) + 기술 이펙트 한 장(배치 예시 `layout.png`) — `run.sh` |
| [env_requests/](env_requests/README.md) | 환경 시트 요청 3개(`troy_extra`·`troy_city`·`troy_coast`) — `prompt.txt` + 첨부 그림 + `run.sh` |
| [action_requests/](action_requests/README.md) | 새 차림 나머지 7동작(idle hit death block dodge bow interact) 요청 14개 (`pose.png`+`prompt.txt`) |
| [soldiers.md](soldiers.md) | 챕터 1 인물: 그리스 부하 3종, 트로이 병사 3종, 수비대장 아게노르, 시논, 정찰병 |
| [environment.md](environment.md) | 환경: 트로이 추가 소품(권양기·화로·경보 종·횃불대 등), 불 효과 |
| [ui_fx.md](ui_fx.md) | 이펙트, UI 아이콘·틀, 초상화, 로고 |
| [TROY_INTRO_VIDEO.md](TROY_INTRO_VIDEO.md) | 챕터 1 오프닝 영상(실사풍) 컷별 요청 — `video/troy_intro/` |
| `outfit/` | 차림 컨셉 그림(`concepts_chibi10.webp` 등) |
| `layouts/` | 새 캐릭터 기본 8방향 배치 `turnaround_4x2.png`, 크기 비교표 `scale_chart.png` (`python3 tools/gen_request_layout.py . all`) |
| `odysseus_reference.png` | 옛 차림 8방향 — 지금은 **칸 배치·방향·카메라 각도 참고로만** 첨부 (OUTFIT.md §1) |
| [archive_caped/](archive_caped/) · [VIDEO_PROMPTS.md](VIDEO_PROMPTS.md) | 옛 망토 차림 시절 프롬프트·배치 그림·걷기 동영상 실험 (보관) |

## 요청 방식 두 가지

**① 요청 묶음 폴더** (오디세우스 동작 — `attack_requests/`, `action_requests/`)
1. 폴더의 `pose.png`(공격은 `guide.png`도)를 첨부
2. `prompt.txt` 전체(또는 `ALL_PROMPTS.txt`의 해당 부분)를 붙여 넣기. Codex로 한꺼번에 돌릴 땐 `run.sh`
3. 결과를 `results/<폴더 이름>.png`로 저장 → `split_rows.py` → `pack_strip.py` → `gen_hero.py`
4. 새 캐릭터도 기본 8방향만 받으면 `python3 tools/motion_request.py <기본 시트> <인물.txt> <출력> <동작들> 1`로 같은 묶음을 만들 수 있다

**② 문서의 프롬프트 블록** (병사 기본 모습·환경·UI·무기)
1. 프롬프트 코드 블록 **하나를 통째로** 복사해 붙여 넣기 (빈칸 `[...]`이 있으면 채운다)
2. 블록 위에 적힌 그림을 첨부
3. 내가 모은 참고 이미지가 있으면 같이 첨부하고 끝에 한 줄 덧붙이기:
   `Also use the attached "<파일 이름>" as reference for <helmet shape / color / pose …> only.`

어느 쪽이든 **후보는 1장씩**, 요청은 10개 안팎으로 나눠 돌린다(한도 — motion_kit/README.md "한도 아끼기").

## 받은 그림 검사표

- [ ] 배경이 단색인가 (캐릭터 `#FF00FF`, 환경·이펙트 `#282B35`) — 그러데이션·바닥·그림자가 없어야 한다
- [ ] 크기·격자가 맞나 (대개 1536×1024), 칸 사이 틈·선·글자가 없나. 안내 그림의 막대·원이 그려지지 않았나
- [ ] 줄(방향) 순서가 요청과 같은가, 한 줄 안에서 바라보는 방향이 그대로인가 (대각선은 몸 돌림이 내내 같은가)
- [ ] 모든 칸에서 캐릭터 키·머리 크기가 같고 발이 같은 땅 높이인가 (제자리 동작)
- [ ] 생김새·색·외곽선 굵기가 `pose.png`/기준 그림과 같은가 (차림: 맨머리·망토 없음)
- [ ] 오디세우스: 손이 비었고 주먹이 보이나 / 병사: 무기가 그려져 있나
- [ ] 크기가 달라도 비율이 같으면 괜찮다(변환 스크립트가 맞춘다)

## 파일 이름 규칙 (`assets/source/`에 저장)

| 종류 | 이름 | 예 |
|---|---|---|
| 인물 기본 8방향 | `<시트 이름>_8dir.webp` | `trojan_sword_8dir.webp` |
| 인물 동작 (방향별) | `<시트 이름>_<동작>_<방향>.webp` | `odysseus_idle_SE.webp` |
| 인물 동작 (8방향 묶음, 도구가 만듦) | `<시트 이름>_<동작>_8dir.webp` | `odysseus_walk_8dir.webp` |
| 환경 | `<챕터>_<내용>.webp` | `troy_env.webp`, `troy_extra.webp` |
| 이펙트 | `fx_<내용>.webp` | `fx_combat.webp` |
| UI | `ui_<내용>.png` | `ui_icons.png` |
| 초상화 | `<시트 이름>_portrait.jpg` | `greek_sword_portrait.jpg` |

webp는 무손실(RGB)로 저장한다. 생성기가 준 그대로 두고 손으로 고치지 않는다(고칠 것은 변환 스크립트에서).

## 고쳐 달라고 할 때 (그대로 붙여 넣기)

```
Same image, same character and style, but fix only these problems:
- Row 2 (SOUTH-EAST) must keep the same three-quarter body turn in every frame.
- Cells must be exactly the same size with no gaps or lines between them.
- Remove the ground shadow; background must be pure flat magenta #FF00FF.
```

필요한 줄만 남기고 지운다. 자주 쓰는 다른 줄:
- `Keep the feet on the same ground line in every cell; do not let him drift across the cell.`
- `The right fist must be clearly visible in every cell, not hidden behind the body.`
- `Exactly the same character size and head size in every cell of every row.`
