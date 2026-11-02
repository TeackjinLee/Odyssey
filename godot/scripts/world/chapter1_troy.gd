class_name Chapter1Troy
extends IsoLevel
## CHAPTER 1 — 트로이의 목마.
## 밤, 불타는 트로이. 오디세우스가 혼자 목마에서 내려(부하는 목마 안에 대기) 세 갈래 길 —
## 횃불이 늘어선 대로, 어두운 서쪽 뒷골목, 짐더미가 쌓인 동쪽 시장 — 중 하나로 성문 앞 북쪽 가로까지 몰래 간다.
## 가로 끝의 꺼진 횃불에 불을 붙여 시논에게 신호를 보내면 부하들이 합류하고,
## 성문 경비대(수비대장) 처치 → 권양기로 성문 개방 → 아카이아 증원군과 성문 거점 사수.
## 들키면 경보병이 갈래마다 하나 있는 경보 종으로 달려가고, 종이 울리면 성문 경비가 2명씩 는다.
## 골라서 하는 목표: 시장 동쪽 막다른 골목의 묶인 정찰병 구출(부하 +1), 뒷골목 성벽 밑 무기고 불태우기(마지막 반격에 궁수 없음).
## 권양기는 E를 누르고 있는 동안만 돌아가고 손을 떼면 성문이 다시 내려간다(부하를 2 위치 사수로 곁에 세워 지킴).
## 사수 반격 3파: 방패벽 → 높은 곳 궁수 → 권양기 돌격(트로이군이 권양기를 돌려 성문을 닫으면 다시 열어야 함).
##
## 격자: x는 화면 오른쪽 아래, y는 왼쪽 아래로 늘어난다. 바깥 성벽은 y=3 줄과 x=2 열(화면 위쪽 두 변).
## 위(북)부터: 성문 광장 y4~9 · 북쪽 가로 y10~12 · 세 갈래 y13~37(뒷골목 x3~6, 대로 x16~20, 시장 x27~33,
## 가운데 가로 y22~25로 서로 이어짐) · 목마 광장 y38~48.

