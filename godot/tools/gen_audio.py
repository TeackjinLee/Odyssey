#!/usr/bin/env python3
"""게임 소리 전부를 합성한다(녹음·외부 소리 없음) → assets/audio/.

    python3 tools/gen_audio.py .            # 전부
    python3 tools/gen_audio.py . sfx        # 효과음만 (sfx · amb · music 중 골라서)

- sfx/<이름>.wav (모노 44.1kHz): 타격·막기·패링·활·함성·종·발소리 등. 자주 나는 소리는 <이름>_1.. 변형 여럿 → Sfx가 무작위로 고른다
- amb/<이름>.ogg (스테레오, 이음매 없이 반복): 밤바람·불길·파도·먼 전투 소리
- music/<이름>.ogg (스테레오): 타이틀·잠입·전투·성문 사수·엔딩, 짧은 승리·패배 곡
  (영화 《오디세이》(2026) 음악 같은 느낌 — 오케스트라 없이 리라·아울로스·청동 징·두드린 쇠붙이,
   그 소리를 일그러뜨린 신시, 말 없는 목소리·합창. 선율은 모두 새로 만든 것. 선법은 D 프리지안·D 에올리안)

게임(scripts/combat/sfx.gd · bgm.gd)은 이 파일이 있으면 쓰고, 없으면 코드로 만든 소리를 쓴다.
실제 녹음·작곡한 소리로 바꾸려면 같은 이름의 파일을 덮어쓰면 된다(.wav 또는 .ogg).
numpy만 쓴다(scipy 없음). ogg는 ffmpeg(libvorbis)로 만든다.
"""
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

SR = 44100
rng = np.random.default_rng(7)


# ── 기본 도구 ─────────────────────────────────────────
def tt(dur):
    return np.arange(int(dur * SR)) / SR


def noise(n):
    return rng.standard_normal(n)


def env_exp(n, decay, attack=0.002):
    """attack초에 올라가 decay초마다 1/e로 줄어드는 포락선"""
    t = np.arange(n) / SR
    e = np.exp(-t / max(decay, 1e-4))
    if attack > 0:
        e *= np.minimum(1.0, t / attack)
    return e


def fade(x, fin=0.0, fout=0.0):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    sh = (-1, 1) if x.ndim == 2 else (-1,)
    if a:
        x[:a] *= np.linspace(0, 1, a).reshape(sh)
    if b:
        x[-b:] *= np.linspace(1, 0, b).reshape(sh)
    return x


def fft_filter(x, lo=None, hi=None, order=2, peaks=()):
    """주파수 영역 필터: lo 아래·hi 위를 버터워스 모양으로 깎고, peaks=[(주파수, 폭, 이득)]로 봉우리(공명·포먼트)를 더한다"""
    n = len(x)
    m = 1 << int(np.ceil(np.log2(max(n, 2))))
    X = np.fft.rfft(x, m)
    f = np.fft.rfftfreq(m, 1 / SR)
    g = np.ones_like(f)
    if hi:
        g /= np.sqrt(1 + (f / hi) ** (2 * order))
    if lo:
        g /= np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** (2 * order))
    if peaks:
        p = np.zeros_like(f)
        for fc, bw, gain in peaks:
            p += gain * np.exp(-((f - fc) / bw) ** 2)
        g = g * (0.15 + p) if len(peaks) else g
    return np.fft.irfft(X * g, m)[:n]


def ola_filter(x, band_at, block=2048):
    """시간에 따라 바뀌는 띠 필터. band_at(초) → (lo, hi). 겹쳐 더하기(hann)."""
    hop = block // 4
    win = np.hanning(block)
    out = np.zeros(len(x) + block)
    xp = np.concatenate([x, np.zeros(block)])
    f = np.fft.rfftfreq(block, 1 / SR)
    for s in range(0, len(x), hop):
        lo, hi = band_at(s / SR)
        g = 1 / np.sqrt(1 + (f / hi) ** 4) / np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** 4)
        seg = np.fft.irfft(np.fft.rfft(xp[s:s + block] * win) * g, block)
        out[s:s + block] += seg * win
    return out[:len(x)] / 1.5


def sat(x, drive=1.5):
    return np.tanh(x * drive) / np.tanh(drive)


def norm(x, peak=0.89):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def pad_to(x, n):
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n] if x.ndim == 1 else \
        np.concatenate([x, np.zeros((max(0, n - len(x)), x.shape[1]))])[:n]


def mix(*parts):
    n = max(len(p) for p in parts)
    return sum(pad_to(p, n) for p in parts)


def at(buf, x, t0, gain=1.0):
    """buf에 x를 t0초 자리에 더한다(넘치면 자름). buf가 스테레오면 x도 스테레오여야 한다"""
    i = int(t0 * SR)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(x))
    buf[i:j] += x[:j - i] * gain


def reverb_ir(dur=2.0, damp=3000.0, seed=0, pre=0.012):
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    ir = r.standard_normal(n) * np.exp(-t * 6.9 / dur)
    ir = fft_filter(ir, lo=120, hi=damp)
    ir[:int(pre * SR)] = 0
    return ir / np.sqrt(np.sum(ir ** 2))


def convolve(x, ir):
    n = len(x) + len(ir) - 1
    m = 1 << int(np.ceil(np.log2(n)))
    return np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[:n]


def reverb(x, wet=0.25, dur=1.6, damp=3500.0, seed=0):
    y = convolve(x, reverb_ir(dur, damp, seed))
    return pad_to(x, len(y)) * (1 - wet * 0.5) + y * wet


def stereo_reverb(st, wet=0.3, dur=2.4, damp=4000.0):
    """스테레오(n,2)에 좌우가 다른 잔향을 더한다"""
    l = convolve(st[:, 0], reverb_ir(dur, damp, 11))
    r = convolve(st[:, 1], reverb_ir(dur, damp, 12))
    n = len(l)
    dry = pad_to(st, n)
    return dry * (1 - wet * 0.4) + np.stack([l, r], 1) * wet


def pan(x, p):
    """p: -1 왼쪽 ~ 1 오른쪽"""
    a = (p + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)], 1)


def loopify(x, xf=1.5):
    """끝 xf초를 앞에 겹쳐 이음매 없이 반복되게 만든다(길이는 xf초 줄어든다)"""
    k = int(xf * SR)
    body = x[:-k].copy()
    w = np.linspace(0, 1, k)
    if x.ndim == 2:
        w = w[:, None]
    body[:k] = body[:k] * w + x[-k:] * (1 - w)
    return body


def wrap_tail(x, length):
    """음악: length 뒤로 넘친 잔향을 앞으로 접어 더한다(반복할 때 잔향이 끊기지 않게)"""
    out = x[:length].copy()
    tail = x[length:]
    while len(tail):
        k = min(len(tail), length)
        out[:k] += tail[:k]
        tail = tail[k:]
    return out


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


# ── 악기 ──────────────────────────────────────────────
def pluck(f, dur, damp=0.995, bright=0.6, seed=None):
    """뜯는 현(카플러스-스트롱). bright가 낮을수록 부드럽다. 정확한 음높이로 다시 표본화한다."""
    r = np.random.default_rng(seed) if seed is not None else rng
    N = max(2, int(round(SR / f)))
    n = int(dur * SR) + N
    out = np.zeros(n)
    exc = r.uniform(-1, 1, N)
    # 들뜸 신호를 살짝 뭉개 밝기 조절
    for _ in range(int((1 - bright) * 4)):
        exc = 0.5 * (exc + np.roll(exc, 1))
    out[:N] = exc - exc.mean()
    L = N - 1
    i = N
    while i < n:
        k = min(L, n - i)
        out[i:i + k] = damp * 0.5 * (out[i - N:i - N + k] + out[i - N + 1:i - N + 1 + k])
        i += k
    # 정확한 음높이: 실제 주기 N+0.5 → f
    ratio = f / (SR / (N + 0.5))
    src = np.arange(0, n - 1, ratio)
    y = np.interp(src, np.arange(n), out)[:int(dur * SR)]
    return y * env_exp(len(y), dur * 0.9, 0.001)


