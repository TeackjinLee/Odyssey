#!/usr/bin/env python3
"""폴리페모스 동작 원본들 → 게임 시트 셋(assets/sprites/polyphemus·polyphemus_combat·polyphemus_sleep).

오디세우스처럼 '2배 밀도' 시트(scale 0.5)로 만든다: 원본을 화면 픽셀 크기에 가깝게 줄이므로(곱하기 1 안팎)
예전처럼 작게 줄였다가 다시 2배로 키워 뭉개지지 않는다. 줄일 때는 미리 곱한 알파로 면적 평균(BOX) → 알파를 끊어 픽셀 가장자리를 살린다.

원본 배치 두 가지:
  grid    : 한 장에 cols×rows, 한 줄 = 한 방향(rows 순서 = dirs)
  per_dir : 방향마다 한 장(<폴더>/<동작>_<방향>.png), 그 안에 cols×rows 프레임(왼→오, 위→아래)
칸 경계는 명목 격자선 근처의 빈 줄을 찾아 자른다(원본 인물이 격자선을 조금 넘어도 이웃 조각이 섞이지 않게).

  python3 tools/pack_polyphemus_hd.py <설정 이름: base|v1|v2> [godot 폴더]

base: 동작 그림이 아직 없을 때 — 새 기본 5방향(polyphemus_v2/results/base.png) 한 장으로 정지 시트를 만든다.
      idle(뜬 눈)·idle_shut(감은 눈 — 잠·취함)·idle_wound(찔린 눈 — 날뛰기·더듬기) 세 동작, 움직임은 cyclops.gd가 코드로 준다.
"""
import json
import sys
from pathlib import Path
from statistics import median

from PIL import Image

ORDER = ['E', 'SE', 'S', 'SW', 'W', 'NW', 'N', 'NE']
MIRROR = {'SW': 'SE', 'W': 'E', 'NW': 'NE'}
FACINGS = ['E', 'SE', 'S', 'NE', 'N']
# 게임에서 서 있는 키(시트 픽셀, 화면에선 절반) — 오디세우스 시트 키 120의 약 2.1배
STAND_H = 250
FRAME = 384
ANCHOR = (192, 366)
SLEEP_FRAME = (512, 256)
SLEEP_ANCHOR = (256, 214)
SLEEP_LEN = 330

KIT = 'docs/sprite_request/ch3_kit/'
# 동작: 원본, 배치, 프레임 수, fps, 반복, 배율 기준(median: 전체 중앙 키 / first: 각 방향 첫 장 / width: 가로 길이)
CONFIGS = {
    'v1': {
        'idle': dict(src=KIT + 'polyphemus/motion/results/idle.png', layout='grid', cols=4, rows=5, fps=4, loop=True, ref='median'),
        'walk': dict(src=KIT + 'polyphemus/motion/results/walk.png', layout='grid', cols=6, rows=5, fps=7, loop=True, ref='median'),
        'club_slam': dict(src=KIT + 'polyphemus/combat/results/club_slam.png', layout='grid', cols=6, rows=5, fps=6, loop=False, ref='first'),
        'grab': dict(src=KIT + 'polyphemus/combat/results/grab.png', layout='grid', cols=6, rows=5, fps=6, loop=False, ref='first'),
        'drunk': dict(src=KIT + 'polyphemus/states/results/drunk.png', layout='grid', cols=6, rows=5, fps=5, loop=True, ref='median'),
        'eye_wound': dict(src=KIT + 'polyphemus/states/results/eye_wound.png', layout='grid', cols=6, rows=5, fps=7, loop=False, ref='first'),
        'grope': dict(src=KIT + 'polyphemus/states/results/grope.png', layout='grid', cols=6, rows=5, fps=5, loop=True, ref='median'),
        'sleep': dict(src=KIT + 'polyphemus/states/results/sleep.png', layout='sleep', cols=4, rows=2, fps=2, loop=True, ref='width'),
    },
    'v2': {
        'idle': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=2, rows=2, fps=4, loop=True, ref='median', steady=True),
        # 걷기 fps 4: 걸음 폭에 비해 7은 다리가 땅보다 3배 빨라 제자리 종종걸음처럼 보였다(속도에 맞춰 speed_scale로 빨라짐)
        'walk': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=4, loop=True, ref='median', steady=True),
        'roar': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=2, rows=2, fps=5, loop=False, ref='median'),
        'club_slam': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=6, loop=False, ref='first'),
        'grab': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=6, loop=False, ref='first'),
        'drunk': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=5, loop=True, ref='median', steady=True),
        'eye_wound': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=7, loop=False, ref='first'),
        'grope': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=5, loop=True, ref='median', steady=True),
        # 바위 밀기·끌기: 몸을 숙여 키가 작으므로 걷기와 같은 배율(k_like)
        'push': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=5, loop=True, ref='median', k_like='walk'),
        'pull': dict(src=KIT + 'polyphemus_v2/results', layout='per_dir', cols=3, rows=2, fps=5, loop=True, ref='median', k_like='walk'),
        'sleep': dict(src=KIT + 'polyphemus_v2/results/sleep_S.png', layout='sleep', cols=2, rows=2, fps=2, loop=True, ref='width'),
    },
}
# 시트 묶음: 이름 → 동작들
SHEETS = {'polyphemus': ['idle', 'walk', 'drunk', 'grope', 'roar'],
          'polyphemus_combat': ['club_slam', 'grab', 'eye_wound', 'push', 'pull']}


