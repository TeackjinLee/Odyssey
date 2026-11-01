class_name Player
extends Actor
## 오디세우스. 이동·달리기, 검 3연타 + 강공격, 방패 막기(막기 직후 0.2초는 패링), 구르기, 활 조준·발사,
## 상호작용(E 길게), 전투의 함성(R), 부대 명령(1~4).

const SWORD_COMBO := [
	{"anim": "attack1", "dur": 0.34, "hit": 0.11, "dmg": 11.0, "reach": 27.0, "arc": 150.0, "kb": 70.0, "lunge": 120.0, "stop": 0.05, "shake": 1.5},
	{"anim": "attack2", "dur": 0.34, "hit": 0.11, "dmg": 12.0, "reach": 27.0, "arc": 150.0, "kb": 70.0, "lunge": 120.0, "stop": 0.05, "shake": 1.5, "reverse": true},
	{"anim": "attack3", "dur": 0.5, "hit": 0.22, "dmg": 19.0, "reach": 31.0, "arc": 120.0, "kb": 170.0, "lunge": 180.0, "stop": 0.09, "shake": 4.0},
]
const HEAVY := {"anim": "heavy", "dur": 0.72, "hit": 0.34, "dmg": 28.0, "reach": 35.0, "arc": 220.0, "kb": 230.0, "lunge": 120.0, "stop": 0.11, "shake": 5.0, "heavy": true}
const BOW_RECOVER := {"anim": "", "dur": 0.2, "hit": 99.0}
const SKILL_CD := 20.0
const HEAVY_CD := 1.2

var weapon := "sword"
var combo_step := 0
var combo_window := 0.0
var current: Dictionary = {}
var hit_done := false
var buffered := 0.0
var heavy_cd := 0.0
var skill_cd := 0.0
var bow_draw := 0.0
var dodge_dir := Vector2.ZERO
var interact_target: Interactable = null
var interact_progress := 0.0
var move_vel := Vector2.ZERO
var inp := {}
var _bot_attack_toggle := false
var weapons: WeaponLayer


func _ready() -> void:
	sheet = "odysseus" if ResourceLoader.exists("res://assets/sprites/odysseus.png") else "odysseus_sword"
	team = Team.GREEK
	display_name = "오디세우스"
	max_hp = 140.0
	walk_speed = 72.0
	run_speed = 118.0
	show_health_bar = false
	can_parry = true
	head_height = 58.0
	super._ready()
	shadow.scale = Vector2(1.3, 1.3)
	if not AssetLibrary.character_hands(sheet).is_empty():
		weapons = WeaponLayer.new()
		weapons.attach(self)
	add_to_group("player")
	Game.player = self
	var light := PointLight2D.new()
	light.texture = AssetLibrary.light_texture()
	light.color = Color(1.0, 0.8, 0.6)
	light.energy = 0.55
	light.texture_scale = 0.9
	light.position = Vector2(0, -16)
	add_child(light)


func _read_input() -> void:
	if Game.autoplay:
		inp = _bot_input()
		return
	inp = {
		"move": Input.get_vector("move_left", "move_right", "move_up", "move_down"),
		"run": Input.is_action_pressed("run"),
		"attack": Input.is_action_just_pressed("attack"),
		"attack_held": Input.is_action_pressed("attack"),
		"block": Input.is_action_pressed("block"),
		"dodge": Input.is_action_just_pressed("dodge"),
		"heavy": Input.is_action_just_pressed("heavy"),
		"switch": Input.is_action_just_pressed("switch_weapon"),
		"interact": Input.is_action_just_pressed("interact"),
		"interact_held": Input.is_action_pressed("interact"),
		"skill": Input.is_action_just_pressed("skill"),
		"aim": get_global_mouse_position(),
	}
	var cmds := ["cmd_follow", "cmd_hold", "cmd_focus", "cmd_regroup"]
	for i in cmds.size():
		if Input.is_action_just_pressed(cmds[i]) and Game.squad:
			Game.squad.command(i, inp["aim"])


func think(delta: float) -> void:
	_read_input()
	heavy_cd = max(0.0, heavy_cd - delta)
	skill_cd = max(0.0, skill_cd - delta)
	buffered = max(0.0, buffered - delta)
	if state == St.IDLE or state == St.MOVE:
		combo_window -= delta
		if combo_window <= 0.0:
			combo_step = 0
		if inp["switch"]:
			_switch_weapon()
	if inp["skill"] and skill_cd <= 0.0 and state != St.INTERACT:
		_war_cry()
	match state:
		St.IDLE, St.MOVE:
			_free_move(delta)
		St.ATTACK:
			_attack_update(delta)
		St.BLOCK:
			_block_update(delta)
		St.DODGE:
			_dodge_update(delta)
		St.BOW:
			_bow_update(delta)
		St.INTERACT:
			_interact_update(delta)


