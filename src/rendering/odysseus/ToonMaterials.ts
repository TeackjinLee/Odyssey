import * as THREE from 'three';

/**
 * 오디세우스 3D 모델용 툰 셰이딩 재료.
 * 씬 조명과 상관없이 왼쪽 위 앞에서 비추는 고정 빛으로 명암을 3단계로만 나눠,
 * 어느 씬에서도 손그림 스프라이트(적·보스)와 어울리는 같은 그림체를 유지한다.
 * 그림자는 아트 방향대로 청록색(#0d2b36) 쪽으로 물든다.
 */
const LIGHT_DIR = new THREE.Vector3(-0.45, 0.8, 0.55).normalize();
const SHADOW_TINT = new THREE.Color('#0d2b36');
const OUTLINE_COLOR = new THREE.Color('#140a06');
const OUTLINE_THICKNESS = 0.022;

const SURFACE_VERTEX = /* glsl */ `
  varying vec3 vNormal;
  varying vec3 vViewDir;
  void main() {
    vec4 worldPos = modelMatrix * vec4(position, 1.0);
    vNormal = normalize(mat3(modelMatrix) * normal);
    vViewDir = normalize(cameraPosition - worldPos.xyz);
    gl_Position = projectionMatrix * viewMatrix * worldPos;
  }
`;

const SURFACE_FRAGMENT = /* glsl */ `
  uniform vec3 uColor;
  uniform vec3 uShadowTint;
  uniform vec3 uLightDir;
  uniform float uMetal;
  uniform float uFlash;
  varying vec3 vNormal;
  varying vec3 vViewDir;
  void main() {
    vec3 n = normalize(vNormal);
    if (!gl_FrontFacing) n = -n;
    float ndl = dot(n, uLightDir);
    float band = ndl > 0.45 ? 1.0 : (ndl > -0.1 ? 0.72 : 0.48);
    vec3 shadowCol = mix(uColor * 0.5, uShadowTint, 0.35);
    vec3 col = mix(shadowCol, uColor, (band - 0.48) / 0.52);

    // 청동·금: 빛을 바로 받는 곳에 반짝이는 띠
    vec3 h = normalize(uLightDir + vViewDir);
    col += step(0.94, dot(n, h)) * uMetal * vec3(1.0, 0.86, 0.55) * 0.6;

    // 가장자리 테두리 빛 (어두운 배경에서 실루엣이 묻히지 않게)
    float rim = 1.0 - max(dot(n, vViewDir), 0.0);
    col += step(0.72, rim) * 0.1 * vec3(0.6, 0.9, 1.0);

    col = mix(col, vec3(1.0), uFlash);
    gl_FragColor = vec4(col, 1.0);
    #include <tonemapping_fragment>
    #include <colorspace_fragment>
  }
`;

const OUTLINE_VERTEX = /* glsl */ `
  uniform float uThickness;
  void main() {
    vec3 p = position + normal * uThickness;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
  }
`;

const OUTLINE_FRAGMENT = /* glsl */ `
  uniform vec3 uColor;
  void main() {
    gl_FragColor = vec4(uColor, 1.0);
    #include <colorspace_fragment>
  }
`;

export class ToonMaterialKit {
  /** 맞았을 때 하얗게 번쩍이는 정도 (모든 재료가 함께 씀) */
  public readonly flash = { value: 0 };
  private readonly outlineMaterial: THREE.ShaderMaterial;

  constructor() {
    this.outlineMaterial = new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: OUTLINE_COLOR },
        uThickness: { value: OUTLINE_THICKNESS },
      },
      vertexShader: OUTLINE_VERTEX,
      fragmentShader: OUTLINE_FRAGMENT,
      side: THREE.BackSide,
    });
  }

  public surface(color: string, opts: { metal?: boolean; doubleSide?: boolean } = {}): THREE.ShaderMaterial {
    return new THREE.ShaderMaterial({
      uniforms: {
        uColor: { value: new THREE.Color(color) },
        uShadowTint: { value: SHADOW_TINT },
        uLightDir: { value: LIGHT_DIR },
        uMetal: { value: opts.metal ? 1 : 0 },
        uFlash: this.flash,
      },
      vertexShader: SURFACE_VERTEX,
      fragmentShader: SURFACE_FRAGMENT,
      side: opts.doubleSide ? THREE.DoubleSide : THREE.FrontSide,
    });
  }

  public outline(): THREE.ShaderMaterial {
    return this.outlineMaterial;
  }
}
