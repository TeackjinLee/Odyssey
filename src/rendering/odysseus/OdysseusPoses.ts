/**
 * 오디세우스 자세 데이터.
 * 자세는 숫자 묶음이라 두 자세를 섞으면(lerp) 그 사이 동작이 된다.
 * 손 위치·창 방향·방패 방향은 body 공간(+Z 앞, -X 오른쪽, y는 땅에서 높이) 값이고,
 * 나머지는 관절 각도(라디안)다. 다리 각도는 +가 뒤로, 무릎은 +가 굽힘.
 */

export const POSE_KEYS = [
  'hipY', 'hipYaw', 'hipRoll', 'spinePitch', 'spineYaw', 'spineRoll', 'headPitch',
  'thighR', 'kneeR', 'ankleR', 'thighL', 'kneeL', 'ankleL', 'spreadR', 'spreadL',
  'handRx', 'handRy', 'handRz', 'spearX', 'spearY', 'spearZ', 'spearSlide',
  'handLx', 'handLy', 'handLz', 'shieldX', 'shieldY', 'shieldZ',
  'stow',
] as const;

export type PoseKey = (typeof POSE_KEYS)[number];
export type Pose = Record<PoseKey, number>;

/** 다리와 골반 높이: 공격 중 걸을 때 이 부분만 걷는 자세로 덮음 */
export const LEG_KEYS: PoseKey[] = [
  'hipY', 'thighR', 'kneeR', 'ankleR', 'thighL', 'kneeL', 'ankleL', 'spreadR', 'spreadL',
];

const IDLE: Pose = {
  hipY: 0, hipYaw: 0, hipRoll: 0, spinePitch: 0.05, spineYaw: 0, spineRoll: 0, headPitch: 0,
  thighR: 0.06, kneeR: 0.14, ankleR: -0.08, thighL: -0.1, kneeL: 0.12, ankleL: -0.02,
  spreadR: -0.09, spreadL: 0.09,
  handRx: -0.38, handRy: 1.1, handRz: 0.16, spearX: 0, spearY: 1, spearZ: 0.1, spearSlide: 0,
  handLx: 0.37, handLy: 1.06, handLz: 0.2, shieldX: 0.6, shieldY: 0, shieldZ: 0.8,
  stow: 0,
};

const pose = (over: Partial<Pose>): Pose => ({ ...IDLE, ...over });

export function copyPose(src: Pose, dst: Pose = { ...src }): Pose {
  for (const k of POSE_KEYS) dst[k] = src[k];
  return dst;
}

export function lerpPose(a: Pose, b: Pose, t: number, out: Pose = { ...a }): Pose {
  for (const k of POSE_KEYS) out[k] = a[k] + (b[k] - a[k]) * t;
  return out;
}

export const ease = {
  outCubic: (t: number): number => 1 - Math.pow(1 - t, 3),
  inOutSine: (t: number): number => 0.5 - 0.5 * Math.cos(Math.PI * t),
  outBack: (t: number): number => {
    const c = 1.4;
    return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2);
  },
};

export function idlePose(time: number): Pose {
  // 숨쉬기와 무게중심이 살짝 옮겨가는 대기 자세
  const breath = Math.sin(time * 2.2);
  const sway = Math.sin(time * 0.9);
  return pose({
    hipY: -0.015 + breath * 0.008,
    hipRoll: sway * 0.025,
    spinePitch: 0.05 + breath * 0.02,
    spineRoll: -sway * 0.02,
    handRy: 1.1 + breath * 0.01,
    handLy: 1.06 + breath * 0.01,
  });
}

/** 달리기 한 주기(phase 0~2π) 자세 */
export function runPose(phase: number): Pose {
  const s = Math.sin(phase);
  const c = Math.cos(phase);
  return pose({
    hipY: -0.045 + 0.045 * Math.cos(2 * phase),
    hipYaw: 0.18 * s,
    hipRoll: 0.04 * c,
    spinePitch: 0.24,
    spineYaw: -0.3 * s,
    spineRoll: -0.03 * c,
    headPitch: -0.14,
    thighR: -0.85 * s,
    kneeR: 0.25 + 1.25 * Math.max(0, c),
    ankleR: -0.1 + 0.4 * Math.max(0, -s),
    thighL: 0.85 * s,
    kneeL: 0.25 + 1.25 * Math.max(0, -c),
    ankleL: -0.1 + 0.4 * Math.max(0, s),
    spreadR: -0.05,
    spreadL: 0.05,
    // 창은 앞으로 기울여 들고, 팔은 다리와 엇갈려 흔듦
    handRx: -0.36, handRy: 1.12 + 0.03 * Math.cos(2 * phase), handRz: 0.22 - 0.09 * s,
    spearX: -0.05, spearY: 0.8, spearZ: 0.6,
    handLx: 0.34, handLy: 1.1, handLz: 0.24 + 0.09 * s,
    shieldX: 0.45, shieldY: 0, shieldZ: 0.9,
  });
}

