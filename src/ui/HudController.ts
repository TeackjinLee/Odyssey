import * as THREE from 'three';
import { COMBAT_CONFIG, OLYMPIAN_BOONS } from '../data/combatConfig';
import { WorldSimulation } from '../combat/WorldSimulation';
import { SceneRenderer25D } from '../rendering/SceneRenderer25D';
import { KeyArtRenderer } from '../rendering/KeyArtRenderer';
import { PerformanceMetrics, SceneId } from '../types/combat';

interface ActiveFloatingDom {
  el: HTMLDivElement;
  worldX: number;
  worldY: number;
  worldZ: number;
  life: number;
  maxLife: number;
}

export class HudController {
  private keyArtCanvas = document.getElementById('keyart-canvas') as HTMLCanvasElement;
  private titleOverlay = document.getElementById('title-overlay') as HTMLDivElement;
  private returnOverlay = document.getElementById('return-overlay') as HTMLDivElement;
  private boonModal = document.getElementById('boon-modal') as HTMLDivElement;
  private boonCardsContainer = document.getElementById('boon-cards-container') as HTMLDivElement;
  private hubPrompt = document.getElementById('hub-prompt') as HTMLDivElement;
  private hubPromptTitle = document.getElementById('hub-prompt-title') as HTMLDivElement;
  private hubPromptSub = document.getElementById('hub-prompt-sub') as HTMLDivElement;
  private hubPromptButtons = document.getElementById('hub-prompt-buttons') as HTMLDivElement;

  private hudContainer = document.getElementById('hud') as HTMLDivElement;
  private hudSceneLabel = document.getElementById('hud-scene-label') as HTMLSpanElement;
  private hpBarInner = document.getElementById('hp-bar-inner') as HTMLDivElement;
  private hpBarText = document.getElementById('hp-bar-text') as HTMLDivElement;
  private reviveBadge = document.getElementById('revive-badge') as HTMLSpanElement;

  private slotSpear = document.getElementById('slot-spear') as HTMLDivElement;
  private spearComboText = document.getElementById('spear-combo-text') as HTMLSpanElement;
  private slotBow = document.getElementById('slot-bow') as HTMLDivElement;
  private bowChargeText = document.getElementById('bow-charge-text') as HTMLSpanElement;
  private slotDash = document.getElementById('slot-dash') as HTMLDivElement;
  private dashCdText = document.getElementById('dash-cd-text') as HTMLSpanElement;
  private slotParry = document.getElementById('slot-parry') as HTMLDivElement;
  private parryCdText = document.getElementById('parry-cd-text') as HTMLSpanElement;
  private slotBoon = document.getElementById('slot-boon') as HTMLDivElement;
  private boonCdText = document.getElementById('boon-cd-text') as HTMLSpanElement;
  private boonBadgesRow = document.getElementById('boon-badges-row') as HTMLDivElement;

  private bossBarWrap = document.getElementById('boss-bar-wrap') as HTMLDivElement;
  private bossName = document.getElementById('boss-name') as HTMLDivElement;
  private bossSubtitle = document.getElementById('boss-subtitle') as HTMLDivElement;
  private bossHpInner = document.getElementById('boss-hp-inner') as HTMLDivElement;

  private fpsMain = document.getElementById('fps-main') as HTMLDivElement;
  private fpsSub = document.getElementById('fps-sub') as HTMLDivElement;
  private coinSub = document.getElementById('coin-sub') as HTMLDivElement;

  private statusBanner = document.getElementById('status-banner') as HTMLDivElement;
  private floatingLayer = document.getElementById('floating-layer') as HTMLDivElement;

  private returnTitle = document.getElementById('return-title') as HTMLHeadingElement;
  private returnCoinsText = document.getElementById('return-coins-text') as HTMLDivElement;
  private upgHpDesc = document.getElementById('upg-hp-desc') as HTMLDivElement;
  private upgAtkDesc = document.getElementById('upg-atk-desc') as HTMLDivElement;

  private keyArtRenderer = new KeyArtRenderer();
  private activeFloatingDoms: ActiveFloatingDom[] = [];
  private enemyLabels = new Map<number, HTMLDivElement>();
  private lastBoonModalState = false;
  private lastHubItemId: string | null = null;

