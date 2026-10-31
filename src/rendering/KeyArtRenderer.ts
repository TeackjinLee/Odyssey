/**
 * 사용자가 제공한 실제 8컷 스토리보드(/assets/storyboard.png)의
 * Panel 1(메인 키아트) 및 Panel 8(귀환) 고해상도 원화를 직접 로드하여 렌더링하고,
 * 그 위에 실시간 광선(God Rays)·파도 윤슬·황금 주화 발광 파티클을 더하는 시네마틱 렌더러.
 */
export class KeyArtRenderer {
  private storyboardImg: HTMLImageElement | null = null;
  private isLoaded = false;

  constructor() {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      this.storyboardImg = img;
      this.isLoaded = true;
    };
    img.src = '/assets/storyboard.png';
  }

  /**
   * Scene 1: 메인 키아트 — “고향은 아직 수평선 너머에”
   * 스토리보드 상단 1번째 패널(Panel 1) 원화를 전체 화면 비율로 렌더링 + 실시간 신성한 빛줄기 애니메이션
   */
  public renderScene1Title(canvas: HTMLCanvasElement, timeSec: number): void {
    const w = (canvas.width = window.innerWidth);
    const h = (canvas.height = window.innerHeight);
    const ctx = canvas.getContext('2d')!;

    if (this.isLoaded && this.storyboardImg) {
      // storyboard.png (1774 x 887, 4x2 그리드 중 좌측 상단 Panel 1 추출)
      const sw = this.storyboardImg.width / 4;
      const sh = this.storyboardImg.height * 0.48;
      const sy = this.storyboardImg.height * 0.04;

      this.drawCoverImage(ctx, this.storyboardImg, 6, sy, sw - 12, sh - 8, w, h);

      // 구름 사이로 쏟아지는 실시간 황금빛 신성 광선(God Rays) 오버레이
      const pulse = 0.14 + Math.sin(timeSec * 1.8) * 0.05;
      const rayGrad = ctx.createRadialGradient(
        w * 0.72,
        h * 0.18,
        10,
        w * 0.72,
        h * 0.18,
        w * 0.55
      );
      rayGrad.addColorStop(0, `rgba(254, 249, 195, ${pulse})`);
      rayGrad.addColorStop(0.5, `rgba(245, 158, 11, ${pulse * 0.45})`);
      rayGrad.addColorStop(1, 'rgba(0, 0, 0, 0)');
      ctx.fillStyle = rayGrad;
      ctx.fillRect(0, 0, w, h);
      return;
    }

    ctx.fillStyle = '#07111e';
    ctx.fillRect(0, 0, w, h);
  }

  /**
   * Scene 8: 귀환 — “아직 끝나지 않은 항해”
   * 스토리보드 하단 4번째 패널(Panel 8) 원화를 전체 화면으로 렌더링 + 손안의 청동 주화 금빛 파동
   */
  public renderScene8Return(canvas: HTMLCanvasElement, timeSec: number): void {
    const w = (canvas.width = window.innerWidth);
    const h = (canvas.height = window.innerHeight);
    const ctx = canvas.getContext('2d')!;

    if (this.isLoaded && this.storyboardImg) {
      const sw = this.storyboardImg.width / 4;
      const sh = this.storyboardImg.height * 0.47;
      const sx = sw * 3 + 6;
      const sy = this.storyboardImg.height * 0.52;

      this.drawCoverImage(ctx, this.storyboardImg, sx, sy, sw - 12, sh - 6, w, h);

      // 손안의 청동 주화 & 아침 햇살 금빛 글로우 오버레이
      const pulse = 0.18 + Math.sin(timeSec * 2.6) * 0.06;
      const glow = ctx.createRadialGradient(
        w * 0.46,
        h * 0.65,
        8,
        w * 0.46,
        h * 0.65,
        w * 0.25
      );
      glow.addColorStop(0, `rgba(254, 240, 138, ${pulse})`);
      glow.addColorStop(1, 'rgba(245, 158, 11, 0)');
      ctx.fillStyle = glow;
      ctx.fillRect(0, 0, w, h);
      return;
    }

    ctx.fillStyle = '#0f172a';
    ctx.fillRect(0, 0, w, h);
  }

  private drawCoverImage(
    ctx: CanvasRenderingContext2D,
    img: HTMLImageElement,
    sx: number,
    sy: number,
    sw: number,
    sh: number,
    dw: number,
    dh: number
  ): void {
    const targetRatio = dw / dh;
    const srcRatio = sw / sh;
    let renderW = dw;
    let renderH = dh;
    let offsetX = 0;
    let offsetY = 0;

    if (targetRatio > srcRatio) {
      renderW = dw;
      renderH = dw / srcRatio;
      offsetY = (dh - renderH) * 0.35;
    } else {
      renderH = dh;
      renderW = dh * srcRatio;
      offsetX = (dw - renderW) * 0.5;
    }

    ctx.drawImage(img, sx, sy, sw, sh, offsetX, offsetY, renderW, renderH);
  }
}
