import * as THREE from 'three';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';
import { COMBAT_CONFIG } from '../data/combatConfig';
import { WorldSimulation } from '../combat/WorldSimulation';
import { ProceduralSprites } from './ProceduralSprites';
import { EnemyEntity, SceneId, Vec2 } from '../types/combat';

interface EnemyVisualNode {
  group: THREE.Group;
  spriteMesh: THREE.Mesh<THREE.PlaneGeometry, THREE.MeshBasicMaterial>;
  shadowMesh: THREE.Mesh<THREE.CircleGeometry, THREE.MeshBasicMaterial>;
  facingArrow: THREE.Mesh<THREE.ConeGeometry, THREE.MeshBasicMaterial>;
  shieldRing: THREE.Mesh<THREE.RingGeometry, THREE.MeshBasicMaterial>;
  weakPointRing: THREE.Mesh<THREE.RingGeometry, THREE.MeshBasicMaterial>;
  telegraphGroup: THREE.Group;
}

export class SceneRenderer25D {
  public scene: THREE.Scene;
  public camera: THREE.PerspectiveCamera;
  public renderer: THREE.WebGLRenderer;
  public composer: EffectComposer;
  public sprites: ProceduralSprites;

  private raycaster = new THREE.Raycaster();
  private groundPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);

  private environmentGroup = new THREE.Group();
  private renderedSceneId: SceneId | null = null;
  private ambientParticles: THREE.Points | null = null;

  private playerGroup: THREE.Group;
  private playerSprite: THREE.Mesh<THREE.PlaneGeometry, THREE.MeshBasicMaterial>;
  private playerFacingRing: THREE.Group;
  private bowAimLine: THREE.Mesh<THREE.PlaneGeometry, THREE.MeshBasicMaterial>;
  private weakPointSightline: THREE.Line;

  private enemyNodes = new Map<number, EnemyVisualNode>();
  private swingGroup = new THREE.Group();
  private projectileGroup = new THREE.Group();
  private shockwaveGroup = new THREE.Group();
  private lightningGroup = new THREE.Group();

  private readonly cameraPitchRad = (38 * Math.PI) / 180;
  private readonly cameraDistance = 22.5;
  private cameraTarget = new THREE.Vector3(0, 0, 1.5);

  constructor(canvas: HTMLCanvasElement, world: WorldSimulation) {
    this.sprites = new ProceduralSprites();

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color('#061018');
    this.scene.fog = new THREE.FogExp2('#061018', 0.013);

    this.camera = new THREE.PerspectiveCamera(
      40,
      window.innerWidth / window.innerHeight,
      0.1,
      140
    );

    this.renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      powerPreference: 'high-performance',
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.12;

    // UnrealBloomPass 포스트프로세싱 (레퍼런스 일러스트의 발광 이끼·청백색 화살·황금 공명·화로 불빛 재현)
    this.composer = new EffectComposer(this.renderer);
    const renderPass = new RenderPass(this.scene, this.camera);
    this.composer.addPass(renderPass);

    const bloomPass = new UnrealBloomPass(
      new THREE.Vector2(window.innerWidth, window.innerHeight),
      0.42, // strength
      0.55, // radius
      0.72  // threshold
    );
    this.composer.addPass(bloomPass);

    this.scene.add(this.environmentGroup);

    // 플레이어 비주얼 그룹
    this.playerGroup = new THREE.Group();
    this.scene.add(this.playerGroup);

    const shadowGeo = new THREE.CircleGeometry(0.75, 28);
    shadowGeo.rotateX(-Math.PI / 2);
    const playerShadow = new THREE.Mesh(
      shadowGeo,
      new THREE.MeshBasicMaterial({ color: '#030b10', transparent: true, opacity: 0.68 })
    );
    playerShadow.position.y = 0.02;
    this.playerGroup.add(playerShadow);

    this.playerFacingRing = new THREE.Group();
    const ringGeo = new THREE.RingGeometry(0.74, 0.86, 36);
    ringGeo.rotateX(-Math.PI / 2);
    const ringMesh = new THREE.Mesh(
      ringGeo,
      new THREE.MeshBasicMaterial({ color: '#d4a853', side: THREE.DoubleSide })
    );
    ringMesh.position.y = 0.03;
    this.playerFacingRing.add(ringMesh);

    const pointerGeo = new THREE.CircleGeometry(0.36, 3);
    pointerGeo.rotateX(-Math.PI / 2);
    const pointerMesh = new THREE.Mesh(
      pointerGeo,
      new THREE.MeshBasicMaterial({ color: '#fef08a', side: THREE.DoubleSide })
    );
    pointerMesh.position.set(1.02, 0.04, 0);
    this.playerFacingRing.add(pointerMesh);
    this.playerGroup.add(this.playerFacingRing);

    // 청백색 차징 화살 조준선
    const aimLineGeo = new THREE.PlaneGeometry(1, 0.18);
    aimLineGeo.rotateX(-Math.PI / 2);
    aimLineGeo.translate(0.5, 0, 0);
    this.bowAimLine = new THREE.Mesh(
      aimLineGeo,
      new THREE.MeshBasicMaterial({
        color: '#e0f2fe',
        transparent: true,
        opacity: 0.88,
        side: THREE.DoubleSide,
      })
    );
    this.bowAimLine.position.y = 0.06;
    this.bowAimLine.visible = false;
    this.playerGroup.add(this.bowAimLine);

    // Scene 4: 화살 끝과 보스의 금빛 외눈 사이에 만들어지는 시선의 선 (Sightline)
    const sightGeo = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0, 1.2, 0),
      new THREE.Vector3(0, 2.5, -5),
    ]);
    this.weakPointSightline = new THREE.Line(
      sightGeo,
      new THREE.LineBasicMaterial({ color: '#fef08a', linewidth: 2 })
    );
    this.weakPointSightline.visible = false;
    this.scene.add(this.weakPointSightline);

    const spriteGeo = new THREE.PlaneGeometry(2.55, 3.18);
    spriteGeo.translate(0, 1.54, 0);
    this.playerSprite = new THREE.Mesh(
      spriteGeo,
      new THREE.MeshBasicMaterial({
        map: this.sprites.updateAndGetPlayerTexture(world.player, 0),
        transparent: true,
        alphaTest: 0.05,
        side: THREE.DoubleSide,
      })
    );
    this.playerSprite.rotation.x = -this.cameraPitchRad;
    this.playerGroup.add(this.playerSprite);

    this.scene.add(this.swingGroup);
    this.scene.add(this.projectileGroup);
    this.scene.add(this.shockwaveGroup);
    this.scene.add(this.lightningGroup);

    this.rebuildBiomeEnvironment(world);
    window.addEventListener('resize', () => this.onResize());
  }

  /**
   * 레퍼런스 일러스트(Panel 2, 3, 4, 6, 7)의 디테일을 3D 공간에 입체적으로 구축
   */
  private rebuildBiomeEnvironment(world: WorldSimulation): void {
    this.renderedSceneId = world.currentScene;

    while (this.environmentGroup.children.length > 0) {
      const child = this.environmentGroup.children.pop()!;
      this.environmentGroup.remove(child);
    }

    for (const [, node] of this.enemyNodes.entries()) {
      this.scene.remove(node.group);
    }
    this.enemyNodes.clear();

    const sceneId = world.currentScene;

    if (sceneId === 'scene2_hub' || sceneId === 'scene1_title' || sceneId === 'scene8_return') {
      // =========================================================================
      // Scene 2: 전함 허브 — “폭풍 사이의 안식” (Panel 2 완벽 재현)
      // =========================================================================
      this.scene.background = new THREE.Color('#061322');
      this.scene.fog = new THREE.FogExp2('#061322', 0.014);

      this.environmentGroup.add(new THREE.AmbientLight('#38bdf8', 0.65));

      const brazierLight = new THREE.PointLight('#fb923c', 4.5, 22);
      brazierLight.position.set(-4.2, 3.0, 2.2);
      this.environmentGroup.add(brazierLight);

      const chartLight = new THREE.PointLight('#fde047', 2.8, 16);
      chartLight.position.set(0, 3.5, 0.4);
      this.environmentGroup.add(chartLight);

      // 주변 황혼 바다와 파도 물결
      const seaGeo = new THREE.PlaneGeometry(110, 110);
      seaGeo.rotateX(-Math.PI / 2);
      const seaMesh = new THREE.Mesh(
        seaGeo,
        new THREE.MeshStandardMaterial({
          color: '#071f32',
          roughness: 0.25,
          metalness: 0.65,
        })
      );
      seaMesh.position.y = -0.45;
      this.environmentGroup.add(seaMesh);

      // 고대 전함 목재 갑판 본체 + 양현 목재 난간(Bulwarks) + 돛대(Mast) 및 밧줄(Rigging)
      const deckTex = this.createDeckPlankTexture();
      const deckMesh = new THREE.Mesh(
        new THREE.BoxGeometry(24, 0.8, 16),
        new THREE.MeshStandardMaterial({ map: deckTex, roughness: 0.78 })
      );
      deckMesh.position.y = -0.4;
      this.environmentGroup.add(deckMesh);

      // 전함 난간 기둥 및 목재 상자·물통·창 묶음 배치
      const woodMat = new THREE.MeshStandardMaterial({ color: '#451a03', roughness: 0.75 });
      const bronzeMat = new THREE.MeshStandardMaterial({
        color: '#d97706',
        metalness: 0.7,
        roughness: 0.3,
      });

      // 북·남·동·서 난간
      for (const zPos of [-7.8, 7.8]) {
        const rail = new THREE.Mesh(new THREE.BoxGeometry(24, 0.9, 0.45), woodMat);
        rail.position.set(0, 0.45, zPos);
        this.environmentGroup.add(rail);
      }
      for (let x = -11; x <= 11; x += 2.75) {
        for (const zPos of [-7.8, 7.8]) {
          const post = new THREE.Mesh(new THREE.BoxGeometry(0.35, 1.35, 0.55), woodMat);
          post.position.set(x, 0.65, zPos);
          this.environmentGroup.add(post);
        }
      }

      // 전함 거대 돛대(Mast)와 반쯤 접힌 돛·밧줄
      const mast = new THREE.Mesh(new THREE.CylinderGeometry(0.45, 0.58, 14, 16), woodMat);
      mast.position.set(-9.5, 7, 0);
      this.environmentGroup.add(mast);

      // 갑판 가장자리 물통(Barrels), 보급 상자(Crates), 암포라 항아리
      for (const [bx, bz] of [
        [-8.5, 4.8],
        [-7.2, 5.2],
        [6.8, 5.0],
        [8.2, 4.5],
        [8.8, 1.5],
      ]) {
        const barrel = new THREE.Mesh(
          new THREE.CylinderGeometry(0.45, 0.42, 1.1, 14),
          woodMat
        );
        barrel.position.set(bx, 0.55, bz);
        this.environmentGroup.add(barrel);
      }

      // 중앙 해도 탁자(Sea Chart Table) + 양피지 지도 + 두루마리 + 섬 모형 + 청동 주화
      const tableGroup = new THREE.Group();
      tableGroup.position.set(0, 0, 0.4);
      const tableBody = new THREE.Mesh(new THREE.BoxGeometry(3.8, 1.0, 2.5), woodMat);
      tableBody.position.y = 0.5;
      tableGroup.add(tableBody);

      const mapTex = this.createSeaChartMapTexture();
      const mapPlane = new THREE.Mesh(
        new THREE.PlaneGeometry(3.2, 1.95),
        new THREE.MeshBasicMaterial({ map: mapTex })
      );
      mapPlane.rotation.x = -Math.PI / 2;
      mapPlane.position.y = 1.02;
      tableGroup.add(mapPlane);

      // 탁자 위 작은 섬 모형 2개와 황금 주화 더미
      const miniIsland1 = new THREE.Mesh(
        new THREE.ConeGeometry(0.28, 0.45, 7),
        new THREE.MeshStandardMaterial({ color: '#78716c' })
      );
      miniIsland1.position.set(-0.6, 1.22, -0.2);
      tableGroup.add(miniIsland1);

      const miniIsland2 = new THREE.Mesh(
        new THREE.ConeGeometry(0.24, 0.4, 7),
        new THREE.MeshStandardMaterial({ color: '#475569' })
      );
      miniIsland2.position.set(0.65, 1.2, 0.25);
      tableGroup.add(miniIsland2);
      this.environmentGroup.add(tableGroup);

      // 화로(Brazier)와 붉은 불꽃 코어 + 옆의 창 거치대
      const brazierStand = new THREE.Mesh(
        new THREE.CylinderGeometry(0.75, 0.52, 0.95, 16),
        bronzeMat
      );
      brazierStand.position.set(-4.2, 0.48, 2.2);
      this.environmentGroup.add(brazierStand);

      const flameCore = new THREE.Mesh(
        new THREE.ConeGeometry(0.55, 1.15, 12),
        new THREE.MeshBasicMaterial({ color: '#fb923c' })
      );
      flameCore.position.set(-4.2, 1.35, 2.2);
      this.environmentGroup.add(flameCore);

      // 배 가장자리 네 신의 대리석·황금 제단과 신상 조각 (Panel 2 재현)
      const marbleMat = new THREE.MeshStandardMaterial({ color: '#e2e8f0', roughness: 0.45 });
      for (const item of world.hubInteractables) {
        if (item.kind !== 'shrine') continue;
        const shrineGroup = new THREE.Group();
        shrineGroup.position.set(item.x, 0, item.z);

        // 대리석 제단 받침대
        const base = new THREE.Mesh(new THREE.BoxGeometry(1.7, 1.5, 1.3), marbleMat);
        base.position.y = 0.75;
        shrineGroup.add(base);

        // 전면 황금 문양 판
        const plaque = new THREE.Mesh(
          new THREE.PlaneGeometry(0.95, 0.95),
          new THREE.MeshBasicMaterial({ color: item.color })
        );
        plaque.position.set(0, 0.78, 0.67);
        shrineGroup.add(plaque);

        // 제단 위 조각상 실루엣 기둥
        const statue = new THREE.Mesh(
          new THREE.CylinderGeometry(0.32, 0.42, 1.85, 12),
          marbleMat
        );
        statue.position.y = 2.4;
        shrineGroup.add(statue);

        const halo = new THREE.Mesh(
          new THREE.RingGeometry(0.45, 0.62, 24),
          new THREE.MeshBasicMaterial({ color: item.color, side: THREE.DoubleSide })
        );
        halo.position.set(0, 3.1, 0);
        shrineGroup.add(halo);

        const sLight = new THREE.PointLight(item.color, 2.5, 9);
        sLight.position.set(0, 2.6, 0.8);
        shrineGroup.add(sLight);

        this.environmentGroup.add(shrineGroup);
      }

      this.createAmbientParticles('#fb923c', 120);
    } else if (
      sceneId === 'scene3_cyclops_cave' ||
      sceneId === 'scene4_polyphemus_boss' ||
      sceneId === 'training_grounds'
    ) {
      // =========================================================================
      // Scene 3 & 4: 키클롭스의 동굴 & 폴리페모스 투기장 (Panel 3 & 4 완벽 재현)
      // - 부러진 도리스식 주름 기둥, 석회암 바위 절벽, 청록색 발광 이끼 군락, 천장 빛줄기
      // =========================================================================
      this.scene.background = new THREE.Color('#091318');
      this.scene.fog = new THREE.FogExp2('#091318', 0.013);

      this.environmentGroup.add(new THREE.AmbientLight('#5eead4', 0.62));

      const caveSun = new THREE.DirectionalLight('#fef3c7', 1.65);
      caveSun.position.set(12, 28, 14);
      this.environmentGroup.add(caveSun);

      const w = COMBAT_CONFIG.arena.halfWidth * 2;
      const d = COMBAT_CONFIG.arena.halfDepth * 2;
      const floorTex = this.createCaveMossTexture();
      const floorMesh = new THREE.Mesh(
        new THREE.PlaneGeometry(w, d).rotateX(-Math.PI / 2),
        new THREE.MeshStandardMaterial({ map: floorTex, roughness: 0.88 })
      );
      this.environmentGroup.add(floorMesh);

      // 동굴 외곽 바위 암벽과 청록색 발광 이끼 결정(Bioluminescent Cyan Moss Clusters)
      const rockMat = new THREE.MeshStandardMaterial({ color: '#3f3f46', roughness: 0.9 });
      const mossGlowMat = new THREE.MeshBasicMaterial({ color: '#2dd4bf' });

      for (let i = 0; i < 24; i++) {
        const angle = (i / 24) * Math.PI * 2;
        const rx = Math.cos(angle) * (COMBAT_CONFIG.arena.halfWidth - 0.5);
        const rz = Math.sin(angle) * (COMBAT_CONFIG.arena.halfDepth - 0.5);
        const rock = new THREE.Mesh(
          new THREE.DodecahedronGeometry(1.4 + (i % 3) * 0.6, 1),
          rockMat
        );
        rock.position.set(rx, 0.9, rz);
        this.environmentGroup.add(rock);

        if (i % 2 === 0) {
          const mossPatch = new THREE.Mesh(
            new THREE.SphereGeometry(0.42, 8, 8),
            mossGlowMat
          );
          mossPatch.scale.set(1.5, 0.35, 1.5);
          mossPatch.position.set(rx * 0.88, 0.12, rz * 0.88);
          this.environmentGroup.add(mossPatch);
        }
      }

      // 천장 틈새 빛줄기
      for (const [lx, lz] of [
        [-6.5, -4.5],
        [5.5, 2.5],
      ]) {
        const cone = new THREE.Mesh(
          new THREE.ConeGeometry(3.8, 18, 24, 1, true),
          new THREE.MeshBasicMaterial({
            color: '#fef08a',
            transparent: true,
            opacity: 0.08,
            side: THREE.DoubleSide,
            depthWrite: false,
          })
        );
        cone.position.set(lx, 9, lz);
        this.environmentGroup.add(cone);
      }

      this.createAmbientParticles('#2dd4bf', 160);
    } else if (sceneId === 'scene6_siren_reef' || sceneId === 'scene7_parthenope_boss') {
      // =========================================================================
      // Scene 6 & 7: 세이렌의 암초 & 수몰된 원형 대리석 신전 (Panel 6 & 7 완벽 재현)
      // - 달빛 수면, 수몰된 원형 열주(Colonnade), 난파선 실루엣, 물보라와 횃불 화로
      // =========================================================================
      this.scene.background = new THREE.Color('#040d1a');
      this.scene.fog = new THREE.FogExp2('#040d1a', 0.012);

      this.environmentGroup.add(new THREE.AmbientLight('#7dd3fc', 0.78));

      const moonLight = new THREE.DirectionalLight('#e0f2fe', 1.6);
      moonLight.position.set(-10, 28, 12);
      this.environmentGroup.add(moonLight);

      // 깊은 남색 달빛 바다 수면
      const seaMesh = new THREE.Mesh(
        new THREE.PlaneGeometry(90, 90).rotateX(-Math.PI / 2),
        new THREE.MeshStandardMaterial({
          color: '#071c34',
          roughness: 0.2,
          metalness: 0.7,
        })
      );
      seaMesh.position.y = -0.08;
      this.environmentGroup.add(seaMesh);

      const marbleMat = new THREE.MeshStandardMaterial({
        color: '#94a3b8',
        roughness: 0.5,
      });

      if (sceneId === 'scene7_parthenope_boss') {
        // Scene 7: 물에 잠긴 원형 대리석 신전 투기장 & 외곽 열주 기둥 링 (Panel 7 완벽 재현)
        const templeFloor = new THREE.Mesh(
          new THREE.CylinderGeometry(13.8, 14.2, 0.25, 48),
          new THREE.MeshStandardMaterial({
            map: this.createSirenMarbleWaterTexture(),
            roughness: 0.3,
          })
        );
        templeFloor.position.y = -0.05;
        this.environmentGroup.add(templeFloor);

        // 원형 신전을 둘러싼 부서진 대리석 열주(Colonnade) 14기
        for (let i = 0; i < 14; i++) {
          const ang = (i / 14) * Math.PI * 2;
          if (Math.sin(ang) > 0.65) continue; // 전면 카메라 시야 확보
          const cx = Math.cos(ang) * 13.5;
          const cz = Math.sin(ang) * 13.5;
          const h = 2.6 + (i % 3) * 1.1;
          const col = new THREE.Mesh(
            new THREE.CylinderGeometry(0.55, 0.65, h, 14),
            marbleMat
          );
          col.position.set(cx, h * 0.5, cz);
          this.environmentGroup.add(col);
        }
      } else {
        // Scene 6: 육지(대리석 다리 통로)와 깊은 물의 경계가 뚜렷한 암초 유적 + 배경 난파선
        const w = COMBAT_CONFIG.arena.halfWidth * 2;
        const d = COMBAT_CONFIG.arena.halfDepth * 2;
        const bridgeFloor = new THREE.Mesh(
          new THREE.PlaneGeometry(w, d).rotateX(-Math.PI / 2),
          new THREE.MeshStandardMaterial({
            map: this.createSirenMarbleWaterTexture(),
            roughness: 0.4,
          })
        );
        this.environmentGroup.add(bridgeFloor);

        // 우측 후경 난파선 돛대와 선체 실루엣 (Shipwreck in background)
        const wreckWood = new THREE.MeshStandardMaterial({ color: '#1e1b18' });
        const wreckMast = new THREE.Mesh(
          new THREE.CylinderGeometry(0.25, 0.35, 11, 10),
          wreckWood
        );
        wreckMast.position.set(14, 4.5, -11);
        wreckMast.rotation.z = 0.28;
        this.environmentGroup.add(wreckMast);
      }

      this.createAmbientParticles('#7dd3fc', 150);
    }

    // 전술 엄폐물: 고대 그리스 주름진 도리스식 석주(Fluted Doric Columns with Capitals)
    const colMat = new THREE.MeshStandardMaterial({
      color: '#cbd5e1',
      roughness: 0.65,
    });
    for (const p of world.pillars) {
      const colGroup = new THREE.Group();
      colGroup.position.set(p.x, 0, p.z);

      const base = new THREE.Mesh(new THREE.BoxGeometry(2.0, 0.45, 2.0), colMat);
      base.position.y = 0.22;
      colGroup.add(base);

      const shaft = new THREE.Mesh(
        new THREE.CylinderGeometry(p.radius * 0.88, p.radius, 3.1, 16),
        colMat
      );
      shaft.position.y = 1.75;
      colGroup.add(shaft);

      // 부러진 기둥 상단 단면 표현
      const topCap = new THREE.Mesh(new THREE.BoxGeometry(1.9, 0.35, 1.9), colMat);
      topCap.position.y = 3.35;
      topCap.rotation.z = 0.08;
      colGroup.add(topCap);

      this.environmentGroup.add(colGroup);
    }
  }

  private createAmbientParticles(colorHex: string, count: number): void {
    const geo = new THREE.BufferGeometry();
    const positions = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      positions[i * 3] = (Math.random() - 0.5) * 42;
      positions[i * 3 + 1] = 0.4 + Math.random() * 6.5;
      positions[i * 3 + 2] = (Math.random() - 0.5) * 30;
    }
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const mat = new THREE.PointsMaterial({
      color: colorHex,
      size: 0.18,
      transparent: true,
      opacity: 0.75,
    });
    this.ambientParticles = new THREE.Points(geo, mat);
    this.environmentGroup.add(this.ambientParticles);
  }

  private createSeaChartMapTexture(): THREE.CanvasTexture {
    const c = document.createElement('canvas');
    c.width = 512;
    c.height = 320;
    const ctx = c.getContext('2d')!;
    ctx.fillStyle = '#fde68a';
    ctx.fillRect(0, 0, 512, 320);
    ctx.strokeStyle = '#92400e';
    ctx.lineWidth = 8;
    ctx.strokeRect(12, 12, 488, 296);

    // 고대 지중해 해안선 및 항로 점선 묘사
    ctx.fillStyle = '#d97706';
    ctx.beginPath();
    ctx.arc(140, 150, 48, 0, Math.PI * 2);
    ctx.arc(360, 140, 56, 0, Math.PI * 2);
    ctx.fill();

    ctx.strokeStyle = '#7f1d1d';
    ctx.setLineDash([10, 8]);
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(80, 240);
    ctx.quadraticCurveTo(240, 80, 420, 140);
    ctx.stroke();

    return new THREE.CanvasTexture(c);
  }

  private createDeckPlankTexture(): THREE.CanvasTexture {
    const c = document.createElement('canvas');
    c.width = 512;
    c.height = 512;
    const ctx = c.getContext('2d')!;
    ctx.fillStyle = '#3b2110';
    ctx.fillRect(0, 0, 512, 512);
    ctx.strokeStyle = '#1a0d06';
    ctx.lineWidth = 5;
    for (let y = 0; y < 512; y += 48) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(512, y);
      ctx.stroke();
    }
    const tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(5, 4);
    return tex;
  }

  private createCaveMossTexture(): THREE.CanvasTexture {
    const c = document.createElement('canvas');
    c.width = 512;
    c.height = 512;
    const ctx = c.getContext('2d')!;
    ctx.fillStyle = '#262322';
    ctx.fillRect(0, 0, 512, 512);
    ctx.strokeStyle = '#171514';
    ctx.lineWidth = 6;
    ctx.strokeRect(10, 10, 236, 236);
    ctx.strokeRect(266, 266, 236, 236);

    // 청록색 발광 이끼 패치
    for (const [mx, my, mr] of [
      [110, 390, 95],
      [390, 120, 80],
    ]) {
      const moss = ctx.createRadialGradient(mx, my, 8, mx, my, mr);
      moss.addColorStop(0, 'rgba(45, 212, 191, 0.68)');
      moss.addColorStop(0.5, 'rgba(13, 148, 136, 0.28)');
      moss.addColorStop(1, 'rgba(19, 78, 74, 0)');
      ctx.fillStyle = moss;
      ctx.beginPath();
      ctx.arc(mx, my, mr, 0, Math.PI * 2);
      ctx.fill();
    }

    const tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(6, 5);
    return tex;
  }

  private createSirenMarbleWaterTexture(): THREE.CanvasTexture {
    const c = document.createElement('canvas');
    c.width = 512;
    c.height = 512;
    const ctx = c.getContext('2d')!;
    ctx.fillStyle = '#091e36';
    ctx.fillRect(0, 0, 512, 512);

    // 물에 잠긴 고대 대리석 블록과 청록 해초 테두리
    ctx.fillStyle = '#1e3a5f';
    ctx.fillRect(28, 28, 456, 456);
    ctx.strokeStyle = '#38bdf8';
    ctx.lineWidth = 4;
    ctx.strokeRect(28, 28, 456, 456);

    const tex = new THREE.CanvasTexture(c);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(6, 5);
    return tex;
  }

  public updateMouseGroundPosition(ndc: { x: number; y: number }): Vec2 {
    this.raycaster.setFromCamera(new THREE.Vector2(ndc.x, ndc.y), this.camera);
    const intersect = new THREE.Vector3();
    const hit = this.raycaster.ray.intersectPlane(this.groundPlane, intersect);
    if (hit) return { x: intersect.x, z: intersect.z };
    return { x: 0, z: 0 };
  }

  public render(world: WorldSimulation, dt: number): void {
    if (this.renderedSceneId !== world.currentScene) {
      this.rebuildBiomeEnvironment(world);
    }

    if (this.ambientParticles) {
      this.ambientParticles.rotation.y += dt * 0.04;
    }

    const p = world.player;
    this.playerGroup.position.set(p.x, 0, p.z);
    this.playerFacingRing.rotation.y = -p.facingAngle;

    // 8방향 스프라이트 시트 기반 다관절 보행 및 창/활/방패 모션 동적 텍스처 갱신
    this.playerSprite.material.map = this.sprites.updateAndGetPlayerTexture(p, dt);
    this.playerSprite.material.needsUpdate = true;

    // 8방향 시트(N, NE, E, SE, S, SW, W, NW)가 방향별 좌우를 자체 처리하므로 중복 반전 방지
    this.playerSprite.scale.x = 1;

    // 보행 시 3D 빌보드 탄성 스텝(Stride Tilt & Footstep Dust) 추가
    if (p.state === 'move') {
      const walkPhase = this.sprites.getWalkPhase();
      this.playerSprite.rotation.z = Math.sin(walkPhase) * 0.045;
      if (Math.abs(Math.cos(walkPhase)) > 0.96 && Math.random() < 0.35) {
        world.shockwaves.push({
          id: Math.random(),
          x: p.x + (Math.random() - 0.5) * 0.35,
          z: p.z + 0.12,
          maxRadius: 0.55,
          color: '#a8a29e',
          timer: 0,
          duration: 0.22,
        });
      }
    } else {
      this.playerSprite.rotation.z = 0;
    }

    // 강궁 청백색 차징 화살 조준선 & 보스 금빛 외눈 약점 시선의 선(Sightline)
    const exposedBoss = world.enemies.find((e) => e.hp > 0 && e.weakPointExposed);
    if (p.state === 'bow_charge') {
      this.bowAimLine.visible = true;
      this.bowAimLine.rotation.y = -p.facingAngle;
      const aimLen = p.isFullCharged ? 18 : 6 + p.bowCharge * 10;
      this.bowAimLine.scale.set(aimLen, 1, p.isFullCharged ? 2.4 : 1.15);
      this.bowAimLine.material.color.set(p.isFullCharged ? '#e0f2fe' : '#7dd3fc');

      if (exposedBoss) {
        this.weakPointSightline.visible = true;
        const posAttr = this.weakPointSightline.geometry.attributes
          .position as THREE.BufferAttribute;
        posAttr.setXYZ(0, p.x, 1.3, p.z);
        posAttr.setXYZ(1, exposedBoss.x, 2.8, exposedBoss.z);
        posAttr.needsUpdate = true;
      } else {
        this.weakPointSightline.visible = false;
      }
    } else {
      this.bowAimLine.visible = false;
      this.weakPointSightline.visible = false;
    }

    this.syncEnemies(world);
    this.syncSwings(world);
    this.syncProjectiles(world);
    this.syncShockwaves(world);
    this.syncLightning(world);
    this.updateCamera(world, dt);

    this.composer.render();
  }

  private syncEnemies(world: WorldSimulation): void {
    const activeIds = new Set<number>();

    for (const enemy of world.enemies) {
      activeIds.add(enemy.id);
      let node = this.enemyNodes.get(enemy.id);
      if (!node) {
        node = this.createEnemyVisualNode(enemy);
        this.enemyNodes.set(enemy.id, node);
        this.scene.add(node.group);
      }

      node.group.visible = enemy.hp > 0;
      if (enemy.hp <= 0) continue;

      node.group.position.set(enemy.x, 0, enemy.z);

      let texState: 'normal' | 'windup' | 'weak_open' | 'staggered' | 'hit' = 'normal';
      if (enemy.hitFlashTimer > 0) texState = 'hit';
      else if (enemy.weakPointExposed) texState = 'weak_open';
      else if (enemy.state === 'windup' || enemy.state === 'attack') texState = 'windup';
      else if (enemy.state === 'staggered') texState = 'staggered';

      node.spriteMesh.material.map = this.sprites.getEnemyTexture(enemy.kind, texState);

      if (enemy.state === 'windup') {
        const pulse = 1 + Math.sin(performance.now() * 0.025) * 0.07;
        node.spriteMesh.scale.set(pulse, pulse, 1);
      } else {
        node.spriteMesh.scale.set(1, 1, 1);
      }

      node.facingArrow.position.set(
        Math.cos(enemy.facingAngle) * (enemy.radius + 0.35),
        0.05,
        Math.sin(enemy.facingAngle) * (enemy.radius + 0.35)
      );
      node.facingArrow.rotation.y = -enemy.facingAngle - Math.PI / 2;

      node.shieldRing.visible = enemy.shielded && !enemy.weakPointExposed;
      node.weakPointRing.visible = enemy.weakPointExposed;

      this.updateTelegraphVisual(node.telegraphGroup, enemy);
    }

    for (const [id, node] of this.enemyNodes.entries()) {
      if (!activeIds.has(id)) {
        this.scene.remove(node.group);
        this.enemyNodes.delete(id);
      }
    }
  }

  private createEnemyVisualNode(enemy: EnemyEntity): EnemyVisualNode {
    const group = new THREE.Group();

    const shadowGeo = new THREE.CircleGeometry(enemy.radius * 1.1, 28);
    shadowGeo.rotateX(-Math.PI / 2);
    const shadowMesh = new THREE.Mesh(
      shadowGeo,
      new THREE.MeshBasicMaterial({ color: '#030c12', transparent: true, opacity: 0.65 })
    );
    shadowMesh.position.y = 0.02;
    group.add(shadowMesh);

    const arrowGeo = new THREE.ConeGeometry(0.24, 0.48, 4);
    arrowGeo.rotateX(Math.PI / 2);
    const facingArrow = new THREE.Mesh(
      arrowGeo,
      new THREE.MeshBasicMaterial({ color: '#fb923c' })
    );
    group.add(facingArrow);

    const shieldGeo = new THREE.RingGeometry(enemy.radius + 0.15, enemy.radius + 0.32, 36);
    shieldGeo.rotateX(-Math.PI / 2);
    const shieldRing = new THREE.Mesh(
      shieldGeo,
      new THREE.MeshBasicMaterial({ color: '#60a5fa', side: THREE.DoubleSide })
    );
    shieldRing.position.y = 0.04;
    group.add(shieldRing);

    const weakGeo = new THREE.RingGeometry(enemy.radius + 0.18, enemy.radius + 0.48, 36);
    weakGeo.rotateX(-Math.PI / 2);
    const weakPointRing = new THREE.Mesh(
      weakGeo,
      new THREE.MeshBasicMaterial({ color: '#fef08a', side: THREE.DoubleSide })
    );
    weakPointRing.position.y = 0.06;
    group.add(weakPointRing);

    const scale = enemy.visualScale * 1.25;
    const spriteGeo = new THREE.PlaneGeometry(scale * 0.85, scale);
    spriteGeo.translate(0, scale * 0.48, 0);
    const spriteMesh = new THREE.Mesh(
      spriteGeo,
      new THREE.MeshBasicMaterial({
        map: this.sprites.getEnemyTexture(enemy.kind, 'normal'),
        transparent: true,
        alphaTest: 0.06,
        side: THREE.DoubleSide,
      })
    );
    spriteMesh.rotation.x = -this.cameraPitchRad;
    group.add(spriteMesh);

    const telegraphGroup = new THREE.Group();
    group.add(telegraphGroup);

    return {
      group,
      spriteMesh,
      shadowMesh,
      facingArrow,
      shieldRing,
      weakPointRing,
      telegraphGroup,
    };
  }

  private updateTelegraphVisual(container: THREE.Group, enemy: EnemyEntity): void {
    while (container.children.length > 0) {
      const child = container.children.pop() as THREE.Mesh;
      child.geometry.dispose();
    }

    const tele = enemy.telegraph;
    if (!tele) return;

    const p = Math.max(0.05, Math.min(1, tele.progress));
    const relX = tele.x - enemy.x;
    const relZ = tele.z - enemy.z;

    if (tele.type === 'circle') {
      const outerGeo = new THREE.RingGeometry(tele.radius - 0.15, tele.radius, 56);
      outerGeo.rotateX(-Math.PI / 2);
      const outerMesh = new THREE.Mesh(
        outerGeo,
        new THREE.MeshBasicMaterial({ color: tele.color, side: THREE.DoubleSide })
      );
      outerMesh.position.set(relX, 0.04, relZ);
      container.add(outerMesh);

      if (tele.style === 'siren_pull') {
        // Scene 7 레퍼런스 완벽 재현: 여왕 주변의 다중 청자색 동심원 음파 링
        for (let r = 1; r <= 4; r++) {
          const waveR = (1 - ((performance.now() * 0.0007 + r * 0.25) % 1)) * tele.radius;
          const ringG = new THREE.RingGeometry(Math.max(0.1, waveR - 0.18), waveR, 48);
          ringG.rotateX(-Math.PI / 2);
          const ringM = new THREE.Mesh(
            ringG,
            new THREE.MeshBasicMaterial({
              color: r % 2 === 0 ? '#a855f7' : '#60a5fa',
              transparent: true,
              opacity: 0.72,
              side: THREE.DoubleSide,
            })
          );
          ringM.position.set(relX, 0.05, relZ);
          container.add(ringM);
        }
      } else {
        const fillGeo = new THREE.CircleGeometry(tele.radius * p, 48);
        fillGeo.rotateX(-Math.PI / 2);
        const fillMesh = new THREE.Mesh(
          fillGeo,
          new THREE.MeshBasicMaterial({
            color: tele.color,
            transparent: true,
            opacity: 0.42,
            side: THREE.DoubleSide,
          })
        );
        fillMesh.position.set(relX, 0.03, relZ);
        container.add(fillMesh);
      }
    } else if (tele.type === 'sector') {
      const outerGeo = new THREE.CircleGeometry(
        tele.radius,
        36,
        -tele.arc * 0.5,
        tele.arc
      );
      outerGeo.rotateX(-Math.PI / 2);
      const outerMesh = new THREE.Mesh(
        outerGeo,
        new THREE.MeshBasicMaterial({
          color: tele.color,
          transparent: true,
          opacity: 0.28 + 0.42 * p,
          side: THREE.DoubleSide,
        })
      );
      outerMesh.rotation.y = -tele.angle;
      outerMesh.position.set(relX, 0.04, relZ);
      container.add(outerMesh);
    } else if (tele.type === 'line') {
      const lineGeo = new THREE.PlaneGeometry(tele.length, tele.width);
      lineGeo.rotateX(-Math.PI / 2);
      lineGeo.translate(tele.length * 0.5, 0, 0);
      const lineMesh = new THREE.Mesh(
        lineGeo,
        new THREE.MeshBasicMaterial({
          color: tele.color,
          transparent: true,
          opacity: 0.3 + 0.5 * p,
          side: THREE.DoubleSide,
        })
      );
      lineMesh.rotation.y = -tele.angle;
      lineMesh.position.set(relX, 0.04, relZ);
      container.add(lineMesh);
    }
  }

  private syncSwings(world: WorldSimulation): void {
    while (this.swingGroup.children.length > 0) {
      const c = this.swingGroup.children.pop() as THREE.Mesh;
      c.geometry.dispose();
    }

    for (const sw of world.swings) {
      const alpha = Math.max(0, 1 - sw.timer / sw.maxTimer);

      if (sw.comboStep === 2) {
        const geo = new THREE.PlaneGeometry(sw.length, sw.width);
        geo.rotateX(-Math.PI / 2);
        geo.translate(sw.length * 0.5, 0, 0);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({
            color: '#fef08a',
            transparent: true,
            opacity: 0.78 * alpha,
            side: THREE.DoubleSide,
          })
        );
        mesh.position.set(sw.x, 0.16, sw.z);
        mesh.rotation.y = -sw.angle;
        this.swingGroup.add(mesh);
      } else {
        const color =
          sw.comboStep === 'parry'
            ? '#fef08a'
            : sw.comboStep === 3
              ? '#fb923c'
              : '#fde047';

        const geo = new THREE.RingGeometry(
          sw.radius * 0.35,
          sw.radius,
          36,
          1,
          -sw.arc * 0.5,
          sw.arc
        );
        geo.rotateX(-Math.PI / 2);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({
            color,
            transparent: true,
            opacity: 0.8 * alpha,
            side: THREE.DoubleSide,
          })
        );
        mesh.position.set(sw.x, 0.16, sw.z);
        mesh.rotation.y = -sw.angle;
        this.swingGroup.add(mesh);
      }
    }
  }

  private syncProjectiles(world: WorldSimulation): void {
    while (this.projectileGroup.children.length > 0) {
      const c = this.projectileGroup.children.pop() as THREE.Mesh;
      c.geometry.dispose();
    }

    for (const proj of world.projectiles) {
      if (proj.kind === 'arrow_normal' || proj.kind === 'arrow_pierce') {
        const isPierce = proj.kind === 'arrow_pierce';
        const geo = new THREE.PlaneGeometry(isPierce ? 2.2 : 1.25, isPierce ? 0.38 : 0.18);
        geo.rotateX(-Math.PI / 2);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({
            color: isPierce ? '#ffffff' : '#fde68a',
            side: THREE.DoubleSide,
          })
        );
        mesh.position.set(proj.x, 0.65, proj.z);
        mesh.rotation.y = -proj.angle;
        this.projectileGroup.add(mesh);
      } else if (proj.kind === 'siren_sonic_orb') {
        // Scene 6 레퍼런스 완벽 재현: 혜성 같은 꼬리가 달린 밝은 푸른 음파 구체
        const geo = new THREE.SphereGeometry(proj.radius, 16, 16);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({ color: '#bae6fd' })
        );
        mesh.position.set(proj.x, 0.75, proj.z);
        this.projectileGroup.add(mesh);
      } else {
        const isParried = proj.kind === 'parried_orb';
        const geo = new THREE.SphereGeometry(proj.radius, 14, 14);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({
            color: isParried ? '#fef08a' : '#fb923c',
          })
        );
        mesh.position.set(proj.x, 0.65, proj.z);
        this.projectileGroup.add(mesh);
      }
    }
  }

  private syncShockwaves(world: WorldSimulation): void {
    while (this.shockwaveGroup.children.length > 0) {
      const c = this.shockwaveGroup.children.pop() as THREE.Mesh;
      c.geometry.dispose();
    }

    for (const sw of world.shockwaves) {
      const progress = sw.timer / sw.duration;
      const radius = Math.max(0.25, sw.maxRadius * progress);

      if (sw.style === 'dust_fan' && sw.angle !== undefined) {
        const arc = (115 * Math.PI) / 180;
        const geo = new THREE.RingGeometry(radius * 0.35, radius, 36, 1, -arc * 0.5, arc);
        geo.rotateX(-Math.PI / 2);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({
            color: sw.color,
            transparent: true,
            opacity: (1 - progress) * 0.88,
            side: THREE.DoubleSide,
          })
        );
        mesh.position.set(sw.x, 0.1, sw.z);
        mesh.rotation.y = -sw.angle;
        this.shockwaveGroup.add(mesh);
      } else if (sw.style === 'bell_gold') {
        // Scene 7 레퍼런스 완벽 재현: 청동 종 타격 시 수평·수직으로 동시에 뻗어나가는 황금 공명 아크!
        const hGeo = new THREE.RingGeometry(radius * 0.85, radius, 56);
        hGeo.rotateX(-Math.PI / 2);
        const hMesh = new THREE.Mesh(
          hGeo,
          new THREE.MeshBasicMaterial({
            color: '#fef08a',
            transparent: true,
            opacity: (1 - progress) * 0.95,
            side: THREE.DoubleSide,
          })
        );
        hMesh.position.set(sw.x, 0.15, sw.z);
        this.shockwaveGroup.add(hMesh);

        // 수직 황금 공명 링 (Panel 7의 종 앞쪽 입체 황금 고리 재현)
        const vGeo = new THREE.RingGeometry(radius * 0.45, radius * 0.55, 40);
        const vMesh = new THREE.Mesh(
          vGeo,
          new THREE.MeshBasicMaterial({
            color: '#fbbf24',
            transparent: true,
            opacity: (1 - progress) * 0.9,
            side: THREE.DoubleSide,
          })
        );
        vMesh.position.set(sw.x, 1.4, sw.z);
        vMesh.rotation.x = -this.cameraPitchRad;
        this.shockwaveGroup.add(vMesh);
      } else {
        const geo = new THREE.RingGeometry(radius * 0.82, radius, 48);
        geo.rotateX(-Math.PI / 2);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({
            color: sw.color,
            transparent: true,
            opacity: (1 - progress) * 0.9,
            side: THREE.DoubleSide,
          })
        );
        mesh.position.set(sw.x, 0.09, sw.z);
        this.shockwaveGroup.add(mesh);
      }
    }
  }

  private syncLightning(world: WorldSimulation): void {
    while (this.lightningGroup.children.length > 0) {
      const c = this.lightningGroup.children.pop() as THREE.Line;
      c.geometry.dispose();
    }

    for (const arc of world.lightningArcs) {
      const midX = (arc.x1 + arc.x2) * 0.5 + (Math.random() - 0.5) * 0.9;
      const midZ = (arc.z1 + arc.z2) * 0.5 + (Math.random() - 0.5) * 0.9;
      const pts = [
        new THREE.Vector3(arc.x1, 1.1, arc.z1),
        new THREE.Vector3(midX, 1.5, midZ),
        new THREE.Vector3(arc.x2, 1.1, arc.z2),
      ];
      const geo = new THREE.BufferGeometry().setFromPoints(pts);
      const line = new THREE.Line(
        geo,
        new THREE.LineBasicMaterial({ color: '#e0f2fe' })
      );
      this.lightningGroup.add(line);
    }
  }

  private updateCamera(world: WorldSimulation, dt: number): void {
    const p = world.player;
    const lookAheadX = Math.cos(p.facingAngle) * 1.4;
    const lookAheadZ = Math.sin(p.facingAngle) * 1.4;

    const desiredX = p.x + lookAheadX;
    const desiredZ = p.z + lookAheadZ;

    this.cameraTarget.x += (desiredX - this.cameraTarget.x) * Math.min(1, dt * 7.5);
    this.cameraTarget.z += (desiredZ - this.cameraTarget.z) * Math.min(1, dt * 7.5);

    const shakeX = (Math.random() - 0.5) * world.cameraShake * 0.9;
    const shakeZ = (Math.random() - 0.5) * world.cameraShake * 0.9;

    const camY = Math.sin(this.cameraPitchRad) * this.cameraDistance;
    const camZOffset = Math.cos(this.cameraPitchRad) * this.cameraDistance;

    this.camera.position.set(
      this.cameraTarget.x + shakeX,
      camY,
      this.cameraTarget.z + camZOffset + shakeZ
    );
    this.camera.lookAt(this.cameraTarget.x + shakeX, 0, this.cameraTarget.z + shakeZ);
  }

  public projectToScreen(worldPos: THREE.Vector3): { x: number; y: number; visible: boolean } {
    const v = worldPos.clone().project(this.camera);
    const x = (v.x * 0.5 + 0.5) * window.innerWidth;
    const y = (-(v.y * 0.5) + 0.5) * window.innerHeight;
    return { x, y, visible: v.z < 1 };
  }

  private onResize(): void {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.composer.setSize(window.innerWidth, window.innerHeight);
  }
}
