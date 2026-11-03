# 1장 오디세우스(무기 든 모습) 그림 요청 기록

기준 그림 `concept.png`(코린토스 투구·붉은 망토·칼·별 방패·등의 활과 화살통)로 1장 오디세우스의 모든 동작을 받았다.
무기를 몸과 함께 그려 받았으므로 게임은 이 옷(`odysseus_ch1`)에서 따로 그리던 칼·방패·활을 숨긴다.

## 순서

1. 기본 8방향: `base_prompt.txt` + `concept.png` + `base_layout.png`(옛 기본 시트, 배치만 참고) → `assets/source/odysseus_ch1_8dir.webp`
2. 동작 요청 폴더: `tools/motion_request.py <기본 시트> character_motion.txt <출력> <동작들> 1` 로 만들고
   `python3 armed_patch.py <출력>` 으로 맨손 문구를 무기 든 문구로 바꾼다(공격에는 베기 궤적·불꽃, 강공격은 회오리 궤적)
   - `move/` 걷기·달리기 5방향(방향마다 한 장, 12프레임 4×3칸)
   - `attack/` 공격1·2·3·강공격(한 장에 2~3방향)
   - `action/` 구르기·활쏘기·숨쉬기·피격·막기·쓰러짐(한 장에 3방향)
   - Codex는 `run.sh`로 동시에 돌린다(Sol, medium). 한도 때문에 10개 안팎씩 나눠 보냈다
3. 받은 그림은 `results/`에 모으고, 줄 자르기·묶기:
   ```bash
   SPRITE_CHAR=odysseus_ch1 python3 tools/split_rows.py <받은 그림> <동작> E,SE,S .
   SPRITE_CHAR=odysseus_ch1 SPRITE_SRC_H=320 python3 tools/pack_strip.py . <동작> <프레임 수> 1
   ```
   걷기·달리기는 `split_rows` 없이 `assets/source/odysseus_ch1_<동작>_<방향>.webp`로 저장하고 `pack_strip.py . walk`.
4. 시트: `python3 tools/gen_hero.py . odysseus_ch1` → `godot --headless --path . --import`

## 받아 보고 정한 것

- **크기:** 볏 달린 투구 때문에 머리 폭이 자세마다 달라 머리 폭 맞춤이 어긋났다(달리기·북쪽 공격이 작아짐).
  받은 그림은 동작이 달라도 서 있는 키가 약 320px로 같아서 `SPRITE_SRC_H=320`으로 모든 동작을 같은 배율로 묶는다.
  `gen_hero.py`의 `ARMED_BODIES`(키 118)가 걷기 배율을 다른 동작에도 그대로 쓴다.
- **칸:** 베기 궤적·회오리·쓰러진 몸이 잘려 시트 칸을 192(발 180), 묶는 칸을 320으로 넓혔다.
- **다시 받은 것:** 달리기 E·SE(칼·방패가 빠진 장), 공격1 NE·N(옆모습으로 그려짐), 활쏘기 전부(모든 줄이 오른쪽을 겨눔).
  재요청은 같은 폴더를 `…b`로 복사하고 요청 글 끝에 "확인할 점" 한 줄을 붙였다.
- **추가로 받은 것(`extra/`):** 상호작용(도르래) 2장, 쓰러져 있는 장면 1장(3×2칸에 5방향), 활쏘기 북동·북 3번째,
  강공격은 회오리가 칸 경계에서 잘려 방향마다 한 장(3×2칸, 칸 512)으로 다시 받았다. 이 장은 크게 그려 와서
  (서 있는 키 약 410) `SPRITE_SRC_H=410 … pack_strip.py . heavy 3 2 6`으로 묶는다. 동(E)은 색이 어두워 한 번 더 받았다(`heavy_Eb`).

## 적·동료 7종 (`units/`)

트로이 검병·창병·궁수·대장, 그리스 검병·창병·궁수를 같은 화풍의 기본 8방향으로 받았다(`style_ref.png` = 1장 오디세우스 시트,
배치·화풍만 참고). `assets/source/<이름>_8dir.webp` → `python3 tools/gen_hero.py . <이름>`.
`ARMED_BODIES`에서 이 7종은 오디세우스 기본 시트와 같은 배율을 써서 그려 받은 키 차이(대장은 크게)를 살린다.
동작은 아직 기본 8방향의 변형이다. **`tools/gen_characters.py`를 다시 돌리면 이 7종 시트를 옛 64px 그림으로 덮어쓴다.**
