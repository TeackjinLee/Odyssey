import * as THREE from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { COMBAT_CONFIG } from '../../data/combatConfig';
import { PlayerEntity } from '../../types/combat';
import { AVATAR_CONFIG, BoneKey, ClipFile, ClipKey, WeaponKey, WeaponMount } from './avatarConfig';
import { AvatarMotion, approach, clamp } from './AvatarMotion';
import { POLE_L, POLE_R } from './OdysseusModel';
import { PoseDriver, spearProgress } from './PoseDriver';
import { BOW_TIPS, SWORD_POMMEL, SWORD_TIP, buildBowProp, buildShieldProp, buildSwordProp } from './Props';
import { SpearTrail } from './SpearTrail';
import { ToonMaterialKit } from './ToonMaterials';

/** 도형 모델의 키 (보완 자세의 손 위치가 이 키 기준으로 적혀 있음) */
const POSE_SPACE_HEIGHT = 2.1;
const TAG = '[Odysseus GLB]';
/** 동작 파일에서 읽은 동작의 이름 앞에 붙임 */
const CLIP_FILE_PREFIX = 'file:';

const normalizeName = (name: string): string =>
  name.toLowerCase().replace(/mixamorig\d*/g, '').replace(/[^a-z0-9]/g, '');

interface LoadedModel {
  scene: THREE.Object3D;
  animations: THREE.AnimationClip[];
}

/** .fbx(Mixamo)와 .glb/.gltf를 같은 모양으로 읽음. 없는 파일은 Vite가 index.html을 돌려줘 파싱에서 실패함 */
async function loadModelFile(url: string): Promise<LoadedModel> {
  if (url.toLowerCase().endsWith('.fbx')) {
    const group = await new FBXLoader().loadAsync(url);
    return { scene: group, animations: group.animations };
  }
  const gltf = await new GLTFLoader().loadAsync(url);
  return { scene: gltf.scene, animations: gltf.animations };
}

async function loadFirst(urls: string[]): Promise<LoadedModel & { url: string }> {
  let lastError: unknown = null;
  for (const url of urls) {
    try {
      return { ...(await loadModelFile(url)), url };
    } catch (err) {
      lastError = err;
    }
  }
  throw lastError instanceof Error ? lastError : new Error('모델 파일 없음');
}

/** 동작의 from~to(길이 대비 0~1) 구간만 떼어 0초부터 시작하는 새 동작으로 */
function cutClip(source: THREE.AnimationClip, from: number, to: number): THREE.AnimationClip {
  const start = source.duration * from;
  const end = source.duration * to;
  const tracks = source.tracks.map((t) => t.clone().trim(start, end).shift(-start));
  return new THREE.AnimationClip(source.name, end - start, tracks);
}

interface WeaponNode {
  mount: THREE.Group;
  /** 무기 축: 창·활은 +Y, 방패는 +Z(앞면) */
  tipLocal: THREE.Vector3;
}

/**
 * GLB 오디세우스: Meshy 등에서 만든 뼈대 있는 모델을 불러와 동작을 틀고, 무기를 손 뼈에 붙인다.
 * 상태에 맞는 동작이 파일에 없으면 PoseDriver 자세로 상체를 비틀고 팔을 IK로 무기 자리에 뻗어 보완한다.
 */
export class GltfOdysseus {
  public static async load(scene: THREE.Scene): Promise<GltfOdysseus> {
    const model = await loadFirst(AVATAR_CONFIG.modelUrls);
    console.info(TAG, `${model.url} 불러옴`);
    // 동작별 파일 (Mixamo에서 받은 FBX). 파일 이름을 동작 이름으로 써서 clips 후보와 상관없이 그 상태에 연결
    // 한 파일을 여러 상태가 나눠 쓰면(콤보 하나를 1~3타로) 한 번만 읽고 구간을 잘라 씀
    const fileCache = new Map<string, Promise<THREE.AnimationClip | null>>();
    const readClip = (url: string): Promise<THREE.AnimationClip | null> => {
      if (!fileCache.has(url)) {
        fileCache.set(
          url,
          loadModelFile(url)
            .then((f) => f.animations.find((c) => c.duration > 0.05) ?? null)
            .catch(() => null)
        );
      }
      return fileCache.get(url)!;
    };
    const files = await Promise.all(
      (Object.keys(AVATAR_CONFIG.clipFiles) as ClipKey[]).map(async (key) => {
        const entry: ClipFile = AVATAR_CONFIG.clipFiles[key];
        const { url, from, to } = typeof entry === 'string' ? { url: entry, from: 0, to: 1 } : entry;
        const source = await readClip(url);
        if (!source) return null;
        const clip = from > 0 || to < 1 ? cutClip(source, from, to) : source;
        clip.name = `${CLIP_FILE_PREFIX}${key}`;
        return clip;
      })
    );
    const loaded = files.filter((c): c is THREE.AnimationClip => c !== null);
    if (loaded.length) console.info(TAG, '동작 파일:', loaded.map((c) => c.name.slice(CLIP_FILE_PREFIX.length)));
    model.animations.push(...loaded);

    const weaponFiles = {} as Record<WeaponKey, THREE.Object3D | null>;
    for (const key of Object.keys(AVATAR_CONFIG.weapons) as WeaponKey[]) {
      weaponFiles[key] = await loadModelFile(AVATAR_CONFIG.weapons[key].url)
        .then((g) => g.scene)
        .catch(() => null);
    }
    return new GltfOdysseus(scene, model, weaponFiles);
  }

