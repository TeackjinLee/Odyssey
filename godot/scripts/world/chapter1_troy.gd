class_name Chapter1Troy
extends IsoLevel
## CHAPTER 1 — 트로이의 목마.
## 밤, 불타는 트로이. 오디세우스가 혼자 목마에서 내려(부하는 목마 안에 대기) 세 갈래 길 —
## 횃불이 늘어선 대로, 어두운 서쪽 뒷골목, 짐더미가 쌓인 동쪽 시장 — 중 하나로 성문 앞 북쪽 가로까지 몰래 간다.
## 가로 끝의 꺼진 횃불에 불을 붙여 시논에게 신호를 보내면 부하들이 합류하고,
## 성문 경비대(수비대장) 처치 → 권양기로 성문 개방 → 아카이아 증원군과 성문 거점 사수.
## 들키면 경보병이 갈래마다 하나 있는 경보 종으로 달려가고, 종이 울리면 성문 경비가 2명씩 는다.
##
## 격자: x는 화면 오른쪽 아래, y는 왼쪽 아래로 늘어난다. 바깥 성벽은 y=3 줄과 x=2 열(화면 위쪽 두 변).
## 위(북)부터: 성문 광장 y4~9 · 북쪽 가로 y10~12 · 세 갈래 y13~37(뒷골목 x3~6, 대로 x16~20, 시장 x27~33,
## 가운데 가로 y22~25로 서로 이어짐) · 목마 광장 y38~48.

const GATE_CELLS := [Vector2i(17, 3), Vector2i(18, 3)]
const ZONE_CELL := Vector2(18.0, 6.5)
const ZONE_RADIUS := 56.0
## 신호 횃불 자리: 갈래마다 하나 (뒷골목 · 대로 · 시장 끝)
const SIGNAL_CELLS := [Vector2i(4, 12), Vector2i(15, 12), Vector2i(33, 11)]
## 경보 종이 울릴 때마다 성문 경비대에 붙는 병사
const ALARM_GUARDS := [["trojan_sword", Vector2(17.5, 7.5)], ["trojan_spear", Vector2(18.5, 8.0)]]

var step := -1
var gate_sprites: Array = []
var winch_point: Interactable
var sinon: Npc
var stealth_group: Array = []
var guard_group: Array = []
var signals: Array = []
var capture := 0.0
var waves_sent := 0
var zone_pos := Vector2.ZERO
var _done := false
var _combat_hint := false


