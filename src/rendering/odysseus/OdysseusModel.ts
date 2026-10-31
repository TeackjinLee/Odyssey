import * as THREE from 'three';
import { COMBAT_CONFIG } from '../../data/combatConfig';
import { PlayerEntity, Vec2 } from '../../types/combat';
import { CapeCloth } from './CapeCloth';
import { HIP_HEIGHT, MODEL_SCALE, OdysseusRig, PALETTE, SPEAR_HEAD_LENGTH, SPEAR_TIP } from './OdysseusRig';
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
import { SpearTrail } from './SpearTrail';
import { ToonMaterialKit } from './ToonMaterials';

/** 달리기 한 주기(두 걸음) 동안 나아가는 거리 — 발이 미끄러져 보이지 않게 속도에 맞춤 */
const STRIDE = 2.5;
const UP = new THREE.Vector3(0, 1, 0);
const FRONT = new THREE.Vector3(0, 0, 1);
const SPEAR_BACK_SLOT = new THREE.Vector3(0.05, 1.35, -0.3);
const SPEAR_BACK_DIR = new THREE.Vector3(-0.45, 0.85, -0.15).normalize();
const SHIELD_BACK_SLOT = new THREE.Vector3(0, 1.22, -0.36);
const SHIELD_BACK_DIR = new THREE.Vector3(0, 0, -1);
const POLE_R = new THREE.Vector3(-0.6, -0.4, -1);
const POLE_L = new THREE.Vector3(0.6, -0.4, -1);

const wrapAngle = (a: number): number => Math.atan2(Math.sin(a), Math.cos(a));
const clamp = (v: number, lo: number, hi: number): number => Math.max(lo, Math.min(hi, v));
const approach = (rate: number, dt: number): number => 1 - Math.exp(-rate * dt);

/**
 * 오디세우스 3D 모델: 시뮬레이션의 PlayerEntity를 읽어 매 프레임 자세를 정하고 그린다.
 * - 걸을 때는 가는 쪽을 보고, 공격·활·패링 때만 조준(facingAngle) 쪽으로 몸을 돌린다.
 * - 팔은 2관절 IK로 창·방패를 쥔 손 위치에 닿게 한다.
 */
export class OdysseusModel {
  /** 이번 프레임에 땅을 디딘 발 위치 (먼지 효과용) */
  public readonly footsteps: Vec2[] = [];

  private readonly kit = new ToonMaterialKit();
  private readonly rig: OdysseusRig;
  private readonly cape: CapeCloth;
  private readonly trail = new SpearTrail();

  private readonly current: Pose;
  private readonly target: Pose;
  private readonly loco: Pose;

  private bodyAngle = -Math.PI / 2;
  private runPhase = 0;
  private time = 0;
  private prevVx = 0;
  private prevVz = 0;
  private leanForward = 0;
  private leanSide = 0;
  private lastState = '';
  private transitionTimer = 0;

  private readonly v1 = new THREE.Vector3();
  private readonly v2 = new THREE.Vector3();
  private readonly v3 = new THREE.Vector3();
  private readonly v4 = new THREE.Vector3();
  private readonly v5 = new THREE.Vector3();
  private readonly v6 = new THREE.Vector3();
  private readonly m = new THREE.Matrix4();
  private readonly q1 = new THREE.Quaternion();
  private readonly q2 = new THREE.Quaternion();
  private readonly gripR = new THREE.Vector3();
  private readonly gripL = new THREE.Vector3();
  private readonly capeAnchorsWorld: THREE.Vector3[];

  constructor(scene: THREE.Scene) {
    this.rig = new OdysseusRig(this.kit);
    this.cape = new CapeCloth(this.kit.surface(PALETTE.cape, { doubleSide: true }), MODEL_SCALE);
    this.capeAnchorsWorld = this.rig.capeAnchors.map(() => new THREE.Vector3());
    this.current = copyPose(idlePose(0));
    this.target = copyPose(this.current);
    this.loco = copyPose(this.current);

    scene.add(this.rig.root);
    scene.add(this.cape.mesh);
    scene.add(this.trail.mesh);
  }

