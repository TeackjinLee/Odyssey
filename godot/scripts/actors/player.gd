class_name Player
extends Actor
## 오디세우스. 이동·달리기, 검 3연타 + 강공격, 방패 막기(막기 직후 0.2초는 패링), 구르기, 활 조준·발사,
## 상호작용(E 길게), 전투의 함성(R), 부대 명령(1~4). 알아채지 못한 적의 뒤에서 E를 누르면 조용히 처치한다.
## 조준은 마우스를 움직이거나 누르면 마우스 쪽, Z·K·방향키를 누르면 키보드 조준(이동·바라보는 방향, 그쪽 가까운 적에 맞춤).
## 공격하는 동안 실제 판정 범위(부채꼴·화살 길)를 바닥에 그린다(draw_reach, 레벨의 sight_layer).

const SWORD_COMBO := [
	{"anim": "attack1", "dur": 0.34, "hit": 0.11, "dmg": 11.0, "reach": 27.0, "arc": 150.0, "kb": 70.0, "lunge": 120.0, "stop": 0.05, "shake": 1.5},
	{"anim": "attack2", "dur": 0.34, "hit": 0.11, "dmg": 12.0, "reach": 27.0, "arc": 150.0, "kb": 70.0, "lunge": 120.0, "stop": 0.05, "shake": 1.5, "reverse": true},
	{"anim": "attack3", "dur": 0.5, "hit": 0.22, "dmg": 19.0, "reach": 31.0, "arc": 120.0, "kb": 170.0, "lunge": 180.0, "stop": 0.09, "shake": 4.0},
]
const HEAVY := {"anim": "heavy", "dur": 0.72, "hit": 0.34, "dmg": 28.0, "reach": 35.0, "arc": 220.0, "kb": 230.0, "lunge": 120.0, "stop": 0.11, "shake": 5.0, "heavy": true}
const BOW_RECOVER := {"anim": "", "dur": 0.2, "hit": 99.0}
const TAKEDOWN := {"anim": "attack3", "dur": 0.42, "hit": 99.0, "quiet": true}
## 검을 휘두르는 소리가 들리는 거리와 그 소리로 차는 의심
const SWING_NOISE := 95.0
const SWING_SUSPICION := 0.55
const SKILL_CD := 20.0
## 미끼 던지기(C): 쿨타임, 던질 수 있는 가장 먼 거리
const DECOY_CD := 6.0
const DECOY_RANGE := 170.0
const HEAVY_CD := 1.2
## 이 키(+ 공격·방패 키)를 누르면 키보드 조준으로 바뀐다(WASD·F는 마우스와 같이 쓰므로 넣지 않음)
const KEY_AIM_KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
## 키보드 조준이 적을 찾는 거리와 반각(검 / 활·부대 명령)
const KEY_AIM_NEAR := [60.0, 70.0]
const KEY_AIM_FAR := [320.0, 40.0]
## 판정이 난 뒤 범위가 남아 사라지는 시간
const REACH_FLASH := 0.16

## 발소리 간격 남은 시간
var _step_t := 0.0
## 영양(탄수화물·단백질·지방, docs/NUTRITION.md): 체력 회복·공격력·속도에 걸린다
var nutrition := Nutrition.new()
## 달리는 중(동물이 더 멀리서 놀람, 탄수화물이 더 줆)
var running := false
## 처음 걸린 영양 효과 알림을 한 번만
var _food_warned := {}
var weapon := "sword"
var combo_step := 0
var combo_window := 0.0
var current: Dictionary = {}
var hit_done := false
var buffered := 0.0
var heavy_cd := 0.0
var skill_cd := 0.0
var decoy_cd := 0.0
var bow_draw := 0.0
var dodge_dir := Vector2.ZERO
var interact_target: Interactable = null
var interact_progress := 0.0
var move_vel := Vector2.ZERO
var inp := {}
var _bot_attack_toggle := false
var aim_mouse := false
## 키보드 조준이 맞춘 적(바닥에 표시)
var aim_lock: Actor = null
## 판정 직후 남는 범위: [spec, 남은 시간, 위치, 바라보는 방향]
var _reach_flash: Array = []
var weapons: WeaponLayer
## 연출(Game.cutscene)에서 걸어갈 자리 (INF면 제자리)
var script_goal := Vector2.INF


func _ready() -> void:
	sheet = Game.outfit if ResourceLoader.exists("res://assets/sprites/%s.png" % Game.outfit) else "odysseus_sword"
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


