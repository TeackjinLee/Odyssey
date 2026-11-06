class_name Ship
extends Node2D
## 배(GAME_DESIGN 챕터 2 "항해 모드", docs/maps/CH2_ISMAROS.md). 오디세우스의 갤리선(키 입력·봇)과 키코네스 배(ai)를 같은 클래스로 쓴다.
## 위치·방향·속도는 격자 공간에서 계산하고(아이소 맵에서 돌아도 모양이 맞게) 화면에는 Iso로 옮겨 그린다.
## 조작: 노 단계(뒤로·멈춤·천천히·힘껏 — 힘껏은 노꾼 힘을 쓴다) · 키(돌리기 — 느리면 덜 돎 = 회전 반경)
## · 돛(바람을 등지면 빨라지고, 맞바람에 펴면 오히려 밀린다).
## 관성: 속도는 목표 속도를 천천히 따라간다. 해안·암초에 부딪히면 튕겨 나고 빠를수록 선체가 상한다.
## 뱃머리로 빠르게 들이받으면 상대 배가 크게 상한다. 탄 부하 중 궁병·창병은 가까운 적 배를 쏜다(검병은 노를 젓는다).
## 그림: 아직 코드로 그린 임시 그림(_draw). 8방향 갤리선 그림(ART_PLAN §4.8)을 받으면 바꾼다.

signal sunk(ship: Ship)

const GEARS := ["뒤로", "멈춤", "천천히", "힘껏"]
## 노 단계별 목표 속도(격자 칸/초). 배열 번호 = gear + 1
const OAR_SPEED := [-0.55, 0.0, 0.95, 1.8]
## 돛: 바람을 정확히 등질 때 더하는 속도. 옆바람이면 조금, 맞바람이면 뒤로 민다
const SAIL_SPEED := 1.25
const ACCEL := 0.55
const BRAKE := 0.9
## 키: 초당 도는 각도(라디안). 속도가 TURN_FULL 칸/초보다 느리면 그만큼 덜 돈다(가만히 있으면 거의 못 돎)
const TURN_RATE := 0.95
const TURN_FULL := 0.9
## 사람이 몰 때 키(방향타)를 꺾고 푸는 빠르기(초당) — 키를 누르자마자 확 돌지 않고 0.25초쯤에 걸쳐 꺾인다
const RUDDER_IN := 4.0
const RUDDER_OUT := 6.0
## 노꾼 힘: 힘껏 저으면 초당 줄고, 아니면 회복. 0이면 힘껏이 천천히와 같아진다
const ROW_DRAIN := 5.5
const ROW_REST := 4.0
## 부딪힘: 이 속도(칸/초)보다 빠르면 선체가 상함
const BUMP_SPEED := 0.45
const BUMP_DMG := 12.0
## 들이받기: 뱃머리로 이 속도보다 빠르게 받으면 상대 배에 큰 피해
const RAM_SPEED := 1.1
const RAM_DMG := 34.0
## 갑판 사격: 역할 → [사거리(칸), 쿨타임, 피해]
const DECK_FIRE := {"archer": [6.5, 1.8, 8.0], "spear": [4.5, 3.0, 13.0]}

var team: int = Actor.Team.GREEK
var display_name := "갤리선"
var length := 3.2
var width := 1.05
var oars := 6
var gpos := Vector2.ZERO
var heading := 0.0
var speed := 0.0
var gear := 0
var sail := false
var max_hull := 120.0
var hull := 120.0
var row_power := 100.0
var ai := false
var sunk_done := false
## 탄 사람: 오디세우스(조종) · 부하(숨겨 둔 Companion)
var rider: Node2D = null
var crew: Array = []
## 키코네스 배: 궁수 수·쏘는 간격·화살 피해
var archers := 0
var arrow_dmg := 2.0
var shoot_every := 2.4
var sail_color := Color(0.9, 0.86, 0.75)
var stripe := Color(0.7, 0.25, 0.18)
var hull_color := Color(0.36, 0.22, 0.13)
var deck_color := Color(0.62, 0.45, 0.28)
## 그려 받은 배 그림(tools/gen_ship.py): {"sail"/"furl": [텍스처, 방향별 칸 정보]}. 없으면 코드로 그린다
var art := {}
## 갤리선 선체만 16방향 그림(gen_ship.py --hull) + 돛 천 + 배 위 사람 시트(gen_ship_crew.py). 있으면 돛대·돛·노·사람은 코드로 그린다
var hull_art: Array = []
var cloth: Texture2D = null
var crew_tex: Texture2D = null
var crew_meta := {}
const ROWERS := ["greek_sword", "greek_spear", "greek_archer"]
## 그리스 노꾼 노 젓기 시트(ship_crew의 줄). 있으면 ROWERS 대신 노의 위상에 맞춰 그린다
const ROW_SHEET := "greek_rower"
## 배마다 다른 것: 노꾼 시트(앉기 동작이 없는 시트는 윗부분만 그려 앉은 듯), 서 있는 궁수 시트, 돛대 높이 배율
var rowers: Array = ROWERS
var rower_cut := 1.0
var archer_sheet := ""
var mast_k := 1.0
var target_ship: Ship = null
## 폭풍(챕터 2): 파도에 노가 휩쓸려 이보다 빨리 못 간다(칸/초). 돛이 찢어지면 다시 펼 수 없다(레벨이 고침)
var max_speed := INF
var sail_torn := false
var turn_in := 0.0
var _rudder := 0.0

var _shoot_cd := 1.5
var _path := PackedVector2Array()
var _path_t := 0.0
var _oar_t := 0.0
var _stroke := 0.0
var _wake: Array = []
var _wake_t := 0.0
var _flash := 0.0
var _bump_cd := 0.0
var _deck_cd := {}
var _stuck_t := 0.0
var _reverse_t := 0.0