def opaque(im):
    return im.getchannel('A').point(lambda a: 255 if a >= 128 else 0)


def clean(im):
    """생성기가 남긴 반투명 매트(알파 128 미만)를 지운다"""
    a = im.getchannel('A').point(lambda v: 0 if v < 128 else v)
    im = im.copy()
    im.putalpha(a)
    return im


def cuts(mask, n, axis):
    """명목 경계 근처(±18%)에서 가장 빈 줄을 골라 n칸 경계 목록을 돌려준다"""
    w, h = mask.size
    size = h if axis == 1 else w
    px = mask.load()
    def count(i):
        if axis == 1:
            return sum(1 for x in range(0, w, 2) if px[x, i])
        return sum(1 for y in range(0, h, 2) if px[i, y])
    out = [0]
    step = size / n
    for k in range(1, n):
        nominal = round(k * step)
        span = int(step * 0.18)
        best = min(range(max(1, nominal - span), min(size - 1, nominal + span)), key=lambda i: (count(i), abs(i - nominal)))
        out.append(best)
    out.append(size)
    return out


def split(im, cols, rows):
    im = clean(im.convert('RGBA'))
    mask = opaque(im)
    ys = cuts(mask, rows, 1)
    cells = []
    for r in range(rows):
        band = im.crop((0, ys[r], im.width, ys[r + 1]))
        xs = cuts(opaque(band), cols, 0)
        cells.append([band.crop((xs[c], 0, xs[c + 1], band.height)) for c in range(cols)])
    return cells


def main_body(cell):
    """가장 큰 덩어리 둘레만 남기기 대신: 칸 안 불투명 경계"""
    return opaque(cell).getbbox()


def shrink(sprite, k):
    w, h = max(1, round(sprite.width * k)), max(1, round(sprite.height * k))
    out = sprite.convert('RGBa').resize((w, h), Image.Resampling.BOX if k < 1 else Image.Resampling.NEAREST).convert('RGBA')
    a = out.getchannel('A').point(lambda v: 0 if v < 110 else 255)
    out.putalpha(a)
    return out