def lyre(f, dur, vel=1.0, seed=None):
    """리라: 뜯는 현 + 몸통 공명(낮은 봉우리)"""
    y = pluck(f, dur, damp=0.9965 if f < 400 else 0.994, bright=0.55, seed=seed)
    y = fft_filter(y, lo=70, hi=5200, peaks=[(280, 120, 0.8), (900, 300, 0.6), (2400, 800, 0.35)])
    return y * vel


def additive(f0, dur, weight, nh=40, vib=0.0, vib_rate=5.0, drift=0.0, seed=None):
    """배음 더하기. weight(배음 주파수) → 세기. vib는 반음 비율 떨림 폭."""
    r = np.random.default_rng(seed) if seed is not None else rng
    t = tt(dur)
    fcur = f0 * (1 + vib * np.sin(2 * np.pi * vib_rate * t + r.uniform(0, 6)) +
                 drift * np.cumsum(r.standard_normal(len(t))) / np.sqrt(len(t) + 1))
    ph = 2 * np.pi * np.cumsum(fcur) / SR
    y = np.zeros(len(t))
    for k in range(1, nh + 1):
        fk = f0 * k
        if fk > SR * 0.45:
            break
        w = weight(fk, k)
        if w < 1e-4:
            continue
        y += w * np.sin(k * ph + r.uniform(0, 6))
    return y


def formant_w(formants, floor=0.02):
    def w(fk, k):
        return (floor + sum(a * np.exp(-((fk - fc) / bw) ** 2) for fc, bw, a in formants)) / (k ** 0.5)
    return w


VOWEL_A = [(750, 120, 1.0), (1150, 140, 0.55), (2600, 220, 0.25)]
VOWEL_O = [(500, 100, 1.0), (850, 120, 0.5), (2500, 220, 0.12)]
VOWEL_U = [(350, 90, 1.0), (750, 120, 0.3), (2400, 200, 0.08)]


def aulos(f, dur, vel=1.0, seed=None):
    """아울로스(겹리드): 홀수 배음이 센 갈대 소리 + 숨 소리, 서서히 붙는 떨림"""
    def w(fk, k):
        odd = 1.0 if k % 2 else 0.45
        return odd * (0.03 + np.exp(-((fk - 1100) / 700) ** 2) + 0.4 * np.exp(-((fk - 2600) / 500) ** 2)) / k ** 0.7
    y = additive(f, dur, w, nh=30, vib=0.006, vib_rate=5.5, seed=seed)
    y += fft_filter(noise(len(y)), lo=1500, hi=5000) * 0.05
    a = min(0.06, dur * 0.3)
    e = np.minimum(1, tt(dur) / a) * np.minimum(1, (dur - tt(dur)) / min(0.08, dur * 0.3))
    # 떨림은 길게 끄는 음에서만 점점
    return sat(y * e * 0.35, 1.3) * vel


def choir(f, dur, vowel=VOWEL_A, voices=4, seed=0):
    y = np.zeros(int(dur * SR))
    for v in range(voices):
        det = 1 + (v - voices / 2) * 0.004
        y += additive(f * det, dur, formant_w(vowel), nh=36, vib=0.004, vib_rate=4.6 + v * 0.3, seed=seed + v)
    a = min(0.5, dur * 0.4)
    t = tt(dur)
    e = np.minimum(1, t / a) * np.minimum(1, (dur - t) / min(0.6, dur * 0.4))
    return y * e / voices


def drone(f, dur, bright=1400.0, seed=0):
    def w(fk, k):
        return 1 / k / np.sqrt(1 + (fk / bright) ** 4)
    y = additive(f, dur, w, nh=40, vib=0.0015, vib_rate=0.3, seed=seed)
    y += additive(f * 1.003, dur, w, nh=40, vib=0.0015, vib_rate=0.23, seed=seed + 5)
    t = tt(dur)
    return y * (0.8 + 0.2 * np.sin(2 * np.pi * 0.11 * t)) * 0.5


def drone_loop(f, length, bright=1400.0, seed=0):
    """반복 곡 바탕 지속음: 정확히 length 표본, 끝과 처음이 이어진다"""
    return loopify(drone(f, length / SR + 2.0, bright, seed), 2.0)[:length]


def bass_saw(f, dur, cutoff=900.0, seed=None):
    """낮은 현 스타카토(전투 바탕 리듬)"""
    def w(fk, k):
        return 1 / k / np.sqrt(1 + (fk / cutoff) ** 4)
    y = additive(f, dur, w, nh=30, seed=seed)
    return sat(y * env_exp(len(y), dur * 0.45, 0.004) * 0.6, 1.6)


def frame_drum(low=True, vel=1.0):
    """틀북: low면 둥(가죽 울림), 아니면 탁(테두리)"""
    if low:
        n = int(0.45 * SR)
        t = np.arange(n) / SR
        f = 58 + 40 * np.exp(-t * 30)
        y = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, 0.16, 0.001)
        y += fft_filter(noise(n), lo=80, hi=700) * env_exp(n, 0.03) * 0.4
    else:
        n = int(0.18 * SR)
        y = fft_filter(noise(n), lo=700, hi=4500, peaks=[(1500, 500, 1.0)]) * env_exp(n, 0.025, 0.0005)
        y += np.sin(2 * np.pi * 330 * tt(0.18)) * env_exp(n, 0.02) * 0.3
    return sat(y, 1.2) * vel


def big_drum(vel=1.0):
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    f = 42 + 50 * np.exp(-t * 18)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, 0.32, 0.001)
    y += fft_filter(noise(n), lo=60, hi=400) * env_exp(n, 0.06) * 0.5
    y += fft_filter(noise(n), lo=1500, hi=5000) * env_exp(n, 0.008) * 0.25   # 북채 닿는 소리
    return sat(y * 1.2, 1.8) * vel


def horn(f, dur, vel=1.0):
    """뿔나팔·금관: 음이 아래서 밀려 올라가고, 배음이 점점 열린다"""
    t = tt(dur)
    scoop = 1 - 0.06 * np.exp(-t * 12)
    bright = 500 + 1600 * np.minimum(1, t / 0.25)

    def w(fk, k):
        return 1 / k ** 0.8
    ph = 2 * np.pi * np.cumsum(f * scoop * (1 + 0.004 * np.sin(2 * np.pi * 5 * t))) / SR
    y = np.zeros(len(t))
    for k in range(1, 30):
        if f * k > 9000:
            break
        y += w(f * k, k) * np.sin(k * ph) / np.sqrt(1 + (f * k / bright) ** 4)
    e = np.minimum(1, t / 0.05) * np.minimum(1, (dur - t) / 0.25)
    return sat(y * e * 0.5, 1.5) * vel


# ── 효과음 ────────────────────────────────────────────
def sfx_swing(heavy=False, seed=0):
    r = np.random.default_rng(seed)
    dur = 0.34 if heavy else 0.22
    n = int(dur * SR)
    lo0, hi0 = (250, 900) if heavy else (500, 1600)
    sweep = 2.6 + r.uniform(-0.3, 0.3)
    y = ola_filter(r.standard_normal(n), lambda s: (lo0 * (1 + sweep * s / dur), hi0 * (1 + sweep * s / dur)), block=1024)
    t = np.arange(n) / SR
    pk = dur * 0.45
    e = np.where(t < pk, (t / pk) ** 2, np.exp(-(t - pk) / (dur * 0.18)))
    return y * e


def sfx_hit(heavy=False, seed=0):
    """칼이 몸·갑옷에 닿는 소리: 딸깍(닿음) + 둥(몸통) + 바삭(갈라짐) + 쇳소리 조금"""
    r = np.random.default_rng(seed)
    dur = 0.42 if heavy else 0.26
    n = int(dur * SR)
    t = np.arange(n) / SR
    f0 = (95 if heavy else 140) * r.uniform(0.9, 1.1)
    body = np.sin(2 * np.pi * np.cumsum(f0 * (0.45 + 0.55 * np.exp(-t * 25))) / SR) * env_exp(n, 0.11 if heavy else 0.06, 0.0008)
    click = fft_filter(r.standard_normal(n), lo=2500, hi=9000) * env_exp(n, 0.004, 0.0002)
    crunch = fft_filter(r.standard_normal(n), lo=500, hi=3200) * env_exp(n, 0.05 if heavy else 0.03, 0.0005)
    metal = sum(np.sin(2 * np.pi * fr * r.uniform(0.95, 1.05) * t) * env_exp(n, d) * a
                for fr, d, a in [(1730, 0.05, 0.12), (2610, 0.035, 0.08), (3390, 0.025, 0.05)])
    y = body * 1.0 + click * 0.5 + crunch * (0.7 if heavy else 0.5) + metal
    # 영화식 무게: 아주 낮은 쿵을 깐다
    sub = np.sin(2 * np.pi * np.cumsum(38 + 40 * np.exp(-t * 30)) / SR) * env_exp(n, 0.12 if heavy else 0.07, 0.001)
    y += sub * (0.9 if heavy else 0.5)
    if heavy:
        y += fft_filter(r.standard_normal(n), lo=40, hi=200) * env_exp(n, 0.12) * 0.8
    return sat(y, 2.2 if heavy else 1.8)