  public update(p: PlayerEntity, dt: number): void {
    this.footsteps.length = 0;
    // 히트스톱 중에는 모든 움직임이 멈춤
    if (dt <= 0) return;
    this.time += dt;

    const speed = Math.hypot(p.vx, p.vz);
    this.updateFacing(p, speed, dt);
    this.updateLean(p, dt);
    this.updateRunPhase(p, speed, dt);

    const runWeight = THREE.MathUtils.smoothstep(speed, 0.4, 4.5);
    lerpPose(idlePose(this.time), runPose(this.runPhase), runWeight, this.loco);

    const { rate, spin, trail, legsFromLoco } = this.chooseTarget(p, runWeight, dt);
    if (legsFromLoco > 0) {
      for (const k of LEG_KEYS) this.target[k] += (this.loco[k] - this.target[k]) * legsFromLoco;
    }
    if (p.hitFlashTimer > 0) {
      const flinch = Math.min(1, p.hitFlashTimer * 5);
      this.target.spinePitch -= 0.3 * flinch;
      this.target.hipY -= 0.05 * flinch;
    }
    lerpPose(this.current, this.target, approach(rate, dt), this.current);

    this.applyPose(p, spin);
    this.placeArmsAndGear();
    this.updateCape(dt);
    this.updateTrail(p, dt, trail);
    this.kit.flash.value = Math.min(1, p.hitFlashTimer * 5) * 0.75;
  }

  private updateFacing(p: PlayerEntity, speed: number, dt: number): void {
    let target = this.bodyAngle;
    let rate = 16;
    if (p.state === 'dash') {
      target = Math.atan2(p.dashDirZ, p.dashDirX);
      rate = 40;
    } else if (p.state !== 'idle' && p.state !== 'move') {
      // 공격·활·패링: 조준한 쪽으로 빠르게 몸을 돌림
      target = p.facingAngle;
      rate = 40;
    } else if (speed > 0.5) {
      target = Math.atan2(p.vz, p.vx);
    }
    this.bodyAngle = wrapAngle(this.bodyAngle + wrapAngle(target - this.bodyAngle) * approach(rate, dt));
  }

  /** 속도가 바뀌는 쪽으로 몸이 기울어짐 (출발할 때 앞으로, 멈출 때 뒤로, 돌 때 안쪽으로) */
  private updateLean(p: PlayerEntity, dt: number): void {
    const ax = (p.vx - this.prevVx) / dt;
    const az = (p.vz - this.prevVz) / dt;
    this.prevVx = p.vx;
    this.prevVz = p.vz;
    if (p.state === 'dash' || p.state === 'spear_swing') return;
    const fx = Math.cos(this.bodyAngle);
    const fz = Math.sin(this.bodyAngle);
    const forwardAccel = ax * fx + az * fz;
    const sideAccel = ax * -fz + az * fx;
    const k = approach(10, dt);
    this.leanForward += (clamp(forwardAccel * 0.006, -0.18, 0.2) - this.leanForward) * k;
    this.leanSide += (clamp(-sideAccel * 0.005, -0.15, 0.15) - this.leanSide) * k;
  }

  private updateRunPhase(p: PlayerEntity, speed: number, dt: number): void {
    const before = Math.floor((this.runPhase - Math.PI / 2) / Math.PI);
    this.runPhase += (speed * dt * Math.PI * 2) / STRIDE;
    const after = Math.floor((this.runPhase - Math.PI / 2) / Math.PI);
    if (after !== before && speed > 3 && p.state !== 'dash') {
      this.footsteps.push({ x: p.x, z: p.z });
    }
    if (speed < 0.3) this.runPhase = 0;
  }

  private chooseTarget(
    p: PlayerEntity,
    runWeight: number,
    dt: number
  ): { rate: number; spin: number; trail: boolean; legsFromLoco: number } {
    if (p.state !== this.lastState) {
      this.lastState = p.state;
      this.transitionTimer = 0.18;
    }
    this.transitionTimer = Math.max(0, this.transitionTimer - dt);

    switch (p.state) {
      case 'spear_windup':
      case 'spear_swing':
      case 'spear_recovery': {
        const step = p.comboStep;
        const cfg = COMBAT_CONFIG.player.spear.steps[step];
        const phase = p.state === 'spear_windup' ? 'windup' : p.state === 'spear_swing' ? 'swing' : 'recovery';
        const duration = phase === 'windup' ? cfg.windup : phase === 'swing' ? cfg.active : cfg.recovery;
        const t = clamp(1 - p.stateTimer / duration, 0, 1);
        const spinSpan = cfg.active + cfg.recovery * SPIN_RECOVERY_SHARE;
        const spinT =
          phase === 'windup' ? 0 : phase === 'swing' ? (cfg.active * t) / spinSpan : (cfg.active + cfg.recovery * t) / spinSpan;
        const frame = attackFrame(step, phase, t, spinT);
        copyPose(frame.pose, this.target);
        this.trail.setColor(step === 3 ? '#fb923c' : '#fde68a');
        return { rate: frame.rate, spin: frame.spin, trail: frame.trail, legsFromLoco: phase === 'recovery' ? runWeight : 0 };
      }
      case 'dash':
        copyPose(DASH_POSE, this.target);
        return { rate: 30, spin: 0, trail: false, legsFromLoco: 0 };
      case 'parry_active':
      case 'parry_recovery':
        copyPose(PARRY_POSE, this.target);
        return { rate: 30, spin: 0, trail: false, legsFromLoco: runWeight };
      case 'bow_charge':
      case 'bow_recovery':
        copyPose(bowPose(p.state === 'bow_charge' ? p.bowCharge : 0), this.target);
        return { rate: 18, spin: 0, trail: false, legsFromLoco: runWeight };
      default:
        copyPose(this.loco, this.target);
        // 동작이 막 끝났을 때만 천천히 섞고, 걷는 중에는 걷기 자세를 그대로 따라감
        return { rate: this.transitionTimer > 0 ? 14 : 60, spin: 0, trail: false, legsFromLoco: 0 };
    }
  }

