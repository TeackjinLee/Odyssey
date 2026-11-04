# 챕터 1 엔딩 영상 — 불타는 트로이를 떠나다 (실사풍, 대사 없음)

오프닝(`TROY_INTRO_VIDEO.md`)에 이어지는 영상. 제미나이 Omni에 컷마다 한 번씩 요청한다. 8초짜리 4컷 = 약 32초.
줄거리: 성문이 열리고 그리스 대군이 쏟아져 들어옴 → 오디세우스와 부하들이 바다 문을 나와 부두를 걸음 → 부두 끝에서 불타는 트로이를 돌아봄 → 갤리선 열두 척이 밤바다로 출항.
게임 엔딩(`chapter1_troy.gd`의 `_play_ending`)과 같은 흐름이다.

## 요청하는 법

- 프롬프트는 영어 그대로, 컷마다 **새로** 요청하고 통째로 붙인다. 화면 비율 16:9
- 첨부할 참조 이미지(`docs/sprite_request/video/troy_ending/`)
  - `ref1_odysseus_real.jpg` — 오프닝 영상에서 뽑은 오디세우스 실사 프레임(얼굴·옷 고정). 모든 컷에 첨부
  - `ref2_crew_real.jpg` — 오프닝의 부하·시논 실사 프레임(파란 망토 병사들). 컷 1·2에 첨부
  - `ref3_troy_burning.jpg` — 오프닝 마지막 프레임(불타는 트로이). 컷 1·3·4에 첨부
  - `ref4_galley.png` — 오디세우스 갤리선 디자인(게임 그림, **디자인 참고용**). 컷 2·4에 첨부
- 컷 2부터는 앞 컷 마지막 프레임을 캡처해 **시작 이미지**로 같이 넣으면 이어짐이 좋아진다
- 다시 뽑을 때
  - 갤리선이 만화처럼 나오면 ref4를 빼고 프롬프트의 배 설명만 남긴다
  - 말을 하면 `NO DIALOGUE` 줄을 한 번 더 붙인다. 사람이 늘면 `exactly N people` 숫자를 확인한다

## 컷 1 — 성문이 열리고 대군이 들어옴 (첨부: ref1, ref2, ref3)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no shouting, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera with anamorphic lens, 35mm film grain, real fire, real smoke, real materials (bronze, wood, stone, wool). Night, orange firelight mixed with cold blue moonlight. The look matches reference image 3 (a real frame from the same film). NOT animation, NOT cartoon, NOT painting, NOT video game graphics.

PLACE: the inside of the huge wooden city gate of Troy, between two tall stone towers. Rooftops of the white stone houses behind are burning, thick smoke and sparks rise into the night sky.

CHARACTERS: ODYSSEUS stands beside the gate, exactly as in reference image 1 (same real actor: curly dark hair, short dark beard with grey, no helmet, bronze breastplate, deep red cape, short bronze sword in his right hand). Next to him three Greek soldiers in bronze helmets and dark blue wool cloaks, as in reference image 2.

CAMERA: medium-wide shot from inside the city, looking at the gate. Static camera, no cuts.

TIMELINE:
- 0-3 s: the two heavy gate doors swing slowly inward. Odysseus and the soldiers push them open with their shoulders.
- 3-6 s: through the open gate, a large army of Greek soldiers with round bronze shields, spears and torches runs into the city past the camera.
- 6-8 s: Odysseus steps aside, lowers his sword and watches them pass. His face is tired, not happy. His mouth stays closed.

SOUND: heavy wooden creak of the gate, hundreds of running footsteps, clanking bronze, roaring fire, a low war drum. No voices, no war cries, no music with singing.