export const DASH_POSE = pose({
  hipY: -0.14, spinePitch: 0.5, headPitch: -0.35,
  thighR: -1.0, kneeR: 0.9, ankleR: -0.2, thighL: 0.75, kneeL: 0.55, ankleL: 0.5,
  handRx: -0.4, handRy: 0.98, handRz: -0.2, spearX: -0.05, spearY: 0.25, spearZ: -1,
  handLx: 0.3, handLy: 1.08, handLz: 0.3, shieldX: 0.3, shieldY: 0, shieldZ: 1,
});

export const PARRY_POSE = pose({
  hipY: -0.1, spinePitch: 0.14, spineYaw: 0.3,
  thighR: 0.3, kneeR: 0.3, thighL: -0.35, kneeL: 0.38,
  handRx: -0.42, handRy: 1.05, handRz: -0.12, spearX: -0.2, spearY: 0.9, spearZ: -0.3,
  handLx: 0.12, handLy: 1.32, handLz: 0.56, shieldX: 0.05, shieldY: 0.1, shieldZ: 1,
});

export function bowPose(charge: number): Pose {
  // 왼쪽 어깨를 앞으로 내밀고 오른손으로 시위를 당김 (창·방패는 등으로)
  return pose({
    hipY: -0.05, spinePitch: 0.05, spineYaw: -0.75,
    thighR: 0.22, kneeR: 0.2, thighL: -0.22, kneeL: 0.2, spreadR: -0.18, spreadL: 0.18,
    handLx: 0.12, handLy: 1.5, handLz: 0.66,
    handRx: -0.04, handRy: 1.56, handRz: 0.14 - 0.24 * charge,
    stow: 1,
  });
}

/** 회복 끝에 돌아가는 전투 대기 자세 */
const READY = pose({
  hipY: -0.04, spinePitch: 0.1,
  handRx: -0.33, handRy: 1.12, handRz: 0.26, spearX: -0.05, spearY: 0.72, spearZ: 0.68,
});

interface AttackKeys {
  windup: Pose; // 힘을 모은 끝 자세
  mid: Pose; // 휘두르는 도중
  strike: Pose; // 휘두른 끝 자세
}

