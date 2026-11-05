shader_type canvas_item;
// 바다 바닥(floor_atlas의 water 줄)에 씌우는 셰이더. 칸 그림의 무늬는 쓰지 않고 마름모 모양(알파)만 쓴다.
// - 월드 좌표로 그려서 칸 이음매가 없다
// - 가로로 긴 물결 줄이 천천히 흐르고, 달빛 반짝임이 드문드문 깜박인다
// - 물이 아닌 칸(해안·부두·성벽)과 닿는 가장자리에 흰 거품, 그 안쪽은 얕은 물빛
// - 부두(planks) 칸의 앞쪽(화면 아래) 물에는 부두 옆면(나무)과 그림자를 그려 두께를 준다
// - storm(0~1, 챕터 2 폭풍): 물이 어둡고 빨라지며 물결 줄이 많아지고 흰 파도머리가 인다
// - 바다 무늬 그림(sea_calm·sea_storm, tools/gen_storm.py)이 있으면 use_tex: 줄무늬 대신 그림을 월드 좌표로 깐다.
//   잔잔한 무늬는 off_a, 거친 무늬는 off_b만큼 밀어 깐다(레벨이 바람 쪽으로 흘린다).
//   storm만큼 잔잔한 무늬 → 거친 무늬로 점무늬 섞기(픽셀아트라 반투명 섞기 대신)
// - soft(챕터 2): 바닥 칸 전부에 이 셰이더를 씌워, 땅·물 경계를 칸 마름모 대신 부드럽게 휜 해안선으로 그린다.
//   땅 여부를 칸 중심 사이로 이어 매끄럽게 하고(계단 없앰) 소음으로 흔든 뒤, 땅이면 floor_map의 칸 종류 그림을 아틀라스에서 뽑는다.
//   종류끼리 경계(모래·풀·흙)도 같은 소음으로 휘어 격자가 덜 보인다.
// - calm: 잔잔한 물은 그림 대신 코드로 — 느린 너울 띠 + 생겼다 사라지는 물비늘 줄(물결 따라 흐름)
// iso_level.gd가 water_map(물 칸 = 흰색, 부두 = 회색 0.5, 나머지 = 검정)·map_size·origin·ex·ey를 넣는다.

uniform sampler2D water_map : filter_nearest;
uniform vec2 map_size = vec2(1.0);
uniform vec2 origin = vec2(32.0, 0.0);
uniform vec2 ex = vec2(32.0, 16.0);
uniform vec2 ey = vec2(-32.0, 16.0);
uniform vec4 deep : source_color = vec4(0.075, 0.13, 0.27, 1.0);
uniform vec4 mid : source_color = vec4(0.11, 0.20, 0.37, 1.0);
uniform vec4 shallow : source_color = vec4(0.17, 0.31, 0.45, 1.0);
uniform vec4 crest : source_color = vec4(0.38, 0.52, 0.72, 1.0);
uniform vec4 foam : source_color = vec4(0.78, 0.84, 0.90, 1.0);
uniform vec4 pier_side : source_color = vec4(0.22, 0.14, 0.09, 1.0);
uniform vec4 pier_shadow : source_color = vec4(0.04, 0.07, 0.15, 1.0);
uniform float storm = 0.0;
uniform bool use_tex = false;
uniform sampler2D sea_calm_tex : filter_nearest, repeat_enable;
uniform sampler2D sea_storm_tex : filter_nearest, repeat_enable;
uniform vec2 off_a = vec2(0.0);
uniform vec2 off_b = vec2(0.0);
uniform bool soft = false;
uniform sampler2D floor_map : filter_nearest;   // r = 아틀라스 줄, g = 변형 번호 (0~255)
uniform vec2 atlas_size = vec2(256.0, 288.0);
uniform float water_row = 6.0;
// 이음매 없는 바닥 무늬(tools/gen_ground_tex.py): 이 줄의 칸은 칸 그림 대신 월드 좌표로 깐다
uniform sampler2D sand_tex : filter_nearest, repeat_enable;
uniform float sand_row = -1.0;

varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float kind(vec2 cell) {
	if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= map_size.x || cell.y >= map_size.y) {
		return 1.0;
	}
	return texture(water_map, (cell + 0.5) / map_size).r;
}

// 4×4 바이어 점무늬 문턱(0~1)
float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

vec3 sea_tex(sampler2D tex, vec2 p, vec2 off) {
	vec2 sz = vec2(textureSize(tex, 0));
	return texture(tex, fract((p - off) / sz)).rgb;
}

bool is_water(vec2 cell) {
	return kind(cell) > 0.75;
}

bool is_pier(vec2 cell) {
	float k = kind(cell);
	return k > 0.25 && k < 0.75;
}

// 칸이 땅인가(1) 물인가(0) — 부두는 땅으로
float landv(vec2 cell) {
	return kind(cell) > 0.75 ? 0.0 : 1.0;
}

// 칸 중심 사이를 이은 땅 값(0~1): 0.5 선이 계단 대신 비스듬히 깎인 해안선
float land_field(vec2 g) {
	vec2 h = g - 0.5;
	vec2 i = floor(h);
	vec2 t = h - i;
	t = t * t * (3.0 - 2.0 * t);
	return mix(mix(landv(i), landv(i + vec2(1.0, 0.0)), t.x), mix(landv(i + vec2(0.0, 1.0)), landv(i + vec2(1.0, 1.0)), t.x), t.y);
}

vec2 to_grid(vec2 q0) {
	vec2 q = q0 - origin;
	float det = ex.x * ey.y - ey.x * ex.y;
	return vec2((q.x * ey.y - ey.x * q.y) / det, (ex.x * q.y - q.x * ex.y) / det);
}

