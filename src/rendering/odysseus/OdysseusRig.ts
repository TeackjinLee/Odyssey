import * as THREE from 'three';
import { ToonMaterialKit } from './ToonMaterials';

/**
 * 오디세우스 3D 몸체: 도형으로 만든 몸 조각을 관절(Group)로 이어 붙인 것.
 * 모델은 로컬 +Z를 바라보고, 오른쪽이 -X, 위가 +Y, 발바닥이 y=0이다.
 * 창·방패·활은 body 공간에 따로 두고, 팔은 IK로 손이 무기에 닿게 한다.
 */

export const PALETTE = {
  skin: '#c98a5e',
  hair: '#2b1d14',
  bronze: '#c9963a',
  bronzeDark: '#8a5a22',
  gold: '#e8b84a',
  leather: '#5a3420',
  leatherDark: '#3b2114',
  cloth: '#efe6d2',
  cape: '#b3121e',
  shaft: '#4a2c17',
  wrap: '#9b1b22',
};

/** 모델 전체 배율 (화면에서 적·보스 스프라이트와 비슷한 크기로 보이게) */
export const MODEL_SCALE = 1.22;

export const HIP_HEIGHT = 1.0;
export const SPEAR_TIP = 1.55;
export const SPEAR_HEAD_LENGTH = 0.28;

export class OdysseusRig {
  public readonly root = new THREE.Group();
  /** 몸 전체 회전(3타 회전베기)과 눌림·늘어남을 맡는 층 */
  public readonly body = new THREE.Group();
  public readonly hips = new THREE.Group();
  public readonly spine = new THREE.Group();
  public readonly neck = new THREE.Group();
  public readonly head = new THREE.Group();

  public readonly thighR = new THREE.Group();
  public readonly kneeR = new THREE.Group();
  public readonly ankleR = new THREE.Group();
  public readonly thighL = new THREE.Group();
  public readonly kneeL = new THREE.Group();
  public readonly ankleL = new THREE.Group();

  public readonly upperArmR = new THREE.Group();
  public readonly foreArmR = new THREE.Group();
  public readonly upperArmL = new THREE.Group();
  public readonly foreArmL = new THREE.Group();

  public readonly spear = new THREE.Group();
  public readonly shield = new THREE.Group();
  public readonly handBow = new THREE.Group();
  public readonly backBow = new THREE.Group();

  /** 망토 윗단이 붙는 자리 (spine 공간) */
  public readonly capeAnchors: THREE.Vector3[] = [];

  private readonly kit: ToonMaterialKit;
  private readonly mats: Record<keyof typeof PALETTE, THREE.ShaderMaterial>;

  constructor(kit: ToonMaterialKit) {
    this.kit = kit;
    this.mats = {
      skin: kit.surface(PALETTE.skin),
      hair: kit.surface(PALETTE.hair),
      bronze: kit.surface(PALETTE.bronze, { metal: true }),
      bronzeDark: kit.surface(PALETTE.bronzeDark, { metal: true }),
      gold: kit.surface(PALETTE.gold, { metal: true }),
      leather: kit.surface(PALETTE.leather),
      leatherDark: kit.surface(PALETTE.leatherDark, { doubleSide: true }),
      cloth: kit.surface(PALETTE.cloth, { doubleSide: true }),
      cape: kit.surface(PALETTE.cape, { doubleSide: true }),
      shaft: kit.surface(PALETTE.shaft),
      wrap: kit.surface(PALETTE.wrap),
    };

    this.root.scale.setScalar(MODEL_SCALE);
    this.root.add(this.body);
    this.body.add(this.hips);
    this.hips.position.y = HIP_HEIGHT;

    this.buildLegs();
    this.buildTorso();
    this.buildHead();
    this.buildArms();
    this.buildSpear();
    this.buildShield();
    this.buildBows();
  }

  private part(
    parent: THREE.Object3D,
    geo: THREE.BufferGeometry,
    mat: THREE.Material,
    x = 0,
    y = 0,
    z = 0,
    outline = true
  ): THREE.Mesh {
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(x, y, z);
    parent.add(mesh);
    if (outline) mesh.add(new THREE.Mesh(geo, this.kit.outline()));
    return mesh;
  }

  /** 아래로 늘어진 팔다리 한 마디: 관절에서 -Y 방향으로 length만큼 */
  private limb(parent: THREE.Object3D, radius: number, length: number, mat: THREE.Material): THREE.Mesh {
    const geo = new THREE.CapsuleGeometry(radius, Math.max(0.01, length - radius * 2), 4, 10);
    return this.part(parent, geo, mat, 0, -length / 2, 0);
  }