def modal(n, modes, seed=0):
    r = np.random.default_rng(seed)
    t = np.arange(n) / SR
    return sum(a * np.sin(2 * np.pi * f * r.uniform(0.97, 1.03) * t + r.uniform(0, 6)) * env_exp(n, d, 0.0003)
               for f, d, a in modes)


def sfx_block(seed=0):
    """청동 방패: 나무 몸통 둔탁 + 청동 울림"""
    r = np.random.default_rng(seed)
    n = int(0.5 * SR)
    knock = fft_filter(r.standard_normal(n), lo=250, hi=1400, peaks=[(520, 150, 1.0)]) * env_exp(n, 0.025, 0.0004)
    ring = modal(n, [(610, 0.22, 0.35), (1410, 0.16, 0.3), (2230, 0.11, 0.22), (3150, 0.07, 0.15), (4020, 0.05, 0.1)], seed)
    thump = np.sin(2 * np.pi * 110 * tt(0.5)) * env_exp(n, 0.04)
    return sat(knock * 1.2 + ring + thump * 0.6, 1.6)


def sfx_parry():
    """패링: 칼날끼리 미끄러지는 날카로운 쇳소리"""
    n = int(1.1 * SR)
    ring = modal(n, [(1870, 0.5, 0.4), (2950, 0.42, 0.35), (4310, 0.3, 0.25), (5630, 0.22, 0.16), (7120, 0.15, 0.1)], 3)
    scrape = ola_filter(noise(n), lambda s: (3000 + 4000 * s, 7000 + 4000 * s), block=1024) * env_exp(n, 0.07, 0.002)
    hit = sfx_hit(False, 9)[:n] * 0.6
    y = mix(ring, scrape * 0.5, hit)
    return reverb(sat(y, 1.4), wet=0.22, dur=1.2, damp=7000)


def sfx_bow(seed=0):
    """활: 시위 튕김(낮은 현) + 화살 바람"""
    r = np.random.default_rng(seed)
    tw = pluck(98 * r.uniform(0.95, 1.05), 0.35, damp=0.985, bright=0.8, seed=seed)
    tw = fft_filter(tw, lo=80, hi=3000)
    n = int(0.35 * SR)
    wh = ola_filter(r.standard_normal(n), lambda s: (1800 - 2500 * s, 4500 - 4000 * s), block=1024) * env_exp(n, 0.12, 0.02)
    thump = np.sin(2 * np.pi * 70 * tt(0.35)) * env_exp(n, 0.03)
    return sat(tw * 1.2 + wh * 0.35 + thump * 0.5, 1.5)


def sfx_arrow_hit(seed=0):
    r = np.random.default_rng(seed)
    n = int(0.25 * SR)
    thunk = np.sin(2 * np.pi * np.cumsum(220 * (0.6 + 0.4 * np.exp(-tt(0.25) * 40))) / SR) * env_exp(n, 0.04)
    wood = fft_filter(r.standard_normal(n), lo=800, hi=3500, peaks=[(1200, 300, 1)]) * env_exp(n, 0.015)
    quiver = np.sin(2 * np.pi * 180 * tt(0.25)) * env_exp(n, 0.08) * (0.5 + 0.5 * np.sin(2 * np.pi * 38 * tt(0.25))) * 0.2
    return sat(thunk + wood * 0.8 + quiver, 1.5)


def voice(f_curve, vowel, dur, seed=0, breath=0.08):
    """사람 소리: 성대(배음) + 포먼트 + 숨. f_curve(t배열) → 기본 주파수"""
    r = np.random.default_rng(seed)
    t = tt(dur)
    f = f_curve(t) * (1 + 0.012 * np.sin(2 * np.pi * 6 * t) + 0.01 * np.cumsum(r.standard_normal(len(t))) / np.sqrt(len(t)))
    ph = 2 * np.pi * np.cumsum(f) / SR
    fm = float(np.mean(f))
    w = formant_w(vowel, 0.01)
    y = np.zeros(len(t))
    for k in range(1, 40):
        if fm * k > 6000:
            break
        y += w(fm * k, k) * np.sin(k * ph)
    y += fft_filter(r.standard_normal(len(t)), lo=600, hi=4000, peaks=[(vf, bw * 2, a) for vf, bw, a in vowel]) * breath
    return y


def sfx_cry():
    """전투의 함성: 오디세우스 + 부하들의 '와아—' (여러 목소리, 높아졌다 내려감)"""
    dur = 1.15
    y = np.zeros(int(1.5 * SR))
    for v in range(7):
        base = [120, 135, 150, 110, 165, 128, 142][v]
        off = v * 0.025

        def fc(t, b=base):
            return b * (1 + 0.35 * np.minimum(1, t / 0.18) - 0.25 * np.maximum(0, t - 0.6))
        vo = voice(fc, VOWEL_A, dur - off, seed=v, breath=0.15)
        t = tt(dur - off)
        e = np.minimum(1, t / 0.06) * np.clip((dur - off - t) / 0.35, 0, 1)
        at(y, vo * e * (1.0 if v == 0 else 0.55), off)
    y = sat(y * 0.6, 2.0)
    return reverb(y, wet=0.3, dur=1.4, damp=4500)


def sfx_shout(seed=0):
    """부대 명령 외침(짧게 '하!')"""
    dur = 0.35
    y = np.zeros(int(dur * SR))
    for v in range(3):
        vo = voice(lambda t, b=140 + v * 22 + seed * 7: b * (1.15 - 0.4 * t), VOWEL_A, dur, seed=seed * 5 + v, breath=0.2)
        y += vo * np.minimum(1, tt(dur) / 0.02) * np.exp(-tt(dur) / 0.12)
    return reverb(sat(y * 0.7, 1.8), wet=0.2, dur=0.8)


def sfx_death(seed=0):
    """쓰러짐: 짧은 신음 + 몸이 땅에 닿는 둥"""
    r = np.random.default_rng(seed)
    g = voice(lambda t: (150 + r.uniform(-20, 20)) * (1 - 0.45 * t / 0.4), VOWEL_U, 0.4, seed=seed, breath=0.25)
    g *= np.minimum(1, tt(0.4) / 0.02) * np.exp(-tt(0.4) / 0.15)
    n = int(0.5 * SR)
    thud = np.sin(2 * np.pi * np.cumsum(75 * (0.6 + 0.4 * np.exp(-tt(0.5) * 20))) / SR) * env_exp(n, 0.08)
    dirt = fft_filter(r.standard_normal(n), lo=150, hi=1800) * env_exp(n, 0.06)
    clank = modal(n, [(1250, 0.08, 0.15), (2100, 0.06, 0.1)], seed)
    body = thud + dirt * 0.5 + clank
    y = np.zeros(int(0.85 * SR))
    at(y, g * 0.7, 0.0)
    at(y, body, 0.28)
    return sat(y, 1.6)


def sfx_step(seed=0):
    r = np.random.default_rng(seed)
    n = int(0.09 * SR)
    y = fft_filter(r.standard_normal(n), lo=150, hi=2200, peaks=[(400 + seed * 60, 200, 1.0)]) * env_exp(n, 0.018, 0.001)
    y += np.sin(2 * np.pi * 90 * tt(0.09)) * env_exp(n, 0.015) * 0.5
    grit = fft_filter(r.standard_normal(n), lo=2500, hi=6000) * env_exp(n, 0.02) * 0.05
    return y + grit