## 키코네스 배: 작고 붉은 돛, 궁수 몇
func as_enemy_boat() -> Ship:
	team = Actor.Team.TROJAN
	display_name = "키코네스 배"
	ai = true
	length = 2.3
	width = 0.85
	oars = 4
	max_hull = 55.0
	hull = max_hull
	archers = 2
	sail_color = Color(0.62, 0.16, 0.14)
	stripe = Color(0.95, 0.8, 0.4)
	hull_color = Color(0.24, 0.16, 0.1)
	deck_color = Color(0.45, 0.32, 0.2)
	gear = 1
	load_hull("cicones_boat")
	if hull_art.is_empty():
		load_art("cicones_boat")   # 선체 16방향이 없으면 돛까지 그린 8방향
	rowers = ["cicones_sword", "cicones_spear"]
	rower_cut = 0.62
	archer_sheet = "cicones_archer"
	mast_k = 0.78
	return self


## assets/sprites/<이름>_sail·_furl 그림을 쓴다(둘 다 있어야)
func load_art(id: String) -> void:
	art = {}
	for k in ["sail", "furl"]:
		var path := "res://assets/sprites/%s_%s.png" % [id, k]
		if not ResourceLoader.exists(path):
			art = {}
			return
		art[k] = [load(path), JSON.parse_string(FileAccess.get_file_as_string(path.replace(".png", ".json")))]


## 선체 16방향·돛 천·사람 시트가 모두 있어야 쓴다
func load_hull(id: String) -> void:
	var p := "res://assets/sprites/%s_hull.png" % id
	var c := "res://assets/sprites/%s_cloth.png" % id
	if not (ResourceLoader.exists(p) and ResourceLoader.exists(c) and ResourceLoader.exists("res://assets/sprites/ship_crew.png")):
		return
	hull_art = [load(p), JSON.parse_string(FileAccess.get_file_as_string(p.replace(".png", ".json")))]
	cloth = load(c)
	crew_tex = load("res://assets/sprites/ship_crew.png")
	crew_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/ship_crew.json"))


func _ready() -> void:
	add_to_group("ships")
	if team == Actor.Team.GREEK and art.is_empty():
		load_hull("odysseus_galley")
		if hull_art.is_empty():
			load_art("odysseus_galley")   # 그려 받은 갤리선 그림(없으면 코드 그림)
	_sync()


func fwd() -> Vector2:
	return Vector2(cos(heading), sin(heading))


func right() -> Vector2:
	return Vector2(-sin(heading), cos(heading))


func _sync() -> void:
	position = Iso.grid_to_world(gpos)


## 뱃머리·고물·양 옆 — 해안·암초 판정과 배끼리 닿음에 쓰는 점
func _hull_points(p: Vector2, h: float) -> Array:
	var f := Vector2(cos(h), sin(h))
	var r := Vector2(-sin(h), cos(h))
	return [p + f * length * 0.5, p - f * length * 0.5, p + r * width * 0.5, p - r * width * 0.5,
		p + f * length * 0.25 + r * width * 0.4, p + f * length * 0.25 - r * width * 0.4]


func _clear_at(p: Vector2, h: float) -> bool:
	var lv: IsoLevel = Game.level
	for q in _hull_points(p, h):
		if not lv.sea_ok(Vector2i(floori(q.x), floori(q.y))):
			return false
	return true


func wind_effect() -> float:
	var lv = Game.level
	var w: Vector2 = lv.get("wind") if lv.get("wind") != null else Vector2.ZERO
	var k: float = lv.get("wind_strength") if lv.get("wind_strength") != null else 0.0
	return clampf(0.25 + 0.75 * fwd().dot(w), -0.4, 1.0) * k


func target_speed() -> float:
	var t: float = OAR_SPEED[gear + 1]
	if gear == 2 and row_power <= 0.0:
		t = OAR_SPEED[2]
	if sail:
		t += SAIL_SPEED * wind_effect()
	return clampf(t, -max_speed, max_speed)


func is_riding_player() -> bool:
	return rider != null and rider is Player


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 4.0)
	_bump_cd -= delta
	if sunk_done:
		return
	turn_in = 0.0
	if ai:
		_ai(delta)
	elif is_riding_player() and not Game.cutscene:
		if Game.autoplay:
			_bot(delta)
		else:
			_read_controls()
	elif not is_riding_player():
		gear = 0
	# 노꾼 힘
	if gear == 2 and row_power > 0.0:
		row_power = maxf(0.0, row_power - ROW_DRAIN * delta)
	else:
		row_power = minf(100.0, row_power + ROW_REST * delta)
	var t := target_speed()
	var a := ACCEL if absf(t) > absf(speed) and (signf(t) == signf(speed) or absf(speed) < 0.05) else BRAKE
	speed = move_toward(speed, t, a * delta)
	# 키: 빠를수록 잘 돎. 뒤로 갈 때는 반대로
	var turn := turn_in * TURN_RATE * clampf(absf(speed) / TURN_FULL, 0.22, 1.0) * delta * (-1.0 if speed < -0.05 else 1.0)
	if turn != 0.0 and _clear_at(gpos, heading + turn):
		heading = wrapf(heading + turn, -PI, PI)
	var lv = Game.level
	var drift: Vector2 = (lv.get("wind") if lv.get("wind") != null else Vector2.ZERO) * 0.06 * float(lv.get("wind_strength") if lv.get("wind_strength") != null else 0.0)
	var next := gpos + (fwd() * speed + drift) * delta
	if _clear_at(next, heading):
		gpos = next
	else:
		_bump()
	_touch_ships()
	_sync()
	# 노 젓기(그림·소리)
	if gear != 0:
		var rate := 1.1 if gear == 1 else (2.0 if row_power > 0.0 else 1.3)
		_oar_t += delta * rate * TAU * (1.0 if gear > 0 else -1.0)
		_stroke += delta * rate
		if _stroke >= 1.0:
			_stroke = 0.0
			if is_riding_player():
				Sfx.play("oar", -15.0 if gear == 1 else -11.0)
	if absf(speed) > 0.2:
		_wake_t -= delta
		if _wake_t <= 0.0:
			_wake_t = 0.07
			var sd := signf(speed)
			var side := Iso.ex * right().x + Iso.ey * right().y
			var back := -(Iso.ex * fwd().x + Iso.ey * fwd().y).normalized() * sd
			var k := clampf(absf(speed) / 2.5, 0.3, 1.0)
			_wake.push_front([Iso.grid_to_world(gpos - fwd() * length * 0.5 * sd), 1.0, side, k, randi(), back * (WAKE_PUSH + 10.0 * k)])
	# 물결은 고물에서 뒤로 밀려나며 느려지고, 바다 무늬와 같은 흐름(바람 쪽)으로 함께 떠간다
	var flow := _sea_flow()
	for w in _wake:
		w[1] -= delta / WAKE_LIFE
		w[0] += (w[5] + flow) * delta
		w[5] *= exp(-1.2 * delta)
	while _wake.size() > 0 and _wake[_wake.size() - 1][1] <= 0.0:
		_wake.pop_back()
	_deck_fire(delta)
	queue_redraw()