func _input(event: InputEvent) -> void:
	if Game.autoplay:
		return
	if event is InputEventMouseMotion:
		if event.relative.length() > 1.5:
			aim_mouse = true
	elif event is InputEventMouseButton:
		if event.pressed:
			aim_mouse = true
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_O:
		Game.set_outfit(Game.next_outfit())
	elif event is InputEventKey and event.pressed and not event.echo \
			and (event.physical_keycode in KEY_AIM_KEYS or event.is_action("attack") or event.is_action("block")):
		aim_mouse = false


func _read_input() -> void:
	if Game.cutscene:
		inp = _idle_input()
		if script_goal != Vector2.INF:
			var v := nav_velocity(script_goal, 1.0, get_physics_process_delta_time(), 6.0)
			inp["move"] = v.normalized() if v.length() > 0.01 else Vector2.ZERO
		return
	if Game.autoplay:
		inp = _bot_input()
		return
	var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var aim := get_global_mouse_position()
	aim_lock = null
	if not aim_mouse:
		aim_lock = _assist_target(mv, weapon == "bow")
		aim = aim_lock.global_position if aim_lock else global_position + _key_dir(mv) * 60.0
	inp = {
		"move": mv,
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
		"decoy": Input.is_action_just_pressed("decoy"),
		"aim": aim,
	}
	var cmds := ["cmd_follow", "cmd_hold", "cmd_focus", "cmd_regroup", "cmd_special"]
	for i in cmds.size():
		if Input.is_action_just_pressed(cmds[i]) and Game.squad:
			var at := aim
			if not aim_mouse:
				var far := _assist_target(mv, true)
				at = far.global_position if far else global_position + _key_dir(mv) * 90.0
			if i == 4:
				Game.squad.special(at)
			else:
				Game.squad.command(i, at)


func _key_dir(mv: Vector2) -> Vector2:
	return mv.normalized() if mv.length() > 0.1 else facing


## 키보드 조준: 이동(없으면 바라보는) 방향 부채꼴 안에서 가깝고 정면에 가까운 적. 멀리(활)는 가로막히지 않은 적만.
func _assist_target(mv: Vector2, far: bool) -> Actor:
	var dir := _key_dir(mv)
	var lim: Array = KEY_AIM_FAR if far else KEY_AIM_NEAR
	var best: Actor = null
	var best_score := INF
	for e in Game.level.enemies():
		var to: Vector2 = e.global_position - global_position
		var d := Combat.ground_dist(global_position, e.global_position)
		if d > lim[0]:
			continue
		var ang := absf(rad_to_deg(dir.angle_to(to)))
		if ang > lim[1] and d > 14.0:
			continue
		if far and not Game.level.line_clear(global_position, e.global_position, 2.0):
			continue
		var score := d * (1.0 + ang / 60.0)
		if score < best_score:
			best_score = score
			best = e
	return best


func think(delta: float) -> void:
	_read_input()
	_update_nutrition(delta)
	heavy_cd = max(0.0, heavy_cd - delta)
	skill_cd = max(0.0, skill_cd - delta)
	decoy_cd = max(0.0, decoy_cd - delta)
	buffered = max(0.0, buffered - delta)
	if state == St.IDLE or state == St.MOVE:
		combo_window -= delta
		if combo_window <= 0.0:
			combo_step = 0
		if inp["switch"]:
			_switch_weapon()
	if inp["skill"] and skill_cd <= 0.0 and state != St.INTERACT:
		_war_cry()
	if inp.get("decoy", false) and decoy_cd <= 0.0 and (state == St.IDLE or state == St.MOVE):
		_throw_decoy()
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
				if state == St.ATTACK:
					return
			else:
				interact_target = it
				interact_progress = 0.0
				set_state(St.INTERACT)
				face(it.global_position - global_position)
				play("interact")
				return
	running = inp["run"] and mv.length() > 0.1 and stamina > 1.0
	var speed := (run_speed if running else walk_speed) * nutrition.speed_mult()
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
		# 발소리: 달리면 크게(적도 듣는다), 걸으면 아주 작게
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.27 if running else 0.42
			Sfx.play("step", -13.0 if running else -26.0)
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
		if not spec.get("quiet", false):
			Sfx.play("swing_heavy" if spec.get("heavy", false) or spec == SWORD_COMBO[2] else "swing", -10.0)
			Game.level.noise(global_position, SWING_NOISE, SWING_SUSPICION)
	var idx := SWORD_COMBO.find(spec)
	if idx >= 0:
		combo_step = (idx + 1) % SWORD_COMBO.size()
	if spec.get("heavy", false):
		nutrition.spend("protein", Nutrition.PROTEIN_HEAVY)
	elif spec["anim"] != "" and spec.get("dmg", 0.0) > 0.0:
		nutrition.spend("protein", Nutrition.PROTEIN_SWING)


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
		_reach_flash = [spec, REACH_FLASH, global_position, facing]
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
	Fx.anim("dust", global_position, dodge_dir.x < 0.0, 4)
	Sfx.play("swing", -18.0)
	Sfx.play("step", -12.0)
	return true


