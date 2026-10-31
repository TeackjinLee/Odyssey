/**
 * Meshy 등에서 만든 오디세우스 GLB 모델을 게임에 맞추는 설정.
 * 실제 모델을 넣은 뒤 브라우저 콘솔에 찍히는 [Odysseus GLB] 뼈·동작 이름을 보고 여기만 고치면 된다.
 * 자세한 순서: docs/odysseus-model.md
 */

export type BoneKey =
  | 'hips' | 'spine' | 'chest' | 'head'
  | 'rightArm' | 'rightForeArm' | 'rightHand'
  | 'leftArm' | 'leftForeArm' | 'leftHand';

export type ClipKey = 'idle' | 'run' | 'dash' | 'spear1' | 'spear2' | 'spear3' | 'parry' | 'bow';

export type WeaponKey = 'spear' | 'shield' | 'bow';

export interface WeaponMount {
  /** 무기 GLB 경로 (없으면 도형 무기를 씀) */
  url: string;
  /** 붙일 뼈 */
  bone: BoneKey;
  /** 무기의 가장 긴 변을 이 길이(게임 단위)로 맞춤 */
  size: number;
  /** 뼈 기준 위치 (게임 단위) */
  position: [number, number, number];
  /** 뼈 기준 회전 (도, XYZ 순) */
  rotation: [number, number, number];
  /** 무기 파일을 정렬한 뒤 앞뒤가 반대면 true (창끝이 손잡이 쪽에 오는 경우) */
  flip: boolean;
}

export const AVATAR_CONFIG = {
  modelUrl: '/assets/models/odysseus.glb',

  /** 게임 안 키 (머리끝까지, 게임 단위). 도형 모델은 약 2.6 */
  height: 2.6,
  /** 모델이 +Z를 보지 않을 때 더 돌릴 각도 (도). Meshy는 +Z를 봄 */
  yawOffsetDeg: 0,

  /**
   * 'unlit': 텍스처 색을 조명 없이 그대로 (그림처럼 보임, 씬마다 밝기가 같음)
   * 'toon': 3단 명암 / 'original': 파일의 재료 그대로 (씬 조명에 따라 밝기가 달라짐)
   */
  shading: 'unlit' as 'unlit' | 'toon' | 'original',
  /** 외곽선 두께 (게임 단위, 0이면 없음) */
  outline: 0.02,

  /**
   * 뼈 이름 후보. 대소문자·'mixamorig' 접두사·기호를 빼고 비교하며, 앞에 있는 것부터 찾는다.
   * Meshy 기본 뼈대는 Mixamo 이름(mixamorig:RightHand 등)을 쓴다.
   */
  bones: {
    hips: ['hips', 'pelvis'],
    spine: ['spine', 'spine01'],
    chest: ['spine2', 'spine1', 'chest', 'spine02', 'upperchest'],
    head: ['head'],
    rightArm: ['rightarm', 'upperarmr', 'rupperarm', 'rightupperarm'],
    rightForeArm: ['rightforearm', 'lowerarmr', 'rforearm', 'rightlowerarm'],
    rightHand: ['righthand', 'handr', 'rhand'],
    leftArm: ['leftarm', 'upperarml', 'lupperarm', 'leftupperarm'],
    leftForeArm: ['leftforearm', 'lowerarml', 'lforearm', 'leftlowerarm'],
    leftHand: ['lefthand', 'handl', 'lhand'],
  } satisfies Record<BoneKey, string[]>,

  /**
   * 동작 이름 후보 (소문자로 바꿔 포함 여부로 찾고, 앞에 있는 것부터).
   * 맞는 동작이 없으면 그 상태는 도형 모델의 자세로 팔·상체를 보완한다.
   * 빈 배열이면 그 상태는 항상 보완 자세를 쓴다.
   */
  clips: {
    idle: ['idle', 'stand', 'breath'],
    run: ['run', 'jog', 'sprint', 'walk'],
    dash: ['roll', 'dodge', 'dash', 'evade'],
    spear1: [],
    spear2: [],
    spear3: [],
    parry: ['block', 'shield', 'guard'],
    bow: ['bow', 'archer', 'archery'],
  } satisfies Record<ClipKey, string[]>,

  /** 달리기 동작을 1배속으로 틀 때 나아가는 속도 (발이 미끄러지면 조정) */
  runClipSpeed: 5.5,
  /**
   * 공격 동작에서 실제로 맞는 순간의 위치 (동작 길이 대비 0~1).
   * 준비 구간은 0~이 값, 휘두르기는 이 값 앞뒤, 회복은 그 뒤로 맞춰 재생한다.
   */
  attackHitTime: { spear1: 0.4, spear2: 0.4, spear3: 0.45, parry: 0.3 },

  weapons: {
    spear: {
      url: '/assets/models/spear.glb',
      bone: 'rightHand',
      size: 2.9,
      position: [0, 0.08, 0.02],
      rotation: [90, 0, 0],
      flip: false,
    },
    shield: {
      url: '/assets/models/shield.glb',
      bone: 'leftForeArm',
      size: 0.9,
      position: [0.12, 0.2, 0],
      rotation: [0, 90, 0],
      flip: false,
    },
    bow: {
      url: '/assets/models/bow.glb',
      bone: 'leftHand',
      size: 1.0,
      position: [0, 0.06, 0],
      rotation: [0, 0, 0],
      flip: false,
    },
  } satisfies Record<WeaponKey, WeaponMount>,

  /** 창에서 손이 쥐는 자리 (창 길이 대비, 끝에서부터 0~1) */
  spearGrip: 0.35,
  /** 활시위를 코드로 그려 당길지 (활 파일에 시위가 이미 있으면 false) */
  drawBowString: true,
};
