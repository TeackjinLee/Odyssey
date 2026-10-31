import { COMBAT_CONFIG, OLYMPIAN_BOONS } from '../data/combatConfig';
import { AudioSynth } from '../core/AudioSynth';
import { InputManager } from '../core/InputManager';
import {
  ActiveSwingVisual,
  BoonDefinition,
  EnemyEntity,
  FloatingTextEvent,
  GodId,
  HubInteractable,
  LightningArcVisual,
  MetaUpgrades,
  PlayerEntity,
  ProjectileEntity,
  SceneId,
  ShockwaveVisual,
} from '../types/combat';

export class WorldSimulation {
  public currentScene: SceneId = 'scene1_title';
  public nextSceneAfterBoon: SceneId = 'scene4_polyphemus_boss';

  // Scene 5: 신의 가호 — “올림포스의 선택” (시간 정지 3지선다 상태)
  public boonSelectionOpen = false;
  public boonChoices: BoonDefinition[] = [];

  // Scene 8 & Hub 메타 업그레이드 상태 (청동 주화로 최대 체력·공격력·부활[최대 1회] 강화)
  public meta: MetaUpgrades = {
    maxHpLevel: 0,
    attackLevel: 0,
    reviveUnlocked: true,
  };
  public returnOutcome: 'defeat' | 'victory' = 'defeat';

  public player: PlayerEntity;
  public enemies: EnemyEntity[] = [];
  public projectiles: ProjectileEntity[] = [];
  public swings: ActiveSwingVisual[] = [];
  public shockwaves: ShockwaveVisual[] = [];
  public lightningArcs: LightningArcVisual[] = [];
  public floatingTexts: FloatingTextEvent[] = [];
  public hubInteractables: HubInteractable[] = [];
  public nearbyHubItem: HubInteractable | null = null;
  public bannerMessage: { text: string; timer: number } | null = null;

  public cameraShake = 0;
  public hitStopTimer = 0;
  public elapsedTime = 0;

  private nextId = 1;
  private audio: AudioSynth;

  // 현재 씬의 기둥/장애물 목록
  public pillars: Array<{ x: number; z: number; radius: number }> = [];

  constructor(audio: AudioSynth) {
    this.audio = audio;
    this.player = this.createInitialPlayer();
    this.loadScene('scene2_hub');
    // 시작 시 Scene 1 메인 키아트 타이틀 오버레이도 바로 볼 수 있도록 설정하되,
    // 뒤쪽 3D 뷰포트에는 Scene 2 전함 허브가 실시간으로 돌아가게 구성
    this.currentScene = 'scene1_title';
  }

  private createInitialPlayer(): PlayerEntity {
    const maxHp = COMBAT_CONFIG.player.baseMaxHp;
    return {
      x: 0,
      z: 2.5,
      vx: 0,
      vz: 0,
      radius: COMBAT_CONFIG.player.radius,
      facingAngle: -Math.PI / 2,
      moveAngle: 0,
      hp: maxHp,
      maxHp,
      revivesLeft: 1,
      bronzeCoins: 60, // 초기 체험용 청동 주화
      voyageCoinsEarned: 0,
      killsAndBreaks: 0,

      state: 'idle',
      stateTimer: 0,

      dashCooldown: 0,
      dashDirX: 0,
      dashDirZ: -1,
      invulnerableTimer: 0,

      comboStep: 1,
      comboResetTimer: 0,
      hasDealtSwingDamage: false,

      bowCharge: 0,
      isFullCharged: false,

      parryCooldown: 0,
      boonCooldown: 0,
      hitFlashTimer: 0,

      activeBoons: new Set<GodId>(),
    };
  }

  public getAttackMultiplier(): number {
    return 1 + this.meta.attackLevel * 0.15;
  }

  public recalculatePlayerMetaStats(healFull = false): void {
    const newMax = COMBAT_CONFIG.player.baseMaxHp + this.meta.maxHpLevel * 25;
    const diff = newMax - this.player.maxHp;
    this.player.maxHp = newMax;
    if (healFull) {
      this.player.hp = newMax;
      this.player.revivesLeft = this.meta.reviveUnlocked ? 1 : 0;
    } else if (diff > 0) {
      this.player.hp += diff;
    }
  }

  /**
   * 8대 시나리오 씬 로드
   */
  public loadScene(scene: SceneId): void {
    this.currentScene = scene;
    this.boonSelectionOpen = false;
    this.enemies = [];
    this.projectiles = [];
    this.swings = [];
    this.shockwaves = [];
    this.lightningArcs = [];
    this.hubInteractables = [];
    this.nearbyHubItem = null;
    this.pillars = [];

    this.player.vx = 0;
    this.player.vz = 0;
    this.player.state = 'idle';
    this.player.bowCharge = 0;
    this.player.isFullCharged = false;

    if (scene === 'scene1_title') {
      this.showBanner('Scene 1. 메인 키아트 — “고향은 아직 수평선 너머에”');
      return;
    }

    if (scene === 'scene8_return') {
      this.showBanner('Scene 8. 귀환 — “아직 끝나지 않은 항해” (청동 주화로 영구 능력치를 강화하세요)');
      return;
    }

    if (scene === 'scene2_hub') {
      // Scene 2: 전함 허브 — “폭풍 사이의 안식”
      this.recalculatePlayerMetaStats(true);
      this.player.x = 0;
      this.player.z = 4.2;
      this.player.facingAngle = -Math.PI / 2;

      // 갑판 중앙 해도 탁자, 화로 정비소, 가장자리 네 신의 제단 배치
      this.hubInteractables = [
        {
          id: 'sea_chart',
          kind: 'sea_chart',
          title: '중앙 해도 탁자 (출항)',
          subtitle: '섬 모형과 청동 주화가 놓인 해도 — 다음 항해 목적지 선택',
          x: 0,
          z: 0.4,
          radius: 1.8,
          color: '#f59e0b',
        },
        {
          id: 'brazier',
          kind: 'brazier',
          title: '따뜻한 화로 & 창날 손질 (영구 정비)',
          subtitle: '청동 주화로 최대 체력·공격력·여신의 축복(부활) 강화',
          x: -4.2,
          z: 2.2,
          radius: 1.5,
          color: '#ea580c',
        },
        {
          id: 'shrine_athena',
          kind: 'shrine',
          god: 'athena',
          title: '아테나의 제단 (상아·금빛)',
          subtitle: '올빼미와 방패의 가호 받기',
          x: -7.5,
          z: -3.2,
          radius: 1.4,
          color: '#fbbf24',
        },
        {
          id: 'shrine_zeus',
          kind: 'shrine',
          god: 'zeus',
          title: '제우스의 제단 (청백색 뇌전)',
          subtitle: '독수리와 천둥 벼락의 가호 받기',
          x: -2.6,
          z: -4.6,
          radius: 1.4,
          color: '#60a5fa',
        },
        {
          id: 'shrine_apollo',
          kind: 'shrine',
          god: 'apollo',
          title: '아폴론의 제단 (태양빛 광륜)',
          subtitle: '월계관과 태양 활의 가호 받기',
          x: 2.6,
          z: -4.6,
          radius: 1.4,
          color: '#fb923c',
        },
        {
          id: 'shrine_hermes',
          kind: 'shrine',
          god: 'hermes',
          title: '헤르메스의 제단 (민트·은빛 바람)',
          subtitle: '날개 달린 샌들의 가호 받기',
          x: 7.5,
          z: -3.2,
          radius: 1.4,
          color: '#2dd4bf',
        },
      ];

      this.showBanner(
        'Scene 2. 전함 허브 — “폭풍 사이의 안식”: 화로·제단·중앙 해도 탁자로 이동하거나 상단 씬 버튼으로 이동하세요.'
      );
      return;
    }

    if (scene === 'scene3_cyclops_cave') {
      // Scene 3: 키클롭스의 동굴 — “눈을 뜨는 어둠”
      this.player.x = 0;
      this.player.z = 9.5;
      this.player.facingAngle = -Math.PI / 2;

      this.pillars = [
        { x: -6.0, z: 3.0, radius: 0.95 },
        { x: 6.0, z: 3.0, radius: 0.95 },
        { x: -5.5, z: -4.0, radius: 0.95 },
        { x: 5.5, z: -4.0, radius: 0.95 },
      ];

      // 기둥 뒤에서 나타나는 보라색 포자 로토스 광신도 3기
      for (const [lx, lz] of [
        [-7.5, 0.5],
        [7.5, 0.5],
        [-3.5, -2.5],
      ]) {
        this.enemies.push(this.createEnemy('lotus_cultist', lx, lz));
      }

      // 주황색 원형 낙하 예고를 띄우는 키클롭스 투석병 2기
      this.enemies.push(this.createEnemy('boulder_cyclops', 4.5, -6.5));
      this.enemies.push(this.createEnemy('boulder_cyclops', -5.5, -7.5));

      this.showBanner(
        'Scene 3. 키클롭스의 동굴 — “눈을 뜨는 어둠”: 보라색 포자 광신도와 주황색 원형 낙석 예고를 돌파하세요!'
      );
      return;
    }

    if (scene === 'scene4_polyphemus_boss') {
      // Scene 4: 폴리페모스 보스전 — “단 하나의 눈”
      this.player.x = 0;
      this.player.z = 8.5;
      this.player.facingAngle = -Math.PI / 2;

      this.pillars = [
        { x: -8.0, z: 1.5, radius: 1.0 },
        { x: 8.0, z: 1.5, radius: 1.0 },
      ];

      this.enemies.push(this.createEnemy('boss_polyphemus', 0, -5.5));
      this.showBanner(
        'Scene 4. 폴리페모스 보스전 — “단 하나의 눈”: 부채꼴 곤봉 강타 후 빛나는 금빛 외눈을 강궁 풀차징으로 저격하세요!'
      );
      return;
    }

    if (scene === 'scene6_siren_reef') {
      // Scene 6: 세이렌의 암초 — “아름다운 목소리, 위험한 바다”
      this.player.x = 0;
      this.player.z = 9.5;
      this.player.facingAngle = -Math.PI / 2;

      this.pillars = [
        { x: -5.5, z: 2.5, radius: 0.9 },
        { x: 5.5, z: 2.5, radius: 0.9 },
      ];

      // 좁은 대리석 길목을 막는 망령 방패병 2기
      this.enemies.push(this.createEnemy('drowned_hoplite', -3.0, 2.0));
      this.enemies.push(this.createEnemy('drowned_hoplite', 3.0, 1.0));

      // 공중에서 세 갈래 푸른 음파를 쏘는 세이렌 하피 2기
      const bell = this.createEnemy('resonance_bell', 8.5, -5.5);
      this.enemies.push(bell);

      const harpy1 = this.createEnemy('siren_harpy', -6.0, -5.0);
      harpy1.linkedBellId = bell.id;
      harpy1.shielded = true;
      const harpy2 = this.createEnemy('siren_harpy', 3.5, -6.5);
      harpy2.linkedBellId = bell.id;
      harpy2.shielded = true;

      this.enemies.push(harpy1, harpy2);
      this.showBanner(
        'Scene 6. 세이렌의 암초 — “아름다운 목소리, 위험한 바다”: 길 끝의 청동 종을 타격해 하피의 음파 보호막을 깨뜨리세요!'
      );
      return;
    }

    if (scene === 'scene7_parthenope_boss') {
      // Scene 7: 파르테노페 보스전 — “노래를 끊는 종소리”
      this.player.x = 0;
      this.player.z = 9.0;
      this.player.facingAngle = -Math.PI / 2;

      // 가장자리의 청동 종 3개 (중앙 여왕과 가장자리의 영웅·종이 삼각형을 이루는 구도)
      const bellLeft = this.createEnemy('resonance_bell', -10.5, 2.0);
      const bellRight = this.createEnemy('resonance_bell', 10.5, 2.0);
      const bellNorth = this.createEnemy('resonance_bell', 0, -10.5);
      this.enemies.push(bellLeft, bellRight, bellNorth);

      const queen = this.createEnemy('boss_parthenope', 0, -1.5);
      queen.linkedBellId = bellLeft.id;
      this.enemies.push(queen);

      this.showBanner(
        'Scene 7. 파르테노페 보스전 — “노래를 끊는 종소리”: 청자색 인력 음파가 퍼질 때 가장자리 청동 종을 타격해 황금 공명으로 가르세요!'
      );
      return;
    }

    if (scene === 'training_grounds') {
      this.spawnTrainingGrounds();
    }
  }

