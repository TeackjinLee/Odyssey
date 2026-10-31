import * as THREE from 'three';
import { PlayerEntity, Vec2 } from '../../types/combat';
import { AvatarMotion } from './AvatarMotion';
import { GltfOdysseus } from './GltfOdysseus';
import { OdysseusModel } from './OdysseusModel';
import { PoseDriver } from './PoseDriver';

/**
 * 렌더러가 쓰는 오디세우스 하나.
 * 처음엔 도형 모델을 보여 주고, public/assets/models/odysseus.glb를 불러오면 그 모델로 바꾼다.
 * 파일이 없거나 불러오지 못하면 도형 모델을 계속 쓴다.
 */
export class OdysseusAvatar {
  private readonly motion = new AvatarMotion();
  private readonly poses = new PoseDriver();
  private readonly shape: OdysseusModel;
  private gltf: GltfOdysseus | null = null;

  constructor(scene: THREE.Scene) {
    this.shape = new OdysseusModel(scene);
    GltfOdysseus.load(scene)
      .then((model) => {
        this.gltf = model;
        this.shape.setVisible(false);
        console.info('[Odysseus GLB] 새 모델로 바꿈');
      })
      .catch((err: unknown) => {
        console.info('[Odysseus GLB] 모델 파일이 없거나 불러오지 못해 도형 모델을 씀:', err instanceof Error ? err.message : err);
      });
  }

  /** 이번 프레임에 땅을 디딘 발 위치 (먼지 효과용) */
  public get footsteps(): Vec2[] {
    return this.motion.footsteps;
  }

  /** dt가 0이면(히트스톱) 모든 움직임이 멈춤 */
  public update(p: PlayerEntity, dt: number): void {
    if (dt <= 0) {
      this.motion.footsteps.length = 0;
      return;
    }
    this.motion.update(p, dt);
    this.poses.update(p, this.motion, dt);
    if (this.gltf) this.gltf.update(p, this.motion, this.poses, dt);
    else this.shape.update(p, this.motion, this.poses, dt);
  }
}