func build() -> void:
	chapter_title = "CHAPTER 1 — 트로이의 목마"
	W = 36
	H = 50
	canvas_mod.color = Color(0.5, 0.5, 0.74)
	# 바닥
	fill(Rect2i(0, 0, 36, 3), "grass")
	fill(Rect2i(0, 0, 2, 50), "grass")
	fill(Rect2i(16, 0, 4, 3), "road")
	fill(Rect2i(12, 4, 13, 6), "plaza")
	fill(Rect2i(3, 10, 31, 3), "dirt")
	fill(Rect2i(16, 13, 5, 26), "road")
	fill(Rect2i(3, 13, 4, 35), "dirt")
	fill(Rect2i(27, 13, 6, 26), "plaza")
	fill(Rect2i(6, 22, 10, 4), "ash")
	fill(Rect2i(21, 22, 6, 4), "ash")
	fill(Rect2i(21, 30, 6, 2), "dirt")
	fill(Rect2i(7, 38, 26, 10), "plaza")
	# 성벽·탑·성문
	for x in range(2, 36):
		var c := Vector2i(x, 3)
		if c in GATE_CELLS:
			continue
		add_prop("tower" if x in [2, 8, 16, 19, 26, 33] else "wall", c, true, false)
	for y in range(4, H):
		add_prop("tower" if y in [10, 18, 26, 34, 42] else "wall", Vector2i(2, y), true, false)
	for c in GATE_CELLS:
		gate_sprites.append(add_prop("gate_closed", c, true, false))
	# 맵 끝(오른쪽 아래 두 변)은 막는다
	for i in range(3, H):
		set_solid(Vector2i(35, i))
	for i in range(3, 36):
		set_solid(Vector2i(i, H - 1))
	# 집 (이름, 칸, 불탐)
	var houses := [
		# 성문 광장 양옆
		["house_b", Vector2i(4, 6), false], ["house_a", Vector2i(9, 6), true],
		["house_c", Vector2i(27, 6), false], ["house_a", Vector2i(31, 6), false],
		# 서쪽 덩어리 (뒷골목과 대로 사이)
		["house_b", Vector2i(7, 13), false], ["house_c", Vector2i(11, 13), false], ["house_d", Vector2i(14, 13), false],
		["house_a", Vector2i(7, 16), false], ["house_d", Vector2i(10, 17), false], ["house_c", Vector2i(13, 16), false],
		["house_c", Vector2i(7, 19), false], ["house_a", Vector2i(10, 20), false], ["house_b", Vector2i(13, 20), false],
		["house_b", Vector2i(7, 26), false], ["house_a", Vector2i(11, 26), false], ["house_d", Vector2i(14, 26), true],
		["house_d", Vector2i(7, 29), false], ["house_c", Vector2i(10, 29), false], ["house_a", Vector2i(13, 30), false],
		["house_a", Vector2i(7, 33), false], ["house_b", Vector2i(10, 33), false], ["house_c", Vector2i(14, 33), true],
		["house_d", Vector2i(7, 36), false],
		# 동쪽 덩어리 (대로와 시장 사이)
		["house_c", Vector2i(21, 13), false], ["house_a", Vector2i(24, 13), false],
		["house_d", Vector2i(24, 16), false], ["house_a", Vector2i(21, 17), true],
		["house_b", Vector2i(21, 20), false], ["house_a", Vector2i(24, 20), false],
		["house_d", Vector2i(21, 26), false], ["house_c", Vector2i(24, 26), false], ["house_a", Vector2i(21, 28), false],
		["house_b", Vector2i(21, 32), false], ["house_a", Vector2i(24, 33), false],
		["house_d", Vector2i(21, 35), false], ["house_a", Vector2i(24, 36), false],
		# 시장 동쪽 끝
		["house_c", Vector2i(33, 13), false], ["house_a", Vector2i(33, 18), false], ["house_d", Vector2i(33, 24), false],
		["house_c", Vector2i(33, 30), false], ["house_a", Vector2i(33, 35), false],
	]
	for h in houses:
		if h[2]:
			add_burning_house(h[0], h[1])
		else:
			add_prop(h[0], h[1])
	# 목마 광장
	add_prop("horse", Vector2i(19, 42))
	for c in [Vector2i(15, 40), Vector2i(26, 40), Vector2i(15, 46), Vector2i(26, 46)]:
		add_prop("column", c)
	add_light(Iso.grid_to_world(Vector2(21, 43)), Color(0.55, 0.65, 1.0), 0.5, 2.5, false)
	# 횃불: 대로는 밝은 곳과 그늘이 번갈아, 뒷골목은 종 옆에 하나, 시장 하나(+화로), 성문 광장 둘
	for c in [Vector2i(16, 15), Vector2i(20, 15), Vector2i(16, 28), Vector2i(20, 28), Vector2i(16, 36), Vector2i(20, 36),
			Vector2i(6, 31), Vector2i(27, 21), Vector2i(12, 8), Vector2i(23, 8)]:
		add_torch(c)
	for c in [Vector2i(15, 4), Vector2i(21, 4), Vector2i(30, 31)]:
		var b := add_prop("brazier", c, true, false)
		add_fire(b, Vector2(0, -16), 0.6)
	# 경보 종: 뒷골목 · 대로 · 시장
	for c in [Vector2i(3, 30), Vector2i(20, 23), Vector2i(32, 21)]:
		add_bell(c)
	for c in [Vector2i(13, 4), Vector2i(23, 4), Vector2i(16, 38), Vector2i(20, 38)]:
		add_prop("banner_troy", c, true, false)
	# 시장 짐더미·좌판
	for c in [Vector2i(28, 15), Vector2i(30, 16), Vector2i(28, 19), Vector2i(31, 23), Vector2i(29, 26), Vector2i(28, 28),
			Vector2i(31, 28), Vector2i(28, 33), Vector2i(31, 34), Vector2i(29, 37), Vector2i(11, 9), Vector2i(25, 9),
			Vector2i(10, 44), Vector2i(30, 44), Vector2i(5, 21), Vector2i(4, 38)]:
		add_prop("crate" if hash(c) % 2 == 0 else "barrel", c, true, false)
	for c in [Vector2i(30, 19), Vector2i(28, 31)]:
		add_prop("cart", c)
	for c in [Vector2i(32, 27), Vector2i(29, 35), Vector2i(12, 47)]:
		add_prop("amphora", c, true, false)
	for c in [Vector2i(27, 24), Vector2i(19, 9), Vector2i(12, 23), Vector2i(5, 41)]:
		add_prop("rubble", c, true, false)
	add_prop("spear_rack", Vector2i(32, 16))
	add_prop("winch", Vector2i(20, 5))


