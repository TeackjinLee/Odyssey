"""걷기·달리기 12장 움직임 안내 그림(Codex 요청에 붙인다). 다리·팔을 옆 평면(앞 u, 높이 h)에서 풀고 화면으로 비춘다.
디딘 발은 한 장마다 같은 만큼 뒤로 가고, 팔은 같은 쪽 다리와 반대로 흔든다.
달리기(run)는 디딘 발이 3장만 땅에 닿고(한 장마다 걷기보다 많이 뒤로) 나머지는 두 발이 다 뜨며,
뒷발은 엉덩이 쪽으로 차올렸다가 무릎을 높이 들어 앞으로 뻗고, 팔은 직각으로 굽혀 크게 젓는다.
사용: python3 tools/walk_guide.py <출력.png> <앞 x> <앞 y> <오른쪽 x> <오른쪽 y> [back] [run]
  동 1 0 0 0.5 / 남동 0.71 0.35 -0.71 0.35 / 북동 0.71 -0.35 0.71 0.35 / 북 0 -0.3 1.6 0 back / 남 0 0.3 -1.6 0 back
"""
import math, sys
from PIL import Image, ImageDraw
out, fx, fy, rx, ry = sys.argv[1], *map(float, sys.argv[2:6])   # 앞 방향·오른쪽 방향의 화면 벡터
BACK = "back" in sys.argv[6:]   # 앞·뒷모습: 다리가 한 줄로 겹치므로 무릎을 바깥으로 빼고 든 발은 발바닥을 그린다
RUN = "run" in sys.argv[6:]
CW, CH = 384, 341
L, TH, SH, LIFT, HIP, SIDE = 62, 70, 70, 30, 134, 14
# 달리기 한 발의 12장 궤적(u, h): 0~2 디딤(한 장에 RUN_STEP씩 뒤로), 3~5 차고 올림, 6~8 무릎 들어 앞으로, 9~11 내려 디딤 준비
RUN_STEP = 24   # 118px/s ÷ 26fps를 걷기와 같은 비율로 바꾼 값
RUN_FOOT = [(RUN_STEP, 0), (0, 0), (-RUN_STEP, 0), (-50, 22), (-42, 58), (-24, 80),
            (6, 82), (36, 70), (58, 46), (60, 20), (46, 8), (34, 3)]
img = Image.new("RGB", (CW*4, CH*3), (255,255,255)); dr = ImageDraw.Draw(img)
def ik(hu, hh, fu, fh):
    du, dh = fu-hu, fh-hh; d = min(math.hypot(du, dh), TH+SH-1)
    a = math.atan2(dh, du); b = math.acos((TH*TH+d*d-SH*SH)/(2*TH*d))
    return hu+TH*math.cos(a+b), hh+TH*math.sin(a+b)        # 무릎은 앞으로
for i in range(12):
    c, r = i % 4, i // 4; ox, oy = c*CW + CW//2, r*CH + 265
    if RUN:
        legs = {"R": RUN_FOOT[i], "L": RUN_FOOT[(i + 6) % 12]}
        hip = (6.0, HIP + (-4, -8, -4, 4, 8, 4)[i % 6])   # 디딜 때 낮고 떴을 때 높다
        step = RUN_STEP
    else:
        t = (i % 6) / 6
        sup = (L - 2*L*t, 0.0)
        sw = (-L + 2*L*(0.5-0.5*math.cos(math.pi*t)), math.sin(math.pi*t)*LIFT)
        hip = (0.0, HIP - 4*math.cos(2*math.pi*t))
        legs = {"R": sup, "L": sw} if i < 6 else {"L": sup, "R": sw}
        step = 2*L/6
    P = lambda u, h, s: (ox + u*fx + s*rx, oy + u*fy + s*ry - h)
    # 땅 눈금(앞 방향 선 위에서 디딘 발과 같이 뒤로)
    a0, a1 = P(-150, 0, 0), P(150, 0, 0); dr.line([a0, a1], fill=(150,150,150), width=2)
    for k in range(-7, 8):
        u = k*20 - (i*step) % 20; p = P(u, 0, 0); dr.ellipse([p[0]-3, p[1]-3, p[0]+3, p[1]+3], fill=(150,150,150))
    parts = []
    lean = 10 if RUN else 0   # 달릴 땐 어깨가 엉덩이보다 앞
    for s in ("R", "L"):
        side = SIDE if s == "R" else -SIDE; col = (220,30,30) if s == "R" else (40,90,230)
        fu, fh = legs[s]; ku, kh = ik(hip[0], hip[1], fu, fh)
        kside = side * (1 + 0.03 * max(0, kh - (hip[1] - TH))) if BACK else side
        pts = [P(hip[0], hip[1], side), P(ku, kh, kside), P(fu, fh, side)] + ([] if BACK else [P(fu+22, fh, side)])
        parts.append((P(fu, fh, side)[1], pts, col, 9, None))
        if BACK:
            f = P(fu, fh, side); big = 4 + fh * 0.35   # 들수록 발바닥이 크게 보인다
            dr.ellipse([f[0]-12, f[1]-big, f[0]+12, f[1]+big], outline=col, width=3)
        # 팔: 같은 쪽 다리와 반대로 흔든다(오른발이 앞이면 오른팔은 뒤)
        sh_u, sh_h = hip[0] + lean, hip[1] + 62; aside = side * 1.9
        if RUN:
            k = i if s == "R" else i + 6
            ang = -0.9 * math.sin(2 * math.pi * (k - 5) / 12)   # 다리가 가장 앞(8장)일 때 팔은 가장 뒤
            bend = 1.5                                          # 팔꿈치 직각
        else:
            ang = -0.55 * (fu / L)                       # 앞(+)·뒤(-) 흔들림 각도
            bend = 0.5
        eu, eh = sh_u + 30*math.sin(ang), sh_h - 30*math.cos(ang)
        hu, hh = eu + 28*math.sin(ang + bend), eh - 28*math.cos(ang + bend)
        apts = [P(sh_u, sh_h, aside), P(eu, eh, aside), P(hu, hh, aside)]
        acol = (130,0,0) if s == "R" else (0,40,140)
        parts.append((P(hu, hh, aside)[1] + 1000, apts, acol, 7, P(hu, hh, aside)))
    h0 = P(hip[0], hip[1], 0); s0 = P(hip[0] + lean, hip[1] + 62, 0)
    dr.line([h0, s0], fill=(0,0,0), width=6)
    for _, pts, col, w, fist in sorted(parts, key=lambda q: q[0]):   # 먼 것부터
        dr.line(pts, fill=col, width=w)
        if fist: dr.ellipse([fist[0]-9, fist[1]-9, fist[0]+9, fist[1]+9], fill=col)
    dr.ellipse([h0[0]-10, h0[1]-10, h0[0]+10, h0[1]+10], fill=(0,0,0))
    dr.line([P(hip[0] + lean, hip[1]+62, -SIDE*1.9), P(hip[0] + lean, hip[1]+62, SIDE*1.9)], fill=(0,0,0), width=6)
    dr.ellipse([s0[0]-22, s0[1]-70, s0[0]+22, s0[1]-26], outline=(0,0,0), width=4)
    dr.text((c*CW+10, r*CH+8), str(i+1), fill=(0,0,0))
img.save(out)
