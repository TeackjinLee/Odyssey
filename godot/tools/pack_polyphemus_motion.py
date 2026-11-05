#!/usr/bin/env python3
"""거인 대기4·걷기6프레임 5방향 원본을 8방향 후보와 GIF 미리보기로 묶는다."""
import argparse
import json
from pathlib import Path
from statistics import median

from PIL import Image

FACINGS = ['E', 'SE', 'S', 'NE', 'N']
ORDER = ['E', 'SE', 'S', 'SW', 'W', 'NW', 'N', 'NE']
MIRROR = {'SW': 'SE', 'W': 'E', 'NW': 'NE'}
FRAME, ANCHOR = 320, (159.5, 292)
ANIMS = {'idle': (4, 4), 'walk': (6, 6)}


def read(path, count):
    im = Image.open(path).convert('RGBA')
    if im.width < count*32 or im.height < 5*32 or im.getchannel('A').getextrema()[0] != 0:
        raise ValueError(f'{path}: 프레임 열 수와 실제 투명 배경을 확인해야 함')
    # 생성기가 요청 크기와 다른 PNG를 줄 수 있어 원본 크기를 바꾸지 않고
    # 전체 폭·높이에 비례한 반올림 경계로 나눈다.
    cw, ch = im.width / count, im.height / 5
    cells, boxes, issues = {}, {}, []
    for row, direction in enumerate(FACINGS):
        cells[direction], boxes[direction] = [], []
        for col in range(count):
            cell = im.crop((round(col*cw), round(row*ch), round((col+1)*cw), round((row+1)*ch)))
            b = cell.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
            if b is None:
                raise ValueError(f'{path}: {direction} {col+1} 빈 칸')
            if b[0] < 3 or b[1] < 3 or b[2] > cell.width-3 or b[3] > cell.height-3:
                issues.append(f'{direction} {col+1}: 칸 경계 검수 필요 {b}')
            cells[direction].append(cell)
            boxes[direction].append(b)
    return cells, boxes, issues, cw, ch


def pack(idle, walk, out):
    target = out / 'directions'
    target.mkdir(parents=True, exist_ok=True)
    preview = out / 'preview'
    preview.mkdir(exist_ok=True)
    all_frames, review = {}, {'status': 'candidate', 'game_registered': False, 'anims': {}}
    for name, source in [('idle', idle), ('walk', walk)]:
        count, fps = ANIMS[name]
        cells, boxes, issues, cw, ch = read(source, count)
        scale = 156 / median(b[3]-b[1] for row in boxes.values() for b in row)
        frames = {}
        baselines = {d: median(b[3] for b in boxes[d]) for d in FACINGS}
        for direction in FACINGS:
            frames[direction] = []
            for i, (cell, b) in enumerate(zip(cells[direction], boxes[direction])):
                # 프레임마다 위치/크기를 재정렬하지 않는다. 한 동작 공통 배율·방향별 공통 바닥 기준.
                sprite = cell.crop(b).resize((max(1, round((b[2]-b[0])*scale)),
                                             max(1, round((b[3]-b[1])*scale))), Image.Resampling.NEAREST)
                pos = (round(ANCHOR[0]+(b[0]-cell.width/2)*scale), round(ANCHOR[1]+(b[1]-baselines[direction])*scale))
                if min(pos) < 0 or pos[0]+sprite.width > FRAME or pos[1]+sprite.height > FRAME:
                    raise ValueError(f'{name} {direction} {i+1}: 출력 칸을 넘음')
                canvas = Image.new('RGBA', (FRAME, FRAME))
                canvas.alpha_composite(sprite, pos)
                frames[direction].append(canvas)
        for direction, original in MIRROR.items():
            frames[direction] = [f.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for f in frames[original]]
        for direction in ORDER:
            strip = Image.new('RGBA', (FRAME*count, FRAME))
            for i, frame in enumerate(frames[direction]):
                strip.paste(frame, (FRAME*i, 0))
            strip.save(target/f'{name}_{direction}.png')
        gif = []
        for i in range(count):
            canvas = Image.new('RGBA', (192*5, 208), '#252c34')
            for j, direction in enumerate(FACINGS):
                canvas.alpha_composite(frames[direction][i].crop((64, 104, 256, 312)), (192*j, 0))
            gif.append(canvas.convert('RGB'))
        gif[0].save(preview/f'{name}.gif', save_all=True, append_images=gif[1:], duration=round(1000/fps), loop=0, disposal=2)
        all_frames[name] = frames
        review['anims'][name] = {'source': str(source), 'source_cell': [cw, ch], 'frames': count, 'fps': fps,
                                'source_canvas': [round(cw*count), round(ch*5)],
                                'scale': scale, 'baselines': baselines, 'issues': issues,
                                'source_bounds': {d: [list(b) for b in boxes[d]] for d in FACINGS},
                                'foot_sliding_verified': False, 'facing_consistency_verified': False}
    sheet = Image.new('RGBA', (FRAME*10, FRAME*8))
    for row, direction in enumerate(ORDER):
        for name, start in [('idle', 0), ('walk', 4)]:
            for i, frame in enumerate(all_frames[name][direction]):
                sheet.paste(frame, ((start+i)*FRAME, row*FRAME))
    sheet.save(out/'polyphemus.png')
    meta = {'frame': [FRAME, FRAME], 'anchor': list(ANCHOR), 'dirs': 8, 'scale': 1,
            'anims': {'idle': {'start': 0, 'frames': 4, 'fps': 4, 'loop': True},
                      'walk': {'start': 4, 'frames': 6, 'fps': 6, 'loop': True}}}
    (out/'polyphemus.json').write_text(json.dumps(meta, indent=2)+'\n')
    (out/'review.json').write_text(json.dumps(review, ensure_ascii=False, indent=2)+'\n')
    print('대기4·걷기6, 8방향 후보·GIF 저장:', out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('idle', type=Path)
    parser.add_argument('walk', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    pack(args.idle, args.walk, args.out)
