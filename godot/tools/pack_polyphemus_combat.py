#!/usr/bin/env python3
"""거인 공격2종(각6프레임·5방향)을8방향 시트·GIF로 묶는다. 판정 코드는 변경하지 않는다."""
import argparse
import json
from pathlib import Path
from statistics import median

import numpy as np
from PIL import Image

from pack_polyphemus_motion import FACINGS, ORDER, MIRROR, FRAME, ANCHOR


def cuts(profile, count, length):
    """명목 격자선 근처(±60px)에서 불투명 픽셀이 없는 가장 가까운 빈 줄의 가운데를 자르는 선으로 쓴다."""
    out = [0]
    for k in range(1, count):
        c = round(k*length/count)
        empty = [y for y in range(max(0, c-60), min(length, c+60)) if profile[y] == 0]
        if not empty:
            raise ValueError(f'격자선 {c} 근처에 빈 줄이 없음, 인물이 이웃 칸과 겹침')
        runs, start = [], empty[0]
        for a, b in zip(empty, empty[1:]+[None]):
            if b != a+1:
                runs.append((start, a))
                start = b
        lo, hi = min(runs, key=lambda r: abs((r[0]+r[1])/2-c))
        out.append((lo+hi)//2)
    return out+[length]


def read(path, count):
    """생성기 격자는 인물이 칸 선을 조금씩 넘으므로 균등 분할 대신 빈 줄로 자른다.
    알파128 미만(붉은·초록 매트 잔여)은 알파0으로 지운다."""
    im = Image.open(path).convert('RGBA')
    a = np.array(im)
    a[a[..., 3] < 128] = 0
    im = Image.fromarray(a)
    solid = a[..., 3] > 0
    rows = cuts(solid.sum(axis=1), 5, im.height)
    cw, ch = im.width/count, im.height/5
    cells, boxes, issues = {}, {}, []
    for r, d in enumerate(FACINGS):
        band = solid[rows[r]:rows[r+1]]
        cols = cuts(band.sum(axis=0), count, im.width)
        cells[d], boxes[d] = [], []
        for c in range(count):
            # 칸 좌표는 명목 격자 중심을 x 기준으로 쓰도록 명목 칸 폭으로 맞춰 둔다.
            x0 = round(c*cw)
            cell = Image.new('RGBA', (round(cw)+200, rows[r+1]-rows[r]))
            piece = im.crop((cols[c], rows[r], cols[c+1], rows[r+1]))
            cell.alpha_composite(piece, (cols[c]-x0+100, 0))
            b = cell.getbbox()
            if b is None:
                raise ValueError(f'{path}: {d} {c+1} 빈 칸')
            if b[1] < 2 or b[3] > cell.height-2:
                issues.append(f'{d} {c+1}: 줄 경계에 닿음 {b}')
            cells[d].append(cell)
            boxes[d].append(b)
    return cells, boxes, issues, cw, ch


def pack(slam, grab, out):
    directions = out / 'directions'
    directions.mkdir(parents=True, exist_ok=True)
    preview = out / 'preview'
    preview.mkdir(exist_ok=True)
    animations, review = {}, {'status': 'candidate', 'game_registered': False, 'damage_implemented': False, 'anims': {}}
    for name, source in [('club_slam', slam), ('grab', grab)]:
        cells, boxes, issues, cw, ch = read(source, 6)
        # 곤봉이 머리 위로 올라가는 공격 전체 높이로 몸을 축소하지 않는다.
        # 모든 방향의 첫 준비 자세만으로 한 동작 공통 배율을 정한다.
        scale = 156 / median(boxes[d][0][3] - boxes[d][0][1] for d in FACINGS)
        baselines = {d: boxes[d][0][3] for d in FACINGS}
        frames = {}
        for d in FACINGS:
            frames[d] = []
            for i, (cell, b) in enumerate(zip(cells[d], boxes[d])):
                sprite = cell.crop(b).resize((max(1, round((b[2]-b[0])*scale)),
                                             max(1, round((b[3]-b[1])*scale))), Image.Resampling.NEAREST)
                pos = (round(ANCHOR[0]+(b[0]-(cw/2+100))*scale), round(ANCHOR[1]+(b[1]-baselines[d])*scale))
                if min(pos) < 0 or pos[0]+sprite.width > FRAME or pos[1]+sprite.height > FRAME:
                    raise ValueError(f'{name} {d} {i+1}: 공격 궤적이 출력 칸을 넘음, 여백 재요청 필요')
                canvas = Image.new('RGBA', (FRAME, FRAME))
                canvas.alpha_composite(sprite, pos)
                frames[d].append(canvas)
        for d, original in MIRROR.items():
            frames[d] = [f.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for f in frames[original]]
        for d in ORDER:
            strip = Image.new('RGBA', (FRAME*6, FRAME))
            for i, frame in enumerate(frames[d]):
                strip.paste(frame, (FRAME*i, 0))
            strip.save(directions/f'{name}_{d}.png')
        # GIF의 마지막은 잠시 유지한다. 실제 동작은 반복하지 않고 idle로 복귀해야 한다.
        gif = []
        for i in range(6):
            canvas = Image.new('RGBA', (FRAME*5, FRAME), '#252c34')
            for j, d in enumerate(FACINGS):
                canvas.alpha_composite(frames[d][i], (FRAME*j, 0))
            gif.append(canvas.convert('RGB'))
        gif[0].save(preview/f'{name}.gif', save_all=True, append_images=gif[1:],
                    duration=[167]*5+[600], loop=0, disposal=2)
        animations[name] = frames
        review['anims'][name] = {'source': str(source), 'source_canvas': [round(cw*6), round(ch*5)],
                                'source_cell': [cw, ch], 'scale_from_ready': scale, 'baselines': baselines,
                                'source_bounds': {d: [list(b) for b in boxes[d]] for d in FACINGS},
                                'issues': issues, 'handedness_verified': False, 'loop': False,
                                'suggested_active_frames_zero_based': [3, 4], 'attack_points_verified': False}
    sheet = Image.new('RGBA', (FRAME*12, FRAME*8))
    for row, d in enumerate(ORDER):
        for name, start in [('club_slam', 0), ('grab', 6)]:
            for i, frame in enumerate(animations[name][d]):
                sheet.paste(frame, ((start+i)*FRAME, row*FRAME))
    sheet.save(out/'polyphemus_combat.png')
    meta = {'frame': [FRAME, FRAME], 'anchor': list(ANCHOR), 'dirs': 8, 'scale': 1,
            'anims': {'club_slam': {'start': 0, 'frames': 6, 'fps': 6, 'loop': False},
                      'grab': {'start': 6, 'frames': 6, 'fps': 6, 'loop': False}}}
    (out/'polyphemus_combat.json').write_text(json.dumps(meta, indent=2)+'\n')
    (out/'review.json').write_text(json.dumps(review, ensure_ascii=False, indent=2)+'\n')
    print('곤봉6·움켜잡기6,8방향 후보·GIF 저장:', out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('club_slam', type=Path)
    parser.add_argument('grab', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    pack(args.club_slam, args.grab, args.out)