  constructor(world: WorldSimulation, renderer: SceneRenderer25D) {
    // 상단 8대 시나리오 탭 버튼 이벤트 연결
    const tabs = document.querySelectorAll<HTMLButtonElement>('.scene-tab');
    tabs.forEach((tab) => {
      tab.addEventListener('click', () => {
        const target = tab.dataset.scene;
        if (!target) return;
        if (target === 'scene5_boon_trigger') {
          world.openBoonSelection(world.currentScene === 'scene1_title' ? 'scene3_cyclops_cave' : world.currentScene);
        } else {
          world.loadScene(target as SceneId);
        }
      });
    });

    // Scene 1 타이틀 버튼
    document.getElementById('btn-start-hub')?.addEventListener('click', () => {
      world.loadScene('scene2_hub');
    });
    document.getElementById('btn-start-stage1')?.addEventListener('click', () => {
      world.loadScene('scene3_cyclops_cave');
    });
    document.getElementById('btn-start-training')?.addEventListener('click', () => {
      world.loadScene('training_grounds');
    });

    // 하단 리셋 & 신의 가호 열기 버튼
    document.getElementById('btn-respawn-enemies')?.addEventListener('click', () => {
      world.loadScene(world.currentScene);
    });
    document.getElementById('btn-open-boon')?.addEventListener('click', () => {
      world.openBoonSelection(world.currentScene);
    });

    // 브라우저 창에 보스 이미지 파일(이름에 poly / siren·parthenope)을 드래그 앤 드롭하면 배경 제거 후 적용
    window.addEventListener('dragover', (e) => {
      e.preventDefault();
    });
    window.addEventListener('drop', (e) => {
      e.preventDefault();
      const file = e.dataTransfer?.files?.[0];
      if (!file || !file.type.startsWith('image/')) return;
      const lower = file.name.toLowerCase();
      const target = lower.includes('poly')
        ? 'boss_polyphemus'
        : lower.includes('siren') || lower.includes('parthenope')
          ? 'boss_parthenope'
          : null;
      if (!target) {
        world.showBanner('보스 이미지만 바꿀 수 있습니다 (파일 이름에 poly 또는 parthenope)');
        return;
      }
      renderer.sprites.applyUserUploadedImage(file, target, () => {
        world.showBanner(`✅ [${file.name}] 보스 스프라이트 적용 완료! (외곽 흰색 배경 자동 제거됨)`);
      });
    });

    // Scene 8 메타 업그레이드 버튼 (청동 주화로 최대 체력, 기본 공격력 강화)
    document.getElementById('btn-upg-hp')?.addEventListener('click', () => {
      if (world.player.bronzeCoins >= 20) {
        world.player.bronzeCoins -= 20;
        world.meta.maxHpLevel += 1;
        world.recalculatePlayerMetaStats(true);
      }
    });
    document.getElementById('btn-upg-atk')?.addEventListener('click', () => {
      if (world.player.bronzeCoins >= 25) {
        world.player.bronzeCoins -= 25;
        world.meta.attackLevel += 1;
      }
    });
    document.getElementById('btn-return-hub')?.addEventListener('click', () => {
      world.loadScene('scene2_hub');
    });
    document.getElementById('btn-return-stage1')?.addEventListener('click', () => {
      world.recalculatePlayerMetaStats(true);
      world.loadScene('scene3_cyclops_cave');
    });

    // 초기 가호 카드 렌더링 준비
    void renderer;
  }

