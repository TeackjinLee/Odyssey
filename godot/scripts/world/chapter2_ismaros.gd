class_name Chapter2Ismaros
extends IsoLevel
## CHAPTER 2 — 귀환의 시작 (docs/maps/CH2_ISMAROS.md).
## 트로이를 떠난 갤리선. 항해 모드로 이스마로스 해안까지 배를 몰고(바람·돛·노 단계·암초) → 상륙해 키코네스 마을의
## 곡식 창고 셋을 털고(양·염소 사냥, 채집한 음식은 짧게 눌러 배 창고에) → 내륙에서 몰려오는 반격을 막으며 배로 물러나
## 오르면(멀리서 쓰러진 부하는 두고 간다) → 해안에서 떠난 키코네스 배들을 따돌리거나 격침하며 남쪽 먼바다로 빠져나간다.
## 먼바다에 닿으면 제우스의 폭풍: 비·번개 속에서 STORM_TIME초를 버틴다(파도는 바람 쪽에서 온다 — 옆구리로 맞으면 선체·부하가 크게 다치고,
## 돛을 펴 두면 찢어진다) → 여러 날 밀려(식량 창고에서 며칠 치가 빠짐) 남쪽의 로토스 섬에 닿는다 → 상륙하면 정찰 보낸
## 부하 둘이 로토스 열매를 먹고 고향을 잊는다 → 붙잡아 끌고 와 배에 묶는다(다른 부하도 열매 곁에 오래 두면 끌려간다 — 해안에
## 위치 사수) → 섬을 떠나면 클리어. 오디세우스가 열매를 먹으면 잠시 고향을 잊는다(걸음이 흐트러지고 목표 표시가 사라짐).
## 영양·부하는 챕터 1 끝에서 이어받는다(Game.carry_for(2)). 배의 식량 창고(Rations)는 항해 하루(50초)마다 부하 수만큼 준다.
## 체크포인트: 상륙 · 반격 시작 · 출항 · 폭풍 · 로토스 섬.
##
## 격자(64×104): x는 화면 오른쪽 아래, y는 왼쪽 아래. 대부분 바다(물 칸 — 사람은 못 들어감, 배만 다님).
## 위쪽(y 0~55)이 이스마로스 앞바다, 아래쪽(y 58~)이 로토스 섬(가운데 (38, 86)).
## 이스마로스 땅 = x ≥ coast_x(y) 이고 y ≤ coast_y(x) (오른쪽 위). 해안 두 칸은 모래밭. 상륙 지점은 서쪽 해안 (35, 20).
## 시작은 왼쪽 아래 (9, 45), 빠져나갈 곳은 화면 아래쪽 끝 (57~63, 49~55). 가운데 작은 섬과 암초들.

const START := Vector2(9.0, 45.0)
const START_HEADING := -0.82
## 상륙: 배를 대는 자리(배 가운데)·사람이 내리는 자리·승선 지점
const ANCHOR := Vector2(32.6, 20.5)
const LAND_AT := Vector2(36.4, 20.5)
const BOARD_AT := Vector2(35.5, 20.5)
const EXIT_RECT := Rect2(57.0, 49.0, 7.0, 7.0)
const EXIT_MARK := Vector2(59.5, 51.5)
## 상륙하려면 이보다 느려야 함(칸/초)
const LAND_SPEED := 0.7
## 곡식 창고 하나 = 식량 몫
const LOOT_UNITS := 5
## 출항할 때 이만큼(px) 안의 쓰러진 부하는 업고 간다. 더 멀면 두고 간다
const CARRY_DIST := 260.0
## 반격: 물결 수·간격·내륙 출발점
const COUNTER_WAVES := 3
const COUNTER_INTERVAL := 14.0
const INLAND := [Vector2(62.3, 9.5), Vector2(62.3, 19.5)]
## 첫 물결은 해안 양쪽(북·남 모래밭)에서 퇴로를 끊으러 온다
const FLANKS := [Vector2(38.5, 3.5), Vector2(39.5, 25.0)]
## 배 띄우기(해안에서 바다로 밀어냄): 길게 누르는 시간 — 맞으면 끊긴다
const LAUNCH_TIME := 4.0
const REEFS := [Vector2i(14, 38), Vector2i(15, 38), Vector2i(20, 34), Vector2i(21, 33), Vector2i(17, 27), Vector2i(12, 30),
	Vector2i(27, 24), Vector2i(28, 25), Vector2i(42, 33), Vector2i(43, 33), Vector2i(50, 40), Vector2i(47, 46),
	Vector2i(56, 46), Vector2i(38, 38), Vector2i(33, 43), Vector2i(60, 40)]
const ISLET := Vector2(24.0, 30.0)
const BOATS := [Vector2(44.0, 31.0), Vector2(52.0, 31.0), Vector2(57.0, 34.0)]
## ── 로토스 섬 ──
const LOTUS_C := Vector2(38.0, 86.0)
## 폭풍이 끝나고 배가 있는 자리·방향(남남동 — 섬 쪽)
const LOTUS_START := Vector2(27.0, 62.0)
const LOTUS_START_HEADING := 1.15
## 섬 북쪽 해안: 배를 대는 자리·사람이 내리는 자리·승선 지점(해안 첫 칸 y 74)
const LOTUS_ANCHOR := Vector2(38.5, 71.6)
const LOTUS_LAND_AT := Vector2(38.5, 75.4)
const LOTUS_BOARD_AT := Vector2(38.5, 74.5)
## 섬 가운데에서 이만큼(칸) 멀어지면 떠난 것. 표시는 서쪽 바다
const LOTUS_EXIT_DIST := 22.0
const LOTUS_EXIT_MARK := Vector2(14.0, 76.0)
## 폭풍에 밀려 다닌 날(식량 창고에서 빠짐)
const STORM_DAYS := 3
## 폭풍: 버틸 시간(초)·바람 세기·배 속도 상한(칸/초)·파도 간격(초)·파도 피해(옆구리로 맞을 때, 앞뒤로 받으면 15%)·부하 피해
const STORM_TIME := 32.0
const STORM_WIND := 1.5
const STORM_SPEED := 0.65
const SURGE_EVERY := Vector2(3.2, 5.0)
const SURGE_DMG := 11.0
const SURGE_CREW_DMG := 7.0
## 폭풍 체크포인트에서 다시 할 때 배 자리(이스마로스 먼바다 끝)
const STORM_START := Vector2(58.5, 52.0)
## 폭풍 바다의 암초(배가 밀려가는 남서쪽)
const STORM_REEFS := [Vector2i(54, 57), Vector2i(51, 60), Vector2i(57, 61), Vector2i(47, 58), Vector2i(44, 64),
	Vector2i(53, 64), Vector2i(49, 67), Vector2i(58, 66), Vector2i(41, 60)]
