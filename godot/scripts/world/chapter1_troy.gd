class_name Chapter1Troy
extends IsoLevel
## CHAPTER 1 — 트로이의 목마.
## 밤, 불타는 트로이. 목마에서 내린 오디세우스와 부하 셋이 대로를 따라 북쪽 성문으로 가서
## 순찰대 → 성문 경비대(수비대장) 처치 → 권양기로 성문 개방 → 아카이아 증원군과 성문 거점 사수.
##
## 격자: x는 화면 오른쪽 아래, y는 왼쪽 아래로 늘어난다. 바깥 성벽은 y=3 줄과 x=2 열(화면 위쪽 두 변).

const GATE_CELLS := [Vector2i(17, 3), Vector2i(18, 3)]
const ZONE_CELL := Vector2(18.0, 6.5)
const ZONE_RADIUS := 56.0

var step := -1
var gate_sprites: Array = []
var winch_point: Interactable
var sinon: Npc
var patrol_group: Array = []
var guard_group: Array = []
var capture := 0.0
var waves_sent := 0
var zone_pos := Vector2.ZERO
var _done := false


func build() -> void:
	chapter_title = "CHAPTER 1 — 트로이의 목마"
	W = 36
	H = 36
	canvas_mod.color = Color(0.5, 0.5, 0.74)
	# 바닥
	fill(Rect2i(0, 0, 36, 3), "grass")
	fill(Rect2i(0, 0, 2, 36), "grass")
	fill(Rect2i(16, 0, 4, 3), "road")
	fill(Rect2i(12, 4, 13, 6), "plaza")
	fill(Rect2i(16, 10, 6, 11), "road")
	fill(Rect2i(19, 21, 13, 12), "plaza")
	fill(Rect2i(3, 13, 3, 20), "dirt")
	fill(Rect2i(26, 18, 9, 3), "dirt")
	fill(Rect2i(11, 28, 3, 6), "ash")
	fill(Rect2i(7, 18, 4, 3), "ash")
	fill(Rect2i(29, 9, 4, 2), "ash")
	# 성벽·탑·성문
	for x in range(2, 36):
		var c := Vector2i(x, 3)
		if c in GATE_CELLS:
			continue
		add_prop("tower" if x in [2, 8, 16, 19, 26, 33] else "wall", c, true, false)
	for y in range(4, 36):
		add_prop("tower" if y in [10, 18, 26, 34] else "wall", Vector2i(2, y), true, false)
	for c in GATE_CELLS:
		gate_sprites.append(add_prop("gate_closed", c, true, false))
	# 맵 끝(오른쪽 아래 두 변)은 집으로 막는다
	for i in range(3, 36):
		set_solid(Vector2i(35, i))
		set_solid(Vector2i(i, 35))
	# 집 (이름, 칸, 불탐)
	var houses := [
		["house_c", Vector2i(13, 11), false], ["house_a", Vector2i(13, 15), true], ["house_d", Vector2i(13, 18), false],
		["house_b", Vector2i(22, 11), false], ["house_a", Vector2i(23, 14), false], ["house_c", Vector2i(22, 17), true],
		["house_b", Vector2i(4, 6), false], ["house_a", Vector2i(9, 6), true], ["house_c", Vector2i(4, 10), false],
		["house_d", Vector2i(8, 11), false], ["house_a", Vector2i(4, 16), false], ["house_b", Vector2i(8, 16), true],
		["house_c", Vector2i(4, 21), false], ["house_a", Vector2i(9, 21), false], ["house_d", Vector2i(5, 27), true],
		["house_b", Vector2i(9, 27), false], ["house_a", Vector2i(14, 24), false], ["house_c", Vector2i(14, 29), true],
		["house_c", Vector2i(27, 6), false], ["house_a", Vector2i(31, 6), false], ["house_b", Vector2i(27, 11), true],
		["house_d", Vector2i(31, 11), false], ["house_a", Vector2i(28, 15), false], ["house_c", Vector2i(32, 15), false],
		["house_b", Vector2i(32, 22), true], ["house_a", Vector2i(32, 27), false], ["house_d", Vector2i(32, 31), false],
		["house_b", Vector2i(20, 33), false], ["house_a", Vector2i(25, 33), true], ["house_d", Vector2i(28, 33), false],
	]
	for h in houses:
		if h[2]:
			add_burning_house(h[0], h[1])
		else:
			add_prop(h[0], h[1])
	add_prop("horse", Vector2i(23, 26))
	for c in [Vector2i(20, 22), Vector2i(30, 22), Vector2i(20, 31), Vector2i(30, 31)]:
		add_prop("column", c)
	# 소품
	for c in [Vector2i(16, 12), Vector2i(21, 12), Vector2i(16, 17), Vector2i(21, 17), Vector2i(12, 8), Vector2i(23, 8)]:
		# 횃불대 그림에 불이 그려져 있으니 빛만 더한다
		var t := add_prop("torch_post", c, true, false)
		add_light(t.global_position + Vector2(1, -20), Color(1.0, 0.55, 0.25), 0.6, 0.85)
	for c in [Vector2i(15, 4), Vector2i(21, 4)]:
		var b := add_prop("brazier", c, true, false)
		add_fire(b, Vector2(0, -16), 0.8)
	for c in [Vector2i(13, 4), Vector2i(23, 4), Vector2i(16, 21), Vector2i(21, 21)]:
		add_prop("banner_troy", c, true, false)
	for c in [Vector2i(11, 9), Vector2i(10, 14), Vector2i(26, 19), Vector2i(25, 9), Vector2i(7, 25), Vector2i(31, 19), Vector2i(17, 31)]:
		add_prop("crate" if hash(c) % 2 == 0 else "barrel", c, true, false)
	for c in [Vector2i(12, 26), Vector2i(7, 20), Vector2i(29, 10), Vector2i(19, 9)]:
		add_prop("rubble", c, true, false)
	add_prop("cart", Vector2i(11, 23))
	add_prop("winch", Vector2i(20, 5))
	add_light(Iso.grid_to_world(Vector2(25, 27)), Color(0.55, 0.65, 1.0), 0.5, 2.5, false)


