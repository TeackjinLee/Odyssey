# 챕터 3 오프닝 영상 — 폴리페모스의 동굴 (실사풍, 대사 없음, 약 20초)

챕터 1 오프닝(`TROY_INTRO_VIDEO.md`)과 같은 방식이다. 영상 생성기(제미나이 Omni 등)에 컷마다 한 번씩 요청한다. 7초 + 7초 + 6초 = 20초.
생성기가 8초 고정이면 8초로 받고 이어 붙일 때 컷마다 끝을 잘라 20초로 맞춘다.

줄거리: 저녁 바닷가 동굴에 오디세우스와 부하들이 들어가 치즈와 양을 발견 → 땅이 울리고 외눈 거인 폴리페모스가 양 떼를 몰고 들어옴 →
거인이 큰 바위로 입구를 막고, 불빛 속에서 외눈이 숨은 그리스인들 쪽을 본다.

## 요청하는 법

- 프롬프트는 영어 그대로, 컷마다 **새로** 요청하고 하나를 통째로 붙인다. 화면 비율 16:9.
- 첨부할 참조 이미지(`docs/sprite_request/video/ch3_intro/`). 모두 그림이라 **디자인 참고용**으로만 쓰라고 프롬프트에 적어 두었다.
  - `ref1_odysseus.jpg`: 오디세우스 얼굴·옷 (모든 컷)
  - `ref2_polyphemus.png`: 폴리페모스 생김새 (컷 2·3)
  - `ref3_cave.png`: 동굴 안 배치(치즈 선반·화덕·양 우리·입구 바위). 그림 속 숫자는 무시하라고 적어 두었다 (모든 컷)
- 컷 2부터는 앞 컷 마지막 프레임을 캡처해 **시작 이미지**로 같이 넣으면 이어짐이 좋아진다.
- 다시 뽑을 때
  - 거인이 눈 두 개로 나오면 `ONE single eye` 줄을 한 번 더 붙인다.
  - 거인이 너무 작으면 `three times taller than a man` 숫자를 확인한다.
  - 말을 하면 `NO DIALOGUE` 줄을 한 번 더 붙인다.

## 컷 1 — 동굴에 들어감, 7초 (첨부: ref1, ref3)

```
Photorealistic live-action film scene, 7 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera with anamorphic lens, 35mm film grain, real skin texture and real materials (rough limestone, bronze, wool, wood, clay). Low warm light from torches, deep shadows. NOT animation, NOT cartoon, NOT painting, NOT illustration, NOT pixel art, NOT video game graphics.

PLACE: a huge natural sea cave on a wild Greek island at dusk, Bronze Age. The cave layout follows reference image 3 (a drawing used only as a layout reference; ignore the numbers in it): wooden racks full of round cheeses and clay milk jars on the left, a stone fire pit with a hanging iron pot further inside, a wooden sheep pen with a few lambs on the right, a giant bed of sheepskins at the back. Everything is oversized, built for a giant: the cheeses are as big as cart wheels, the milk jars as tall as a man.

CHARACTERS (exactly 4 real human actors):
1. ODYSSEUS, about 40 years old, face, hair, beard and costume match reference image 1 (a drawing used only as a design reference; show him as a real person): curly dark brown hair, short dark beard with grey, bronze breastplate, deep RED wool cape. He carries a burning torch.
2-4. Three Greek soldiers in bronze helmets and dark blue wool cloaks; one carries a big clay wine jar (amphora) on his shoulder.

CAMERA: starts outside at the cave mouth behind the group, then a slow smooth dolly forward following them into the cave. No cuts.

TIMELINE:
- 0-3 s: the four walk from the rocky shore into the dark cave mouth, the torch lighting the wet stone walls.
- 3-6 s: inside, they slow down and look around in wonder at the giant cheeses, milk jars and lambs. One soldier touches a cheese as big as himself.
- 6-7 s: Odysseus raises his hand to stop them and turns his head toward the cave entrance, listening. Mouths stay closed.

SOUND: sea waves outside, dripping water, torch crackling, lambs bleating softly. No voices, no music with singing.

DO NOT: no giant yet, no fighting, no extra people, no text, do not change Odysseus' red cape.
```

