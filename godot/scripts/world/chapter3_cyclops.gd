class_name Chapter3Cyclops
extends IsoLevel
## CHAPTER 3 — 외눈박이 거인 (docs/maps/CH3_CYCLOPS.md).
## 바닷가 동굴에 들어가 치즈 선반을 살피면 → 폴리페모스가 돌아와 큰 바위로 입구를 막는다(연출) →
## 거인의 시야 부채꼴을 피해 포도주 항아리를 가져와 건넨다(들고 있으면 거인이 치지 않음) → 「우티스(아무도 아니다)」 대화,
## 거인이 취해 침상에 눕는다 → 동쪽 구석의 올리브 말뚝을 들고(느려지고 뛸 수 없음) 화덕에서 끝을 달궈 잠든 외눈을 찌른다
## (곁에서 뛰면 뒤척이며 움켜쥠) → 눈 먼 거인이 바위를 치우고 입구에 앉아 지킨다(가까이 가거나 뛰면 잡음) →
## 양 우리 문을 열고 큰 숫양 배 밑에 매달려 빠져나간다(연출) → 「나는 오디세우스다」 → 클리어.
## 칼로는 거인을 이길 수 없다(Cyclops는 actors 그룹 밖). 영양·부하는 챕터 2에서 이어받는다(Game.carry_for(3)).
## 체크포인트: 동굴에 갇힘(cave) · 거인이 잠듦(sleep) · 외눈을 찌름(blind).
##
## 격자 30×30: 위쪽 y 0~3은 동굴 밖 바위 길, y 4는 뒷벽(입구 x 13~15), x 0은 왼쪽 벽, x 29·y 29는 앞쪽 끝.
## 서쪽 위 = 치즈·포도주 창고, 가운데 = 화덕, 동쪽 위 = 말뚝, 동쪽 아래 = 거인 침상, 서쪽 아래 = 양 우리(문은 위쪽).
## 그림: assets/env/cave/(tools/install_cave.py), 거인 assets/sprites/polyphemus*.

const CAVE_JSON := "res://assets/env/cave/cave.json"
const START := Vector2(14.5, 1.6)
const HIDE := Vector2(3.6, 15.2)
const LOOK_AT := Vector2(4.6, 7.8)
const WINE_AT := Vector2(2.6, 10.6)
const HEARTH := Vector2i(14, 13)
const STAKE := Vector2i(24, 7)
const BED := Vector2i(21, 20)
const BED_SIDE := Vector2(25.0, 21.6)
const STAB_AT := Vector2(20.0, 21.8)
const GATE := Vector2i(5, 19)
const GATE_AT := Vector2(6.2, 18.0)
const PEN_C := Vector2(5.0, 24.0)
const ENTRANCE := [13, 14, 15]
const GIANT_OUT := Vector2(14.5, 0.8)
const GIANT_IN := Vector2(14.5, 6.6)
const GUARD_AT := Vector2(16.4, 5.7)
const EXIT_AT := Vector2(14.5, 0.6)
## 거인이 지키는 자리(포도주 전): [격자, 바라볼 격자 방향]
const POSTS := [[Vector2(17.5, 12.0), Vector2(1, 1)], [Vector2(9.5, 17.5), Vector2(-0.4, 1)], [Vector2(19.0, 8.0), Vector2(1, 0.6)]]
const CARRY_SPEED := 46.0
const RIDE_SPEED := 30.0

static var _cave: Dictionary = {}

var step := -1
var ending_done := false
var giant: Cyclops
var carrying := ""
var gate_open := false
var boulder: Sprite2D
var gate_sprite: Sprite2D
var stake_sprite: Sprite2D
var hearth_light: PointLight2D
var out_light: PointLight2D
var look_point: Interactable
var wine_point: Interactable
var give_point: Interactable
var stake_point: Interactable
var heat_point: Interactable
var stab_point: Interactable
var gate_point: Interactable
var ram_point: Interactable
var ram: Animal
var sheep: Array = []
var _carry_spr: Sprite2D
var _walk0 := 72.0
var _run0 := 118.0
var _restored := false
var _sword_cd := 0.0
var _riding := false
var _ride_path := PackedVector2Array()
var _ride_said := false
var _flock: Array = []
var _tuts: Array = []
var _tut_cur: Array = []
var _tut_t := 0.0
var _tut_gap := 0.0


