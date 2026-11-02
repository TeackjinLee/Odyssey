# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트

ODYSSEY: 귀환의 항해 — TypeScript + Three.js + Vite로 만든 브라우저용 2.5D 쿼터뷰(38°) 그리스 신화 액션 로그라이트. 게임 디자인과 8개 씬의 연출 명세는 `SPEC.md`, 마일스톤 진행은 `PLAN.md`에 있다. 문서·주석·UI 문구는 한국어로 쓴다.

이 폴더는 자체 git 저장소다(상위 `~/study` 저장소 안에 있지만 따로 관리).

**새 버전(Godot 4)은 `godot/`에 있다** — 2D 픽셀아트 쿼터뷰 액션 RPG로 다시 만드는 중(챕터 1 플레이 가능). 실행·구조·그림 규칙은 `godot/README.md`, 6챕터 기획은 `godot/docs/GAME_DESIGN.md`. 확인은 `godot --headless --path godot -- --auto --quit-after=200`(봇이 챕터 1 끝까지 진행). 아래 내용은 기존 웹(Three.js) 버전 설명이다.

## 명령

```bash
npm run dev       # Vite 개발 서버, 포트 5173 (host: true)
npm run build     # tsc 타입 검사 후 vite build → dist/
npm run preview   # dist/ 미리보기
npx tsc           # 타입 검사만 (noEmit, strict)
```

테스트·린터는 없다. 변경 확인은 `npx tsc`와 개발 서버에서 직접 플레이로 한다(타이틀의 씬 이동 버튼 `#scene-nav`·훈련장 바로가기로 원하는 씬에 바로 들어갈 수 있다).

## 구조

`src/main.ts`가 하나의 `requestAnimationFrame` 루프를 돌린다. 매 프레임 순서:

1. `renderer.updateMouseGroundPosition()` — 마우스를 지면 좌표로 바꿔 `input.aimWorldPos`에 넣음
2. `world.update(dt, input)` — 게임 로직 (dt는 0.05초로 상한)
3. `renderer.render(world, dt)` — Three.js 그리기
4. `hud.update(...)` — DOM HUD 갱신
5. `input.consumeFrameTriggers()` — 한 프레임짜리 입력 소비

**로직과 렌더링이 분리되어 있다.** `WorldSimulation`(`src/combat/`)이 모든 게임 상태(player, enemies, projectiles, swings, shockwaves, telegraphs, lightningArcs, cameraShake, 씬 전환, 가호, 메타 성장)를 가지고, 렌더러와 HUD는 그 필드를 매 프레임 읽기만 한다. 좌표는 `Vec2 { x, z }`(지면 평면). 새 게임 동작은 `WorldSimulation`에, 보이는 것은 렌더러에 넣는다.

- `src/types/combat.ts` — 공유 타입. `SceneId`, `EnemyKind`, `EnemyState`(idle→chase→windup→attack, weak_open/staggered), `PlayerActionState`, `TelegraphShape`(circle/sector/line 공격 예고) 등. 적·씬을 추가하면 여기부터 고친다.
- `src/data/combatConfig.ts` — 수치 조정은 `COMBAT_CONFIG`, 4신 가호 정의는 `OLYMPIAN_BOONS`.
- `WorldSimulation.loadScene(sceneId)` — 씬별 적·지형(pillars, hubInteractables) 배치. 흐름: title → hub → cyclops_cave → polyphemus_boss → (가호 선택 `openBoonSelection`/`selectBoon`) → siren_reef → parthenope_boss → return. `training_grounds`는 별도 훈련장.
- `src/rendering/SceneRenderer25D.ts` — 씬이 바뀌면(`renderedSceneId` 비교) 바이옴 지형·조명·수면을 다시 짓고, 엔티티는 빌보드 스프라이트로 그림. Bloom 후처리(EffectComposer + UnrealBloomPass).
- `src/rendering/odysseus/` — 오디세우스 3D 모델(적·보스는 스프라이트). 렌더러는 `OdysseusAvatar` 하나만 쓴다: `public/assets/models/odysseus.glb`나 Mixamo `odysseus.fbx`(+`anims/<동작>.fbx`)가 있으면 `GltfOdysseus`(뼈대 모델, 설정은 `avatarConfig.ts`, 안내는 `docs/odysseus-model.md`), 없으면 도형 모델 `OdysseusModel`. 둘 다 `AvatarMotion`(몸 방향: 걸을 땐 가는 쪽, 공격 땐 조준 `facingAngle` 쪽·기울기·발 디딤)과 `PoseDriver`(상태별 `OdysseusPoses` 자세 섞기)를 공유한다. GLB는 상태에 맞는 동작이 없으면 이 자세로 상체·팔(IK)을 보완한다. `CapeCloth`는 도형 모델의 Verlet 망토, `SpearTrail`은 창끝 궤적, `Props`는 도형 무기(GLB 모델의 주무기는 청동 검, 도형 모델은 창), `ToonMaterials`는 고정 빛 툰 셰이더+외곽선. 모델은 +Z가 앞, -X가 오른쪽.
- 창 공격 타이밍·내딛는 거리·히트스톱·입력 버퍼는 `COMBAT_CONFIG.player.spear`에 있고, 애니메이션은 `stateTimer`로 그 구간 진행도를 계산해 따라간다. 히트스톱 중엔 렌더러가 모델에 dt=0을 넘겨 동작도 멈춘다.
- `src/rendering/ProceduralSprites.ts` — 적·보스 스프라이트를 캔버스로 절차 생성한 텍스처 아틀라스. `public/assets/`의 보스 이미지(polyphemus.svg, parthenope.svg)가 있으면 그걸 우선 쓴다.
- `src/rendering/KeyArtRenderer.ts` — 타이틀 키아트(`#keyart-canvas`), `/assets/storyboard.png` 사용.
- `src/ui/HudController.ts` — `index.html`에 미리 있는 DOM 요소(id로 찾음: 타이틀·허브 프롬프트·가호 모달·귀환 강화 화면·HUD 슬롯)를 갱신하고 버튼을 `world.loadScene` 등에 연결. HUD 마크업과 CSS는 전부 `index.html`에 있다.
- `src/core/AudioSynth.ts` — WebAudio로 효과음 합성(오디오 파일 없음). `InputManager.ts` — WASD(화면 기준)·마우스 조준·Space 대시·Q 패링·E 권능.

`dist/`는 빌드 결과물이므로 직접 고치지 않는다. 정적 이미지는 `public/assets/`에 두고 `/assets/...` 경로로 불러온다.