const GATE_CELLS := [Vector2i(17, 3), Vector2i(18, 3)]
const ZONE_CELL := Vector2(18.0, 6.5)
const ZONE_RADIUS := 56.0
## 신호 횃불 자리: 갈래마다 하나 (뒷골목 · 대로 · 시장 끝)
const SIGNAL_CELLS := [Vector2i(4, 12), Vector2i(15, 12), Vector2i(33, 11)]
## 묶인 정찰병 자리(시장 동쪽 막다른 골목)와 무기고(뒷골목 성벽 밑, 화로 옆)
const SCOUT_CELL := Vector2(34.3, 27.8)
const ARMORY_CELLS := [Vector2i(3, 22), Vector2i(3, 23), Vector2i(3, 24)]
## 높은 곳 궁수가 올라서는 짐더미(북쪽 가로 양쪽)
const PERCH_CELLS := [Vector2i(12, 10), Vector2i(24, 10)]
## 권양기: 처음 여는 데 / 다시 여는 데 / 트로이군이 닫는 데 걸리는 시간, 손을 떼면 내려가는 빠르기(1초에)
const WINCH_TIME := 12.0
const REOPEN_TIME := 5.0
const CLOSE_TIME := 4.0
const WINCH_DROP := 0.04
## 트로이 돌격병이 서서 권양기를 돌리는 자리(권양기 칸 바로 앞)
const WINCH_STAND := Vector2(20.5, 6.6)
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
var scout: Npc
var scout_freed := false
var armory_point: Interactable
var armory_sprites: Array = []
var armory_burned := false
var gate_open := false
var opened_once := false
var winch_progress := 0.0
var close_progress := 0.0
var _cranked := false
var _crank_frame := -1
var _winch_attacks := 0
var captain: Enemy
var _boss_hint := false


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
			Vector2i(6, 31), Vector2i(27, 21), Vector2i(12, 8), Vector2i(23, 8), Vector2i(34, 26)]:
		add_torch(c)
	for c in [Vector2i(15, 4), Vector2i(21, 4), Vector2i(30, 31), Vector2i(5, 21)]:
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
			Vector2i(10, 44), Vector2i(30, 44), Vector2i(4, 38)]:
		add_prop("crate" if hash(c) % 2 == 0 else "barrel", c, true, false)
	for c in [Vector2i(30, 19), Vector2i(28, 31)]:
		add_prop("cart", c)
	for c in [Vector2i(30, 24), Vector2i(29, 35), Vector2i(12, 47)]:
		add_prop("amphora", c, true, false)
	for c in [Vector2i(27, 24), Vector2i(19, 9), Vector2i(12, 23), Vector2i(5, 41)]:
		add_prop("rubble", c, true, false)
	add_prop("spear_rack", Vector2i(32, 16))
	add_prop("winch", Vector2i(20, 5))
	# 무기고: 통·창걸이·상자 (화로 불빛 안)
	for i in ARMORY_CELLS.size():
		armory_sprites.append(add_prop(["barrel", "spear_rack", "crate"][i], ARMORY_CELLS[i], true, false))
	# 높은 곳 궁수 발판(지나갈 수 있음 — 화살이 막히지 않게)
	for c in PERCH_CELLS:
		add_prop("crate", c, false, false)


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
		_spawn("trojan_sword", Vector2(4.5, 45.0), [Vector2(4.5, 45.0), Vector2(4.5, 23.6)]),
		_spawn("trojan_sword", Vector2(4.5, 15.0), [], south),
		# 시장: 짐더미 사이를 도는 창병 · 위쪽 보초
		_spawn("trojan_spear", Vector2(28.5, 37.0), [Vector2(28.5, 37.0), Vector2(31.5, 31.0), Vector2(28.5, 25.0),
			Vector2(31.5, 18.0), Vector2(28.5, 25.0), Vector2(31.5, 31.0)]),
		_spawn("trojan_sword", Vector2(30.0, 14.5), [], south),
		# 막다른 골목: 묶인 정찰병을 지키는 보초(골목 안쪽을 봄)
		_spawn("trojan_sword", Vector2(32.6, 27.8), [], _gdir(Vector2(1, 0))),
	]
	guard_group = [
		_spawn("trojan_sword", Vector2(15.5, 6.5)),
		_spawn("trojan_sword", Vector2(20.5, 7.0)),
		_spawn("trojan_spear", Vector2(16.5, 8.5)),
		_spawn("trojan_spear", Vector2(19.5, 8.5)),
		_spawn("trojan_archer", Vector2(23.5, 6.0)),
		_spawn("trojan_captain", Vector2(18.0, 5.2)),
	]
	captain = guard_group[5]
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
	scout = Npc.new()
	scout.setup("greek_sword", "정찰병 테르산드로스", _free_scout)
	scout.talk.label = "묶인 정찰병 풀어 주기"
	scout.talk.hold_time = 1.5
	scout.fixed_dir = Iso.dir8(_gdir(Vector2(-1, 0)))
	scout.fixed_anim = "downed"
	scout.position = Iso.grid_to_world(SCOUT_CELL)
	world.add_child(scout)
	armory_point = Interactable.new()
	armory_point.label = "무기고에 불 지르기"
	armory_point.hold_time = 1.5
	armory_point.radius = 26.0
	armory_point.position = Iso.grid_to_world(Vector2(4.6, 23.5))
	armory_point.on_use = func(_by): _burn_armory()
	world.add_child(armory_point)
	Game.side_markers = [scout.global_position, armory_point.global_position]
	winch_point = Interactable.new()
	winch_point.label = "권양기 돌리기"
	winch_point.hold_time = 999.0   # 끝나지 않음 — 누르고 있는 동안 _update_winch가 돌린다
	winch_point.progress = 0.0
	winch_point.radius = 30.0
	winch_point.enabled = false
	winch_point.position = Iso.grid_to_world(Vector2(20.5, 5.5)) + Vector2(0, 10)
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


## 검증용(--start=winch): 성문 경비대까지 치운 뒤 권양기 앞에서 시작
func skip_to_winch() -> void:
	skip_to_gate()
	for e in guard_group:
		e.queue_free()
	guard_group.clear()
	player.position = Iso.grid_to_world(Vector2(20.0, 7.5))
	for i in squad.members.size():
		squad.members[i].position = player.position + Vector2(-20 + i * 20, 18)
	_set_step(3)