  private createEnemy(kind: EnemyEntity['kind'], x: number, z: number): EnemyEntity {
    if (kind === 'lotus_cultist') {
      return {
        id: this.nextId++,
        kind,
        isBoss: false,
        name: '로토스 광신도',
        subtitle: '탁한 보라색 포자 폭발',
        x,
        z,
        homeX: x,
        homeZ: z,
        vx: 0,
        vz: 0,
        radius: 0.65,
        visualScale: 1.9,
        facingAngle: Math.PI / 2,
        hp: 95,
        maxHp: 95,
        state: 'idle',
        stateTimer: 0,
        stateDuration: 0.9,
        cooldownTimer: 0.8,
        attackPatternIndex: 0,
        weakPointExposed: false,
        shielded: false,
        hitFlashTimer: 0,
        telegraph: null,
      };
    }

    if (kind === 'boulder_cyclops') {
      return {
        id: this.nextId++,
        kind,
        isBoss: false,
        name: '키클롭스 투석병',
        subtitle: '주황색 원형 낙석 예고 공격',
        x,
        z,
        homeX: x,
        homeZ: z,
        vx: 0,
        vz: 0,
        radius: 0.95,
        visualScale: 2.4,
        facingAngle: Math.PI / 2,
        hp: 165,
        maxHp: 165,
        state: 'idle',
        stateTimer: 0,
        stateDuration: 1.3,
        cooldownTimer: 1.2,
        attackPatternIndex: 0,
        weakPointExposed: false,
        shielded: false,
        hitFlashTimer: 0,
        telegraph: null,
      };
    }

    if (kind === 'boss_polyphemus') {
      return {
        id: this.nextId++,
        kind,
        isBoss: true,
        name: '폴리페모스 — 포세이돈의 외눈 거인',
        subtitle: '곤봉 강타 직후 금빛 외눈 약점을 강궁 풀차징으로 저격!',
        x,
        z,
        homeX: x,
        homeZ: z,
        vx: 0,
        vz: 0,
        radius: 1.65,
        visualScale: 4.1, // 작은 영웅과 거대한 보스의 크기 차이를 강조
        facingAngle: Math.PI / 2,
        hp: 680,
        maxHp: 680,
        state: 'idle',
        stateTimer: 0,
        stateDuration: 1.5,
        cooldownTimer: 1.2,
        attackPatternIndex: 0,
        weakPointExposed: false,
        shielded: true,
        hitFlashTimer: 0,
        telegraph: null,
      };
    }

    if (kind === 'siren_harpy') {
      return {
        id: this.nextId++,
        kind,
        isBoss: false,
        name: '세이렌 하피',
        subtitle: '세 갈래의 선명한 푸른 음파 발사',
        x,
        z,
        homeX: x,
        homeZ: z,
        vx: 0,
        vz: 0,
        radius: 0.75,
        visualScale: 2.1,
        facingAngle: Math.PI / 2,
        hp: 130,
        maxHp: 130,
        state: 'idle',
        stateTimer: 0,
        stateDuration: 1.0,
        cooldownTimer: 1.1,
        attackPatternIndex: 0,
        weakPointExposed: false,
        shielded: false,
        hitFlashTimer: 0,
        telegraph: null,
      };
    }

    if (kind === 'drowned_hoplite') {
      return {
        id: this.nextId++,
        kind,
        isBoss: false,
        name: '난파선 망령 방패병',
        subtitle: '정면 방패 방어 · Q 패링 또는 근접 돌파',
        x,
        z,
        homeX: x,
        homeZ: z,
        vx: 0,
        vz: 0,
        radius: 0.8,
        visualScale: 2.15,
        facingAngle: Math.PI / 2,
        hp: 155,
        maxHp: 155,
        state: 'idle',
        stateTimer: 0,
        stateDuration: 0.9,
        cooldownTimer: 1.0,
        attackPatternIndex: 0,
        weakPointExposed: false,
        shielded: false,
        hitFlashTimer: 0,
        telegraph: null,
      };
    }

    if (kind === 'boss_parthenope') {
      return {
        id: this.nextId++,
        kind,
        isBoss: true,
        name: '세이렌 여왕 파르테노페',
        subtitle: '청자색 유혹의 노래 시전 시 가장자리 청동 종을 타격해 파훼!',
        x,
        z,
        homeX: x,
        homeZ: z,
        vx: 0,
        vz: 0,
        radius: 1.45,
        visualScale: 3.7,
        facingAngle: Math.PI / 2,
        hp: 720,
        maxHp: 720,
        state: 'idle',
        stateTimer: 0,
        stateDuration: 1.5,
        cooldownTimer: 1.3,
        attackPatternIndex: 0,
        weakPointExposed: false,
        shielded: true,
        hitFlashTimer: 0,
        telegraph: null,
      };
    }

    if (kind === 'resonance_bell') {
      return {
        id: this.nextId++,
        kind,
        isBoss: false,
        name: '고대 청동 종',
        subtitle: '창·활로 타격 시 황금 공명 파동 발생!',
        x,
        z,
        homeX: x,
        homeZ: z,
        vx: 0,
        vz: 0,
        radius: 0.85,
        visualScale: 2.35,
        facingAngle: 0,
        hp: 9999,
        maxHp: 9999,
        state: 'idle',
        stateTimer: 0,
        stateDuration: 1,
        cooldownTimer: 0,
        attackPatternIndex: 0,
        weakPointExposed: false,
        shielded: false,
        hitFlashTimer: 0,
        telegraph: null,
      };
    }

    return {
      id: this.nextId++,
      kind,
      isBoss: false,
      name: kind === 'pierce_dummy' ? '관통 훈련 허수아비' : '고대 투사체 발사 석상',
      subtitle: kind === 'pierce_dummy' ? '풀차징 일직선 관통 타겟' : 'Q 방패 패링 반사 훈련',
      x,
      z,
      homeX: x,
      homeZ: z,
      vx: 0,
      vz: 0,
      radius: 0.75,
      visualScale: 2.0,
      facingAngle: Math.PI,
      hp: 150,
      maxHp: 150,
      state: 'idle',
      stateTimer: 0,
      stateDuration: 1.0,
      cooldownTimer: 1.4,
      attackPatternIndex: 0,
      weakPointExposed: false,
      shielded: false,
      hitFlashTimer: 0,
      telegraph: null,
    };
  }

