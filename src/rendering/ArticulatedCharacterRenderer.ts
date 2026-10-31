import { PlayerEntity } from '../types/combat';

export type Dir8 = 'N' | 'NE' | 'E' | 'SE' | 'S' | 'SW' | 'W' | 'NW';

interface DirectionalRigCell {
  fullCell: HTMLCanvasElement;
  bodyAndHead: HTMLCanvasElement;
  leftLeg: HTMLCanvasElement;
  rightLeg: HTMLCanvasElement;
  spearArm: HTMLCanvasElement;
  spearOnRightSide: boolean;
  spearPivotX: number;
  spearPivotY: number;
}

/**
 * 1) 8방향 이동/대기 스프라이트 시트(/assets/odysseus_8dir.png, 1536x1024, 4x2 그리드)와
 * 2) 6프레임 전투 액션 스프라이트 시트(/assets/odysseus_attack.png, 1536x1024, 3x2 그리드)를
 * 모두 통합하여,
 * - 평상시 및 8방향 이동 시에는 8방향 시트 셀(N, NE, E, SE, S, SW, W, NW)과 다관절 다리 보행을 표시하고,
 * - 창 3단 콤보(1타 횡베기, 2타 직선 찌르기, 3타 회전 강타), Q 방패 패링, Space 대시 시에는
 *   전용 6프레임 전투 액션 시트의 역동적인 원화 키프레임을 조준 방향에 맞춰 출력하는 렌더러.
 */
export class ArticulatedCharacterRenderer {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;

  private sheet8DirSource: HTMLCanvasElement | null = null;
  private dirCells = new Map<Dir8, DirectionalRigCell>();

  private sheetAttackSource: HTMLCanvasElement | null = null;
  private attackCells: HTMLCanvasElement[] = []; // 0..5 (3x2 그리드)

  private readonly CW = 384;
  private readonly CH = 512;
  private readonly AW = 512;
  private readonly AH = 512;

  constructor() {
    this.canvas = document.createElement('canvas');
    this.canvas.width = 560;
    this.canvas.height = 640;
    this.ctx = this.canvas.getContext('2d')!;
    this.ctx.imageSmoothingEnabled = true;
    this.ctx.imageSmoothingQuality = 'high';
  }

  public getCanvas(): HTMLCanvasElement {
    return this.canvas;
  }

  private ensure8DirSheet(sheetCanvas: HTMLCanvasElement): void {
    if (this.sheet8DirSource === sheetCanvas && this.dirCells.size === 8) {
      return;
    }
    this.sheet8DirSource = sheetCanvas;
    this.dirCells.clear();

    const normSheet = document.createElement('canvas');
    normSheet.width = 1536;
    normSheet.height = 1024;
    const nctx = normSheet.getContext('2d')!;
    nctx.drawImage(sheetCanvas, 0, 0, 1536, 1024);

    const mapping: Array<{
      dir: Dir8;
      col: number;
      row: number;
      flipX: boolean;
      spearOnRight: boolean;
    }> = [
      { dir: 'S', col: 0, row: 0, flipX: false, spearOnRight: false },
      { dir: 'SE', col: 1, row: 0, flipX: false, spearOnRight: false },
      { dir: 'W', col: 2, row: 0, flipX: false, spearOnRight: false },
      { dir: 'NW', col: 3, row: 0, flipX: false, spearOnRight: true },
      { dir: 'N', col: 0, row: 1, flipX: false, spearOnRight: true },
      { dir: 'NE', col: 1, row: 1, flipX: false, spearOnRight: true },
      { dir: 'E', col: 2, row: 1, flipX: false, spearOnRight: true },
      { dir: 'SW', col: 3, row: 1, flipX: true, spearOnRight: true },
    ];

    for (const m of mapping) {
      const cellCanvas = document.createElement('canvas');
      cellCanvas.width = this.CW;
      cellCanvas.height = this.CH;
      const cctx = cellCanvas.getContext('2d')!;

      cctx.save();
      if (m.flipX) {
        cctx.translate(this.CW, 0);
        cctx.scale(-1, 1);
      }
      cctx.drawImage(
        normSheet,
        m.col * this.CW,
        m.row * this.CH,
        this.CW,
        this.CH,
        0,
        0,
        this.CW,
        this.CH
      );
      cctx.restore();

      this.dirCells.set(m.dir, this.segmentCellIntoRig(cellCanvas, m.spearOnRight, m.dir));
    }
  }

