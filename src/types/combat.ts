export interface Vec2 {
  x: number;
  z: number;
}

export type SceneId =
  | 'scene1_title'          // 1. 메인 키아트 — “고향은 아직 수평선 너머에”
  | 'scene2_hub'            // 2. 전함 허브 — “폭풍 사이의 안식”
  | 'scene3_cyclops_cave'   // 3. 키클롭스의 동굴 — “눈을 뜨는 어둠”
  | 'scene4_polyphemus_boss'// 4. 폴리페모스 보스전 — “단 하나의 눈”
  | 'scene6_siren_reef'     // 6. 세이렌의 암초 — “아름다운 목소리, 위험한 바다”
  | 'scene7_parthenope_boss'// 7. 파르테노페 보스전 — “노래를 끊는 종소리”
  | 'scene8_return'         // 8. 귀환 — “아직 끝나지 않은 항해”
  | 'training_grounds';     // M1+M2 자유 전술 훈련장

export type GodId = 'athena' | 'zeus' | 'apollo' | 'hermes';

export interface BoonDefinition {
  id: string;
  god: GodId;
  godNameKo: string;
  titleKo: string;
  emblemDescKo: string;
  effectDescKo: string;
  primaryColor: string;
  secondaryColor: string;
  glowColor: string;
}

export type PlayerActionState =
  | 'idle'
  | 'move'
  | 'dash'
  | 'spear_windup'
  | 'spear_swing'
  | 'spear_recovery'
  | 'bow_charge'
  | 'bow_recovery'
  | 'parry_active'
  | 'parry_recovery';

export type EnemyKind =
  | 'lotus_cultist'
  | 'boulder_cyclops'
  | 'boss_polyphemus'
  | 'siren_harpy'
  | 'drowned_hoplite'
  | 'boss_parthenope'
  | 'resonance_bell'
  | 'pierce_dummy'
  | 'projectile_statue';

export type EnemyState =
  | 'idle'
  | 'chase'
  | 'windup'      // 바닥 예고 표시 + 본체 준비 동작
  | 'attack'      // 실제 타격 판정 또는 지속 채널링(세이렌의 노래)
  | 'weak_open'   // 금빛 외눈 약점 노출 상태 (강궁 풀차징 저격 가능)
  | 'staggered';  // 패링 성공, 약점 저격, 또는 청동 종 공명 파훼로 인한 대경직

export type TelegraphShape =
  | {
      type: 'circle';
      x: number;
      z: number;
      radius: number;
      progress: number; // 0.0 -> 1.0
      color: string;
      style?: 'boulder_orange' | 'spore_purple' | 'siren_pull' | 'slam_dust';
    }
  | {
      type: 'sector';
      x: number;
      z: number;
      radius: number;
      angle: number;
      arc: number; // radians
      progress: number;
      color: string;
    }
  | {
      type: 'line';
      x: number;
      z: number;
      angle: number;
      length: number;
      width: number;
      progress: number;
      color: string;
    };

export interface ActiveSwingVisual {
  id: number;
  x: number;
  z: number;
  angle: number;
  comboStep: 1 | 2 | 3 | 'parry';
  radius: number;
  arc: number;
  length: number;
  width: number;
  timer: number;
  maxTimer: number;
  colorOverride?: string;
}

export interface ProjectileEntity {
  id: number;
  owner: 'player' | 'enemy';
  kind:
    | 'arrow_normal'
    | 'arrow_pierce'
    | 'boulder_lob'
    | 'siren_sonic_orb'
    | 'enemy_orb'
    | 'parried_orb';
  x: number;
  z: number;
  targetX?: number;
  targetZ?: number;
  vx: number;
  vz: number;
  angle: number;
  radius: number;
  damage: number;
  piercing: boolean;
  weakPointShatter: boolean;
  hitEntityIds: Set<number>;
  life: number;
  maxLife: number;
}

export interface EnemyEntity {
  id: number;
  kind: EnemyKind;
  isBoss: boolean;
  name: string;
  subtitle: string;
  x: number;
  z: number;
  homeX: number;
  homeZ: number;
  vx: number;
  vz: number;
  radius: number;
  visualScale: number;
  facingAngle: number;
  hp: number;
  maxHp: number;
  state: EnemyState;
  stateTimer: number;
  stateDuration: number;
  cooldownTimer: number;
  attackPatternIndex: number;
  weakPointExposed: boolean;
  shielded: boolean;
  linkedBellId?: number;
  hitFlashTimer: number;
  telegraph: TelegraphShape | null;
}

export interface HubInteractable {
  id: string;
  kind: 'sea_chart' | 'brazier' | 'shrine';
  god?: GodId;
  title: string;
  subtitle: string;
  x: number;
  z: number;
  radius: number;
  color: string;
}

export interface MetaUpgrades {
  maxHpLevel: number;       // 단계당 최대 체력 +25
  attackLevel: number;      // 단계당 기본 공격력 +15%
  reviveUnlocked: boolean;  // 항해당 최대 1회 부활 해금
}

export interface PlayerEntity {
  x: number;
  z: number;
  vx: number;
  vz: number;
  radius: number;
  facingAngle: number;
  moveAngle: number;
  hp: number;
  maxHp: number;
  revivesLeft: number;
  bronzeCoins: number;
  voyageCoinsEarned: number;
  killsAndBreaks: number;

  state: PlayerActionState;
  stateTimer: number;

  dashCooldown: number;
  dashDirX: number;
  dashDirZ: number;
  invulnerableTimer: number;

  comboStep: 1 | 2 | 3;
  comboResetTimer: number;
  hasDealtSwingDamage: boolean;

  bowCharge: number; // 0.0 ~ 1.0
  isFullCharged: boolean;

  parryCooldown: number;
  boonCooldown: number;
  hitFlashTimer: number;

  activeBoons: Set<GodId>;
}

export interface FloatingTextEvent {
  x: number;
  y: number;
  z: number;
  text: string;
  color: string;
}

export interface ShockwaveVisual {
  id: number;
  x: number;
  z: number;
  maxRadius: number;
  color: string;
  timer: number;
  duration: number;
  style?: 'normal' | 'dust_fan' | 'siren_ring' | 'bell_gold' | 'zeus_lightning';
  angle?: number;
}

export interface LightningArcVisual {
  id: number;
  x1: number;
  z1: number;
  x2: number;
  z2: number;
  timer: number;
  duration: number;
}

export interface PerformanceMetrics {
  fps: number;
  frameTimeMs: number;
  minFps: number;
}