def load_anim(name, cfg, root):
    """방향 → [칸 이미지…] (FACINGS 다섯 방향)"""
    if cfg['layout'] == 'grid':
        cells = split(Image.open(root / cfg['src']), cfg['cols'], cfg['rows'])
        return {d: cells[i] for i, d in enumerate(FACINGS)}
    out = {}
    for d in FACINGS:
        p = root / cfg['src'] / f'{name}_{d}.png'
        if not p.exists():
            raise FileNotFoundError(p)
        cells = split(Image.open(p), cfg['cols'], cfg['rows'])
        out[d] = [c for row in cells for c in row]
    return out


def torso_x(sp):
    """몸통(위에서 20~55% 높이) 불투명 칸들의 가로 무게중심"""
    a = opaque(sp)
    y0, y1 = int(sp.height * 0.2), int(sp.height * 0.55)
    xs = [x for y in range(y0, y1, 2) for x in range(0, sp.width, 2) if a.getpixel((x, y))]
    return sum(xs) / len(xs) if xs else sp.width / 2


def place(frames_by_dir, cfg, frame=FRAME, anchor=ANCHOR, target=STAND_H, k=None):
    boxes = {d: [main_body(c) for c in cs] for d, cs in frames_by_dir.items()}
    for d, bs in boxes.items():
        if any(b is None for b in bs):
            raise ValueError(f'{d}: 빈 칸')
    if cfg['ref'] == 'median':
        ref = median(b[3] - b[1] for bs in boxes.values() for b in bs)
    elif cfg['ref'] == 'first':
        ref = median(bs[0][3] - bs[0][1] for bs in boxes.values())
    else:
        ref = median(b[2] - b[0] for bs in boxes.values() for b in bs)
    k = k or target / ref
    # 팔·곤봉을 높이 든 장면이 칸 위·옆을 넘으면 그 동작 전체를 조금 줄여 넣는다(잘리는 것보다 낫다)
    fit = k
    for d, cs in frames_by_dir.items():
        base = median(b[3] for b in boxes[d])
        for c, b in zip(cs, boxes[d]):
            if base - b[1] > 0:
                fit = min(fit, (anchor[1] - 2) / (base - b[1]))
            if c.width / 2 - b[0] > 0:
                fit = min(fit, (anchor[0] - 2) / (c.width / 2 - b[0]))
            if b[2] - c.width / 2 > 0:
                fit = min(fit, (frame[0] - anchor[0] - 2) / (b[2] - c.width / 2))
    if fit < k:
        print(f'  칸에 맞춰 배율 {k:.2f} → {fit:.2f}')
        k = fit
    out, issues = {}, []
    for d, cs in frames_by_dir.items():
        base = median(b[3] for b in boxes[d])
        dir_h = median(b[3] - b[1] for b in boxes[d])
        out[d] = []
        for i, (c, b) in enumerate(zip(cs, boxes[d])):
            if cfg.get('steady'):
                # 서기·걷기: 방향마다 키를 같게(돌아설 때 커졌다 작아지지 않게), 프레임마다 키 차이는 30%만 남기고,
                # 가장 낮은 발을 땅(anchor)에 붙이고, 몸통 가운데를 anchor x에 맞춘다(발·곤봉이 흔들려도 몸이 미끄러지지 않게)
                h = b[3] - b[1]
                kf = k * ref / dir_h * (dir_h / h) ** 0.7
                sp = shrink(c.crop(b), kf)
                x = round(anchor[0] - torso_x(sp))
                y = anchor[1] - sp.height
            else:
                sp = shrink(c.crop(b), k)
                x = round(anchor[0] + (b[0] - c.width / 2) * k)
                y = round(anchor[1] + (b[1] - base) * k)
            if x < 0 or y < 0 or x + sp.width > frame[0] or y + sp.height > frame[1]:
                issues.append(f'{d} {i + 1}: 칸을 넘어 잘림')
            canvas = Image.new('RGBA', frame)
            canvas.alpha_composite(sp.crop((max(0, -x), max(0, -y), sp.width, sp.height)), (max(0, x), max(0, y)))
            out[d].append(canvas)
    return out, k, issues