  /**
   * 1536x1024 (3열 x 2행) 전투 액션 스프라이트 시트(/assets/odysseus_attack.png)에서
   * 6개의 액션 키프레임 셀(각 512x512) 추출:
   * - Frame 0 (0,0): 창 머리 위 준비 동작 (Windup)
   * - Frame 1 (1,0): 창 중단 가르기 / 찌르기 준비 (Mid-Slash / Ready)
   * - Frame 2 (2,0): 창 전방 롱리치 돌진 찌르기 (Full Lunge Thrust)
   * - Frame 3 (0,1): 후면·회전 대각선 강타 (Back-View / 3rd Hit Spin Slash)
   * - Frame 4 (1,1): 방패 방어 태세 / 무적 대시 자세 (Shield Brace / Dash)
   * - Frame 5 (2,1): Q 방패 패링 밀치기 & 광역 횡베기 피니시 (Shield Bash Parry & Wide Slash Finish)
   */
  private ensureAttackSheet(attackSheetCanvas: HTMLCanvasElement): void {
    if (this.sheetAttackSource === attackSheetCanvas && this.attackCells.length === 6) {
      return;
    }
    this.sheetAttackSource = attackSheetCanvas;
    this.attackCells = [];

    const norm = document.createElement('canvas');
    norm.width = 1536;
    norm.height = 1024;
    const nctx = norm.getContext('2d')!;
    nctx.drawImage(attackSheetCanvas, 0, 0, 1536, 1024);

    for (let row = 0; row < 2; row++) {
      for (let col = 0; col < 3; col++) {
        const c = document.createElement('canvas');
        c.width = this.AW;
        c.height = this.AH;
        const cctx = c.getContext('2d')!;
        cctx.drawImage(
          norm,
          col * this.AW,
          row * this.AH,
          this.AW,
          this.AH,
          0,
          0,
          this.AW,
          this.AH
        );
        this.attackCells.push(c);
      }
    }
  }

  private segmentCellIntoRig(
    cell: HTMLCanvasElement,
    spearOnRight: boolean,
    dir: Dir8
  ): DirectionalRigCell {
    const W = this.CW;
    const H = this.CH;

    const extractPoly = (poly: Array<[number, number]>): HTMLCanvasElement => {
      const c = document.createElement('canvas');
      c.width = W;
      c.height = H;
      const ctx = c.getContext('2d')!;
      ctx.save();
      ctx.beginPath();
      poly.forEach(([px, py], i) => {
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      });
      ctx.closePath();
      ctx.clip();
      ctx.drawImage(cell, 0, 0);
      ctx.restore();
      return c;
    };

    const spearPoly: Array<[number, number]> = spearOnRight
      ? [
          [242, 0],
          [W, 0],
          [W, 455],
          [242, 455],
          [248, 200],
        ]
      : [
          [0, 0],
          [138, 0],
          [132, 200],
          [138, 455],
          [0, 455],
        ];

    const spearArm = extractPoly(spearPoly);

    const legSplitX = dir === 'E' || dir === 'W' ? 190 : 192;
    const leftLegMinX = spearOnRight ? 75 : 112;
    const rightLegMaxX = spearOnRight ? 268 : 310;

    const leftLeg = extractPoly([
      [leftLegMinX, 322],
      [legSplitX, 322],
      [legSplitX, H],
      [leftLegMinX, H],
    ]);
    const rightLeg = extractPoly([
      [legSplitX, 322],
      [rightLegMaxX, 322],
      [rightLegMaxX, H],
      [legSplitX, H],
    ]);

    const bodyAndHead = document.createElement('canvas');
    bodyAndHead.width = W;
    bodyAndHead.height = H;
    const bctx = bodyAndHead.getContext('2d')!;
    bctx.drawImage(cell, 0, 0);

    const erasePoly = (poly: Array<[number, number]>): void => {
      bctx.save();
      bctx.globalCompositeOperation = 'destination-out';
      bctx.beginPath();
      poly.forEach(([px, py], i) => {
        if (i === 0) bctx.moveTo(px, py);
        else bctx.lineTo(px, py);
      });
      bctx.closePath();
      bctx.fill();
      bctx.restore();
    };

    erasePoly([
      [leftLegMinX, 344],
      [rightLegMaxX, 344],
      [rightLegMaxX, H],
      [leftLegMinX, H],
    ]);
    erasePoly(spearPoly);

    return {
      fullCell: cell,
      bodyAndHead,
      leftLeg,
      rightLeg,
      spearArm,
      spearOnRightSide: spearOnRight,
      spearPivotX: spearOnRight ? 275 : 108,
      spearPivotY: 225,
    };
  }