// 잔잔한 바다(코드): 큰 얼룩 3단 색 + 너울 띠 + 물비늘 줄 두 겹
vec3 calm_sea(vec2 p, float t) {
	vec2 w = p - off_a;                         // 물결 따라 흐르는 좌표
	float n = noise(w * vec2(0.006, 0.018) + vec2(t * 0.02, 0.0)) * 0.7 + noise(w * vec2(0.03, 0.06) - vec2(0.0, t * 0.03)) * 0.3;
	float sw = sin(p.y * 0.16 + noise(p * vec2(0.008, 0.02)) * 7.0 + t * 0.55);   // 너울(위아래로 천천히)
	float tone = n + sw * 0.08;
	// 색 단계 사이는 점무늬로 섞어 얼룩 테두리가 선으로 보이지 않게
	float m = smoothstep(0.3, 0.8, tone) * 2.0;
	float lv = min(2.0, floor(m + bayer(p) * 0.9));
	vec3 col = mix(deep.rgb, mid.rgb, lv * 0.32);
	// 물비늘: (22×5)px 칸마다 줄 하나가 제 박자로 길어졌다 짧아진다. 줄은 칸마다 반 칸 어긋남
	for (int layer = 0; layer < 2; layer++) {
		vec2 sz = layer == 0 ? vec2(26.0, 6.0) : vec2(15.0, 4.0);
		vec2 wp = w + (layer == 0 ? vec2(0.0) : vec2(5.0, 1.0));
		float row = floor(wp.y / sz.y);
		wp.x += mod(row, 2.0) * sz.x * 0.5;
		vec2 slot = vec2(floor(wp.x / sz.x), row);
		float h = hash(slot + float(layer) * 31.7);
		float life = sin(t * (0.7 + h * 0.9) + h * 40.0) * (0.55 + 0.45 * sw * (h - 0.3));
		float th = layer == 0 ? 0.42 : 0.8;
		if (life > th) {
			float len = floor((life - th) / (1.0 - th) * (layer == 0 ? 8.0 : 4.0)) + 1.0;
			float cx = floor(h * (sz.x - 8.0)) + 4.0;
			float lx = wp.x - slot.x * sz.x;
			float ly = wp.y - row * sz.y;
			if (ly < 1.0 && abs(lx - cx) < len * 0.5) {
				col = layer == 0 ? (life > 0.85 && abs(lx - cx) < 1.0 ? mix(crest.rgb, foam.rgb, 0.4) : crest.rgb) : mix(col, crest.rgb, 0.5);
			}
		}
	}
	// 달빛 반짝임
	vec2 cellp = floor(p / vec2(8.0, 4.0));
	float hh = hash(cellp);
	vec2 spot = cellp * vec2(8.0, 4.0) + floor(vec2(hash(cellp + 7.1) * 6.0, hash(cellp + 3.3) * 3.0));
	if (hh > 0.985 && p.y == spot.y && (p.x == spot.x || p.x == spot.x + 1.0) && sin(t * 2.5 + hh * 60.0) > 0.5) {
		col = foam.rgb;
	}
	return col;
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	vec2 p = floor(wpos);                      // 픽셀 단위로 끊어 픽셀아트처럼
	float t = TIME * (1.0 + storm * 1.6);

	// soft: 휜 위치(wq)에서 땅·물과 칸 종류를 정한다
	vec2 wq = p;
	if (soft) {
		wq += (vec2(noise(p * 0.05), noise(p * 0.05 + 17.3)) - 0.5) * vec2(16.0, 9.0)
			+ (vec2(noise(p * 0.16 + 5.1), noise(p * 0.16 + 9.7)) - 0.5) * vec2(4.0, 2.0);
	}
	vec2 g = to_grid(wq + 0.5);
	vec2 cell = floor(g);
	vec2 f = g - cell;

	bool land_px = false;
	vec3 land_col = vec3(0.0);
	float lf = 0.0;
	float thr = 0.5;
	if (soft) {
		lf = land_field(g);
		thr = 0.5 + (noise(p * vec2(0.09, 0.18)) - 0.5) * 0.22;
		if (lf > thr) {
			// 땅: 이 칸(휜 위치의 칸)이 땅이면 그 종류, 물 칸이면 가장 가까운 땅 칸의 종류(보통 모래)
			vec2 src = cell;
			if (landv(cell) < 0.5) {
				vec2 best = cell;
				float bd = 9.0;
				for (int k = 0; k < 8; k++) {
					vec2 o = vec2(k < 3 ? -1.0 : (k < 5 ? 0.0 : 1.0), float(k < 3 ? k - 1 : (k < 5 ? (k == 3 ? -1 : 1) : k - 6)));
					vec2 c2 = cell + o;
					float dd = length(g - (c2 + 0.5));
					if (landv(c2) > 0.5 && dd < bd) { bd = dd; best = c2; }
				}
				src = best;
			}
			vec4 fm = texture(floor_map, (src + 0.5) / map_size);
			float row = floor(fm.r * 255.0 + 0.5);
			float vv = floor(texture(floor_map, (cell + 0.5) / map_size).g * 255.0 + 0.5);
			// 아틀라스에서 휜 위치의 칸(cell) 마름모 안 같은 자리 — 같은 종류 칸끼리 이어지므로 종류만 바꿔 뽑아도 맞는다
			vec2 top = origin + ex * cell.x + ey * cell.y;
			vec2 tp = clamp(floor(wq - top + vec2(32.0, 0.0)), vec2(0.0), vec2(63.0, 31.0));
			vec4 lc = texture(TEXTURE, (vec2(vv * 64.0, row * 32.0) + tp + 0.5) / atlas_size);
			vec3 lcol = lc.rgb;
			if (lc.a < 0.5) {   // 마름모 밖(드묾): 가까운 안쪽
				lcol = texture(TEXTURE, (vec2(vv * 64.0, row * 32.0) + vec2(32.0, 16.0) + 0.5) / atlas_size).rgb;
			}
			if (row == sand_row) {
				lcol = texture(sand_tex, fract((floor(wq) + 0.5) / vec2(textureSize(sand_tex, 0)))).rgb;
			}
			// 물가 젖은 띠
			if (lf - thr < 0.06) {
				lcol *= 0.78;
			}
			land_px = true;
			land_col = lcol;
		}
	}

	vec3 col;
	if (use_tex) {
		col = calm_sea(p, t);
		if (storm > 0.01) {
			vec3 sc = sea_tex(sea_storm_tex, p, off_b);
			float th = mix(bayer(p), noise(p * vec2(0.012, 0.024) + vec2(t * 0.05, 0.0)), 0.7) * 0.94 + 0.03;
			col = storm > th ? sc : col;
		}
	} else {
		col = calm_sea(p, t);
		col = mix(col, col * 0.6 + vec3(0.015, 0.02, 0.035), storm * 0.7);
		if (storm > 0.01) {
			float wc = noise(p * vec2(0.04, 0.08) + vec2(t * 0.35, -t * 0.18));
			float roll = sin(p.y * 0.8 - p.x * 0.15 + t * 2.6 + wc * 8.0);
			if (wc > 0.9 - storm * 0.14 && roll > 0.55) {
				col = foam.rgb;
			} else if (wc > 0.86 - storm * 0.14 && roll > 0.75) {
				col = mix(col, foam.rgb, 0.5);
			}
		}
	}

	// 해안 거품까지의 거리 d(칸 단위). soft면 땅 값으로, 아니면 이웃 칸으로
	float d = 9.0;
	if (soft) {
		if (lf > 0.02) {
			d = (thr - lf) * 1.6;
		}
	} else {
		if (!is_water(cell + vec2(-1.0, 0.0))) d = min(d, f.x);
		if (!is_water(cell + vec2(1.0, 0.0))) d = min(d, 1.0 - f.x);
		if (!is_water(cell + vec2(0.0, -1.0))) d = min(d, f.y);
		if (!is_water(cell + vec2(0.0, 1.0))) d = min(d, 1.0 - f.y);
		if (!is_water(cell + vec2(-1.0, -1.0))) d = min(d, max(f.x, f.y));
		if (!is_water(cell + vec2(1.0, -1.0))) d = min(d, max(1.0 - f.x, f.y));
		if (!is_water(cell + vec2(-1.0, 1.0))) d = min(d, max(f.x, 1.0 - f.y));
		if (!is_water(cell + vec2(1.0, 1.0))) d = min(d, max(1.0 - f.x, 1.0 - f.y));
	}
	if (d < 2.0) {
		col = mix(col, shallow.rgb, (1.0 - smoothstep(0.0, 0.7, d)) * 0.55);
		float fn = noise(p * vec2(0.14, 0.28) + vec2(t * 0.5, t * 0.2));
		float surge = 0.08 + 0.04 * sin(t * 1.3 + (g.x - g.y) * 1.7);
		float edge = surge * (0.2 + 1.3 * fn);
		if (d < 0.025) {
			col = mix(col, crest.rgb, 0.8);
		}
		if (d < edge && fn > 0.32) {
			col = foam.rgb;
		} else if (d < edge + 0.06 && fn > 0.5) {
			col = mix(col, crest.rgb, 0.6);
		}
	}
	float pd = 9.0;
	if (is_pier(cell + vec2(-1.0, 0.0))) pd = min(pd, f.x);
	if (is_pier(cell + vec2(0.0, -1.0))) pd = min(pd, f.y);
	if (is_pier(cell + vec2(-1.0, -1.0))) pd = min(pd, max(f.x, f.y));
	if (pd < 0.07) {
		col = pier_side.rgb * (0.85 + 0.3 * step(0.5, fract(p.x / 6.0)));
	} else if (pd < 0.24) {
		col = mix(col, pier_shadow.rgb, 0.6 * (1.0 - smoothstep(0.07, 0.24, pd)) + 0.25);
	}
	COLOR = vec4(land_px ? land_col : col, a);
}
