import * as THREE from 'three';
import { PlayerEntity } from '../../types/combat';
import { AvatarMotion, clamp } from './AvatarMotion';
import { CapeCloth } from './CapeCloth';
import { HIP_HEIGHT, MODEL_SCALE, OdysseusRig, PALETTE } from './OdysseusRig';
import { PoseDriver } from './PoseDriver';
import { SPEAR_HEAD_LENGTH, SPEAR_TIP } from './Props';
import { SpearTrail } from './SpearTrail';
import { ToonMaterialKit } from './ToonMaterials';

const UP = new THREE.Vector3(0, 1, 0);
const FRONT = new THREE.Vector3(0, 0, 1);
export const SPEAR_BACK_SLOT = new THREE.Vector3(0.05, 1.35, -0.3);
export const SPEAR_BACK_DIR = new THREE.Vector3(-0.45, 0.85, -0.15).normalize();
const SHIELD_BACK_SLOT = new THREE.Vector3(0, 1.22, -0.36);
const SHIELD_BACK_DIR = new THREE.Vector3(0, 0, -1);
export const POLE_R = new THREE.Vector3(-0.6, -0.4, -1);
export const POLE_L = new THREE.Vector3(0.6, -0.4, -1);

/**
 * 오디세우스 도형 3D 모델 (GLB 모델이 없거나 불러오지 못했을 때 쓰는 기본 모델).
 * PoseDriver가 고른 자세를 관절에 입히고, 팔은 2관절 IK로 창·방패를 쥔 손 위치에 닿게 한다.
 */
export class OdysseusModel {
  private readonly kit = new ToonMaterialKit();
  private readonly rig: OdysseusRig;
  private readonly cape: CapeCloth;
  private readonly trail = new SpearTrail();

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

    scene.add(this.rig.root);
    scene.add(this.cape.mesh);
    scene.add(this.trail.mesh);
  }

  public setVisible(visible: boolean): void {
    this.rig.root.visible = visible;
    this.cape.mesh.visible = visible;
    this.trail.mesh.visible = visible;
  }

  /** dt가 0이면(히트스톱) 모든 움직임이 멈춤 */
  public update(p: PlayerEntity, motion: AvatarMotion, poses: PoseDriver, dt: number): void {
    if (dt <= 0) return;
    this.applyPose(p, motion, poses);
    this.placeArmsAndGear(poses);
    this.updateCape(dt);
    this.trail.setColor(p.comboStep === 3 ? '#fb923c' : '#fde68a');
    this.updateTrail(p, dt, poses.trail);
    this.kit.flash.value = Math.min(1, p.hitFlashTimer * 5) * 0.75;
  }

  private applyPose(p: PlayerEntity, motion: AvatarMotion, poses: PoseDriver): void {
    const r = this.rig;
    const c = poses.current;

    r.root.position.set(p.x, 0, p.z);
    r.root.rotation.y = motion.rootYaw;
    r.body.rotation.y = poses.spin;
    const dashStretch = p.state === 'dash' ? 1 : 0;
    r.body.scale.set(1, 1 - 0.05 * dashStretch, 1 + 0.08 * dashStretch);

    r.hips.position.y = HIP_HEIGHT + c.hipY;
    r.hips.rotation.set(0, c.hipYaw, c.hipRoll + motion.leanSide);
    const pitch = c.spinePitch + motion.leanForward;
    r.spine.rotation.set(pitch, c.spineYaw, c.spineRoll);

    // 머리는 앞을 보려고 몸의 비틀림을 되돌리고, 서 있거나 걸을 때는 조준 쪽을 살짝 봄
    const headYaw = clamp(-(c.hipYaw + c.spineYaw) + motion.lookYaw(p), -1.2, 1.2);
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

  private placeArmsAndGear(poses: PoseDriver): void {
    const r = this.rig;
    const c = poses.current;
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
