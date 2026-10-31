import { AudioSynth } from './core/AudioSynth';
import { InputManager } from './core/InputManager';
import { WorldSimulation } from './combat/WorldSimulation';
import { SceneRenderer25D } from './rendering/SceneRenderer25D';
import { HudController } from './ui/HudController';
import { PerformanceMetrics } from './types/combat';

function bootstrap(): void {
  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (!canvas) {
    throw new Error('Canvas #game-canvas not found');
  }

  const audio = new AudioSynth();
  const input = new InputManager(canvas);
  const world = new WorldSimulation(audio);
  const renderer = new SceneRenderer25D(canvas, world);
  const hud = new HudController(world, renderer);

  let lastTime = performance.now();
  let frameCount = 0;
  let fpsAccumTime = 0;
  let frameTimeAccum = 0;
  let minInstantFps = 60;

  const perfMetrics: PerformanceMetrics = {
    fps: 60,
    frameTimeMs: 16.67,
    minFps: 60,
  };

  function gameLoop(now: number): void {
    const rawDeltaMs = Math.max(0.1, now - lastTime);
    lastTime = now;

    const dt = Math.min(rawDeltaMs / 1000, 0.05);

    frameCount += 1;
    fpsAccumTime += rawDeltaMs;
    frameTimeAccum += rawDeltaMs;
    const instantFps = Math.round(1000 / rawDeltaMs);
    if (instantFps < minInstantFps && frameCount > 10) {
      minInstantFps = instantFps;
    }

    if (fpsAccumTime >= 400) {
      perfMetrics.fps = Math.round((frameCount * 1000) / fpsAccumTime);
      perfMetrics.frameTimeMs = frameTimeAccum / frameCount;
      perfMetrics.minFps = minInstantFps;
      frameCount = 0;
      fpsAccumTime = 0;
      frameTimeAccum = 0;
      minInstantFps = perfMetrics.fps;
    }

    input.aimWorldPos = renderer.updateMouseGroundPosition(input.mouseNDC);
    world.update(dt, input);
    renderer.render(world, dt);
    hud.update(world, renderer, perfMetrics, dt);
    input.consumeFrameTriggers();

    requestAnimationFrame(gameLoop);
  }

  requestAnimationFrame(gameLoop);
}

bootstrap();