func aim_dir() -> Vector2:
	var a: Vector2 = inp.get("aim", global_position + facing) - global_position
	return a if a.length() > 2.0 else facing


func _free_move(delta: float) -> void:
	var mv: Vector2 = inp["move"]
	if inp["dodge"] and _start_dodge():
		return
	if weapon == "sword":
		if inp["heavy"] and heavy_cd <= 0.0 and use_stamina(25.0):
			heavy_cd = HEAVY_CD
			_start_attack(HEAVY)
			return
		if inp["attack"] or buffered > 0.0:
			_start_attack(SWORD_COMBO[combo_step])
			return
		if inp["block"]:
			set_state(St.BLOCK)
			play("block")
			return
	elif inp["attack"]:
		set_state(St.BOW)
		bow_draw = 0.0
		play("bow")
		body.pause()
		return
	if inp["interact"]:
		var it: Interactable = Game.level.find_interactable(global_position)
		if it:
			if it.hold_time <= 0.0:
				it.use(self)
			else:
				interact_target = it
				interact_progress = 0.0
				set_state(St.INTERACT)
				face(it.global_position - global_position)
				play("interact")
				return
	var running: bool = inp["run"] and mv.length() > 0.1 and stamina > 1.0
	var speed := run_speed if running else walk_speed
	if running:
		stamina = max(0.0, stamina - 16.0 * delta)
		stamina_rest = 0.0
	var accel := 900.0 if mv.length() > 0.1 else 1100.0
	move_vel = move_vel.move_toward(mv * speed, accel * delta)
	desired_velocity = move_vel
	if mv.length() > 0.1:
		face(mv)
		state = St.MOVE
		play("run" if running else "walk")
	else:
		state = St.IDLE
		play("idle")


func _start_attack(spec: Dictionary) -> void:
	set_state(St.ATTACK)
	current = spec
	hit_done = false
	buffered = 0.0
	face(aim_dir())
	move_vel = Vector2.ZERO
	if spec["anim"] != "":
		play_timed(spec["anim"], spec["dur"])
		Sfx.play("swing", -12.0)
	var idx := SWORD_COMBO.find(spec)
	if idx >= 0:
		combo_step = (idx + 1) % SWORD_COMBO.size()


func _attack_update(_delta: float) -> void:
	var t := state_time
	var spec := current
	if t < spec["hit"]:
		desired_velocity = facing * float(spec.get("lunge", 0.0)) * (1.0 - t / spec["hit"])
	if inp["attack"]:
		buffered = 0.4
	if not hit_done and t >= spec["hit"]:
		hit_done = true
		var hits := Combat.melee(self, spec["reach"], spec["arc"], spec["dmg"], spec["kb"], spec.get("heavy", false))
		var col := Color(1, 0.95, 0.8) if not spec.get("heavy", false) else Color(1, 0.75, 0.35)
		Fx.slash(self, spec["reach"], spec["arc"], col, spec.get("reverse", false), 7.0 if spec.get("heavy", false) else 5.0)
		if hits.size() > 0:
			Game.hitstop(spec["stop"])
			Game.shake(spec["shake"])
	if inp["dodge"] and t > float(spec["hit"]) + 0.04 and _start_dodge():
		return
	if t >= spec["dur"]:
		if buffered > 0.0 and weapon == "sword" and spec != HEAVY:
			_start_attack(SWORD_COMBO[combo_step])
			return
		combo_window = 0.45
		set_state(St.IDLE)


func _block_update(delta: float) -> void:
	if not inp["block"]:
		set_state(St.IDLE)
		return
	if inp["dodge"] and _start_dodge():
		return
	face(aim_dir())
	var mv: Vector2 = inp["move"]
	move_vel = move_vel.move_toward(mv * 32.0, 600.0 * delta)
	desired_velocity = move_vel
	play("block")


func _start_dodge() -> bool:
	if not use_stamina(22.0):
		return false
	var mv: Vector2 = inp["move"]
	dodge_dir = mv.normalized() if mv.length() > 0.1 else facing
	face(dodge_dir)
	set_state(St.DODGE)
	invuln = 0.28
	play_timed("dodge", 0.36)
	return true