## 로토스나무(열매)와 그 곁 앉을 자리. 부하가 열매에서 LURE_DIST(px) 안에 LURE_TIME초 넘게 있으면 끌려가 먹는다
const LOTUS_TREES := [Vector2i(36, 88), Vector2i(41, 86), Vector2i(39, 92), Vector2i(33, 85)]
const LURE_DIST := 120.0
const LURE_TIME := 5.0
## 상륙하면 정찰 보내는 부하 수(뒤에서부터)
const SCOUTS := 2
## 로토파고스 자리(앉을 자리와 떨어지게)
const LOTOPHAGI := [Vector2(38.0, 84.5), Vector2(43.5, 90.5), Vector2(33.5, 92.0)]

var step := -1
var ship: Ship
var rations := Rations.new()
var wind := Vector2(0.75, -0.66).normalized()
var wind_strength := 0.7
var _wind_base := Vector2(0.75, -0.66).normalized()
var land_point: Interactable
var board_point: Interactable
var loot_points: Array = []
var looted := 0
var defenders: Array = []
var boats: Array = []
var lost: Array = []
var ending_done := false
var _done := false
var _waves := 0
var _wave_t := 0.0
var _t := 0.0
var _hungry_warned := false
var sea_astar := AStarGrid2D.new()
var _tuts: Array = []
var _tut_cur: Array = []
var _tut_t := 0.0
var _tut_gap := 0.0
var _restored := false
var _storming := false
var lotus_fruits: Array = []
var scouts: Array = []
var bound := 0
var _lure_t := {}
var _canvas_base := Color(0.86, 0.82, 0.86)
## 폭풍
var storm_on := false
var storm_fx: StormFx
var _storm_t := 0.0
var _storm_k := 0.0
var _surge_t := 0.0
var _bolt_t := 0.0
var _storm_dir := Vector2(-0.7, 0.7).normalized()
var _side_warned := false


static func coast_x(y: float) -> int:
	return 36 + roundi(1.5 * sin(y * 0.55))


static func coast_y(x: float) -> int:
	return 27 + roundi(1.5 * sin(x * 0.6))


static func is_land(c: Vector2i) -> bool:
	return c.y < 56 and c.x >= coast_x(c.y) and c.y <= coast_y(c.x)


## 로토스 섬: 가운데에서 각도마다 다른 반지름 안
static func lotus_r(a: float) -> float:
	return 11.0 + 1.5 * sin(3.0 * a) + 0.8 * sin(5.0 * a + 1.0)


static func is_lotus_land(c: Vector2i) -> bool:
	var d := Vector2(c.x + 0.5, c.y + 0.5) - LOTUS_C
	return d.length() < lotus_r(d.angle())


func build() -> void:
	Lines.use("res://data/dialogue/ch2.json")
	chapter_title = Lines.t("meta.chapter_title")
	area_name = Lines.t("meta.area")
	minimap_land = true
	W = 64
	H = 104
	canvas_mod.color = _canvas_base
	fill(Rect2i(0, 0, W, H), "water")
	# 이스마로스·로토스 섬: 풀밭, 물가 두 칸은 모래
	for x in W:
		for y in H:
			var c := Vector2i(x, y)
			if is_land(c) or is_lotus_land(c):
				floor_kind[c] = "grass"
	for c in floor_kind.keys():
		if floor_kind[c] != "grass":
			continue
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var n: Vector2i = c + Vector2i(dx, dy)
				if in_bounds(n) and not is_land(n) and not is_lotus_land(n):
					floor_kind[c] = "sand"
	# 가운데 작은 섬
	for x in range(20, 29):
		for y in range(26, 35):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(ISLET)
			if d < 1.6:
				floor_kind[Vector2i(x, y)] = "grass"
			elif d < 2.8:
				floor_kind[Vector2i(x, y)] = "sand"
	# 마을: 해안에서 광장까지 흙길, 광장, 내륙으로 가는 길, 들판 길
	for seg in [[Vector2(35, 20), Vector2(40, 19)], [Vector2(40, 19), Vector2(44, 16)], [Vector2(44, 16), Vector2(47, 14)],
			[Vector2(50, 12), Vector2(63, 10)], [Vector2(48, 15), Vector2(52, 22)], [Vector2(54, 15), Vector2(63, 19)]]:
		_path_line(seg[0], seg[1])
	fill(Rect2i(45, 11, 6, 5), "plaza")
	# 사람에게는 물이 막힘(해안에서 두 칸 띠만 막으면 그 밖 바다는 닿을 수 없다)
	for c in floor_kind:
		if floor_kind[c] == "water":
			var near_land := false
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var k: String = floor_kind.get(c + Vector2i(dx, dy), "water")
					if k != "water":
						near_land = true
			if near_land:
				set_solid(c)
	for c in REEFS + STORM_REEFS:
		reefs[c] = true
		add_prop("rock", c, true, false)
	# 섬: 소나무·바위
	add_prop("pine", Vector2i(24, 30), true, false)
	add_prop("rock", Vector2i(22, 29), true, false)
	# 마을 집(키코네스 — 챕터 1 집 그림을 같이 씀)
	for h in [["house_a", Vector2i(41, 10)], ["house_b", Vector2i(45, 7)], ["house_c", Vector2i(50, 8)], ["house_d", Vector2i(53, 12)],
			["house_d", Vector2i(41, 14)], ["house_a", Vector2i(49, 17)], ["house_b", Vector2i(55, 16)], ["house_a", Vector2i(56, 6)]]:
		_check_land(h[1])
		add_prop(h[0], h[1])
	# 나무·덤불(엄폐물 겸 채집)
	for c in [Vector2i(39, 2), Vector2i(44, 3), Vector2i(58, 2), Vector2i(61, 7), Vector2i(61, 23), Vector2i(38, 25)]:
		_check_land(c)
		add_prop("cypress", c, true, true)
	for c in [Vector2i(60, 3), Vector2i(52, 4)]:
		add_prop("pine", c, true, false)
	add_prop("stall_red", Vector2i(46, 11))
	for c in [Vector2i(57, 11), Vector2i(43, 22), Vector2i(53, 25)]:
		add_prop("bush", c, true, false)
	# 곡식 창고 셋: 통·상자·수레 무더기
	var stores := [[Vector2(44.5, 13.1), [["crate", Vector2i(44, 12)], ["amphora", Vector2i(43, 12)]]],
		[Vector2(52.5, 11.4), [["cart", Vector2i(52, 10)], ["crate", Vector2i(53, 10)]]],
		[Vector2(47.5, 20.7), [["barrel", Vector2i(47, 19)], ["barrel", Vector2i(46, 20)], ["crate", Vector2i(48, 20)]]]]
	for s in stores:
		for pr in s[1]:
			_check_land(pr[1])
			add_prop(pr[0], pr[1], true, false)
		var it := Interactable.new()
		it.label = Lines.t("label.loot")
		it.hold_time = 1.5
		it.radius = 26.0
		it.position = Iso.grid_to_world(s[0])
		it.on_use = func(_by): _loot(it)
		world.add_child(it)
		loot_points.append(it)
	# 해안 승선 지점의 깃발
	add_prop("banner_greek", Vector2i(36, 22), true, false)
	_build_lotus_island()
	_build_sea_astar()