  public update(
    world: WorldSimulation,
    renderer: SceneRenderer25D,
    perf: PerformanceMetrics,
    dt: number
  ): void {
    const p = world.player;

    // 상단 탭 활성 표시 동기화
    const tabs = document.querySelectorAll<HTMLButtonElement>('.scene-tab');
    tabs.forEach((tab) => {
      const s = tab.dataset.scene;
      const isAct =
        (world.boonSelectionOpen && s === 'scene5_boon_trigger') ||
        (!world.boonSelectionOpen && s === world.currentScene);
      tab.classList.toggle('active', isAct);
    });

    // 1. Scene 1 (메인 키아트) & Scene 8 (귀환) 시네마틱 캔버스 처리
    if (world.currentScene === 'scene1_title') {
      this.keyArtCanvas.style.display = 'block';
      this.titleOverlay.style.display = 'flex';
      this.returnOverlay.style.display = 'none';
      this.hudContainer.style.display = 'none';
      this.keyArtRenderer.renderScene1Title(this.keyArtCanvas, world.elapsedTime);
      this.clearEnemyLabels();
      return;
    }

    if (world.currentScene === 'scene8_return') {
      this.keyArtCanvas.style.display = 'block';
      this.titleOverlay.style.display = 'none';
      this.returnOverlay.style.display = 'flex';
      this.hudContainer.style.display = 'none';
      this.keyArtRenderer.renderScene8Return(this.keyArtCanvas, world.elapsedTime);

      this.returnTitle.textContent =
        world.returnOutcome === 'victory'
          ? '승리의 귀환 — “이타카를 향한 전진”'
          : '귀환 — “아직 끝나지 않은 항해”';
      this.returnCoinsText.textContent = `보유 청동 주화: ${p.bronzeCoins} 🪙 (이번 항해 획득: +${p.voyageCoinsEarned})`;
      this.upgHpDesc.textContent = `현재 단계: Lv.${world.meta.maxHpLevel} (최대 HP ${COMBAT_CONFIG.player.baseMaxHp + world.meta.maxHpLevel * 25})`;
      this.upgAtkDesc.textContent = `현재 단계: Lv.${world.meta.attackLevel} (공격력 +${world.meta.attackLevel * 15}%)`;
      this.clearEnemyLabels();
      return;
    }

    this.keyArtCanvas.style.display = 'none';
    this.titleOverlay.style.display = 'none';
    this.returnOverlay.style.display = 'none';
    this.hudContainer.style.display = 'flex';

    // 2. Scene 5: 신의 가호 — “올림포스의 선택” 모달 표시
    if (world.boonSelectionOpen !== this.lastBoonModalState) {
      this.lastBoonModalState = world.boonSelectionOpen;
      if (world.boonSelectionOpen) {
        this.renderBoonCards(world, renderer);
        this.boonModal.style.display = 'flex';
      } else {
        this.boonModal.style.display = 'none';
      }
    }

    // 3. Scene 2: 전함 허브 인터랙션 프롬프트
    if (world.currentScene === 'scene2_hub' && world.nearbyHubItem) {
      this.hubPrompt.style.display = 'block';
      if (this.lastHubItemId !== world.nearbyHubItem.id) {
        this.lastHubItemId = world.nearbyHubItem.id;
        const item = world.nearbyHubItem;
        this.hubPromptTitle.textContent = item.title;
        this.hubPromptSub.textContent = item.subtitle;
        this.hubPromptButtons.innerHTML = '';

        if (item.kind === 'sea_chart') {
          this.addHubButton('👁️ Stage 1: 키클롭스의 동굴 출항', () =>
            world.loadScene('scene3_cyclops_cave')
          );
          this.addHubButton('🎵 Stage 2: 세이렌의 암초 출항', () =>
            world.loadScene('scene6_siren_reef')
          );
          this.addHubButton('⚔️ 전술 훈련장 입장', () =>
            world.loadScene('training_grounds')
          );
        } else if (item.kind === 'brazier') {
          this.addHubButton('🪙 영구 정비 및 강화 화면 열기 (Scene 8)', () =>
            world.loadScene('scene8_return')
          );
        } else if (item.kind === 'shrine' && item.god) {
          const god = item.god;
          this.addHubButton(`✨ ${OLYMPIAN_BOONS[god].titleKo} 축복 받기`, () =>
            world.selectBoon(god)
          );
        }
      }
    } else {
      this.hubPrompt.style.display = 'none';
      this.lastHubItemId = null;
    }

    // 4. 상단 플레이어 상태 및 가호 뱃지 갱신
    const sceneTitleMap: Record<SceneId, string> = {
      scene1_title: 'SCENE 1 // 메인 키아트',
      scene2_hub: 'SCENE 2 // 전함 허브 — 폭풍 사이의 안식',
      scene3_cyclops_cave: 'SCENE 3 // 키클롭스의 동굴 — 눈을 뜨는 어둠',
      scene4_polyphemus_boss: 'SCENE 4 // 폴리페모스 보스전 — 단 하나의 눈',
      scene6_siren_reef: 'SCENE 6 // 세이렌의 암초 — 아름다운 목소리',
      scene7_parthenope_boss: 'SCENE 7 // 파르테노페 보스전 — 노래를 끊는 종소리',
      scene8_return: 'SCENE 8 // 귀환',
      training_grounds: 'M1+M2 // 전술 훈련장',
    };
    this.hudSceneLabel.textContent = sceneTitleMap[world.currentScene];

    const hpPercent = Math.max(0, Math.min(100, (p.hp / p.maxHp) * 100));
    this.hpBarInner.style.width = `${hpPercent}%`;
    this.hpBarText.textContent = `HP ${p.hp} / ${p.maxHp}`;

    if (p.revivesLeft > 0) {
      this.reviveBadge.textContent = `여신의 축복(부활): ${p.revivesLeft} / 1`;
      this.reviveBadge.className = 'revive-badge';
    } else {
      this.reviveBadge.textContent = '여신의 축복: 소모됨 (0 / 1)';
      this.reviveBadge.className = 'revive-badge used';
    }

    this.spearComboText.textContent = COMBAT_CONFIG.player.spear.steps[p.comboStep].name;
    this.slotSpear.className =
      p.state === 'spear_windup' || p.state === 'spear_swing' ? 'slot active' : 'slot ready';

    if (p.state === 'bow_charge') {
      const pct = Math.round(p.bowCharge * 100);
      this.bowChargeText.textContent = p.isFullCharged ? '100% 관통·저격!' : `차징 ${pct}%`;
      this.slotBow.className = 'slot active';
    } else {
      this.bowChargeText.textContent = '무제한 화살';
      this.slotBow.className = 'slot ready';
    }

    this.dashCdText.textContent = p.dashCooldown > 0 ? `${p.dashCooldown.toFixed(1)}s` : 'READY';
    this.slotDash.className =
      p.state === 'dash' ? 'slot active' : p.dashCooldown <= 0 ? 'slot ready' : 'slot';

    this.parryCdText.textContent = p.parryCooldown > 0 ? `${p.parryCooldown.toFixed(1)}s` : 'READY';
    this.slotParry.className =
      p.state === 'parry_active' ? 'slot active' : p.parryCooldown <= 0 ? 'slot ready' : 'slot';

    this.boonCdText.textContent = p.boonCooldown > 0 ? `${p.boonCooldown.toFixed(1)}s` : 'READY';
    this.slotBoon.className = p.boonCooldown <= 0 ? 'slot ready' : 'slot';

    // 획득한 올림포스 가호 배지
    this.boonBadgesRow.innerHTML = '';
    for (const g of p.activeBoons) {
      const span = document.createElement('span');
      span.className = 'boon-pill';
      span.textContent = `✦ ${OLYMPIAN_BOONS[g].godNameKo}`;
      this.boonBadgesRow.appendChild(span);
    }

    // 5. 보스 체력바 (Scene 4 폴리페모스 & Scene 7 파르테노페)
    const activeBoss = world.enemies.find((e) => e.isBoss && e.hp > 0);
    if (activeBoss) {
      this.bossBarWrap.style.display = 'flex';
      this.bossName.textContent = activeBoss.name;
      this.bossSubtitle.textContent = activeBoss.subtitle;
      this.bossHpInner.style.width = `${Math.max(0, (activeBoss.hp / activeBoss.maxHp) * 100)}%`;
    } else {
      this.bossBarWrap.style.display = 'none';
    }

    // 6. 실시간 측정 60FPS 모니터
    this.fpsMain.textContent = `${perf.fps} FPS (목표: 60 FPS)`;
    this.fpsMain.style.color = perf.fps >= 55 ? '#4ade80' : perf.fps >= 40 ? '#facc15' : '#f87171';
    this.fpsSub.textContent = `실측 프레임 타임: ${perf.frameTimeMs.toFixed(2)} ms | 최저: ${perf.minFps} FPS`;
    this.coinSub.textContent = `청동 주화: ${p.bronzeCoins} 🪙 | 처치·파훼: ${p.killsAndBreaks}`;

    // 7. 상단 배너
    if (world.bannerMessage) {
      this.statusBanner.textContent = world.bannerMessage.text;
      this.statusBanner.classList.add('visible');
    } else {
      this.statusBanner.classList.remove('visible');
    }

    // 8. 플로팅 전투 텍스트
    while (world.floatingTexts.length > 0) {
      const ev = world.floatingTexts.shift()!;
      const el = document.createElement('div');
      el.className = 'floating-text';
      el.textContent = ev.text;
      el.style.color = ev.color;
      this.floatingLayer.appendChild(el);
      this.activeFloatingDoms.push({
        el,
        worldX: ev.x,
        worldY: ev.y,
        worldZ: ev.z,
        life: 0,
        maxLife: 1.05,
      });
    }

    for (let i = this.activeFloatingDoms.length - 1; i >= 0; i--) {
      const item = this.activeFloatingDoms[i];
      item.life += dt;
      item.worldY += dt * 1.25;
      if (item.life >= item.maxLife) {
        item.el.remove();
        this.activeFloatingDoms.splice(i, 1);
        continue;
      }
      const pos = renderer.projectToScreen(
        new THREE.Vector3(item.worldX, item.worldY, item.worldZ)
      );
      item.el.style.left = `${pos.x}px`;
      item.el.style.top = `${pos.y}px`;
      item.el.style.opacity = `${1 - item.life / item.maxLife}`;
    }

    this.syncEnemyOverheadLabels(world, renderer);
  }

