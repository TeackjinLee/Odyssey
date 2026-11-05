#!/usr/bin/env python3
"""아직 못 받은 요청을 사람이 ChatGPT에 직접 넣도록 manual/index.html로 모은다.
요청마다 번호·붙일 그림(끌어다 놓기)·요청 글(복사 단추)·받은 그림을 저장할 이름을 보여 준다.
받은 그림은 manual_results/<단위>__<요청>.png로 두면 process.py가 Codex 결과보다 먼저 쓴다.
사용: python3 docs/sprite_request/ch2_kit/make_manual.py   (godot/ 안에서)
"""
import html
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
CODEX = ["Use your built-in image generation tool to create exactly ONE image from the prompt below.",
         "Do not write code or edit any files. When the image is generated, reply with its saved file path only.\n"]


def pending():
    for job in sorted(HERE.glob("*/*/prompt.txt")):
        job = job.parent
        log = job.parent / f"{job.name}.log"
        if log.exists() and re.search(r"/Users[^ ]*generated_images[^ ]*\.png", log.read_text(errors="ignore")):
            continue
        if (HERE / "manual_results" / save_name(job)).exists():
            continue
        yield job


def save_name(job):
    return f"{job.parent.name}__{re.sub(r'[a-z]$', '', job.name)}.png"


def main():
    (HERE / "manual_results").mkdir(exist_ok=True)
    rows = []
    for i, job in enumerate(pending(), 1):
        t = (job / "prompt.txt").read_text()
        t = t.replace(CODEX[0], "Create exactly ONE image from the prompt below.").replace(CODEX[1], "")
        imgs = [p for p in ("pose.png", "guide.png") if (job / p).exists()]
        rel = f"../{job.parent.name}/{job.name}"
        figs = "".join(f'<figure><img src="{rel}/{p}" draggable="true"><figcaption>{n}) {p}</figcaption></figure>'
                       for n, p in enumerate(imgs, 1))
        rows.append(f'''<section id="j{i}"><h2>{i:02d}. {job.parent.name} / {job.name}</h2>
<div class="att">{figs}</div>
<p>저장 이름: <code class="name">{save_name(job)}</code> <button data-copy="name">이름 복사</button></p>
<textarea readonly>{html.escape(t)}</textarea><button data-copy="text">요청 글 복사</button>
<label><input type="checkbox"> 받음</label></section>''')
    page = f'''<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>2장 직접 요청</title>
<style>
:root {{ --bg:#16191d; --fg:#e8e2d6; --card:#22262c; --line:#3a3f47; --acc:#e0b860; }}
body {{ background:var(--bg); color:var(--fg); font:14px/1.5 -apple-system,sans-serif; margin:0 auto; max-width:980px; padding:16px; }}
section {{ background:var(--card); border:1px solid var(--line); border-radius:8px; padding:12px 16px; margin:12px 0; }}
section:has(input:checked) {{ opacity:.45; }}
h2 {{ font-size:16px; margin:0 0 8px; color:var(--acc); }}
.att {{ display:flex; gap:12px; flex-wrap:wrap; }}
figure {{ margin:0; }} img {{ max-height:180px; max-width:100%; border:1px solid var(--line); background:#f0f; }}
figcaption {{ font-size:12px; }}
textarea {{ width:100%; height:140px; background:#111; color:var(--fg); border:1px solid var(--line); font:12px monospace; }}
button {{ background:var(--acc); border:0; border-radius:4px; padding:4px 10px; cursor:pointer; margin:4px 8px 4px 0; }}
code {{ color:var(--acc); }}
</style></head><body>
<h1>2장 그림 직접 요청 ({len(rows)}개)</h1>
<p>요청마다: ① 붙일 그림을 순서대로 ChatGPT 창에 끌어다 놓기 ② 요청 글 복사·붙여 넣기 ③ 받은 그림을
<code>docs/sprite_request/ch2_kit/manual_results/</code>에 저장 이름으로 저장. 받은 것은 체크해 두면 흐려진다.</p>
{"".join(rows)}
<script>
document.querySelectorAll('button[data-copy]').forEach(b => b.onclick = () => {{
  const s = b.closest('section');
  const v = b.dataset.copy === 'name' ? s.querySelector('.name').textContent : s.querySelector('textarea').value;
  navigator.clipboard.writeText(v).then(() => {{ b.textContent = '복사됨'; setTimeout(() => b.textContent = b.dataset.copy === 'name' ? '이름 복사' : '요청 글 복사', 1200); }});
}});
</script></body></html>'''
    (HERE / "manual").mkdir(exist_ok=True)
    (HERE / "manual/index.html").write_text(page)
    print(len(rows), "개 → manual/index.html")


if __name__ == "__main__":
    main()