func start() -> void:
	zone_pos = Iso.grid_to_world(ZONE_CELL)
	player = Player.new()
	player.position = Iso.grid_to_world(Vector2(25.5, 29.0))
	world.add_child(player)
	player.face(Vector2(-1, -1))
	var crew := [["sword", "에우릴로코스"], ["spear", "폴리테스"], ["archer", "엘페노르"]]
	for i in crew.size():
		var c := Companion.new()
		c.setup(crew[i][0], crew[i][1])
		c.position = player.position + Vector2(-20 + i * 20, 18)
		world.add_child(c)
		squad.add_member(c)
	sinon = Npc.new()
	sinon.setup("greek_archer", "시논", _talk_sinon)
	sinon.position = Iso.grid_to_world(Vector2(22.5, 29.5))
	world.add_child(sinon)
	patrol_group = [
		_spawn("trojan_sword", Vector2(18.5, 16.5), [Vector2(18.5, 16.5), Vector2(19.5, 12.5)]),
		_spawn("trojan_spear", Vector2(20.0, 15.0), [Vector2(20.0, 15.0), Vector2(20.5, 19.0)]),
		_spawn("trojan_sword", Vector2(19.5, 18.0)),
	]
	_spawn("trojan_archer", Vector2(7.5, 14.5))
	_spawn("trojan_sword", Vector2(9.0, 14.0), [Vector2(9.0, 14.0), Vector2(6.5, 19.5)])
	_spawn("trojan_spear", Vector2(6.5, 9.0))
	guard_group = [
		_spawn("trojan_sword", Vector2(15.5, 6.5)),
		_spawn("trojan_sword", Vector2(20.5, 7.0)),
		_spawn("trojan_spear", Vector2(16.5, 8.5)),
		_spawn("trojan_spear", Vector2(19.5, 8.5)),
		_spawn("trojan_archer", Vector2(23.5, 6.0)),
		_spawn("trojan_captain", Vector2(18.0, 5.2)),
	]
	for g in guard_group:
		g.aggro_range = 110.0
	winch_point = Interactable.new()
	winch_point.label = "권양기 돌리기"
	winch_point.hold_time = 2.0
	winch_point.radius = 30.0
	winch_point.enabled = false
	winch_point.position = Iso.grid_to_world(Vector2(20.5, 5.5)) + Vector2(0, 10)
	winch_point.on_use = func(_by): _open_gate()
	world.add_child(winch_point)
	_set_step(0)


