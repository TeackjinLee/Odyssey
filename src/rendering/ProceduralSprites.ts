import * as THREE from 'three';
import { EnemyKind, GodId, PlayerEntity } from '../types/combat';
import { ArticulatedCharacterRenderer } from './ArticulatedCharacterRenderer';

/**
 * 오디세우스 주인공 관절 애니메이션 렌더러(ArticulatedCharacterRenderer)와
 * 적/보스 고해상도 스프라이트 및 사용자 PNG 드래그 앤 드롭(Flood-Fill 흰 배경 자동 투명화)을 관리하는 매니저.
 */
export class ProceduralSprites {
  private cache = new Map<string, THREE.CanvasTexture>();
  private articulatedPlayer = new ArticulatedCharacterRenderer();
  private playerDynamicTex: THREE.CanvasTexture;
  private customPlayerCanvas: HTMLCanvasElement | null = null;
  private customPlayerAttackCanvas: HTMLCanvasElement | null = null;
  private customEnemyTex = new Map<EnemyKind, THREE.CanvasTexture>();

  private walkAccumTime = 0;
  private idleAccumTime = 0;

  constructor() {
    this.playerDynamicTex = new THREE.CanvasTexture(this.articulatedPlayer.getCanvas());
    this.playerDynamicTex.colorSpace = THREE.SRGBColorSpace;
    this.initDefaultAndSavedSprites();
  }

  private initDefaultAndSavedSprites(): void {
    try {
      // 1) 8방향 이동/대기 시트(/assets/odysseus_8dir.png) 및 2) 6프레임 전투 액션 시트(/assets/odysseus_attack.png) 로드!
      this.tryLoadExternalAsset('/assets/odysseus_8dir.png', 'player', true);
      this.tryLoadExternalAsset('/assets/odysseus_attack.png', 'player_attack', true);

      const savedPoly = localStorage.getItem('odyssey_custom_sprite_boss_polyphemus');
      if (savedPoly) {
        this.loadDataUrlIntoCustomSprite('boss_polyphemus', savedPoly, false);
      } else {
        this.tryLoadExternalAsset('/assets/polyphemus.svg', 'boss_polyphemus', false);
      }

      const savedParthenope = localStorage.getItem('odyssey_custom_sprite_boss_parthenope');
      if (savedParthenope) {
        this.loadDataUrlIntoCustomSprite('boss_parthenope', savedParthenope, false);
      } else {
        this.tryLoadExternalAsset('/assets/parthenope.svg', 'boss_parthenope', false);
      }
    } catch {
      // ignore storage errors
    }
  }

