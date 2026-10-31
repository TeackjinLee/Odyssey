import * as THREE from 'three';
import { ToonMaterialKit } from './ToonMaterials';

/**
 * 도형으로 만든 창·방패·활. 도형 모델이 쓰고, GLB 모델도 무기 파일이 없을 때 대신 쓴다.
 * - 창: 원점이 손잡이 자리, +Y가 창끝 방향
 * - 방패: 원점이 중심, +Z가 앞면
 * - 활: 원점이 손잡이, 활 몸통은 로컬 +X로 휘고 시위는 -X 쪽, 위아래가 Y
 */
export const SPEAR_TIP = 1.55;
export const SPEAR_HEAD_LENGTH = 0.28;
export const SPEAR_BUTT = -0.85;
/** 활 위·아래 끝 (시위가 걸리는 자리, 활 로컬 좌표) */
export const BOW_TIPS: [THREE.Vector3, THREE.Vector3] = [
  new THREE.Vector3(-0.32, 0.41, 0),
  new THREE.Vector3(-0.32, -0.41, 0),
];

export function toonPart(
  kit: ToonMaterialKit,
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
  if (outline) mesh.add(new THREE.Mesh(geo, kit.outline()));
  return mesh;
}

export function buildSpearProp(kit: ToonMaterialKit): THREE.Group {
  const g = new THREE.Group();
  const shaft = kit.surface('#4a2c17');
  const gold = kit.surface('#e8b84a', { metal: true });
  const shaftLen = SPEAR_TIP - SPEAR_BUTT;
  toonPart(kit, g, new THREE.CylinderGeometry(0.024, 0.026, shaftLen, 8), shaft, 0, SPEAR_BUTT + shaftLen / 2, 0);
  toonPart(kit, g, new THREE.CylinderGeometry(0.033, 0.033, 0.2, 8), kit.surface('#9b1b22'), 0, 0.36, 0);
  toonPart(kit, g, new THREE.CylinderGeometry(0.036, 0.036, 0.05, 8), gold, 0, SPEAR_TIP - 0.02, 0);
  const head = new THREE.ConeGeometry(0.075, SPEAR_HEAD_LENGTH, 4);
  head.scale(1, 1, 0.4);
  head.computeVertexNormals();
  toonPart(kit, g, head, gold, 0, SPEAR_TIP + SPEAR_HEAD_LENGTH / 2, 0);
  const spike = new THREE.ConeGeometry(0.035, 0.12, 6);
  spike.rotateX(Math.PI);
  toonPart(kit, g, spike, gold, 0, SPEAR_BUTT - 0.05, 0);
  return g;
}

export function buildShieldProp(kit: ToonMaterialKit): THREE.Group {
  const g = new THREE.Group();
  const gold = kit.surface('#e8b84a', { metal: true });
  const disc = new THREE.CylinderGeometry(0.37, 0.37, 0.05, 28);
  disc.rotateX(Math.PI / 2);
  toonPart(kit, g, disc, kit.surface('#8a5a22', { metal: true }));
  toonPart(kit, g, new THREE.TorusGeometry(0.36, 0.03, 6, 28), kit.surface('#c9963a', { metal: true }), 0, 0, 0.02, false);
  const boss = new THREE.SphereGeometry(0.1, 12, 8, 0, Math.PI * 2, 0, Math.PI / 2);
  boss.rotateX(Math.PI / 2);
  toonPart(kit, g, boss, gold, 0, 0, 0.025, false);
  // 태양 문양 빛살 8개
  const ray = new THREE.ConeGeometry(0.045, 0.2, 3);
  ray.scale(1, 1, 0.25);
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2;
    const mesh = toonPart(kit, g, ray, gold, Math.cos(a) * 0.2, Math.sin(a) * 0.2, 0.03, false);
    mesh.rotation.z = a - Math.PI / 2;
  }
  return g;
}

/** withString이 false면 시위를 빼고 활대만 (시위는 따로 당겨 그릴 때) */
export function buildBowProp(kit: ToonMaterialKit, withString = true): THREE.Group {
  const g = new THREE.Group();
  const arc = new THREE.TorusGeometry(0.42, 0.022, 6, 16, Math.PI * 0.85);
  arc.rotateZ(-Math.PI * 0.425);
  toonPart(kit, g, arc, kit.surface('#5a3420'), -0.42, 0, 0);
  if (withString) {
    const string = new THREE.CylinderGeometry(0.005, 0.005, 0.82, 4);
    toonPart(kit, g, string, kit.surface('#efe6d2'), -0.32, 0, 0, false);
  }
  return g;
}
