---
name: art-pipeline
description: ODYSSEY 그림 작업 흐름과 변환 명령 — 그림 요청 묶음 만들기, 받은 그림 검사·저장, split_rows·pack_strip·gen_* 변환, ART_PLAN·ROADMAP 갱신, 참고 이미지 보관. 스프라이트·환경·이펙트·소리·영상을 받거나 넣을 때 쓴다.
---

# 그림 작업 흐름

1. `ART_PLAN.md`에서 다음 항목(ID)을 고른다 → `sprite_request/`의 해당 요청 묶음·프롬프트를 사용자에게 준다.
2. 받은 그림을 검사(`sprite_request/README.md`) → `assets/source/`에 이름 규칙대로 저장.
3. `split_rows.py`·`pack_strip.py`·`gen_hero.py` 등 변환 → `--showcase`·`--auto`로 확인.
4. `ART_PLAN.md`의 상태를 ✅로, 끝난 작업은 `ROADMAP.md` 체크박스를 고친다.

사용자가 참고 이미지를 주면 `godot/docs/references/<분류>/`에 저장하고 `references/INDEX.md`에 한 줄 적는다.

## 변환 명령 (godot/ 안에서)

```bash
python3 tools/gen_hero.py .                             # 오디세우스 원본 → assets/sprites/odysseus.*
python3 tools/gen_environment.py . && python3 tools/gen_env_from_sheet.py . && python3 tools/gen_env_extra.py .   # 환경 그림(순서대로, 끝에서 gen_env_redraw가 받은 troy_city·troy_coast로 덮어씀)
python3 tools/motion_request.py <기본 시트> <인물.txt> <출력> <동작들> 1   # 이미지 요청 폴더 만들기
python3 tools/split_rows.py <받은 그림> <동작> E,SE,S .  # 여러 방향 한 장 → 방향별 파일 (다른 캐릭터·옷: SPRITE_CHAR=<이름>)
python3 tools/pack_strip.py . <동작> <열> <줄>          # 방향별 → 8방향 한 장 (SPRITE_CHAR·SPRITE_SRC_H, sprite_request/ch1_kit/README.md)
python3 tools/gen_storm.py .                            # 받은 바다 무늬·폭풍 이펙트 → assets/env/sea_*·assets/fx/storm_* (요청 묶음 storm_requests/)
python3 tools/gen_ship.py . odysseus_galley --hull && python3 tools/gen_ship_crew.py .   # 갤리선 선체 16방향·돛 천·배 위 사람 시트 (ch2_kit/README.md)
python3 tools/gen_animal.py . chicken                    # 받은 동물 원본 → assets/sprites/animal_<종류>.* (요청 묶음 animal_kit/)
python3 tools/gen_food.py .                             # 받은 음식 그림 → assets/sprites/food_icons.* (food_source.gd가 씀)
python3 tools/gen_audio.py . [sfx amb music]            # 소리 전부 합성 → assets/audio/ (ffmpeg 필요, 음악 1분쯤)
python3 tools/gen_video.py .                            # 컷신 영상 assets/source/video/*.mp4 → assets/video/*.ogv (Godot 무비 메이커로, 창이 잠깐 뜬다)
python3 tools/env_redraw_request.py . [시트]            # 환경 다시 그려 받기 요청 묶음(아직 안 받은 시트만)
```
