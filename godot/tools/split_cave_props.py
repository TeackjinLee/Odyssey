#!/usr/bin/env python3
"""투명 동굴 소품 4×3 시트를 검수 후보 PNG 12개로 나눈다. 게임에는 등록하지 않는다."""
import argparse
import json
from pathlib import Path

from PIL import Image

GROUPS = [
    (['wine_closed', 'wine_open'], 26),
    (['stake_cold', 'stake_hot'], 104),
    (['hearth_cold', 'hearth_lit'], 88),
    (['boulder_closed', 'boulder_rolled'], 112),
    (['pen_gate_closed', 'pen_gate_open'], 112),
    (['giant_bed'], 168),
    (['giant_club'], 88),
]


def split(source, out):
    im = Image.open(source).convert('RGBA')
    if im.size != (1536, 1024):
        raise ValueError(f'1536×1024 원본이 필요함: {im.size}')
    if im.getchannel('A').getextrema()[0] != 0:
        raise ValueError('실제 투명 배경이 없음. 이미지 생성 도구로 배경을 다시 제거해야 함')
    out.mkdir(parents=True, exist_ok=True)
    manifest = {'source': str(source), 'status': 'candidate', 'camera': 'isometric30', 'items': {}}
    index = 0
    for names, width in GROUPS:
        cells, boxes = [], []
        for name in names:
            x, y = index % 4 * 384, index // 4 * 341
            cell = im.crop((x, y, x + 384, y + 341))
            # 미세한 반투명 픽셀이 칸 전체를 차지한다고 오인하지 않도록
            # 경계 검출에만 불투명 중심부를 사용하고 저장할 RGBA는 보존한다.
            box = cell.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
            if box is None:
                raise ValueError(f'{name}: 빈 칸')
            if box[0] < 4 or box[1] < 4 or box[2] > 380 or box[3] > 337:
                raise ValueError(f'{name}: 칸 경계에 닿은 그림 {box}, 잘림 검수 필요')
            cells.append(cell)
            boxes.append(box)
            index += 1
        # 상태 전환 때 잘라내기·배율 차이로 튀지 않도록 두 상태의 합집합을 사용한다.
        box = (min(b[0] for b in boxes), min(b[1] for b in boxes),
               max(b[2] for b in boxes), max(b[3] for b in boxes))
        k = width / (box[2] - box[0])
        size = (width, max(1, round((box[3] - box[1]) * k)))
        anchor = [round((192 - box[0]) * k), size[1] - 1]
        for name, cell, bounds in zip(names, cells, boxes):
            cell.crop(box).resize(size, Image.Resampling.NEAREST).save(out / f'{name}.png')
            manifest['items'][name] = {'file': f'{name}.png', 'size': list(size), 'anchor': anchor,
                                       'cell_alpha_bounds': list(bounds), 'group_crop': list(box),
                                       'needs_visual_registration_check': True}
    (out / 'props.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(f'{len(manifest["items"])}개 후보를 {out}에 저장')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    split(args.source, args.out)
