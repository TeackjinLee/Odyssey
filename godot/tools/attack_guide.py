"""공격 움직임 안내 그림(Codex 요청에 붙인다). 막대 인물이 프레임마다 어떤 자세로 어느 쪽 주먹을 휘두르는지 보여 준다.
치는 주먹(오른손)은 굵은 짙은 빨강 + 큰 원, 방패 팔(왼손)은 파랑, 오른발 빨강·왼발 파랑, 몸통 돌림은 어깨선으로 나타낸다.
몸 앞쪽 u, 오른쪽 s, 높이 h의 몸 좌표에서 푼 뒤 화면 방향 벡터로 비춘다(walk_guide.py와 같은 방식).
사용: python3 tools/attack_guide.py <출력.png> <동작> <방향,방향,...>
  동작: attack1 가로 베기 4장 / attack2 되베기 4장 / attack3 내려찍기 5장 / heavy 회전 베기 6장
  방향: E SE S NE N (쉼표로 이어 쓰면 한 장에 방향마다 한 줄씩 그린다 — Codex 한도를 아끼려고 한 번에 여러 방향을 받는다)
격자: 열 = 프레임 수, 줄 = 한 장에 담는 방향 수(attack1·2·3은 3줄 칸 384×341 안팎, heavy는 2줄 칸 256×512), 전체 1536×1024.
방향이 줄 수보다 적으면 남는 줄은 비워 둔다(요청 글도 그 줄은 빈 마젠타로 두라고 쓴다).
"""
import math, sys
from PIL import Image, ImageDraw

VEC = {"E": (1, 0, 0, 0.5), "SE": (0.71, 0.35, -0.71, 0.35), "NE": (0.71, -0.35, 0.71, 0.35),
       "N": (0, -0.3, 1.6, 0), "S": (0, 0.3, -1.6, 0)}   # 앞·오른쪽 방향의 화면 벡터
ROWS_PER_IMAGE = {"attack1": 3, "attack2": 3, "attack3": 3, "heavy": 2}
out, kind, dirs = sys.argv[1], sys.argv[2], sys.argv[3].split(",")
HIP, SH, TH, SHD, ARM1, ARM2, SIDE = 134, 62, 70, 70, 30, 28, 14
# 프레임별 자세: 치는 주먹 (u, s, h), 몸통 돌림 yaw(도, +면 오른쪽으로 돌려 오른 어깨가 뒤로), 웅크림 crouch, 상체 기울기 lean,
#               오른발 u, 왼발 u (발은 s=±SIDE)
POSES = {
    "attack1": [  # 가로 베기: 오른쪽으로 감았다가 왼쪽으로 크게 벤다
        dict(fist=(-25, 38, 150), yaw=40, crouch=0, lean=-6, rf=-28, lf=14),
        dict(fist=(45, 26, 186), yaw=0, crouch=6, lean=8, rf=-28, lf=46),
        dict(fist=(40, -48, 180), yaw=-45, crouch=6, lean=10, rf=-14, lf=44),
        dict(fist=(30, 8, 160), yaw=0, crouch=0, lean=0, rf=-8, lf=22)],
    "attack2": [  # 되베기: 왼쪽 아래에서 위로 올려 오른쪽 높이 벤다
        dict(fist=(14, -38, 128), yaw=-40, crouch=4, lean=2, rf=-14, lf=34),
        dict(fist=(48, 0, 192), yaw=0, crouch=0, lean=8, rf=-18, lf=40),
        dict(fist=(14, 52, 206), yaw=44, crouch=0, lean=-4, rf=-12, lf=34),
        dict(fist=(30, 8, 160), yaw=0, crouch=0, lean=0, rf=-8, lf=22)],
    "attack3": [  # 내려찍기: 높이 들어 올려 앞으로 크게 내리찍는다
        dict(fist=(4, 26, 236), yaw=10, crouch=0, lean=-6, rf=-18, lf=14),
        dict(fist=(-10, 16, 268), yaw=14, crouch=-4, lean=-14, rf=-24, lf=10),
        dict(fist=(58, 10, 150), yaw=0, crouch=14, lean=22, rf=-22, lf=52),
        dict(fist=(64, 10, 70), yaw=0, crouch=40, lean=30, rf=-26, lf=56),
        dict(fist=(34, 10, 150), yaw=0, crouch=12, lean=10, rf=-14, lf=34)],
    "heavy": [  # 회전 베기: 웅크려 모았다가 한 바퀴 돌며 베고 낮게 마무리
        dict(fist=(-30, 36, 100), yaw=35, crouch=40, lean=14, rf=-24, lf=18),
        dict(fist=(-32, 40, 88), yaw=58, crouch=52, lean=18, rf=-28, lf=18),
        dict(fist=(0, 74, 150), yaw=-100, crouch=24, lean=4, rf=-14, lf=14),
        dict(fist=(-4, 74, 152), yaw=-180, crouch=10, lean=0, rf=-6, lf=10),
        dict(fist=(56, -16, 160), yaw=-310, crouch=18, lean=10, rf=-8, lf=26),
        dict(fist=(40, -52, 112), yaw=-350, crouch=36, lean=12, rf=-26, lf=30)],
}
frames = POSES[kind]
n = len(frames)
cols, rows = n, ROWS_PER_IMAGE[kind]
W, H = 1536, 1024
CW, CH = W // cols, H // rows
SC = CH / 341 * 0.98
img = Image.new("RGB", (W, H), (255, 255, 255))
dr = ImageDraw.Draw(img)