static func cave() -> Dictionary:
	if _cave.is_empty():
		_cave = JSON.parse_string(FileAccess.get_file_as_string(CAVE_JSON))
	return _cave


static func g(v: Vector2) -> Vector2:
	return Iso.grid_to_world(v)


## 동굴 바닥 아틀라스(줄: cave_stone·cave_dust·cave_straw)
func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(64, 32)
	var src := TileSetAtlasSource.new()
	var fa: Dictionary = cave()["floor_atlas"]
	src.texture = AssetLibrary.texture("res://assets/env/cave/" + String(fa["file"]))
	src.texture_region_size = Vector2i(64, 32)
	_source_id = ts.add_source(src)
	var rows: Array = fa["rows"]
	for r in rows.size():
		FLOOR_ROWS[rows[r]] = r
		for v in int(fa["variants"]):
			src.create_tile(Vector2i(v, r))
	return ts


## 동굴 소품: cave.json의 그림·기준점·발자국. off는 그림만 옮김(벽을 칸 경계에 맞출 때)
func cprop(prop_name: String, cell: Vector2i, blocking := true, occlude := true, off := Vector2.ZERO) -> Sprite2D:
	var meta: Dictionary = cave()["props"][prop_name]
	var fp := Vector2(meta["footprint"][0], meta["footprint"][1])
	var s := Sprite2D.new()
	s.texture = AssetLibrary.texture("res://assets/env/cave/" + String(meta["file"]))
	s.centered = false
	s.offset = -Vector2(meta["anchor"][0], meta["anchor"][1])
	s.position = g(Vector2(cell) + fp * 0.5) + off
	world.add_child(s)
	if blocking:
		for x in int(fp.x):
			for y in int(fp.y):
				set_solid(cell + Vector2i(x, y))
	if occlude:
		occluders.append(s)
	return s


func _set_tex(s: Sprite2D, prop_name: String) -> void:
	var meta: Dictionary = cave()["props"][prop_name]
	s.texture = AssetLibrary.texture("res://assets/env/cave/" + String(meta["file"]))
	s.offset = -Vector2(meta["anchor"][0], meta["anchor"][1])


