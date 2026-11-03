# 오디세우스 나머지 7동작 이미지 요청 묶음 (직접 받기)

새 차림(맨머리·망토 없음)의 **idle · hit · death · block · dodge · bow · interact**를 공격(`../attack_requests/`)처럼
**한 장에 여러 방향(줄)씩** 받는 요청 14개다. 움직임이 작거나 몸 전체가 함께 움직이는 동작이라 안내 그림 없이 `pose.png`만 붙인다.
다시 만들기(godot 폴더에서):

```bash
python3 tools/motion_request.py assets/source/odysseus_8dir.webp docs/sprite_request/motion_kit/odysseus_character.txt docs/sprite_request/action_requests rest 1
```

## 받는 법 (요청 하나마다)

1. 폴더 안의 **`pose.png`를 이미지 생성 도구(ChatGPT 이미지 생성·Codex 등)에 첨부**한다.
2. **`prompt.txt`의 글 전체**(또는 `ALL_PROMPTS.txt`의 해당 부분)를 그대로 붙여 넣고 보낸다. Codex로 한 번에 돌리려면 `run.sh`.
3. 나온 그림이 **1536×1024**인지 본다. 아니면 그대로 `results/`에 둔다(맞춰 자른다).
4. 결과를 **`results/<요청 폴더 이름>.png`**로 저장한다. 예: `results/idle_E-SE-Sa.png`.
5. 받으면 방향별로 자르고 시트로 묶는다:
   `python3 tools/split_rows.py <받은 그림> <동작> E,SE,S .` → `python3 tools/pack_strip.py . <동작> <열 수> 1`
   → `gen_hero.py`에 주먹 위치를 찍고 `.json`의 `drawn`에 넣는다(공격과 같은 방식).

## 요청 목록 (먼저 받을 것부터)

| 폴더 | 동작 | 위→아래 줄(방향) | 프레임(열) | 칸 |
|---|---|---|---|---|
| `idle_E-SE-Sa` · `idle_NE-Na` | 숨쉬기 (반복) | E·SE·S / NE·N | 4 | 384×341 |
| `hit_E-SE-Sa` · `hit_NE-Na` | 피격 | E·SE·S / NE·N | 2 | 768×341 |
| `death_E-SE-Sa` · `death_NE-Na` | 쓰러짐 (마지막 칸 유지) | E·SE·S / NE·N | 5 | 307×341 |
| `block_E-SE-Sa` · `block_NE-Na` | 방패 막기 (반복) | E·SE·S / NE·N | 2 | 768×341 |
| `dodge_E-SE-Sa` · `dodge_NE-Na` | 구르기 | E·SE·S / NE·N | 4 | 384×341 |
| `bow_E-SE-Sa` · `bow_NE-Na` | 활 당겨 쏘기 (활은 게임이 붙임) | E·SE·S / NE·N | 4 | 384×341 |
| `interact_E-SE-Sa` · `interact_NE-Na` | 권양기 돌리기·종 치기 (반복) | E·SE·S / NE·N | 4 | 384×341 |

`NE-N` 요청의 세 번째 줄은 빈 마젠타로 둔다. 서쪽 세 방향(W NW SW)은 동쪽 줄을 뒤집어 만든다.

## 결과를 볼 때 확인할 것

- 모든 칸에서 **주먹이 보이는가**(dodge 2·3칸은 몸에 붙여도 됨), 방패 쪽 왼팔은 가슴 앞인가 (bow는 왼팔을 앞으로 뻗음)
- **칸마다 캐릭터 크기·머리 크기가 같은가**, 발이 줄마다 같은 땅 높이인가
- 대각선(SE·NE) 줄은 **몸 돌림이 프레임 내내 같은가**, 맨머리·망토 없음 차림이 pose.png와 같은가
- death 마지막 칸의 쓰러진 몸이 칸 밖으로 나가지 않았는가
- 배경은 순수 마젠타(#FF00FF)이고 칼·방패·활·효과선·글자가 없는가

> 이 묶음은 안내 그림이 없다. 받아 보고 dodge·death처럼 몸이 크게 움직이는 동작의 자세가 흐트러지면
> `tools/attack_guide.py`처럼 막대 인물 안내 그림을 더하는 것이 다음 개선이다.