  public spawnTrainingGrounds(): void {
    this.enemies = [];
    this.projectiles = [];
    this.pillars = [
      { x: -5.5, z: -3.5, radius: 0.85 },
      { x: 5.5, z: -3.5, radius: 0.85 },
    ];

    // 서쪽: 3열 관통 허수아비
    for (const dx of [-8.5, -11.5, -14.5]) {
      this.enemies.push(this.createEnemy('pierce_dummy', dx, 2.0));
    }
    // 동쪽: 투사체 발사 석상
    this.enemies.push(this.createEnemy('projectile_statue', 13.0, -2.0));
    this.enemies.push(this.createEnemy('projectile_statue', 13.0, 4.0));
    // 북쪽 중앙: 폴리페모스 축소 수련체
    const polyTrainer = this.createEnemy('boss_polyphemus', 0, -8.5);
    polyTrainer.name = '외눈 거인 수련체 (약점 저격 훈련)';
    polyTrainer.hp = 350;
    polyTrainer.maxHp = 350;
    this.enemies.push(polyTrainer);
    // 북서쪽: 청동 종 + 세이렌 하피
    const bell = this.createEnemy('resonance_bell', -8.0, -8.0);
    const harpy = this.createEnemy('siren_harpy', -12.5, -8.0);
    harpy.linkedBellId = bell.id;
    harpy.shielded = true;
    this.enemies.push(bell, harpy);

    this.showBanner('M1+M2 자유 훈련장: 창 3단 콤보, 강궁 풀차징 관통·약점 저격, Q 방패 패링을 시험하세요!');
  }

  /**
   * Scene 5: 신의 가호 — “올림포스의 선택” 3지선다 열기 (한 번에 세 가호만 표시)
   */
  public openBoonSelection(nextScene: SceneId): void {
    this.boonSelectionOpen = true;
    this.nextSceneAfterBoon = nextScene;

    const allGods: GodId[] = ['athena', 'zeus', 'apollo', 'hermes'];
    // 셔플 후 정확히 3개의 가호만 추출
    const shuffled = [...allGods].sort(() => Math.random() - 0.5);
    this.boonChoices = shuffled.slice(0, 3).map((g) => OLYMPIAN_BOONS[g]);
    this.showBanner('Scene 5. 신의 가호 — “올림포스의 선택”: 세 갈래 신성한 문양 중 하나를 선택하세요.');
  }

  public selectBoon(god: GodId): void {
    this.player.activeBoons.add(god);
    this.boonSelectionOpen = false;
    this.audio.playParrySuccess();
    this.addFloatingText(
      this.player.x,
      this.player.z,
      `✨ ${OLYMPIAN_BOONS[god].titleKo} 획득!`,
      OLYMPIAN_BOONS[god].glowColor,
      2.6
    );

    if (this.nextSceneAfterBoon && this.nextSceneAfterBoon !== this.currentScene) {
      this.loadScene(this.nextSceneAfterBoon);
    }
  }

  public showBanner(text: string, duration = 4.0): void {
    this.bannerMessage = { text, timer: duration };
  }

  public addFloatingText(x: number, z: number, text: string, color = '#ffffff', y = 1.9): void {
    this.floatingTexts.push({ x, y, z, text, color });
  }

  public update(dt: number, input: InputManager): void {
    this.elapsedTime += dt;

    if (this.bannerMessage) {
      this.bannerMessage.timer -= dt;
      if (this.bannerMessage.timer <= 0) this.bannerMessage = null;
    }

    if (this.cameraShake > 0) {
      this.cameraShake = Math.max(0, this.cameraShake - dt * 2.8);
    }

    // 타이틀(Scene 1), 가호 선택(Scene 5), 귀환(Scene 8) 화면에서는 전투 물리 일시 정지
    if (
      this.currentScene === 'scene1_title' ||
      this.currentScene === 'scene8_return' ||
      this.boonSelectionOpen
    ) {
      return;
    }

    if (input.respawnJustPressed) {
      this.loadScene(this.currentScene);
      return;
    }

    if (this.hitStopTimer > 0) {
      this.hitStopTimer -= dt;
      return;
    }

    this.updatePlayer(dt, input);
    this.updateHubInteractions();
    this.updateEnemies(dt);
    this.updateProjectiles(dt);
    this.updateVisualTimers(dt);
  }

  private updateHubInteractions(): void {
    if (this.currentScene !== 'scene2_hub') {
      this.nearbyHubItem = null;
      return;
    }
    const p = this.player;
    let closest: HubInteractable | null = null;
    let minDist = 999;

    for (const item of this.hubInteractables) {
      const d = Math.hypot(p.x - item.x, p.z - item.z);
      if (d <= item.radius + 1.1 && d < minDist) {
        minDist = d;
        closest = item;
      }
    }
    this.nearbyHubItem = closest;
  }