# ── 지형 ─────────────────────────────────────────────
func build() -> void:
	Lines.use("res://data/dialogue/ch3.json")
	chapter_title = Lines.t("meta.chapter_title")
	area_name = Lines.t("meta.area")
	death_text = Lines.t("meta.death")
	W = 30
	H = 30
	canvas_mod.color = Color(0.62, 0.55, 0.6)
	fill(Rect2i(0, 0, W, H), "cave_stone")
	fill(Rect2i(10, 0, 9, 4), "cave_dust")
	fill(Rect2i(1, 5, 8, 9), "cave_dust")
	fill(Rect2i(1, 20, 9, 9), "cave_straw")
	fill(Rect2i(20, 19, 6, 5), "cave_straw")
	# 동굴 밖: 입구 앞 바위 길만 걸을 수 있다
	for x in W:
		for y in 4:
			if x < 11 or x > 17:
				set_solid(Vector2i(x, y))
	for c in [Vector2i(10, 1), Vector2i(18, 0), Vector2i(10, 3)]:
		cprop("cover_rock", c, true, false)
	# 뒷벽(y 4, 입구 빼고)·왼쪽 벽(x 0)·앞쪽 끝(x 29, y 29)
	for x in W:
		if not x in ENTRANCE:
			set_solid(Vector2i(x, 4))
	for y in range(4, H):
		set_solid(Vector2i(0, y))
		set_solid(Vector2i(W - 1, y))
	for x in W:
		set_solid(Vector2i(x, H - 1))
	for x in [1, 3, 5, 7, 9, 11, 16, 18, 20, 22, 24, 26]:
		cprop("wall_nw_cracked" if x % 6 == 3 else "wall_nw", Vector2i(x, 4), false, false, Vector2(32, 16))
	for y in range(5, H - 1, 2):
		cprop("wall_ne_cracked" if y % 6 == 3 else "wall_ne", Vector2i(0, y), false, false, Vector2(16, 24))
	cprop("corner_inner", Vector2i(0, 4), false, false, Vector2(16, 24))
	for c in [Vector2i(29, 8), Vector2i(29, 15), Vector2i(29, 23), Vector2i(7, 29), Vector2i(15, 29), Vector2i(23, 29)]:
		cprop("stalagmites", c, false, true)
	# 창고: 치즈 선반·우유 항아리·포도주
	for c in [Vector2i(2, 5), Vector2i(4, 5), Vector2i(6, 5)]:
		cprop("cheese_rack", c)
	for c in [Vector2i(1, 7), Vector2i(1, 9), Vector2i(2, 13), Vector2i(4, 13), Vector2i(6, 12)]:
		cprop("milk_amphorae", c)
	for c in [Vector2i(1, 11), Vector2i(2, 11)]:
		cprop("wine_closed", c, true, false)
	# 엄폐 바위·석순
	for c in [Vector2i(8, 9), Vector2i(10, 13), Vector2i(12, 18), Vector2i(19, 10), Vector2i(21, 15), Vector2i(26, 16), Vector2i(17, 24), Vector2i(13, 23)]:
		cprop("cover_rock", c)
	for c in [Vector2i(8, 16), Vector2i(26, 12), Vector2i(11, 8)]:
		cprop("stalagmites", c)
	# 화덕(2×2)과 불
	var h := cprop("hearth_lit", HEARTH, true, false)
	add_embers(h, Vector2(0, -12), 0.8)
	hearth_light = add_light(h.global_position + Vector2(0, -14), Color(1.0, 0.55, 0.25), 1.35, 2.6)
	# 말뚝(2×1)·곤봉
	stake_sprite = cprop("stake_cold", STAKE, true, false)
	cprop("giant_club", Vector2i(26, 9), true, false)
	# 거인 침상(3×3)
	cprop("giant_bed", BED, true, false)
	# 양 우리: 위쪽 울타리(y 19, 문 x 5~6)·오른쪽 울타리(x 10)
	for x in range(1, 10):
		if x != GATE.x and x != GATE.x + 1:
			set_solid(Vector2i(x, 19))
	for x in [1, 3, 7]:
		cprop("fence_nw", Vector2i(x, 19), false, false, Vector2(32, 10))
	for y in range(19, H - 1):
		set_solid(Vector2i(10, y))
	for y in range(20, H - 1, 2):
		cprop("fence_ne", Vector2i(10, y), false, false, Vector2(16, 18))
	gate_sprite = cprop("pen_gate_closed", GATE, false, false, Vector2(16, 14))
	_set_gate(false)
	# 입구 바위: 처음엔 옆으로 굴려 둔 상태(거인이 돌아오며 닫는다)
	boulder = Sprite2D.new()
	boulder.centered = false
	world.add_child(boulder)
	_place_boulder(false)
	out_light = add_light(g(Vector2(14.5, 2.5)), Color(1.0, 0.62, 0.35), 1.2, 2.4, false)


func _set_gate(open: bool) -> void:
	gate_open = open
	_set_tex(gate_sprite, "pen_gate_open" if open else "pen_gate_closed")
	for x in [GATE.x, GATE.x + 1]:
		set_solid(Vector2i(x, 19), not open)


## closed: 입구를 막음(칸도 막힘) / 아니면 입구 오른쪽 바깥에 굴려 둠
func _place_boulder(closed: bool) -> void:
	_set_tex(boulder, "boulder_closed" if closed else "boulder_rolled")
	boulder.position = g(Vector2(14.5, 4.6)) if closed else g(Vector2(19.6, 2.2))
	for x in ENTRANCE:
		set_solid(Vector2i(x, 4), closed)
	if out_light:
		out_light.enabled = not closed


