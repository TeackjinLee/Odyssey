import * as THREE from 'three';

/**
 * 붉은 망토: 점(가로 4 × 세로 8)을 막대로 이은 천 흉내(Verlet).
 * 윗단은 어깨 뒤에 고정되고, 아래는 몸이 움직인 만큼 뒤로 날리고 출렁인다.
 * 점은 월드 좌표로 움직이므로 메시는 씬에 바로 붙인다.
 */
const COLS = 4;
const ROWS = 8;
const STEP = 1 / 60;

export class CapeCloth {
  public readonly mesh: THREE.Mesh;

  private readonly pos = new Float32Array(COLS * ROWS * 3);
  private readonly prev = new Float32Array(COLS * ROWS * 3);
  private readonly geo = new THREE.BufferGeometry();
  private readonly segLen: number;
  private readonly topWidth: number;
  private readonly bottomWidth: number;
  private readonly scale: number;
  private initialized = false;
  private accumulator = 0;
  private time = 0;

  constructor(material: THREE.Material, scale: number) {
    this.scale = scale;
    this.segLen = 0.14 * scale;
    this.topWidth = 0.54 * scale;
    this.bottomWidth = 0.78 * scale;

    const index: number[] = [];
    for (let r = 0; r < ROWS - 1; r++) {
      for (let c = 0; c < COLS - 1; c++) {
        const a = r * COLS + c;
        index.push(a, a + COLS, a + 1, a + 1, a + COLS, a + COLS + 1);
      }
    }
    this.geo.setIndex(index);
    this.geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3));
    this.mesh = new THREE.Mesh(this.geo, material);
    this.mesh.frustumCulled = false;
  }

  /**
   * anchors: 윗단 4점(월드), center: 골반 위치(월드), forward: 몸 앞쪽(월드, 수평)
   */
  public update(anchors: THREE.Vector3[], center: THREE.Vector3, forward: THREE.Vector3, dt: number): void {
    const teleported =
      this.initialized &&
      Math.hypot(this.pos[0] - anchors[0].x, this.pos[2] - anchors[0].z) > 3 * this.scale;
    if (!this.initialized || teleported) this.reset(anchors);

    this.accumulator = Math.min(this.accumulator + dt, STEP * 4);
    while (this.accumulator >= STEP) {
      this.accumulator -= STEP;
      this.time += STEP;
      this.step(anchors, center, forward);
    }

    (this.geo.getAttribute('position') as THREE.BufferAttribute).needsUpdate = true;
    this.geo.computeVertexNormals();
  }

  private reset(anchors: THREE.Vector3[]): void {
    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        const i = (r * COLS + c) * 3;
        this.pos[i] = anchors[c].x;
        this.pos[i + 1] = anchors[c].y - r * this.segLen;
        this.pos[i + 2] = anchors[c].z;
      }
    }
    this.prev.set(this.pos);
    this.initialized = true;
  }

  private step(anchors: THREE.Vector3[], center: THREE.Vector3, forward: THREE.Vector3): void {
    const p = this.pos;
    const q = this.prev;
    const g = 11 * this.scale * STEP * STEP;
    // 바닷바람 같은 약한 흔들림
    const windX = Math.sin(this.time * 1.7) * 0.4 * STEP * STEP;
    const windZ = Math.cos(this.time * 1.3) * 0.4 * STEP * STEP;

    for (let n = COLS; n < COLS * ROWS; n++) {
      const i = n * 3;
      for (let a = 0; a < 3; a++) {
        const cur = p[i + a];
        const v = (cur - q[i + a]) * 0.965;
        q[i + a] = cur;
        p[i + a] = cur + v;
      }
      p[i] += windX;
      p[i + 1] -= g;
      p[i + 2] += windZ;
    }

    for (let iter = 0; iter < 4; iter++) {
      for (let c = 0; c < COLS; c++) {
        const i = c * 3;
        p[i] = anchors[c].x;
        p[i + 1] = anchors[c].y;
        p[i + 2] = anchors[c].z;
      }
      for (let r = 0; r < ROWS; r++) {
        const width = this.topWidth + (this.bottomWidth - this.topWidth) * (r / (ROWS - 1));
        const across = width / (COLS - 1);
        for (let c = 0; c < COLS; c++) {
          const n = r * COLS + c;
          if (c < COLS - 1) this.constrain(n, n + 1, across);
          if (r < ROWS - 1) this.constrain(n, n + COLS, this.segLen);
          if (r < ROWS - 2) this.constrain(n, n + COLS * 2, this.segLen * 2);
        }
      }
      this.collide(center, forward);
    }
  }

  private constrain(a: number, b: number, rest: number): void {
    const p = this.pos;
    const ia = a * 3;
    const ib = b * 3;
    const dx = p[ib] - p[ia];
    const dy = p[ib + 1] - p[ia + 1];
    const dz = p[ib + 2] - p[ia + 2];
    const d = Math.hypot(dx, dy, dz) || 1e-6;
    const diff = (d - rest) / d;
    // 윗단(고정점)은 움직이지 않음
    const wa = a < COLS ? 0 : 0.5;
    const wb = b < COLS ? 0 : 0.5;
    const total = wa + wb || 1;
    p[ia] += dx * diff * (wa / total);
    p[ia + 1] += dy * diff * (wa / total);
    p[ia + 2] += dz * diff * (wa / total);
    p[ib] -= dx * diff * (wb / total);
    p[ib + 1] -= dy * diff * (wb / total);
    p[ib + 2] -= dz * diff * (wb / total);
  }

  /** 몸통(세운 원기둥)과 몸 앞쪽으로 천이 파고들지 않게 밀어냄 */
  private collide(center: THREE.Vector3, forward: THREE.Vector3): void {
    const p = this.pos;
    const radius = 0.27 * this.scale;
    const backLimit = -0.12 * this.scale;
    const bottom = center.y - 0.75 * this.scale;
    for (let n = COLS; n < COLS * ROWS; n++) {
      const i = n * 3;
      if (p[i + 1] < 0.04) p[i + 1] = 0.04;
      if (p[i + 1] < bottom) continue;
      let dx = p[i] - center.x;
      let dz = p[i + 2] - center.z;
      const ahead = dx * forward.x + dz * forward.z;
      if (ahead > backLimit) {
        p[i] -= forward.x * (ahead - backLimit);
        p[i + 2] -= forward.z * (ahead - backLimit);
        dx = p[i] - center.x;
        dz = p[i + 2] - center.z;
      }
      const d = Math.hypot(dx, dz);
      if (d < radius && d > 1e-5) {
        p[i] = center.x + (dx / d) * radius;
        p[i + 2] = center.z + (dz / d) * radius;
      }
    }
  }
}