# ── 퀘스트 ────────────────────────────────────────────
func _set_step(s: int) -> void:
	step = s
	match s:
		0:
			Game.set_objective(chapter_title, "목마 옆의 첩자 시논에게 말을 걸어라  [E]")
			Game.quest_marker = sinon.global_position
		1:
			Game.set_objective(chapter_title, "들키지 않고 성문 앞 북쪽 가로까지 가서 횃불로 신호를 보내라" + _side_text())
			for it in signals:
				it.enabled = true
			Game.quest_marker = signals[1].global_position
			Game.show_hint("들키지 않게: 바닥의 옅은 부채꼴이 적의 시야(밝은 곳일수록 멀리 봄) · 뒤에서 E 조용히 처치 · Q 활은 눈치채지 못한 적을 한 발에 · E 횃불 끄기 · 달리면 발소리")
		2:
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (0/%d)" % guard_group.size() + _side_text())
			Game.quest_marker = Iso.grid_to_world(Vector2(18, 7))
			Game.show_hint("부대 명령  1 따라오기 · 2 위치 사수 · 3 집중 공격(마우스 근처 적) · 4 후퇴·집결   R 전투의 함성 · Q 활")
		3:
			winch_point.enabled = true
			Game.quest_marker = winch_point.global_position
			Game.boss_changed.emit(null)
			Game.show_hint("권양기는 E를 누르고 있는 동안만 돈다 — 손을 떼면 성문이 다시 내려간다. 2(위치 사수)로 부하를 곁에 세워 지키게 하라")
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
		["시논", "그리고… 시장 동쪽 막다른 골목에 우리 정찰병이 묶여 있습니다. 뒷골목 성벽 밑 무기고를 태우면 놈들 궁수가 화살을 못 챙길 겁니다."],
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


func _side_text() -> String:
	return "\n선택  %s 정찰병 구출 · %s 무기고 불태우기" % ["●" if scout_freed else "○", "●" if armory_burned else "○"]


## 묶인 정찰병을 풀면 부하가 되어 바로 따라온다.
func _free_scout(_by) -> void:
	if scout_freed:
		return
	scout_freed = true
	var at := scout.global_position
	scout.queue_free()
	Game.side_markers.erase(at)
	var c := Companion.new()
	c.setup("sword", "테르산드로스")
	c.position = at
	world.add_child(c)
	squad.add_member(c)
	c.face(player.global_position - at)
	Sfx.play("ui")
	Game.say([["테르산드로스", "장군! 살았습니다. 이 칼로 은혜를 갚겠습니다."]])
	_refresh_side()


## 무기고에 불을 지르면 불빛이 퍼지고 타는 소리에 가까운 적이 의심한다.
func _burn_armory() -> void:
	if armory_burned:
		return
	armory_burned = true
	armory_point.enabled = false
	Game.side_markers.erase(armory_point.global_position)
	for i in armory_sprites.size():
		var sp: Sprite2D = armory_sprites[i]
		add_fire(sp, Vector2(randf_range(-3, 3), -10), 0.7 + 0.15 * i, i == 1)
	add_smoke(armory_sprites[1], Vector2(0, -40), 1.0)
	Sfx.play("cry", -14.0)
	noise(armory_point.global_position, 130.0, 0.6)
	Fx.text(armory_point.global_position + Vector2(0, -40), "무기고가 탄다", Color(1, 0.7, 0.3))
	Game.show_hint("무기고가 탄다 — 마지막 반격에 궁수가 오지 못한다. 불빛에 들키지 않게 물러나라")
	_refresh_side()


func _refresh_side() -> void:
	if step == 1:
		Game.set_objective(chapter_title, "들키지 않고 성문 앞 북쪽 가로까지 가서 횃불로 신호를 보내라" + _side_text())


## 성문을 열거나 닫는다(통과 가능 여부·그림·소리).
func _set_gate(open: bool) -> void:
	gate_open = open
	Sfx.play("gate", -2.0)
	Game.shake(6.0 if open else 4.0)
	var pname := "gate_open" if open else "gate_closed"
	var meta: Dictionary = AssetLibrary.prop(pname)
	for i in GATE_CELLS.size():
		set_solid(GATE_CELLS[i], not open)
		var sp: Sprite2D = gate_sprites[i]
		sp.texture = AssetLibrary.prop_texture(pname)
		sp.offset = -Vector2(meta["anchor"][0], meta["anchor"][1])


## 닫힌 성문: 오디세우스가 권양기를 누르고 있으면 올라가고, 놓으면 천천히 내려간다.
func _update_winch(delta: float) -> void:
	var need := REOPEN_TIME if opened_once else WINCH_TIME
	if player.state == Actor.St.INTERACT and player.interact_target == winch_point:
		winch_progress = minf(1.0, winch_progress + delta / need)
	else:
		winch_progress = maxf(0.0, winch_progress - delta * WINCH_DROP)
	winch_point.progress = winch_progress
	if not opened_once and _winch_attacks < 2 and winch_progress >= [0.15, 0.55][_winch_attacks]:
		_send_winch_attack(_winch_attacks)
		_winch_attacks += 1
	if winch_progress >= 1.0:
		winch_progress = 0.0
		winch_point.enabled = false
		if opened_once:
			_set_gate(true)
			Game.show_hint("성문을 다시 열었다!")
		else:
			_open_gate()
		return
	if step == 3:
		Game.set_objective(chapter_title, "권양기를 돌려 성문을 열어라  [E 누르고 있기]  %d%%\n손을 떼면 성문이 다시 내려간다" % int(winch_progress * 100.0) + _side_text())