  public angleToDir8(angleRad: number): Dir8 {
    let deg = (angleRad * 180) / Math.PI;
    while (deg < 0) deg += 360;
    while (deg >= 360) deg -= 360;

    if (deg >= 337.5 || deg < 22.5) return 'E';
    if (deg >= 22.5 && deg < 67.5) return 'SE';
    if (deg >= 67.5 && deg < 112.5) return 'S';
    if (deg >= 112.5 && deg < 157.5) return 'SW';
    if (deg >= 157.5 && deg < 202.5) return 'W';
    if (deg >= 202.5 && deg < 247.5) return 'NW';
    if (deg >= 247.5 && deg < 292.5) return 'N';
    return 'NE';
  }

  public renderOdysseusFrame(
    player: PlayerEntity,
    walkTime: number,
    idleTime: number,
    sheet8DirImage: HTMLCanvasElement | null,
    sheetAttackImage: HTMLCanvasElement | null = null
  ): HTMLCanvasElement {
    const ctx = this.ctx;
    const cw = this.canvas.width;
    const ch = this.canvas.height;
    ctx.clearRect(0, 0, cw, ch);

    if (!sheet8DirImage) {
      return this.canvas;
    }

    this.ensure8DirSheet(sheet8DirImage);
    if (sheetAttackImage) {
      this.ensureAttackSheet(sheetAttackImage);
    }

    const isDashing = player.state === 'dash';
    const isParrying =
      player.state === 'parry_active' || player.state === 'parry_recovery';
    const isSpear =
      player.state === 'spear_windup' ||
      player.state === 'spear_swing' ||
      player.state === 'spear_recovery';

    // =========================================================================
    // [전투 액션 시트(/assets/odysseus_attack.png) 출력 구간]
    // 창 3단 콤보, Q 방패 패링, Space 무적 대시 중에는 6프레임 액션 시트의 전용 원화 사용!
    // =========================================================================
    if (this.attackCells.length === 6 && (isSpear || isParrying || isDashing)) {
      this.renderCombatActionKeyframe(ctx, cw, ch, player);
      return this.canvas;
    }

    // =========================================================================
    // [8방향 시트(/assets/odysseus_8dir.png) 출력 구간]
    // 대기(Idle), 8방향 이동(Move), 강궁 차징(Bow Charge) 시 방향별 셀 + 다리 보행 모션 출력
    // =========================================================================
    const dir8 = this.angleToDir8(player.facingAngle);
    const cell = this.dirCells.get(dir8);
    if (!cell) return this.canvas;

    const isMoving =
      player.state === 'move' ||
      (player.state === 'bow_charge' && Math.hypot(player.vx, player.vz) > 0.2);
    const isBow = player.state === 'bow_charge' || player.state === 'bow_recovery';

    // 정지(Idle) 상태이고 활 차징 중이 아니면 세그먼트 이음새가 전혀 없는 원본 셀(fullCell)을 그대로 출력하여 원화 품질 100% 보장!
    if (!isMoving && !isBow) {
      const breatheY = Math.sin(idleTime * 3.0) * 3.5;
      ctx.save();
      const renderScale = 1.18;
      ctx.translate(cw * 0.5, ch * 0.54 + breatheY);
      ctx.scale(renderScale, renderScale);
      ctx.translate(-this.CW * 0.5, -this.CH * 0.52);
      ctx.drawImage(cell.fullCell, 0, 0);
      ctx.restore();

      this.applyHitFlash(ctx, cw, ch, player);
      return this.canvas;
    }

    const walkFreq = player.state === 'bow_charge' ? 8.5 : 14.5;
    const phase = walkTime * walkFreq;
    const strideSin = isMoving ? Math.sin(phase) : 0;
    const strideCos = isMoving ? Math.cos(phase) : 0;

    const bodyBobY = isMoving ? -Math.abs(Math.sin(phase)) * 12 : 0;
    const bodyTiltRad = isMoving ? Math.sin(phase) * 0.035 : 0;
    const spearRot = -strideSin * 0.2 + bodyTiltRad;

    ctx.save();
    const renderScale = 1.18;
    ctx.translate(cw * 0.5, ch * 0.54);
    ctx.scale(renderScale, renderScale);
    ctx.translate(-this.CW * 0.5, -this.CH * 0.52);

    const isBackDir = dir8 === 'N' || dir8 === 'NW' || dir8 === 'NE';

    if (isBackDir) {
      this.drawPivotedLayer(
        ctx,
        cell.spearArm,
        cell.spearPivotX,
        cell.spearPivotY,
        0,
        bodyBobY,
        spearRot
      );
    }

    // 양다리 교차 보행
    const leftLegRot = -strideSin * 0.28;
    const leftLegLiftY = isMoving ? -Math.max(0, -strideCos) * 22 : 0;
    const leftLegStepX = strideSin * 11;

    const rightLegRot = strideSin * 0.28;
    const rightLegLiftY = isMoving ? -Math.max(0, strideCos) * 22 : 0;
    const rightLegStepX = -strideSin * 11;

    this.drawPivotedLayer(
      ctx,
      cell.leftLeg,
      152,
      332,
      leftLegStepX,
      bodyBobY * 0.5 + leftLegLiftY,
      leftLegRot
    );
    this.drawPivotedLayer(
      ctx,
      cell.rightLeg,
      232,
      332,
      rightLegStepX,
      bodyBobY * 0.5 + rightLegLiftY,
      rightLegRot
    );

    this.drawPivotedLayer(
      ctx,
      cell.bodyAndHead,
      192,
      310,
      0,
      bodyBobY,
      bodyTiltRad
    );

    if (!isBackDir) {
      this.drawPivotedLayer(
        ctx,
        cell.spearArm,
        cell.spearPivotX,
        cell.spearPivotY,
        0,
        bodyBobY,
        spearRot
      );
    }

    if (isBow) {
      this.drawDirectionalBowOverlay(
        ctx,
        192,
        245 + bodyBobY,
        player.facingAngle,
        player.bowCharge
      );
    }

    ctx.restore();
    this.applyHitFlash(ctx, cw, ch, player);
    return this.canvas;
  }