  private updatePlayer(dt: number, input: InputManager): void {
    const p = this.player;
    const hasHermes = p.activeBoons.has('hermes');
    const hasApollo = p.activeBoons.has('apollo');

    if (p.dashCooldown > 0) p.dashCooldown = Math.max(0, p.dashCooldown - dt);
    if (p.parryCooldown > 0) p.parryCooldown = Math.max(0, p.parryCooldown - dt);
    if (p.boonCooldown > 0) p.boonCooldown = Math.max(0, p.boonCooldown - dt);
    if (p.invulnerableTimer > 0) p.invulnerableTimer = Math.max(0, p.invulnerableTimer - dt);
    if (p.hitFlashTimer > 0) p.hitFlashTimer = Math.max(0, p.hitFlashTimer - dt);

    if (p.state === 'idle' || p.state === 'move') {
      if (p.comboResetTimer > 0) {
        p.comboResetTimer -= dt;
        if (p.comboResetTimer <= 0) p.comboStep = 1;
      }
    }

    const aimDx = input.aimWorldPos.x - p.x;
    const aimDz = input.aimWorldPos.z - p.z;
    if (Math.hypot(aimDx, aimDz) > 0.01 && p.state !== 'dash') {
      p.facingAngle = Math.atan2(aimDz, aimDx);
    }

    const moveVec = input.getMoveVector();
    const baseMoveSpeed = COMBAT_CONFIG.player.moveSpeed * (hasHermes ? 1.25 : 1.0);

    // 1. E키: 신의 권능 발동 (보유한 가호에 따라 신성 스킬 발동!)
    if (input.boonJustPressed && p.boonCooldown <= 0) {
      p.boonCooldown = COMBAT_CONFIG.player.boonSlotE.cooldown;
      this.triggerDivinePowerE();
    }

    // 2. Space키: 무적 대시 (강궁 차징 중 대시 시 즉시 차징 취소!)
    if (input.dashJustPressed && p.dashCooldown <= 0 && p.state !== 'dash') {
      const wasChargingBow = p.state === 'bow_charge';
      p.bowCharge = 0;
      p.isFullCharged = false;

      p.state = 'dash';
      p.stateTimer = COMBAT_CONFIG.player.dash.duration;
      p.dashCooldown = COMBAT_CONFIG.player.dash.cooldown * (hasHermes ? 0.65 : 1.0);
      p.invulnerableTimer = COMBAT_CONFIG.player.dash.iframeDuration;

      if (Math.hypot(moveVec.x, moveVec.z) > 0.1) {
        p.dashDirX = moveVec.x;
        p.dashDirZ = moveVec.z;
      } else {
        p.dashDirX = Math.cos(p.facingAngle);
        p.dashDirZ = Math.sin(p.facingAngle);
      }
      p.facingAngle = Math.atan2(p.dashDirZ, p.dashDirX);
      this.audio.playDash();

      // 아테나 가호 보유 시 대시 출발 지점에 아이기스 황금 보호막 충격파 발생
      if (p.activeBoons.has('athena')) {
        this.shockwaves.push({
          id: this.nextId++,
          x: p.x,
          z: p.z,
          maxRadius: 3.0,
          color: '#fbbf24',
          timer: 0,
          duration: 0.28,
        });
      }

      if (wasChargingBow) {
        this.addFloatingText(p.x, p.z, '차징 취소 대시!', '#fde68a', 2.0);
      }
      return;
    }

    // 3. Q키: 방패 패링
    if (
      input.parryJustPressed &&
      p.parryCooldown <= 0 &&
      p.state !== 'dash' &&
      p.state !== 'parry_active'
    ) {
      p.bowCharge = 0;
      p.isFullCharged = false;
      p.state = 'parry_active';
      p.stateTimer = COMBAT_CONFIG.player.parry.activeDuration;
      p.parryCooldown = COMBAT_CONFIG.player.parry.cooldown;

      this.swings.push({
        id: this.nextId++,
        x: p.x,
        z: p.z,
        angle: p.facingAngle,
        comboStep: 'parry',
        radius: COMBAT_CONFIG.player.parry.range,
        arc: COMBAT_CONFIG.player.parry.arc,
        length: 0,
        width: 0,
        timer: 0,
        maxTimer: COMBAT_CONFIG.player.parry.activeDuration,
      });
      this.audio.playSpearSwing(1);
      return;
    }

    switch (p.state) {
      case 'dash': {
        p.vx = p.dashDirX * COMBAT_CONFIG.player.dash.speed;
        p.vz = p.dashDirZ * COMBAT_CONFIG.player.dash.speed;
        this.movePlayerWithCollision(dt);
        p.stateTimer -= dt;
        if (p.stateTimer <= 0) {
          p.state = 'idle';
          p.vx = 0;
          p.vz = 0;
        }
        break;
      }

      case 'parry_active': {
        p.vx = moveVec.x * baseMoveSpeed * 0.35;
        p.vz = moveVec.z * baseMoveSpeed * 0.35;
        this.movePlayerWithCollision(dt);
        p.stateTimer -= dt;
        if (p.stateTimer <= 0) {
          p.state = 'parry_recovery';
          p.stateTimer = COMBAT_CONFIG.player.parry.recoveryDuration;
        }
        break;
      }

      case 'parry_recovery':
      case 'bow_recovery': {
        p.vx = moveVec.x * baseMoveSpeed * 0.5;
        p.vz = moveVec.z * baseMoveSpeed * 0.5;
        this.movePlayerWithCollision(dt);
        p.stateTimer -= dt;
        if (p.stateTimer <= 0) p.state = 'idle';
        break;
      }

      case 'spear_windup': {
        const stepCfg = COMBAT_CONFIG.player.spear.steps[p.comboStep];
        p.vx = Math.cos(p.facingAngle) * stepCfg.stepForward;
        p.vz = Math.sin(p.facingAngle) * stepCfg.stepForward;
        this.movePlayerWithCollision(dt);
        p.stateTimer -= dt;
        if (p.stateTimer <= 0) {
          p.state = 'spear_swing';
          p.stateTimer = stepCfg.active;
          p.hasDealtSwingDamage = false;
          this.audio.playSpearSwing(p.comboStep);
          this.spawnSpearSwingVisual(p.comboStep);
        }
        break;
      }

      case 'spear_swing': {
        const stepCfg = COMBAT_CONFIG.player.spear.steps[p.comboStep];
        p.vx = Math.cos(p.facingAngle) * (stepCfg.stepForward * 0.5);
        p.vz = Math.sin(p.facingAngle) * (stepCfg.stepForward * 0.5);
        this.movePlayerWithCollision(dt);

        if (!p.hasDealtSwingDamage) {
          this.performSpearHitCheck(p.comboStep);
          p.hasDealtSwingDamage = true;
        }

        p.stateTimer -= dt;
        if (p.stateTimer <= 0) {
          p.state = 'spear_recovery';
          p.stateTimer = stepCfg.recovery;
        }
        break;
      }

      case 'spear_recovery': {
        p.vx = moveVec.x * baseMoveSpeed * 0.45;
        p.vz = moveVec.z * baseMoveSpeed * 0.45;
        this.movePlayerWithCollision(dt);
        p.stateTimer -= dt;

        if (input.leftClickJustPressed && p.stateTimer <= 0.09) {
          this.advanceSpearCombo();
          this.startSpearAttack();
          break;
        }

        if (p.stateTimer <= 0) {
          this.advanceSpearCombo();
          p.state = 'idle';
        }
        break;
      }

      case 'bow_charge': {
        const speed = baseMoveSpeed * COMBAT_CONFIG.player.bowChargeMoveMultiplier;
        p.vx = moveVec.x * speed;
        p.vz = moveVec.z * speed;
        this.movePlayerWithCollision(dt);

        const chargeTimeReq =
          COMBAT_CONFIG.player.bow.fullChargeTime * (hasApollo ? 0.65 : 1.0);
        const prevFull = p.isFullCharged;
        p.bowCharge = Math.min(1, p.bowCharge + dt / chargeTimeReq);
        if (p.bowCharge >= 1 && !prevFull) {
          p.isFullCharged = true;
          this.audio.playBowReady();
          this.addFloatingText(p.x, p.z, '⚡ 차징 완료! (관통 · 외눈 약점 저격)', '#7dd3fc', 2.2);
        }

        if (!input.rightMouseDown || input.rightClickJustReleased) {
          this.fireBowArrow();
        }
        break;
      }

      case 'idle':
      case 'move':
      default: {
        if (input.leftClickJustPressed) {
          this.startSpearAttack();
          break;
        }
        if (input.rightMouseDown) {
          p.state = 'bow_charge';
          p.bowCharge = 0;
          p.isFullCharged = false;
          break;
        }
        p.vx = moveVec.x * baseMoveSpeed;
        p.vz = moveVec.z * baseMoveSpeed;
        this.movePlayerWithCollision(dt);
        p.state = Math.hypot(p.vx, p.vz) > 0.1 ? 'move' : 'idle';
        break;
      }
    }
  }

  private triggerDivinePowerE(): void {
    const p = this.player;
    this.audio.playParrySuccess();
    this.cameraShake = 0.32;

    const color = p.activeBoons.has('zeus')
      ? '#60a5fa'
      : p.activeBoons.has('apollo')
        ? '#fb923c'
        : p.activeBoons.has('hermes')
          ? '#2dd4bf'
          : '#fbbf24';

    this.shockwaves.push({
      id: this.nextId++,
      x: p.x,
      z: p.z,
      maxRadius: 5.5,
      color,
      timer: 0,
      duration: 0.42,
    });

    let hitCount = 0;
    const dmg = Math.round(58 * this.getAttackMultiplier());
    for (const enemy of this.enemies) {
      if (enemy.hp <= 0) continue;
      const d = Math.hypot(enemy.x - p.x, enemy.z - p.z);
      if (d <= 6.2) {
        hitCount++;
        this.lightningArcs.push({
          id: this.nextId++,
          x1: p.x,
          z1: p.z,
          x2: enemy.x,
          z2: enemy.z,
          timer: 0,
          duration: 0.28,
        });
        this.applyDamageToEnemy(enemy, dmg, 0, 0, false);
      }
    }

    this.addFloatingText(
      p.x,
      p.z,
      hitCount > 0 ? `⚡ 신의 권능 방출! (${hitCount}체 타격)` : '⚡ 신의 권능 방출!',
      color,
      2.5
    );
  }

  private startSpearAttack(): void {
    const p = this.player;
    const stepCfg = COMBAT_CONFIG.player.spear.steps[p.comboStep];
    p.state = 'spear_windup';
    p.stateTimer = stepCfg.windup;
    p.comboResetTimer = COMBAT_CONFIG.player.spear.comboWindow;
  }

  private advanceSpearCombo(): void {
    const p = this.player;
    p.comboStep = p.comboStep === 1 ? 2 : p.comboStep === 2 ? 3 : 1;
    p.comboResetTimer = COMBAT_CONFIG.player.spear.comboWindow;
  }

  private spawnSpearSwingVisual(step: 1 | 2 | 3): void {
    const p = this.player;
    const stepCfg = COMBAT_CONFIG.player.spear.steps[step];
    this.swings.push({
      id: this.nextId++,
      x: p.x,
      z: p.z,
      angle: p.facingAngle,
      comboStep: step,
      radius: 'range' in stepCfg ? stepCfg.range : 0,
      arc: 'arc' in stepCfg ? stepCfg.arc : 0,
      length: 'length' in stepCfg ? stepCfg.length : 0,
      width: 'width' in stepCfg ? stepCfg.width : 0,
      timer: 0,
      maxTimer: step === 3 ? 0.24 : 0.18,
    });
  }