def pack(which, root):
    root = Path(root)
    cfgs = CONFIGS[which]
    anims, report = {}, {}
    for name, cfg in cfgs.items():
        if cfg['layout'] == 'sleep':
            continue
        try:
            src = load_anim(name, cfg, root)
        except FileNotFoundError as e:
            print('건너뜀(원본 없음):', name, e)
            continue
        like = report.get(cfg.get('k_like', ''), {}).get('scale')
        frames, k, issues = place(src, cfg, (FRAME, FRAME), k=like)
        for d, o in MIRROR.items():
            frames[d] = [f.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for f in frames[o]]
        anims[name] = frames
        report[name] = {'scale': round(k, 3), 'issues': issues}
        print(f'{name}: 배율 {k:.2f}', '· '.join(issues) if issues else '')
    # 감은 눈(잠·취함)·찔린 눈(날뛰기) 정지 그림은 기본 시트에서 — 동작 그림이 없는 동작은 코드 자세가 이걸 기울여 쓴다
    stills = ['idle_shut', 'idle_wound'] + ([] if 'idle' in anims else ['idle'])
    for n, f in base_stills(root, stills).items():
        anims[n] = f
    out_dir = root / 'assets/sprites'
    for sheet, names in SHEETS.items():
        names = [n for n in names + (stills if sheet == 'polyphemus' else []) if n in anims]
        total = sum(len(anims[n]['E']) for n in names)
        img = Image.new('RGBA', (FRAME * total, FRAME * 8))
        meta = {'frame': [FRAME, FRAME], 'anchor': list(ANCHOR), 'dirs': 8, 'scale': 0.5, 'anims': {}}
        col = 0
        for n in names:
            cnt = len(anims[n]['E'])
            for r, d in enumerate(ORDER):
                for i, f in enumerate(anims[n][d]):
                    img.paste(f, ((col + i) * FRAME, r * FRAME))
            c = cfgs.get(n, {'fps': 1, 'loop': True})
            meta['anims'][n] = {'start': col, 'frames': cnt, 'fps': c['fps'], 'loop': c['loop']}
            col += cnt
        img.save(out_dir / f'{sheet}.png')
        (out_dir / f'{sheet}.json').write_text(json.dumps(meta, indent=2) + '\n')
        print('시트', sheet, img.size)
    # 잠듦: 한 장 cols×rows, 줄 0 = 반듯이, 줄 1 = 옆으로 웅크림 → dirs 2
    sc = cfgs['sleep']
    p = root / sc['src']
    if p.exists():
        cells = split(Image.open(p), sc['cols'], sc['rows'])
        frames, k, issues = place({'S': cells[0], 'N': cells[1]}, sc, SLEEP_FRAME, SLEEP_ANCHOR, SLEEP_LEN)
        cnt = sc['cols']
        img = Image.new('RGBA', (SLEEP_FRAME[0] * cnt, SLEEP_FRAME[1] * 2))
        for r, d in enumerate(['S', 'N']):
            for i, f in enumerate(frames[d]):
                img.paste(f, (i * SLEEP_FRAME[0], r * SLEEP_FRAME[1]))
        img.save(out_dir / 'polyphemus_sleep.png')
        meta = {'frame': list(SLEEP_FRAME), 'anchor': list(SLEEP_ANCHOR), 'dirs': 2, 'scale': 0.5,
                'anims': {'sleep': {'start': 0, 'frames': cnt, 'fps': sc['fps'], 'loop': True}}}
        (out_dir / 'polyphemus_sleep.json').write_text(json.dumps(meta, indent=2) + '\n')
        report['sleep'] = {'scale': round(k, 3), 'issues': issues}
        print(f'sleep: 배율 {k:.2f}', '· '.join(issues))
    (root / KIT / f'polyphemus_hd_{which}.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')