def bell_strike(f=520.0, dur=2.6, seed=0):
    partials = [(0.5, 1.6, 0.5), (1.0, 1.2, 1.0), (1.183, 0.9, 0.55), (1.506, 0.7, 0.45), (2.0, 0.55, 0.35),
                (2.514, 0.4, 0.25), (2.662, 0.35, 0.2), (3.011, 0.25, 0.15), (4.166, 0.15, 0.1)]
    n = int(dur * SR)
    y = modal(n, [(f * r, d, a) for r, d, a in partials], seed)
    y += fft_filter(noise(n), lo=1500, hi=7000) * env_exp(n, 0.006) * 0.6
    return y


def sfx_bell():
    """경보 종: 땡—땡—땡 (청동 종 세 번)"""
    y = np.zeros(int(3.4 * SR))
    for i, t0 in enumerate([0.0, 0.55, 1.1]):
        at(y, bell_strike(540, 2.3, seed=i), t0, 1.0 - i * 0.1)
    return reverb(sat(y * 0.5, 1.3), wet=0.35, dur=2.2, damp=5000)


def sfx_horn():
    """뿔나팔: 낮게 길게 '뿌우—'"""
    y = horn(98, 1.4) * 1.0 + horn(98 * 1.5, 1.4) * 0.25
    y = fft_filter(y, lo=60, hi=3500)
    return reverb(y, wet=0.35, dur=2.0, damp=3000)


def sfx_gate():
    """성문: 묵직한 나무 삐걱임 + 쇠사슬 + 우르릉 + 쿵"""
    dur = 2.4
    n = int(dur * SR)
    t = tt(dur)
    rumble = fft_filter(noise(n), lo=30, hi=140) * fade(np.ones(n), 0.3, 0.5) * 1.2
    creak_f = 85 + 25 * np.sin(2 * np.pi * 0.7 * t) + 8 * np.sin(2 * np.pi * 3.1 * t)
    ph = 2 * np.pi * np.cumsum(creak_f) / SR
    creak = sum(np.sin(k * ph) / k for k in range(1, 25))
    creak = fft_filter(creak * (0.6 + 0.4 * (np.sin(2 * np.pi * 9 * t) > 0)), lo=200, hi=1600, peaks=[(450, 120, 1.0), (900, 200, 0.6)])
    creak *= fade(np.ones(n), 0.2, 0.6) * 0.5
    chain = np.zeros(n)
    tc = 0.1
    r = np.random.default_rng(4)
    while tc < dur - 0.6:
        at(chain, modal(int(0.08 * SR), [(r.uniform(2500, 4200), 0.03, 0.3), (r.uniform(5000, 7000), 0.02, 0.2)], int(tc * 100)), tc)
        tc += r.uniform(0.04, 0.13)
    boom = big_drum(1.0)
    y = rumble + creak + chain * 0.6
    at(y, boom * 0.9, dur - 0.75)
    y = np.concatenate([y, np.zeros(int(3.0 * SR))])
    at(y, gong(48, 3.5, 0.9, seed=7), dur - 0.75)
    return reverb(sat(y * 0.7, 1.5), wet=0.3, dur=1.8, damp=2500)


def sfx_winch(seed=0):
    """권양기 톱니: 나무+쇠 딸깍"""
    r = np.random.default_rng(seed)
    n = int(0.12 * SR)
    clack = fft_filter(r.standard_normal(n), lo=600, hi=3000, peaks=[(900 + seed * 80, 200, 1)]) * env_exp(n, 0.012)
    tick = modal(n, [(3100 + seed * 150, 0.02, 0.25), (4700, 0.015, 0.12)], seed)
    return clack + tick + np.sin(2 * np.pi * 160 * tt(0.12)) * env_exp(n, 0.02) * 0.4


def sfx_ui():
    y = lyre(midi(74), 0.35, seed=1) * 0.8
    return fft_filter(y, lo=300)


def sfx_ui_ok():
    """할 일 끝(튜토리얼 ✓): 리라 두 음 위로"""
    y = np.zeros(int(0.7 * SR))
    at(y, lyre(midi(69), 0.6, seed=2), 0.0)
    at(y, lyre(midi(74), 0.6, seed=3), 0.09)
    return reverb(y, wet=0.2, dur=1.0)


def sfx_checkpoint():
    y = np.zeros(int(1.5 * SR))
    for i, m in enumerate([62, 69, 74, 78]):
        at(y, lyre(midi(m), 1.1, seed=10 + i) * (1 - i * 0.1), i * 0.1)
    return reverb(y, wet=0.3, dur=1.6)


def sfx_alert():
    """적이 알아챔(!): 쇠붙이 '깡' + 낮은 쿵 + 일그러진 신시 찌름"""
    y = np.zeros(int(1.0 * SR))
    at(y, metal_hit(0.8, seed=31, bright=1.2), 0.0)
    at(y, sub_drop(0.8, 0.8), 0.0)
    st = synth_bass(midi(39), 0.35, 300, 2500, 4.0) * env_exp(int(0.35 * SR), 0.12)
    at(y, st * 0.5, 0.0)
    return reverb(sat(y, 1.5), wet=0.3, dur=1.4)


def sfx_takedown():
    """조용히 처치: 둔한 찌름 + 짧은 숨"""
    n = int(0.5 * SR)
    stab = np.sin(2 * np.pi * np.cumsum(120 * (0.5 + 0.5 * np.exp(-tt(0.5) * 30))) / SR) * env_exp(n, 0.05)
    wet = fft_filter(noise(n), lo=300, hi=1500) * env_exp(n, 0.04) * 0.6
    breath = fft_filter(noise(n), lo=900, hi=3500, peaks=[(1400, 400, 1)]) * np.minimum(1, tt(0.5) / 0.05) * np.exp(-tt(0.5) / 0.12)
    y = np.zeros(n)
    at(y, stab + wet, 0.0)
    at(y, breath * 0.25, 0.12)
    return sat(y, 1.4)


def crackle(n, density=18.0, seed=0, lo=1500, hi=8000):
    r = np.random.default_rng(seed)
    y = np.zeros(n)
    k = int(n / SR * density)
    pos = r.integers(0, max(1, n - 400), k)
    for p in pos:
        L = r.integers(30, 260)
        y[p:p + L] += r.standard_normal(L) * np.exp(-np.arange(L) / (L / 4)) * r.uniform(0.1, 1.0) ** 2
    return fft_filter(y, lo=lo, hi=hi)


def sfx_torch_out():
    n = int(0.7 * SR)
    hiss = fft_filter(noise(n), lo=2500, hi=9000) * env_exp(n, 0.18, 0.01)
    return hiss * 0.5 + crackle(n, 30, 1) * env_exp(n, 0.2) * 1.5


def sfx_torch_on():
    n = int(0.9 * SR)
    t = tt(0.9)
    whoosh = ola_filter(noise(n), lambda s: (150 + 400 * s, 800 + 2500 * s), block=1024)
    whoosh *= np.minimum(1, t / 0.15) * np.exp(-np.maximum(0, t - 0.15) / 0.25)
    return whoosh + crackle(n, 25, 2) * np.minimum(1, t / 0.2) * 1.2


def sfx_fire_burst():
    n = int(2.0 * SR)
    t = tt(2.0)
    whoosh = ola_filter(noise(n), lambda s: (80 + 200 * s, 400 + 1500 * min(1, s * 2)), block=2048)
    whoosh *= np.minimum(1, t / 0.25) * np.exp(-np.maximum(0, t - 0.3) / 0.6)
    boom = big_drum(0.8)
    y = whoosh * 1.4 + crackle(n, 45, 3) * np.minimum(1, t / 0.3) * 2.0
    at(y, boom, 0.0)
    return reverb(sat(y * 0.6, 1.5), wet=0.25, dur=1.5)


def sfx_stone(seed=0):
    """미끼 돌멩이가 돌바닥에 떨어져 튐: 딸깍-딱-딱"""
    r = np.random.default_rng(seed)
    y = np.zeros(int(0.5 * SR))
    tc, a = 0.0, 1.0
    for _ in range(4):
        n = int(0.05 * SR)
        c = fft_filter(r.standard_normal(n), lo=1200, hi=6000, peaks=[(r.uniform(2000, 3500), 400, 1)]) * env_exp(n, 0.006)
        at(y, c * a, tc)
        tc += r.uniform(0.06, 0.12) * a
        a *= 0.55
    return y