func _spawn(kind: String, g: Vector2, route := []) -> Enemy:
	var e := Enemy.new()
	e.setup(kind)
	e.position = Iso.grid_to_world(g)
	for r in route:
		e.patrol.append(Iso.grid_to_world(r))
	world.add_child(e)
	return e


# ── 퀘스트 ────────────────────────────────────────────
func _set_step(s: int) -> void:
	step = s
	match s:
		0:
			Game.set_objective(chapter_title, "목마 옆의 첩자 시논에게 말을 걸어라  [E]")
			Game.quest_marker = sinon.global_position
		1:
			Game.set_objective(chapter_title, "대로의 트로이 순찰대를 처치하라  (0/3)")
			Game.quest_marker = Iso.grid_to_world(Vector2(19, 17))
			Game.show_hint("좌클릭 검 3연타 · F 강공격 · 우클릭 방패(막는 순간 패링) · Space 구르기 · Shift 달리기")
		2:
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (0/6)")
			Game.quest_marker = Iso.grid_to_world(Vector2(18, 7))
			Game.show_hint("부대 명령  1 따라오기 · 2 위치 사수 · 3 집중 공격(마우스 근처 적) · 4 후퇴·집결   R 전투의 함성 · Q 활")
		3:
			Game.set_objective(chapter_title, "권양기를 돌려 성문을 열어라  [E 길게]")
			winch_point.enabled = true
			Game.quest_marker = winch_point.global_position
			Game.boss_changed.emit(null)
		4:
			Game.set_objective(chapter_title, "성문 거점을 사수하라  (0%)")
			Game.quest_marker = zone_pos
			Game.show_hint("붉은 원 안에 머물러라. 적이 원 안에 있으면 점령이 멈춘다.")


func _talk_sinon(_by) -> void:
	if step != 0:
		Game.say([["시논", "북쪽 대로 끝이 성문입니다. 서두르십시오!"]])
		return
	sinon.talk.enabled = false
	Game.say([
		["시논", "오디세우스 님! 트로이 놈들은 목마를 신의 선물이라 믿고 밤새 잔치를 벌였습니다."],
		["오디세우스", "아테나 여신의 지혜가 통했군. 부하들은 모두 내려왔나?"],
		["에우릴로코스", "예, 장군. 칼을 뽑을 준비가 됐습니다."],
		["시논", "북쪽 대로를 따라가면 성문입니다. 권양기를 돌리면 해안의 아카이아 군이 밀려들 겁니다."],
		["오디세우스", "가자. 소리 없이, 빠르게."],
	], func(): _set_step(1))


func _process(delta: float) -> void:
	super._process(delta)
	if _done:
		return
	match step:
		1:
			var n := _dead_count(patrol_group)
			Game.set_objective(chapter_title, "대로의 트로이 순찰대를 처치하라  (%d/3)" % n)
			if n >= 3:
				_set_step(2)
		2:
			var n := _dead_count(guard_group)
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (%d/6)" % n)
			if n >= guard_group.size():
				_set_step(3)
		4:
			_update_capture(delta)
	queue_redraw()


func _dead_count(group: Array) -> int:
	var n := 0
	for e in group:
		if not is_instance_valid(e) or not e.is_alive():
			n += 1
	return n