# 기본 시트(512 칸) 안 외눈 타원: 방향 → (x0, y0, x1, y1). 뒤쪽 두 방향은 눈이 안 보인다
EYES = {'E': (400, 100, 421, 122), 'SE': (327, 104, 370, 131), 'S': (250, 110, 292, 131)}
BASE_CELLS = {'E': (0, 0), 'SE': (1, 0), 'S': (2, 0), 'NE': (0, 1), 'N': (1, 1)}


def eye_variant(cell, d, kind):
    """kind shut: 눈꺼풀(눈썹 아래 살빛 + 가운데 어두운 금) / wound: 검붉은 상처"""
    if d not in EYES:
        return cell
    out = cell.copy()
    px = out.load()
    x0, y0, x1, y1 = EYES[d]
    cx, cy, rx, ry = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2 + 1.5, (y1 - y0) / 2 + 1.5
    lid = px[int(cx), max(0, y0 - 6)]
    for y in range(y0 - 2, y1 + 3):
        for x in range(x0 - 2, x1 + 3):
            e = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if e > 1.0 or px[x, y][3] < 128:
                continue
            if kind == 'shut':
                k = 0.78 - 0.18 * ((y - y0) / max(1, y1 - y0))
                c = tuple(int(v * k) for v in lid[:3])
                if abs(y - (cy + 1 + 2.5 * (1 - ((x - cx) / rx) ** 2))) < 1.2:
                    c = (34, 28, 30)
            else:
                k = e ** 0.7
                c = (int(40 + 120 * k), int(8 + 18 * k), int(10 + 16 * k))
            px[x, y] = c + (255,)
    return out


BASE_VARIANTS = {'idle': None, 'idle_shut': 'shut', 'idle_wound': 'wound'}


def base_stills(root, names=BASE_VARIANTS):
    """기본 5방향 한 장 → 1프레임 동작들(뜬 눈·감은 눈·찔린 눈), 8방향"""
    src = Image.open(root / KIT / 'polyphemus_v2/results/base.png').convert('RGBA')
    cells = {d: clean(src.crop((c * 512, r * 512, c * 512 + 512, r * 512 + 512))) for d, (c, r) in BASE_CELLS.items()}
    frames_by_anim = {}
    for name in names:
        kind = BASE_VARIANTS[name]
        by_dir = {d: [eye_variant(c, d, kind) if kind else c] for d, c in cells.items()}
        frames, k, issues = place(by_dir, {'ref': 'median'}, (FRAME, FRAME))
        for d, o in MIRROR.items():
            frames[d] = [f.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for f in frames[o]]
        frames_by_anim[name] = frames
        print(f'{name}: 배율 {k:.2f}', '· '.join(issues))
    return frames_by_anim


def pack_base(root):
    root = Path(root)
    variants = BASE_VARIANTS
    frames_by_anim = base_stills(root)
    img = Image.new('RGBA', (FRAME * len(variants), FRAME * 8))
    meta = {'frame': [FRAME, FRAME], 'anchor': list(ANCHOR), 'dirs': 8, 'scale': 0.5, 'anims': {}}
    for i, name in enumerate(variants):
        for r, d in enumerate(ORDER):
            img.paste(frames_by_anim[name][d][0], (i * FRAME, r * FRAME))
        meta['anims'][name] = {'start': i, 'frames': 1, 'fps': 1, 'loop': True}
    out = root / 'assets/sprites'
    img.save(out / 'polyphemus.png')
    (out / 'polyphemus.json').write_text(json.dumps(meta, indent=2) + '\n')
    for old in ['polyphemus_combat', 'polyphemus_sleep']:
        for ext in ['png', 'json', 'png.import']:
            (out / f'{old}.{ext}').unlink(missing_ok=True)
    print('시트 polyphemus', img.size, '(동작 시트 polyphemus_combat·polyphemus_sleep는 지움)')


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'base':
        pack_base(sys.argv[2] if len(sys.argv) > 2 else '.')
        sys.exit()
    pack(sys.argv[1] if len(sys.argv) > 1 else 'v1', sys.argv[2] if len(sys.argv) > 2 else '.')
