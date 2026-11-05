#!/usr/bin/env python3
"""투명 동굴 환경 4×3 시트 두 장 → 바닥 12종·구조물 12종 후보. 게임 자동 등록 없음."""
import argparse
import json
from pathlib import Path

from PIL import Image

PROPS = ['wall_ne', 'wall_nw', 'wall_ne_cracked', 'wall_nw_cracked',
         'corner_inner', 'corner_outer', 'cover_rock', 'stalagmites',
         'fence_ne', 'fence_nw', 'cheese_rack', 'milk_amphorae']
GROUPS = [([0, 1, 2, 3], 64), ([4, 5], 96), ([6], 56), ([7], 44),
          ([8, 9], 64), ([10], 52), ([11], 30)]


def read_cells(path):
    im = Image.open(path).convert('RGBA')
    if im.size != (1536, 1024) or im.getchannel('A').getextrema()[0] != 0:
        raise ValueError(f'{path}: 실제 투명 배경의 1536×1024 PNG가 필요함')
    cells, bounds = [], []
    for i in range(12):
        x, y = i % 4 * 384, i // 4 * 341
        cell = im.crop((x, y, x + 384, y + 341))
        box = cell.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
        if box is None:
            raise ValueError(f'{path}: {i + 1}번 칸 비어 있음')
        if box[0] < 4 or box[1] < 4 or box[2] > 380 or box[3] > 337:
            raise ValueError(f'{path}: {i + 1}번 칸 경계 잘림 검수 필요 {box}')
        cells.append(cell)
        bounds.append(box)
    return cells, bounds


def split(floor_source, structure_source, out):
    floors, fb = read_cells(floor_source)
    structures, sb = read_cells(structure_source)
    out.mkdir(parents=True, exist_ok=True)
    tiles, props = out / 'tiles', out / 'props'
    tiles.mkdir(exist_ok=True)
    props.mkdir(exist_ok=True)
    atlas = Image.new('RGBA', (256, 96))
    meta = {'status': 'candidate', 'tile': [64, 32], 'rows': ['cave_stone', 'cave_dust', 'cave_straw'],
            'variants': 4, 'atlas': 'floor_atlas.png', 'tiles': {}, 'props': {},
            'seams_verified': False, 'game_registered': False}
    for i, (cell, box) in enumerate(zip(floors, fb)):
        name = f'{meta["rows"][i // 4]}_{i % 4}'
        tile = cell.crop(box).resize((64, 32), Image.Resampling.NEAREST)
        tile.save(tiles / f'{name}.png')
        atlas.paste(tile, (i % 4 * 64, i // 4 * 32))
        meta['tiles'][name] = {'file': f'tiles/{name}.png', 'source_alpha_bounds': list(box)}
    atlas.save(out / 'floor_atlas.png')
    for indexes, width in GROUPS:
        box = (min(sb[i][0] for i in indexes), min(sb[i][1] for i in indexes),
               max(sb[i][2] for i in indexes), max(sb[i][3] for i in indexes))
        scale = width / (box[2] - box[0])
        size = (width, max(1, round((box[3] - box[1]) * scale)))
        for i in indexes:
            name = PROPS[i]
            structures[i].crop(box).resize(size, Image.Resampling.NEAREST).save(props / f'{name}.png')
            meta['props'][name] = {'file': f'props/{name}.png', 'size': list(size),
                                   'anchor': [round((192 - box[0]) * scale), size[1] - 1],
                                   'source_alpha_bounds': list(sb[i]), 'group_crop': list(box),
                                   'connection_points_verified': False}
    (out / 'environment.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2) + '\n')
    print('바닥12종·바닥 아틀라스·구조물12종·후보 메타데이터 저장:', out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('floor_source', type=Path)
    parser.add_argument('structure_source', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    split(args.floor_source, args.structure_source, args.out)