func _open_gate() -> void:
	winch_point.enabled = false
	Sfx.play("gate", -2.0)
	Game.shake(6.0)
	for i in GATE_CELLS.size():
		set_solid(GATE_CELLS[i], false)
		var s: Sprite2D = gate_sprites[i]
		var meta: Dictionary = AssetLibrary.prop("gate_open")
		s.texture = AssetLibrary.prop_texture("gate_open")
		s.offset = -Vector2(meta["anchor"][0], meta["anchor"][1])
	var allies := [["sword", "아카이아 검병"], ["spear", "아카이아 창병"], ["sword", "아카이아 검병"], ["spear", "아카이아 창병"]]
	for i in allies.size():
		var c := Companion.new()
		c.setup(allies[i][0], allies[i][1])
		c.independent = true
		c.position = Iso.grid_to_world(Vector2(17.2 + (i % 2) * 1.2, 0.6 + (i / 2) * 1.0))
		world.add_child(c)
		c.hold_anchor = zone_pos + Vector2(-30 + i * 20, 10 + (i % 2) * 8)
	Game.say([
		["아카이아 병사", "성문이 열렸다! 이타카의 왕이 길을 열었다!"],
		["오디세우스", "트로이의 반격이 올 것이다. 성문을 지켜라!"],
	], func(): _set_step(4))


func _update_capture(delta: float) -> void:
	var p_in := player.is_alive() and Combat.ground_dist(player.global_position, zone_pos) < ZONE_RADIUS
	var contested := false
	for e in enemies():
		if Combat.ground_dist(e.global_position, zone_pos) < ZONE_RADIUS:
			contested = true
			break
	if p_in and not contested:
		capture = min(100.0, capture + delta * 1.9)
	var wave_at := [0.0, 30.0, 62.0]
	if waves_sent < wave_at.size() and capture >= wave_at[waves_sent]:
		_send_wave(waves_sent)
		waves_sent += 1
	var status := "" if p_in else "  — 원 안으로 들어가라"
	if contested:
		status = "  — 적이 거점에 있다!"
	Game.set_objective(chapter_title, "성문 거점을 사수하라  (%d%%)%s" % [int(capture), status])
	if capture >= 100.0:
		_finish()


func _send_wave(i: int) -> void:
	var waves := [
		[["trojan_sword", Vector2(18.5, 20.0)], ["trojan_spear", Vector2(19.5, 20.5)], ["trojan_sword", Vector2(17.5, 19.5)]],
		[["trojan_sword", Vector2(8.0, 9.0)], ["trojan_archer", Vector2(7.0, 8.5)], ["trojan_spear", Vector2(18.5, 20.0)], ["trojan_sword", Vector2(19.5, 20.0)]],
		[["trojan_sword", Vector2(18.0, 20.0)], ["trojan_spear", Vector2(19.0, 20.5)], ["trojan_archer", Vector2(20.0, 20.0)], ["trojan_sword", Vector2(26.5, 9.5)], ["trojan_spear", Vector2(26.5, 10.5)]],
	]
	Game.show_hint("트로이군의 반격이다! (%d/3)" % (i + 1))
	for w in waves[i]:
		var e := _spawn(w[0], w[1])
		e.alert(player)


func _finish() -> void:
	_done = true
	Game.quest_marker = Vector2.INF
	for c in squad.members:
		c.revive(0.6)
	Game.set_objective(chapter_title, "성문 점령 완료")
	Game.say([
		["오디세우스", "트로이의 성문은 우리 것이다. 십 년의 전쟁이 오늘 밤 끝난다."],
		["에우릴로코스", "장군, 이제… 이타카로 돌아가는 겁니까?"],
		["오디세우스", "그래. 배를 준비해라. 고향이 기다린다."],
	], func(): Game.chapter_cleared.emit(Game.stats.duplicate()))


func _draw() -> void:
	if step != 4 or _done:
		return
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		pts.append(zone_pos + Vector2(cos(a) * ZONE_RADIUS, sin(a) * ZONE_RADIUS / Combat.Y_STRETCH))
	var c := Color(1, 0.3, 0.2, 0.75)
	draw_polyline(pts, c, 1.5)
	var fill_pts := PackedVector2Array()
	var k := capture / 100.0
	for i in 41:
		var a := TAU * i / 40.0
		fill_pts.append(zone_pos + Vector2(cos(a) * ZONE_RADIUS * k, sin(a) * ZONE_RADIUS * k / Combat.Y_STRETCH))
	if k > 0.02:
		draw_colored_polygon(fill_pts, Color(0.4, 0.6, 1.0, 0.18))