# ── 인물 ─────────────────────────────────────────────
func start() -> void:
	var carry := Game.carry_for(3)
	player = Player.new()
	player.position = g(START)
	world.add_child(player)
	_walk0 = player.walk_speed
	_run0 = player.run_speed
	if carry.has("food"):
		player.nutrition.load_state(carry["food"])
	var crew: Array = carry.get("crew", Lines.list("names.crew"))
	if crew.is_empty():
		crew = Lines.list("names.crew")
	for i in crew.size():
		var c := Companion.new()
		c.setup(crew[i][0], crew[i][1])
		c.position = player.position + Vector2(-20 + 20 * i, 14)
		world.add_child(c)
		squad.add_member(c)
	giant = Cyclops.new()
	giant.level = self
	giant.position = g(GIANT_OUT)
	for p in POSTS:
		giant.posts.append([g(p[0]), _gdir(p[1])])
	world.add_child(giant)
	giant.woke.connect(func(): Game.show_hint(Lines.t("hint.stirred")))
	# 양 떼(우리 안)와 큰 숫양
	for i in 6:
		var s := Animal.new().setup("sheep")
		s.position = g(PEN_C + Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5)))
		s.wander_radius = 40.0
		world.add_child(s)
		sheep.append(s)
	ram = Animal.new().setup("sheep")
	ram.cfg = ram.cfg.duplicate()
	ram.cfg["scare"] = 0.0
	ram.cfg["size"] = 2.2
	ram.position = g(PEN_C + Vector2(-1.5, 1.5))
	ram.wander_radius = 26.0
	ram.scale = Vector2(1.35, 1.35)
	ram.modulate = Color(0.95, 0.9, 0.8)
	world.add_child(ram)
	_make_points()
	Bgm.play("stealth", 2.0)
	Bgm.amb("sea", 0.5, 2.0)
	Bgm.amb("fire", 0.6, 2.0)
	_set_step(0)
	get_tree().create_timer(1.2).timeout.connect(func():
		if step == 0 and not _restored:
			Game.say(Lines.say("intro")))


func _point(label_id: String, at: Vector2, radius := 30.0, hold := 0.0, parent: Node2D = null) -> Interactable:
	var it := Interactable.new()
	it.label = Lines.t("label." + label_id)
	it.radius = radius
	it.hold_time = hold
	it.enabled = false
	if parent:
		parent.add_child(it)
	else:
		it.position = g(at)
		world.add_child(it)
	return it


func _make_points() -> void:
	look_point = _point("look", LOOK_AT, 40.0)
	look_point.on_use = func(_by): _look()
	wine_point = _point("wine", WINE_AT, 30.0, 0.6)
	wine_point.on_use = func(_by): _take("wine")
	give_point = _point("give", Vector2.ZERO, 72.0, 0.0, giant)
	give_point.on_use = func(_by): _give_wine()
	stake_point = _point("stake", Vector2(STAKE) + Vector2(1.0, 1.7), 34.0, 0.8)
	stake_point.on_use = func(_by): _take("stake")
	heat_point = _point("heat", Vector2(HEARTH) + Vector2(1.0, 2.6), 36.0, 2.5)
	heat_point.on_use = func(_by): _heat()
	stab_point = _point("stab", STAB_AT, 40.0, 1.2)
	stab_point.on_use = func(_by): _stab()
	gate_point = _point("gate", GATE_AT, 32.0, 1.0)
	gate_point.on_use = func(_by): _open_gate()
	ram_point = _point("ram", Vector2.ZERO, 30.0, 0.8, ram)
	ram_point.on_use = func(_by): _ride()


func _gdir(gv: Vector2) -> Vector2:
	return (g(gv) - g(Vector2.ZERO)).normalized()


func holding_wine() -> bool:
	return carrying == "wine"


## 들기: 포도주(빠르기 그대로) / 말뚝(느리고 뛸 수 없음 — 달리기 속도를 걷기와 같게)
func _take(what: String) -> void:
	carrying = what
	if _carry_spr:
		_carry_spr.queue_free()
	_carry_spr = Sprite2D.new()
	var tex := "wine_closed" if what == "wine" else ("stake_hot" if what == "hot" else "stake_cold")
	var meta: Dictionary = cave()["props"][tex]
	_carry_spr.texture = AssetLibrary.texture("res://assets/env/cave/" + String(meta["file"]))
	if what == "wine":
		_carry_spr.position = Vector2(0, -60)
		_carry_spr.scale = Vector2(0.8, 0.8)
		wine_point.enabled = false
		Sfx.play("switch", -6.0)
	else:
		_carry_spr.position = Vector2(0, -24)
		_carry_spr.scale = Vector2(0.55, 0.55)
		player.walk_speed = CARRY_SPEED
		player.run_speed = CARRY_SPEED
		if what == "stake":
			stake_point.enabled = false
			stake_sprite.visible = false
			for c in [STAKE, STAKE + Vector2i(1, 0)]:
				set_solid(c, false)
			Sfx.play("winch", -8.0)
	player.add_child(_carry_spr)
	_refresh_marker()


func _drop() -> void:
	carrying = ""
	if _carry_spr:
		_carry_spr.queue_free()
		_carry_spr = null
	player.walk_speed = _walk0
	player.run_speed = _run0