const ATTACKS: Record<1 | 2 | 3, AttackKeys> = {
  // 1타: 오른쪽에서 왼쪽으로 크게 가로베기
  1: {
    windup: pose({
      hipY: -0.06, hipYaw: -0.25, spineYaw: -0.6, spinePitch: 0.1,
      thighR: 0.25, kneeR: 0.3, thighL: -0.3, kneeL: 0.35,
      handRx: -0.62, handRy: 1.22, handRz: -0.05, spearX: -0.92, spearY: 0.12, spearZ: 0.38,
      handLx: 0.32, handLy: 1.18, handLz: 0.3, shieldX: 0.4, shieldZ: 0.9,
    }),
    mid: pose({
      hipY: -0.1, spinePitch: 0.2,
      thighR: 0.4, kneeR: 0.3, thighL: -0.5, kneeL: 0.45,
      handRx: -0.15, handRy: 1.15, handRz: 0.6, spearX: 0, spearY: 0, spearZ: 1,
      handLx: 0.38, handLy: 1.12, handLz: 0.12, shieldX: 0.8, shieldZ: 0.6,
    }),
    strike: pose({
      hipY: -0.1, hipYaw: 0.2, spineYaw: 0.5, spinePitch: 0.18,
      thighR: 0.4, kneeR: 0.3, thighL: -0.5, kneeL: 0.45,
      handRx: 0.3, handRy: 1.1, handRz: 0.45, spearX: 0.92, spearY: -0.08, spearZ: 0.35,
      handLx: 0.4, handLy: 1.1, handLz: -0.05, shieldX: 0.95, shieldZ: 0.2,
    }),
  },
  // 2타: 창을 뒤로 당겼다가 곧게 찌르기 (창이 손 안에서 앞으로 미끄러짐)
  2: {
    windup: pose({
      hipY: -0.08, hipYaw: -0.2, spineYaw: -0.5, spinePitch: -0.05,
      thighR: 0.3, kneeR: 0.3, thighL: -0.3, kneeL: 0.3,
      handRx: -0.32, handRy: 1.3, handRz: -0.3, spearX: 0.04, spearY: 0.04, spearZ: 1, spearSlide: -0.25,
      handLx: 0.3, handLy: 1.2, handLz: 0.35, shieldX: 0.3, shieldZ: 1,
    }),
    mid: pose({
      hipY: -0.12, hipYaw: 0, spineYaw: -0.05, spinePitch: 0.15,
      thighR: 0.45, kneeR: 0.25, thighL: -0.55, kneeL: 0.5,
      handRx: -0.15, handRy: 1.3, handRz: 0.3, spearX: 0.03, spearY: 0, spearZ: 1, spearSlide: 0.1,
      handLx: 0.4, handLy: 1.15, handLz: 0.1, shieldX: 0.7, shieldZ: 0.7,
    }),
    strike: pose({
      hipY: -0.15, hipYaw: 0.15, spineYaw: 0.25, spinePitch: 0.32,
      thighR: 0.55, kneeR: 0.2, ankleR: 0.3, thighL: -0.7, kneeL: 0.6,
      handRx: -0.06, handRy: 1.28, handRz: 0.7, spearX: 0.03, spearY: -0.03, spearZ: 1, spearSlide: 0.35,
      handLx: 0.42, handLy: 1.15, handLz: 0, shieldX: 0.9, shieldZ: 0.3,
    }),
  },
  // 3타: 몸을 낮게 비틀었다가 창을 옆으로 뻗고 한 바퀴 회전베기
  3: {
    windup: pose({
      hipY: -0.22, hipYaw: -0.45, spineYaw: -0.9, spinePitch: 0.28,
      thighR: 0.35, kneeR: 0.7, thighL: -0.4, kneeL: 0.7, spreadR: -0.25, spreadL: 0.25,
      handRx: -0.62, handRy: 1.0, handRz: -0.4, spearX: -0.7, spearY: 0.05, spearZ: -0.7,
      handLx: 0.35, handLy: 1.2, handLz: 0.3, shieldX: 0.3, shieldZ: 1,
    }),
    mid: pose({
      hipY: -0.12, spinePitch: 0.15,
      thighR: 0.15, kneeR: 0.4, thighL: -0.15, kneeL: 0.4, spreadR: -0.18, spreadL: 0.18,
      handRx: -0.62, handRy: 1.2, handRz: 0.15, spearX: -0.97, spearY: 0.05, spearZ: 0.22,
      handLx: 0.35, handLy: 1.15, handLz: -0.1, shieldX: 0.8, shieldZ: -0.4,
    }),
    strike: pose({
      hipY: -0.18, spinePitch: 0.3,
      thighR: 0.45, kneeR: 0.35, thighL: -0.55, kneeL: 0.6,
      handRx: -0.35, handRy: 1.05, handRz: 0.55, spearX: -0.35, spearY: -0.2, spearZ: 0.9,
      handLx: 0.4, handLy: 1.15, handLz: 0.1, shieldX: 0.8, shieldZ: 0.5,
    }),
  },
};

/** 3타 회전이 이어지는 구간: 휘두르기 전체 + 회복 앞 40% */
export const SPIN_RECOVERY_SHARE = 0.4;

export interface AttackFrame {
  pose: Pose;
  /** 현재 자세가 목표 자세를 따라붙는 빠르기 */
  rate: number;
  /** 3타 회전 각도 (0~2π) */
  spin: number;
  /** 창 궤적을 그릴지 */
  trail: boolean;
}

const scratch = { ...IDLE };

/**
 * 창 공격 한 순간의 자세.
 * phase: 'windup' | 'swing' | 'recovery', t: 그 구간 안 진행도(0~1),
 * spinT: 3타 회전 진행도(0~1)
 */
export function attackFrame(
  step: 1 | 2 | 3,
  phase: 'windup' | 'swing' | 'recovery',
  t: number,
  spinT: number
): AttackFrame {
  const keys = ATTACKS[step];
  const spin = step === 3 ? Math.PI * 2 * ease.outCubic(Math.min(1, spinT)) : 0;

  if (phase === 'windup') {
    return { pose: keys.windup, rate: 30, spin: 0, trail: false };
  }
  if (phase === 'swing') {
    const e = ease.outCubic(t);
    if (step === 3) lerpPose(keys.windup, keys.mid, e, scratch);
    else if (e < 0.5) lerpPose(keys.windup, keys.mid, e * 2, scratch);
    else lerpPose(keys.mid, keys.strike, (e - 0.5) * 2, scratch);
    return { pose: scratch, rate: 90, spin, trail: true };
  }
  if (step === 3 && t < SPIN_RECOVERY_SHARE) {
    lerpPose(keys.mid, keys.strike, ease.inOutSine(t / SPIN_RECOVERY_SHARE), scratch);
    return { pose: scratch, rate: 60, spin, trail: true };
  }
  const start = step === 3 ? SPIN_RECOVERY_SHARE : 0;
  const rt = ease.inOutSine(Math.min(1, (t - start) / (1 - start)));
  lerpPose(keys.strike, READY, rt, scratch);
  return { pose: scratch, rate: 22, spin, trail: t < 0.25 };
}
