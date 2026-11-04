shader_type canvas_item;
// 바다 바닥(floor_atlas의 water 줄)에 씌우는 셰이더. 칸 그림의 무늬는 쓰지 않고 마름모 모양(알파)만 쓴다.
// - 월드 좌표로 그려서 칸 이음매가 없다
// - 가로로 긴 물결 줄이 천천히 흐르고, 달빛 반짝임이 드문드문 깜박인다
// - 물이 아닌 칸(해안·부두·성벽)과 닿는 가장자리에 흰 거품, 그 안쪽은 얕은 물빛
// - 부두(planks) 칸의 앞쪽(화면 아래) 물에는 부두 옆면(나무)과 그림자를 그려 두께를 준다
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

bool is_water(vec2 cell) {
	return kind(cell) > 0.75;
}

bool is_pier(vec2 cell) {
	float k = kind(cell);
	return k > 0.25 && k < 0.75;
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	vec2 p = floor(wpos);                      // 픽셀 단위로 끊어 픽셀아트처럼
	float t = TIME;

	// 격자 좌표(칸 안 위치 f: 0~1)
	vec2 q = p + 0.5 - origin;
	float det = ex.x * ey.y - ey.x * ex.y;
	vec2 g = vec2((q.x * ey.y - ey.x * q.y) / det, (ex.x * q.y - q.x * ex.y) / det);
	vec2 cell = floor(g);
	vec2 f = g - cell;

	// 바탕: 느리게 움직이는 큰 얼룩으로 깊은 물·중간 물
	float n = noise(p * vec2(0.012, 0.024) + vec2(t * 0.03, t * 0.01));
	vec3 col = mix(deep.rgb, mid.rgb, smoothstep(0.35, 0.75, n));

	// 물결: 화면 가로로 긴 짧은 줄. 줄 위치는 얼룩 소음으로 휘고, 시간에 따라 위아래로 출렁인다
	float bend = noise(p * vec2(0.025, 0.07)) * 7.0;
	float w = sin(p.y * 0.5 + bend + t * 1.2);
	float dash = noise(vec2(p.x * 0.07 + t * 0.25, floor(p.y / 2.0) * 0.9));
	if (w > 0.93 && dash > 0.62) {
		col = crest.rgb;
	} else if (w > 0.78 && dash > 0.55) {
		col = mix(col, crest.rgb, 0.35);
	}

	// 달빛 반짝임: 8×4 칸마다 드물게 가로 2px 점 하나가 제각각 깜박인다
	vec2 cellp = floor(p / vec2(8.0, 4.0));
	float h = hash(cellp);
	vec2 spot = cellp * vec2(8.0, 4.0) + floor(vec2(hash(cellp + 7.1) * 6.0, hash(cellp + 3.3) * 3.0));
	if (h > 0.985 && p.y == spot.y && (p.x == spot.x || p.x == spot.x + 1.0) && sin(t * 2.5 + h * 60.0) > 0.5) {
		col = foam.rgb;
	}

	// 해안 거품: 물이 아닌 이웃 쪽 가장자리까지의 거리
	float d = 9.0;
	if (!is_water(cell + vec2(-1.0, 0.0))) d = min(d, f.x);
	if (!is_water(cell + vec2(1.0, 0.0))) d = min(d, 1.0 - f.x);
	if (!is_water(cell + vec2(0.0, -1.0))) d = min(d, f.y);
	if (!is_water(cell + vec2(0.0, 1.0))) d = min(d, 1.0 - f.y);
	if (!is_water(cell + vec2(-1.0, -1.0))) d = min(d, max(f.x, f.y));
	if (!is_water(cell + vec2(1.0, -1.0))) d = min(d, max(1.0 - f.x, f.y));
	if (!is_water(cell + vec2(-1.0, 1.0))) d = min(d, max(f.x, 1.0 - f.y));
	if (!is_water(cell + vec2(1.0, 1.0))) d = min(d, max(1.0 - f.x, 1.0 - f.y));
	if (d < 2.0) {
		// 얕은 물빛
		col = mix(col, shallow.rgb, (1.0 - smoothstep(0.0, 0.7, d)) * 0.55);
		// 밀려왔다 빠지는 거품 띠(가장자리를 따라 끊긴 모양)
		float fn = noise(p * vec2(0.14, 0.28) + vec2(t * 0.5, t * 0.2));
		float surge = 0.08 + 0.04 * sin(t * 1.3 + (g.x - g.y) * 1.7);
		float edge = surge * (0.2 + 1.3 * fn);
		if (d < 0.025) {
			col = mix(col, crest.rgb, 0.8);       // 닿는 선은 늘 옅게
		}
		if (d < edge && fn > 0.32) {
			col = foam.rgb;
		} else if (d < edge + 0.06 && fn > 0.5) {
			col = mix(col, crest.rgb, 0.6);
		}
	}
	// 부두 옆면·그림자: 부두가 격자 -x 또는 -y 쪽(화면 위쪽)에 있으면 이 칸의 그쪽 가장자리에 보인다
	float pd = 9.0;
	if (is_pier(cell + vec2(-1.0, 0.0))) pd = min(pd, f.x);
	if (is_pier(cell + vec2(0.0, -1.0))) pd = min(pd, f.y);
	if (is_pier(cell + vec2(-1.0, -1.0))) pd = min(pd, max(f.x, f.y));
	if (pd < 0.07) {
		col = pier_side.rgb * (0.85 + 0.3 * step(0.5, fract(p.x / 6.0)));   // 나무 옆면(널 이음)
	} else if (pd < 0.24) {
		col = mix(col, pier_shadow.rgb, 0.6 * (1.0 - smoothstep(0.07, 0.24, pd)) + 0.25);
	}
	COLOR = vec4(col, a);
}