# ── 사건 ─────────────────────────────────────────────
func _look() -> void:
	look_point.enabled = false
	Game.quest_marker = Vector2.INF
	Game.say(Lines.say("look"), _arrival)


## 거인이 돌아와 입구를 막는다(연출)
func _arrival() -> void:
	Game.cutscene = true
	player.script_goal = g(HIDE)
	for i in squad.members.size():
		squad.members[i].global_position = g(HIDE + Vector2(-1.0 + i * 0.9, 1.2))
	Game.shake(5.0)
	Sfx.play("thunder", -4.0)
	camera_target = giant
	giant.global_position = g(GIANT_OUT)
	giant.walk_to(g(GIANT_IN), _close_boulder)


func _close_boulder() -> void:
	giant.face(_gdir(Vector2(0, -1)))
	var tw := create_tween()
	_set_tex(boulder, "boulder_closed")
	tw.tween_property(boulder, "position", g(Vector2(14.5, 4.6)), 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		_place_boulder(true)
		Sfx.play("stone", 0.0)
		Sfx.play("hit_heavy", -2.0)
		Game.shake(9.0)
		canvas_mod.color = Color(0.36, 0.31, 0.38))
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		giant.face(_gdir(Vector2(0, 1)))
		Game.say(Lines.say("arrival"), _arrival_done))


func _arrival_done() -> void:
	camera_target = null
	Game.cutscene = false
	player.script_goal = Vector2.INF
	giant.post_i = 0
	giant.walk_to(giant.posts[0][0], giant.watch)
	_set_step(1)


func _give_wine() -> void:
	if carrying != "wine":
		return
	give_point.enabled = false
	_drop()
	giant.face(player.global_position - giant.global_position)
	giant.mode = Cyclops.Mode.WAIT_WINE
	Sfx.play("eat", -4.0)
	Game.say(Lines.say("give"), func():
		Game.quest_marker = Vector2.INF
		giant.walk_to(g(BED_SIDE), _giant_asleep, Cyclops.DRUNK_SPEED, Cyclops.Mode.DRUNK))


func _giant_asleep(quiet := false) -> void:
	giant.sleep_on(g(Vector2(BED) + Vector2(1.5, 1.5)) + Vector2(66, -16))
	if not quiet:
		Game.say(Lines.say("sleep"))
	_set_step(2)


func _heat() -> void:
	if carrying != "stake":
		return
	Sfx.play("fire_burst", -4.0)
	Fx.spark(player.global_position + Vector2(0, -20), Color(1, 0.6, 0.2), 10)
	_take("hot")
	Game.say(Lines.say("hot"))


func _stab() -> void:
	if carrying != "hot" or giant.mode != Cyclops.Mode.SLEEP:
		return
	stab_point.enabled = false
	_drop()
	Game.cutscene = true
	Game.quest_marker = Vector2.INF
	Sfx.play("cry", 0.0)
	Sfx.play("fire_burst", 0.0)
	Game.shake(14.0)
	Game.hitstop(0.25)
	Fx.spark(giant.eye_pos(), Color(1, 0.5, 0.2), 18)
	Fx.ring(giant.eye_pos(), 40.0, Color(1, 0.3, 0.2), 0.6)
	var tw := create_tween()
	tw.tween_property(giant.body, "modulate", Color(1.6, 0.5, 0.4), 0.15)
	tw.tween_property(giant.body, "modulate", Color(1, 1, 1), 0.6)
	Game.say(Lines.say("stab"), _blinded)


## 눈 먼 거인: 일어나 더듬어 입구로 가서 바위를 치우고 앉는다
func _blinded() -> void:
	Game.cutscene = false
	giant.blind()
	giant.global_position = g(BED_SIDE)
	giant.walk_to(g(GUARD_AT), _guard_entrance, Cyclops.DRUNK_SPEED, Cyclops.Mode.BLIND)
	_set_step(3)


func _guard_entrance() -> void:
	var tw := create_tween()
	_set_tex(boulder, "boulder_rolled")
	tw.tween_property(boulder, "position", g(Vector2(19.6, 2.2)), 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		_place_boulder(false)
		Sfx.play("stone", 0.0)
		Game.shake(6.0)
		giant.guard_at(g(GUARD_AT), _gdir(Vector2(-1, 0.2)))
		if not _restored:
			Game.say(Lines.say("blind_guard")))


func _open_gate() -> void:
	gate_point.enabled = false
	_set_gate(true)
	Sfx.play("gate", -4.0)
	ram_point.enabled = true
	_refresh_marker()