  private readonly root = new THREE.Group();
  private readonly fit = new THREE.Group();
  /** 보완 자세의 손 위치를 모델 크기에 맞추는 공간 */
  private readonly poseSpace = new THREE.Group();
  private readonly bones: Partial<Record<BoneKey, THREE.Object3D>> = {};
  private readonly restQuats = new Map<THREE.Object3D, THREE.Quaternion>();
  private readonly mixer: THREE.AnimationMixer;
  private readonly actions: Partial<Record<ClipKey, THREE.AnimationAction>> = {};
  private readonly weights = new Map<THREE.AnimationAction, number>();
  private readonly weapons: Partial<Record<WeaponKey, WeaponNode>> = {};
  private readonly flash = { value: 0 };
  private readonly trail = new SpearTrail();
  private readonly kit = new ToonMaterialKit();
  private bowString: THREE.Line | null = null;
  private lastState = '';
  /** 걷기·달리기 동작을 1배속으로 틀 때 나아가는 속도 (골반이 앞으로 가는 동작이면 그 거리로 잼) */
  private readonly clipSpeed = { walk: AVATAR_CONFIG.walkClipSpeed, run: AVATAR_CONFIG.runClipSpeed };
  /** 공격 디딤 자세: 지금 섞인 정도와 발 위치·골반 높이 (몸 기준, 부드럽게 따라감) */
  private readonly stance = { weight: 0, front: 0, back: 0, width: 0, drop: 0 };
  /** 서 있을 때 발목 높이 (게임 단위) */
  private ankleHeight = 0.1;
  /** 골반 위치 트랙이 없는 동작에서도 디딤 자세로 낮춘 높이가 쌓이지 않게 매 프레임 되돌릴 위치 */
  private readonly restHipsPos = new THREE.Vector3();
  /** 동작 파일을 틀 때 주무기를 대기 방향으로 내려 드는 정도 (0~1) */
  private spearIdleWeight = 1;

  private readonly v1 = new THREE.Vector3();
  private readonly v2 = new THREE.Vector3();
  private readonly v3 = new THREE.Vector3();
  private readonly v4 = new THREE.Vector3();
  private readonly q1 = new THREE.Quaternion();
  private readonly q2 = new THREE.Quaternion();

  private constructor(scene: THREE.Scene, gltf: LoadedModel, weaponFiles: Record<WeaponKey, THREE.Object3D | null>) {
    const model = gltf.scene;
    this.fit.add(model);
    this.root.add(this.fit);
    this.root.add(this.poseSpace);
    this.poseSpace.scale.setScalar(AVATAR_CONFIG.height / POSE_SPACE_HEIGHT);
    scene.add(this.root);
    scene.add(this.trail.mesh);

    this.fitToGame(model);
    this.findBones(model);
    const foot = this.bones.leftFoot;
    if (foot) this.ankleHeight = this.root.worldToLocal(foot.getWorldPosition(this.v1)).y;
    if (this.bones.hips) this.restHipsPos.copy(this.bones.hips.position);
    this.applyShading(model);
    this.mixer = new THREE.AnimationMixer(model);
    this.setupClips(gltf.animations);
    this.attachWeapons(weaponFiles);
  }

  public dispose(scene: THREE.Scene): void {
    scene.remove(this.root);
    scene.remove(this.trail.mesh);
  }

  // ---------------------------------------------------------------- 불러올 때 한 번

  /** 키를 게임 기준으로 맞추고, 발바닥을 y=0에, 몸 중심을 원점에 둠 */
  private fitToGame(model: THREE.Object3D): void {
    this.fit.rotation.y = THREE.MathUtils.degToRad(AVATAR_CONFIG.yawOffsetDeg);
    model.updateMatrixWorld(true);
    const box = new THREE.Box3().setFromObject(model);
    const size = box.getSize(this.v1);
    const center = box.getCenter(this.v2);
    const scale = AVATAR_CONFIG.height / Math.max(size.y, 1e-4);
    model.scale.multiplyScalar(scale);
    model.position.set(-center.x * scale, -box.min.y * scale, -center.z * scale);
    this.root.updateMatrixWorld(true);
    console.info(TAG, `원래 키 ${size.y.toFixed(3)} → ${AVATAR_CONFIG.height} (배율 ${scale.toFixed(4)})`);
  }

