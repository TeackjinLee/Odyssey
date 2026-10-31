import * as THREE from 'three';

/**
 * 창끝이 지나간 자리를 따라 남는 빛 궤적.
 * 매 프레임 창끝과 창대 중간 두 점을 기록해 띠로 잇고, 오래된 쪽부터 흐려진다.
 */
const MAX_SAMPLES = 22;
const LIFE = 0.15;

interface Sample {
  tip: THREE.Vector3;
  base: THREE.Vector3;
  age: number;
}

export class SpearTrail {
  public readonly mesh: THREE.Mesh;

  private samples: Sample[] = [];
  private readonly positions = new Float32Array(MAX_SAMPLES * 2 * 3);
  private readonly alphas = new Float32Array(MAX_SAMPLES * 2);
  private readonly geo = new THREE.BufferGeometry();
  private readonly material: THREE.ShaderMaterial;

  constructor() {
    const index: number[] = [];
    for (let i = 0; i < MAX_SAMPLES - 1; i++) {
      const a = i * 2;
      index.push(a, a + 1, a + 2, a + 1, a + 3, a + 2);
    }
    this.geo.setIndex(index);
    this.geo.setAttribute('position', new THREE.BufferAttribute(this.positions, 3));
    this.geo.setAttribute('alpha', new THREE.BufferAttribute(this.alphas, 1));
    this.geo.setDrawRange(0, 0);

    this.material = new THREE.ShaderMaterial({
      uniforms: { uColor: { value: new THREE.Color('#fde68a') } },
      vertexShader: /* glsl */ `
        attribute float alpha;
        varying float vAlpha;
        void main() {
          vAlpha = alpha;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: /* glsl */ `
        uniform vec3 uColor;
        varying float vAlpha;
        void main() {
          gl_FragColor = vec4(uColor * 1.6, vAlpha);
          #include <colorspace_fragment>
        }
      `,
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide,
    });

    this.mesh = new THREE.Mesh(this.geo, this.material);
    this.mesh.frustumCulled = false;
  }

  public setColor(color: string): void {
    this.material.uniforms.uColor.value.set(color);
  }

  public update(dt: number, emit: boolean, tip: THREE.Vector3, base: THREE.Vector3): void {
    for (const s of this.samples) s.age += dt;
    this.samples = this.samples.filter((s) => s.age < LIFE);

    if (emit) {
      const last = this.samples[this.samples.length - 1];
      if (!last || last.tip.distanceToSquared(tip) > 1e-4) {
        this.samples.push({ tip: tip.clone(), base: base.clone(), age: 0 });
        if (this.samples.length > MAX_SAMPLES) this.samples.shift();
      }
    }

    const n = this.samples.length;
    for (let i = 0; i < n; i++) {
      const s = this.samples[i];
      const fade = (1 - s.age / LIFE) * ((i + 1) / n);
      this.positions.set([s.base.x, s.base.y, s.base.z, s.tip.x, s.tip.y, s.tip.z], i * 6);
      this.alphas[i * 2] = 0;
      this.alphas[i * 2 + 1] = fade * 0.85;
    }
    (this.geo.getAttribute('position') as THREE.BufferAttribute).needsUpdate = true;
    (this.geo.getAttribute('alpha') as THREE.BufferAttribute).needsUpdate = true;
    this.geo.setDrawRange(0, n >= 2 ? (n - 1) * 6 : 0);
  }
}
