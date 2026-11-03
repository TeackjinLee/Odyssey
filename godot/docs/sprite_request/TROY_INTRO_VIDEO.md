# 챕터 1 오프닝 영상 — 트로이의 목마 (실사풍, 대사 없음)

제미나이 Omni(동영상)에 컷마다 한 번씩 요청한다. 8초짜리 4컷 = 약 32초.
줄거리: 잔치가 끝난 밤 광장 → 목마 배의 문이 열리고 오디세우스가 밧줄로 내려옴 → 부하 셋과 첩자 시논 합류 → 북쪽 성문으로 달려가고 트로이에 불이 붙음.

## 요청하는 법

- 프롬프트는 영어 그대로 붙인다(한국어보다 잘 알아듣는다). 컷마다 **새로** 요청하고, 프롬프트 하나를 통째로 붙인다
- 화면 비율 16:9, 길이 8초
- 첨부할 참조 이미지(`docs/sprite_request/video/troy_intro/`) — 둘 다 그림이라 **디자인 참고용**으로만 쓰라고 프롬프트에 적어 두었다
  - `ref1_odysseus.jpg` — 오디세우스 얼굴·옷 (모든 컷에 첨부)
  - `ref2_horse.png` — 목마 모양 (모든 컷에 첨부)
- 컷 2부터는 앞 컷 마지막 프레임을 캡처해 **시작 이미지**로 같이 넣으면 이어짐이 좋아진다(실사로 나온 프레임이라 화풍도 실사로 고정된다)
- 다시 뽑을 때
  - 그림체가 섞이면: 참조 이미지를 빼고 컷 1의 실사 결과 프레임만 참조로 넣는다
  - 말을 하면: `NO DIALOGUE` 줄을 한 번 더 붙인다. 사람이 늘면 `exactly N people` 숫자를 확인한다

## 컷 1 — 고요한 광장 (첨부: ref1, ref2)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera with anamorphic lens, 35mm film grain, real materials (weathered wood, stone, bronze, clay), realistic night lighting with deep shadows. NOT animation, NOT cartoon, NOT painting, NOT illustration, NOT pixel art, NOT video game graphics.

PLACE: night inside the walled city of Troy, Bronze Age. A wide stone-paved plaza surrounded by white stone houses with flat roofs and two tall stone towers in the background. Cold blue moonlight from a full moon. A few small dying campfires glow orange.

MAIN OBJECT: a giant wooden horse on wooden wheels stands in the center of the plaza, about four times taller than a man. Its shape and design follow reference image 2 (a drawing used only as a design reference), but it is a real physical structure built from weathered wooden planks held by iron bolts, with four heavy wooden wheels.

DETAILS: the feast is over. Around the horse lie overturned clay wine jars, spilled wine, scattered flower garlands and bread. Two Trojan guards in leather armor sit asleep against a stone column on the left, spears leaning on their shoulders.

CAMERA: wide shot from a slightly high angle. Slow, smooth dolly push-in toward the belly of the horse for the whole 8 seconds. No cuts, no shaking.

TIMELINE:
- 0-5 s: everything is still. Only the campfire flames flicker and the sleeping guards breathe slowly.
- 5-8 s: a small square hatch on the underside of the horse's belly opens a little; a thin line of warm light shows from inside.

SOUND: only ambient night sounds: crackling embers, soft wind, crickets, a distant dog. No voices, no music with singing.

DO NOT: no people awake, no one walking, no fire on the buildings yet, no modern objects, no text.
```

## 컷 2 — 오디세우스가 내려옴 (첨부: ref1, ref2, 컷 1 마지막 프레임)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera, 35mm film grain, real skin texture and real materials (bronze, leather, wool, wood, rope). Night, cold blue moonlight, warm orange light from the hatch. NOT animation, NOT cartoon, NOT painting, NOT illustration, NOT video game graphics.

PLACE: under the belly of the giant wooden horse (shape from reference image 2, built from real weathered wood), in a moonlit stone plaza of ancient Troy.

CHARACTER (exactly 1 person in this shot): ODYSSEUS, played by a real human actor, about 40 years old, strong and battle-worn. His face, hair, beard and costume match reference image 1 (a drawing used only as a design reference; show him as a real person): curly dark brown hair, short dark beard with grey, no helmet, real hammered bronze breastplate with a Greek key pattern, deep red wool cape fastened with a round gold brooch, leather strip skirt over a white linen tunic, bronze shin guards, leather sandals. A short bronze sword in a sheath on his left hip.

CAMERA: medium shot from a low angle, looking up at the belly of the horse. Static camera, no cuts.

TIMELINE:
- 0-2 s: the square hatch on the horse's belly swings fully open downward.
- 2-3 s: a thick knotted rope drops from the hatch and hits the stone ground.
- 3-6 s: Odysseus climbs down the rope, hand over hand, facing the rope. His red cape hangs down behind him.
- 6-8 s: he lands softly on the ground in a low crouch, then turns his head left, then right, watching for guards. His mouth stays closed.

SOUND: creak of wood, rope sliding, soft thud of sandals on stone, crickets. No voices, no music with singing.

DO NOT: no other people, no fire, no running, no talking, do not change his face or clothes.
```