def sfx_switch():
    """무기 바꾸기: 가죽 스침 + 쇠 '칭'"""
    n = int(0.3 * SR)
    sc = ola_filter(noise(n), lambda s: (1500 + 3000 * s, 5000 + 3000 * s), block=512) * env_exp(n, 0.08, 0.02)
    ring = modal(n, [(3600, 0.1, 0.3), (5200, 0.07, 0.2)], 2)
    y = np.zeros(n)
    at(y, sc * 0.4, 0)
    at(y, ring, 0.09)
    return y


SFX = {
    "swing": [lambda s=s: sfx_swing(False, s) for s in range(3)],
    "swing_heavy": [lambda s=s: sfx_swing(True, 10 + s) for s in range(2)],
    "hit": [lambda s=s: sfx_hit(False, s) for s in range(4)],
    "hit_heavy": [lambda s=s: sfx_hit(True, 20 + s) for s in range(3)],
    "block": [lambda s=s: sfx_block(s) for s in range(3)],
    "parry": [sfx_parry],
    "bow": [lambda s=s: sfx_bow(s) for s in range(2)],
    "arrow_hit": [lambda s=s: sfx_arrow_hit(s) for s in range(2)],
    "cry": [sfx_cry],
    "shout": [lambda s=s: sfx_shout(s) for s in range(3)],
    "death": [lambda s=s: sfx_death(s) for s in range(3)],
    "step": [lambda s=s: sfx_step(s) for s in range(4)],
    "bell": [sfx_bell],
    "horn": [sfx_horn],
    "gate": [sfx_gate],
    "winch": [lambda s=s: sfx_winch(s) for s in range(2)],
    "ui": [sfx_ui],
    "ui_ok": [sfx_ui_ok],
    "checkpoint": [sfx_checkpoint],
    "alert": [sfx_alert],
    "takedown": [sfx_takedown],
    "torch_out": [sfx_torch_out],
    "torch_on": [sfx_torch_on],
    "fire_burst": [sfx_fire_burst],
    "stone": [lambda s=s: sfx_stone(s) for s in range(2)],
    "switch": [sfx_switch],
}


# ── 환경음 (스테레오, 반복) ───────────────────────────
def amb_wind(dur=32.0):
    n = int((dur + 2) * SR)
    out = []
    for ch in range(2):
        r = np.random.default_rng(100 + ch)
        ph = r.uniform(0, 6)
        y = ola_filter(r.standard_normal(n), lambda s: (180 + 140 * np.sin(s * 0.37 + ph) + 60 * np.sin(s * 1.3 + ph),
                                                         600 + 400 * np.sin(s * 0.29 + ph * 2) + 200 * np.sin(s * 0.9)), block=4096)
        t = np.arange(n) / SR
        y *= 0.6 + 0.4 * np.sin(2 * np.pi * t / 11.0 + ph) ** 2
        y += fft_filter(r.standard_normal(n), lo=25, hi=90) * 0.5
        out.append(y)
    return loopify(np.stack(out, 1), 2.0)


def amb_fire(dur=24.0):
    n = int((dur + 2) * SR)
    out = []
    for ch in range(2):
        r = np.random.default_rng(200 + ch)
        t = np.arange(n) / SR
        roar = fft_filter(r.standard_normal(n), lo=40, hi=260) * (0.7 + 0.3 * np.sin(2 * np.pi * t / 5.3 + ch))
        y = roar * 0.9 + crackle(n, 22, 300 + ch, 1200, 7000) * 2.2 + crackle(n, 6, 310 + ch, 300, 2000) * 1.5
        out.append(y)
    return loopify(np.stack(out, 1), 2.0)


def amb_sea(dur=36.0):
    """파도: 밀려오고(커지며 밝아짐) 부서져 빠지는(쏴아) 소리가 6~9초마다"""
    n = int((dur + 3) * SR)
    out = np.zeros((n, 2))
    r = np.random.default_rng(400)
    tc = 0.0
    while tc < dur + 1:
        L = r.uniform(5.5, 8.5)
        m = int(L * SR)
        t = np.arange(m) / SR
        rise = L * 0.45
        e = np.where(t < rise, (t / rise) ** 1.5, np.exp(-(t - rise) / (L * 0.22)))
        body = ola_filter(r.standard_normal(m), lambda s, rise=rise, L=L: (60, 300 + 1400 * (min(s, rise) / rise) * np.exp(-max(0, s - rise) / L * 2)), block=4096)
        wash = fft_filter(r.standard_normal(m), lo=1500, hi=7000) * np.where(t < rise, 0, np.exp(-(t - rise) / 1.2)) * 0.35
        p = r.uniform(-0.5, 0.5)
        at(out, pan((body * e + wash) * r.uniform(0.7, 1.0), p), tc)
        tc += r.uniform(3.5, 5.5)
    out += np.stack([fft_filter(noise(n), lo=30, hi=120), fft_filter(noise(n), lo=30, hi=120)], 1) * 0.3
    return loopify(out, 3.0)


def amb_battle(dur=30.0):
    """먼 전투: 칼 부딪는 소리, 외침, 웅성거림. 멀리서 들리게 높은 소리를 깎고 잔향을 많이"""
    n = int((dur + 2) * SR)
    out = np.zeros((n, 2))
    r = np.random.default_rng(500)
    for i in range(int(dur * 9)):
        tc = r.uniform(0, dur + 1)
        m = int(0.4 * SR)
        k = modal(m, [(r.uniform(1500, 2600), 0.08, 0.5), (r.uniform(2800, 4200), 0.05, 0.3)], i) + \
            fft_filter(r.standard_normal(m), lo=800, hi=3000) * env_exp(m, 0.01) * 0.5
        at(out, pan(k * r.uniform(0.1, 0.5), r.uniform(-0.9, 0.9)), tc)
    for i in range(int(dur * 1.5)):
        tc = r.uniform(0, dur + 1)
        d = r.uniform(0.3, 0.9)
        b = r.uniform(110, 190)
        vo = voice(lambda t, b=b: b * (1.1 + 0.2 * np.sin(t * 6) - 0.3 * t), [VOWEL_A, VOWEL_O][i % 2], d, seed=600 + i, breath=0.2)
        vo *= np.minimum(1, tt(d) / 0.05) * np.clip((d - tt(d)) / 0.2, 0, 1)
        at(out, pan(vo * r.uniform(0.1, 0.35), r.uniform(-0.9, 0.9)), tc)
    crowd = np.stack([fft_filter(noise(n), lo=150, hi=700, peaks=[(400, 150, 1)]) for _ in range(2)], 1)
    t = np.arange(n) / SR
    crowd *= (0.6 + 0.4 * np.sin(2 * np.pi * t / 7.0))[:, None] * 0.25
    out = out + crowd
    out = np.stack([fft_filter(out[:, c], lo=80, hi=2200) for c in range(2)], 1)
    out = stereo_reverb(out, wet=0.6, dur=2.5, damp=2000)[:n]
    return loopify(out, 2.0)


AMB = {"wind": amb_wind, "fire": amb_fire, "sea": amb_sea, "battle": amb_battle}


# ── 음악 ──────────────────────────────────────────────
# 느낌: 영화 《오디세이》(2026) 음악처럼 — 오케스트라 없이 고대 악기(리라·아울로스·청동 징·두드린 쇠붙이)와
# 그 소리를 일그러뜨린 신시사이저, 말 없는 목소리·합창. 무겁고 쓸쓸하고 으스스하게. 선율·화성은 모두 이 게임용으로 새로 만든 것.
# 선법: D 에올리안(D E F G A Bb C) · D 프리지안(D Eb F G A Bb C)

def place_melody(buf, notes, beat, start, inst, p=0.0, gain=1.0, octave=0, legato=1.0, seed=0):
    """notes: [(미디 음 또는 None 쉼표, 박 수)]"""
    tc = start
    for i, (m, b) in enumerate(notes):
        if m is not None:
            d = b * beat * legato
            at(buf, pan(inst(midi(m + octave), d + 0.05, seed=seed + i) * gain, p), tc)
        tc += b * beat
    return tc