## 컷 2 — 거인이 들어옴, 7초 (첨부: ref1, ref2, ref3, 컷 1 마지막 프레임)

```
Photorealistic live-action film scene, 7 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, 35mm film grain, real skin texture, real materials, practical torchlight and the last orange light of sunset coming through the cave mouth. NOT animation, NOT cartoon, NOT painting, NOT illustration, NOT video game graphics.

PLACE: inside the same huge sea cave (layout from reference image 3, ignore its numbers), seen from deep inside looking toward the bright cave entrance.

CHARACTERS:
- POLYPHEMUS, the cyclops: a real giant man, about THREE TIMES TALLER than a man, with ONE single eye in the middle of his forehead (no other eyes). His look follows reference image 2 (a drawing used only as a design reference; show him as a real, believable giant): huge muscular body with sun-tanned skin and old scars, wild curly dark brown hair and a thick beard, a white sheepskin over one shoulder, a rough brown hide loincloth tied with rope, leather wrist wraps, bare feet. He carries a huge wooden club studded with knots in one hand and a big bundle of firewood on his other shoulder.
- About 10 white sheep and one big ram walk in ahead of him.
- ODYSSEUS (red cape, from reference image 1) and three Greek soldiers in dark blue cloaks, small in the foreground, hiding behind the giant milk jars.

CAMERA: low angle from behind the hiding Greeks, Odysseus' shoulder and red cape in the foreground left. Static, then a slight slow tilt up as the giant comes closer. No cuts.

TIMELINE:
- 0-2 s: the ground trembles, dust falls from the ceiling, the torch flame shakes. Sheep pour in through the bright entrance.
- 2-5 s: the huge silhouette of Polyphemus fills the whole entrance and walks in; his single eye catches the light.
- 5-7 s: he throws the firewood down; it crashes on the stone floor in a cloud of dust and sparks. The Greeks press themselves flat against the jars.

SOUND: heavy footsteps that shake the ground, sheep bleating, the loud crash of wood, a deep low drum. No voices, no roaring words, no music with singing.

DO NOT: the giant has only ONE eye, no fighting yet, no blood, no text, do not shrink the giant.
```

## 컷 3 — 입구가 막힘, 6초 (첨부: ref1, ref2, ref3, 컷 2 마지막 프레임)

```
Photorealistic live-action film scene, 6 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, 35mm film grain, real materials. The light changes from orange sunset at the cave mouth to near darkness, then to the red glow of a single fire. NOT animation, NOT cartoon, NOT painting, NOT illustration, NOT video game graphics.

PLACE: the same huge sea cave (layout from reference image 3, ignore its numbers). A gigantic round boulder, taller than the giant, stands beside the cave entrance.

CHARACTERS: POLYPHEMUS (the one-eyed giant from reference image 2, shown as a real giant three times taller than a man, ONE single eye), and ODYSSEUS (red cape, from reference image 1) hiding with three soldiers behind the giant milk jars.

CAMERA: wide shot of the entrance for the first half, then a slow push-in to a close-up of the giant's face. No cuts.

TIMELINE:
- 0-3 s: Polyphemus puts both hands on the boulder and rolls it across the cave entrance with a deep grinding sound. The last orange light of the sunset shrinks to a thin line and disappears. Darkness.
- 3-5 s: he kneels at the fire pit and blows on the embers; red firelight slowly lights his bearded face from below.
- 5-6 s: close-up: his ONE huge eye slowly turns toward the camera, toward the hiding Greeks, and narrows. Hold on the eye. End.

SOUND: the long deep grinding of the rolling stone, a heavy boom when it closes, then silence with crackling embers and the giant's slow breathing. One low drum hit at the end. No voices, no music with singing.

DO NOT: the giant has only ONE eye, no fighting, no blood, no text, the boulder stays closed at the end.
```