func _read_controls() -> void:
	if Input.is_action_just_pressed("move_up"):
		gear = mini(2, gear + 1)
		Sfx.play("ui", -12.0)
	if Input.is_action_just_pressed("move_down"):
		gear = maxi(-1, gear - 1)
		Sfx.play("ui", -12.0)
	var want := Input.get_axis("move_left", "move_right")
	var rate := RUDDER_IN if absf(want) > absf(_rudder) and signf(want) == signf(_rudder) or _rudder == 0.0 else RUDDER_OUT
	_rudder = move_toward(_rudder, want, rate * get_physics_process_delta_time())
	turn_in = _rudder
	if Input.is_action_just_pressed("run"):
		set_sail(not sail)


func set_sail(on: bool) -> void:
	if sail == on:
		return
	if on and sail_torn:
		if is_riding_player() and not Game.autoplay:
			Game.show_hint("돛이 찢어져 펼 수 없다")
		return
	sail = on
	Sfx.at("swing", global_position, -8.0)


func _bump() -> void:
	if _bump_cd > 0.0:
		speed = 0.0
		return
	_bump_cd = 0.6
	if absf(speed) > BUMP_SPEED:
		damage(BUMP_DMG * absf(speed), null)
		Sfx.at("ram", global_position, -4.0)
		if is_riding_player():
			Game.shake(4.0)
			Fx.text(global_position + Vector2(0, -50), "쾅!", Color(1, 0.7, 0.5))
	speed = -speed * 0.3


## 배끼리 닿음: 서로 밀어내고, 뱃머리로 빠르게 받았으면 들이받기
func _touch_ships() -> void:
	var mine := [gpos + fwd() * length * 0.32, gpos, gpos - fwd() * length * 0.32]
	for o in get_tree().get_nodes_in_group("ships"):
		if o == self or o.sunk_done:
			continue
		if gpos.distance_to(o.gpos) > (length + o.length) * 0.6:
			continue
		var theirs: Array = [o.gpos + o.fwd() * o.length * 0.32, o.gpos, o.gpos - o.fwd() * o.length * 0.32]
		var r: float = (width + o.width) * 0.45
		for i in mine.size():
			for q in theirs:
				var d: Vector2 = mine[i] - q
				var l := d.length()
				if l >= r:
					continue
				var push: Vector2 = (d / maxf(l, 0.01)) * (r - l) * 0.5
				if _clear_at(gpos + push, heading):
					gpos += push
				if i == 0 and speed > RAM_SPEED and o.team != team and _bump_cd <= 0.0:
					_bump_cd = 0.8
					o.damage(RAM_DMG * speed / OAR_SPEED[3], self)
					damage(3.0, o)
					speed *= 0.45
					Sfx.at("ram", global_position, 0.0)
					Game.shake(5.0)
					Fx.text(o.global_position + Vector2(0, -48), "들이받기!", Color(1, 0.85, 0.4))
					if is_riding_player():
						Game.stats["rams"] = Game.stats.get("rams", 0) + 1
				return


func damage(amount: float, _src) -> void:
	if sunk_done:
		return
	if team == Actor.Team.GREEK and Game.level and Game.level.get("god"):
		amount = 0.0
	hull = maxf(0.0, hull - amount)
	_flash = 1.0
	if hull <= 0.0:
		_sink()


func _sink() -> void:
	sunk_done = true
	remove_from_group("ships")
	gear = 0
	Sfx.at("splash", global_position, 0.0)
	Sfx.at("ram", global_position, -4.0)
	Fx.text(global_position + Vector2(0, -50), "격침!" if team != Actor.Team.GREEK else "배가 가라앉는다!", Color(1, 0.85, 0.4))
	if team != Actor.Team.GREEK:
		Game.stats["kills"] = Game.stats.get("kills", 0) + 1
		Game.stats["sunk"] = Game.stats.get("sunk", 0) + 1
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 2.4)
	tw.tween_property(self, "position", position + Vector2(0, 14), 2.4)
	sunk.emit(self)
	if team != Actor.Team.GREEK:
		tw.chain().tween_callback(queue_free)


# ── 갑판 사격 ─────────────────────────────────────────
func _deck_fire(delta: float) -> void:
	if team == Actor.Team.GREEK:
		for c in crew:
			if not is_instance_valid(c) or c.state == Actor.St.DOWNED or not DECK_FIRE.has(c.role):
				continue
			var spec: Array = DECK_FIRE[c.role]
			_deck_cd[c] = float(_deck_cd.get(c, randf_range(0.3, 1.2))) - delta
			if _deck_cd[c] > 0.0:
				continue
			var tgt := _nearest_foe(spec[0])
			if tgt:
				_deck_cd[c] = spec[1]
				var rp = Game.level.get("rations")
				var dmg: float = spec[2] * (rp.crew_power() if rp else 1.0)
				shoot_at(tgt, dmg, c.role == "spear")
	elif archers > 0 and target_ship and is_instance_valid(target_ship) and not target_ship.sunk_done:
		_shoot_cd -= delta
		if _shoot_cd <= 0.0 and gpos.distance_to(target_ship.gpos) < 6.5:
			_shoot_cd = shoot_every / archers
			shoot_at(target_ship, arrow_dmg, false)


