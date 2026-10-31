import { PlayerEntity, Vec2 } from '../../types/combat';

/** 달리기 한 주기(두 걸음) 동안 나아가는 거리 — 발이 미끄러져 보이지 않게 속도에 맞춤 */
export const STRIDE = 2.5;

export const wrapAngle = (a: number): number => Math.atan2(Math.sin(a), Math.cos(a));
export const clamp = (v: number, lo: number, hi: number): number => Math.max(lo, Math.min(hi, v));
export const approach = (rate: number, dt: number): number => 1 - Math.exp(-rate * dt);

/**
 * 도형 모델과 GLB 모델이 함께 쓰는 몸 전체 움직임.
 * - 몸 방향: 걸을 땐 가는 쪽, 대시는 대시 쪽, 공격·활·패링은 조준(facingAngle) 쪽
 * - 기울기: 속도가 바뀌는 쪽으로 (출발할 때 앞으로, 멈출 때 뒤로, 돌 때 안쪽으로)
 * - 걸음 주기와 발 디딤(먼지 효과용)
 */
export class AvatarMotion {
  /** 몸이 바라보는 월드 각도 (atan2(z, x)) */
  public bodyAngle = -Math.PI / 2;
  public leanForward = 0;
  public leanSide = 0;
  public runPhase = 0;
  public speed = 0;
  /** 이번 프레임에 땅을 디딘 발 위치 */
  public readonly footsteps: Vec2[] = [];

  private prevVx = 0;
  private prevVz = 0;

  public update(p: PlayerEntity, dt: number): void {
    this.footsteps.length = 0;
    this.speed = Math.hypot(p.vx, p.vz);
    this.updateFacing(p, dt);
    this.updateLean(p, dt);
    this.updateRunPhase(p, dt);
  }

  /** 모델 로컬 +Z가 몸 앞쪽일 때 루트에 넣을 Y 회전 */
  public get rootYaw(): number {
    return Math.PI / 2 - this.bodyAngle;
  }

  /** 서 있거나 걸을 때 머리를 조준 쪽으로 돌릴 각도 (로컬 Y 회전) */
  public lookYaw(p: PlayerEntity): number {
    if (p.state !== 'idle' && p.state !== 'move') return 0;
    return clamp(wrapAngle(this.bodyAngle - p.facingAngle), -0.7, 0.7) * 0.8;
  }

  private updateFacing(p: PlayerEntity, dt: number): void {
    let target = this.bodyAngle;
    let rate = 16;
    if (p.state === 'dash') {
      target = Math.atan2(p.dashDirZ, p.dashDirX);
      rate = 40;
    } else if (p.state !== 'idle' && p.state !== 'move') {
      target = p.facingAngle;
      rate = 40;
    } else if (this.speed > 0.5) {
      target = Math.atan2(p.vz, p.vx);
    }
    this.bodyAngle = wrapAngle(this.bodyAngle + wrapAngle(target - this.bodyAngle) * approach(rate, dt));
  }

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

  private updateRunPhase(p: PlayerEntity, dt: number): void {
    const before = Math.floor((this.runPhase - Math.PI / 2) / Math.PI);
    this.runPhase += (this.speed * dt * Math.PI * 2) / STRIDE;
    const after = Math.floor((this.runPhase - Math.PI / 2) / Math.PI);
    if (after !== before && this.speed > 3 && p.state !== 'dash') {
      this.footsteps.push({ x: p.x, z: p.z });
    }
    if (this.speed < 0.3) this.runPhase = 0;
  }
}