  /**
   * 6프레임 전투 액션 시트(/assets/odysseus_attack.png) 키프레임 매핑 및 역동적 모션 보간:
   * - Frame 0 (0,0): 창 머리 위 준비 동작 (1타·3타 Windup)
   * - Frame 1 (1,0): 창 중단 가르기 / 찌르기 준비 (2타 Windup & 1타 초반 스윙)
   * - Frame 2 (2,0): 창 전방 롱리치 돌진 찌르기 (2타 Swing/Recovery & 1타 전방 찌르기)
   * - Frame 3 (0,1): 후면·회전 대각선 강타 (3타 Swing/Recovery & 후방 공격)
   * - Frame 4 (1,1): 방패 방어 태세 / 무적 대시 자세 (Dash & Parry Recovery)
   * - Frame 5 (2,1): Q 방패 패링 밀치기 & 1타 광역 횡베기 피니시 (Parry Active & 1타 Finish)
   */
  private renderCombatActionKeyframe(
    ctx: CanvasRenderingContext2D,
    cw: number,
    ch: number,
    player: PlayerEntity
  ): void {
    const cosA = Math.cos(player.facingAngle);
    const sinA = Math.sin(player.facingAngle);
    const flipLeft = cosA < -0.15;
    const isBackAim = sinA < -0.25;

    let frameIdx = 0;
    let lungeX = 0;
    let lungeY = 0;
    let tiltRad = 0;

    if (player.state === 'dash') {
      frameIdx = 4; // 방패 방어 돌진 태세
      lungeX = 18;
      lungeY = -12;
      tiltRad = 0.08;
    } else if (player.state === 'parry_active') {
      frameIdx = 5; // Q 방패 패링 밀치기 (방패를 전방으로 강하게 내밀고 창을 뒤로 젖힌 포즈!)
      lungeX = 24;
      lungeY = -8;
    } else if (player.state === 'parry_recovery') {
      frameIdx = 4; // 방패 방어 자세
    } else if (player.comboStep === 1) {
      // 1타: 횡베기 (Frame 0 준비 -> Frame 1 중단 가르기 -> Frame 5 광역 베기 피니시)
      if (player.state === 'spear_windup') {
        frameIdx = 0;
        lungeX = -16;
        tiltRad = -0.06;
      } else if (player.state === 'spear_swing') {
        frameIdx = isBackAim ? 3 : 1;
        lungeX = 28;
        tiltRad = 0.08;
      } else {
        frameIdx = 5;
        lungeX = 16;
      }
    } else if (player.comboStep === 2) {
      // 2타: 직선 롱리치 찌르기 (Frame 1 창 수평 조준 -> Frame 2 전방 풀 익스텐션 돌진 찌르기!)
      if (player.state === 'spear_windup') {
        frameIdx = 1;
        lungeX = -22;
      } else if (player.state === 'spear_swing') {
        frameIdx = 2;
        lungeX = 48;
        lungeY = sinA * 24;
        tiltRad = 0.09;
      } else {
        frameIdx = 2;
        lungeX = 22;
      }
    } else {
      // 3타: 도약 회전 강타 (Frame 0 도약 준비 -> Frame 3 후면/회전 대각선 내려찍기 강타 -> Frame 5 피니시)
      if (player.state === 'spear_windup') {
        frameIdx = 0;
        lungeY = -34;
        tiltRad = -0.1;
      } else if (player.state === 'spear_swing') {
        frameIdx = 3;
        lungeX = 36;
        lungeY = 14;
        tiltRad = 0.14;
      } else {
        frameIdx = 5;
        lungeX = 18;
      }
    }

    const frameCanvas = this.attackCells[frameIdx] || this.attackCells[0];

    ctx.save();
    const scale = 1.12;
    ctx.translate(
      cw * 0.5 + (flipLeft ? -lungeX : lungeX),
      ch * 0.54 + lungeY
    );
    if (flipLeft) {
      ctx.scale(-scale, scale);
    } else {
      ctx.scale(scale, scale);
    }
    ctx.rotate(tiltRad);
    ctx.translate(-this.AW * 0.5, -this.AH * 0.52);

    ctx.drawImage(frameCanvas, 0, 0);

    // Q 방패 패링 시 태양 방패 전면에 황금빛 아이기스 충격파 발광 추가
    if (player.state === 'parry_active') {
      const g = ctx.createRadialGradient(385, 255, 10, 385, 255, 135);
      g.addColorStop(0, 'rgba(254, 249, 195, 0.92)');
      g.addColorStop(0.5, 'rgba(250, 204, 21, 0.5)');
      g.addColorStop(1, 'rgba(250, 204, 21, 0)');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(385, 255, 135, 0, Math.PI * 2);
      ctx.fill();
    }

    ctx.restore();
    this.applyHitFlash(ctx, cw, ch, player);
  }

