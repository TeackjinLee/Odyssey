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
`tools/gen_characters.py`는 그려 받은 원본이 있는 캐릭터를 건너뛴다(덮어쓰지 않음).

**트로이 검병 동작(`units/trojan_sword/`):** 적이 쓰는 걷기·공격1·2·피격·쓰러짐 13장을 받았다(`armed_patch.py <폴더> unit`이
오디세우스 전용 문구를 병사 무기 문구로 바꾼다). `SPRITE_CHAR=trojan_sword SPRITE_SRC_H=320`으로 묶고, `gen_hero.py`는
병사 걷기 줄에 1장 오디세우스 걷기와 같은 배율을 써서 키 차이를 살린다(고정 배율이면 걷기도 키를 216에 억지로 맞추지 않는다).
**나머지 6종 동작:** `units/make_motion.py <이름>…`이 같은 흐름으로 요청 폴더를 만든다(검병·창병 걷기·공격1·2·피격·쓰러짐,
궁수 걷기·활쏘기·피격·쓰러짐, 대장은 공격3과 방향마다 한 장인 강공격까지). 창병 공격은 찌르기 문구, 궁수는 왼손 활 문구를 붙인다.
`units/run_all.sh`가 10개씩 동시에 돌린다(`one.sh` = 한 요청). 받은 그림은 `results/<이름>/`.
다시 받은 것: 궁수 둘 활쏘기(모든 줄이 오른쪽을 겨눔), 그리스 창병 공격2 북쪽(얼굴이 보임), 대장 강공격 SE(칸 선이 그려짐).
묶기는 `SPRITE_SRC_H=320`, 대장은 기본 시트처럼 조금 더 크게 305(강공격은 크게 그려 와 420).
**달리기·막기·초상화:** `make_motion.py --anims=run,block,portrait <이름>…`(막기는 방패 든 병사만, 초상화는 `units/portrait/<이름>`).
모두 받아 넣었다. Codex 한도에 걸린 요청은 `rerun_later.sh`가 한도가 풀린 뒤 다시 보낸다(그리스 궁수 달리기 SE는 다른 아이처럼 그려져 다시 받음).
초상화는 `assets/source/<이름>_portrait.webp`로 두면 `gen_hero.py`가 부대 칸 초상화로 만든다(아게노르 초상화는 보스 체력바 왼쪽).
**시논:** 기본 8방향(`units/sinon.txt`, 다른 7종처럼 `style_ref.png` 첨부)과 걷기(`make_motion.py sinon`, 빈손·손목 밧줄 문구)를 받아
`ARMED_BODIES`에 넣고 1장 시논이 궁병 시트 대신 `sinon` 시트를 쓴다. 트로이 검병·창병 상호작용(종 치기·권양기)과 아게노르 함성(interact 자리에 뿔나팔)도 `--anims=interact`로 받았다.
대화창은 말하는 이 이름(대사 글의 names)으로 초상화를 찾아 왼쪽에 그린다(`hud.gd` `_speaker_portrait`).

**HUD 초상화:** `extra/portrait`로 받은 그림을 `assets/source/odysseus_ch1_portrait.webp`로 두면 `gen_hero.py`가
`portrait_odysseus_ch1.png`(80×80)를 만들고, HUD는 입은 옷의 초상화를 쓴다.
**활쏘기 북동:** 세 번 실패한 뒤 옆모습 줄(`side.png`)을 같이 붙이고 "45도 위로"를 강조한 한 방향 요청(`extra/bow_NEd`)으로 받았다.
크게(키 480) 그려 와서 다른 방향 키(327)에 맞춰 줄인 뒤 묶었다.