func _nearest_foe(reach: float) -> Ship:
	var best: Ship = null
	var bd := reach
	for o in get_tree().get_nodes_in_group("ships"):
		if o.team != team and not o.sunk_done:
			var d: float = gpos.distance_to(o.gpos)
			if d < bd:
				bd = d
				best = o
	return best


## 화살·창 한 발: 포물선으로 날아가 맞으면 선체 피해. 우리 배가 맞으면 갑판의 부하가 다치기도 한다
func shoot_at(t: Ship, dmg: float, javelin: bool) -> void:
	var s := Shot.new()
	s.from = global_position + Vector2(0, -14)
	s.to = t.global_position + Vector2(randf_range(-10, 10), -8 + randf_range(-4, 4))
	s.javelin = javelin
	s.dur = 0.45 + s.from.distance_to(s.to) / 420.0
	s.hit = func():
		if is_instance_valid(t) and not t.sunk_done:
			t.damage(dmg, self)
			Sfx.at("arrow_hit", t.global_position, -8.0)
			if t.team == Actor.Team.GREEK and not t.crew.is_empty() and randf() < 0.4:
				var c: Companion = t.crew.pick_random()
				if is_instance_valid(c) and c.state != Actor.St.DOWNED:
					c.hp = maxf(1.0, c.hp - 5.0)
	Sfx.at("bow", global_position, -10.0)
	Game.level.fx_layer.add_child(s)


class Shot extends Node2D:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var t := 0.0
	var dur := 0.6
	var javelin := false
	var hit: Callable

	func _process(delta: float) -> void:
		t += delta / dur
		if t >= 1.0:
			if hit.is_valid():
				hit.call()
			queue_free()
			return
		queue_redraw()

	func _at(k: float) -> Vector2:
		return from.lerp(to, k) + Vector2(0, -36.0 * sin(PI * k))

	func _draw() -> void:
		var p := _at(t)
		var q := _at(maxf(0.0, t - 0.05))
		var d := (p - q).normalized() * (9.0 if javelin else 6.0)
		draw_line(p - d, p, Color(0.9, 0.85, 0.7) if javelin else Color(0.85, 0.8, 0.65), 1.5 if javelin else 1.0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(0.75, 0.75, 0.8))


# ── AI(키코네스 배) · 봇(--auto) ───────────────────────
## 격자 목표 쪽으로 키를 돌린다. 각도 차(라디안)를 돌려준다
func _steer(goal: Vector2) -> float:
	var to := goal - gpos
	if to.length() < 0.05:
		return 0.0
	var diff := wrapf(to.angle() - heading, -PI, PI)
	turn_in = clampf(diff * 2.0, -1.0, 1.0)
	return absf(diff)


## 바다 길(암초·해안을 돌아감)을 따라 다음 점. 0.8초마다 다시 찾는다
func _waypoint(goal: Vector2, delta: float) -> Vector2:
	_path_t -= delta
	if _path_t <= 0.0 or _path.is_empty():
		_path_t = 0.8
		_path = Game.level.sea_path(gpos, goal) if Game.level.has_method("sea_path") else PackedVector2Array()
	while _path.size() > 1 and gpos.distance_to(_path[0]) < 1.2:
		_path.remove_at(0)
	if _path.size() > 1 and gpos.distance_to(_path[0]) < 2.4:
		return _path[1]
	return _path[0] if not _path.is_empty() else goal


func _ai(delta: float) -> void:
	var t := target_ship
	if t == null or not is_instance_valid(t) or t.sunk_done:
		gear = 0
		return
	var d := gpos.distance_to(t.gpos)
	var goal := t.gpos
	if d < 4.2:
		# 가까우면 옆으로 돌며 쏜다
		goal = t.gpos + (gpos - t.gpos).normalized().rotated(1.0) * 3.4
	var wp := _waypoint(goal, delta)
	var diff := _steer(wp)
	gear = 2 if d > 5.0 and diff < 1.0 else 1
	sail = fwd().dot(Game.level.wind) > 0.35


## 봇: 퀘스트 표시(Game.quest_marker) 쪽 바다 길을 따라간다. 가까우면 멈추고, 막히면 잠깐 뒤로.
func _bot(delta: float) -> void:
	if Game.quest_marker == Vector2.INF:
		gear = 0
		return
	var goal := Iso.world_to_grid(Game.quest_marker)
	var dist := gpos.distance_to(goal)
	if _reverse_t > 0.0:
		_reverse_t -= delta
		gear = -1
		turn_in = 1.0
		return
	var wp := _waypoint(goal, delta)
	var diff := _steer(wp)
	if dist < 2.2:
		gear = 0
	elif diff > 1.3 or dist < 4.0:
		gear = 1
	else:
		gear = 2 if row_power > 30.0 else 1
	set_sail(fwd().dot(Game.level.wind) > 0.3 and dist > 4.0 and not Game.level.get("storm_on"))
	if gear > 0 and absf(speed) < 0.08:
		_stuck_t += delta
		if _stuck_t > 2.5:
			_stuck_t = 0.0
			_reverse_t = 1.4
	else:
		_stuck_t = 0.0


# ── 그림(임시: 코드로 그림) ─────────────────────────────
## 배 기준 격자 오프셋(앞 lx, 오른쪽 ly) + 높이 h(px) → 이 노드 기준 화면 좌표
func _pt(lx: float, ly: float, h := 0.0) -> Vector2:
	var g := fwd() * lx + right() * ly
	return Iso.ex * g.x + Iso.ey * g.y + Vector2(0, -h)