  private findBones(model: THREE.Object3D): void {
    const byName = new Map<string, THREE.Object3D>();
    const allBones: string[] = [];
    model.traverse((o) => {
      if ((o as THREE.Bone).isBone) allBones.push(o.name);
      const key = normalizeName(o.name);
      if (key && !byName.has(key)) byName.set(key, o);
    });
    for (const key of Object.keys(AVATAR_CONFIG.bones) as BoneKey[]) {
      for (const cand of AVATAR_CONFIG.bones[key]) {
        const found = byName.get(cand);
        if (found) {
          this.bones[key] = found;
          this.restQuats.set(found, found.quaternion.clone());
          break;
        }
      }
    }
    console.info(TAG, '뼈 이름:', allBones);
    console.info(
      TAG,
      '찾은 뼈:',
      Object.fromEntries((Object.keys(AVATAR_CONFIG.bones) as BoneKey[]).map((k) => [k, this.bones[k]?.name ?? '(없음)']))
    );
  }

  private applyShading(model: THREE.Object3D): void {
    const gradient = new THREE.DataTexture(new Uint8Array([90, 170, 255]), 3, 1, THREE.RedFormat);
    gradient.minFilter = gradient.magFilter = THREE.NearestFilter;
    gradient.needsUpdate = true;

    const meshes: THREE.Mesh[] = [];
    model.traverse((o) => {
      if ((o as THREE.Mesh).isMesh) meshes.push(o as THREE.Mesh);
    });
    for (const mesh of meshes) {
      mesh.frustumCulled = false;
      const convert = (m: THREE.Material): THREE.Material => {
        const src = m as THREE.MeshStandardMaterial;
        // 비스듬히 내려다보는 카메라라 텍스처가 뭉개지지 않게 이방성 필터 (지원 최대치로 자동 제한됨)
        if (src.map) src.map.anisotropy = 8;
        const common = {
          map: src.map ?? null,
          // FBX는 텍스처가 있어도 색을 0.8 회색으로 두는 경우가 많아, 텍스처가 있으면 흰색으로
          color: src.map || !src.color ? new THREE.Color(1, 1, 1) : src.color.clone(),
          transparent: src.transparent,
          alphaTest: src.alphaTest,
          side: src.side,
          vertexColors: src.vertexColors,
        };
        const out =
          AVATAR_CONFIG.shading === 'unlit'
            ? new THREE.MeshBasicMaterial(common)
            : AVATAR_CONFIG.shading === 'toon'
              ? new THREE.MeshToonMaterial({ ...common, gradientMap: gradient })
              : m;
        this.patchFlash(out);
        return out;
      };
      mesh.material = Array.isArray(mesh.material) ? mesh.material.map(convert) : convert(mesh.material);
      if (AVATAR_CONFIG.outline > 0) this.addOutline(mesh);
    }
  }

  /** 맞았을 때 하얗게 번쩍이게 재료 끝에 한 줄 끼움 */
  private patchFlash(mat: THREE.Material): void {
    mat.onBeforeCompile = (shader) => {
      shader.uniforms.uFlash = this.flash;
      shader.fragmentShader =
        'uniform float uFlash;\n' +
        shader.fragmentShader.replace(
          '#include <opaque_fragment>',
          '#include <opaque_fragment>\n  gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(1.0), uFlash);'
        );
    };
    mat.needsUpdate = true;
  }

  /** 뒷면을 법선 방향으로 조금 부풀린 검은 껍데기 (뼈 움직임도 같이 따라감) */
  private addOutline(mesh: THREE.Mesh): void {
    const worldScale = mesh.getWorldScale(this.v1).x || 1;
    const mat = new THREE.MeshBasicMaterial({ color: '#140a06', side: THREE.BackSide });
    const thickness = AVATAR_CONFIG.outline / worldScale;
    mat.onBeforeCompile = (shader) => {
      shader.uniforms.uThick = { value: thickness };
      shader.vertexShader =
        'uniform float uThick;\n' +
        shader.vertexShader.replace('#include <begin_vertex>', '#include <begin_vertex>\n  transformed += normal * uThick;');
    };
    let outline: THREE.Mesh;
    if ((mesh as THREE.SkinnedMesh).isSkinnedMesh) {
      const skinned = mesh as THREE.SkinnedMesh;
      const s = new THREE.SkinnedMesh(skinned.geometry, mat);
      s.bind(skinned.skeleton, skinned.bindMatrix);
      outline = s;
    } else {
      outline = new THREE.Mesh(mesh.geometry, mat);
    }
    outline.frustumCulled = false;
    mesh.add(outline);
  }