func start() -> void:
	zone_pos = Iso.grid_to_world(ZONE_CELL)
	player = Player.new()
	player.position = Iso.grid_to_world(Vector2(21.5, 46.0))
	world.add_child(player)
	player.face(Vector2(-1, -1))
	sinon = Npc.new()
	sinon.setup("greek_archer", "시논", _talk_sinon)
	sinon.position = Iso.grid_to_world(Vector2(18.5, 45.5))
	world.add_child(sinon)
	var south := _gdir(Vector2(0, 1))
	stealth_group = [
		# 대로: 입구 보초 · 오르내리는 창병 · 가운데 궁수
		_spawn("trojan_sword", Vector2(18.5, 37.0), [], south),
		_spawn("trojan_spear", Vector2(17.5, 34.0), [Vector2(17.5, 34.0), Vector2(17.5, 17.0)]),
		_spawn("trojan_archer", Vector2(19.0, 26.5), [], south),
		# 뒷골목: 오르내리는 검병 · 위쪽 보초
		_spawn("trojan_sword", Vector2(4.5, 45.0), [Vector2(4.5, 45.0), Vector2(4.5, 27.0)]),
		_spawn("trojan_sword", Vector2(4.5, 15.0), [], south),
		# 시장: 짐더미 사이를 도는 창병 · 위쪽 보초
		_spawn("trojan_spear", Vector2(28.5, 37.0), [Vector2(28.5, 37.0), Vector2(31.5, 31.0), Vector2(28.5, 25.0),
			Vector2(31.5, 18.0), Vector2(28.5, 25.0), Vector2(31.5, 31.0)]),
		_spawn("trojan_sword", Vector2(30.0, 14.5), [], south),
	]
	guard_group = [
		_spawn("trojan_sword", Vector2(15.5, 6.5)),
		_spawn("trojan_sword", Vector2(20.5, 7.0)),
		_spawn("trojan_spear", Vector2(16.5, 8.5)),
		_spawn("trojan_spear", Vector2(19.5, 8.5)),
		_spawn("trojan_archer", Vector2(23.5, 6.0)),
		_spawn("trojan_captain", Vector2(18.0, 5.2)),
	]
	for g in guard_group:
		g.vision = 130.0
		g.raises_alarm = false
	for c in SIGNAL_CELLS:
		var s := add_prop("torch_post_off", c, true, false)
		var it := Interactable.new()
		it.label = "횃불로 신호 보내기"
		it.hold_time = 1.2
		it.radius = 30.0
		it.enabled = false
		it.position = s.global_position + Vector2(0, 6)
		it.on_use = func(_by): _send_signal(s)
		world.add_child(it)
		signals.append(it)
	alarm_rung.connect(_on_alarm)
	winch_point = Interactable.new()
	winch_point.label = "권양기 돌리기"
	winch_point.hold_time = 2.0
	winch_point.radius = 30.0
	winch_point.enabled = false
	winch_point.position = Iso.grid_to_world(Vector2(20.5, 5.5)) + Vector2(0, 10)
	winch_point.on_use = func(_by): _open_gate()
	world.add_child(winch_point)
	_set_step(0)


## 격자 방향 → 화면 방향 (적이 바라볼 쪽)
func _gdir(g: Vector2) -> Vector2:
	return (Iso.grid_to_world(g) - Iso.grid_to_world(Vector2.ZERO)).normalized()


func _spawn(kind: String, g: Vector2, route := [], facing_dir := Vector2.ZERO) -> Enemy:
	var e := Enemy.new()
	e.setup(kind)
	e.position = Iso.grid_to_world(g)
	for r in route:
		e.patrol.append(Iso.grid_to_world(r))
	world.add_child(e)
	if facing_dir != Vector2.ZERO:
		e.face(facing_dir)
		e.home_facing = facing_dir
	return e