## 로토스 섬: 가운데 흙길 마을, 로토스나무(올리브 그림을 분홍빛으로 — 임시), 소나무·덤불·바위
func _build_lotus_island() -> void:
	_path_line(Vector2(38.5, 75.0), Vector2(38.0, 84.0))
	_path_line(Vector2(38.0, 84.0), Vector2(36.0, 90.0))
	_path_line(Vector2(38.0, 84.0), Vector2(42.0, 88.0))
	fill(Rect2i(36, 86, 4, 3), "dirt")
	for c in LOTUS_TREES:
		_check_land(c)
		var s := add_prop("olive", c, true, false)
		s.modulate = Color(1.0, 0.74, 0.92)
	for c in [Vector2i(30, 80), Vector2i(44, 80), Vector2i(31, 92), Vector2i(45, 93), Vector2i(43, 78)]:
		_check_land(c)
		add_prop("pine" if c.x < 40 else "cypress", c, true, c.x >= 40)
	for c in [Vector2i(34, 79), Vector2i(44, 84), Vector2i(35, 94)]:
		_check_land(c)
		add_prop("bush", c, true, false)
	add_prop("rock", Vector2i(28, 87), true, false)
	add_prop("rock", Vector2i(48, 89), true, false)


func _check_land(c: Vector2i) -> void:
	if floor_kind.get(c, "water") == "water":
		push_warning("챕터 2: 땅이 아닌 칸에 소품 " + str(c))


func _path_line(a: Vector2, b: Vector2) -> void:
	var n := int(a.distance_to(b) * 2.0) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		var c := Vector2i(floori(p.x), floori(p.y))
		if floor_kind.get(c, "") == "grass":
			floor_kind[c] = "dirt"


# ── 바다 길찾기(배): 둘레 8칸이 모두 바다인 칸만 지나간다(배 길이만큼 여유) ───────
func _build_sea_astar() -> void:
	sea_astar.region = Rect2i(0, 0, W, H)
	sea_astar.cell_size = Vector2(1, 1)
	sea_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	sea_astar.update()
	for x in W:
		for y in H:
			var c := Vector2i(x, y)
			var ok := sea_ok(c)
			if ok:
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if not sea_ok(c + Vector2i(dx, dy)):
							ok = false
			sea_astar.set_point_solid(c, not ok)


func _sea_nearest(c: Vector2i) -> Vector2i:
	if sea_astar.is_in_boundsv(c) and not sea_astar.is_point_solid(c):
		return c
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if sea_astar.is_in_boundsv(n) and not sea_astar.is_point_solid(n):
					return n
	return c