  private applyPose(p: PlayerEntity, spin: number): void {
    const r = this.rig;
    const c = this.current;

    r.root.position.set(p.x, 0, p.z);
    r.root.rotation.y = Math.PI / 2 - this.bodyAngle;
    r.body.rotation.y = spin;
    const dashStretch = p.state === 'dash' ? 1 : 0;
    r.body.scale.set(1, 1 - 0.05 * dashStretch, 1 + 0.08 * dashStretch);

    r.hips.position.y = HIP_HEIGHT + c.hipY;
    r.hips.rotation.set(0, c.hipYaw, c.hipRoll + this.leanSide);
    const pitch = c.spinePitch + this.leanForward;
    r.spine.rotation.set(pitch, c.spineYaw, c.spineRoll);

    // 머리는 앞을 보려고 몸의 비틀림을 되돌리고, 서 있거나 걸을 때는 조준 쪽을 살짝 봄
    let look = 0;
    if (p.state === 'idle' || p.state === 'move') {
      look = clamp(wrapAngle(this.bodyAngle - p.facingAngle), -0.7, 0.7) * 0.8;
    }
    const headYaw = clamp(-(c.hipYaw + c.spineYaw) + look, -1.2, 1.2);
    r.head.rotation.set(c.headPitch - pitch * 0.5, headYaw, -c.spineRoll);

    const leg = (thigh: THREE.Group, knee: THREE.Group, ankle: THREE.Group, t: number, k: number, a: number, s: number): void => {
      thigh.rotation.set(t, 0, s);
      knee.rotation.x = k;
      // 발은 땅과 거의 평평하게 유지
      ankle.rotation.x = a - (t + k) * 0.8;
    };
    leg(r.thighR, r.kneeR, r.ankleR, c.thighR, c.kneeR, c.ankleR, c.spreadR);
    leg(r.thighL, r.kneeL, r.ankleL, c.thighL, c.kneeL, c.ankleL, c.spreadL);

    r.root.updateMatrixWorld(true);
  }

