import * as THREE from 'three';
import { COMBAT_CONFIG } from '../../data/combatConfig';
import { PlayerEntity } from '../../types/combat';
import { AvatarMotion, approach, clamp } from './AvatarMotion';
import {
  DASH_POSE,
  LEG_KEYS,
  PARRY_POSE,
  Pose,
  SPIN_RECOVERY_SHARE,
  attackFrame,
  bowPose,
  copyPose,
  idlePose,
  lerpPose,
  runPose,
} from './OdysseusPoses';

export type SpearPhase = 'windup' | 'swing' | 'recovery';

/** 창 공격 한 순간: 몇 타의 어느 구간을 얼마나 지났는지 */
export interface SpearProgress {
  step: 1 | 2 | 3;
  phase: SpearPhase;
  t: number;
}

export function spearProgress(p: PlayerEntity): SpearProgress | null {
  if (p.state !== 'spear_windup' && p.state !== 'spear_swing' && p.state !== 'spear_recovery') return null;
  const cfg = COMBAT_CONFIG.player.spear.steps[p.comboStep];
  const phase: SpearPhase = p.state === 'spear_windup' ? 'windup' : p.state === 'spear_swing' ? 'swing' : 'recovery';
  const duration = phase === 'windup' ? cfg.windup : phase === 'swing' ? cfg.active : cfg.recovery;
  return { step: p.comboStep, phase, t: clamp(1 - p.stateTimer / duration, 0, 1) };
}

/**
 * PlayerEntity 상태에 맞는 자세(OdysseusPoses)를 골라 부드럽게 섞는다.
 * 도형 모델은 이 자세를 그대로 몸에 입히고, GLB 모델은 맞는 동작 파일이 없을 때 이 자세로 팔·상체를 보완한다.
 */
export class PoseDriver {
  public readonly current: Pose;
  /** 3타 회전베기의 몸 회전 각도 */
  public spin = 0;
  /** 창 궤적을 그릴지 */
  public trail = false;

  private readonly target: Pose;
  private readonly loco: Pose;
  private time = 0;
  private lastState = '';
  private transitionTimer = 0;

  constructor() {
    this.current = copyPose(idlePose(0));
    this.target = copyPose(this.current);
    this.loco = copyPose(this.current);
  }

  public update(p: PlayerEntity, motion: AvatarMotion, dt: number): void {
    this.time += dt;
    const runWeight = THREE.MathUtils.smoothstep(motion.speed, 0.4, 4.5);
    lerpPose(idlePose(this.time), runPose(motion.runPhase), runWeight, this.loco);

    if (p.state !== this.lastState) {
      this.lastState = p.state;
      this.transitionTimer = 0.18;
    }
    this.transitionTimer = Math.max(0, this.transitionTimer - dt);

    const { rate, legsFromLoco } = this.chooseTarget(p, runWeight);
    if (legsFromLoco > 0) {
      for (const k of LEG_KEYS) this.target[k] += (this.loco[k] - this.target[k]) * legsFromLoco;
    }
    if (p.hitFlashTimer > 0) {
      const flinch = Math.min(1, p.hitFlashTimer * 5);
      this.target.spinePitch -= 0.3 * flinch;
      this.target.hipY -= 0.05 * flinch;
    }
    lerpPose(this.current, this.target, approach(rate, dt), this.current);
  }

  private chooseTarget(p: PlayerEntity, runWeight: number): { rate: number; legsFromLoco: number } {
    this.spin = 0;
    this.trail = false;
    const spear = spearProgress(p);
    if (spear) {
      const cfg = COMBAT_CONFIG.player.spear.steps[spear.step];
      const spinSpan = cfg.active + cfg.recovery * SPIN_RECOVERY_SHARE;
      const spinT =
        spear.phase === 'windup'
          ? 0
          : spear.phase === 'swing'
            ? (cfg.active * spear.t) / spinSpan
            : (cfg.active + cfg.recovery * spear.t) / spinSpan;
      const frame = attackFrame(spear.step, spear.phase, spear.t, spinT);
      copyPose(frame.pose, this.target);
      this.spin = frame.spin;
      this.trail = frame.trail;
      return { rate: frame.rate, legsFromLoco: spear.phase === 'recovery' ? runWeight : 0 };
    }
    switch (p.state) {
      case 'dash':
        copyPose(DASH_POSE, this.target);
        return { rate: 30, legsFromLoco: 0 };
      case 'parry_active':
      case 'parry_recovery':
        copyPose(PARRY_POSE, this.target);
        return { rate: 30, legsFromLoco: runWeight };
      case 'bow_charge':
      case 'bow_recovery':
        copyPose(bowPose(p.state === 'bow_charge' ? p.bowCharge : 0), this.target);
        return { rate: 18, legsFromLoco: runWeight };
      default:
        copyPose(this.loco, this.target);
        // 동작이 막 끝났을 때만 천천히 섞고, 걷는 중에는 걷기 자세를 그대로 따라감
        return { rate: this.transitionTimer > 0 ? 14 : 60, legsFromLoco: 0 };
    }
  }
}