## 격자 a → b 바다 길(칸 가운데 점들, 첫 점 빼고). 못 가면 갈 수 있는 데까지
func sea_path(a: Vector2, b: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var ca := _sea_nearest(Vector2i(floori(a.x), floori(a.y)))
	var cb := _sea_nearest(Vector2i(floori(b.x), floori(b.y)))
	if not sea_astar.is_in_boundsv(ca) or not sea_astar.is_in_boundsv(cb):
		return out
	var ids := sea_astar.get_id_path(ca, cb, true)
	for i in range(1, ids.size()):
		out.append(Vector2(ids[i]) + Vector2(0.5, 0.5))
	if out.is_empty():
		out.append(b)
	return out


# ── 시작 ──────────────────────────────────────────────
func start() -> void:
	var carry := Game.carry_for(2)
	player = Player.new()
	player.position = Iso.grid_to_world(START)
	world.add_child(player)
	if carry.has("food"):
		player.nutrition.load_state(carry["food"])
	rations.load_state(carry)
	ship = Ship.new()
	ship.display_name = Lines.t("names.ship")
	ship.gpos = START
	ship.heading = START_HEADING
	world.add_child(ship)
	ship.sunk.connect(_on_ship_sunk)
	var crew: Array = carry.get("crew", Lines.list("names.crew"))
	if crew.is_empty():
		crew = Lines.list("names.crew")
	for m in crew:
		var c := Companion.new()
		c.setup(m[0], m[1])
		c.position = player.position
		world.add_child(c)
		squad.add_member(c)
	_board_all(true)
	land_point = Interactable.new()
	land_point.label = Lines.t("label.land")
	land_point.radius = 100.0
	land_point.position = Iso.grid_to_world(ANCHOR + Vector2(-0.6, 0))
	land_point.on_use = func(_by): _try_land()
	world.add_child(land_point)
	board_point = Interactable.new()
	board_point.label = Lines.t("label.board")
	board_point.hold_time = LAUNCH_TIME
	board_point.radius = 34.0
	board_point.enabled = false
	board_point.position = Iso.grid_to_world(BOARD_AT)
	board_point.on_use = func(_by): _board()
	world.add_child(board_point)
	_place_village()
	_place_lotus()
	storm_fx = StormFx.new()
	add_child(storm_fx)
	Bgm.play("ending", 2.0)
	Bgm.amb("sea", 1.0, 2.0)
	Bgm.amb("wind", 0.5, 2.0)
	_set_step(0)
	# HUD가 생긴 뒤에(레벨이 먼저 만들어진다) 첫 대사. 체크포인트에서 다시 하면 건너뜀
	get_tree().create_timer(1.2).timeout.connect(func():
		if step == 0 and not _restored:
			Game.say(Lines.say("intro")))


func _place_village() -> void:
	var dirs := [Vector2(-1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(-1, 1), Vector2(-1, 0)]
	var spots := [["cicones_sword", Vector2(47.5, 13.0)], ["cicones_spear", Vector2(45.5, 16.5)], ["cicones_archer", Vector2(51.5, 12.5)],
		["cicones_sword", Vector2(45.5, 19.5)], ["cicones_archer", Vector2(53.5, 9.5)]]
	for i in spots.size():
		var e := _spawn(spots[i][0], spots[i][1])
		e.raises_alarm = false
		var f := _gdir(dirs[i])
		e.face(f)
		e.home_facing = f
		defenders.append(e)
	# 음식(docs/NUTRITION.md §6 챕터 2): 올리브나무·덤불·좌판, 양·염소·닭
	var spots_f := [["olive", Vector2(38, 8), "fruit", Color(0.35, 0.45, 0.2)], ["berry", Vector2(57, 11), "fruit", Color(0.8, 0.15, 0.2)],
		["berry", Vector2(43, 22), "fruit", Color(0.8, 0.15, 0.2)], ["berry", Vector2(53, 25), "fruit", Color(0.8, 0.15, 0.2)],
		["fig", Vector2(46, 11), "fruit", Color(0.55, 0.2, 0.45)], ["nuts", Vector2(60, 3), "", Color.WHITE], ["olive", Vector2(43, 12), "", Color.WHITE]]
	add_prop("olive", Vector2i(38, 8), true, false)
	for s in spots_f:
		var fs := FoodSource.new().setup(s[0], s[2])
		fs.fruit_color = s[3]
		fs.position = Iso.grid_to_world(s[1] + Vector2(0.5, 1.15))
		world.add_child(fs)
	for a in [["goat", Vector2(40.0, 6.0)], ["goat", Vector2(39.5, 4.0)], ["sheep", Vector2(55.0, 21.0)], ["sheep", Vector2(58.0, 22.0)],
			["sheep", Vector2(57.0, 24.0)], ["chicken", Vector2(44.5, 18.5)], ["chicken", Vector2(48.5, 22.5)]]:
		var an := Animal.new().setup(a[0])
		an.position = Iso.grid_to_world(a[1])
		an.wander_radius = 30.0 if a[0] == "chicken" else 44.0
		world.add_child(an)


## 로토스 섬: 로토스 열매 넷(먹으면 고향을 잊음 — 배 창고에 못 넣음), 무화과·산딸기·잣, 해안 낚시터, 로토파고스 셋(말을 걸면 열매를 권함)
func _place_lotus() -> void:
	for c in LOTUS_TREES:
		var fs := FoodSource.new().setup("lotus", "fruit")
		fs.fruit_color = Color(0.98, 0.72, 0.3)
		fs.position = Iso.grid_to_world(Vector2(c) + Vector2(0.5, 1.15))
		world.add_child(fs)
		lotus_fruits.append(fs)
	for s in [["fig", Vector2(34, 79), Color(0.55, 0.2, 0.45)], ["berry", Vector2(44, 84), Color(0.8, 0.15, 0.2)],
			["berry", Vector2(35, 94), Color(0.8, 0.15, 0.2)], ["nuts", Vector2(30, 80), Color.WHITE]]:
		var fs := FoodSource.new().setup(s[0], "fruit" if s[0] != "nuts" else "")
		fs.fruit_color = s[2]
		fs.position = Iso.grid_to_world(s[1] + Vector2(0.5, 1.15))
		world.add_child(fs)
	var fish := FoodSource.new().setup("fish", "bob")
	fish.radius = 34.0
	fish.position = Iso.grid_to_world(Vector2(35.6, 73.6))
	world.add_child(fish)
	for i in LOTOPHAGI.size():
		var n := Npc.new()
		n.setup("greek_archer", Lines.t("names.lotophagi"), Callable())
		var talk := n.talk
		# 한 번 말하면 잠시 쉰다(붙어 서 있는 동안 대사가 되풀이되지 않게)
		talk.on_use = func(_by):
			talk.enabled = false
			Game.say(Lines.say("lotophagi"))
			get_tree().create_timer(12.0).timeout.connect(func(): talk.enabled = true)
		n.tint = Color(1.05, 0.82, 1.0)
		n.position = Iso.grid_to_world(LOTOPHAGI[i])
		world.add_child(n)


## 로토스 열매 곁에 앉을 자리(나무 i의 열매 남서쪽)
func _seat(i: int) -> Vector2:
	var c: Vector2i = LOTUS_TREES[i % LOTUS_TREES.size()]
	return Iso.grid_to_world(Vector2(c) + Vector2(-0.2, 1.9))


func _gdir(g: Vector2) -> Vector2:
	return (Iso.grid_to_world(g) - Iso.grid_to_world(Vector2.ZERO)).normalized()


func _spawn(kind: String, g: Vector2) -> Enemy:
	var e := Enemy.new()
	e.setup(kind)
	e.position = Iso.grid_to_world(g)
	world.add_child(e)
	return e


# ── 배 타기·내리기 ─────────────────────────────────────
## 오디세우스와 부하를 배에 태운다(숨김). quiet면 소리·글 없이(시작할 때)
func _board_all(quiet := false) -> void:
	player.set_riding(ship)
	ship.rider = player
	ship.crew = squad.members.duplicate()
	for c in squad.members:
		_hide_member(c, true)
	if not quiet:
		Sfx.play("splash", -8.0)


func _hide_member(c: Companion, aboard: bool) -> void:
	c.visible = not aboard
	c.process_mode = Node.PROCESS_MODE_DISABLED if aboard else Node.PROCESS_MODE_INHERIT
	c._shape.set_deferred("disabled", aboard or c.state == Actor.St.DOWNED)
	if aboard:
		c.remove_from_group("actors")
		c.target = null
	elif not c.is_in_group("actors"):
		c.add_to_group("actors")


func _try_land() -> void:
	if (step != 0 and step != 4) or ship.rider == null:
		return
	if absf(ship.speed) > LAND_SPEED:
		Game.show_hint(Lines.t("hint.slow_down"))
		return
	_land()


func _land() -> void:
	var lotus := step == 4
	var at: Vector2 = LOTUS_LAND_AT if lotus else LAND_AT
	var inland: Vector2 = Vector2(0, 1) if lotus else Vector2(1, 0)
	ship.gpos = LOTUS_ANCHOR if lotus else ANCHOR
	ship.heading = -PI * 0.5 if lotus else PI   # 고물을 해안 쪽으로 대 놓는다(떠날 때 바로 나감)
	ship.speed = 0.0
	ship.gear = 0
	ship.set_sail(false)
	ship.rider = null
	ship.crew = []
	ship._sync()
	player.set_riding(null)
	player.position = Iso.grid_to_world(at)
	player.face(_gdir(inland))
	for i in squad.members.size():
		var c: Companion = squad.members[i]
		_hide_member(c, false)
		var side := Vector2(-0.9 + i * 0.6, -0.4) if lotus else Vector2(-0.4, -0.9 + i * 0.6)
		c.position = Iso.grid_to_world(at + side)
		c.hold_anchor = c.position
		c.face(_gdir(inland))
	land_point.enabled = false
	Sfx.play("splash", -6.0)
	if lotus:
		area_name = Lines.t("meta.area_lotus_land")
		if Game.hud:
			Game.hud.show_title(Lines.list("title.lotus_land"))
		_set_step(5)
		Game.say(Lines.say("lotus_landed"))
		return
	area_name = Lines.t("meta.area_land")
	if Game.hud:
		Game.hud.show_title(Lines.list("title.land"))
	_set_step(1)
	Game.say(Lines.say("landed"))


## 출항: 가까운(CARRY_DIST) 쓰러진 부하는 업어 태우고, 더 먼 부하는 두고 간다
func _board() -> void:
	if step == 6:
		_board_lotus()
		return
	if step != 2:
		return
	var from := board_point.global_position
	for c in squad.members.duplicate():
		if c.state == Actor.St.DOWNED:
			if c.global_position.distance_to(from) <= CARRY_DIST:
				c.revive(0.4)
			else:
				_lose(c)
	for i in squad.members.size():
		squad.members[i].squad_index = i
	_board_all()
	board_point.enabled = false
	ship.gear = 0
	area_name = Lines.t("meta.area")
	_set_step(3)
	Game.say(Lines.say("boarded"))


## 로토스 섬 출항: 고향을 잊은 채 남은 부하(끌고 오지 못한)는 섬에 남는다. 끌고 온 부하는 노 젓는 자리 밑에 묶는다
func _board_lotus() -> void:
	for c in squad.members.duplicate():
		if c.lotus == Companion.Lotus.LURED or c.lotus == Companion.Lotus.DAZED:
			_lose(c, "hint.lost_lotus")
		else:
			if c.state == Actor.St.DOWNED:
				c.revive(0.4)
			c.clear_lotus()
	for i in squad.members.size():
		squad.members[i].squad_index = i
	_board_all()
	board_point.enabled = false
	ship.gear = 0
	area_name = Lines.t("meta.area_lotus")
	_set_step(7)
	Game.say(Lines.say("lotus_board" if bound > 0 else "lotus_board_none"))


func _lose(c: Companion, hint := "hint.lost") -> void:
	squad.members.erase(c)
	scouts.erase(c)
	lost.append(c.display_name)
	Game.stats["lost"] = Game.stats.get("lost", 0) + 1
	Game.show_hint(Lines.t(hint, c.display_name))
	c.queue_free()


# ── 약탈·반격 ─────────────────────────────────────────
func _loot(it: Interactable) -> void:
	if not it.enabled:
		return
	it.enabled = false
	looted += 1
	var n := rations.add(LOOT_UNITS)
	Sfx.play("ui_ok", -6.0)
	Fx.text(it.global_position + Vector2(0, -34), "창고 +%d" % n, Color(0.75, 0.9, 1.0))
	Game.show_hint(Lines.t("hint.loot", n))
	if step == 1 and looted >= loot_points.size():
		_set_step(2)


func _send_wave() -> void:
	_waves += 1
	var kinds: Array = [["cicones_sword", "cicones_spear", "cicones_sword"], ["cicones_spear", "cicones_archer", "cicones_sword", "cicones_sword"],
		["cicones_chief", "cicones_sword", "cicones_spear", "cicones_archer"]][mini(_waves, COUNTER_WAVES) - 1]
	var from: Array = FLANKS if _waves == 1 else INLAND
	for i in kinds.size():
		var at: Vector2 = from[i % from.size()] + Vector2(randf_range(-0.6, 0.6), randf_range(-0.8, 0.8))
		var e := _spawn(kinds[i], at)
		e.raises_alarm = false
		e.hunts_player = true
		e.alert(player)


func on_boss_horn(_boss: Enemy) -> void:
	for i in 2:
		var e := _spawn("cicones_sword", INLAND[i])
		e.raises_alarm = false
		e.hunts_player = true
		e.alert(player)
	Game.show_hint(Lines.t("hint.horn", _boss.display_name))


func _launch_boats() -> void:
	for b in BOATS:
		var s := Ship.new().as_enemy_boat()
		s.gpos = b
		s.heading = PI * 0.25
		s.target_ship = ship
		world.add_child(s)
		boats.append(s)


func _on_ship_sunk(_s: Ship) -> void:
	if _done:
		return
	_done = true
	death_text = Lines.t("meta.death_sea")
	Game.quest_marker = Vector2.INF
	Sfx.play("death")
	Bgm.sting("defeat")
	await get_tree().create_timer(1.8).timeout
	Game.player_died.emit()


# ── 폭풍 → 로토스 섬 ─────────────────────────────────
## 이스마로스 먼바다에 닿음: 탈출 대사 뒤 폭풍
func _escaped() -> void:
	_storming = true
	ship.gear = 0
	Game.quest_marker = Vector2.INF
	for b in boats:
		if is_instance_valid(b):
			b.target_ship = null
	Bgm.sting("victory")
	if Game.hud:
		Game.hud.show_title(Lines.list("title.escaped"))
	Game.say(Lines.say("escaped"), func(): _start_storm())


## 폭풍 시작: 적 배·화살을 치우고 비·번개·거친 물결. teleport면 배를 폭풍 자리로 옮긴다(체크포인트·검증)
func _start_storm(teleport := false) -> void:
	_storming = true
	_clear_ismaros_foes()
	storm_on = true
	_storm_t = 0.0
	_surge_t = 2.5
	_bolt_t = 1.5
	if teleport:
		ship.gpos = STORM_START
		ship.heading = _storm_dir.angle()
		ship.speed = 0.0
		ship._wake.clear()
		ship._sync()
		player.global_position = ship.global_position
		_cam_pos = ship.global_position
		if Game.hud:
			Game.hud.clear_story()
	ship.max_speed = STORM_SPEED
	wind_strength = STORM_WIND
	_canvas_base = Color(0.5, 0.53, 0.66)
	canvas_mod.color = _canvas_base
	area_name = Lines.t("meta.area_storm")
	_save_checkpoint("storm")
	Bgm.play("siege", 1.5)
	Bgm.amb("wind", 1.0, 1.5)
	Bgm.amb("rain", 0.9, 1.5)
	Bgm.amb("sea", 1.0, 1.5)
	if Game.hud:
		Game.hud.show_title(Lines.list("title.storm_start"))
	_tut_clear()
	_tut(Lines.t("tut.storm"), func(): return not storm_on, 18.0)


func _clear_ismaros_foes() -> void:
	for b in boats:
		if is_instance_valid(b):
			b.queue_free()
	boats.clear()
	for e in enemies():
		e.queue_free()
	for n in fx_layer.get_children():
		if n is Ship.Shot:
			n.queue_free()


## 폭풍 속 매 프레임: 바람이 흔들리고, 파도가 바람 쪽에서 덮치고, 번개가 친다. 다 버티면 _storm()
func _update_storm(delta: float) -> void:
	_storm_t += delta
	wind = _storm_dir.rotated(0.55 * sin(_t / 4.5) + 0.25 * sin(_t * 1.3))
	wind_strength = STORM_WIND
	var wd := (Iso.ex * wind.x + Iso.ey * wind.y).normalized()
	storm_fx.lean = Vector2(wd.x * 0.6, 1.0)
	# 표시: 바람이 불어 가는 쪽(봇도 이걸 따라 바람을 등진다)
	var goal := (ship.gpos + wind * 6.0).clamp(Vector2(3, 3), Vector2(W - 4, 70))
	Game.quest_marker = Iso.grid_to_world(goal)
	Game.set_objective(chapter_title, Lines.t("objective.storm", maxi(0, ceili(STORM_TIME - _storm_t))))
	_surge_t -= delta
	if _surge_t <= 0.0:
		_surge_t = randf_range(SURGE_EVERY.x, SURGE_EVERY.y)
		_surge()
	_bolt_t -= delta
	if _bolt_t <= 0.0:
		_bolt_t = randf_range(3.5, 8.0)
		storm_fx.lightning()
		get_tree().create_timer(randf_range(0.2, 0.9)).timeout.connect(func(): Sfx.play("thunder", -4.0))
	if _storm_t >= STORM_TIME:
		storm_on = false
		_storm()


## 파도 한 번: 옆구리(바람과 직각)로 맞을수록 크게 다치고 배가 옆으로 돌려진다. 펴 둔 돛은 찢어진다
func _surge() -> void:
	var w := wind.normalized()
	var broad := absf(ship.right().dot(w))
	var dmg := SURGE_DMG * (0.15 + 0.85 * broad * broad)
	ship.damage(dmg, null)
	var push := ship.gpos + w * 0.45
	if ship._clear_at(push, ship.heading):
		ship.gpos = push
	var cross := ship.fwd().x * w.y - ship.fwd().y * w.x
	var turn := 0.3 * (1.0 - broad) * signf(cross)
	if ship._clear_at(ship.gpos, ship.heading + turn):
		ship.heading = wrapf(ship.heading + turn, -PI, PI)
	ship._sync()
	Sfx.play("wave", -3.0 + 4.0 * broad)
	Game.shake(2.5 + 5.0 * broad)
	Fx.text(ship.global_position + Vector2(0, -56), "파도! -%d" % roundi(dmg), Color(0.75, 0.88, 1.0) if broad < 0.5 else Color(1, 0.6, 0.5))
	if broad > 0.5:
		Game.stats["broadside"] = Game.stats.get("broadside", 0) + 1
		if not squad.members.is_empty():
			var c: Companion = squad.members.pick_random()
			c.hp = maxf(1.0, c.hp - SURGE_CREW_DMG * broad)
		if not _side_warned:
			_side_warned = true
			Game.show_hint(Lines.t("hint.wave_side"))
	if ship.sail and not ship.sail_torn:
		ship.sail = false
		ship.sail_torn = true
		Sfx.play("ram", -8.0)
		Game.show_hint(Lines.t("hint.sail_torn"))


## 폭풍이 지나감 → 여러 날 밀려 로토스 섬 앞바다로. instant면 화면 연출·식량 소비 없이 바로(검증·체크포인트)
func _storm(instant := false) -> void:
	_storming = true
	storm_on = false
	_clear_ismaros_foes()
	Game.quest_marker = Vector2.INF
	if not instant:
		Game.cutscene = true
		Game.set_objective(chapter_title, Lines.t("objective.drift"))
		Bgm.amb("wind", 1.0, 1.0)
		Game.shake(5.0)
		canvas_mod.color = Color(0.45, 0.48, 0.6)
		if Game.hud:
			Game.hud.fade_to(1.0, 1.6)
		await get_tree().create_timer(1.8).timeout
		var before := rations.store
		var missed := 0
		for i in STORM_DAYS:
			missed += int(rations.pass_day(squad.members.size())["missed"])
		if Game.hud:
			Game.hud.show_title(Lines.list("title.storm"))
		Game.show_hint(Lines.t("hint.storm_days" if missed == 0 else "hint.storm_days_miss",
			[STORM_DAYS, before - rations.store, rations.store, roundi(rations.fullness)]))
	# 폭풍이 지나감: 비·물결을 가라앉히고 찢어진 돛을 기운다
	ship.max_speed = INF
	Bgm.amb("rain", 0.0, 2.0)
	Bgm.amb("sea", 1.0, 2.0)
	if ship.sail_torn:
		ship.sail_torn = false
		Game.show_hint(Lines.t("hint.sail_mended"))
	ship.gpos = LOTUS_START
	ship.heading = LOTUS_START_HEADING
	ship.speed = 0.0
	ship.gear = 0
	ship.set_sail(false)
	ship._wake.clear()
	ship._sync()
	player.global_position = ship.global_position
	_cam_pos = ship.global_position
	_wind_base = Vector2(-0.35, 0.94).normalized()
	wind_strength = 0.45
	_canvas_base = Color(1.0, 0.93, 0.86)
	canvas_mod.color = _canvas_base
	area_name = Lines.t("meta.area_lotus")
	if instant and Game.hud:
		Game.hud.clear_story()
	_set_step(4)
	if not instant:
		await get_tree().create_timer(3.0).timeout
		if Game.hud:
			Game.hud.fade_to(0.0, 1.4)
		Game.cutscene = false
		Bgm.amb("wind", 0.35, 3.0)
		if Game.hud:
			Game.hud.show_title(Lines.list("title.lotus"))
		Game.say(Lines.say("lotus_arrive"))
	_storming = false


## 상륙하자마자 뒤쪽 부하 둘을 정찰 보낸다 — 둘은 로토스 열매에 닿아 먹고 고향을 잊는다
func _send_scouts() -> void:
	scouts.clear()
	var n := mini(SCOUTS, squad.members.size())
	for i in n:
		var c: Companion = squad.members[squad.members.size() - 1 - i]
		c.lure(_seat(i))
		scouts.append(c)
	if n > 0:
		Game.show_hint(Lines.t("hint.scouts", ", ".join(scouts.map(func(c): return c.display_name))))


## 열매 곁에 오래 있는 부하는 끌려간다(정찰·묶인 부하·쓰러진 부하는 빼고)
func _update_lure(delta: float) -> void:
	for c in squad.members:
		if c.lotus != Companion.Lotus.NONE or c.state == Actor.St.DOWNED:
			continue
		var best := -1
		var bd := LURE_DIST
		for i in lotus_fruits.size():
			var d: float = c.global_position.distance_to(lotus_fruits[i].global_position)
			if d < bd:
				bd = d
				best = i
		var id: int = c.get_instance_id()
		if best < 0:
			_lure_t[id] = 0.0
			continue
		_lure_t[id] = float(_lure_t.get(id, 0.0)) + delta
		if _lure_t[id] > LURE_TIME:
			_lure_t[id] = 0.0
			c.lure(_seat(best))
			Game.show_hint(Lines.t("hint.lured", c.display_name))


func on_crew_dazed(c: Companion) -> void:
	if step == 5 and c in scouts and scouts.all(func(s): return s.lotus == Companion.Lotus.DAZED):
		_set_step(6)
	elif step == 6:
		Game.show_hint(Lines.t("hint.dazed", c.display_name))


func on_crew_bound(c: Companion) -> void:
	bound += 1
	Game.stats["dragged"] = Game.stats.get("dragged", 0) + 1
	Game.show_hint(Lines.t("hint.bound", c.display_name))
	# 정찰이 아직 열매에 닿기 전에 붙잡았으면 바로 다음 단계
	if step == 5 and scouts.all(func(s): return s.lotus != Companion.Lotus.LURED):
		_set_step(6)


## 오디세우스가 로토스를 먹음(Player.eat)
func on_forget() -> void:
	Game.say(Lines.say("forget"))


func _dazed_left() -> Array:
	return squad.members.filter(func(c): return c.lotus == Companion.Lotus.LURED or c.lotus == Companion.Lotus.DAZED)


func _refresh_rescue_marker() -> void:
	var left := _dazed_left()
	var best: Node2D = board_point
	var bd := INF
	for c in left:
		var d: float = c.global_position.distance_to(player.global_position)
		if d < bd:
			bd = d
			best = c
	Game.quest_marker = best.global_position
	if left.is_empty():
		Game.set_objective(chapter_title, Lines.t("objective.lotus_board"))
	else:
		Game.set_objective(chapter_title, Lines.t("objective.rescue", left.size()))


# ── 단계 ──────────────────────────────────────────────
func _set_step(s: int) -> void:
	step = s
	match s:
		0:
			Game.quest_marker = land_point.global_position
			Game.set_objective(chapter_title, Lines.t("objective.sail"))
			_tut(Lines.t("tut.oars"), func(): return ship.gear == 2)
			_tut(Lines.t("tut.steer"), func(): return absf(ship.turn_in) > 0.5 and absf(ship.speed) > 0.6, 14.0)
			_tut(Lines.t("tut.sail"), func(): return ship.sail, 16.0)
			_tut(Lines.t("tut.land"), func(): return step >= 1, 30.0)
		1:
			_save_checkpoint("landing")
			Bgm.play("battle", 2.0)
			Bgm.amb("wind", 0.25, 2.0)
			_tut(Lines.t("tut.loot"), func(): return looted > 0, 25.0)
			_tut(Lines.t("tut.store"), func(): return Game.stats.get("stored", 0) > 0 or Game.stats.get("meals", 0) > 0, 20.0)
			_refresh_loot_marker()
		2:
			_save_checkpoint("retreat")
			Bgm.play("siege", 1.5)
			board_point.enabled = true
			Game.quest_marker = board_point.global_position
			Game.set_objective(chapter_title, Lines.t("objective.retreat"))
			canvas_mod.color = Color(0.92, 0.78, 0.72)
			if Game.hud:
				Game.hud.show_title(Lines.list("title.counter"))
			Game.say(Lines.say("counter"))
			_wave_t = 2.0
			_waves = 0
			_tut(Lines.t("tut.launch"), func(): return step >= 3, 20.0)
		3:
			_save_checkpoint("escape")
			Bgm.play("battle", 1.5)
			Bgm.amb("wind", 1.0, 3.0)
			Game.quest_marker = Iso.grid_to_world(EXIT_MARK)
			Game.set_objective(chapter_title, Lines.t("objective.escape"))
			# 제우스의 북풍: 남쪽(빠져나갈 쪽)으로 세게 분다 — 돛을 펴면 빠르지만 밀린다
			_wind_base = Vector2(0.55, 0.83).normalized()
			wind_strength = 1.0
			canvas_mod.color = Color(0.66, 0.68, 0.8)
			_launch_boats()
			_tut(Lines.t("tut.ram"), func(): return Game.stats.get("sunk", 0) > 0, 14.0)
		4:
			_save_checkpoint("lotus")
			Bgm.play("ending", 2.0)
			land_point.position = Iso.grid_to_world(LOTUS_ANCHOR + Vector2(0, -0.6))
			land_point.enabled = true
			Game.quest_marker = land_point.global_position
			Game.set_objective(chapter_title, Lines.t("objective.lotus_sail"))
		5:
			_send_scouts()
			Game.quest_marker = Iso.grid_to_world(LOTUS_C + Vector2(0.0, 1.0))
			Game.set_objective(chapter_title, Lines.t("objective.scout"))
			_tut(Lines.t("tut.lure"), func(): return Game.squad.mode == Squad.Mode.HOLD, 18.0)
			# 봇: 남은 부하는 해안에 세워 둔다(사람에게 권하는 방법 그대로)
			if Game.autoplay:
				Game.squad.command(Squad.Mode.HOLD, player.global_position)
			if scouts.is_empty():
				_set_step(6)
		6:
			board_point.position = Iso.grid_to_world(LOTUS_BOARD_AT)
			board_point.label = Lines.t("label.board_lotus")
			board_point.hold_time = 2.0
			board_point.enabled = true
			if not scouts.is_empty():
				Game.say(Lines.say("lotus_missing"))
			_tut(Lines.t("tut.drag"), func(): return bound > 0, 20.0)
			_refresh_rescue_marker()
		7:
			Bgm.play("ending", 2.0)
			Game.quest_marker = Iso.grid_to_world(LOTUS_EXIT_MARK)
			Game.set_objective(chapter_title, Lines.t("objective.lotus_leave"))


func _refresh_loot_marker() -> void:
	var best: Interactable = null
	var bd := INF
	for it in loot_points:
		if it.enabled:
			var d: float = it.global_position.distance_to(player.global_position)
			if d < bd:
				bd = d
				best = it
	Game.quest_marker = best.global_position if best else Vector2.INF
	Game.set_objective(chapter_title, Lines.t("objective.loot", [looted, loot_points.size()]))


# ── 체크포인트 ──────────────────────────────────────
func _save_checkpoint(id: String) -> void:
	Game.checkpoint = {"chapter": 2, "id": id, "stats": Game.stats.duplicate(), "food": player.nutrition.state(),
		"rations": rations.store, "fullness": rations.fullness, "looted": looted,
		"crew": squad.members.map(func(c): return [c.role, c.display_name]), "hull": ship.hull}
	Game.save_progress()
	Sfx.play("checkpoint", -8.0)
	Fx.text(player.global_position + Vector2(0, -64), Lines.t("fx.checkpoint"), Color(0.55, 0.85, 1.0))


func checkpoint_name(id: String) -> String:
	return {"landing": "상륙", "retreat": "반격 시작", "escape": "출항", "storm": "폭풍", "lotus": "로토스 섬"}.get(id, id)


func restore_checkpoint(cp: Dictionary) -> void:
	player.nutrition.load_state(cp.get("food", {}))
	rations.store = int(cp.get("rations", rations.store))
	rations.fullness = float(cp.get("fullness", rations.fullness))
	ship.hull = float(cp.get("hull", ship.max_hull))
	# 부하: 체크포인트 때 있던 사람만
	var keep: Array = cp.get("crew", []).map(func(m): return m[1])
	for c in squad.members.duplicate():
		if not c.display_name in keep:
			squad.members.erase(c)
			c.queue_free()
	for i in squad.members.size():
		squad.members[i].squad_index = i
	ship.crew = squad.members.duplicate()
	_restored = true
	skip_to(String(cp["id"]))
	if Game.hud:
		Game.hud.clear_story()
		if step == 4:
			Game.hud.show_title(Lines.list("title.lotus"))
		elif storm_on:
			Game.hud.show_title(Lines.list("title.storm_start"))
	for i in mini(int(cp.get("looted", 0)), loot_points.size()):
		if loot_points[i].enabled:
			loot_points[i].enabled = false
			looted += 1
	if step == 1:
		_refresh_loot_marker()
	Game.show_hint(Lines.t("hint.checkpoint"))


## 검증용 --start=landing|retreat|escape|storm|lotus|lotus_land
func skip_to(id: String) -> void:
	_tut_clear()
	match id:
		"landing":
			if step == 0:
				_land()
		"retreat":
			if step == 0:
				_land()
			for it in loot_points:
				if it.enabled:
					it.enabled = false
					looted += 1
			for e in defenders:
				if is_instance_valid(e):
					e.queue_free()
			_set_step(2)
		"escape":
			skip_to("retreat")
			_board()
		"storm":
			skip_to("escape")
			_start_storm(true)
		"lotus":
			skip_to("escape")
			_storm(true)
		"lotus_land":
			skip_to("lotus")
			_land()


func report() -> Dictionary:
	return {"ending": ending_done, "hull": snappedf(ship.hull, 0.1), "rations": rations.store, "fullness": snappedf(rations.fullness, 0.1),
		"day": rations.day, "crew": squad.members.size(), "lost": lost, "looted": looted, "step": step,
		"bound": bound, "lotus_eaten": Game.stats.get("lotus", 0), "broadside": Game.stats.get("broadside", 0), "sail_torn": ship.sail_torn,
		"boats": boats.filter(func(b): return is_instance_valid(b) and not b.sunk_done).size(),
		"ship_cell": ship.gpos.snapped(Vector2(0.1, 0.1)), "riding": player.riding != null}


func result_info(st: Dictionary) -> Dictionary:
	var t: float = st.get("time", 0.0)
	var badge := ""
	if st.get("lost", 0) == 0:
		badge = "칭호 「아무도 두고 오지 않은 자」 — 이스마로스와 로토스 섬에서 부하를 하나도 잃지 않음"
		if st.get("lotus", 0) == 0:
			badge += " · 로토스도 입에 대지 않음"
	return {"head": "CHAPTER 2 클리어", "title": "로토스 섬을 떠났다", "badge": badge,
		"badge_hint": "이스마로스와 로토스 섬에서 부하를 하나도 잃지 않으면 칭호를 얻는다",
		"rows": [
			"시간 %d분 %02d초   ·   처치 %d   ·   격침 %d   ·   들이받기 %d" % [int(t) / 60, int(t) % 60, st.get("kills", 0), st.get("sunk", 0), st.get("rams", 0)],
			"곡식 창고 %d/%d   ·   배 창고 %d몫   ·   부하 배부름 %d   ·   잃은 부하 %d" % [looted, loot_points.size(), rations.store, roundi(rations.fullness), st.get("lost", 0)],
			"먹은 횟수 %d   ·   창고에 넣은 몫 %d   ·   남은 선체 %d%%" % [st.get("meals", 0), st.get("stored", 0), roundi(100.0 * ship.hull / ship.max_hull)],
			"옆으로 맞은 파도 %d   ·   끌고 온 부하 %d   ·   %s" % [Game.stats.get("broadside", 0), bound, "로토스를 먹지 않았다" if st.get("lotus", 0) == 0 else "로토스를 %d번 먹었다" % st.get("lotus", 0)],
		],
		"next": "다음: CHAPTER 3 — 외눈박이 거인 (준비 중). 영양·부하·식량 창고는 이어진다"}


# ── 매 프레임 ─────────────────────────────────────────
func _process(delta: float) -> void:
	super._process(delta)
	_t += delta
	wind = _wind_base.rotated(0.3 * sin(_t / 23.0))
	_update_tut(delta)
	# 폭풍 화면(비·물결)은 천천히 오르내린다
	_storm_k = move_toward(_storm_k, 1.0 if storm_on else 0.0, delta * 0.5)
	if storm_fx:
		storm_fx.strength = _storm_k
	if water_material:
		water_material.set_shader_parameter("storm", _storm_k)
	if storm_fx and storm_fx.flash > 0.0:
		canvas_mod.color = _canvas_base.lerp(Color(1.3, 1.3, 1.45), storm_fx.flash * 0.6)
	elif storm_on:
		canvas_mod.color = _canvas_base
	if _done:
		return
	if ship.rider != null and not Game.cutscene:
		var day := rations.tick_sea(delta, squad.members.size())
		if not day.is_empty():
			_on_day(day)
	match step:
		1:
			_refresh_loot_marker()
		2:
			_wave_t -= delta
			if _waves < COUNTER_WAVES and _wave_t <= 0.0:
				_wave_t = COUNTER_INTERVAL
				_send_wave()
		3:
			if storm_on:
				_update_storm(delta)
			elif _storming:
				pass
			elif EXIT_RECT.has_point(ship.gpos):
				_escaped()
			elif ship.gpos.distance_to(ANCHOR) > 14.0:
				# 해안에 남은 키코네스는 더 쫓지 못한다
				for e in enemies():
					e.queue_free()
		5, 6:
			_update_lure(delta)
			if step == 6:
				_refresh_rescue_marker()
			else:
				Game.quest_marker = Iso.grid_to_world(LOTUS_C + Vector2(0.0, 1.0))
			# 오디세우스가 로토스를 먹고 고향을 잊은 동안: 목표 표시가 사라지고 화면이 흐려진다
			var k := clampf(player.forget_t / 3.0, 0.0, 1.0)
			if k > 0.0:
				Game.quest_marker = Vector2.INF
			canvas_mod.color = _canvas_base.lerp(Color(1.0, 0.72, 0.95), k * (0.7 + 0.3 * sin(_t * 2.0)))
		7:
			if ship.gpos.distance_to(LOTUS_C) > LOTUS_EXIT_DIST:
				_finish()


func _on_day(day: Dictionary) -> void:
	if day["missed"] > 0:
		Game.show_hint(Lines.t("hint.day_miss", [day["missed"], roundi(rations.fullness)]))
	else:
		Game.show_hint(Lines.t("hint.day", [day["ate"], day["ate"], rations.store]))
	if rations.fullness < Rations.HUNGRY and not _hungry_warned:
		_hungry_warned = true
		Game.show_hint(Lines.t("hint.hungry_crew"))


func _finish() -> void:
	_done = true
	ship.gear = 0
	Game.quest_marker = Vector2.INF
	Game.set_objective(chapter_title, Lines.t("objective.done"))
	for b in boats:
		if is_instance_valid(b):
			b.target_ship = null
	# 먼바다로 나가며 하루가 지난다(부하가 창고에서 먹음)
	_on_day(rations.pass_day(squad.members.size()))
	if Game.hud:
		Game.hud.show_title(Lines.list("title.clear"))
	Bgm.sting("victory")
	Game.say(Lines.say("lotus_left"), _end_chapter)


func _end_chapter() -> void:
	if ending_done:
		return
	ending_done = true
	Game.mark_cleared(2)
	Game.set_carry(3, {"food": player.nutrition.state(), "crew": squad.members.map(func(c): return [c.role, c.display_name]),
		"rations": rations.store, "fullness": rations.fullness})
	Game.chapter_cleared.emit(Game.stats.duplicate())


# ── 튜토리얼 카드(한 번에 하나, 할 일을 하면 ✓) ──────────
## 단계(step)가 바뀌면 그 전 단계의 남은 카드는 버린다
func _tut(text: String, done: Callable, timeout := 12.0) -> void:
	_tuts.append([text, done, timeout, step])


func _tut_clear() -> void:
	_tuts.clear()
	if not _tut_cur.is_empty():
		Game.tutorial("")
	_tut_cur = []


func _update_tut(delta: float) -> void:
	if _tut_cur.is_empty():
		_tut_gap -= delta
		if _tuts.is_empty() or _tut_gap > 0.0 or (Game.hud and Game.hud.dialogue.size() > 0):
			return
		_tut_cur = _tuts.pop_front()
		if _tut_cur[3] != step:
			_tut_cur = []
			return
		_tut_t = 0.0
		Game.tutorial(_tut_cur[0])
		return
	_tut_t += delta
	var cb: Callable = _tut_cur[1]
	if _tut_t > 1.0 and (cb.call() or _tut_t > _tut_cur[2] or _tut_cur[3] != step):
		Game.tutorial_done()
		_tut_cur = []
		_tut_gap = 1.2