  private placeArmsAndGear(): void {
    const r = this.rig;
    const c = this.current;
    const stow = clamp(c.stow, 0, 1);

    // 오른손: 창 손잡이
    this.v1.set(c.handRx, c.handRy + c.hipY, c.handRz);
    r.body.localToWorld(this.v1);
    this.v2.copy(POLE_R).transformDirection(r.body.matrixWorld);
    this.solveArm(r.upperArmR, r.foreArmR, this.v1, this.v2, this.gripR);

    // 왼손: 방패 (활을 쏠 때는 활)
    this.v1.set(c.handLx, c.handLy + c.hipY, c.handLz);
    r.body.localToWorld(this.v1);
    this.v2.copy(POLE_L).transformDirection(r.body.matrixWorld);
    this.solveArm(r.upperArmL, r.foreArmL, this.v1, this.v2, this.gripL);

    // 창: 손에 쥔 자리와 등에 멘 자리를 stow 비율로 섞음
    const gripR = r.body.worldToLocal(this.v3.copy(this.gripR));
    const spearDir = this.v4.set(c.spearX, c.spearY, c.spearZ).normalize();
    const heldPos = this.v5.copy(gripR).addScaledVector(spearDir, c.spearSlide);
    const backPos = this.v6.copy(SPEAR_BACK_SLOT).setY(SPEAR_BACK_SLOT.y + c.hipY);
    r.spear.position.lerpVectors(heldPos, backPos, stow);
    spearDir.lerp(SPEAR_BACK_DIR, stow).normalize();
    r.spear.quaternion.setFromUnitVectors(UP, spearDir);

    // 방패: 왼팔 바깥쪽에 붙음
    const gripL = r.body.worldToLocal(this.v3.copy(this.gripL));
    const shieldDir = this.v4.set(c.shieldX, c.shieldY, c.shieldZ).normalize();
    const shieldHeld = this.v5.copy(gripL).addScaledVector(shieldDir, 0.07);
    shieldHeld.x += 0.05;
    const shieldBack = this.v6.copy(SHIELD_BACK_SLOT).setY(SHIELD_BACK_SLOT.y + c.hipY);
    r.shield.position.lerpVectors(shieldHeld, shieldBack, stow);
    shieldDir.lerp(SHIELD_BACK_DIR, stow).normalize();
    r.shield.quaternion.setFromUnitVectors(FRONT, shieldDir);

    r.handBow.visible = stow > 0.5;
    r.backBow.visible = stow <= 0.5;
    r.handBow.position.copy(gripL);

    r.root.updateMatrixWorld(true);
  }

  /**
   * 2관절 IK: 어깨에서 target까지 팔을 뻗고, 팔꿈치는 pole 쪽으로 굽힘.
   * out에는 손이 실제로 닿은 위치(월드)를 넣는다.
   */
  private solveArm(upper: THREE.Group, fore: THREE.Group, target: THREE.Vector3, pole: THREE.Vector3, out: THREE.Vector3): void {
    const shoulder = upper.getWorldPosition(this.v3);
    const elbowNow = fore.getWorldPosition(this.v4);
    const a = shoulder.distanceTo(elbowNow);
    const b = a;

    const dir = this.v5.subVectors(target, shoulder);
    const dist = clamp(dir.length(), 0.05, a + b - 0.001);
    dir.normalize();

    const cosA = clamp((a * a + dist * dist - b * b) / (2 * a * dist), -1, 1);
    const sinA = Math.sqrt(1 - cosA * cosA);
    const bend = this.v6.copy(pole).addScaledVector(dir, -pole.dot(dir));
    if (bend.lengthSq() < 1e-6) bend.set(0, -1, 0);
    bend.normalize();

    const upperDir = this.v4.copy(dir).multiplyScalar(cosA).addScaledVector(bend, sinA);
    out.copy(shoulder).addScaledVector(dir, dist);
    const elbow = this.v1.copy(shoulder).addScaledVector(upperDir, a);
    const foreDir = this.v2.subVectors(out, elbow).normalize();

    const side = elbow.copy(foreDir).addScaledVector(upperDir, -foreDir.dot(upperDir));
    if (side.lengthSq() < 1e-6) side.copy(bend);
    side.normalize();

    const yAxis = this.v3.copy(upperDir).negate();
    const zAxis = side.negate();
    const xAxis = this.v6.crossVectors(yAxis, zAxis);
    this.m.makeBasis(xAxis, yAxis, zAxis);
    this.q1.setFromRotationMatrix(this.m);
    upper.parent!.getWorldQuaternion(this.q2).invert();
    upper.quaternion.copy(this.q2.multiply(this.q1));
    fore.rotation.set(Math.acos(clamp(upperDir.dot(foreDir), -1, 1)), 0, 0);
  }

  private updateCape(dt: number): void {
    const r = this.rig;
    for (let i = 0; i < r.capeAnchors.length; i++) {
      this.capeAnchorsWorld[i].copy(r.capeAnchors[i]);
      r.spine.localToWorld(this.capeAnchorsWorld[i]);
    }
    const center = r.hips.getWorldPosition(this.v1);
    center.y += 0.35 * MODEL_SCALE;
    const forward = r.spine.getWorldDirection(this.v2).setY(0).normalize();
    this.cape.update(this.capeAnchorsWorld, center, forward, dt);
  }

  private updateTrail(p: PlayerEntity, dt: number, emit: boolean): void {
    const tip = this.rig.spear.localToWorld(this.v1.set(0, SPEAR_TIP + SPEAR_HEAD_LENGTH, 0));
    const base = this.rig.spear.localToWorld(this.v2.set(0, SPEAR_TIP * 0.35, 0));
    this.trail.update(dt, emit && p.state !== 'dash', tip, base);
  }
}