func _dodge_update(_delta: float) -> void:
	var k: float = clamp(state_time / 0.36, 0.0, 1.0)
	desired_velocity = dodge_dir * 235.0 * nutrition.speed_mult() * (1.0 - k * k)
	if state_time >= 0.36:
		move_vel = dodge_dir * walk_speed * nutrition.speed_mult()
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
			nutrition.spend("protein", Nutrition.PROTEIN_SHOT)
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


# ── 영양 ──────────────────────────────────────────────
func _update_nutrition(delta: float) -> void:
	if not is_alive() or Game.cutscene:
		return
	var fighting := since_hurt < 4.0 or state in [St.ATTACK, St.BLOCK, St.DODGE, St.BOW]
	nutrition.tick(delta, running and state == St.MOVE, fighting)
	if nutrition.starving() and hp > max_hp * Nutrition.STARVE_FLOOR:
		hp = maxf(max_hp * Nutrition.STARVE_FLOOR, hp - Nutrition.STARVE_HP * delta)
	for eff in nutrition.effects():
		if not _food_warned.has(eff):
			_food_warned[eff] = true
			Game.show_hint(Lines.t("food.warn_" + {"굶주림": "starve", "배고픔": "hungry", "힘 빠짐": "weak", "무거움": "heavy"}[eff]))


## 음식 먹기(FoodSource가 부른다): 오른 양을 머리 위에 띄운다
func eat(food_id: String) -> void:
	var f := Nutrition.food(food_id)
	if f.is_empty():
		return
	var r := nutrition.eat(f)
	var parts := []
	for k in [["carb", "탄"], ["protein", "단"], ["fat", "지"]]:
		if r[k[0]] > 0.0:
			parts.append("+%s %d" % [k[1], roundi(r[k[0]])])
	Fx.text(global_position + Vector2(0, -head_height - 4), " · ".join(parts), Color(0.95, 0.9, 0.6))
	if r["to_fat"] >= 1.0:
		Fx.text(global_position + Vector2(0, -head_height - 16), "넘쳐서 지방 +%d" % roundi(r["to_fat"]), Color(0.95, 0.85, 0.7))
	Sfx.play("eat", -6.0)
	Game.stats["meals"] = Game.stats.get("meals", 0) + 1


func use_stamina(amount: float) -> bool:
	var ok := super.use_stamina(amount)
	if ok:
		nutrition.spend("carb", amount * Nutrition.CARB_PER_STAMINA)
	return ok


func regen_mult() -> float:
	return nutrition.regen_mult()


func update_buff(delta: float) -> void:
	super.update_buff(delta)
	damage_mult *= nutrition.power_mult()


func takedown(e: Enemy) -> void:
	face(e.global_position - global_position)
	_start_attack(TAKEDOWN)
	e.silent_kill(true)


## 옷 갈아입기: 몸 시트만 바꾼다(손 위치 표·무기 겹치기는 시트에서 읽는다)
func wear(outfit: String) -> void:
	if weapons != null:
		set_sheet(outfit)
		Fx.text(global_position + Vector2(0, -head_height), "옷 갈아입음", Color(1, 0.9, 0.6))


func _switch_weapon() -> void:
	weapon = "bow" if weapon == "sword" else "sword"
	if weapons == null:
		set_sheet("odysseus_bow" if weapon == "bow" else "odysseus_sword")
	Fx.text(global_position + Vector2(0, -head_height), "활" if weapon == "bow" else "검", Color(1, 0.9, 0.6))
	Sfx.play("switch", -8.0)


func _war_cry() -> void:
	skill_cd = SKILL_CD
	if not Fx.anim("shout", global_position, false, 5):
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


