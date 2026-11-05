#!/usr/bin/env python3
"""현재 차림에 맞는 미수령 스프라이트 요청 4개를 준비한다. 생성 도구는 실행하지 않는다."""
import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'docs/sprite_request/next_batch_2026-11-05'
JOBS = {
    'lotus_props': [
        ('lotus_tree_fruit', 'A low spreading Mediterranean LOTUS TREE, twisted brown trunk, dense green leaves, clearly visible pink-gold lotus fruits and a few ivory-pink flowers. Full tree, no roots cut off.'),
        ('lotus_tree_flower', 'A second low spreading lotus tree, same species and scale, flowering crown, fewer fruits, different branching silhouette.'),
        ('lotus_tree_picked', 'Same species lotus tree with mostly picked fruits, sparse few fruits remain, same healthy green leaves.'),
        ('lotus_bush', 'Small dense leafy lotus fruit shrub with visible pink-gold fruits.'),
        ('lotus_basket', 'Woven reed basket filled with the same pink-gold lotus fruits, sitting upright.'),
        ('lotus_fruit_cluster', 'Small group of three freshly picked pink-gold lotus fruits and one green leaf. Readable at small game size.'),
        ('lotus_flower_patch', 'Low isolated patch of tiny ivory-pink flowers and green leaves, organically shaped, no soil tile underneath.'),
        ('lotus_reeds', 'Small low cluster of coastal reeds and soft green grasses, no ground tile underneath.'),
    ],
    'harbor_props': [
        ('harbor_net', 'Fishing net hanging on two short wooden drying poles, net visibly woven and slack, small compact free standing prop.'),
        ('harbor_rope', 'A coiled thick brown mooring rope, one short loose end, compact isolated prop.'),
        ('harbor_bollard', 'Weathered low wooden mooring bollard with thick rope wound around its top, no dock floor included.'),
        ('harbor_fish_basket', 'Low woven basket holding several silver fish, entirely visible.'),
        ('harbor_amphorae', 'Compact group of three ancient Greek terracotta transport amphorae in a short wooden rack.'),
        ('harbor_cargo', 'Compact cargo stack of two wood crates and a tied cream linen grain sack, readable separated silhouette.'),
        ('harbor_ramp', 'Short low wooden boarding gangplank with simple rope rail, facing diagonally down-right in isometric view. Isolated, no boat or pier.'),
        ('harbor_oars', 'Three long wooden galley oars resting against a low wooden rack, blades visible, isolated prop.'),
    ],
}
COMMON = '''Create a production environment PROP SPRITE SHEET for ODYSSEY, a 2D pixel-art isometric ancient Greek action RPG.
Exactly 1536x1024 pixels, FOUR columns by TWO rows, invisible cells384x512. Exactly eight separate props, one centered in each cell. All props fully inside their cells with at least32px empty margins. Each prop uses only as much cell space as its relative size needs: trees about300px high, medium props150-220px, small objects60-110px; do not enlarge a fruit to tree size. Consistent30degree top-down orthographic2:1 isometric camera and illumination from upper left. Match style_ref.png pixel clusters, dark1px contour and warm restrained palette. Environment proportions realistic, not chibi. Crisp2D pixel art, no antialiasing or blur. Background EVERYWHERE outside sprites exactly flat#282B35, no gradient, no cast shadows, no ground or scenery, no text, labels, numbers, borders or grid. Layout.png is a positioning guide only; replace placeholders with finished sprites and remove all guide marks. Do not copy props from style_ref.png; draw the requested new assets.
Read order top row left to right then bottom row left to right:
'''


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = []
    for name, props in JOBS.items():
        folder = DEST / name
        folder.mkdir(exist_ok=True)
        shutil.copy2(ROOT / 'docs/sprite_request/env_requests/troy_env.png', folder / 'style_ref.png')
        guide = Image.new('RGB', (1536, 1024), '#282B35')
        d = ImageDraw.Draw(guide)
        for i in range(8):
            x, y = (i % 4) * 384, (i // 4) * 512
            # 테두리·문자 없이 배치할 위치만 표시한다.
            d.ellipse((x + 115, y + 300, x + 269, y + 375), fill='#747988')
        guide.save(folder / 'layout.png')
        text = COMMON + '\n'.join(f'Cell{i+1}: {p[1]}' for i, p in enumerate(props))
        (folder / 'prompt.txt').write_text(text + '\n')
        cells = [{'name': p[0], 'cell': [(i % 4)*384, (i // 4)*512, 384, 512]} for i, p in enumerate(props)]
        (folder / 'cells.json').write_text(json.dumps({'canvas': [1536, 1024], 'background': '#282B35', 'cells': cells}, indent=2) + '\n')
        manifest.append({'id': name, 'prompt': f'{name}/prompt.txt', 'references': [f'{name}/layout.png', f'{name}/style_ref.png'], 'result': f'results/{name}.png', 'status': 'prepared'})
    # 현재 게임에서 쓰는 무기 포함 차림으로 포즈를 만든다.
    subprocess.run([sys.executable, str(ROOT/'tools/motion_request.py'), str(ROOT/'assets/source/odysseus_ch1_8dir.webp'), str(ROOT/'docs/sprite_request/ch1_kit/character_motion.txt'), str(DEST/'armed_throw'), 'throw', '1'], check=True, cwd=ROOT)
    subprocess.run([sys.executable, str(ROOT/'docs/sprite_request/ch1_kit/armed_patch.py'), str(DEST/'armed_throw')], check=True, cwd=ROOT)
    for folder in sorted((DEST/'armed_throw').iterdir()):
        if not (folder/'prompt.txt').exists():
            continue
        prompt = (folder/'prompt.txt').read_text()
        prompt = prompt.replace('a short bronze leaf-blade sword with a gold crossguard held in the RIGHT fist', 'a short bronze leaf-blade sword sheathed at the hip, leaving the RIGHT hand free to throw')
        prompt = prompt.replace('about 290px tall when standing straight', 'about 320px tall when standing straight')
        prompt = '\n'.join(line.rstrip() for line in prompt.splitlines()) + '\n'
        (folder/'prompt.txt').write_text(prompt)
        with (folder/'prompt.txt').open('a') as out:
            out.write('\nSword MUST be sheathed at the hip for this throwing action; right hand holds the small stone only in frames1-2, releases in frame3, empty in frame4. The left forearm keeps the star shield, helmet cape bow and quiver are preserved. Standing height about320px in every cell.\n')
        manifest.append({'id': folder.name, 'prompt': f'armed_throw/{folder.name}/prompt.txt', 'references': [f'armed_throw/{folder.name}/pose.png'], 'result': f'results/{folder.name}.png', 'status': 'prepared'})
    (DEST/'results').mkdir(exist_ok=True)
    for job in manifest:
        if (DEST/job['result']).exists():
            job['status'] = 'candidate'
    (DEST/'manifest.json').write_text(json.dumps({'date': '2026-11-05', 'jobs': manifest}, ensure_ascii=False, indent=2) + '\n')
    print(DEST)


if __name__ == '__main__':
    main()
