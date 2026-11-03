# GEMINI.md

이 저장소의 작업 규칙은 [`CLAUDE.md`](CLAUDE.md)와 같다. 요약:

- **개발 대상은 Godot 4 버전 `godot/`** (2D 픽셀아트 쿼터뷰 액션 RPG). 루트의 웹 시제품(TypeScript + Three.js)은 보관용이다 → `docs/legacy-web/`.
- 문서·주석·UI 문구·커밋 메시지는 한국어.
- 코드 구조·그림 규칙: `godot/README.md` / 기획: `godot/docs/GAME_DESIGN.md` / 계획: `godot/docs/ROADMAP.md` / 그림 목록: `godot/docs/ART_PLAN.md`.
- 변경 확인: `godot --headless --path godot -- --auto --quit-after=220` (봇이 챕터 1 클리어), 잠입 봇은 `--auto=stealth --quit-after=300`.
- 로직(`scripts/`)과 그림(`assets/` + `.json`)을 섞지 않는다. 그려 받은 원본은 `assets/source/`, 변환은 `tools/`.