  private performSpearHitCheck(step: 1 | 2 | 3): void {
    const p = this.player;
    const mult = this.getAttackMultiplier();
    let hitAny = false;

    for (const enemy of this.enemies) {
      if (enemy.hp <= 0) continue;

      const dx = enemy.x - p.x;
      const dz = enemy.z - p.z;
      const dist = Math.hypot(dx, dz);
      const angleToEnemy = Math.atan2(dz, dx);
      const angleDiff = Math.abs(this.normalizeAngle(angleToEnemy - p.facingAngle));

      let isHit = false;
      let damage = 0;
      let knockback = 0;

      if (step === 1) {
        const cfg = COMBAT_CONFIG.player.spear.steps[1];
        if (dist <= cfg.range + enemy.radius && angleDiff <= cfg.arc * 0.5 + 0.18) {
          isHit = true;
          damage = Math.round(cfg.damage * mult);
          knockback = cfg.knockback;
        }
      } else if (step === 2) {
        const cfg = COMBAT_CONFIG.player.spear.steps[2];
        const dirX = Math.cos(p.facingAngle);
        const dirZ = Math.sin(p.facingAngle);
        const forwardProj = dx * dirX + dz * dirZ;
        const sideDist = Math.abs(-dx * dirZ + dz * dirX);
        if (
          forwardProj >= -0.35 &&
          forwardProj <= cfg.length + enemy.radius &&
          sideDist <= cfg.width * 0.5 + enemy.radius
        ) {
          isHit = true;
          damage = Math.round(cfg.damage * mult);
          knockback = cfg.knockback;
        }
      } else {
        const cfg = COMBAT_CONFIG.player.spear.steps[3];
        if (dist <= cfg.range + enemy.radius && angleDiff <= cfg.arc * 0.5 + 0.2) {
          isHit = true;
          damage = Math.round(cfg.damage * mult);
          knockback = cfg.knockback;
        }
      }

      if (isHit) {
        hitAny = true;
        this.applyDamageToEnemy(
          enemy,
          damage,
          Math.cos(p.facingAngle) * knockback,
          Math.sin(p.facingAngle) * knockback,
          false
        );

        // 제우스 가호 보유 시 3타 적중에 연쇄 번개 발동
        if (step === 3 && p.activeBoons.has('zeus')) {
          this.triggerZeusChainLightning(enemy);
        }
      }
    }

    if (hitAny) {
      this.audio.playHit(step === 3);
      this.hitStopTimer = step === 3 ? 0.055 : 0.03;
      this.cameraShake = Math.max(this.cameraShake, step === 3 ? 0.35 : 0.16);
    }
  }

  private triggerZeusChainLightning(sourceEnemy: EnemyEntity): void {
    for (const other of this.enemies) {
      if (other.hp <= 0 || other.id === sourceEnemy.id || other.kind === 'resonance_bell') continue;
      if (Math.hypot(other.x - sourceEnemy.x, other.z - sourceEnemy.z) <= 6.5) {
        this.lightningArcs.push({
          id: this.nextId++,
          x1: sourceEnemy.x,
          z1: sourceEnemy.z,
          x2: other.x,
          z2: other.z,
          timer: 0,
          duration: 0.26,
        });
        other.hp = Math.max(0, other.hp - 28);
        this.addFloatingText(other.x, other.z, '⚡뇌전 -28', '#93c5fd', 2.2);
      }
    }
  }

  private fireBowArrow(): void {
    const p = this.player;
    const chargeRatio = p.bowCharge;
    const isFull = p.isFullCharged || chargeRatio >= 0.99;

    if (chargeRatio * COMBAT_CONFIG.player.bow.fullChargeTime < COMBAT_CONFIG.player.bow.minChargeToFire) {
      p.bowCharge = 0;
      p.isFullCharged = false;
      p.state = 'idle';
      return;
    }

    const mult = this.getAttackMultiplier();
    const speed = isFull
      ? COMBAT_CONFIG.player.bow.pierceSpeed
      : COMBAT_CONFIG.player.bow.normalSpeed;
    const rawDmg = isFull
      ? COMBAT_CONFIG.player.bow.pierceDamage
      : Math.round(COMBAT_CONFIG.player.bow.normalDamage * (0.65 + 0.35 * chargeRatio));

    const dirX = Math.cos(p.facingAngle);
    const dirZ = Math.sin(p.facingAngle);

    this.projectiles.push({
      id: this.nextId++,
      owner: 'player',
      kind: isFull ? 'arrow_pierce' : 'arrow_normal',
      x: p.x + dirX * 0.75,
      z: p.z + dirZ * 0.75,
      vx: dirX * speed,
      vz: dirZ * speed,
      angle: p.facingAngle,
      radius: isFull ? 0.35 : 0.22,
      damage: Math.round(rawDmg * mult),
      piercing: isFull,
      weakPointShatter: isFull,
      hitEntityIds: new Set<number>(),
      life: 0,
      maxLife: 1.4,
    });

    this.audio.playBowRelease(isFull);
    if (isFull) this.cameraShake = Math.max(this.cameraShake, 0.22);

    p.bowCharge = 0;
    p.isFullCharged = false;
    p.state = 'bow_recovery';
    p.stateTimer = COMBAT_CONFIG.player.bow.postFireRecovery;
  }

  private updateEnemies(dt: number): void {
    const p = this.player;

    for (const enemy of this.enemies) {
      if (enemy.hp <= 0) continue;
      if (enemy.hitFlashTimer > 0) enemy.hitFlashTimer = Math.max(0, enemy.hitFlashTimer - dt);

      enemy.x += enemy.vx * dt;
      enemy.z += enemy.vz * dt;
      enemy.vx *= Math.pow(0.001, dt);
      enemy.vz *= Math.pow(0.001, dt);
      this.clampToArena(enemy);

      if (enemy.kind === 'pierce_dummy' || enemy.kind === 'resonance_bell') {
        continue;
      }

      if (enemy.state === 'staggered') {
        enemy.telegraph = null;
        enemy.weakPointExposed = false;
        enemy.stateTimer -= dt;
        if (enemy.stateTimer <= 0) {
          enemy.state = 'idle';
          enemy.cooldownTimer = 1.1;
          if (enemy.kind === 'boss_polyphemus' || enemy.kind === 'boss_parthenope') {
            enemy.shielded = true;
          }
        }
        continue;
      }

      const dx = p.x - enemy.x;
      const dz = p.z - enemy.z;
      const distToPlayer = Math.hypot(dx, dz);
      const angleToPlayer = Math.atan2(dz, dx);

      // 1. 로토스 광신도 (Scene 3 — 보라색 포자 구름 근접 폭발)
      if (enemy.kind === 'lotus_cultist') {
        if (enemy.state === 'idle' || enemy.state === 'chase') {
          enemy.facingAngle = angleToPlayer;
          if (distToPlayer > 2.2) {
            enemy.state = 'chase';
            enemy.x += Math.cos(angleToPlayer) * 4.2 * dt;
            enemy.z += Math.sin(angleToPlayer) * 4.2 * dt;
          } else {
            enemy.state = 'windup';
            enemy.stateDuration = 0.8;
            enemy.stateTimer = 0.8;
          }
        } else if (enemy.state === 'windup') {
          const progress = 1 - enemy.stateTimer / enemy.stateDuration;
          enemy.telegraph = {
            type: 'circle',
            x: enemy.x,
            z: enemy.z,
            radius: 2.9,
            progress,
            color: '#a855f7',
            style: 'spore_purple',
          };
          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            enemy.telegraph = null;
            enemy.state = 'idle';
            enemy.cooldownTimer = 1.4;
            this.shockwaves.push({
              id: this.nextId++,
              x: enemy.x,
              z: enemy.z,
              maxRadius: 2.9,
              color: '#a855f7',
              timer: 0,
              duration: 0.35,
            });
            if (distToPlayer <= 2.9 + p.radius) {
              this.handleEnemyMeleeHitPlayer(enemy, 18);
            }
          }
        }
        continue;
      }

      // 2. 키클롭스 투석병 (Scene 3 — 바위 낙하 예정 지점에 주황색 원형 예고 표시!)
      if (enemy.kind === 'boulder_cyclops') {
        if (enemy.state === 'idle') {
          enemy.facingAngle = angleToPlayer;
          enemy.cooldownTimer -= dt;
          if (enemy.cooldownTimer <= 0) {
            enemy.state = 'windup';
            enemy.stateDuration = 1.25;
            enemy.stateTimer = 1.25;
            // 플레이어의 현재 위치에 주황색 원형 바위 낙하 예고 장판 생성
            enemy.telegraph = {
              type: 'circle',
              x: p.x,
              z: p.z,
              radius: 2.6,
              progress: 0,
              color: '#f97316',
              style: 'boulder_orange',
            };
          }
        } else if (enemy.state === 'windup') {
          if (enemy.telegraph && enemy.telegraph.type === 'circle') {
            enemy.telegraph.progress = 1 - enemy.stateTimer / enemy.stateDuration;
          }
          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            const tx = enemy.telegraph ? enemy.telegraph.x : p.x;
            const tz = enemy.telegraph ? enemy.telegraph.z : p.z;
            enemy.telegraph = null;
            enemy.state = 'idle';
            enemy.cooldownTimer = 2.0;

            this.shockwaves.push({
              id: this.nextId++,
              x: tx,
              z: tz,
              maxRadius: 2.6,
              color: '#f97316',
              timer: 0,
              duration: 0.38,
            });
            this.cameraShake = Math.max(this.cameraShake, 0.25);
            if (Math.hypot(p.x - tx, p.z - tz) <= 2.6 + p.radius) {
              this.damagePlayer(24);
            }
          }
        }
        continue;
      }