DO NOT: no fighting, no blood, no talking, do not change Odysseus' face, beard or red cape, nobody else wears a red cape.
```

## 컷 2 — 바다 문을 나와 부두로 (첨부: ref1, ref2, ref4, 컷 1 마지막 프레임)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera, 35mm film grain, real water, real fire, real materials. Night, the sky glows orange from the burning city, the sea reflects the fire. NOT animation, NOT cartoon, NOT painting, NOT video game graphics.

PLACE: outside the sea gate of Troy. A long wooden pier runs along the base of the high stone city wall and out into a calm dark sea. Above the wall, the city of Troy is burning: flames and smoke over the battlements. Several Greek galleys are tied to the pier.

SHIPS: Bronze Age Greek galleys built from real wood and pitch: long low black hull, a red painted stripe along the side, a large painted eye on each side of the bow, a bronze ram at the bow, a curled stern post, one mast with a furled cream sail with a red band, a row of oars. The design follows reference image 4 (a game drawing used only as a design reference; show real ships).

CHARACTERS (exactly 4 real human actors, seen from behind and side): ODYSSEUS in front, exactly as in reference image 1 (red cape, bronze breastplate, sword in its sheath now). Behind him three Greek soldiers in bronze helmets and dark blue wool cloaks (sword and shield, long spear, bow), as in reference image 2.

CAMERA: slow tracking shot from the side, moving along the pier with the four men as they walk. No cuts.

TIMELINE:
- 0-2 s: the four men walk out of the small arched sea gate onto the wooden pier.
- 2-6 s: they walk along the pier toward the nearest galley. Fire light flickers on the water and on their armor.
- 6-8 s: they reach the galley. Soldiers already on board hold out their hands to help them climb up.

SOUND: footsteps on wooden planks, small waves slapping the pier, ropes creaking, distant roaring fire. No voices, no music with singing.

DO NOT: no running, no fighting, no talking, no modern boats, do not change Odysseus' face, beard or red cape.
```

## 컷 3 — 부두 끝에서 돌아봄 (첨부: ref1, ref3, 컷 2 마지막 프레임)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera, 35mm film grain, shallow depth of field, real skin texture. Night; warm orange firelight on one side of his face, cold blue moonlight on the other. NOT animation, NOT cartoon, NOT painting, NOT video game graphics.

CHARACTER (exactly 1 person in focus): ODYSSEUS, exactly as in reference image 1 (same real actor: about 40 years old, curly dark hair, short dark beard with grey, no helmet, bronze breastplate, deep red cape). He stands on the deck at the stern of a wooden galley, holding a rope of the ship.

BACKGROUND: across the dark water, the whole city of Troy burns on its hill, high stone walls and towers in flames, smoke rising to the moon, as in reference image 3. Out of focus.

CAMERA: starts as a medium shot from behind his shoulder looking at the burning city, then a slow smooth move around him to a close-up of his face. No cuts.

TIMELINE:
- 0-3 s: Odysseus stands still, looking back at the burning city. His red cape moves in the sea wind.
- 3-6 s: the camera moves to his face. The fire is reflected in his eyes. He looks tired and sad, not proud.
- 6-8 s: he slowly closes his eyes, breathes out, then turns his head away from the city toward the open sea. His mouth stays closed.

SOUND: sea wind, waves against the hull, creaking wood, a far roar of fire, one low soft drone. No voices, no music with singing.

DO NOT: no tears falling, no talking, no smiling, no other faces in focus, do not change his face, beard or red cape.
```

## 컷 4 — 열두 척이 밤바다로 출항 (첨부: ref3, ref4, 컷 3 마지막 프레임)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera, 35mm film grain, real ocean water, real fire on the horizon. Night with a full moon, the light changes from orange (near the city) to cold blue (open sea). NOT animation, NOT cartoon, NOT painting, NOT video game graphics.

SHIPS: twelve Bronze Age Greek galleys built from real wood: long low black hulls, a red stripe along the side, a large painted eye on the bow, a bronze ram, a curled stern post, one mast with a square cream sail with a horizontal red band, two rows of wooden oars. The design follows reference image 4 (a game drawing used only as a design reference; show real ships). Odysseus' galley leads in front.

PLACE: the dark Aegean sea at night. Behind the ships, on the shore, the city of Troy burns on its hill as in reference image 3, getting smaller.

CAMERA: starts low just above the water beside the leading galley, then a slow smooth crane up and backward to a very high wide view of the whole fleet on the sea. No cuts.

TIMELINE:
- 0-3 s: the oars of the leading galley dip into the water together and pull. The cream sail with the red band drops open and fills with wind.
- 3-6 s: the camera rises. The other eleven galleys follow in a line behind, each with its sail open and oars moving.
- 6-8 s: very high wide view: twelve small ships on the moonlit sea moving away from the burning city, which is now only an orange glow on the horizon.

SOUND: oars splashing in rhythm, wind filling the sails, waves, a slow low drum and one long deep horn far away. No voices, no singing.

DO NOT: no storm, no other enemy ships, no text, no modern ships, keep the sails cream with one red band.
```
