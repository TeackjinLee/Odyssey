# ODYSSEY — 오디세우스의 귀환

호메로스 《오디세이아》를 바탕으로 한 2.5D 쿼터뷰 픽셀아트 액션 RPG. 치비 오디세우스로 잠입하고 부하를 지휘하며
트로이 함락부터 이타카 귀환까지 6개 챕터를 겪는다.

**개발 중인 버전은 Godot 4 버전([`godot/`](godot/README.md))이다.** 루트의 `src/`·`index.html`·`public/`은
이전 웹 시제품(TypeScript + Three.js)으로, 더 손대지 않고 참고용으로만 둔다.

## 문서 지도

| 문서 | 내용 | 언제 보나 |
|---|---|---|
| [godot/README.md](godot/README.md) | 실행·조작·코드 구조·그림 교체 규칙 | 코드를 고칠 때 |
| [godot/docs/GAME_DESIGN.md](godot/docs/GAME_DESIGN.md) | 6챕터 게임 기획 | 무엇을 만드는지 볼 때 |
| [godot/docs/ROADMAP.md](godot/docs/ROADMAP.md) | 개발 계획: 마일스톤·다음 할 일·완료 기준 | 다음에 뭘 할지 정할 때 |
| [godot/docs/ART_PLAN.md](godot/docs/ART_PLAN.md) | 화풍 규칙·크기 규격·전체 그림 목록과 진행 상태 | 그림을 요청·교체할 때 |
| [godot/docs/sprite_request/](godot/docs/sprite_request/README.md) | 이미지 요청: 오디세우스 차림·요청 키트·요청 묶음·병사/환경/UI 프롬프트 | 그림을 요청할 때 |
| [godot/docs/references/](godot/docs/references/README.md) | 직접 모은 참고 이미지를 두는 곳 | 참고 이미지를 줄 때 |
| [docs/legacy-web/](docs/legacy-web/README.md) | 웹 버전 문서 (보관) | 옛 구현을 찾아볼 때 |

## 실행

```bash
godot --path godot                 # Godot 4.7 이상, 타이틀부터
godot --path godot -- --play       # 바로 챕터 1
```

웹 시제품: `npm install && npm run dev` (포트 5173)