## 숫양 배 밑에 매달려 나간다(연출): 양 떼가 앞서 나가고, 거인이 등을 더듬는다
func _ride() -> void:
	if _riding:
		return
	_riding = true
	ram_point.enabled = false
	Game.cutscene = true
	Game.quest_marker = Vector2.INF
	player.visible = false
	player._shape.set_deferred("disabled", true)
	for c in squad.members:
		_hide_member(c, true)
	ram.set_process(false)
	_ride_path = find_path(ram.global_position, g(EXIT_AT))
	camera_target = ram
	# 다른 양들도 차례로 나간다
	_flock.clear()
	for i in sheep.size():
		var s: Animal = sheep[i]
		if not is_instance_valid(s):
			continue
		s.set_process(false)
		_flock.append([s, find_path(s.global_position, g(EXIT_AT + Vector2(randf_range(-1.5, 1.5), -0.2))), 0.6 + i * 0.7])


func _hide_member(c: Companion, hide: bool) -> void:
	c.visible = not hide
	c.process_mode = Node.PROCESS_MODE_DISABLED if hide else Node.PROCESS_MODE_INHERIT
	c._shape.set_deferred("disabled", hide)
	if hide:
		c.remove_from_group("actors")
	elif not c.is_in_group("actors"):
		c.add_to_group("actors")


func _walk_animal(a: Animal, path: PackedVector2Array, speed: float, delta: float) -> bool:
	if path.is_empty():
		return true
	var next := path[0]
	var to := next - a.global_position
	if to.length() < 3.0:
		path.remove_at(0)
		return path.is_empty()
	var v := to.normalized() * speed
	a.global_position += v * delta
	if a.body:
		var key := "walk_%d" % (1 if v.y < -1.0 else 0)
		if a.body.animation != key:
			a.body.play(key)
		a.body.flip_h = v.x < 0.0
	return false


func _update_ride(delta: float) -> void:
	for f in _flock:
		f[2] -= delta
		if f[2] <= 0.0 and is_instance_valid(f[0]):
			if _walk_animal(f[0], f[1], RIDE_SPEED * 1.1, delta):
				f[0].visible = false
	if not _ride_said and ram.global_position.distance_to(giant.global_position) < 90.0:
		_ride_said = true
		giant.face(ram.global_position - giant.global_position)
		Game.say(Lines.say("ride"))
		return
	player.global_position = ram.global_position
	if _walk_animal(ram, _ride_path, RIDE_SPEED, delta):
		_escaped()


func _escaped() -> void:
	_riding = false
	step = 5
	camera_target = null
	player.visible = true
	player.global_position = g(EXIT_AT + Vector2(-1.2, 0.6))
	player._shape.set_deferred("disabled", false)
	for i in squad.members.size():
		var c: Companion = squad.members[i]
		_hide_member(c, false)
		c.global_position = g(EXIT_AT + Vector2(-0.5 + i * 0.8, 1.0))
	Game.set_objective(chapter_title, Lines.t("objective.done"))
	if Game.hud:
		Game.hud.show_title(Lines.list("title.clear"))
	Bgm.sting("victory")
	Game.say(Lines.say("ending"), func():
		Game.shake(10.0)
		Sfx.play("stone", 0.0)
		Game.cutscene = false
		_end_chapter())


func _end_chapter() -> void:
	if ending_done:
		return
	ending_done = true
	Game.mark_cleared(3)
	Game.set_carry(4, {"food": player.nutrition.state(), "crew": squad.members.map(func(c): return [c.role, c.display_name])})
	Game.chapter_cleared.emit(Game.stats.duplicate())


# ── 단계 ──────────────────────────────────────────────
func _set_step(s: int) -> void:
	step = s
	match s:
		0:
			look_point.enabled = true
			Game.set_objective(chapter_title, Lines.t("objective.look"))
		1:
			_save_checkpoint("cave")
			wine_point.enabled = true
			if Game.hud:
				Game.hud.show_title(Lines.list("title.cave"))
			_tut(Lines.t("tut.sight"), func(): return carrying == "wine", 16.0)
		2:
			_save_checkpoint("sleep")
			stake_point.enabled = true
			_tut(Lines.t("tut.carry"), func(): return carrying == "hot", 20.0)
		3:
			_save_checkpoint("blind")
			gate_point.enabled = not gate_open
			ram_point.enabled = gate_open
			if Game.hud and not _restored:
				Game.hud.show_title(Lines.list("title.blind"))
			_tut(Lines.t("tut.hide"), func(): return gate_open, 16.0)
	_refresh_marker()