def gong(f=62.0, dur=7.0, vel=1.0, seed=0):
    """청동 징(탐탐): 촘촘한 비정수 배음. 높은 배음이 늦게 피어올랐다(bloom) 길게 사라진다"""
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for i in range(48):
        ratio = 1.0 + (i ** 1.35) * 0.21 + r.uniform(-0.05, 0.05)
        fk = f * ratio
        if fk > 9000:
            break
        bloom = 0.02 + 0.5 * (i / 48) ** 1.3          # 높은 배음일수록 늦게 커진다
        decay = dur * (0.55 - 0.4 * i / 48)
        a = r.uniform(0.5, 1.0) / ratio ** 0.6
        beat = 1 + 0.15 * np.sin(2 * np.pi * r.uniform(0.3, 2.0) * t + r.uniform(0, 6))   # 맥놀이로 일렁임
        y += a * np.sin(2 * np.pi * fk * t + r.uniform(0, 6)) * (1 - np.exp(-t / bloom)) * np.exp(-t / decay) * beat
    y += fft_filter(r.standard_normal(n), lo=60, hi=900) * env_exp(n, 0.05, 0.001) * 0.5   # 채로 친 둔한 소리
    return y * vel * 0.4


def gong_swell(dur=4.0, f=62.0, seed=0):
    """거꾸로 튼 징: 점점 커져 다음 마디 첫 박에 꽂힌다"""
    g = gong(f, dur + 0.5, 1.0, seed)[:int(dur * SR)]
    return fade(g[::-1], 0.3, 0.02)


def metal_hit(vel=1.0, seed=0, bright=1.0):
    """두드린 쇠붙이(난간·철판): 비정수 울림 몇 개 + 딱 소리, 살짝 일그러뜨림"""
    r = np.random.default_rng(seed)
    n = int(0.9 * SR)
    modes = [(r.uniform(180, 420) * bright, r.uniform(0.15, 0.35), 0.6), (r.uniform(600, 1100) * bright, r.uniform(0.1, 0.25), 0.5),
             (r.uniform(1300, 2400) * bright, r.uniform(0.06, 0.15), 0.4), (r.uniform(2600, 4800) * bright, r.uniform(0.03, 0.08), 0.3)]
    y = modal(n, modes, seed)
    y += fft_filter(r.standard_normal(n), lo=900, hi=7000) * env_exp(n, 0.006, 0.0003) * 0.8
    return sat(y * 1.4, 2.0) * vel


def bowed_metal(f, dur, seed=0):
    """활로 긁은 쇠(으스스한 지속음): 비정수 배음 몇 개가 천천히 부풀었다 줄어든다 + 마찰 잡음"""
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for ratio, a in [(1.0, 1.0), (2.76, 0.5), (5.4, 0.3), (8.93, 0.15)]:
        sw = 0.5 + 0.5 * np.sin(2 * np.pi * r.uniform(0.07, 0.25) * t + r.uniform(0, 6))
        y += a * sw * np.sin(2 * np.pi * f * ratio * (1 + 0.002 * np.sin(2 * np.pi * 0.4 * t)) * t)
    y += fft_filter(r.standard_normal(n), lo=f * 2, hi=f * 9) * 0.08
    e = np.minimum(1, t / (dur * 0.35)) * np.minimum(1, (dur - t) / (dur * 0.35))
    return y * e * 0.4


def synth_bass(f, dur, cut0=180.0, cut1=1400.0, drive=3.0, seed=None):
    """일그러진 신시 베이스: 톱니파, 필터가 cut0→cut1로 열렸다 닫히고 세게 일그러뜨린다(거친 전자음)"""
    t = tt(dur)
    cut = cut0 + (cut1 - cut0) * np.exp(-t / max(0.03, dur * 0.3))
    ph = 2 * np.pi * f * t
    y = np.zeros(len(t))
    for k in range(1, 40):
        if f * k > 8000:
            break
        y += np.sin(k * ph) / k / np.sqrt(1 + (f * k / cut) ** 4)
    y += np.sin(ph * 0.5) * 0.3   # 한 옥타브 아래
    e = np.minimum(1, t / 0.005) * np.minimum(1, (dur - t) / 0.03)
    return sat(y * e, drive) * 0.5


def sub_drop(dur=2.0, vel=1.0):
    """영화식 낮은 쿵: 55Hz에서 28Hz로 떨어지는 사인 + 일그러짐"""
    t = tt(dur)
    f = 28 + 30 * np.exp(-t * 3)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(len(t), dur * 0.4, 0.002)
    return sat(y * 1.5, 2.0) * vel


def pulse_tick(vel=1.0, seed=0):
    """째깍이는 긴장 박(낮은 펄스 + 짧은 금속 틱)"""
    n = int(0.25 * SR)
    y = np.sin(2 * np.pi * 50 * tt(0.25)) * env_exp(n, 0.05, 0.001) * 0.8
    y += modal(n, [(2300, 0.02, 0.2), (3700, 0.015, 0.12)], seed)
    return y * vel


VOWEL_A_HI = [(850, 140, 1.0), (1250, 160, 0.6), (2900, 260, 0.3)]
VOWEL_O_HI = [(560, 110, 1.0), (950, 140, 0.5), (2800, 240, 0.15)]


def lament(notes, beat, vowel=VOWEL_A_HI, seed=0, glide=0.09):
    """말 없는 목소리 한 줄(애가): 음 사이를 미끄러지고, 길게 끄는 음에 떨림이 붙는다. notes: [(미디 또는 None, 박)]"""
    total = sum(b for _, b in notes) * beat
    n = int((total + 0.6) * SR)
    f0 = np.zeros(n)
    amp = np.zeros(n)
    tc = 0.0
    last = None
    for m, b in notes:
        i0, i1 = int(tc * SR), int((tc + b * beat) * SR)
        if m is None:
            if last is not None:
                f0[i0:i1] = midi(last)
            tc += b * beat
            continue
        tgt = midi(m)
        seg = np.full(i1 - i0, tgt)
        if last is not None and amp[max(0, i0 - 1)] > 0:
            k = min(len(seg), int(glide * SR))
            seg[:k] = np.geomspace(midi(last), tgt, k)
        f0[i0:i1] = seg
        a = np.ones(i1 - i0)
        k = int(0.04 * SR)
        a[:k] = np.minimum(a[:k], np.linspace(0.3, 1, k))
        amp[i0:i1] = a
        last = m
        tc += b * beat
    f0[f0 == 0] = midi(notes[0][0] or 69)
    # 쉼표 앞뒤로 부드럽게
    sm = int(0.08 * SR)
    amp = np.convolve(amp, np.ones(sm) / sm, mode="same")
    t = np.arange(n) / SR
    vib = 1 + 0.018 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, np.maximum(0, np.convolve(amp, np.ones(int(0.5 * SR)) / (0.5 * SR), "same") - 0.6) * 2.5)
    fcur = f0 * vib
    y = voice(lambda tt_: np.interp(tt_, t, fcur), vowel, n / SR, seed=seed, breath=0.12)
    return y * amp * 0.6


def aulos_fx(f, dur, vel=1.0, seed=None):
    """신시로 손본 아울로스: 원음 + 한 옥타브 아래 일그러진 겹소리 + 짧은 메아리"""
    a = aulos(f, dur, 1.0, seed=seed)
    low = sat(aulos(f / 2, dur, 1.0, seed=(seed or 0) + 50) * 2.0, 2.5) * 0.35
    y = a + low
    d = int(0.19 * SR)
    y = np.concatenate([y, np.zeros(d)])
    y[d:] += y[:-d] * 0.3
    return y * vel


