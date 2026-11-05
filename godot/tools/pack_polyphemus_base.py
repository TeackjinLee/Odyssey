#!/usr/bin/env python3
"""거인 5방향 투명 기본 시트 → 방향별 원본과 8방향 idle 후보. 게임 자동 등록 없음."""
import argparse
import json
from pathlib import Path
from statistics import median

from PIL import Image

CELLS = {'E': (0, 0), 'SE': (1, 0), 'S': (2, 0), 'NE': (0, 1), 'N': (1, 1)}
ORDER = ['E', 'SE', 'S', 'SW', 'W', 'NW', 'N', 'NE']
MIRROR = {'SW': 'SE', 'W': 'E', 'NW': 'NE'}
FRAME, ANCHOR, HEIGHT = 320, (159.5, 292), 156


def pack(source, out):
    im = Image.open(source).convert('RGBA')
    if im.size != (1536, 1024) or im.getchannel('A').getextrema()[0] != 0:
        raise ValueError('실제 투명 배경의 1536×1024 원본이 필요함')
    cells, boxes = {}, {}
    for name, (col, row) in CELLS.items():
        cell = im.crop((col*512, row*512, (col+1)*512, (row+1)*512))
        box = cell.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
        if box is None:
            raise ValueError(f'{name}: 빈 방향')
        if min(box[:2]) < 4 or max(box[2:]) > 508:
            raise ValueError(f'{name}: 칸 경계 잘림 검수 필요 {box}')
        cells[name], boxes[name] = cell, box
    blank = im.crop((1024, 512, 1536, 1024)).getchannel('A')
    if blank.point(lambda a: 255 if a >= 128 else 0).getbbox():
        raise ValueError('6번째 칸은 비워야 함')
    scale = HEIGHT / median(b[3] - b[1] for b in boxes.values())
    source_dir, game_dir = out / 'directions', out / 'game'
    source_dir.mkdir(parents=True, exist_ok=True)
    game_dir.mkdir(exist_ok=True)
    normalized = {}
    review = {'status': 'candidate', 'target_body_height': HEIGHT, 'scale': scale,
              'source_bounds': {n: list(b) for n, b in boxes.items()}, 'directions': ORDER,
              'mirrored': MIRROR, 'game_registered': False, 'interaction_points_verified': False}
    for name, cell in cells.items():
        cell.save(source_dir / f'polyphemus_{name}.png')
        # 모든 방향에 같은 배율을 적용하며, 발/곤봉을 포함한 하단 기준을 맞춘다.
        b = boxes[name]
        sprite = cell.crop(b).resize((max(1, round((b[2]-b[0])*scale)),
                                     max(1, round((b[3]-b[1])*scale))), Image.Resampling.NEAREST)
        pos = (round(ANCHOR[0] + (b[0]-256)*scale), ANCHOR[1] - sprite.height)
        if min(pos) < 0 or pos[0]+sprite.width > FRAME or pos[1]+sprite.height > FRAME:
            raise ValueError(f'{name}: 출력 칸을 넘음')
        canvas = Image.new('RGBA', (FRAME, FRAME))
        canvas.alpha_composite(sprite, pos)
        normalized[name] = canvas
    for name, original in MIRROR.items():
        normalized[name] = normalized[original].transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    sheet = Image.new('RGBA', (FRAME, FRAME*8))
    for row, name in enumerate(ORDER):
        normalized[name].save(game_dir / f'polyphemus_{name}.png')
        sheet.paste(normalized[name], (0, FRAME*row))
    sheet.save(game_dir / 'polyphemus.png')
    meta = {'frame': [FRAME, FRAME], 'anchor': list(ANCHOR), 'dirs': 8, 'scale': 1.0,
            'anims': {'idle': {'start': 0, 'frames': 1, 'fps': 1, 'loop': True}}}
    (game_dir/'polyphemus.json').write_text(json.dumps(meta, indent=2)+'\n')
    (out/'review.json').write_text(json.dumps(review, ensure_ascii=False, indent=2)+'\n')
    print('5방향 원본·8방향 정지 포즈 후보 저장:', out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    pack(args.source, args.out)