## 목표 표시·목표 글: 지금 들고 있는 것에 따라
func _refresh_marker() -> void:
	var at := Vector2.INF
	var obj := ""
	match step:
		0:
			at = look_point.global_position
			obj = "look"
		1:
			if carrying == "wine":
				at = giant.global_position
				obj = "give"
			else:
				at = wine_point.global_position
				obj = "wine"
		2:
			match carrying:
				"stake":
					at = heat_point.global_position
					obj = "heat"
				"hot":
					at = stab_point.global_position
					obj = "stab"
				_:
					at = stake_point.global_position
					obj = "stake"
		3:
			at = ram.global_position if gate_open else gate_point.global_position
			obj = "ram" if gate_open else "gate"
	if obj != "":
		Game.set_objective(chapter_title, Lines.t("objective." + obj))
	if not Game.cutscene:
		Game.quest_marker = at


# ── 체크포인트 ──────────────────────────────────────
func _save_checkpoint(id: String) -> void:
	if _restored and Game.checkpoint.get("id", "") == id:
		return
	Game.checkpoint = {"chapter": 3, "id": id, "stats": Game.stats.duplicate(), "food": player.nutrition.state(),
		"crew": squad.members.map(func(c): return [c.role, c.display_name])}
	Game.save_progress()
	Sfx.play("checkpoint", -8.0)
	Fx.text(player.global_position + Vector2(0, -64), Lines.t("fx.checkpoint"), Color(0.55, 0.85, 1.0))
	Fx.icon(player.global_position + Vector2(0, -78), "checkpoint", "", Color.WHITE)


func checkpoint_name(id: String) -> String:
	return {"cave": "동굴에 갇힘", "sleep": "거인이 잠듦", "blind": "외눈을 찌름"}.get(id, id)


func restore_checkpoint(cp: Dictionary) -> void:
	player.nutrition.load_state(cp.get("food", {}))
	var keep: Array = cp.get("crew", []).map(func(m): return m[1])
	for c in squad.members.duplicate():
		if not c.display_name in keep:
			squad.members.erase(c)
			c.queue_free()
	for i in squad.members.size():
		squad.members[i].squad_index = i
	_restored = true
	skip_to(String(cp["id"]))
	if Game.hud:
		Game.hud.clear_story()
	Game.show_hint(Lines.t("hint.checkpoint"))


## 검증용 --start=cave|sleep|blind|ending
func skip_to(id: String) -> void:
	_tut_clear()
	match id:
		"cave":
			if step >= 1:
				return
			look_point.enabled = false
			_place_boulder(true)
			canvas_mod.color = Color(0.36, 0.31, 0.38)
			player.global_position = g(HIDE)
			for i in squad.members.size():
				squad.members[i].global_position = g(HIDE + Vector2(-1.0 + i * 0.9, 1.2))
			giant.global_position = giant.posts[0][0]
			giant.post_i = 0
			giant.watch()
			_set_step(1)
		"sleep":
			skip_to("cave")
			wine_point.enabled = false
			player.global_position = g(STAB_AT + Vector2(-2.0, -1.5))
			_giant_asleep(true)
		"blind":
			skip_to("sleep")
			stake_point.enabled = false
			stake_sprite.visible = false
			for c in [STAKE, STAKE + Vector2i(1, 0)]:
				set_solid(c, false)
			player.global_position = g(STAB_AT + Vector2(-1.5, 0.5))
			giant.blind()
			_place_boulder(false)
			giant.guard_at(g(GUARD_AT), _gdir(Vector2(-1, 0.2)))
			_set_step(3)
		"ending":
			skip_to("blind")
			_open_gate()
			player.global_position = ram.global_position
			_ride()


func report() -> Dictionary:
	return {"ending": ending_done, "step": step, "carrying": carrying, "gate_open": gate_open,
		"giant": Cyclops.Mode.keys()[giant.mode], "giant_cell": Iso.world_to_grid(giant.global_position).snapped(Vector2(0.1, 0.1)),
		"crew": squad.members.size(), "downs": Game.stats.get("downs", 0)}