  private addHubButton(label: string, onClick: () => void): void {
    const btn = document.createElement('button');
    btn.className = 'hud-btn';
    btn.textContent = label;
    btn.addEventListener('click', onClick);
    this.hubPromptButtons.appendChild(btn);
  }

  private renderBoonCards(world: WorldSimulation, renderer: SceneRenderer25D): void {
    this.boonCardsContainer.innerHTML = '';
    for (const boon of world.boonChoices) {
      const card = document.createElement('div');
      card.className = 'boon-card';
      card.style.borderColor = boon.primaryColor;

      const emblemUrl = renderer.sprites.drawGodEmblemDataUrl(boon.god);
      card.innerHTML = `
        <img class="boon-emblem-img" src="${emblemUrl}" alt="${boon.godNameKo}" />
        <div class="boon-god-name">${boon.godNameKo}</div>
        <div class="boon-title">${boon.titleKo}</div>
        <div class="boon-emblem-desc">${boon.emblemDescKo}</div>
        <div class="boon-effect-desc">${boon.effectDescKo}</div>
      `;
      card.addEventListener('click', () => {
        world.selectBoon(boon.god);
      });
      this.boonCardsContainer.appendChild(card);
    }
  }

  private clearEnemyLabels(): void {
    for (const [, el] of this.enemyLabels.entries()) {
      el.remove();
    }
    this.enemyLabels.clear();
  }