func _outline(h: float, k := 1.0) -> PackedVector2Array:
	var L := length * 0.5 * k
	var Wd := width * 0.5 * k
	return PackedVector2Array([_pt(L, 0, h + 3), _pt(L * 0.64, Wd, h), _pt(-L * 0.76, Wd, h), _pt(-L, Wd * 0.5, h + 2),
		_pt(-L, -Wd * 0.5, h + 2), _pt(-L * 0.76, -Wd, h), _pt(L * 0.64, -Wd, h)])


func _draw() -> void:
	_draw_wake()
	var flash := Color(1, 1, 1).lerp(Color(1.6, 0.6, 0.5), _flash)
	if not hull_art.is_empty():
		_draw_hull_ship(flash)
		_draw_hull_bar()
		return
	# 그림자·물 닿는 곳
	draw_colored_polygon(_outline(-1, 1.12), Color(0.02, 0.05, 0.12, 0.45))
	# 노(물에 닿는 쪽 먼저) — 그려 받은 배는 노 구멍이 그림에 있고 코드 노는 선체 밖에 떠 보여 그리지 않는다
	var side_pts: Array = []
	for s in ([] if not art.is_empty() else [-1.0, 1.0]):
		for i in oars:
			var lx := lerpf(-length * 0.3, length * 0.26, float(i) / maxf(1.0, oars - 1))
			var sw := sin(_oar_t + i * 0.15) * 0.22 if gear != 0 else 0.0
			var lift := maxf(0.0, cos(_oar_t + i * 0.15)) * 3.0 if gear != 0 else 0.0
			side_pts.append([_pt(lx, s * width * 0.45, 6), _pt(lx + sw, s * (width * 0.5 + 0.8), lift)])
	for o in side_pts:
		draw_line(o[0], o[1], Color(0.55, 0.4, 0.25), 1.0)
	if not art.is_empty():
		_draw_art(flash)   # 머리 점도 코드 갑판 높이라 그림 위에선 떠 보여 그리지 않는다(부하는 HUD 목록에 '배 위')
	else:
		_draw_code_hull(flash)
	_draw_hull_bar()


## 적 배: 상했으면 체력 막대
func _draw_hull_bar() -> void:
	if team != Actor.Team.GREEK and hull < max_hull:
		var r := Rect2(-14, -62, 28, 3)
		draw_rect(r, Color(0, 0, 0, 0.7))
		draw_rect(Rect2(r.position, Vector2(r.size.x * hull / max_hull, r.size.y)), Color(0.85, 0.25, 0.2))


## 그려 받은 배: 뱃머리 화면 방향에 가까운 칸을 골라, 선체 폭을 코드 선체 폭에 맞추고 바닥을 물 높이에 둔다
func _draw_art(flash: Color) -> void:
	var o := _outline(0)
	var box := Rect2(o[0], Vector2.ZERO)
	for q in o:
		box = box.expand(q)
	var v := Iso.ex * fwd().x + Iso.ey * fwd().y
	var sheet: Array = art["sail" if sail else "furl"]
	var m: Dictionary = sheet[1]["dirs"][posmod(roundi(v.angle() / (PI / 4.0)), 8)]
	var rc: Array = m["rect"]
	# 한 배율로 그려 온 시트(len = 동쪽 칸 선체 길이)는 모든 방향에 같은 배율 — 돌 때 크기가 바뀌지 않게
	var k := box.size.x / float(m["hull_w"])
	if sheet[1].has("len"):
		k = length * (Iso.ex - Iso.ey).length() / sqrt(2.0) / float(sheet[1]["len"])
	var size := Vector2(rc[2], rc[3]) * k
	var at := Vector2(box.get_center().x - float(m["hull_x"]) * k, box.end.y + 2.0 - size.y)
	draw_texture_rect_region(sheet[0], Rect2(at, size), Rect2(rc[0], rc[1], rc[2], rc[3]), flash)


# ── 선체 16방향 그림 + 코드 돛대·돛·노·사람 ─────────────────────────────
# 선체 그림은 화면 방향 22.5°마다 한 장이라, 노·사람·돛대도 그 칸의 방향(_hf)으로 놓아 선체에서 어긋나지 않게 한다.
# 높이는 그림 픽셀(요청 안내 그림 기준)로 재고 _hk배 해서 화면 픽셀로.
const HYST := 0.2   # 선체 그림을 바꾸기 전 경계를 넘어 더 돌아야 하는 몫(한 칸 22.5°의 몇 배)
var _hull_idx := -1
var _hf := Vector2.RIGHT
var _hk := 0.35


func _hp(lx: float, ly: float, h: float) -> Vector2:
	var g := _hf * lx + Vector2(-_hf.y, _hf.x) * ly
	return Iso.ex * g.x + Iso.ey * g.y + Vector2(0, -h * _hk)