  private applyHitFlash(
    ctx: CanvasRenderingContext2D,
    cw: number,
    ch: number,
    player: PlayerEntity
  ): void {
    if (player.hitFlashTimer > 0) {
      ctx.save();
      ctx.globalCompositeOperation = 'source-atop';
      ctx.fillStyle = 'rgba(255, 255, 255, 0.72)';
      ctx.fillRect(0, 0, cw, ch);
      ctx.restore();
    }
  }

  private drawDirectionalBowOverlay(
    ctx: CanvasRenderingContext2D,
    cx: number,
    cy: number,
    facingAngle: number,
    bowCharge: number
  ): void {
    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(facingAngle);

    const pullX = -18 - bowCharge * 48;

    ctx.strokeStyle = '#78350f';
    ctx.lineWidth = 9;
    ctx.beginPath();
    ctx.arc(28, 0, 82, -Math.PI * 0.44, Math.PI * 0.44);
    ctx.stroke();
    ctx.strokeStyle = '#facc15';
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.strokeStyle = '#e0f2fe';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.moveTo(42, -80);
    ctx.lineTo(pullX, 0);
    ctx.lineTo(42, 80);
    ctx.stroke();

    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(pullX, 0);
    ctx.lineTo(pullX + 135, 0);
    ctx.stroke();

    const tipX = pullX + 135;
    const glowR = 28 + bowCharge * 42;
    const g = ctx.createRadialGradient(tipX, 0, 4, tipX, 0, glowR);
    g.addColorStop(0, 'rgba(255, 255, 255, 0.98)');
    g.addColorStop(0.45, 'rgba(56, 189, 248, 0.75)');
    g.addColorStop(1, 'rgba(56, 189, 248, 0)');
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.arc(tipX, 0, glowR, 0, Math.PI * 2);
    ctx.fill();

    ctx.restore();
  }

  private drawPivotedLayer(
    ctx: CanvasRenderingContext2D,
    layer: HTMLCanvasElement,
    pivotX: number,
    pivotY: number,
    offsetX: number,
    offsetY: number,
    angleRad: number
  ): void {
    ctx.save();
    ctx.translate(pivotX + offsetX, pivotY + offsetY);
    ctx.rotate(angleRad);
    ctx.translate(-pivotX, -pivotY);
    ctx.drawImage(layer, 0, 0);
    ctx.restore();
  }
}
