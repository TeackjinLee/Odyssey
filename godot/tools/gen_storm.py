#!/usr/bin/env python3
"""챕터 2 폭풍 그림 변환: 받은 원본(assets/source/) → 게임 그림.

    python3 tools/gen_storm.py .        # godot 폴더에서

- sea_storm.webp · sea_calm.webp (Codex, 1254²쯤) → assets/env/sea_storm.png · sea_calm.png (512², 이음매 없는 무늬)
  원본은 그림 한 점이 약 2.45픽셀이라 512로 줄이면 한 점 = 게임 1픽셀. 줄인 뒤 색을 다시 모아(16색) 픽셀을 또렷하게,
  끝 띠를 겹쳐 섞어 이음매를 지운다. water.gdshader가 월드 좌표로 깔아 흘린다.
- storm_fx.webp (1536×1024, 칸 = docs/sprite_request/storm_requests/storm_fx/boxes.json) → assets/fx/storm_<이름>.png + .json
  (Fx.anim 형식: 프레임을 가로로 늘어놓은 한 장). 배경 #282B35는 투명으로, 크기는 항목마다 SCALE(대개 반).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

SEA_SIZE = 512
SEA_COLORS = 16
BLEND = 24          # 이음매 지우기 띠(원본 픽셀)
BG = np.array([39, 42, 52])
KEY = 26            # 배경과 이만큼 가까우면 투명
SEA_HUE = 155       # 파도 몸통 색을 바다 무늬(sea_storm) 색상에 맞춘다(PIL HSV 0~255 — 받은 그림은 청록 142)

# 항목: 자르기 여백 [왼, 위, 오른, 아래](받은 그림이 칸을 조금 넘친 만큼) · 줄이는 비율 · 기준점(0~1) · 초당 프레임
FX = {
    "wave_crash": {"sea": True, "pad": [10, 4, 6, 6], "scale": 0.5, "anchor": [0.45, 0.97], "fps": 10},
    "whitecap_a": {"sea": True, "pad": [6, 6, 6, 6], "scale": 0.5, "anchor": [0.5, 0.6], "fps": 8},
    "whitecap_b": {"sea": True, "pad": [6, 6, 6, 6], "scale": 0.5, "anchor": [0.5, 0.6], "fps": 8},
    "bow_spray": {"sea": True, "pad": [14, 4, 4, 4], "scale": 0.5, "anchor": [0.15, 0.9], "fps": 12},
    "rain_splash": {"pad": [10, -36, 14, 56], "scale": 0.5, "anchor": [0.5, 0.5], "fps": 16},   # 받은 그림이 칸보다 40px 아래에
    "lightning": {"pad": [0, 0, 0, 0], "scale": 0.5, "anchor": [0.5, 0.0], "fps": 1},
    "foam_streak": {"pad": [26, 6, 28, 6], "scale": 0.5, "anchor": [0.5, 0.5], "fps": 1},
    "spray_drift": {"pad": [12, 4, 6, 4], "scale": 0.5, "anchor": [0.5, 0.5], "fps": 8},
    "rain_streak": {"pad": [2, 6, 4, 6], "scale": 0.25, "anchor": [0.5, 0.5], "fps": 1},
}


def seamless(a: np.ndarray, band: int) -> np.ndarray:
    """끝 띠 겹치기: 오른쪽 끝 band 줄을 왼쪽 처음 band 줄에 겹쳐 섞고 잘라낸다(위아래도). 받은 그림이 거의 이어져 있어
    띠만 겹치면 이음매가 사라지고, 가운데는 원본 그대로다. 결과는 band만큼 작아진다."""
    w = np.linspace(0.0, 1.0, band)
    h, wd = a.shape[:2]
    left = a[:, wd - band:] * (1 - w)[None, :, None] + a[:, :band] * w[None, :, None]
    a = np.concatenate([left, a[:, band:wd - band]], 1)
    top = a[h - band:] * (1 - w)[:, None, None] + a[:band] * w[:, None, None]
    return np.concatenate([top, a[band:h - band]], 0)


def make_sea(root: str, name: str) -> None:
    src = Image.open(os.path.join(root, "assets/source", name + ".webp")).convert("RGB")
    a = seamless(np.asarray(src).astype(float), BLEND)
    img = Image.fromarray(a.round().clip(0, 255).astype(np.uint8)).resize((SEA_SIZE, SEA_SIZE), Image.LANCZOS)
    img = img.quantize(SEA_COLORS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    out = os.path.join(root, "assets/env", name + ".png")
    img.save(out)
    print("바다", out, img.size)


def key_and_scale(cell: Image.Image, scale: float) -> Image.Image:
    a = np.asarray(cell.convert("RGB")).astype(float)
    alpha = (np.abs(a - BG).sum(2) > KEY).astype(float)
    if scale != 1.0:
        w, h = cell.size
        nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
        # 미리 곱한 색으로 상자 평균 → 반 넘게 덮인 픽셀만 남긴다
        pre = np.dstack([a * alpha[..., None], alpha * 255.0]).round().clip(0, 255).astype(np.uint8)
        small = np.asarray(Image.fromarray(pre, "RGBA").resize((nw, nh), Image.BOX)).astype(float)
        al = small[..., 3] / 255.0
        rgb = np.where(al[..., None] > 0, small[..., :3] / np.maximum(al[..., None], 1e-6), 0)
        keep = al > 0.45
        out = np.dstack([rgb.clip(0, 255), keep * 255.0])
    else:
        out = np.dstack([a, alpha * 255.0])
    return Image.fromarray(out.round().astype(np.uint8), "RGBA")


def to_sea(im: Image.Image) -> Image.Image:
    """어두운 물 몸통(밝기 < 170)만 바다 색상으로 돌리고 조금 어둡게 — 흰 거품은 그대로."""
    hsv = np.asarray(im.convert("RGB").convert("HSV")).astype(float)
    dark = hsv[..., 2] < 170
    hsv[..., 0] = np.where(dark, SEA_HUE, hsv[..., 0])
    hsv[..., 2] = np.where(dark, hsv[..., 2] * 0.82, hsv[..., 2])
    rgb = Image.fromarray(hsv.round().clip(0, 255).astype(np.uint8), "HSV").convert("RGB")
    out = rgb.convert("RGBA")
    out.putalpha(im.getchannel("A"))
    return out


def make_fx(root: str) -> None:
    src = Image.open(os.path.join(root, "assets/source/storm_fx.webp")).convert("RGB")
    boxes = json.load(open(os.path.join(root, "docs/sprite_request/storm_requests/storm_fx/boxes.json")))["items"]
    os.makedirs(os.path.join(root, "assets/fx"), exist_ok=True)
    for name, cfg in FX.items():
        l, t, r, b = cfg["pad"]
        frames = [key_and_scale(src.crop((x0 - l, y0 - t, x1 + r, y1 + b)), cfg["scale"]) for x0, y0, x1, y1 in boxes[name]]
        if cfg.get("sea"):
            frames = [to_sea(f) for f in frames]
        fw, fh = frames[0].size
        strip = Image.new("RGBA", (fw * len(frames), fh), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            strip.paste(f, (i * fw, 0))
        base = os.path.join(root, "assets/fx", "storm_" + name)
        strip.save(base + ".png")
        meta = {"frame": [fw, fh], "frames": len(frames), "fps": cfg["fps"],
                "anchor": [round(fw * cfg["anchor"][0]), round(fh * cfg["anchor"][1])], "scale": 1}
        with open(base + ".json", "w") as f:
            json.dump(meta, f)
        print("이펙트", base + ".png", strip.size, len(frames))


def main(root: str) -> None:
    make_sea(root, "sea_storm")
    make_sea(root, "sea_calm")
    make_fx(root)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