  private syncEnemyOverheadLabels(world: WorldSimulation, renderer: SceneRenderer25D): void {
    const activeIds = new Set<number>();

    for (const enemy of world.enemies) {
      if (enemy.hp <= 0) continue;
      activeIds.add(enemy.id);

      let labelEl = this.enemyLabels.get(enemy.id);
      if (!labelEl) {
        labelEl = document.createElement('div');
        labelEl.style.position = 'absolute';
        labelEl.style.transform = 'translate(-50%, -100%)';
        labelEl.style.textAlign = 'center';
        labelEl.style.pointerEvents = 'none';
        labelEl.style.fontSize = '11px';
        labelEl.style.fontWeight = '700';
        labelEl.style.textShadow = '0 1px 3px rgba(0,0,0,0.95)';
        this.floatingLayer.appendChild(labelEl);
        this.enemyLabels.set(enemy.id, labelEl);
      }

      const screen = renderer.projectToScreen(
        new THREE.Vector3(enemy.x, enemy.visualScale + 0.35, enemy.z)
      );
      labelEl.style.left = `${screen.x}px`;
      labelEl.style.top = `${screen.y}px`;

      let stateTag = '';
      if (enemy.weakPointExposed) {
        stateTag = '<div style="color:#fde047;font-size:12px;">🎯 [금빛 외눈 노출! 우클릭 풀차징 저격]</div>';
      } else if (enemy.state === 'windup' || enemy.state === 'attack') {
        stateTag = '<div style="color:#fb923c;">⚠️ [강공격 예고!]</div>';
      } else if (enemy.state === 'staggered') {
        stateTag = '<div style="color:#67e8f9;">💫 [대경직 상태!]</div>';
      }

      const hpDisplay =
        enemy.kind === 'resonance_bell'
          ? '🔔 검·활로 타격 시 황금 공명 발동'
          : `HP ${enemy.hp}/${enemy.maxHp}`;

      labelEl.innerHTML = `
        ${stateTag}
        <div style="color:#f8fafc;">${enemy.name}</div>
        <div style="color:#99f6e4;font-size:10px;">${hpDisplay}</div>
      `;
    }

    for (const [id, el] of this.enemyLabels.entries()) {
      if (!activeIds.has(id)) {
        el.remove();
        this.enemyLabels.delete(id);
      }
    }
  }
}