## 권양기 소리를 듣고 몰려오는 트로이군 (처음 열 때 두 번)
func _send_winch_attack(i: int) -> void:
	var groups := [
		[["trojan_sword", Vector2(30.0, 11.0)], ["trojan_spear", Vector2(31.0, 11.5)], ["trojan_sword", Vector2(29.0, 10.5)]],
		[["trojan_sword", Vector2(6.0, 11.0)], ["trojan_spear", Vector2(7.0, 11.5)], ["trojan_sword", Vector2(18.5, 15.0)]],
	]
	Game.show_hint("권양기 소리에 트로이군이 몰려온다! 부하를 곁에 세워 막게 하라")
	for g in groups[i]:
		var e := _spawn(g[0], g[1])
		e.alert(player)


## 트로이 돌격병이 권양기를 돌린다(Enemy._run_crank가 부름). 다 돌리면 성문이 닫힌다.
func crank_gate(delta: float) -> void:
	if not gate_open or step != 4 or _done or _crank_frame == Engine.get_physics_frames():
		return   # 여럿이 붙어도 한 프레임에 한 번만 — 닫히는 데 늘 CLOSE_TIME
	_crank_frame = Engine.get_physics_frames()
	_cranked = true
	close_progress = minf(1.0, close_progress + delta / CLOSE_TIME)
	if close_progress >= 1.0:
		close_progress = 0.0
		_set_gate(false)
		winch_progress = 0.0
		winch_point.enabled = true
		Game.show_hint("성문이 닫혔다! 권양기를 다시 돌려라 (%d초)" % int(REOPEN_TIME))
		for e in enemies():
			if e.phase == "crank":
				e.crank_pos = Vector2.INF
				e._set_phase("chase")
				e.target = player


## 아게노르 2페이즈: 뿔나팔 소리에 북쪽 가로 양쪽에서 검병 둘이 뛰어온다(경비대 수에 더함).
func on_boss_horn(_boss: Enemy) -> void:
	for g in [Vector2(11.0, 10.5), Vector2(25.5, 10.5)]:
		var e := _spawn("trojan_sword", g)
		e.raises_alarm = false
		e.alert(player)
		guard_group.append(e)
	Game.show_hint("아게노르가 뿔나팔로 검병을 불렀다! 방패 돌진(붉은 길)은 옆으로 피하라 — 벽에 박히면 2초 무방비")


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
			if not _boss_hint and is_instance_valid(captain) and captain.alerted:
				_boss_hint = true
				Game.show_hint("아게노르: 3연타 뒤 크게 붉게 깜빡이면 내려찍기 — 막는 순간(K/우클릭) 패링하면 2초 무방비")
			var n := _dead_count(guard_group)
			Game.set_objective(chapter_title, "성문 앞 광장의 경비대를 처치하라  (%d/%d)" % [n, guard_group.size()] + _side_text())
			if n >= guard_group.size():
				_set_step(3)
		3:
			if not gate_open:
				_update_winch(delta)
		4:
			if gate_open:
				if not _cranked:
					close_progress = maxf(0.0, close_progress - delta * 0.3)
				_cranked = false
			else:
				_update_winch(delta)
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
	opened_once = true
	_set_gate(true)
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
	if p_in and not contested and gate_open:
		capture = min(100.0, capture + delta * 1.9)
	var wave_at := [0.0, 30.0, 62.0]
	if waves_sent < wave_at.size() and capture >= wave_at[waves_sent]:
		_send_wave(waves_sent)
		waves_sent += 1
	var status := "" if p_in else "  — 원 안으로 들어가라"
	if contested:
		status = "  — 적이 거점에 있다!"
	if not gate_open:
		status = "\n성문이 닫혔다! 권양기를 다시 돌려라  %d%%" % int(winch_progress * 100.0)
	elif close_progress > 0.0:
		status += "\n트로이군이 권양기를 돌린다! 성문이 닫힌다  %d%%" % int(close_progress * 100.0)
	Game.set_objective(chapter_title, "성문 거점을 사수하라  (%d%%)%s" % [int(capture), status])
	if capture >= 100.0:
		_finish()