  private setupClips(clips: THREE.AnimationClip[]): void {
    const hipsName = this.bones.hips?.name;
    for (const clip of clips) {
      // 골반 말고 다른 뼈의 위치·크기 트랙은 버림 (뼈 길이는 모델 그대로 두고 회전만 씀)
      clip.tracks = clip.tracks.filter((t) => !/\.(position|scale)$/.test(t.name) || t.name === `${hipsName}.position`);
      for (const key of ['walk', 'run'] as const) {
        if (clip.name === `${CLIP_FILE_PREFIX}${key}` || clip === this.findClip(clips, AVATAR_CONFIG.clips[key])) {
          this.measureLocoSpeed(key, clip, hipsName);
        }
      }
      // 제자리 동작으로: 골반의 앞뒤·좌우는 기본 자리에 고정하고 위아래 출렁임만 남김 (이동 거리는 게임 로직이 정함)
      // 콤보를 잘라 쓴 조각은 시작 위치가 앞으로 가 있으므로 동작 첫 값이 아니라 기본 자리로 맞춤
      for (const track of clip.tracks) {
        if (!hipsName || track.name !== `${hipsName}.position`) continue;
        const v = track.values;
        for (let i = 0; i < v.length; i += 3) {
          v[i] = this.restHipsPos.x;
          v[i + 2] = this.restHipsPos.z;
        }
      }
    }
    for (const key of Object.keys(AVATAR_CONFIG.clips) as ClipKey[]) {
      const clip =
        clips.find((c) => c.name === `${CLIP_FILE_PREFIX}${key}`) ?? this.findClip(clips, AVATAR_CONFIG.clips[key]);
      if (!clip) continue;
      const action = this.mixer.clipAction(clip);
      action.play();
      action.setEffectiveWeight(0);
      this.actions[key] = action;
      this.weights.set(action, 0);
    }
    console.info(TAG, '동작 이름:', clips.map((c) => `${c.name} (${c.duration.toFixed(2)}초)`));
    console.info(
      TAG,
      '연결한 동작:',
      Object.fromEntries((Object.keys(AVATAR_CONFIG.clips) as ClipKey[]).map((k) => [k, this.actions[k]?.getClip().name ?? '(없음 → 보완 자세)']))
    );
  }

  /** In Place를 끈 걷기·달리기는 골반이 한 바퀴에 간 거리를 게임 단위로 바꿔 재생 속도 기준으로 씀 */
  private measureLocoSpeed(key: 'walk' | 'run', clip: THREE.AnimationClip, hipsName: string | undefined): void {
    const track = clip.tracks.find((t) => t.name === `${hipsName}.position`);
    const hipsParent = this.bones.hips?.parent;
    if (!track || !hipsParent || clip.duration <= 0) return;
    const v = track.values;
    const n = v.length;
    const distance = Math.hypot(v[n - 3] - v[0], v[n - 1] - v[2]) * hipsParent.getWorldScale(this.v1).x;
    if (distance < 0.1) return; // 제자리 동작이면 설정값 그대로
    this.clipSpeed[key] = distance / clip.duration;
    console.info(TAG, `${key} 동작 속도 ${this.clipSpeed[key].toFixed(2)} (골반 이동으로 잼)`);
  }

  private findClip(clips: THREE.AnimationClip[], candidates: string[]): THREE.AnimationClip | null {
    for (const cand of candidates) {
      const found = clips.find((c) => c.name.toLowerCase().includes(cand));
      if (found) return found;
    }
    return null;
  }

