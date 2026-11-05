# 기술 그림 요청 묶음 (Codex·직접 받기)

미끼 던지기(C)·부대 특수 명령(5)에 쓸 그림 3장. 지금 게임은 이 효과들을 도형으로 그리고 있다(`scripts/combat/skills.gd`).

| 폴더 | 받을 것 | 첨부(순서대로) | 받을 이름 |
|---|---|---|---|
| `throw_E-SE-Sa` | 오디세우스 돌 던지기 4프레임 — 동·남동·남 3줄 | `pose.png` | `results/throw_E-SE-Sa.png` |
| `throw_NE-Na` | 같은 동작 — 북동·북 2줄(세 번째 줄은 빈 마젠타) | `pose.png` | `results/throw_NE-Na.png` |
| `fx_skills` | 기술 이펙트 한 장: 화살비·불화살비·돌멩이·흙먼지·창·방패벽 번쩍임·꽂힌 화살·아이콘 6 | `layout.png` → `style_fire.png` → `style_hero.png` | `results/fx_skills.png` |

- **Codex로 한꺼번에**: `./run.sh` (끝나면 요청마다 생성된 그림 경로가 찍힌다). 한도를 아끼려고 후보는 1장씩.
- **직접**: 폴더의 `prompt.txt` 전체를 붙여 넣고 표의 첨부를 순서대로 붙인다.

## 예시 그림이 하는 일

- `throw_*/pose.png` — 같은 인물이 그 줄 방향들로 서 있는 그림. 생김새·크기·방향을 붙잡는다(다른 동작 요청과 같은 방식).
- `fx_skills/layout.png` — **생성기에 붙이는 배치 그림.** 1536×1024를 칸으로 나누고 칸마다 회색 자리표시로 "이 칸에 이런 모양을 이 크기로"를
  보여 준다. 프롬프트가 "회색 자리표시를 완성된 그림으로 바꾸고, 칸 테두리는 그리지 마라"라고 말한다.
- `fx_skills/layout_labeled.png` — 사람이 보는 설명판(칸 이름·프레임 수·게임 크기). 생성기에는 **붙이지 않는다**(글자를 따라 그린다).
- `style_fire.png`·`style_hero.png` — 화풍 기준(`assets/source/troy_fire.webp`, `odysseus_8dir.webp`를 png로 바꾼 것).

## 받은 그림 확인

- 던지기: 1536×1024, 4열×3줄(칸 384×341), 1~2칸에만 손에 작은 돌, 3칸은 손을 편 채 돌 없음. 나머지는 `../README.md` 검사표.
- 이펙트: 배경이 단색 `#282B35`인가, 칸 테두리·회색 선·글자가 남지 않았나, 칸 밖으로 삐져나가지 않았나, 사람이 그려지지 않았나.

## 넣는 법 (godot 폴더에서)

```bash
python3 tools/split_rows.py docs/sprite_request/skill_requests/results/throw_E-SE-Sa.png throw E,SE,S .
python3 tools/split_rows.py docs/sprite_request/skill_requests/results/throw_NE-Na.png throw NE,N .
python3 tools/pack_strip.py . throw 4 1
python3 tools/fx_layout.py cut docs/sprite_request/skill_requests/results/fx_skills.png assets/fx/skills
```

`fx_layout.py cut`은 항목마다 게임 크기의 가로 띠(배경 투명)를 만든다(`volley.png` 128×96×6 등).
그다음 `gen_hero.py`에 throw 손 위치를 찍고, `skills.gd`·`hud.gd`가 띠 그림을 쓰게 바꾼다 — Claude에게 "기술 그림 넣어 줘"라고 하면 된다.

## 다시 만들기

```bash
python3 tools/motion_request.py assets/source/odysseus_8dir.webp docs/sprite_request/motion_kit/odysseus_character.txt docs/sprite_request/skill_requests throw 1
python3 tools/fx_layout.py draw docs/sprite_request/skill_requests/fx_skills
```

`motion_request.py`는 `run.sh`를 새로 쓰므로, 다시 만든 뒤 `fx_skills` 줄을 `run.sh`에 다시 넣는다(아래 한 줄):

```
(cd fx_skills && "$(git rev-parse --show-toplevel)"/godot/tools/codex_image.sh --skip-git-repo-check -s read-only -i layout.png -i style_fire.png -i style_hero.png - < prompt.txt > ../fx_skills.log 2>&1) &
```