## 컷 3 — 부하 셋과 시논 (첨부: ref1, ref2, 컷 2 마지막 프레임)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no lip movement, no voice, no narration, no subtitles, no text. Communication only by hand signals and nods.

STYLE: photorealistic historical epic movie, shot on a cinema camera, 35mm film grain, real skin texture and real materials. Night, cold blue moonlight, small warm torch light. NOT animation, NOT cartoon, NOT painting, NOT illustration, NOT video game graphics.

PLACE: the moonlit stone plaza of Troy, next to the legs and wheels of the giant wooden horse (shape from reference image 2, built from real weathered wood). A rope hangs from an open hatch in the horse's belly.

CHARACTERS (exactly 5 real human actors in this shot):
1. ODYSSEUS — face, hair, beard and costume match reference image 1, shown as a real person (dark curly hair, beard, no helmet, bronze breastplate, RED cape). He is the only person with a red cape.
2. Greek soldier with a sword and a round bronze shield, bronze helmet, dark blue wool cloak.
3. Greek soldier with a long spear, bronze helmet, dark blue wool cloak.
4. Greek soldier with a wooden bow and a quiver of arrows, leather cap, dark blue wool cloak.
5. SINON — a thin Greek spy in a ragged brown hooded cloak, no armor, holding a small burning torch.

CAMERA: medium-wide shot at eye level, Odysseus in the front left. Static camera, no cuts.

TIMELINE:
- 0-5 s: Odysseus crouches in front, watching. Behind him, soldiers 2, 3 and 4 climb down the rope one after another and crouch beside him.
- 5-7 s: Sinon walks in quickly from the right side with his torch and kneels in front of Odysseus.
- 7-8 s: Odysseus nods once, then stretches his right arm and points forward, deeper into the city. Everyone's mouth stays closed.

SOUND: footsteps on stone, rope creak, torch fire crackling, crickets. No voices, no whispering, no music with singing.

DO NOT: no talking, no fighting, no fire on the buildings yet, no extra people, do not give anyone else a red cape.
```

## 컷 4 — 성문으로, 불타는 트로이 (첨부: ref1, ref2, 컷 3 마지막 프레임)

```
Photorealistic live-action film scene, 8 seconds, 16:9. NO DIALOGUE: no one speaks, no shouting, no lip movement, no voice, no narration, no subtitles, no text.

STYLE: photorealistic historical epic movie, shot on a cinema camera, 35mm film grain, real fire, real smoke and real materials. Night; the light changes from cold blue moonlight to orange firelight. NOT animation, NOT cartoon, NOT painting, NOT illustration, NOT video game graphics.

PLACE: a wide straight stone street in ancient Troy, white stone houses with flat roofs on both sides. At the far end of the street: a huge closed wooden city gate between two stone towers. The giant wooden horse (shape from reference image 2, built from real weathered wood) stands behind the group, close to the camera.

CHARACTERS (exactly 5 real human actors, all seen from behind): Odysseus in front (red cape, costume from reference image 1), behind him three Greek soldiers in bronze helmets and dark blue wool cloaks (sword and shield, long spear, bow), and Sinon in a brown hooded cloak with a torch.

CAMERA: starts low behind the group, looking toward the gate. Then a slow, smooth crane up and backward to a high wide view of the city. No cuts.

TIMELINE:
- 0-3 s: Odysseus draws his short bronze sword. The five run away from the camera down the street toward the far gate.
- 3-6 s: the camera rises up and back. The group becomes small figures running on the street.
- 6-8 s: orange flames burst from several rooftops on both sides of the street, thick smoke and sparks rise into the night sky. The whole city begins to burn. The group keeps running toward the gate.

SOUND: running footsteps, rising roar of fire, crackling wood, a low war drum. No voices, no screaming, no music with singing.

DO NOT: the gate stays closed, no fighting, no blood, no text, do not change Odysseus' red cape.
```