      // 3. 보스 1: 폴리페모스 (Scene 4 — 부채꼴 곤봉 충격파 + 포효 시 금빛 외눈 약점 노출)
      if (enemy.kind === 'boss_polyphemus') {
        if (enemy.state === 'idle') {
          enemy.facingAngle = angleToPlayer;
          if (distToPlayer > 4.2) {
            enemy.x += Math.cos(angleToPlayer) * 2.3 * dt;
            enemy.z += Math.sin(angleToPlayer) * 2.3 * dt;
          }
          enemy.cooldownTimer -= dt;
          if (enemy.cooldownTimer <= 0) {
            enemy.state = 'windup';
            enemy.stateDuration = 1.25;
            enemy.stateTimer = 1.25;
            enemy.facingAngle = angleToPlayer;
          }
        } else if (enemy.state === 'windup') {
          const progress = 1 - enemy.stateTimer / enemy.stateDuration;
          // 거대 곤봉 부채꼴 강타 예고
          enemy.telegraph = {
            type: 'sector',
            x: enemy.x,
            z: enemy.z,
            radius: 6.2,
            angle: enemy.facingAngle,
            arc: (115 * Math.PI) / 180,
            progress,
            color: '#f97316',
          };
          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            enemy.telegraph = null;
            // 부채꼴 먼지와 돌조각 충격파 방출!
            this.shockwaves.push({
              id: this.nextId++,
              x: enemy.x,
              z: enemy.z,
              maxRadius: 6.2,
              color: '#d97706',
              timer: 0,
              duration: 0.45,
              style: 'dust_fan',
              angle: enemy.facingAngle,
            });
            this.cameraShake = Math.max(this.cameraShake, 0.45);

            const diff = Math.abs(this.normalizeAngle(angleToPlayer - enemy.facingAngle));
            if (distToPlayer <= 6.2 + p.radius && diff <= ((115 * Math.PI) / 180) * 0.5 + 0.15) {
              this.handleEnemyMeleeHitPlayer(enemy, 32);
            }

            // 강타 직후 포효하며 금빛 외눈 약점 노출!
            enemy.state = 'weak_open';
            enemy.stateDuration = 3.8;
            enemy.stateTimer = 3.8;
            enemy.weakPointExposed = true;
            this.addFloatingText(
              enemy.x,
              enemy.z,
              '👁️ 금빛 외눈 노출! (우클릭 풀차징 화살로 저격!)',
              '#fde047',
              3.2
            );
          }
        } else if (enemy.state === 'weak_open') {
          enemy.facingAngle = angleToPlayer;
          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            enemy.weakPointExposed = false;
            enemy.state = 'idle';
            enemy.cooldownTimer = 1.4;
          }
        }
        continue;
      }

      // 4. 세이렌 하피 (Scene 6 — 공중에서 날개를 펼치며 세 갈래의 푸른 음파 발사!)
      if (enemy.kind === 'siren_harpy') {
        enemy.facingAngle = angleToPlayer;
        if (enemy.state === 'idle') {
          enemy.cooldownTimer -= dt;
          if (enemy.cooldownTimer <= 0) {
            enemy.state = 'windup';
            enemy.stateDuration = 0.85;
            enemy.stateTimer = 0.85;
          }
        } else if (enemy.state === 'windup') {
          const progress = 1 - enemy.stateTimer / enemy.stateDuration;
          enemy.telegraph = {
            type: 'sector',
            x: enemy.x,
            z: enemy.z,
            radius: 5.5,
            angle: enemy.facingAngle,
            arc: (50 * Math.PI) / 180,
            progress,
            color: '#38bdf8',
          };
          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            enemy.telegraph = null;
            enemy.state = 'idle';
            enemy.cooldownTimer = 2.1;

            // 세 갈래의 선명한 푸른 음파 탄환 발사!
            const spreadAngles = [-0.26, 0, 0.26];
            for (const offset of spreadAngles) {
              const ang = enemy.facingAngle + offset;
              const spd = 10.5;
              this.projectiles.push({
                id: this.nextId++,
                owner: 'enemy',
                kind: 'siren_sonic_orb',
                x: enemy.x + Math.cos(ang) * 0.8,
                z: enemy.z + Math.sin(ang) * 0.8,
                vx: Math.cos(ang) * spd,
                vz: Math.sin(ang) * spd,
                angle: ang,
                radius: 0.36,
                damage: 16,
                piercing: false,
                weakPointShatter: false,
                hitEntityIds: new Set<number>(),
                life: 0,
                maxLife: 2.8,
              });
            }
          }
        }
        continue;
      }

      // 5. 난파선 망령 방패병 (Scene 6 — 좁은 대리석 통로를 막으며 창 찌르기)
      if (enemy.kind === 'drowned_hoplite') {
        if (enemy.state === 'idle' || enemy.state === 'chase') {
          enemy.facingAngle = angleToPlayer;
          if (distToPlayer > 2.4 && distToPlayer < 10) {
            enemy.state = 'chase';
            enemy.x += Math.cos(angleToPlayer) * 2.9 * dt;
            enemy.z += Math.sin(angleToPlayer) * 2.9 * dt;
          }
          enemy.cooldownTimer -= dt;
          if (distToPlayer <= 3.0 && enemy.cooldownTimer <= 0) {
            enemy.state = 'windup';
            enemy.stateDuration = 0.8;
            enemy.stateTimer = 0.8;
          }
        } else if (enemy.state === 'windup') {
          const progress = 1 - enemy.stateTimer / enemy.stateDuration;
          enemy.telegraph = {
            type: 'sector',
            x: enemy.x,
            z: enemy.z,
            radius: 3.1,
            angle: enemy.facingAngle,
            arc: (95 * Math.PI) / 180,
            progress,
            color: '#38bdf8',
          };
          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            enemy.telegraph = null;
            enemy.state = 'idle';
            enemy.cooldownTimer = 1.5;
            const diff = Math.abs(this.normalizeAngle(angleToPlayer - enemy.facingAngle));
            if (distToPlayer <= 3.1 + p.radius && diff <= ((95 * Math.PI) / 180) * 0.5 + 0.15) {
              this.handleEnemyMeleeHitPlayer(enemy, 20);
            }
          }
        }
        continue;
      }

      // 6. 보스 2: 세이렌 여왕 파르테노페 (Scene 7 — 동심원 청자색 음파 인력 vs 가장자리 청동 종 황금 공명!)
      if (enemy.kind === 'boss_parthenope') {
        enemy.facingAngle = angleToPlayer;
        if (enemy.state === 'idle') {
          enemy.cooldownTimer -= dt;
          if (enemy.cooldownTimer <= 0) {
            enemy.attackPatternIndex = (enemy.attackPatternIndex + 1) % 2;

            if (enemy.attackPatternIndex === 1) {
              // 패턴 A: 유혹의 노래 (청자색 동심원 음파로 플레이어를 중앙으로 끌어당김!)
              enemy.state = 'attack';
              enemy.stateDuration = 4.8;
              enemy.stateTimer = 4.8;
              this.addFloatingText(
                enemy.x,
                enemy.z,
                '🎵 파멸의 노래! (가장자리 청동 종을 타격해 황금 공명으로 끊으세요!)',
                '#c084fc',
                3.2
              );
            } else {
              // 패턴 B: 5갈래 푸른 세이렌 음파 탄막 방사
              for (let i = -2; i <= 2; i++) {
                const ang = angleToPlayer + i * 0.22;
                const spd = 11.0;
                this.projectiles.push({
                  id: this.nextId++,
                  owner: 'enemy',
                  kind: 'siren_sonic_orb',
                  x: enemy.x + Math.cos(ang) * 1.1,
                  z: enemy.z + Math.sin(ang) * 1.1,
                  vx: Math.cos(ang) * spd,
                  vz: Math.sin(ang) * spd,
                  angle: ang,
                  radius: 0.38,
                  damage: 18,
                  piercing: false,
                  weakPointShatter: false,
                  hitEntityIds: new Set<number>(),
                  life: 0,
                  maxLife: 3.0,
                });
              }
              enemy.cooldownTimer = 1.8;
            }
          }
        } else if (enemy.state === 'attack') {
          const progress = 1 - enemy.stateTimer / enemy.stateDuration;
          enemy.telegraph = {
            type: 'circle',
            x: enemy.x,
            z: enemy.z,
            radius: 9.2,
            progress,
            color: '#a855f7',
            style: 'siren_pull',
          };

          // 플레이어를 중앙 여왕 쪽으로 서서히 끌어당기는 인력 작동!
          if (distToPlayer > 1.8 && p.state !== 'dash') {
            const pullSpeed = 2.65;
            p.x -= Math.cos(angleToPlayer) * pullSpeed * dt;
            p.z -= Math.sin(angleToPlayer) * pullSpeed * dt;
          }

          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            enemy.telegraph = null;
            enemy.state = 'idle';
            enemy.cooldownTimer = 2.0;
            this.shockwaves.push({
              id: this.nextId++,
              x: enemy.x,
              z: enemy.z,
              maxRadius: 9.2,
              color: '#a855f7',
              timer: 0,
              duration: 0.45,
              style: 'siren_ring',
            });
            if (distToPlayer <= 9.2) {
              this.damagePlayer(34);
            }
          }
        }
        continue;
      }

      // 7. 고대 투사체 발사 석상 (훈련장용)
      if (enemy.kind === 'projectile_statue') {
        if (enemy.state === 'idle') {
          enemy.facingAngle = angleToPlayer;
          enemy.cooldownTimer -= dt;
          if (enemy.cooldownTimer <= 0) {
            enemy.state = 'windup';
            enemy.stateDuration = 0.9;
            enemy.stateTimer = 0.9;
          }
        } else if (enemy.state === 'windup') {
          const progress = 1 - enemy.stateTimer / enemy.stateDuration;
          enemy.telegraph = {
            type: 'line',
            x: enemy.x,
            z: enemy.z,
            angle: enemy.facingAngle,
            length: 15,
            width: 0.5,
            progress,
            color: '#ef4444',
          };
          enemy.stateTimer -= dt;
          if (enemy.stateTimer <= 0) {
            enemy.telegraph = null;
            enemy.state = 'idle';
            enemy.cooldownTimer = 2.1;
            const spd = 10.5;
            this.projectiles.push({
              id: this.nextId++,
              owner: 'enemy',
              kind: 'enemy_orb',
              x: enemy.x + Math.cos(enemy.facingAngle) * 0.9,
              z: enemy.z + Math.sin(enemy.facingAngle) * 0.9,
              vx: Math.cos(enemy.facingAngle) * spd,
              vz: Math.sin(enemy.facingAngle) * spd,
              angle: enemy.facingAngle,
              radius: 0.36,
              damage: 18,
              piercing: false,
              weakPointShatter: false,
              hitEntityIds: new Set<number>(),
              life: 0,
              maxLife: 3.0,
            });
          }
        }
      }
    }
  }

  private handleEnemyMeleeHitPlayer(attacker: EnemyEntity, damage: number): void {
    const p = this.player;

    if (p.state === 'parry_active') {
      const angleToAttacker = Math.atan2(attacker.z - p.z, attacker.x - p.x);
      const angleDiff = Math.abs(this.normalizeAngle(angleToAttacker - p.facingAngle));
      if (angleDiff <= COMBAT_CONFIG.player.parry.arc * 0.5 + 0.35) {
        attacker.state = 'staggered';
        attacker.stateDuration = COMBAT_CONFIG.player.parry.meleeStaggerDuration;
        attacker.stateTimer = attacker.stateDuration;
        attacker.telegraph = null;
        attacker.weakPointExposed = false;

        this.audio.playParrySuccess();
        this.hitStopTimer = 0.07;
        this.cameraShake = 0.35;
        this.shockwaves.push({
          id: this.nextId++,
          x: p.x,
          z: p.z,
          maxRadius: 3.2,
          color: '#fbbf24',
          timer: 0,
          duration: 0.3,
        });
        this.addFloatingText(attacker.x, attacker.z, '🛡️ 방패 패링! (적 대경직)', '#fde047', 2.5);
        return;
      }
    }

    if (p.invulnerableTimer > 0) {
      this.addFloatingText(p.x, p.z, '대시 회피!', '#67e8f9', 2.0);
      return;
    }

    this.damagePlayer(damage);
  }

  private damagePlayer(damage: number): void {
    const p = this.player;
    p.hp = Math.max(0, p.hp - damage);
    p.hitFlashTimer = 0.2;
    this.cameraShake = 0.32;
    this.audio.playHit(false);
    this.addFloatingText(p.x, p.z, `-${damage}`, '#f87171', 2.0);

    if (p.hp <= 0) {
      if (p.revivesLeft > 0) {
        p.revivesLeft -= 1;
        p.hp = Math.round(p.maxHp * 0.5);
        p.invulnerableTimer = 1.6;
        this.shockwaves.push({
          id: this.nextId++,
          x: p.x,
          z: p.z,
          maxRadius: 4.8,
          color: '#4ade80',
          timer: 0,
          duration: 0.45,
        });
        this.addFloatingText(p.x, p.z, '🌿 여신의 축복 발동! (HP 50% 부활)', '#4ade80', 2.6);
        this.showBanner('여신의 축복으로 부활했습니다! (항해당 최대 1회)');
      } else {
        this.returnOutcome = 'defeat';
        this.loadScene('scene8_return');
      }
    }
  }

  private updateProjectiles(dt: number): void {
    const p = this.player;
    const hasAthena = p.activeBoons.has('athena');
    const hasApollo = p.activeBoons.has('apollo');
    const hasZeus = p.activeBoons.has('zeus');

    for (let i = this.projectiles.length - 1; i >= 0; i--) {
      const proj = this.projectiles[i];
      proj.life += dt;
      if (proj.life >= proj.maxLife) {
        this.projectiles.splice(i, 1);
        continue;
      }

      proj.x += proj.vx * dt;
      proj.z += proj.vz * dt;

      if (
        Math.abs(proj.x) > COMBAT_CONFIG.arena.halfWidth ||
        Math.abs(proj.z) > COMBAT_CONFIG.arena.halfDepth
      ) {
        this.projectiles.splice(i, 1);
        continue;
      }

      let hitPillar = false;
      for (const pillar of this.pillars) {
        if (Math.hypot(proj.x - pillar.x, proj.z - pillar.z) <= pillar.radius + proj.radius * 0.5) {
          hitPillar = true;
          break;
        }
      }
      if (hitPillar) {
        this.projectiles.splice(i, 1);
        continue;
      }

      if (proj.owner === 'enemy') {
        const distToPlayer = Math.hypot(proj.x - p.x, proj.z - p.z);

        // Q 방패 패링 반사!
        if (
          p.state === 'parry_active' &&
          distToPlayer <= COMBAT_CONFIG.player.parry.range + proj.radius
        ) {
          const angleToProj = Math.atan2(proj.z - p.z, proj.x - p.x);
          const diff = Math.abs(this.normalizeAngle(angleToProj - p.facingAngle));
          if (diff <= COMBAT_CONFIG.player.parry.arc * 0.5 + 0.3) {
            proj.owner = 'player';
            proj.kind = 'parried_orb';
            const newSpeed =
              Math.hypot(proj.vx, proj.vz) * COMBAT_CONFIG.player.parry.reflectSpeedMultiplier;
            proj.angle = p.facingAngle;
            proj.vx = Math.cos(p.facingAngle) * newSpeed;
            proj.vz = Math.sin(p.facingAngle) * newSpeed;
            proj.damage = Math.round(
              COMBAT_CONFIG.player.parry.reflectDamage * (hasAthena ? 1.6 : 1.0)
            );
            proj.life = 0;
            proj.maxLife = 2.2;

            this.audio.playParrySuccess();
            this.hitStopTimer = 0.05;
            this.cameraShake = 0.28;
            this.addFloatingText(p.x, p.z, '🛡️ 투사체 반사!', '#fde047', 2.2);
            continue;
          }
        }

        if (distToPlayer <= p.radius + proj.radius) {
          if (p.invulnerableTimer > 0) {
            this.addFloatingText(p.x, p.z, '대시 회피!', '#67e8f9', 2.0);
          } else {
            this.damagePlayer(proj.damage);
          }
          this.projectiles.splice(i, 1);
          continue;
        }
      } else {
        let shouldRemove = false;

        for (const enemy of this.enemies) {
          if (enemy.hp <= 0 || proj.hitEntityIds.has(enemy.id)) continue;

          const dist = Math.hypot(proj.x - enemy.x, proj.z - enemy.z);
          if (dist <= enemy.radius + proj.radius) {
            proj.hitEntityIds.add(enemy.id);

            const isWeakPointSnipe = proj.weakPointShatter && enemy.weakPointExposed;
            this.applyDamageToEnemy(
              enemy,
              proj.damage,
              Math.cos(proj.angle) * (proj.piercing ? 5.5 : 2.5),
              Math.sin(proj.angle) * (proj.piercing ? 5.5 : 2.5),
              isWeakPointSnipe,
              proj.piercing
            );

            if (hasApollo) {
              this.shockwaves.push({
                id: this.nextId++,
                x: enemy.x,
                z: enemy.z,
                maxRadius: 2.4,
                color: '#fb923c',
                timer: 0,
                duration: 0.26,
              });
            }
            if (proj.piercing && hasZeus) {
              this.triggerZeusChainLightning(enemy);
            }

            if (!proj.piercing) {
              shouldRemove = true;
              break;
            }
          }
        }

        if (shouldRemove) {
          this.projectiles.splice(i, 1);
        }
      }
    }
  }

  private applyDamageToEnemy(
    enemy: EnemyEntity,
    rawDamage: number,
    kbX: number,
    kbZ: number,
    isWeakPointSnipe: boolean,
    isPiercingArrow = false
  ): void {
    // Scene 6 & 7: 고대 청동 종(Resonance Bell) 타격 시 황금색 공명이 푸른 음파를 가르고 적 대경직!
    if (enemy.kind === 'resonance_bell') {
      enemy.hitFlashTimer = 0.3;
      this.audio.playBellResonance();
      this.cameraShake = 0.38;
      this.shockwaves.push({
        id: this.nextId++,
        x: enemy.x,
        z: enemy.z,
        maxRadius: 14.5,
        color: '#fbbf24',
        timer: 0,
        duration: 0.65,
        style: 'bell_gold',
      });
      this.addFloatingText(enemy.x, enemy.z, '🔔 황금 종의 공명 파동!', '#fde047', 2.8);

      for (const target of this.enemies) {
        if (target.hp <= 0 || target.kind === 'resonance_bell') continue;
        if (target.kind === 'boss_parthenope' || target.kind === 'siren_harpy') {
          target.shielded = false;
          target.state = 'staggered';
          target.stateDuration = 4.2;
          target.stateTimer = 4.2;
          target.telegraph = null;
          target.hp = Math.max(1, target.hp - 45);
          this.addFloatingText(
            target.x,
            target.z,
            '💥 황금 공명이 푸른 음파를 가름! (보호막 파괴 & 대경직)',
            '#fde047',
            3.1
          );
        }
      }
      return;
    }

    let finalDamage = rawDamage;

    // Scene 4: 폴리페모스 금빛 외눈 약점 저격 판정!
    if (isWeakPointSnipe) {
      finalDamage = Math.round(rawDamage * COMBAT_CONFIG.player.bow.weakPointMultiplier);
      enemy.weakPointExposed = false;
      enemy.shielded = false;
      enemy.state = 'staggered';
      enemy.stateDuration = 4.2;
      enemy.stateTimer = 4.2;
      enemy.telegraph = null;

      this.audio.playParrySuccess();
      this.hitStopTimer = 0.09;
      this.cameraShake = 0.48;
      this.shockwaves.push({
        id: this.nextId++,
        x: enemy.x,
        z: enemy.z,
        maxRadius: 4.5,
        color: '#fde047',
        timer: 0,
        duration: 0.4,
      });
      this.addFloatingText(
        enemy.x,
        enemy.z,
        `🎯 단 하나의 눈 저격! -${finalDamage} (대경직)`,
        '#fde047',
        3.2
      );
    } else if (enemy.shielded) {
      finalDamage = Math.max(2, Math.round(rawDamage * 0.35));
      const hint =
        enemy.kind === 'boss_parthenope' || enemy.kind === 'siren_harpy'
          ? '음파 장막! (청동 종 타격)'
          : '거인의 피부! (금빛 외눈 풀차징 저격)';
      this.addFloatingText(enemy.x, enemy.z, `-${finalDamage} (${hint})`, '#94a3b8', 2.2);
    } else {
      const label = isPiercingArrow ? `⚡관통 -${finalDamage}` : `-${finalDamage}`;
      const color = isPiercingArrow ? '#7dd3fc' : '#ffffff';
      this.addFloatingText(enemy.x, enemy.z, label, color, 2.0);
    }

    enemy.hp = Math.max(0, enemy.hp - finalDamage);
    enemy.hitFlashTimer = 0.14;
    if (!enemy.isBoss) {
      enemy.vx += kbX;
      enemy.vz += kbZ;
    }
    this.audio.playHit(isWeakPointSnipe || isPiercingArrow);

    if (enemy.hp <= 0) {
      const coinReward = enemy.isBoss ? 80 : 20;
      this.player.bronzeCoins += coinReward;
      this.player.voyageCoinsEarned += coinReward;
      this.player.killsAndBreaks += 1;
      this.addFloatingText(
        enemy.x,
        enemy.z,
        `처치! (+${coinReward} 청동 주화)`,
        '#4ade80',
        2.5
      );

      if (this.currentScene === 'training_grounds') {
        setTimeout(() => {
          enemy.hp = enemy.maxHp;
          enemy.x = enemy.homeX;
          enemy.z = enemy.homeZ;
          enemy.state = 'idle';
          enemy.telegraph = null;
          enemy.weakPointExposed = false;
        }, 2800);
      } else {
        this.checkStageClearProgression();
      }
    }
  }

  private checkStageClearProgression(): void {
    const remainingCombatEnemies = this.enemies.filter(
      (e) => e.hp > 0 && e.kind !== 'resonance_bell' && e.kind !== 'pierce_dummy'
    );
    if (remainingCombatEnemies.length > 0) return;

    if (this.currentScene === 'scene3_cyclops_cave') {
      setTimeout(() => {
        this.openBoonSelection('scene4_polyphemus_boss');
      }, 900);
    } else if (this.currentScene === 'scene4_polyphemus_boss') {
      setTimeout(() => {
        this.openBoonSelection('scene6_siren_reef');
      }, 1100);
    } else if (this.currentScene === 'scene6_siren_reef') {
      setTimeout(() => {
        this.openBoonSelection('scene7_parthenope_boss');
      }, 900);
    } else if (this.currentScene === 'scene7_parthenope_boss') {
      setTimeout(() => {
        this.returnOutcome = 'victory';
        this.loadScene('scene8_return');
      }, 1200);
    }
  }

  private movePlayerWithCollision(dt: number): void {
    const p = this.player;
    p.x += p.vx * dt;
    p.z += p.vz * dt;

    for (const pillar of this.pillars) {
      const dx = p.x - pillar.x;
      const dz = p.z - pillar.z;
      const dist = Math.hypot(dx, dz);
      const minDist = p.radius + pillar.radius;
      if (dist < minDist && dist > 0.0001) {
        p.x = pillar.x + (dx / dist) * minDist;
        p.z = pillar.z + (dz / dist) * minDist;
      }
    }

    this.clampToArena(p);
  }

  private clampToArena(entity: { x: number; z: number; radius: number }): void {
    const halfW = this.currentScene === 'scene2_hub' ? 11.5 : COMBAT_CONFIG.arena.halfWidth;
    const halfD = this.currentScene === 'scene2_hub' ? 7.5 : COMBAT_CONFIG.arena.halfDepth;
    const maxX = halfW - entity.radius;
    const maxZ = halfD - entity.radius;
    entity.x = Math.max(-maxX, Math.min(maxX, entity.x));
    entity.z = Math.max(-maxZ, Math.min(maxZ, entity.z));
  }

  private updateVisualTimers(dt: number): void {
    for (let i = this.swings.length - 1; i >= 0; i--) {
      this.swings[i].timer += dt;
      if (this.swings[i].timer >= this.swings[i].maxTimer) this.swings.splice(i, 1);
    }
    for (let i = this.shockwaves.length - 1; i >= 0; i--) {
      this.shockwaves[i].timer += dt;
      if (this.shockwaves[i].timer >= this.shockwaves[i].duration) this.shockwaves.splice(i, 1);
    }
    for (let i = this.lightningArcs.length - 1; i >= 0; i--) {
      this.lightningArcs[i].timer += dt;
      if (this.lightningArcs[i].timer >= this.lightningArcs[i].duration)
        this.lightningArcs.splice(i, 1);
    }
  }

  private normalizeAngle(angle: number): number {
    while (angle > Math.PI) angle -= Math.PI * 2;
    while (angle < -Math.PI) angle += Math.PI * 2;
    return angle;
  }
}