func _spawn_crew(at: Vector2) -> void:
	var crew := [["sword", "에우릴로코스"], ["spear", "폴리테스"], ["archer", "엘페노르"]]
	for i in crew.size():
		var c := Companion.new()
		c.setup(crew[i][0], crew[i][1])
		c.position = at + Vector2(-20 + i * 20, 18)
		world.add_child(c)
		squad.add_member(c)


## 검증용(--start=gate): 잠입을 건너뛰고 부하와 함께 성문 경비대 앞에서 시작
func skip_to_gate() -> void:
	for e in stealth_group:
		e.queue_free()
	stealth_group.clear()
	sinon.talk.enabled = false
	for it in signals:
		it.enabled = false
	player.position = Iso.grid_to_world(Vector2(18.5, 13.5))
	_spawn_crew(player.position)
	_set_step(2)


# ── 퀘스트 ────────────────────────────────────────────
func _set_step(s: int) -> void:
	step = s
	match s:
		0:
			Game.set_objective(chapter_title, "목마 옆의 첩자 시논에게 말을 걸어라  [E]")
			Game.quest_marker = sinon.global_position
		1:
			Game.set_objective(chapter_title, "들키지 않고 성문 앞 북쪽 가로까지 가서 횃불로 신호를 보내라")
			for it in signals:
				it.enabled = true
			Game.quest_marker = signals[1].global_position
			Game.show_hint("들키지 않게: 바닥의 옅은 부채꼴이 적의 시야(밝은 곳일수록 멀리 봄) · 뒤에서 E 조용히 처치 · Q 활은 눈치채지 못한 적을 한 발에 · E 횃불 끄기 · 달리면 발소리")
		2:
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (0/%d)" % guard_group.size())
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
		Game.say([["시논", "성문 앞 북쪽 가로에 닿으면 꺼진 횃불에 불을 붙이십시오. 부하들을 보내겠습니다."]])
		return
	sinon.talk.enabled = false
	Game.say([
		["시논", "오디세우스 님! 트로이 놈들은 목마를 신의 선물이라 믿고 밤새 잔치를 벌였습니다."],
		["오디세우스", "부하들은 아직 목마 안에 둔다. 내가 먼저 성문까지 길을 살피겠다."],
		["시논", "보초는 앞만 봅니다. 횃불 빛 안에선 멀리서도 보이니 그늘로 다니십시오. 뒤로 다가가면 소리 없이 처리할 수 있습니다."],
		["시논", "들키면 놈들이 경보 종으로 달려갑니다. 종이 울리면 성문 경비가 늘어날 겁니다."],
		["시논", "성문 앞 북쪽 가로 끝마다 꺼진 횃불이 있습니다. 불을 붙이시면 그걸 신호로 부하들을 보내겠습니다."],
		["오디세우스", "대로, 뒷골목, 시장… 길은 셋이군. 소리 없이 가겠다."],
	], func(): _set_step(1))


func _send_signal(torch: Sprite2D) -> void:
	if step != 1:
		return
	for it in signals:
		it.enabled = false
	torch.texture = AssetLibrary.prop_texture("torch_post")
	add_light(torch.global_position + Vector2(1, -20), Color(1.0, 0.55, 0.25), 0.6, 0.85)
	Sfx.play("cry", -10.0)
	_spawn_crew(player.global_position + Vector2(0, 30))
	Game.say([
		["에우릴로코스", "장군! 시논의 신호를 받고 그림자를 따라 왔습니다."],
		["오디세우스", "성문 경비를 치운다. 내 명령을 따르라."],
	], func(): _set_step(2))


func _on_alarm(_bell: Dictionary) -> void:
	if step > 2:
		return
	for a in ALARM_GUARDS:
		var e := _spawn(a[0], a[1])
		e.vision = 130.0
		e.raises_alarm = false
		guard_group.append(e)
	Game.show_hint("경보가 울렸다! 성문 경비가 2명 늘었다")


func _process(delta: float) -> void:
	super._process(delta)
	if _done:
		return
	if not _combat_hint and step in [1, 2] and enemies().any(func(e): return e.alerted):
		_combat_hint = true
		Game.show_hint("들켰다! 좌클릭 검 3연타 · F 강공격 · 우클릭 방패(막는 순간 패링) · Space 구르기 · Shift 달리기")
	match step:
		2:
			var n := _dead_count(guard_group)
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (%d/%d)" % [n, guard_group.size()])
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