def track_theme():
    """타이틀: 징이 피어오르고, 낮은 지속음 위로 리라, 이어서 말 없는 목소리의 애가. 66박/분, 16마디"""
    beat = 60 / 66
    bar = 4 * beat
    bars = 16
    L = int(bars * bar * SR)
    buf = np.zeros((L + int(6 * SR), 2))
    chords = [[38, 57, 62, 65], [34, 58, 62, 65], [36, 55, 60, 64], [33, 57, 61, 64]]
    dr = drone_loop(midi(26), L, bright=500, seed=1) + drone_loop(midi(38), L, bright=700, seed=2) * 0.4
    at(buf, pan(sat(dr * 0.8, 1.6) * 0.4, 0.0), 0)
    at(buf, pan(gong(55, 9.0, 0.9, seed=1), 0.0), 0.0)
    at(buf, pan(gong(55, 9.0, 0.8, seed=2), 0.1), 8 * bar)
    for b in range(bars):
        ch = chords[(b // 2) % 4]
        for i in range(6):
            m = ch[1 + [0, 1, 2, 1, 2, 1][i]]
            at(buf, pan(lyre(midi(m), 2.2, 0.32 if b < 8 else 0.25, seed=b * 6 + i), -0.4 + 0.15 * i), b * bar + i * bar / 6)
        if b % 4 == 3:
            at(buf, pan(gong_swell(bar, 110, seed=b), 0.0), b * bar)
    for b in [4, 12]:
        at(buf, pan(bowed_metal(midi(74), 4 * bar, seed=b) * 0.35, 0.5), b * bar)
    # 리라 주제(앞 8마디) → 목소리(뒤 8마디)
    motif = [(69, 1), (70, 1), (69, 1.5), (65, .5), (67, 2), (62, 2),
             (65, 1), (67, 1), (69, 1), (72, 1), (70, 3), (None, 1),
             (69, 1), (70, 1), (72, 1.5), (70, .5), (69, 2), (65, 2),
             (64, 1), (65, 1), (61, 2), (62, 4)]
    place_melody(buf, motif, beat, 0.0, lambda f, d, seed: lyre(f, d + 1.5, 0.9, seed=seed), p=0.15, gain=0.75)
    v = lament([(m + 12 if m else None, b) for m, b in motif], beat, VOWEL_A_HI, seed=3)
    at(buf, pan(v * 0.55, 0.05), 8 * bar)
    at(buf, pan(aulos_fx(midi(50), 4 * bar, 0.35, seed=9), -0.3), 12 * bar)
    out = stereo_reverb(buf, wet=0.45, dur=4.0, damp=3500)
    return wrap_tail(out, L)


def track_stealth():
    """잠입: 숨죽인 낮은 지속음, 심장 같은 낮은 쿵, 활로 긁은 쇠, 먼 아울로스 숨결, 거꾸로 피는 징. 60박/분, 12마디"""
    beat = 1.0
    bars = 12
    L = int(bars * 4 * SR)
    buf = np.zeros((L + int(5 * SR), 2))
    r = np.random.default_rng(77)
    dr = drone_loop(midi(26), L, bright=350, seed=1) * 0.9 + drone_loop(midi(33), L, bright=450, seed=2) * 0.3
    t = np.arange(L) / SR
    dr *= 0.7 + 0.3 * np.sin(2 * np.pi * t / 16.0)
    at(buf, pan(sat(dr, 1.4) * 0.45, 0.0), 0)
    for b in range(bars):
        at(buf, pan(sub_drop(0.6, 0.35), 0.0), b * 4)
        at(buf, pan(sub_drop(0.5, 0.22), 0.0), b * 4 + 0.35)
        if b % 2 == 1:
            at(buf, pan(metal_hit(0.08, seed=b, bright=1.6), r.uniform(-0.7, 0.7)), b * 4 + r.uniform(1.5, 3.2))
    for b, m in [(0, 62), (6, 63)]:
        at(buf, pan(bowed_metal(midi(m), 14.0, seed=b) * 0.5, -0.4 if b else 0.4), b * 4 + 1)
    for b in [3, 7, 11]:
        at(buf, pan(gong_swell(4.0, 70, seed=b) * 0.6, 0.0), b * 4)
    phrases = [[(50, 1), (51, 1), (50, 2)], [(57, 1.5), (55, 0.5), (53, 1), (51, 1)], [(62, 2), (63, 1), (62, 1)],
               [(53, 0.5), (51, 0.5), (50, 3)]]
    for b in range(0, bars, 3):
        ph = phrases[(b // 3) % len(phrases)]
        place_melody(buf, ph, beat, b * 4 + 1.5 + r.uniform(0, 0.3), lambda f, d, seed: lyre(f, d + 1.8, 0.6, seed=seed),
                     p=r.uniform(-0.5, 0.5), gain=0.5, seed=b * 10)
    for b in [5, 10]:
        at(buf, pan(fft_filter(aulos_fx(midi(62), 3.5, 0.25, seed=b), hi=1800), 0.6), b * 4 + 0.5)
    out = stereo_reverb(buf, wet=0.55, dur=4.0, damp=2500)
    return wrap_tail(out, L)


BATTLE_RIFF = [(62, .5), (63, .5), (62, .5), (60, .5), (62, 1), (57, 1),
               (58, .5), (57, .5), (55, .5), (57, .5), (62, 2)]
BATTLE_MEL = [(74, 1.5), (75, .5), (74, 1), (70, 1),
              (72, 1), (70, .5), (69, .5), (67, 2),
              (65, 1), (67, 1), (69, 1), (70, 1),
              (69, 3), (None, 1),
              (77, 1.5), (75, .5), (74, 1), (72, 1),
              (70, 1), (72, .5), (70, .5), (69, 2),
              (67, 1), (65, 1), (63, 1), (65, 1),
              (62, 4)]


def track_battle(intense=False):
    """전투(intense면 성문 사수): 큰북·틀북·두드린 쇠붙이, 일그러진 신시 베이스 8분음표, 신시로 손본 아울로스 리프.
    성문 사수는 낮은 합창 구호, 말 없는 목소리, 징 몰아치기, 낮은 쿵이 더해진다. 120박/분, 16마디"""
    beat = 60 / 120
    bars = 16
    bar = 4 * beat
    L = int(bars * bar * SR)
    buf = np.zeros((L + int(6 * SR), 2))
    roots = [38, 38, 34, 36]   # D D Bb C (2마디씩)
    s16 = beat / 4
    boom_steps = [0, 6, 8, 11] if not intense else [0, 3, 6, 8, 10, 11, 14]
    for b in range(bars):
        t0 = b * bar
        for st in boom_steps:
            at(buf, pan(big_drum(0.9 if st in (0, 8) else 0.6), 0.0), t0 + st * s16)
        for st in [4, 12]:
            at(buf, pan(metal_hit(0.45, seed=b * 2 + st, bright=0.8), 0.3), t0 + st * s16)
            at(buf, pan(frame_drum(False, 0.5), -0.2), t0 + st * s16)
        for st in [2, 10, 14] + ([7, 15] if intense else []):
            at(buf, pan(frame_drum(False, 0.25), -0.35), t0 + st * s16)
        if b % 4 == 3:
            at(buf, pan(gong_swell(bar, 80, seed=b) * (0.9 if intense else 0.6), 0.0), t0)
            if intense:
                for st in range(8, 16, 2 if b % 8 != 7 else 1):
                    at(buf, pan(metal_hit(0.3, seed=500 + b * 16 + st, bright=1.3), (st % 3 - 1) * 0.5), t0 + st * s16)
        if b % 4 == 0:
            at(buf, pan(gong(60, 4 * bar, 0.7 if intense else 0.45, seed=b), 0.0), t0)
            if intense:
                at(buf, pan(sub_drop(2.0, 0.9), 0.0), t0)
        root = roots[(b // 2) % 4]
        pat = [0, 0, 12, 0, 1, 0, 12, -2]
        for i in range(8):
            at(buf, pan(synth_bass(midi(root + pat[i]), beat / 2 * 0.85, 150, 900 if not intense else 1600, 3.0 if not intense else 4.0)
                        * 0.45, 0.0), t0 + i * beat / 2)
    if not intense:
        for b in range(0, bars, 2):
            if b >= 4:
                place_melody(buf, BATTLE_RIFF, beat, b * bar, aulos_fx, p=0.2, gain=0.45, seed=b * 20)
        place_melody(buf, BATTLE_MEL, beat, 8 * bar, lambda f, d, seed: lyre(f, d + 0.5, 0.8, seed=seed), p=-0.25, gain=0.5, octave=-12)
    else:
        for b in range(0, bars, 2):
            place_melody(buf, BATTLE_RIFF, beat, b * bar, aulos_fx, p=0.2, gain=0.42, seed=b * 20)
        # 낮은 남성 합창 구호(마디 첫 박마다 '오!')
        chord = {38: [50, 57, 62], 34: [46, 53, 58], 36: [48, 55, 60]}
        for b in range(bars):
            root = roots[(b // 2) % 4]
            for st in ([0, 6] if b % 2 == 0 else [0, 6, 12]):
                for m in chord[root]:
                    c = choir(midi(m), 0.32, VOWEL_O, 3, seed=b * 7 + m + st)
                    at(buf, pan(c * 0.3, -0.4 + (m % 4) * 0.25), b * bar + st * s16)
        at(buf, pan(lament([(m, b) for m, b in BATTLE_MEL], beat, VOWEL_A_HI, seed=8) * 0.5, 0.1), 0.0)
        at(buf, pan(lament([(m, b) for m, b in BATTLE_MEL], beat, VOWEL_A_HI, seed=9) * 0.5, -0.1), 8 * bar)
    out = stereo_reverb(buf, wet=0.25, dur=2.2, damp=4000)
    return wrap_tail(out, L)


def track_ending():
    """엔딩(출항): 쓸쓸한 리라, 말 없는 목소리의 애가, 멀리 징. 60박/분, 16마디"""
    beat = 1.0
    bar = 4.0
    bars = 16
    L = int(bars * bar * SR)
    buf = np.zeros((L + int(6 * SR), 2))
    chords = [[38, 57, 62, 65], [34, 58, 62, 65], [36, 55, 60, 64], [33, 57, 61, 64]]
    dr = drone_loop(midi(26), L, bright=400, seed=5)
    at(buf, pan(dr * 0.3, 0.0), 0)
    for b in range(bars):
        ch = chords[(b // 2) % 4]
        for i in range(6):
            m = ch[1 + [0, 1, 2, 1, 2, 1][i]] + (12 if b >= 8 else 0)
            at(buf, pan(lyre(midi(m), 2.4, 0.28, seed=b * 6 + i), -0.3 + 0.12 * i), b * bar + i * bar / 6)
        at(buf, pan(lyre(midi(ch[0]), 3.5, 0.45, seed=900 + b), 0.0), b * bar)
        if b % 2 == 0:
            for m in ch[1:]:
                at(buf, pan(choir(midi(m), 2 * bar + 0.5, VOWEL_O, 3, seed=b * 3 + m) * 0.16, -0.3 + (m % 3) * 0.3), b * bar)
        if b % 8 == 0:
            at(buf, pan(gong(50, 10.0, 0.6, seed=b), 0.0), b * bar)
    mel = [(69, 2), (70, 1), (69, 1), (67, 2), (65, 2),
           (64, 1.5), (65, .5), (67, 2), (69, 4),
           (74, 2), (72, 1), (70, 1), (69, 2), (67, 1), (65, 1),
           (64, 2), (61, 2), (62, 4)]
    at(buf, pan(lament(mel, beat, VOWEL_A_HI, seed=21) * 0.6, 0.05), 4 * bar)
    place_melody(buf, mel[:8], beat, 12 * bar, aulos_fx, p=0.3, gain=0.3, octave=-12)
    out = stereo_reverb(buf, wet=0.5, dur=4.5)
    return wrap_tail(out, L)


def track_victory():
    """승리(챕터 클리어): 징 + 큰북 + 합창 화음 + 목소리 한 줄"""
    beat = 60 / 80
    buf = np.zeros((int(10 * SR), 2))
    for i, b in enumerate([0, 1, 2, 2.5, 3]):
        at(buf, pan(big_drum(1.0 if i in (0, 4) else 0.7), 0.0), b * beat)
    at(buf, pan(gong(58, 8.0, 1.0, seed=3), 0.0), 3 * beat)
    at(buf, pan(sub_drop(2.5, 0.8), 0.0), 3 * beat)
    for m in [50, 57, 62, 66, 69]:
        at(buf, pan(choir(midi(m), 5.0, VOWEL_A, 3, seed=m) * 0.3, -0.4 + (m % 5) * 0.2), 3 * beat)
    at(buf, pan(lament([(74, 1), (76, 1), (78, 4)], beat, VOWEL_A_HI, seed=4) * 0.6, 0.0), 3 * beat)
    out = stereo_reverb(buf, wet=0.4, dur=3.5)
    return fade(out[:int(10 * SR)], 0, 2.0)


def track_defeat():
    """쓰러짐: 낮은 쿵, 멀어지는 징, 내려앉는 목소리"""
    buf = np.zeros((int(7 * SR), 2))
    at(buf, pan(sub_drop(3.0, 1.0), 0), 0)
    at(buf, pan(gong(48, 6.5, 0.7, seed=9), 0), 0)
    at(buf, pan(lament([(65, 1.5), (64, 1), (62, 3)], 0.8, VOWEL_O_HI, seed=6) * 0.5, 0), 0.4)
    at(buf, pan(lyre(midi(38), 4.0, 0.8, seed=5), 0), 0.0)
    out = stereo_reverb(buf, wet=0.45, dur=3.5)
    return fade(out[:int(7 * SR)], 0, 2.0)


MUSIC = {"theme": track_theme, "stealth": track_stealth, "battle": lambda: track_battle(False),
         "siege": lambda: track_battle(True), "ending": track_ending, "victory": track_victory, "defeat": track_defeat}


# ── 저장 ──────────────────────────────────────────────
def write_wav(path, x):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1 if x.ndim == 1 else 2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def write_ogg(path, x, q=4):
    tmp = path.with_suffix(".tmp.wav")
    write_wav(tmp, x)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", str(q), str(path)], check=True)
    tmp.unlink()


def trim(x, floor=0.002):
    """끝의 거의 안 들리는 꼬리(-54dB 아래)를 자른다"""
    idx = np.nonzero(np.abs(x) > floor)[0]
    return x[:idx[-1] + int(0.01 * SR)] if len(idx) else x


def master_eq(st):
    """음악 마무리 소리 다듬기: 38Hz 아래 자르기, 150Hz 아래 살짝 줄이고, 2~4kHz(리라·아울로스·목소리)를 살린다.
    작은 스피커에서도 선율이 들리게."""
    out = []
    for c in range(st.shape[1]):
        x = st[:, c]
        n = len(x)
        m = n   # 덧붙임 없이 = 고리 모양 필터(반복 곡은 끝과 처음이 이어진 채로 걸러진다)
        X = np.fft.rfft(x, m)
        f = np.fft.rfftfreq(m, 1 / SR)
        g = 1 / np.sqrt(1 + (38 / np.maximum(f, 1e-3)) ** 4)
        g *= 0.55 + 0.45 / np.sqrt(1 + (150 / np.maximum(f, 1e-3)) ** 4)       # 저음 선반 약 -5dB
        g *= 1 + 0.9 * np.exp(-((np.log2(np.maximum(f, 1) / 2800)) / 0.9) ** 2)   # 2.8kHz 부근 +5.5dB
        out.append(np.fft.irfft(X * g, m)[:n])
    return np.stack(out, 1)


def loudness(x, target_rms=0.12, peak=0.95):
    """음악·환경음 크기 맞추기: 평균 세기를 맞추되 봉우리가 넘지 않게"""
    rms = np.sqrt(np.mean(x ** 2)) + 1e-9
    y = x * (target_rms / rms)
    m = np.max(np.abs(y))
    if m > peak:
        y = sat(y / m * 1.1, 1.1) * peak
    return y


def main(root, which=("sfx", "amb", "music")):
    out = Path(root) / "assets/audio"
    if "sfx" in which:
        d = out / "sfx"
        d.mkdir(parents=True, exist_ok=True)
        for name, makers in SFX.items():
            for i, mk in enumerate(makers):
                fn = f"{name}.wav" if len(makers) == 1 else f"{name}_{i + 1}.wav"
                write_wav(d / fn, fade(trim(norm(mk(), 0.89)), 0, 0.01))
        print("효과음", sum(len(v) for v in SFX.values()), "개")
    if "amb" in which:
        d = out / "amb"
        d.mkdir(parents=True, exist_ok=True)
        for name, mk in AMB.items():
            write_ogg(d / f"{name}.ogg", loudness(mk(), 0.10), q=3)
            print("환경음", name)
    if "music" in which:
        d = out / "music"
        d.mkdir(parents=True, exist_ok=True)
        for name, mk in MUSIC.items():
            write_ogg(d / f"{name}.ogg", loudness(master_eq(mk()), 0.13), q=4)
            print("음악", name)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".", tuple(sys.argv[2:]) or ("sfx", "amb", "music"))