  private buildLegs(): void {
    const build = (thigh: THREE.Group, knee: THREE.Group, ankle: THREE.Group, side: number): void => {
      thigh.position.set(0.13 * side, -0.05, 0);
      this.hips.add(thigh);
      this.limb(thigh, 0.09, 0.46, this.mats.skin);

      knee.position.y = -0.46;
      thigh.add(knee);
      this.limb(knee, 0.075, 0.44, this.mats.skin);
      // 청동 정강이받이
      const greave = new THREE.CylinderGeometry(0.095, 0.08, 0.3, 10, 1);
      this.part(knee, greave, this.mats.bronze, 0, -0.24, 0.015);

      ankle.position.y = -0.44;
      knee.add(ankle);
      const foot = new THREE.BoxGeometry(0.13, 0.07, 0.27);
      this.part(ankle, foot, this.mats.leather, 0, -0.02, 0.06);
    };
    build(this.thighR, this.kneeR, this.ankleR, -1);
    build(this.thighL, this.kneeL, this.ankleL, 1);
  }

  private buildTorso(): void {
    // 흰 튜닉 치마와 그 위를 덮는 가죽 띠(프테루게스)
    const tunic = new THREE.CylinderGeometry(0.21, 0.31, 0.38, 14, 1, true);
    this.part(this.hips, tunic, this.mats.cloth, 0, -0.17, 0, false);
    const strips = new THREE.CylinderGeometry(0.23, 0.33, 0.3, 9, 1, true);
    this.part(this.hips, strips, this.mats.leatherDark, 0, -0.1, 0, false);

    this.spine.position.y = 0.12;
    this.hips.add(this.spine);

    const belly = new THREE.CylinderGeometry(0.2, 0.21, 0.2, 12);
    this.part(this.spine, belly, this.mats.cloth, 0, -0.04, 0);
    const belt = new THREE.CylinderGeometry(0.225, 0.225, 0.07, 14);
    this.part(this.spine, belt, this.mats.leather, 0, 0.03, 0);

    // 청동 흉갑: 위가 넓고 앞뒤로 납작한 통
    const cuirass = new THREE.CylinderGeometry(0.29, 0.22, 0.5, 14);
    cuirass.scale(1, 1, 0.72);
    cuirass.computeVertexNormals();
    this.part(this.spine, cuirass, this.mats.bronze, 0, 0.3, 0);

    // 어깨를 감싼 흰 소매
    const sleeve = new THREE.SphereGeometry(0.11, 10, 8);
    this.part(this.spine, sleeve, this.mats.cloth, -0.31, 0.47, 0);
    this.part(this.spine, sleeve, this.mats.cloth, 0.31, 0.47, 0);

    // 망토 고정 금장식 (왼쪽 가슴)
    const clasp = new THREE.CylinderGeometry(0.055, 0.055, 0.03, 12);
    clasp.rotateX(Math.PI / 2);
    this.part(this.spine, clasp, this.mats.gold, 0.15, 0.5, 0.17);

    // 등에 멘 화살통
    const quiver = new THREE.CylinderGeometry(0.06, 0.05, 0.5, 8);
    const quiverMesh = this.part(this.spine, quiver, this.mats.leather, 0.12, 0.32, -0.24);
    quiverMesh.rotation.z = -0.5;

    // 망토 윗단: 어깨 뒤쪽 4점
    for (let i = 0; i < 4; i++) {
      const x = -0.27 + (0.54 * i) / 3;
      this.capeAnchors.push(new THREE.Vector3(x, 0.5, -0.17 - Math.abs(x) * 0.08));
    }
  }

  private buildHead(): void {
    this.neck.position.y = 0.56;
    this.spine.add(this.neck);
    this.part(this.neck, new THREE.CylinderGeometry(0.075, 0.085, 0.14, 8), this.mats.skin, 0, 0.04, 0);

    this.head.position.y = 0.2;
    this.neck.add(this.head);
    this.part(this.head, new THREE.SphereGeometry(0.17, 16, 12), this.mats.skin);

    // 곱슬 검은 머리: 큰 덩어리 하나와 작은 덩어리 여럿
    this.part(this.head, new THREE.SphereGeometry(0.18, 14, 10), this.mats.hair, 0, 0.05, -0.04);
    const curl = new THREE.SphereGeometry(0.075, 8, 6);
    const curls: Array<[number, number, number]> = [
      [-0.13, 0.08, 0.03], [0.13, 0.08, 0.03], [-0.15, -0.02, -0.06], [0.15, -0.02, -0.06],
      [0, 0.17, 0.02], [-0.08, 0.15, 0.08], [0.08, 0.15, 0.08], [0, 0.04, -0.17],
    ];
    for (const [x, y, z] of curls) this.part(this.head, curl, this.mats.hair, x, y, z, false);

    // 수염
    const beard = new THREE.SphereGeometry(0.13, 12, 8, 0, Math.PI * 2, Math.PI * 0.45, Math.PI * 0.55);
    this.part(this.head, beard, this.mats.hair, 0, -0.03, 0.04, false);

    // 코와 눈 (앞을 알아보게)
    this.part(this.head, new THREE.BoxGeometry(0.04, 0.06, 0.05), this.mats.skin, 0, 0.0, 0.17, false);
    const eye = new THREE.SphereGeometry(0.018, 6, 4);
    this.part(this.head, eye, this.mats.hair, -0.06, 0.04, 0.155, false);
    this.part(this.head, eye, this.mats.hair, 0.06, 0.04, 0.155, false);
  }