func _draw_hull_ship(flash: Color) -> void:
	var m: Dictionary = hull_art[1]
	var v := Iso.ex * fwd().x + Iso.ey * fwd().y
	# 22.5°마다 한 장. 반투명으로 두 장을 겹치면 배가 둘로 보여, 한 장씩 딱 바꾸되 경계에서 떨리지 않게 HYST만큼 더 돌아야 바꾼다.
	# 노·사람·돛대·물거품도 지금 그림의 방향(_hf)에 맞춰 함께 바뀐다
	var f := v.angle() / (PI / 8.0)
	if _hull_idx < 0 or absf(wrapf(f - _hull_idx, -8.0, 8.0)) > 0.5 + HYST:
		_hull_idx = posmod(roundi(f), 16)
	var idx := _hull_idx
	var a := idx * PI / 8.0
	_hf = Vector2(cos(a) + 2.0 * sin(a), 2.0 * sin(a) - cos(a)).normalized()   # 화면 방향 → 격자 방향(투영의 역)
	_hk = Iso.ex.x / float(m["px"]) * length / float(m["len"])
	var dw := length * float(m["wid"]) / float(m["len"])
	var deck := float(m["deck"]) - 6.0
	# 그림자
	var sh := PackedVector2Array()
	for i in 16:
		var t := TAU * i / 16.0
		sh.append(_hp(cos(t) * length * 0.55, sin(t) * dw * 0.75, -2))
	draw_colored_polygon(sh, Color(0.02, 0.05, 0.12, 0.45))
	# 노: 먼 쪽 → 선체 → 갑판 위(깊이 순) → 가까운 쪽
	var near := 1.0 if _hp(0, 1, 0).y > _hp(0, -1, 0).y or (is_equal_approx(_hp(0, 1, 0).y, _hp(0, -1, 0).y) and _hp(0, 1, 0).x > 0) else -1.0
	var n := mini(oars, 5)
	_draw_oars(-near, n, dw, flash)
	_draw_waterline(dw, false)
	_draw_hull_cell(m["dirs"][idx], flash)
	_draw_waterline(dw, true)
	var items: Array = []   # [화면 y, 종류, 값…]
	var back := posmod(roundi((-v).angle() / (PI / 4.0)), 8)
	var face := posmod(roundi(v.angle() / (PI / 4.0)), 8)
	for side in [-1.0, 1.0]:
		for i in n:
			var lx := lerpf(-length * 0.3, length * 0.2, float(i) / (n - 1)) + sin(_oar_t + i * 0.15) * 0.04 * float(gear != 0)
			var p := _hp(lx, side * dw * 0.24, deck)
			var who: String = rowers[(i + (1 if side > 0 else 0)) % rowers.size()]
			var tick := 0
			if rowers == ROWERS and crew_meta["rows"].has(ROW_SHEET):
				# 노 젓는 그림(tools/gen_rower.py): 노깃이 물에 드는 순간(cos = 0, 내려가며) 뻗기 → 당기기 → 끝까지 당김 → 돌아오기
				who = ROW_SHEET
				if gear != 0:
					var u := fposmod(_oar_t + i * 0.15 - PI * 0.5, TAU) / TAU
					tick = int(floor(u * 4.0 + 0.5)) % 4
				else:
					tick = 3
			items.append([p.y, 0, p, who, back, tick, rower_cut])
	if archer_sheet != "" and crew_meta["rows"].has(archer_sheet):
		# 궁수: 뱃머리·고물에 서서 쫓는 배 쪽을 본다
		var look := v
		if target_ship:
			var tg := target_ship.gpos - gpos
			look = Iso.ex * tg.x + Iso.ey * tg.y
		for j in archers:
			var p := _hp(length * (0.34 if j % 2 == 0 else -0.36), (0.12 if j > 1 else 0.0) * dw, deck)
			items.append([p.y, 0, p, archer_sheet, posmod(roundi(look.angle() / (PI / 4.0)), 8), int(Time.get_ticks_msec() / 300.0) + j, 1.0])
	if rider:
		var p := _hp(length * 0.36, 0, deck + 4)
		var who: String = Game.outfit if crew_meta["rows"].has(Game.outfit) else "odysseus_ch1"
		items.append([p.y, 0, p, who, face, int(Time.get_ticks_msec() / 250.0), 1.0])
	var mb := _hp(-length * 0.02, 0, deck)
	items.append([mb.y, 1, mb])
	items.sort_custom(func(x, y): return x[0] < y[0])
	for it in items:
		if it[1] == 0:
			_draw_crew(it[2], it[3], it[4], it[5], flash, it[6])
		else:
			_draw_mast(dw, deck, flash)
	_draw_oars(near, n, dw, flash)


func _draw_hull_cell(d: Dictionary, mod: Color) -> void:
	var rc: Array = d["rect"]
	draw_texture_rect_region(hull_art[0], Rect2(-Vector2(d["ax"], d["ay"]) * _hk, Vector2(rc[2], rc[3]) * _hk), Rect2(rc[0], rc[1], rc[2], rc[3]), mod)


func _draw_oars(side: float, n: int, dw: float, flash: Color) -> void:
	var wood := Color(0.32, 0.21, 0.12) * flash
	var lite := Color(0.62, 0.46, 0.3) * flash
	for i in n:
		var ph := _oar_t + i * 0.15
		var lx := lerpf(-length * 0.3, length * 0.2, float(i) / (n - 1)) + 0.06
		var sw := sin(ph) * 0.2 if gear != 0 else 0.0
		var lift := maxf(0.0, cos(ph)) * 14.0 if gear != 0 else 8.0
		var a := _hp(lx, side * dw * 0.5, float(hull_art[1]["deck"]) - 4.0)
		var b := _hp(lx - 0.14 - sw, side * (dw * 0.5 + 0.6), lift)   # 노깃은 고물 쪽으로 조금 눕힌다
		draw_line(a, b, wood, 2.0)
		draw_line(a, a.lerp(b, 0.7), lite, 1.0)
		draw_line(a.lerp(b, 0.72), b, wood, 3.0)   # 노깃


## cut < 1이면 칸 위쪽 cut만 그려 그 아래 끝을 발 자리에 둔다(앉기 동작이 없는 인물을 노 젓는 자리에 앉은 듯이)
func _draw_crew(p: Vector2, sheet: String, dir: int, tick: int, flash: Color, cut := 1.0) -> void:
	var r: Dictionary = crew_meta["rows"][sheet]
	var fs: float = crew_meta["frame"]
	var nf: int = r["frames"]
	var col := dir * nf + tick % nf
	var an := Vector2(crew_meta["anchor"][0], crew_meta["anchor"][1]) * 0.5
	if cut < 1.0:
		an.y = fs * cut * 0.5
	draw_texture_rect_region(crew_tex, Rect2(p - an, Vector2(fs, fs * cut) * 0.5), Rect2(col * fs, int(r["row"]) * fs, fs, fs * cut), flash)


