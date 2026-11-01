import { BoonDefinition, GodId } from '../types/combat';

export const OLYMPIAN_BOONS: Record<GodId, BoonDefinition> = {
  athena: {
    id: 'boon_athena_aegis',
    god: 'athena',
    godNameKo: '아테나 (Athena)',
    titleKo: '아이기스의 지혜와 방패',
    emblemDescKo: '상아색과 금색 · 올빼미와 방패 문양 · 겹겹의 보호막',
    effectDescKo:
      '방패 패링(Q) 및 회피 대시(Space) 시 황금 보호막 충격파를 일으키고, 반사 피해량이 +60% 증가합니다. (E: 아이기스 성역 방출)',
    primaryColor: '#f59e0b',
    secondaryColor: '#fef3c7',
    glowColor: '#fbbf24',
  },
  zeus: {
    id: 'boon_zeus_thunder',
    god: 'zeus',
    godNameKo: '제우스 (Zeus)',
    titleKo: '올림포스의 천둥 벼락',
    emblemDescKo: '짙은 청색과 백색 · 독수리와 번개 문양 · 갈라지는 전류',
    effectDescKo:
      '청동 검 3타 및 강궁 풀차징 적중 시 주변 적들에게 연쇄 번개(Chain Lightning)가 내리칩니다. (E: 천둥 낙뢰 소환)',
    primaryColor: '#2563eb',
    secondaryColor: '#e0f2fe',
    glowColor: '#60a5fa',
  },
  apollo: {
    id: 'boon_apollo_sunbow',
    god: 'apollo',
    godNameKo: '아폴론 (Apollo)',
    titleKo: '태양과 월계관의 광륜',
    emblemDescKo: '주황색과 태양빛 · 월계관과 활 문양 · 불꽃 같은 광륜',
    effectDescKo:
      '강궁 차징 시간이 35% 단축되고, 발사된 화살이 적중 시 태양 화염 폭발을 일으킵니다. (E: 태양의 화살 세례)',
    primaryColor: '#ea580c',
    secondaryColor: '#fef08a',
    glowColor: '#fb923c',
  },
  hermes: {
    id: 'boon_hermes_swift',
    god: 'hermes',
    godNameKo: '헤르메스 (Hermes)',
    titleKo: '날개 달린 샌들의 질풍',
    emblemDescKo: '민트색과 은색 · 날개 달린 샌들과 바람 문양 · 흐르는 잔상',
    effectDescKo:
      '이동 속도가 +25% 증가하고 대시 쿨타임이 35% 감소하며, 대시 직후 치명타 피해가 강화됩니다. (E: 질풍 충격파)',
    primaryColor: '#14b8a6',
    secondaryColor: '#f1f5f9',
    glowColor: '#2dd4bf',
  },
};

export const COMBAT_CONFIG = {
  arena: {
    halfWidth: 21,
    halfDepth: 15,
  },
  player: {
    baseMaxHp: 120,
    maxRevivesPerVoyage: 1,
    moveSpeed: 7.8,
    // 속도가 목표 속도로 따라붙는 빠르기 (클수록 즉각적, 하데스처럼 0.15초 안에 거의 다 붙음)
    acceleration: 20,
    deceleration: 16,
    bowChargeMoveMultiplier: 0.44,
    radius: 0.55,

    dash: {
      speed: 21.5,
      duration: 0.19,
      iframeDuration: 0.22,
      cooldown: 0.52,
    },

    spear: {
      comboWindow: 0.95,
      // 공격 중·대시 중 미리 누른 클릭을 기억하는 시간
      inputBuffer: 0.4,
      // 회복 동작 중 이 비율이 지나면 다음 타로 이어지거나 이동으로 끊을 수 있음
      comboCancelAt: 0.3,
      moveCancelAt: 0.5,
      // stepForward: 휘두르는 동안 앞으로 내딛는 거리(유닛), 앞에 적이 붙어 있으면 줄어듦
      steps: {
        1: {
          name: '1타: 횡베기',
          windup: 0.09,
          active: 0.1,
          recovery: 0.2,
          damage: 26,
          range: 2.9,
          arc: (118 * Math.PI) / 180,
          knockback: 3.5,
          stepForward: 0.45,
          hitStop: 0.05,
          shake: 0,
        },
        2: {
          name: '2타: 직선 찌르기',
          windup: 0.1,
          active: 0.09,
          recovery: 0.22,
          damage: 34,
          length: 3.8,
          width: 1.15,
          knockback: 4.5,
          stepForward: 0.8,
          hitStop: 0.05,
          shake: 0,
        },
        3: {
          name: '3타: 돌진 회전베기',
          windup: 0.18,
          active: 0.16,
          recovery: 0.32,
          damage: 52,
          range: 3.4,
          arc: (165 * Math.PI) / 180,
          knockback: 8.5,
          stepForward: 1.4,
          hitStop: 0.1,
          shake: 0.3,
        },
      },
    },

    bow: {
      fullChargeTime: 0.58,
      minChargeToFire: 0.1,
      postFireRecovery: 0.2,
      normalSpeed: 20.0,
      pierceSpeed: 31.0,
      normalDamage: 25,
      pierceDamage: 62,
      weakPointMultiplier: 2.6,
    },

    parry: {
      activeDuration: 0.28,
      recoveryDuration: 0.14,
      cooldown: 0.78,
      arc: (145 * Math.PI) / 180,
      range: 2.4,
      reflectSpeedMultiplier: 1.9,
      reflectDamage: 75,
      meleeStaggerDuration: 3.0,
    },

    boonSlotE: {
      cooldown: 4.0,
    },
  },
} as const;