  private attachWeapons(files: Record<WeaponKey, THREE.Object3D | null>): void {
    for (const key of Object.keys(AVATAR_CONFIG.weapons) as WeaponKey[]) {
      const cfg: WeaponMount = AVATAR_CONFIG.weapons[key];
      const bone = this.bones[cfg.bone];
      if (!bone) {
        console.warn(TAG, `${key}: 붙일 뼈(${cfg.bone})를 못 찾아 무기를 뺍니다`);
        continue;
      }
      const mount = new THREE.Group();
      // 뼈의 배율을 되돌려 mount 안에서는 게임 단위로 위치·크기를 적을 수 있게 함
      const s = bone.getWorldScale(this.v1);
      mount.scale.set(1 / s.x, 1 / s.y, 1 / s.z);
      bone.add(mount);
      const offset = new THREE.Group();
      offset.position.fromArray(cfg.position);
      offset.rotation.set(...(cfg.rotation.map((d) => THREE.MathUtils.degToRad(d)) as [number, number, number]));
      mount.add(offset);

      const file = files[key];
      const tipLocal = new THREE.Vector3();
      if (file) {
        offset.add(this.normalizeWeapon(key, file, cfg, tipLocal));
        console.info(TAG, `${key}: ${cfg.url} 사용`);
      } else {
        offset.add(this.fallbackWeapon(key, cfg, tipLocal));
        console.info(TAG, `${key}: 파일이 없어 도형 무기 사용`);
      }
      this.weapons[key] = { mount: offset, tipLocal };
    }
    if (AVATAR_CONFIG.drawBowString && this.weapons.bow) {
      const geo = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3()]);
      this.bowString = new THREE.Line(geo, new THREE.LineBasicMaterial({ color: '#efe6d2' }));
      this.bowString.frustumCulled = false;
      this.root.parent?.add(this.bowString);
    }
  }

  /**
   * 무기 파일을 정해진 축으로 돌리고 크기를 맞춤.
   * 창·활: 가장 긴 변을 +Y로 (창은 손잡이 자리가 원점), 방패: 가장 얇은 변을 +Z(앞면)로
   */
  private normalizeWeapon(key: WeaponKey, file: THREE.Object3D, cfg: WeaponMount, tipOut: THREE.Vector3): THREE.Object3D {
    const norm = new THREE.Group();
    const rot = new THREE.Group();
    rot.add(file);
    norm.add(rot);
    file.updateMatrixWorld(true);
    const size = new THREE.Box3().setFromObject(file).getSize(new THREE.Vector3());
    const axes = [new THREE.Vector3(1, 0, 0), new THREE.Vector3(0, 1, 0), new THREE.Vector3(0, 0, 1)];
    const dims = [size.x, size.y, size.z];
    const pick = key === 'shield' ? dims.indexOf(Math.min(...dims)) : dims.indexOf(Math.max(...dims));
    const target = key === 'shield' ? new THREE.Vector3(0, 0, 1) : new THREE.Vector3(0, 1, 0);
    rot.quaternion.setFromUnitVectors(axes[pick], target);
    if (cfg.flip) rot.quaternion.premultiply(new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), Math.PI));

    rot.updateMatrixWorld(true);
    const box = new THREE.Box3().setFromObject(rot);
    const bsize = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());
    const longest = Math.max(bsize.x, bsize.y, bsize.z);
    const scale = cfg.size / Math.max(longest, 1e-4);
    norm.scale.setScalar(scale);
    norm.position.copy(center).multiplyScalar(-scale);
    if (key === 'spear') {
      // 손잡이 자리를 원점으로: 창 아래끝에서 spearGrip 비율만큼 올라간 곳
      norm.position.y += cfg.size / 2 - AVATAR_CONFIG.spearGrip * cfg.size;
      tipOut.set(0, cfg.size * (1 - AVATAR_CONFIG.spearGrip), 0);
    } else if (key === 'bow') {
      tipOut.set(0, cfg.size * 0.48, 0);
    }
    return norm;
  }

  private fallbackWeapon(key: WeaponKey, cfg: WeaponMount, tipOut: THREE.Vector3): THREE.Object3D {
    if (key === 'spear') {
      const prop = buildSwordProp(this.kit);
      const length = SWORD_TIP - SWORD_POMMEL;
      prop.scale.setScalar(cfg.size / length);
      tipOut.set(0, SWORD_TIP * (cfg.size / length), 0);
      return prop;
    }
    if (key === 'shield') {
      const prop = buildShieldProp(this.kit);
      prop.scale.setScalar(cfg.size / 0.8);
      return prop;
    }
    const prop = buildBowProp(this.kit, !AVATAR_CONFIG.drawBowString);
    const scale = cfg.size / 0.84;
    prop.scale.setScalar(scale);
    tipOut.copy(BOW_TIPS[0]).multiplyScalar(scale);
    return prop;
  }

  // ---------------------------------------------------------------- 매 프레임

  public update(p: PlayerEntity, motion: AvatarMotion, poses: PoseDriver, dt: number): void {
    if (dt <= 0) return;
    if (p.state !== this.lastState) this.onStateEnter(p);
    this.lastState = p.state;

    const { clipKey, progress } = this.stateClip(p);
    const playing = clipKey ? this.actions[clipKey] : undefined;
    const fillIn = !playing && this.needsFillIn(p);

    this.root.position.set(p.x, 0, p.z);
    this.root.rotation.y = motion.rootYaw + (fillIn ? poses.spin : 0);

    this.updateWeights(p, motion, playing, progress, dt);
    for (const [bone, q] of this.restQuats) bone.quaternion.copy(q);
    this.bones.hips?.position.copy(this.restHipsPos);
    this.mixer.update(dt);
    this.root.updateMatrixWorld(true);

    this.applyBodyLean(p, motion, fillIn ? poses : null);
    if (fillIn) this.applyFillInArms(poses);
    else this.aimSpearWithClip(p, dt);
    this.applyAttackStance(p, fillIn, dt);
    this.updateGearVisibility(fillIn ? poses.current.stow : p.state.startsWith('bow') ? 1 : 0);
    this.updateBowString(p);

    this.trail.setColor(p.comboStep === 3 ? '#fb923c' : '#fde68a');
    const spear = this.weapons.spear;
    const emitTrail = spearProgress(p) !== null && (fillIn ? poses.trail : p.state === 'spear_swing');
    if (spear) {
      const tip = spear.mount.localToWorld(this.v1.copy(spear.tipLocal));
      const base = spear.mount.localToWorld(this.v2.copy(spear.tipLocal).multiplyScalar(0.3));
      this.trail.update(dt, emitTrail, tip, base);
    }
    this.flash.value = Math.min(1, p.hitFlashTimer * 5) * 0.75;
  }

  private onStateEnter(p: PlayerEntity): void {
    // 대시·패링은 들어갈 때 동작을 처음부터
    if (p.state === 'dash') this.actions.dash?.reset().play();
  }

  /** 지금 상태에 쓸 동작과, 시간을 직접 맞출 동작이면 그 진행도(0~1) */
  private stateClip(p: PlayerEntity): { clipKey: ClipKey | null; progress: number | null } {
    const spear = spearProgress(p);
    if (spear) {
      const key = `spear${spear.step}` as 'spear1' | 'spear2' | 'spear3';
      const hit = AVATAR_CONFIG.attackHitTime[key];
      const progress =
        spear.phase === 'windup'
          ? spear.t * (hit - 0.08)
          : spear.phase === 'swing'
            ? hit - 0.08 + spear.t * 0.16
            : hit + 0.08 + spear.t * (1 - hit - 0.08);
      return { clipKey: key, progress };
    }
    switch (p.state) {
      case 'dash':
        return { clipKey: 'dash', progress: (1 - p.stateTimer / COMBAT_CONFIG.player.dash.duration) * 0.75 };
      case 'parry_active': {
        const hit = AVATAR_CONFIG.attackHitTime.parry;
        return { clipKey: 'parry', progress: (1 - p.stateTimer / COMBAT_CONFIG.player.parry.activeDuration) * hit };
      }
      case 'parry_recovery': {
        const hit = AVATAR_CONFIG.attackHitTime.parry;
        return { clipKey: 'parry', progress: hit + (1 - p.stateTimer / COMBAT_CONFIG.player.parry.recoveryDuration) * (1 - hit) };
      }
      case 'bow_charge':
        return { clipKey: 'bow', progress: p.bowCharge * 0.5 };
      case 'bow_recovery':
        return { clipKey: 'bow', progress: 0.5 + (1 - p.stateTimer / COMBAT_CONFIG.player.bow.postFireRecovery) * 0.5 };
      default:
        return { clipKey: null, progress: null };
    }
  }

  private needsFillIn(p: PlayerEntity): boolean {
    return p.state !== 'idle' && p.state !== 'move';
  }

  private updateWeights(
    p: PlayerEntity,
    motion: AvatarMotion,
    playing: THREE.AnimationAction | undefined,
    progress: number | null,
    dt: number
  ): void {
    const speed = motion.speed;
    const targets = new Map<THREE.AnimationAction, number>();
    for (const action of this.weights.keys()) targets.set(action, 0);

    if (playing) {
      targets.set(playing, 1);
      if (progress !== null) {
        playing.paused = true;
        playing.time = clamp(progress, 0, 0.999) * playing.getClip().duration;
      }
    } else {
      // 이동 동작 (보완 자세를 쓰는 상태도 다리는 이 동작을 따름): 대기 → 걷기 → 달리기를 속도로 섞음
      const { idle, walk, run } = this.actions;
      const moving = idle ? THREE.MathUtils.smoothstep(speed, 0.3, walk ? 1.2 : 4.5) : 1;
      const runShare = walk && run ? THREE.MathUtils.smoothstep(speed, this.clipSpeed.walk * 1.1, this.clipSpeed.run * 0.6) : run ? 1 : 0;
      if (idle) {
        targets.set(idle, 1 - moving);
        idle.paused = false;
      }
      if (walk) {
        targets.set(walk, moving * (1 - runShare));
        walk.paused = false;
        walk.timeScale = clamp(speed / this.clipSpeed.walk, 0.6, 1.8);
      }
      if (run) {
        targets.set(run, moving * runShare);
        run.paused = false;
        run.timeScale = Math.max(0.5, speed / this.clipSpeed.run);
      }
    }

    const rate = playing && p.state !== 'idle' && p.state !== 'move' ? 30 : 12;
    const k = approach(rate, dt);
    for (const [action, w] of this.weights) {
      const next = w + ((targets.get(action) ?? 0) - w) * k;
      this.weights.set(action, next);
      action.setEffectiveWeight(next);
    }
  }

  /** 속도 변화에 따른 몸 기울기, 조준 쪽을 보는 머리, 보완 자세의 상체 비틀기 */
  private applyBodyLean(p: PlayerEntity, motion: AvatarMotion, fill: PoseDriver | null): void {
    const up = this.v3.set(0, 1, 0);
    const right = this.v4.set(1, 0, 0).applyQuaternion(this.root.quaternion);
    const spine = this.bones.spine;
    if (spine) {
      let pitch = motion.leanForward;
      let yaw = 0;
      if (fill) {
        pitch += fill.current.spinePitch * 0.6;
        yaw += fill.current.hipYaw + fill.current.spineYaw;
      }
      this.q1.setFromAxisAngle(right, pitch);
      this.q2.setFromAxisAngle(up, yaw);
      this.rotateBoneWorld(spine, this.q2.multiply(this.q1));
      const forward = this.v1.set(0, 0, 1).applyQuaternion(this.root.quaternion);
      this.rotateBoneWorld(spine, this.q1.setFromAxisAngle(forward, -motion.leanSide));
    }
    const head = this.bones.head;
    if (head) {
      const back = fill ? -(fill.current.hipYaw + fill.current.spineYaw) * 0.85 : 0;
      this.rotateBoneWorld(head, this.q1.setFromAxisAngle(up, motion.lookYaw(p) + back));
    }
    this.root.updateMatrixWorld(true);
  }

  /**
   * 동작 파일을 틀 때 주무기 방향. 공격 중엔 검 동작이 손 방향을 그대로 쓰도록 두고,
   * 대기·이동(맨손 동작)에선 spearIdleDir 쪽으로 내려 듦. 둘 사이는 섞는 비율로 부드럽게 넘어감
   */
  private aimSpearWithClip(p: PlayerEntity, dt: number): void {
    const spear = this.weapons.spear;
    const hand = this.bones.rightHand;
    const c = AVATAR_CONFIG.spearIdleDir;
    if (!spear || !hand || !c || !spear.mount.visible) return;
    const idle = !spearProgress(p) && !p.state.startsWith('parry');
    this.spearIdleWeight += ((idle ? 1 : 0) - this.spearIdleWeight) * approach(idle ? 8 : 25, dt);
    if (this.spearIdleWeight < 0.01) return;
    spear.mount.updateWorldMatrix(true, false);
    const now = this.v1.set(0, 1, 0).transformDirection(spear.mount.matrixWorld);
    const want = this.v3.set(c[0], c[1], c[2]).applyQuaternion(this.root.quaternion).normalize();
    this.alignWeaponAxis(hand, spear.mount, new THREE.Vector3(0, 1, 0), now.lerp(want, this.spearIdleWeight).normalize());
    this.root.updateMatrixWorld(true);
  }

  /**
   * 창 공격 동작 파일이 없을 때의 하체: 준비 동안 왼발을 앞·오른발을 뒤로 벌리며 골반을 낮추고,
   * 휘두를 때 가장 깊게, 회복하며 대기 자세로 돌아옴. 발은 다리 IK로 디딤 자리에 둠
   */
  private applyAttackStance(p: PlayerEntity, fillIn: boolean, dt: number): void {
    const spear = fillIn ? spearProgress(p) : null;
    const st = this.stance;
    let want = 0;
    if (spear) {
      want = spear.phase === 'windup' ? 0.4 + 0.6 * THREE.MathUtils.smoothstep(spear.t, 0, 1) : spear.phase === 'swing' ? 1 : 1 - THREE.MathUtils.smoothstep(spear.t, 0.35, 1);
      const cfg = AVATAR_CONFIG.attackStance[spear.step as 1 | 2 | 3];
      const k = approach(25, dt);
      st.front += (cfg.front - st.front) * k;
      st.back += (cfg.back - st.back) * k;
      st.width += (cfg.width - st.width) * k;
      st.drop += (cfg.drop - st.drop) * k;
    }
    st.weight += (want - st.weight) * approach(spear ? 30 : 14, dt);
    const w = st.weight;
    const b = this.bones;
    if (w < 0.01 || !b.hips || !b.leftUpLeg || !b.leftLeg || !b.leftFoot || !b.rightUpLeg || !b.rightLeg || !b.rightFoot) return;

    // 골반을 낮춤 (부모 공간의 배율을 되돌려 게임 단위로)
    const parentScale = b.hips.parent!.getWorldScale(this.v1).y;
    b.hips.position.y -= (st.drop * w) / parentScale;
    b.hips.updateWorldMatrix(false, true);

    const pole = this.v2.set(0, 0, 1).applyQuaternion(this.root.quaternion);
    const legs: [THREE.Object3D, THREE.Object3D, THREE.Object3D, number, number][] = [
      [b.leftUpLeg, b.leftLeg, b.leftFoot, st.width, st.front],
      [b.rightUpLeg, b.rightLeg, b.rightFoot, -st.width, -st.back],
    ];
    for (const [upper, lower, foot, x, z] of legs) {
      const footQuat = foot.getWorldQuaternion(this.q2);
      const now = this.root.worldToLocal(foot.getWorldPosition(this.v3));
      const target = this.root.localToWorld(now.lerp(this.v4.set(x, this.ankleHeight, z), w));
      this.solveTwoBone(upper, lower, foot, target, pole);
      // 발바닥은 IK 전 방향 그대로 (땅에 붙어 있게)
      const after = foot.getWorldQuaternion(new THREE.Quaternion()).invert();
      this.rotateBoneWorld(foot, footQuat.clone().multiply(after));
    }
    this.root.updateMatrixWorld(true);
  }

  /** 동작 파일이 없는 상태: 도형 모델 자세의 손 위치로 팔을 뻗고, 무기 방향을 맞춤 */
  private applyFillInArms(poses: PoseDriver): void {
    const c = poses.current;
    const b = this.bones;
    if (b.rightArm && b.rightForeArm && b.rightHand) {
      const target = this.poseSpace.localToWorld(this.v1.set(c.handRx, c.handRy, c.handRz));
      const pole = this.v2.copy(POLE_R).transformDirection(this.poseSpace.matrixWorld);
      this.solveTwoBone(b.rightArm, b.rightForeArm, b.rightHand, target, pole);
      const spear = this.weapons.spear;
      if (spear) {
        const want = this.v3.set(c.spearX, c.spearY, c.spearZ).transformDirection(this.poseSpace.matrixWorld);
        this.alignWeaponAxis(b.rightHand, spear.mount, new THREE.Vector3(0, 1, 0), want);
      }
    }
    if (b.leftArm && b.leftForeArm && b.leftHand) {
      const target = this.poseSpace.localToWorld(this.v1.set(c.handLx, c.handLy, c.handLz));
      const pole = this.v2.copy(POLE_L).transformDirection(this.poseSpace.matrixWorld);
      this.solveTwoBone(b.leftArm, b.leftForeArm, b.leftHand, target, pole);
      const shield = this.weapons.shield;
      if (shield && c.stow < 0.5) {
        const want = this.v3.set(c.shieldX, c.shieldY, c.shieldZ).transformDirection(this.poseSpace.matrixWorld);
        const bone = this.bones[AVATAR_CONFIG.weapons.shield.bone]!;
        this.alignWeaponAxis(bone, shield.mount, new THREE.Vector3(0, 0, 1), want);
      }
    }
    this.root.updateMatrixWorld(true);
  }

  /** 활을 쏠 때는 창·방패를 숨기고 활을 보이게 (등에 메는 자리는 실제 모델을 보고 정함) */
  private updateGearVisibility(stow: number): void {
    const bowOut = stow > 0.5;
    if (this.weapons.spear) this.weapons.spear.mount.visible = !bowOut;
    if (this.weapons.shield) this.weapons.shield.mount.visible = !bowOut;
    if (this.weapons.bow) this.weapons.bow.mount.visible = bowOut;
    if (this.bowString) this.bowString.visible = bowOut;
  }

  /** 활시위: 활 위·아래 끝을 잇고, 당기는 동안 가운데를 오른손 쪽으로 끌어옴 */
  private updateBowString(p: PlayerEntity): void {
    const bow = this.weapons.bow;
    if (!this.bowString || !bow || !this.bowString.visible) return;
    const top = bow.mount.localToWorld(this.v1.copy(bow.tipLocal));
    const bottom = bow.mount.localToWorld(this.v2.copy(bow.tipLocal).setY(-bow.tipLocal.y));
    const mid = this.v3.addVectors(top, bottom).multiplyScalar(0.5);
    const hand = this.bones.rightHand;
    if (hand && p.state === 'bow_charge') {
      const handPos = hand.getWorldPosition(this.v4);
      mid.lerp(handPos, clamp(p.bowCharge * 1.4, 0, 1));
    }
    const attr = this.bowString.geometry.getAttribute('position') as THREE.BufferAttribute;
    attr.setXYZ(0, top.x, top.y, top.z);
    attr.setXYZ(1, mid.x, mid.y, mid.z);
    attr.setXYZ(2, bottom.x, bottom.y, bottom.z);
    attr.needsUpdate = true;
  }

  // ---------------------------------------------------------------- 뼈 다루기

  /** 뼈를 월드 기준으로 delta만큼 더 돌림 */
  private rotateBoneWorld(bone: THREE.Object3D, delta: THREE.Quaternion): void {
    const world = bone.getWorldQuaternion(new THREE.Quaternion());
    const parent = bone.parent!.getWorldQuaternion(new THREE.Quaternion()).invert();
    bone.quaternion.copy(parent.multiply(delta.clone().multiply(world)));
    bone.updateWorldMatrix(false, true);
  }

  /** 무기의 축(무기 로컬)이 want(월드)를 향하도록 손 뼈를 돌림 */
  private alignWeaponAxis(bone: THREE.Object3D, mount: THREE.Object3D, axisLocal: THREE.Vector3, want: THREE.Vector3): void {
    mount.updateWorldMatrix(true, false);
    const now = axisLocal.clone().transformDirection(mount.matrixWorld);
    this.rotateBoneWorld(bone, new THREE.Quaternion().setFromUnitVectors(now, want.clone().normalize()));
  }

  /** 뼈 축 방향과 상관없이 쓰는 2관절 IK: 현재 방향에서 원하는 방향으로 돌리는 만큼만 돌림 */
  private solveTwoBone(
    upper: THREE.Object3D,
    fore: THREE.Object3D,
    hand: THREE.Object3D,
    target: THREE.Vector3,
    pole: THREE.Vector3
  ): void {
    const a = upper.getWorldPosition(new THREE.Vector3());
    const b = fore.getWorldPosition(new THREE.Vector3());
    const c = hand.getWorldPosition(new THREE.Vector3());
    const lenA = a.distanceTo(b);
    const lenB = b.distanceTo(c);
    const dir = target.clone().sub(a);
    const dist = clamp(dir.length(), 0.01, lenA + lenB - 1e-4);
    dir.normalize();
    const cosA = clamp((lenA * lenA + dist * dist - lenB * lenB) / (2 * lenA * dist), -1, 1);
    const bend = pole.clone().addScaledVector(dir, -pole.dot(dir));
    if (bend.lengthSq() < 1e-8) bend.set(0, -1, 0);
    bend.normalize();
    const upperDir = dir.clone().multiplyScalar(cosA).addScaledVector(bend, Math.sqrt(1 - cosA * cosA));
    const elbow = a.clone().addScaledVector(upperDir, lenA);
    const wrist = a.clone().addScaledVector(dir, dist);

    const curUpper = b.clone().sub(a).normalize();
    this.rotateBoneWorld(upper, new THREE.Quaternion().setFromUnitVectors(curUpper, upperDir));
    const b2 = fore.getWorldPosition(new THREE.Vector3());
    const c2 = hand.getWorldPosition(new THREE.Vector3());
    const curFore = c2.sub(b2).normalize();
    const wantFore = wrist.sub(elbow).normalize();
    this.rotateBoneWorld(fore, new THREE.Quaternion().setFromUnitVectors(curFore, wantFore));
  }
}
