import { Vec2 } from '../types/combat';

export class InputManager {
  private keys = new Set<string>();
  public mouseNDC = { x: 0, y: 0 };
  public aimWorldPos: Vec2 = { x: 0, z: 1 };

  public leftClickJustPressed = false;
  public leftMouseDown = false;
  public rightMouseDown = false;
  public rightClickJustReleased = false;

  public dashJustPressed = false;
  public parryJustPressed = false;
  public boonJustPressed = false;
  public respawnJustPressed = false;

  constructor(canvas: HTMLElement) {
    window.addEventListener('keydown', (e) => {
      const code = e.code;
      if (!this.keys.has(code)) {
        if (code === 'Space') this.dashJustPressed = true;
        if (code === 'KeyQ') this.parryJustPressed = true;
        if (code === 'KeyE') this.boonJustPressed = true;
        if (code === 'KeyR') this.respawnJustPressed = true;
      }
      this.keys.add(code);
      if (code === 'Space') {
        e.preventDefault();
      }
    });

    window.addEventListener('keyup', (e) => {
      this.keys.delete(e.code);
    });

    window.addEventListener('blur', () => {
      this.keys.clear();
      this.leftMouseDown = false;
      this.rightMouseDown = false;
    });

    canvas.addEventListener('mousemove', (e) => {
      const rect = canvas.getBoundingClientRect();
      this.mouseNDC.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      this.mouseNDC.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    });

    canvas.addEventListener('mousedown', (e) => {
      if (e.button === 0) {
        this.leftMouseDown = true;
        this.leftClickJustPressed = true;
      } else if (e.button === 2) {
        this.rightMouseDown = true;
      }
    });

    window.addEventListener('mouseup', (e) => {
      if (e.button === 0) {
        this.leftMouseDown = false;
      } else if (e.button === 2) {
        if (this.rightMouseDown) {
          this.rightClickJustReleased = true;
        }
        this.rightMouseDown = false;
      }
    });

    canvas.addEventListener('contextmenu', (e) => {
      e.preventDefault();
    });
  }

  /**
   * 화면 기준 WASD 8방향 이동 벡터 반환
   * W = 화면 위쪽(-Z), S = 화면 아래쪽(+Z), A = 화면 왼쪽(-X), D = 화면 오른쪽(+X)
   */
  public getMoveVector(): Vec2 {
    let x = 0;
    let z = 0;
    if (this.keys.has('KeyW') || this.keys.has('ArrowUp')) z -= 1;
    if (this.keys.has('KeyS') || this.keys.has('ArrowDown')) z += 1;
    if (this.keys.has('KeyA') || this.keys.has('ArrowLeft')) x -= 1;
    if (this.keys.has('KeyD') || this.keys.has('ArrowRight')) x += 1;

    const len = Math.hypot(x, z);
    if (len > 0) {
      x /= len;
      z /= len;
    }
    return { x, z };
  }

  public consumeFrameTriggers(): void {
    this.leftClickJustPressed = false;
    this.rightClickJustReleased = false;
    this.dashJustPressed = false;
    this.parryJustPressed = false;
    this.boonJustPressed = false;
    this.respawnJustPressed = false;
  }
}