## 반격 3파: [종류, 칸, 역할("wall" 방패벽 · "perch" 높은 곳 궁수 · "crank" 권양기 돌격 · "" 보통)]
func _send_wave(i: int) -> void:
	var waves := [
		[["trojan_spear", Vector2(16.5, 17.0), "wall"], ["trojan_sword", Vector2(17.5, 17.0), "wall"],
			["trojan_sword", Vector2(18.5, 17.0), "wall"], ["trojan_spear", Vector2(19.5, 17.0), "wall"]],
		[["trojan_archer", Vector2(PERCH_CELLS[0]) + Vector2(0.5, 0.5), "perch"], ["trojan_archer", Vector2(PERCH_CELLS[1]) + Vector2(0.5, 0.5), "perch"],
			["trojan_sword", Vector2(7.0, 11.0), ""], ["trojan_sword", Vector2(29.0, 11.0), ""]],
		[["trojan_sword", Vector2(7.0, 11.0), "crank"], ["trojan_sword", Vector2(29.5, 11.0), "crank"], ["trojan_sword", Vector2(18.5, 15.0), "crank"],
			["trojan_spear", Vector2(17.5, 16.0), ""], ["trojan_spear", Vector2(19.5, 16.0), ""],
			["trojan_archer", Vector2(10.0, 10.5), ""], ["trojan_archer", Vector2(26.5, 10.5), ""]],
	]
	var hints := [
		"반격 1/3 — 방패벽이 밀고 온다! 정면은 막힌다: F 강공격으로 방패를 부숴라",
		"반격 2/3 — 짐더미 위의 궁수! Q 활로 쏘거나 3(집중 공격)으로 부하를 보내라",
		"반격 3/3 — 트로이군이 권양기로 달려간다! 돌리면 성문이 닫힌다 — 막아라",
	]
	Game.show_hint(hints[i])
	for w in waves[i]:
		if i == 2 and w[0] == "trojan_archer" and armory_burned:
			continue
		var e := _spawn(w[0], w[1])
		match w[2]:
			"wall":
				e.shield_wall = true
			"perch":
				e.perch = true
				e.body.position.y = -14.0
			"crank":
				e.start_crank(Iso.grid_to_world(WINCH_STAND))
				continue
		e.alert(player)
	if i == 2 and armory_burned:
		Game.show_hint(hints[i] + "  (무기고가 타서 궁수가 없다)")


func _finish() -> void:
	_done = true
	Game.quest_marker = Vector2.INF
	Game.side_markers = []
	Game.stats["scout"] = scout_freed
	Game.stats["armory"] = armory_burned
	for c in squad.members:
		c.revive(0.6)
	Game.set_objective(chapter_title, "성문 점령 완료")
	Game.say([
		["오디세우스", "트로이의 성문은 우리 것이다. 십 년의 전쟁이 오늘 밤 끝난다."],
		["에우릴로코스", "장군, 이제… 이타카로 돌아가는 겁니까?"],
		["오디세우스", "그래. 배를 준비해라. 고향이 기다린다."],
	], func(): Game.chapter_cleared.emit(Game.stats.duplicate()))


func _draw() -> void:
	if _done:
		return
	# 권양기 둘레: 파랑 = 여는 정도, 빨강 = 트로이군이 닫는 정도
	if step >= 3:
		var wp := winch_point.global_position
		if not gate_open:
			_draw_ring(wp, 16.0, 1.0, Color(0, 0, 0, 0.5), 3.0)
			_draw_ring(wp, 16.0, winch_progress, Color(0.45, 0.75, 1.0, 0.95), 2.0)
		elif close_progress > 0.0:
			_draw_ring(wp, 16.0, 1.0, Color(0, 0, 0, 0.5), 3.0)
			_draw_ring(wp, 16.0, close_progress, Color(1.0, 0.3, 0.2, 0.95), 2.0)
	if step != 4:
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


## 땅 위 타원 고리의 frac만큼(12시부터 시계 방향)
func _draw_ring(o: Vector2, r: float, frac: float, col: Color, width: float) -> void:
	if frac <= 0.0:
		return
	var n := maxi(2, int(40 * frac))
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := -PI / 2.0 + TAU * frac * i / n
		pts.append(o + Vector2(cos(a) * r, sin(a) * r / Combat.Y_STRETCH))
	draw_polyline(pts, col, width)