func _dodge_update(_delta: float) -> void:
	var k: float = clamp(state_time / 0.36, 0.0, 1.0)
	desired_velocity = dodge_dir * 235.0 * (1.0 - k * k)
	if state_time >= 0.36:
		move_vel = dodge_dir * walk_speed
		set_state(St.IDLE)


func _bow_update(delta: float) -> void:
	face(aim_dir())
	bow_draw = min(1.0, bow_draw + delta / 0.55)
	var mv: Vector2 = inp["move"]
	move_vel = move_vel.move_toward(mv * 28.0, 600.0 * delta)
	desired_velocity = move_vel
	play("bow")
	body.pause()
	body.frame = 0 if bow_draw < 0.3 else (1 if bow_draw < 0.85 else 2)
	if inp["dodge"] and _start_dodge():
		return
	if not inp["attack_held"]:
		if bow_draw > 0.2:
			Combat.shoot(self, inp["aim"], 7.0 + 17.0 * bow_draw, 240.0 + 140.0 * bow_draw)
		body.frame = 3
		_start_attack(BOW_RECOVER)


func _interact_update(delta: float) -> void:
	var it := interact_target
	if not inp["interact_held"] or it == null or not is_instance_valid(it) or not it.enabled \
			or it.global_position.distance_to(global_position) > it.radius + 8.0:
		interact_target = null
		set_state(St.IDLE)
		return
	interact_progress += delta
	if interact_progress >= it.hold_time:
		interact_target = null
		set_state(St.IDLE)
		it.use(self)


func _switch_weapon() -> void:
	weapon = "bow" if weapon == "sword" else "sword"
	if weapons == null:
		set_sheet("odysseus_bow" if weapon == "bow" else "odysseus_sword")
	Fx.text(global_position + Vector2(0, -head_height), "활" if weapon == "bow" else "검", Color(1, 0.9, 0.6))
	Sfx.play("ui")


func _war_cry() -> void:
	skill_cd = SKILL_CD
	Fx.ring(global_position, 170.0, Color(1, 0.8, 0.3), 0.6)
	Fx.text(global_position + Vector2(0, -head_height - 6), "전투의 함성!", Color(1, 0.85, 0.35))
	Sfx.play("cry", -4.0)
	Game.shake(3.0)
	for a in Game.level.greeks():
		if a.global_position.distance_to(global_position) < 170.0:
			a.heal(20.0)
			a.buff_time = 8.0
	for e in Game.level.enemies():
		if e.global_position.distance_to(global_position) < 70.0:
			e.stagger(0.6)


func _update_visual() -> void:
	super._update_visual()
	if weapons:
		weapons.update()


func _draw() -> void:
	if not is_alive():
		return
	var pts := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 10.0, sin(a) * 4.5 + 1.0))
	draw_polyline(pts, Color(1.0, 0.82, 0.35, 0.8), 1.0)


func on_interrupted() -> void:
	interact_target = null
	move_vel = Vector2.ZERO


func _die() -> void:
	super._die()
	Sfx.play("death")
	await get_tree().create_timer(1.6).timeout
	Game.player_died.emit()


# ── 자동 플레이(검증용: --auto) ──────────────────────
func _bot_input() -> Dictionary:
	var out := {"move": Vector2.ZERO, "run": false, "attack": false, "attack_held": false, "block": false,
		"dodge": false, "heavy": false, "switch": false, "interact": false, "interact_held": false, "skill": false,
		"aim": global_position + facing * 20.0}
	if weapon != "sword":
		out["switch"] = true
	var foe: Actor = null
	var best := 230.0
	for e in Game.level.enemies():
		var d := global_position.distance_to(e.global_position)
		if d < best and Game.level.line_clear(global_position, e.global_position):
			best = d
			foe = e
	if foe:
		out["aim"] = foe.global_position
		if best > 24.0:
			out["move"] = nav_velocity(foe.global_position, 1.0, get_physics_process_delta_time()).normalized()
		else:
			_bot_attack_toggle = not _bot_attack_toggle
			out["attack"] = _bot_attack_toggle
			if hp < max_hp * 0.5 and skill_cd <= 0.0:
				out["skill"] = true
		return out
	var it: Interactable = Game.level.find_interactable(global_position)
	if it:
		out["interact"] = true
		out["interact_held"] = true
		return out
	if Game.quest_marker != Vector2.INF:
		var v := nav_velocity(Game.quest_marker, 1.0, get_physics_process_delta_time(), 10.0)
		out["move"] = v.normalized() if v.length() > 0.01 else Vector2.ZERO
		out["run"] = true
	return out