  private buildArms(): void {
    const build = (upper: THREE.Group, fore: THREE.Group, side: number): void => {
      upper.position.set(0.33 * side, 0.47, 0);
      this.spine.add(upper);
      this.limb(upper, 0.075, 0.4, this.mats.skin);

      fore.position.y = -0.4;
      upper.add(fore);
      this.limb(fore, 0.068, 0.4, this.mats.skin);
      // 가죽 팔목보호대와 주먹
      this.part(fore, new THREE.CylinderGeometry(0.08, 0.075, 0.16, 10), this.mats.leather, 0, -0.26, 0);
      this.part(fore, new THREE.SphereGeometry(0.075, 10, 8), this.mats.skin, 0, -0.4, 0);
    };
    build(this.upperArmR, this.foreArmR, -1);
    build(this.upperArmL, this.foreArmL, 1);
  }

  private buildSpear(): void {
    // 손잡이 자리가 원점, +Y가 창끝 방향
    this.body.add(this.spear);
    const butt = -0.85;
    const shaftLen = SPEAR_TIP - butt;
    this.part(this.spear, new THREE.CylinderGeometry(0.024, 0.026, shaftLen, 8), this.mats.shaft, 0, butt + shaftLen / 2, 0);
    this.part(this.spear, new THREE.CylinderGeometry(0.033, 0.033, 0.2, 8), this.mats.wrap, 0, 0.36, 0);
    this.part(this.spear, new THREE.CylinderGeometry(0.036, 0.036, 0.05, 8), this.mats.gold, 0, SPEAR_TIP - 0.02, 0);
    const head = new THREE.ConeGeometry(0.075, SPEAR_HEAD_LENGTH, 4);
    head.scale(1, 1, 0.4);
    head.computeVertexNormals();
    this.part(this.spear, head, this.mats.gold, 0, SPEAR_TIP + SPEAR_HEAD_LENGTH / 2, 0);
    const spike = new THREE.ConeGeometry(0.035, 0.12, 6);
    spike.rotateX(Math.PI);
    this.part(this.spear, spike, this.mats.gold, 0, butt - 0.05, 0);
  }

  private buildShield(): void {
    // 원점이 방패 중심, +Z가 앞면 방향
    this.body.add(this.shield);
    const disc = new THREE.CylinderGeometry(0.37, 0.37, 0.05, 28);
    disc.rotateX(Math.PI / 2);
    this.part(this.shield, disc, this.mats.bronzeDark);
    const rim = new THREE.TorusGeometry(0.36, 0.03, 6, 28);
    this.part(this.shield, rim, this.mats.bronze, 0, 0, 0.02, false);
    const boss = new THREE.SphereGeometry(0.1, 12, 8, 0, Math.PI * 2, 0, Math.PI / 2);
    boss.rotateX(Math.PI / 2);
    this.part(this.shield, boss, this.mats.gold, 0, 0, 0.025, false);
    // 태양 문양 빛살 8개
    const ray = new THREE.ConeGeometry(0.045, 0.2, 3);
    ray.scale(1, 1, 0.25);
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * Math.PI * 2;
      const mesh = this.part(this.shield, ray, this.mats.gold, Math.cos(a) * 0.2, Math.sin(a) * 0.2, 0.03, false);
      mesh.rotation.z = a - Math.PI / 2;
    }
  }

  private buildBows(): void {
    const makeBow = (group: THREE.Group): void => {
      const arc = new THREE.TorusGeometry(0.42, 0.022, 6, 16, Math.PI * 0.85);
      arc.rotateZ(-Math.PI * 0.425);
      this.part(group, arc, this.mats.leather, -0.42, 0, 0);
      const string = new THREE.CylinderGeometry(0.005, 0.005, 0.82, 4);
      this.part(group, string, this.mats.cloth, -0.32, 0, 0, false);
    };
    // 활을 쏠 때 왼손에 드는 활 (원점이 손잡이, 활 몸통은 로컬 +X로 휘고 시위는 -X 쪽)
    makeBow(this.handBow);
    this.handBow.rotation.y = -Math.PI / 2;
    this.body.add(this.handBow);
    // 평소 등에 멘 활
    makeBow(this.backBow);
    this.backBow.position.set(-0.05, 0.3, -0.27);
    this.backBow.rotation.set(0, Math.PI / 2, 0.6);
    this.spine.add(this.backBow);
  }
}
