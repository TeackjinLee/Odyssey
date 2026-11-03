/**
 * Meshy 등에서 만든 오디세우스 GLB 모델을 게임에 맞추는 설정.
 * 실제 모델을 넣은 뒤 브라우저 콘솔에 찍히는 [Odysseus GLB] 뼈·동작 이름을 보고 여기만 고치면 된다.
 * 자세한 순서: docs/legacy-web/odysseus-model.md
 */

export type BoneKey =
  | 'hips' | 'spine' | 'chest' | 'head'
  | 'rightArm' | 'rightForeArm' | 'rightHand'
  | 'leftArm' | 'leftForeArm' | 'leftHand'
  | 'leftUpLeg' | 'leftLeg' | 'leftFoot'
  | 'rightUpLeg' | 'rightLeg' | 'rightFoot';

export type ClipKey = 'idle' | 'walk' | 'run' | 'dash' | 'spear1' | 'spear2' | 'spear3' | 'parry' | 'bow';

/** 동작 파일 경로, 또는 한 파일의 일부 구간 (from~to: 동작 길이 대비 0~1) */
export type ClipFile = string | { url: string; from: number; to: number };

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
  /** 앞에 있는 파일부터 찾아 처음 읽힌 것을 씀 (Mixamo에서 With Skin으로 받은 FBX도 됨) */
  modelUrls: ['/assets/models/odysseus.glb', '/assets/models/odysseus.fbx'],

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
    leftUpLeg: ['leftupleg', 'thighl', 'leftupperleg'],
    leftLeg: ['leftleg', 'calfl', 'leftlowerleg'],
    leftFoot: ['leftfoot', 'footl'],
    rightUpLeg: ['rightupleg', 'thighr', 'rightupperleg'],
    rightLeg: ['rightleg', 'calfr', 'rightlowerleg'],
    rightFoot: ['rightfoot', 'footr'],
  } satisfies Record<BoneKey, string[]>,

  /**
   * 동작 이름 후보 (소문자로 바꿔 포함 여부로 찾고, 앞에 있는 것부터).
   * 맞는 동작이 없으면 그 상태는 도형 모델의 자세로 팔·상체를 보완한다.
   * 빈 배열이면 그 상태는 항상 보완 자세를 쓴다.
   */
  clips: {
    idle: ['idle', 'stand', 'breath'],
    walk: ['walk'],
    run: ['run', 'jog', 'sprint'],
    dash: ['roll', 'dodge', 'dash', 'evade'],
    spear1: [],
    spear2: [],
    spear3: [],
    parry: ['block', 'shield', 'guard'],
    bow: ['bow', 'archer', 'archery'],
  } satisfies Record<ClipKey, string[]>,

  /**
   * 동작별 파일. Mixamo에서 같은 캐릭터로 Without Skin 받은 FBX를 이 이름으로 넣으면 그 상태에 바로 연결된다.
   * 없는 파일은 건너뛰고, 모델 파일 안의 동작(위 clips 후보)이나 보완 자세를 쓴다.
   */
  clipFiles: {
    idle: '/assets/models/anims/idle.fbx',
    walk: '/assets/models/anims/walk.fbx',
    run: '/assets/models/anims/run.fbx',
    dash: '/assets/models/anims/dash.fbx',
    // Mixamo Great Sword Slash: 한 파일에 베기 세 번 (손이 가장 빠른 때 0.23·0.48·0.73) → 손이 멈추는 0.375·0.625에서 자름
    spear1: { url: '/assets/models/anims/spear-combo.fbx', from: 0, to: 0.375 },
    spear2: { url: '/assets/models/anims/spear-combo.fbx', from: 0.375, to: 0.625 },
    spear3: { url: '/assets/models/anims/spear-combo.fbx', from: 0.625, to: 1 },
    parry: '/assets/models/anims/parry.fbx',
    bow: '/assets/models/anims/bow.fbx',
  } satisfies Record<ClipKey, ClipFile>,

  /** 걷기·달리기 동작을 1배속으로 틀 때 나아가는 속도. In Place 동작일 때만 씀 (아니면 골반 이동으로 자동 계산) */
  walkClipSpeed: 1.6,
  runClipSpeed: 5.5,

  /**
   * 창 공격 동작 파일이 없을 때 다리 IK로 만드는 디딤 자세 (게임 단위, 몸 기준).
   * front: 왼발을 앞으로, back: 오른발을 뒤로, width: 두 발 좌우 간격의 절반, drop: 골반을 낮추는 높이
   */
  attackStance: {
    1: { front: 0.3, back: 0.25, width: 0.2, drop: 0.1 },
    2: { front: 0.45, back: 0.35, width: 0.22, drop: 0.15 },
    3: { front: 0.6, back: 0.5, width: 0.3, drop: 0.24 },
  } as Record<1 | 2 | 3, { front: number; back: number; width: number; drop: number }>,
  /**
   * 공격 동작에서 실제로 맞는 순간의 위치 (동작 길이 대비 0~1).
   * 준비 구간은 0~이 값, 휘두르기는 이 값 앞뒤, 회복은 그 뒤로 맞춰 재생한다.
   */
  attackHitTime: { spear1: 0.6, spear2: 0.4, spear3: 0.28, parry: 0.3 },

  weapons: {
    // 주무기. 지금은 청동 검 (게임 상태 이름이 spear_*라 키는 spear 그대로)
    // Mixamo 오른손 뼈: +Y 손가락, +X 검지·엄지 쪽, +Z 손바닥 쪽 → 날(+Y)을 +X로 돌려 주먹 엄지 쪽으로 나오게
    spear: {
      url: '/assets/models/sword.glb',
      bone: 'rightHand',
      size: 1.5,
      position: [0, 0.08, 0.05],
      rotation: [0, 0, -90],
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

  /**
   * 동작 파일을 틀 때 공격 밖(대기·이동)에서 주무기가 향할 방향 (몸 기준, +Y 위·+Z 앞·-X 오른쪽).
   * 맨손 동작이라 손 방향 그대로면 검이 앞으로 뻗으므로, 앞 아래로 비스듬히 내려 듦. null이면 손 방향 그대로
   */
  spearIdleDir: [-0.15, -0.55, 0.8] as [number, number, number] | null,
  /** 주무기 파일에서 손이 쥐는 자리 (무기 길이 대비, 아래 끝에서부터 0~1) */
  spearGrip: 0.12,
  /** 활시위를 코드로 그려 당길지 (활 파일에 시위가 이미 있으면 false) */
  drawBowString: true,
};