## 돛대·활대·돛(천 그림을 사각형에 입힘). 활대는 배 폭 방향이지만, 정면에서 옆으로 볼 때 돛이 선이 되지 않게 가로 폭을 남긴다
func _draw_mast(dw: float, deck: float, flash: Color) -> void:
	var lx := -length * 0.02
	var base := _hp(lx, 0, deck)
	var top := _hp(lx, 0, deck + 250 * mast_k)
	var yard_h := deck + (225.0 if sail else 200.0) * mast_k
	var y0 := _hp(lx, 0, yard_h)
	var half := (_hp(lx, dw * 1.05, yard_h) - y0)
	var full := dw * 1.05 * Iso.ex.length() * 1.4
	if absf(half.x) < full * 0.55:
		half.x = (1.0 if half.x >= 0 else -1.0) * full * 0.55
	var wood := Color(0.36, 0.24, 0.14) * flash
	draw_line(base, top, Color(0.22, 0.14, 0.08) * flash, 3.0)
	draw_line(base, top, wood, 1.5)
	if sail and not sail_torn:
		var drop := Vector2(0, 150.0 * mast_k * _hk)
		var belly := (_hp(lx + 0.25, 0, 0) - _hp(lx, 0, 0))   # 돛이 뱃머리 쪽으로 부푼다
		var pts := PackedVector2Array([y0 - half, y0 + half, y0 + half + drop + belly * 0.3, y0 + belly * 0.5 + drop * 1.05, y0 - half + drop + belly * 0.3])
		# 가운데 아래 꼭짓점이 부풀어 다각형이 오목해지지 않게 두 장으로
		draw_polygon(PackedVector2Array([pts[0], y0, y0 + belly * 0.5 + drop * 1.05, pts[4]]),
			PackedColorArray([flash, flash, flash, flash]), PackedVector2Array([Vector2(0, 0), Vector2(0.5, 0), Vector2(0.5, 1), Vector2(0, 1)]), cloth)
		draw_polygon(PackedVector2Array([y0, pts[1], pts[2], y0 + belly * 0.5 + drop * 1.05]),
			PackedColorArray([flash, flash, flash, flash]), PackedVector2Array([Vector2(0.5, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0.5, 1)]), cloth)
		draw_line(base, top, wood, 1.5)
	else:
		# 접은 돛: 활대에 감긴 줄무늬 두루마리
		var k := 8
		for i in k:
			var a := y0 - half + half * 2.0 * i / k
			var b := y0 - half + half * 2.0 * (i + 1) / k
			draw_line(a + Vector2(0, 2), b + Vector2(0, 2), (stripe if i % 2 == 0 else sail_color) * flash, 4.0)
	draw_line(y0 - half, y0 + half, Color(0.22, 0.14, 0.08) * flash, 2.0)
	draw_line(top, y0 - half, Color(0.2, 0.14, 0.1, 0.7), 1.0)   # 밧줄
	draw_line(top, y0 + half, Color(0.2, 0.14, 0.1, 0.7), 1.0)
	draw_line(top, _hp(length * 0.48, 0, deck), Color(0.2, 0.14, 0.1, 0.6), 1.0)
	draw_line(top, _hp(-length * 0.45, 0, deck), Color(0.2, 0.14, 0.1, 0.6), 1.0)


func _draw_code_hull(flash: Color) -> void:
	# 선체: 물에 잠긴 옆면 → 갑판
	draw_colored_polygon(_outline(0), hull_color.darkened(0.35) * flash)
	draw_colored_polygon(_outline(7), hull_color * flash)
	draw_colored_polygon(_outline(8, 0.82), deck_color * flash)
	var rim := _outline(8)
	rim.append(rim[0])
	draw_polyline(rim, Color(0.12, 0.07, 0.04), 1.0)
	for i in range(1, 4):
		draw_line(_pt(-length * 0.36, -width * 0.4 + i * width * 0.2, 8), _pt(length * 0.28, -width * 0.4 + i * width * 0.2, 8), deck_color.darkened(0.2), 1.0)
	# 뱃머리 장식·고물 기둥
	draw_line(_pt(length * 0.5, 0, 10), _pt(length * 0.56, 0, 17), hull_color.darkened(0.2), 2.0)
	draw_line(_pt(-length * 0.5, 0, 10), _pt(-length * 0.55, 0, 19), hull_color.darkened(0.2), 2.0)
	draw_circle(_pt(length * 0.46, width * 0.22, 9), 1.2, Color(0.95, 0.95, 0.9))   # 뱃머리 눈
	draw_circle(_pt(length * 0.46, -width * 0.22, 9), 1.2, Color(0.95, 0.95, 0.9))
	_draw_heads()
	_draw_code_sail(flash)


## 사람: 노꾼·부하(머리), 고물의 조타수(오디세우스: 금빛)
func _draw_heads() -> void:
	var heads := crew.size() if team == Actor.Team.GREEK else archers + 2
	for i in heads:
		var lx := lerpf(-length * 0.2, length * 0.25, float(i) / maxf(1.0, heads - 1))
		var ly := (0.18 if i % 2 == 0 else -0.18) * width
		draw_circle(_pt(lx, ly, 13), 2.2, Color(0.1, 0.07, 0.05))
		draw_circle(_pt(lx, ly, 13), 1.6, Color(0.55, 0.75, 0.85) if team == Actor.Team.GREEK else Color(0.75, 0.55, 0.35))
	if rider:
		draw_circle(_pt(-length * 0.4, 0, 14), 2.6, Color(0.1, 0.07, 0.05))
		draw_circle(_pt(-length * 0.4, 0, 14), 2.0, Color(0.95, 0.78, 0.38))


func _draw_code_sail(flash: Color) -> void:
	# 돛대·활대·돛
	var mx := length * 0.06
	draw_line(_pt(mx, 0, 8), _pt(mx, 0, 50), Color(0.3, 0.2, 0.12), 2.0)
	var span := width * 1.05
	draw_line(_pt(mx, -span, 47), _pt(mx, span, 47), Color(0.3, 0.2, 0.12), 1.5)
	if sail:
		var belly := 0.18 * clampf(wind_effect() + 0.3, 0.0, 1.0)
		var quad := PackedVector2Array([_pt(mx, -span, 47), _pt(mx, span, 47), _pt(mx + belly, span * 0.92, 20), _pt(mx + belly, -span * 0.92, 20)])
		draw_colored_polygon(quad, sail_color * flash)
		draw_colored_polygon(PackedVector2Array([_pt(mx, -span, 38), _pt(mx, span, 38), _pt(mx + belly * 0.5, span * 0.96, 33), _pt(mx + belly * 0.5, -span * 0.96, 33)]), stripe)
		quad.append(quad[0])
		draw_polyline(quad, Color(0.2, 0.15, 0.1, 0.8), 1.0)
	else:
		draw_line(_pt(mx, -span, 45), _pt(mx, span, 45), sail_color.darkened(0.15), 3.0)