  private tryLoadExternalAsset(
    url: string,
    target: 'player' | 'player_attack' | EnemyKind,
    removeWhiteBg = true
  ): void {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      const tex = removeWhiteBg
        ? this.createFloodFillKeyedTexture(img)
        : this.createDirectTexture(img);
      if (target === 'player') {
        this.customPlayerCanvas = tex.image as HTMLCanvasElement;
      } else if (target === 'player_attack') {
        this.customPlayerAttackCanvas = tex.image as HTMLCanvasElement;
      } else {
        this.customEnemyTex.set(target, tex);
      }
    };
    img.src = url;
  }

  /**
   * 매 프레임 오디세우스의 8방향 시트 셀(N, NE, E, SE, S, SW, W, NW)과
   * 6프레임 전투 액션 키프레임(창 1·2·3타, Q 패링, Space 대시)을 결합하여 동적 텍스처를 반환
   */
  public updateAndGetPlayerTexture(player: PlayerEntity, dt: number): THREE.CanvasTexture {
    this.idleAccumTime += dt;
    const speed = Math.hypot(player.vx, player.vz);
    if (player.state === 'move' || (player.state === 'bow_charge' && speed > 0.2)) {
      this.walkAccumTime += dt * (speed / 7.8);
    } else {
      this.walkAccumTime = 0;
    }

    this.articulatedPlayer.renderOdysseusFrame(
      player,
      this.walkAccumTime,
      this.idleAccumTime,
      this.customPlayerCanvas,
      this.customPlayerAttackCanvas
    );
    this.playerDynamicTex.needsUpdate = true;
    return this.playerDynamicTex;
  }

  public getWalkPhase(): number {
    return this.walkAccumTime * 13.5;
  }

  /**
   * 사용자가 업로드한 이미지(흰색 배경 PNG/JPG 포함)에서
   * 외곽 흰색 배경만 Flood-Fill로 투명화하여 적용 (업로드된 이미지도 3분할 다리 보행 모션이 자동 적용됨)
   */
  public applyUserUploadedImage(
    file: File,
    target: 'player' | EnemyKind = 'player',
    onComplete?: () => void
  ): void {
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = reader.result as string;
      this.loadDataUrlIntoCustomSprite(target, dataUrl, true, onComplete);
    };
    reader.readAsDataURL(file);
  }

  public resetToBuiltInOdysseusRig(): void {
    this.customPlayerCanvas = null;
    try {
      localStorage.removeItem('odyssey_custom_sprite_player');
    } catch {
      // ignore
    }
  }

  private loadDataUrlIntoCustomSprite(
    target: 'player' | EnemyKind,
    dataUrl: string,
    saveToStorage: boolean,
    onComplete?: () => void
  ): void {
    const img = new Image();
    img.onload = () => {
      const tex = this.createFloodFillKeyedTexture(img);
      if (target === 'player') {
        this.customPlayerCanvas = tex.image as HTMLCanvasElement;
      } else {
        this.customEnemyTex.set(target, tex);
      }

      if (saveToStorage) {
        try {
          const keyedCanvas = tex.image as HTMLCanvasElement;
          const compressedUrl = keyedCanvas.toDataURL('image/png');
          const storageKey =
            target === 'player'
              ? 'odyssey_custom_sprite_player'
              : `odyssey_custom_sprite_${target}`;
          localStorage.setItem(storageKey, compressedUrl);
        } catch {
          // ignore quota error
        }
      }
      if (onComplete) onComplete();
    };
    img.src = dataUrl;
  }

  private createDirectTexture(img: HTMLImageElement): THREE.CanvasTexture {
    const canvas = document.createElement('canvas');
    canvas.width = 640;
    canvas.height = 800;
    const ctx = canvas.getContext('2d')!;
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    const tex = new THREE.CanvasTexture(canvas);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.needsUpdate = true;
    return tex;
  }

  private createFloodFillKeyedTexture(img: HTMLImageElement): THREE.CanvasTexture {
    const maxDim = 1536;
    const scale = Math.min(1, maxDim / Math.max(img.width || 1024, img.height || 1536));
    const w = Math.max(64, Math.round((img.width || 1024) * scale));
    const h = Math.max(64, Math.round((img.height || 1536) * scale));

    const canvas = document.createElement('canvas');
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext('2d')!;
    ctx.drawImage(img, 0, 0, w, h);

    const imgData = ctx.getImageData(0, 0, w, h);
    const data = imgData.data;
    const visited = new Uint8Array(w * h);
    const queue = new Int32Array(w * h);
    let head = 0;
    let tail = 0;

    const isBgWhite = (idx: number): boolean => {
      const p = idx * 4;
      const a = data[p + 3];
      if (a < 20) return true;
      const r = data[p];
      const g = data[p + 1];
      const b = data[p + 2];
      const maxC = Math.max(r, g, b);
      const minC = Math.min(r, g, b);
      return r > 224 && g > 224 && b > 220 && maxC - minC < 26;
    };

    const pushIfBg = (x: number, y: number): void => {
      const idx = y * w + x;
      if (!visited[idx] && isBgWhite(idx)) {
        visited[idx] = 1;
        queue[tail++] = idx;
      }
    };

    for (let x = 0; x < w; x++) {
      pushIfBg(x, 0);
      pushIfBg(x, h - 1);
    }
    for (let y = 0; y < h; y++) {
      pushIfBg(0, y);
      pushIfBg(w - 1, y);
    }

    // 활시위 안쪽 및 창대와 팔/허벅지 사이의 막힌 순백색(#FEFEFE~#FFFFFF) 배경 홀(Hole)도 시드로 추가
    for (let y = 2; y < h - 2; y += 2) {
      for (let x = 2; x < w - 2; x += 2) {
        const idx = y * w + x;
        if (visited[idx]) continue;
        const p = idx * 4;
        if (data[p] >= 251 && data[p + 1] >= 251 && data[p + 2] >= 251) {
          const pUp = ((y - 2) * w + x) * 4;
          const pDn = ((y + 2) * w + x) * 4;
          const pLf = (y * w + (x - 2)) * 4;
          const pRt = (y * w + (x + 2)) * 4;
          if (
            data[pUp] >= 251 && data[pUp + 2] >= 251 &&
            data[pDn] >= 251 && data[pDn + 2] >= 251 &&
            data[pLf] >= 251 && data[pLf + 2] >= 251 &&
            data[pRt] >= 251 && data[pRt + 2] >= 251
          ) {
            pushIfBg(x, y);
          }
        }
      }
    }

    while (head < tail) {
      const curr = queue[head++];
      const p = curr * 4;
      data[p + 3] = 0;

      const cx = curr % w;
      const cy = (curr / w) | 0;

      if (cx > 0) pushIfBg(cx - 1, cy);
      if (cx < w - 1) pushIfBg(cx + 1, cy);
      if (cy > 0) pushIfBg(cx, cy - 1);
      if (cy < h - 1) pushIfBg(cx, cy + 1);
    }

    for (let y = 1; y < h - 1; y++) {
      for (let x = 1; x < w - 1; x++) {
        const idx = y * w + x;
        if (visited[idx]) continue;
        if (
          visited[idx - 1] ||
          visited[idx + 1] ||
          visited[idx - w] ||
          visited[idx + w]
        ) {
          const p = idx * 4;
          const lum = (data[p] + data[p + 1] + data[p + 2]) / 3;
          if (lum > 200) {
            data[p + 3] = Math.round(data[p + 3] * 0.35);
          }
        }
      }
    }

    ctx.putImageData(imgData, 0, 0);
    const tex = new THREE.CanvasTexture(canvas);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.needsUpdate = true;
    return tex;
  }

  private setupHiResCanvas(w = 512, h = 640): {
    canvas: HTMLCanvasElement;
    ctx: CanvasRenderingContext2D;
  } {
    const canvas = document.createElement('canvas');
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext('2d')!;
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';
    return { canvas, ctx };
  }

  public getEnemyTexture(
    kind: EnemyKind,
    state: 'normal' | 'windup' | 'weak_open' | 'staggered' | 'hit'
  ): THREE.CanvasTexture {
    if (state === 'normal' && this.customEnemyTex.has(kind)) {
      return this.customEnemyTex.get(kind)!;
    }

    const key = `enemy_comic_${kind}_${state}`;
    if (this.cache.has(key)) return this.cache.get(key)!;

    const { canvas, ctx } = this.setupHiResCanvas(512, 640);
    const isHit = state === 'hit';
    const isWindup = state === 'windup';
    const isWeak = state === 'weak_open';

    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    if (kind === 'boss_polyphemus') {
      ctx.strokeStyle = '#140c08';
      ctx.lineWidth = 7;

      for (const lx of [165, 325]) {
        ctx.fillStyle = isHit ? '#ffffff' : '#c68b59';
        ctx.beginPath();
        ctx.roundRect(lx - 42, 390, 84, 210, 26);
        ctx.fill();
        ctx.stroke();

        const gGrad = ctx.createLinearGradient(lx - 40, 450, lx + 40, 560);
        gGrad.addColorStop(0, '#fef08a');
        gGrad.addColorStop(0.5, '#ca8a04');
        gGrad.addColorStop(1, '#713f12');
        ctx.fillStyle = gGrad;
        ctx.beginPath();
        ctx.roundRect(lx - 38, 450, 76, 110, 14);
        ctx.fill();
        ctx.stroke();
      }

      for (let i = 0; i < 6; i++) {
        const kx = 128 + i * 44;
        ctx.fillStyle = '#3e2011';
        ctx.beginPath();
        ctx.roundRect(kx, 345, 38, 108, 6);
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#facc15';
        ctx.beginPath();
        ctx.arc(kx + 19, 425, 7, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();
      }

      const bodyGrad = ctx.createLinearGradient(80, 120, 430, 380);
      bodyGrad.addColorStop(0, isHit ? '#ffffff' : '#eab688');
      bodyGrad.addColorStop(0.55, isHit ? '#ffffff' : '#b87a4b');
      bodyGrad.addColorStop(1, '#6e3f1d');
      ctx.fillStyle = bodyGrad;
      ctx.beginPath();
      ctx.moveTo(75, 165);
      ctx.bezierCurveTo(65, 95, 445, 95, 435, 165);
      ctx.lineTo(385, 365);
      ctx.lineTo(125, 365);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(195, 225, 55, 0.15, Math.PI - 0.15);
      ctx.arc(317, 225, 55, 0.15, Math.PI - 0.15);
      ctx.stroke();

      ctx.strokeStyle = '#ca8a04';
      ctx.lineWidth = 20;
      ctx.beginPath();
      ctx.moveTo(115, 130);
      ctx.lineTo(395, 335);
      ctx.moveTo(395, 130);
      ctx.lineTo(115, 335);
      ctx.stroke();
      ctx.strokeStyle = '#140c08';
      ctx.lineWidth = 5;
      ctx.stroke();

      ctx.save();
      ctx.translate(155, isWindup ? 190 : 375);
      ctx.rotate(isWindup ? -0.85 : -0.45);
      ctx.fillStyle = '#5c3418';
      ctx.strokeStyle = '#140c08';
      ctx.lineWidth = 6;
      ctx.beginPath();
      ctx.roundRect(-34, -140, 68, 290, 18);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = '#eab308';
      ctx.fillRect(-38, 25, 76, 26);
      ctx.strokeRect(-38, 25, 76, 26);
      ctx.fillRect(-38, 82, 76, 26);
      ctx.strokeRect(-38, 82, 76, 26);
      ctx.restore();

      ctx.fillStyle = '#27201c';
      ctx.beginPath();
      ctx.arc(256, 130, 78, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = '#d49466';
      ctx.beginPath();
      ctx.arc(256, 138, 56, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = '#27201c';
      ctx.beginPath();
      ctx.arc(256, 152, 58, 0.1, Math.PI - 0.1);
      ctx.lineTo(256, 228);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      if (isWeak || isWindup) {
        const g = ctx.createRadialGradient(256, 112, 4, 256, 112, 85);
        g.addColorStop(0, '#ffffff');
        g.addColorStop(0.35, '#fef08a');
        g.addColorStop(0.7, 'rgba(234, 179, 8, 0.55)');
        g.addColorStop(1, 'rgba(234, 179, 8, 0)');
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(256, 112, 85, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.fillStyle = isWeak ? '#fef08a' : '#facc15';
      ctx.beginPath();
      ctx.arc(256, 112, isWeak ? 26 : 18, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    } else if (kind === 'boulder_cyclops') {
      ctx.strokeStyle = '#140c08';
      ctx.lineWidth = 6;
      ctx.fillStyle = isHit ? '#ffffff' : '#b87a4b';
      ctx.beginPath();
      ctx.roundRect(145, 220, 222, 260, 32);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = '#78716c';
      ctx.beginPath();
      ctx.arc(256, 105, isWindup ? 92 : 76, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = '#fde047';
      ctx.beginPath();
      ctx.arc(256, 235, 16, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    } else if (kind === 'lotus_cultist') {
      ctx.strokeStyle = '#140c08';
      ctx.lineWidth = 6;
      ctx.fillStyle = isHit ? '#ffffff' : '#581c87';
      ctx.beginPath();
      ctx.moveTo(256, 110);
      ctx.lineTo(375, 550);
      ctx.lineTo(137, 550);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = '#e879f9';
      ctx.beginPath();
      ctx.arc(365, 165, 34, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    } else if (kind === 'siren_harpy' || kind === 'boss_parthenope') {
      const isQueen = kind === 'boss_parthenope';
      ctx.strokeStyle = '#090d16';
      ctx.lineWidth = 5;

      for (const dir of [-1, 1]) {
        for (let f = 0; f < (isQueen ? 12 : 8); f++) {
          const ang = dir * (0.18 + f * 0.11);
          const len = (isQueen ? 245 : 205) - f * 10;
          ctx.save();
          ctx.translate(256 + dir * 24, 230);
          ctx.rotate(ang);
          ctx.fillStyle = f % 2 === 0 ? '#1e3a8a' : '#0f172a';
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.quadraticCurveTo(dir * len * 0.6, -55, dir * len, -25);
          ctx.quadraticCurveTo(dir * len * 0.6, 16, 0, 26);
          ctx.closePath();
          ctx.fill();
          ctx.stroke();
          ctx.restore();
        }
      }

      ctx.fillStyle = isHit ? '#ffffff' : isQueen ? '#312e81' : '#1e293b';
      ctx.beginPath();
      ctx.roundRect(196, 210, 120, 320, 28);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = '#e2e8f0';
      ctx.beginPath();
      ctx.arc(256, 145, 38, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      if (isQueen) {
        ctx.strokeStyle = '#facc15';
        ctx.lineWidth = 6;
        for (let s = -4; s <= 4; s++) {
          const sa = -Math.PI / 2 + s * 0.22;
          ctx.beginPath();
          ctx.moveTo(256 + Math.cos(sa) * 38, 140 + Math.sin(sa) * 38);
          ctx.lineTo(256 + Math.cos(sa) * 76, 140 + Math.sin(sa) * 76);
          ctx.stroke();
        }
      }
    } else if (kind === 'drowned_hoplite') {
      ctx.strokeStyle = '#cffafe';
      ctx.fillStyle = 'rgba(34, 211, 238, 0.45)';
      ctx.lineWidth = 5;
      ctx.beginPath();
      ctx.roundRect(190, 185, 132, 280, 24);
      ctx.fill();
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(256, 135, 42, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(178, 305, 84, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    } else if (kind === 'resonance_bell') {
      ctx.strokeStyle = '#140c08';
      ctx.lineWidth = 6;
      const bGrad = ctx.createLinearGradient(110, 125, 402, 510);
      bGrad.addColorStop(0, isHit ? '#ffffff' : '#fef08a');
      bGrad.addColorStop(0.45, '#ca8a04');
      bGrad.addColorStop(1, '#451a03');
      ctx.fillStyle = bGrad;
      ctx.beginPath();
      ctx.moveTo(165, 130);
      ctx.quadraticCurveTo(256, 108, 347, 130);
      ctx.lineTo(422, 495);
      ctx.lineTo(90, 495);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
    } else {
      ctx.strokeStyle = '#140c08';
      ctx.lineWidth = 6;
      ctx.fillStyle = isHit ? '#ffffff' : '#ca8a04';
      ctx.beginPath();
      ctx.roundRect(176, 185, 160, 260, 24);
      ctx.fill();
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(256, 125, 48, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }

    const tex = new THREE.CanvasTexture(canvas);
    tex.colorSpace = THREE.SRGBColorSpace;
    this.cache.set(key, tex);
    return tex;
  }

  public drawGodEmblemDataUrl(god: GodId): string {
    const { canvas, ctx } = this.setupHiResCanvas(320, 320);
    const cx = 160;
    const cy = 160;

    if (god === 'athena') {
      const g = ctx.createRadialGradient(cx, cy, 18, cx, cy, 145);
      g.addColorStop(0, '#fef9c3');
      g.addColorStop(0.55, '#d97706');
      g.addColorStop(1, '#451a03');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(cx, cy, 142, 0, Math.PI * 2);
      ctx.fill();
      ctx.lineWidth = 8;
      ctx.strokeStyle = '#fef08a';
      ctx.stroke();

      ctx.fillStyle = '#fef9c3';
      ctx.strokeStyle = '#78350f';
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.moveTo(cx, cy - 10);
      ctx.quadraticCurveTo(cx - 95, cy - 55, cx - 85, cy + 45);
      ctx.quadraticCurveTo(cx - 40, cy + 55, cx, cy + 75);
      ctx.quadraticCurveTo(cx + 40, cy + 55, cx + 85, cy + 45);
      ctx.quadraticCurveTo(cx + 95, cy - 55, cx, cy - 10);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
    } else if (god === 'zeus') {
      const g = ctx.createRadialGradient(cx, cy, 16, cx, cy, 145);
      g.addColorStop(0, '#ffffff');
      g.addColorStop(0.45, '#2563eb');
      g.addColorStop(1, '#0f172a');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(cx, cy, 142, 0, Math.PI * 2);
      ctx.fill();
      ctx.lineWidth = 8;
      ctx.strokeStyle = '#bae6fd';
      ctx.stroke();

      ctx.fillStyle = '#ffffff';
      ctx.beginPath();
      ctx.moveTo(cx, cy - 108);
      ctx.lineTo(cx + 22, cy - 20);
      ctx.lineTo(cx + 68, cy - 68);
      ctx.lineTo(cx + 38, cy + 32);
      ctx.lineTo(cx, cy + 112);
      ctx.lineTo(cx - 38, cy + 32);
      ctx.lineTo(cx - 68, cy - 68);
      ctx.lineTo(cx - 22, cy - 20);
      ctx.closePath();
      ctx.fill();
    } else if (god === 'apollo') {
      const g = ctx.createRadialGradient(cx, cy, 16, cx, cy, 145);
      g.addColorStop(0, '#fef08a');
      g.addColorStop(0.55, '#ea580c');
      g.addColorStop(1, '#431407');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(cx, cy, 142, 0, Math.PI * 2);
      ctx.fill();
      ctx.lineWidth = 8;
      ctx.strokeStyle = '#fde047';
      ctx.stroke();

      ctx.fillStyle = '#fef08a';
      ctx.beginPath();
      ctx.arc(cx, cy, 42, 0, Math.PI * 2);
      ctx.fill();
    } else {
      const g = ctx.createRadialGradient(cx, cy, 16, cx, cy, 145);
      g.addColorStop(0, '#f0fdfa');
      g.addColorStop(0.55, '#0d9488');
      g.addColorStop(1, '#042f2e');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(cx, cy, 142, 0, Math.PI * 2);
      ctx.fill();
      ctx.lineWidth = 8;
      ctx.strokeStyle = '#99f6e4';
      ctx.stroke();

      ctx.fillStyle = '#f8fafc';
      ctx.beginPath();
      ctx.moveTo(cx, cy + 45);
      ctx.lineTo(cx - 105, cy - 45);
      ctx.lineTo(cx - 25, cy - 10);
      ctx.lineTo(cx, cy - 85);
      ctx.lineTo(cx + 25, cy - 10);
      ctx.lineTo(cx + 105, cy - 45);
      ctx.closePath();
      ctx.fill();
    }

    return canvas.toDataURL();
  }
}