func result_info(st: Dictionary) -> Dictionary:
	var t: float = st.get("time", 0.0)
	var seen: int = st.get("giant_seen", 0)
	var badge := ""
	if seen == 0:
		badge = "칭호 「아무도 아닌 자」 — 거인에게 한 번도 들키지 않고 빠져나옴"
	return {"head": "CHAPTER 3 클리어", "title": "폴리페모스의 동굴을 빠져나왔다", "badge": badge,
		"badge_hint": "거인에게 한 번도 들키지 않고 빠져나오면 칭호를 얻는다",
		"rows": [
			"시간 %d분 %02d초   ·   거인에게 들킴 %d   ·   다시 하기 %d" % [int(t) / 60, int(t) % 60, seen, st.get("retries", 0)],
			"함께 나온 부하 %d   ·   먹은 횟수 %d" % [squad.members.size(), st.get("meals", 0)],
		],
		"next": "다음: CHAPTER 4 — 키르케의 섬 (준비 중). 포세이돈이 바다를 거칠게 할 것이다"}


# ── 매 프레임 ─────────────────────────────────────────
func _process(delta: float) -> void:
	super._process(delta)
	_update_tut(delta)
	if _riding:
		_update_ride(delta)
		return
	if step >= 5 or player == null:
		return
	_sword_cd -= delta
	# 칼로 거인을 치면: 튕겨 나온다(정면으로는 못 이김)
	if _sword_cd <= 0.0 and player.state == Actor.St.ATTACK and giant.visible \
			and Combat.ground_dist(player.global_position, giant.global_position) < 60.0:
		_sword_cd = 5.0
		Fx.spark(giant.global_position + Vector2(0, -40), Color(1, 0.9, 0.6), 6)
		Sfx.at("block", giant.global_position, -4.0)
		Game.show_hint(Lines.t("hint.no_sword"))
	if giant.mode == Cyclops.Mode.CHASE and giant.suspicion >= 1.0 and not _chasing:
		_chasing = true
		Game.stats["giant_seen"] = Game.stats.get("giant_seen", 0) + 1
	elif giant.mode != Cyclops.Mode.CHASE and giant.mode != Cyclops.Mode.ATTACK:
		_chasing = false
	match step:
		1:
			give_point.enabled = carrying == "wine" and giant.mode in [Cyclops.Mode.WATCH, Cyclops.Mode.WALK, Cyclops.Mode.WAIT_WINE, Cyclops.Mode.CHASE]
			if carrying == "wine":
				_refresh_marker()
		2:
			heat_point.enabled = carrying == "stake"
			stab_point.enabled = carrying == "hot"
		3:
			if gate_open and not Game.cutscene:
				Game.quest_marker = ram.global_position
			# 맨몸으로 입구에 다가가면: 거인 손이 막는다
			if giant.mode == Cyclops.Mode.ATTACK and Combat.ground_dist(player.global_position, g(EXIT_AT + Vector2(0, 4))) < 70.0 and _grab_hint <= 0.0:
				_grab_hint = 8.0
				Game.show_hint(Lines.t("hint.grabbed"))
			_grab_hint -= delta


var _chasing := false
var _grab_hint := 0.0


## 거인 시야 부채꼴과 공격 예고를 바닥에 그린다
func _draw_sight() -> void:
	super._draw_sight()
	if giant == null or not giant.visible:
		return
	giant.draw_warning(sight_layer)
	if not giant.watching() and giant.mode != Cyclops.Mode.CHASE:
		return
	var o: Vector2 = giant.global_position
	var col := Color(1.0, 0.92, 0.65).lerp(Color(1.0, 0.25, 0.15), giant.suspicion)
	var far := PackedVector2Array([o])
	var n := 12
	for i in n + 1:
		var a: float = giant.facing.angle() + deg_to_rad(Cyclops.ARC * (float(i) / n - 0.5))
		var dv := Vector2(cos(a), sin(a))
		var k := 1.0 / Vector2(dv.x, dv.y * Combat.Y_STRETCH).length()
		far.append(o + dv * ray_len(o, dv, Cyclops.SIGHT * k))
	sight_layer.draw_colored_polygon(far, Color(col, 0.1 + 0.12 * giant.suspicion))
	far.append(o)
	sight_layer.draw_polyline(far, Color(col, 0.4 + 0.3 * giant.suspicion), 1.0)


# ── 튜토리얼 카드(챕터 2와 같은 방식) ──────────────────
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