# ── 물과 닿는 곳: 뱃전 물거품 띠·뱃머리 물결·고물 뒤 V자 물결 ─────────────
const FOAM := Color(0.86, 0.93, 1.0)
## 손볼 수치: 물결 자국이 남는 시간(초), 벌어지는 빠르기, 고물에서 뒤로 밀려나는 빠르기(px/초)
const WAKE_LIFE := 3.3
const WAKE_SPREAD := 1.3
const WAKE_PUSH := 14.0


## 바다 무늬가 흐르는 속도(월드 px/초) — iso_level._update_sea와 같은 방향·빠르기
func _sea_flow() -> Vector2:
	var lv = Game.level
	if lv == null or lv.get("sea_speed") == null:
		return Vector2.ZERO
	var dir := Vector2(1.0, 0.3).normalized()
	var w: Variant = lv.get("wind")
	if w is Vector2 and w != Vector2.ZERO:
		dir = (Iso.ex * w.x + Iso.ey * w.y).normalized()
	return dir * float(lv.sea_speed.x)


## 흘수선 둘레 거품: 선체 둘레 타원을 따라 픽셀 점이 깜박인다. front면 화면 앞쪽 반(선체 위에), 아니면 뒤쪽 반(선체 아래에)
func _draw_waterline(dw: float, front: bool) -> void:
	var c := _hp(0, 0, 0)
	var sp := clampf(absf(speed) / 2.5, 0.0, 1.0)
	var tick := int(Time.get_ticks_msec() / 110.0)
	var n := 40
	for i in n:
		var t := TAU * i / n
		var lx := cos(t)
		var p := _hp(lx * length * 0.5, sin(t) * dw * 0.52, 0)
		if (p.y > c.y) != front:
			continue
		var bow := maxf(0.0, lx * signf(speed if absf(speed) > 0.05 else 1.0))   # 뱃머리 쪽일수록 거품이 많다
		var on := 0.35 + bow * sp * 0.6
		if float(hash(i * 7 + tick) % 100) / 100.0 > on:
			continue
		var q := p.round()
		draw_rect(Rect2(q, Vector2(2 if bow * sp > 0.4 else 1, 1)), Color(FOAM, 0.55 + 0.35 * bow))
	# 뱃머리 물결: 빠를수록 길게 갈라지는 두 줄
	if sp > 0.1:
		var sd := signf(speed)
		var tip := _hp(length * 0.5 * sd, 0, 0)
		for side in [-1.0, 1.0]:
			var end := _hp(length * (0.5 - 0.35 * sp) * sd, side * dw * (0.6 + 0.5 * sp), 0)
			if (end.y > c.y) != front:
				continue
			var k := 7
			for j in k:
				if hash(j * 13 + tick + int(side)) % 4 == 0:
					continue
				var q := tip.lerp(end, (j + 0.5) / k).round()
				draw_rect(Rect2(q, Vector2(2, 1)), Color(FOAM, 0.8 - 0.07 * j))


## 고물 뒤 물결: 뿌린 자리(월드)에서 뒤로 밀려나며 양옆으로 벌어지는(V자) 두 줄 거품 + 그 사이 옅게 일렁이는 물
func _draw_wake() -> void:
	var arms := [[], []]
	var mids: Array = []
	for w in _wake:
		var a: float = w[1]
		if a <= 0.0:
			continue
		var age := 1.0 - a
		var base: Vector2 = w[0] - global_position
		var side: Vector2 = w[2] * width * 0.5
		var spread := 0.5 + age * (WAKE_SPREAD + float(w[3]))
		arms[0].append([(base - side * spread).round(), a, int(w[4])])
		arms[1].append([(base + side * spread).round(), a, int(w[4]) >> 3])
		mids.append([base, a, int(w[4])])
	# 사이 물: 두 줄 사이를 옅은 물빛으로
	for i in range(arms[0].size() - 1):
		var a: float = arms[0][i + 1][1]
		var quad := PackedVector2Array([arms[0][i][0], arms[0][i + 1][0], arms[1][i + 1][0], arms[1][i][0]])
		if arms[0][i][0].distance_to(arms[0][i + 1][0]) < 30.0:
			var qc := Color(0.5, 0.65, 0.85, 0.16 * a)
			draw_primitive(quad, PackedColorArray([qc, qc, qc, qc]), PackedVector2Array())   # 꼬인 사각형도 삼각분할 없이
	# 두 줄 거품: 이웃 점을 잇되 군데군데 끊는다
	for arm in arms:
		for i in range(arm.size() - 1):
			var p0: Vector2 = arm[i][0]
			var p1: Vector2 = arm[i + 1][0]
			var a: float = arm[i + 1][1]
			if p0.distance_to(p1) > 30.0 or arm[i][2] % 6 == 0:
				continue
			draw_line(p0, p1, Color(FOAM, minf(1.0, 1.3 * a * a)), 2.0 if a > 0.7 else 1.0)
	# 고물 바로 뒤 휘도는 거품
	for m in mids:
		var a: float = m[1]
		if a < 0.6:
			continue
		var sd0: int = m[2]
		var jit := Vector2((sd0 % 9) - 4, ((sd0 / 9) % 5) - 2)
		draw_rect(Rect2((m[0] + jit).round(), Vector2(2, 1)), Color(FOAM, (a - 0.6) * 2.2))