def ik(hu, hh, fu, fh):
    du, dh = fu - hu, fh - hh
    d = min(math.hypot(du, dh), TH + SHD - 1)
    a = math.atan2(dh, du)
    b = math.acos(max(-1, min(1, (TH * TH + d * d - SHD * SHD) / (2 * TH * d))))
    return hu + TH * math.cos(a + b), hh + TH * math.sin(a + b)


def rot(u, s, yaw):
    r = math.radians(yaw)
    return u * math.cos(r) - s * math.sin(r), u * math.sin(r) + s * math.cos(r)


for ri, d in enumerate(dirs):
  fx, fy, rx, ry = VEC[d]
  for i, f in enumerate(frames):
      c, r = i, ri
      ox, oy = c * CW + CW // 2, r * CH + CH * 0.78
      P = lambda u, s, h: (ox + (u * fx + s * rx) * SC, oy + (u * fy + s * ry - h) * SC)
      yaw = f["yaw"]
      hipu = (f["rf"] + f["lf"]) / 2 * 0.5
      hiph = HIP - f["crouch"]
      shu, shh = hipu + f["lean"], hiph + SH
      # 땅 줄
      dr.line([P(-170, 0, 0), P(170, 0, 0)], fill=(170, 170, 170), width=2)
      parts = []
      for side, fu in ((1, f["rf"]), (-1, f["lf"])):
          s = side * SIDE
          hu, hs_ = rot(0, s, yaw * 0.4)   # 골반은 몸통 돌림의 일부만 따라 돈다
          ku, kh = ik(hipu + hu, hiph, fu, 0)
          col = (220, 30, 30) if side > 0 else (40, 90, 230)
          pts = [P(hipu + hu, hs_, hiph), P(ku, s, kh), P(fu, s, 0), P(fu + 22, s, 0)]
          parts.append((P(fu, s, 0)[1], pts, col, 9, None))
      # 어깨선(몸통 돌림)
      sru, srs = rot(0, SIDE * 1.9, yaw)
      slu, sls = rot(0, -SIDE * 1.9, yaw)
      shR = P(shu + sru, srs, shh)
      shL = P(shu + slu, sls, shh)
      # 치는 팔: 어깨 → 팔꿈치 → 주먹(팔 길이를 맞춰 팔꿈치를 바깥으로)
      fu_, fs_, fh_ = f["fist"]
      ax, ay = shu + sru, shh
      dx, dy, dz = fu_ - ax, fs_ - srs, fh_ - ay
      d3 = math.sqrt(dx * dx + dy * dy + dz * dz)
      t = min(1.0, (ARM1 + ARM2 - 2) / max(d3, 1))
      fu2, fs2, fh2 = ax + dx * t, srs + dy * t, ay + dz * t   # 닿을 수 있는 만큼
      mu, ms, mh = (ax + fu2) / 2, (srs + fs2) / 2, (ay + fh2) / 2
      bulge = 11 * (1 - t) + 9
      mu, ms, mh = mu - bulge * 0.4, ms + bulge * (1 if fs2 > 0 else 0.4), mh - bulge * 0.6
      fist = P(fu2, fs2, fh2)
      parts.append((fist[1] + 1000, [shR, P(mu, ms, mh), fist], (130, 0, 0), 11, fist))
      # 방패 팔: 가슴 앞에 굽혀 든다(몸통을 따라 돈다)
      lu, ls = rot(26, -SIDE * 2.4, yaw)
      lfist = P(shu + lu, ls, shh - 26)
      parts.append((lfist[1] + 999, [shL, P(shu + lu * 0.5, sls + (ls - sls) * 0.5 - 4, shh - 22), lfist], (0, 40, 140), 8, lfist))
      hip0 = P(hipu, 0, hiph)
      sh0 = P(shu, 0, shh)
      dr.line([hip0, sh0], fill=(0, 0, 0), width=7)
      for _, pts, col, w, fp in sorted(parts, key=lambda q: q[0]):
          dr.line(pts, fill=col, width=w)
          if fp:
              rr = 13 if col == (130, 0, 0) else 8
              dr.ellipse([fp[0] - rr, fp[1] - rr, fp[0] + rr, fp[1] + rr], fill=col)
      dr.line([shL, shR], fill=(0, 0, 0), width=6)
      dr.ellipse([hip0[0] - 10, hip0[1] - 10, hip0[0] + 10, hip0[1] + 10], fill=(0, 0, 0))
      hd = P(shu + f["lean"] * 0.3, 0, shh + 48)
      dr.ellipse([hd[0] - 22 * SC, hd[1] - 22 * SC, hd[0] + 22 * SC, hd[1] + 22 * SC], outline=(0, 0, 0), width=4)
      # 보는 쪽(몸통이 향한 방향): 머리에서 짧은 선
      cu, cs = rot(1, 0, yaw)
      tip = P(shu + f["lean"] * 0.3 + cu * 26, cs * 26, shh + 48)
      dr.line([hd, tip], fill=(0, 0, 0), width=3)
      dr.text((c * CW + 10, r * CH + 8), str(i + 1), fill=(0, 0, 0))
img.save(out)