## 미끼 던지기: 조준한 쪽(가장 멀리 DECOY_RANGE)으로 돌멩이를 던진다. 막힌 칸이면 그 앞에 떨어진다.
func _throw_decoy() -> void:
	decoy_cd = DECOY_CD
	var to: Vector2 = inp["aim"]
	var v := to - global_position
	if v.length() < 30.0:
		v = facing * 110.0
	to = global_position + v.limit_length(DECOY_RANGE)
	var steps := 12
	for i in range(1, steps + 1):
		var p := global_position.lerp(to, float(i) / steps)
		if Game.level.is_blocked_world(p):
			to = global_position.lerp(to, float(i - 1) / steps)
			break
	face(to - global_position)
	Skills.throw_decoy(global_position + Vector2(0, -2), to)


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


# ── 공격 범위 그리기 ──────────────────────────────────
## 레벨의 sight_layer(바닥 위, 인물 아래)가 매 프레임 부른다. Combat.melee와 같은 모양:
## 땅 거리(reach + 5) 안의 부채꼴(arc) + 방향과 상관없이 맞는 발밑 9px. 판정 전에는 안쪽이 차오르고, 판정 순간 밝게 번쩍인다.
func draw_reach(ci: CanvasItem) -> void:
	if not is_alive():
		return
	if _reach_flash.size() > 0:
		_reach_flash[1] -= get_process_delta_time()
		if _reach_flash[1] <= 0.0:
			_reach_flash = []
		else:
			var k: float = _reach_flash[1] / REACH_FLASH
			_draw_fan(ci, _reach_flash[0], _reach_flash[2], _reach_flash[3], 1.0, 0.55 * k, 1.0 * k)
	if state == St.ATTACK and current.has("reach") and not hit_done:
		var p: float = clamp(state_time / float(current["hit"]), 0.0, 1.0)
		_draw_fan(ci, current, global_position, facing, 1.0, 0.12, 0.85)
		_draw_fan(ci, current, global_position, facing, p, 0.18 + 0.22 * p, 0.0)
	if state == St.BOW:
		_draw_arrow_path(ci)
	if aim_lock and is_instance_valid(aim_lock) and aim_lock.is_alive():
		var blink := 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.01)
		_draw_ellipse(ci, aim_lock.global_position, 12.0, Color(1.0, 0.45, 0.25, blink), false)


func _draw_fan(ci: CanvasItem, spec: Dictionary, o: Vector2, dir: Vector2, scale_k: float, fill_a: float, edge_a: float) -> void:
	var heavy: bool = spec.get("heavy", false)
	var col := Color(1.0, 0.62, 0.25) if heavy else Color(1.0, 0.9, 0.62)
	var r: float = (float(spec["reach"]) + 5.0) * scale_k
	var arc := deg_to_rad(float(spec["arc"]))
	var n := int(ceil(spec["arc"] / 10.0))
	var pts := PackedVector2Array([o])
	for i in n + 1:
		var a := dir.angle() + arc * (float(i) / n - 0.5)
		var dv := Vector2(cos(a), sin(a))
		pts.append(o + dv * r / Vector2(dv.x, dv.y * Combat.Y_STRETCH).length())
	if fill_a > 0.0:
		ci.draw_colored_polygon(pts, Color(col, fill_a))
		_draw_ellipse(ci, o, 9.0 * scale_k, Color(col, fill_a), true)
	if edge_a > 0.0:
		# 밝은 바닥에서도 보이게 어두운 테두리를 먼저 깐다
		pts.append(o)
		ci.draw_polyline(pts, Color(0, 0, 0, 0.45 * edge_a), 2.5)
		ci.draw_polyline(pts, Color(col, edge_a), 1.0)


## 땅 거리 r인 타원(쿼터뷰라 세로가 1/Y_STRETCH)
func _draw_ellipse(ci: CanvasItem, o: Vector2, r: float, col: Color, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 21:
		var a := TAU * i / 20.0
		pts.append(o + Vector2(cos(a) * r, sin(a) * r / Combat.Y_STRETCH))
	if filled:
		ci.draw_colored_polygon(pts, col)
	else:
		ci.draw_polyline(pts, col, 1.0)


## 활: 지금 놓으면 화살이 날아갈 길(속도 × 수명, 벽에서 끊김)과 맞는 폭(땅 거리 9px). 많이 당길수록 길고 진하다.
func _draw_arrow_path(ci: CanvasItem) -> void:
	var dir: Vector2 = (inp["aim"] - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = facing
	var o := global_position + dir * 8.0
	var length: float = Game.level.ray_len(o, dir, (240.0 + 140.0 * bow_draw) * Projectile.LIFE)
	var side := dir.orthogonal()
	var w := 9.0 / Vector2(side.x, side.y * Combat.Y_STRETCH).length()
	var col := Color(0.85, 0.85, 0.75).lerp(Color(1.0, 0.8, 0.35), bow_draw)
	var end := o + dir * length
	var strip := PackedVector2Array([o + side * w, end + side * w, end - side * w, o - side * w])
	ci.draw_colored_polygon(strip, Color(col, 0.06 + 0.14 * bow_draw))
	ci.draw_line(o + side * w, end + side * w, Color(col, 0.3 + 0.4 * bow_draw), 1.0)
	ci.draw_line(o - side * w, end - side * w, Color(col, 0.3 + 0.4 * bow_draw), 1.0)
	ci.draw_line(end + side * w, end - side * w, Color(col, 0.5 + 0.4 * bow_draw), 1.0)


func on_interrupted() -> void:
	interact_target = null
	move_vel = Vector2.ZERO


func _die() -> void:
	super._die()
	Sfx.play("death")
	Bgm.sting("defeat")
	await get_tree().create_timer(1.6).timeout
	Game.player_died.emit()


# ── 자동 플레이(검증용: --auto) ──────────────────────
## 아무것도 누르지 않은 입력
func _idle_input() -> Dictionary:
	return {"move": Vector2.ZERO, "run": false, "attack": false, "attack_held": false, "block": false,
		"dodge": false, "heavy": false, "switch": false, "interact": false, "interact_held": false, "skill": false,
		"decoy": false, "aim": global_position + facing * 20.0}


func _bot_input() -> Dictionary:
	var out := _idle_input()
	if Game.stealth_bot:
		var sneak := _bot_sneak(out)
		if not sneak.is_empty():
			return sneak
	if weapon != "sword":
		out["switch"] = true
	var foe: Actor = null
	var best := 230.0
	for e in Game.level.enemies():
		var d := global_position.distance_to(e.global_position)
		# 알아채지 못한 적에게는 먼저 덤비지 않는다(지나가다 들키면 싸움). 부하가 모이면 보스(조용히 처치 불가)에게는 덤빈다
		if not e.alerted and d > 50.0 and not (e.poise and Game.squad.members.size() > 0):
			continue
		if d < best and Game.level.line_clear(global_position, e.global_position):
			best = d
			foe = e
	if foe:
		out["aim"] = foe.global_position
		# 알아챈 적이 셋 이상 모이면 부대 특수 명령을 쓴다(봇 검증용으로 기술 경로를 돌려 봄)
		if Game.squad and Game.squad.special_cd <= 0.0 and not Game.squad.members.is_empty():
			var crowd: Array = Game.level.enemies().filter(func(e): return e.alerted and e.global_position.distance_to(foe.global_position) < 90.0)
			if crowd.size() >= 3:
				Game.squad.special(foe.global_position)
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
		out["run"] = not Game.stealth_bot
	return out


## 잠입 봇(--auto=stealth): 알아채지 못한 적(보스 제외)이 보이면 뒤에서 E, 아니면 시야 밖에서 활로 쏜다.
## 시야 안 보이는 거리에 들면 물러난다. 할 일이 없으면 빈 사전(기본 봇이 이어서 움직임).
func _bot_sneak(out: Dictionary) -> Dictionary:
	var foe: Enemy = null
	var best := 420.0
	for e in Game.level.enemies():
		if e.alerted or e.poise:
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best and Game.level.line_clear(global_position, e.global_position, 2.0):
			best = d
			foe = e
	if foe == null:
		return {}
	var it: Interactable = Game.level.find_interactable(global_position)
	if it and it.get_parent() is Enemy:
		out["interact"] = true
		return out
	if weapon != "bow":
		out["switch"] = true
		return out
	out["aim"] = foe.global_position + foe.velocity * (best / 380.0)
	if state == St.BOW:
		out["attack_held"] = bow_draw < 0.95
		return out
	var to_me := global_position - foe.global_position
	var seen_zone: bool = absf(rad_to_deg(foe.facing.angle_to(to_me))) < Enemy.VIEW_ARC * 0.5 + 10.0 \
			and Combat.ground_dist(foe.global_position, global_position) < foe.sight_range(global_position) + 15.0
	if seen_zone:
		out["move"] = to_me.normalized()
		return out
	out["attack"] = true
	out["attack_held"] = true
	return out
