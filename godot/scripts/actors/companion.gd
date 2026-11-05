class_name Companion
extends Actor
## 오디세우스의 부하(검병·창병·궁병). 부대 명령에 따라 따라오기/사수/집중/후퇴하고, 적을 보면 알아서 싸운다.
## 검병은 방패로 적의 공격 예고를 보고 막고, 창병은 근처 방패병 뒤에 서서 긴 창으로 찌른다.
## 체력이 0이 되면 죽지 않고 쓰러지며, 오디세우스가 E를 길게 눌러 일으킬 수 있다.

const ROLES := {
	"sword": {"sheet": "greek_sword", "hp": 75.0, "reach": 21.0, "dmg": 7.0, "cd": 0.85, "dur": 0.36, "hit": 0.13, "arc": 130.0, "anims": ["attack1", "attack2"]},
	"spear": {"sheet": "greek_spear", "hp": 62.0, "reach": 35.0, "dmg": 8.0, "cd": 1.05, "dur": 0.42, "hit": 0.18, "arc": 50.0, "anims": ["attack1", "attack2"]},
	"archer": {"sheet": "greek_archer", "hp": 48.0, "reach": 150.0, "dmg": 7.0, "cd": 1.6, "dur": 0.6, "hit": 0.45, "arc": 0.0, "anims": ["bow"]},
}
const ROLE_NAMES := {"sword": "검병", "spear": "창병", "archer": "궁병"}

var role := "sword"
var portrait := ""
var squad_index := 0
var independent := false
var hold_anchor := Vector2.ZERO
var target: Actor = null
var attack_cd := 0.0
var retarget := 0.0
var cfg: Dictionary = {}
var hit_done := false
var anim_i := 0
var block_left := 0.0
var _seen_windup: Actor = null
var revive_point: Interactable
## 방패벽: 남은 시간과 막는 방향(그동안 제자리에서 방패를 세우고 화살·정면 공격을 막는다)
var wall_time := 0.0
var wall_dir := Vector2.ZERO
const WALL_TIME := 5.0
## 창 던지기: 조준한 곳 가까이의 적을 찾는 거리, 피해
const JAVELIN_RANGE := 230.0
const JAVELIN_DMG := 22.0
## 로토스(챕터 2): 열매 쪽으로 걸어감 → 먹고 고향을 잊음(명령을 듣지 않고 그 자리에 앉아 있음) → 오디세우스가 끌고 감(묶여서 무조건 따라옴)
enum Lotus { NONE, LURED, DAZED, BOUND }
var lotus := Lotus.NONE
var lotus_goal := Vector2.ZERO
var drag_point: Interactable
var _mutter_t := 0.0


func setup(r: String, who: String) -> void:
	role = r
	display_name = who
	cfg = ROLES[r]
	sheet = cfg["sheet"]
	portrait = "res://assets/ui/portrait_%s.png" % cfg["sheet"]
	max_hp = cfg["hp"]
	has_shield = r != "archer"
	walk_speed = 66.0
	run_speed = 112.0
	team = Team.GREEK


func _ready() -> void:
	super._ready()
	hold_anchor = global_position


func think(delta: float) -> void:
	if state == St.DOWNED:
		if wall_time > 0.0:
			_end_wall()
		return
	if lotus == Lotus.LURED or lotus == Lotus.DAZED:
		_lotus_think(delta)
		return
	attack_cd -= delta
	if wall_time > 0.0:
		wall_time -= delta
		desired_velocity = Vector2.ZERO
		face(wall_dir)
		state = St.BLOCK
		stamina = max_stamina
		play("block")
		if wall_time <= 0.0:
			_end_wall()
		return
	if state == St.ATTACK:
		_attack_update()
		return
	if state == St.BLOCK:
		block_left -= delta
		if target and is_instance_valid(target):
			face(target.global_position - global_position)
		play("block")
		if block_left <= 0.0:
			set_state(St.IDLE)
		return
	retarget -= delta
	if retarget <= 0.0 or (target and not target.is_alive()):
		target = _choose_target()
		retarget = 0.3
	var sq: Squad = Game.squad
	var mode: int = Squad.Mode.HOLD if independent else sq.mode
	if lotus == Lotus.BOUND:
		mode = Squad.Mode.FOLLOW
		_mutter(delta, "lotus_bound")
	var goal: Vector2
	var speed := walk_speed
	if target:
		var d := Combat.ground_dist(global_position, target.global_position)
		if has_shield and target.telegraph > 0.35 and target.get("target") == self and d < 40.0 and _seen_windup != target:
			_seen_windup = target
			if randf() < 0.65:
				block_left = 0.6
				set_state(St.BLOCK)
				return
		if target.telegraph <= 0.0 and _seen_windup == target:
			_seen_windup = null
		if attack_cd <= 0.0 and d <= cfg["reach"] + 2.0 and (role != "archer" or Game.level.line_clear(global_position, target.global_position, 1.0)):
			_start_attack()
			return
		goal = _engage_goal(target, d)
		speed = run_speed if d > 70.0 else walk_speed
	else:
		match mode:
			Squad.Mode.HOLD:
				goal = hold_anchor
			_:
				goal = sq.slot_for(self)
		var gd := global_position.distance_to(goal)
		speed = run_speed if gd > 46.0 or mode == Squad.Mode.REGROUP else walk_speed
	desired_velocity = nav_velocity(goal, speed, delta, 5.0)
	if desired_velocity.length() > 8.0:
		face(desired_velocity if not target else target.global_position - global_position)
		play("run" if speed > walk_speed + 1.0 else "walk")
	else:
		if target:
			face(target.global_position - global_position)
		elif Game.player:
			face(Game.player.facing)
		play("idle")


## 부대 특수 명령(Squad.special): 병과마다 기술 하나.
func special(aim_pos: Vector2) -> void:
	match role:
		"sword":
			wall_time = WALL_TIME
			wall_dir = (aim_pos - global_position).normalized()
			if wall_dir == Vector2.ZERO:
				wall_dir = facing
			add_to_group("shield_wall")
			if not Fx.anim("shield_glint", global_position + wall_dir * 6.0 + Vector2(0, -14)):
				Fx.ring(global_position, 18.0, Color(0.6, 0.8, 1.0), 0.4)
		"spear":
			var best: Actor = null
			var best_d := JAVELIN_RANGE
			for e in Game.level.enemies():
				var d := global_position.distance_to(e.global_position)
				if d < best_d and e.global_position.distance_to(aim_pos) < 120.0 \
						and Game.level.line_clear(global_position, e.global_position, 1.0):
					best_d = d
					best = e
			if best:
				face(best.global_position - global_position)
				play_timed("attack1", 0.4)
				Combat.shoot(self, best.global_position + best.velocity * 0.2, JAVELIN_DMG, 340.0, true)
		"archer":
			face(aim_pos - global_position)
			play_timed("bow", 0.6)
			Skills.volley(self, aim_pos, Game.level.get("armory_burned") == true)


func _end_wall() -> void:
	wall_time = 0.0
	remove_from_group("shield_wall")
	if state == St.BLOCK:
		set_state(St.IDLE)


func _choose_target() -> Actor:
	var sq: Squad = Game.squad
	var p: Player = Game.player
	if lotus != Lotus.NONE:
		return null
	if not independent:
		if sq.mode == Squad.Mode.REGROUP:
			return null
		if sq.mode == Squad.Mode.FOCUS and sq.focus_target and sq.focus_target.is_alive():
			return sq.focus_target
	var hold := independent or sq.mode == Squad.Mode.HOLD
	var best: Actor = null
	var best_d := INF
	for e in Game.level.enemies():
		# 잠입 중엔 먼저 덤비지 않는다: 알아챈 적만 (알아채지 못한 적은 집중 공격 명령으로만)
		if not e.alerted:
			continue
		var ep: Vector2 = e.global_position
		var d := global_position.distance_to(ep)
		var ok := false
		if hold:
			ok = ep.distance_to(hold_anchor) < 90.0 or (role == "archer" and d < 150.0)
		else:
			ok = d < 120.0 or (p and ep.distance_to(p.global_position) < 150.0)
		if ok and d < best_d and (d < 40.0 or Game.level.line_clear(global_position, ep, 2.0)):
			best_d = d
			best = e
	return best


func _engage_goal(t: Actor, d: float) -> Vector2:
	var away := global_position - t.global_position
	away = away.normalized() if away.length() > 0.5 else -t.facing
	match role:
		"spear":
			for a in Game.level.greeks():
				if a == self or not a.has_shield:
					continue
				var shield_pos: Vector2 = a.global_position
				if shield_pos.distance_to(t.global_position) < 34.0:
					return shield_pos + (shield_pos - t.global_position).normalized() * 13.0
			return t.global_position + away * 28.0
		"archer":
			if d < 80.0:
				return t.global_position + away * 125.0
			if d > 145.0 or not Game.level.line_clear(global_position, t.global_position, 1.0):
				return t.global_position + away * 120.0
			return global_position
	return t.global_position + away * 17.0


func _start_attack() -> void:
	set_state(St.ATTACK)
	hit_done = false
	face(target.global_position - global_position)
	var anims: Array = cfg["anims"]
	anim_i = (anim_i + 1) % anims.size()
	play_timed(anims[anim_i], cfg["dur"])


func _attack_update() -> void:
	var t := state_time
	if role != "archer" and t < cfg["hit"]:
		desired_velocity = facing * 60.0 * (1.0 - t / cfg["hit"])
	if not hit_done and t >= cfg["hit"]:
		hit_done = true
		if role == "archer":
			if target and target.is_alive():
				Combat.shoot(self, target.global_position + target.velocity * 0.25, cfg["dmg"], 260.0)
		else:
			Combat.melee(self, cfg["reach"], cfg["arc"], cfg["dmg"], 55.0)
			Fx.slash(self, cfg["reach"], cfg["arc"], Color(0.75, 0.85, 1.0), anim_i == 1, 4.0)
			Sfx.at("swing", global_position, -16.0)
	if t >= cfg["dur"]:
		attack_cd = cfg["cd"] * randf_range(0.8, 1.25)
		set_state(St.IDLE)


func _die() -> void:
	telegraph = 0.0
	set_state(St.DOWNED)
	play("downed", true)
	_shape.set_deferred("disabled", true)
	Game.stats["downs"] += 1
	Fx.text(global_position + Vector2(0, -40), "%s 쓰러짐" % display_name, Color(1, 0.5, 0.45))
	revive_point = Interactable.new()
	revive_point.label = "%s 일으키기" % display_name
	revive_point.hold_time = 1.2
	revive_point.on_use = func(_by): revive()
	add_child(revive_point)
	died.emit(self)


## 챕터 2부터: 배의 식량 창고로 채우는 배부름(Rations)이 낮으면 회복·공격력이 준다
func regen_mult() -> float:
	var r = Game.level.get("rations") if Game.level else null
	return r.crew_regen() if r else 1.0


func update_buff(delta: float) -> void:
	super.update_buff(delta)
	var r = Game.level.get("rations") if Game.level else null
	if r:
		damage_mult *= r.crew_power()


func revive(ratio := 0.5) -> void:
	if state != St.DOWNED:
		return
	hp = max_hp * ratio
	set_state(St.IDLE)
	_shape.set_deferred("disabled", false)
	play("idle", true)
	Fx.text(global_position + Vector2(0, -46), "다시 일어섰다", Color(0.6, 1, 0.6))
	if revive_point:
		revive_point.queue_free()
		revive_point = null


# ── 로토스 ────────────────────────────────────────────
## 로토스 열매 쪽으로 걸어가게 한다(goal = 앉을 자리)
func lure(goal: Vector2) -> void:
	lotus = Lotus.LURED
	lotus_goal = goal
	target = null
	if wall_time > 0.0:
		_end_wall()
	if state == St.ATTACK or state == St.BLOCK:
		set_state(St.IDLE)


func _lotus_think(delta: float) -> void:
	if lotus == Lotus.LURED:
		desired_velocity = nav_velocity(lotus_goal, walk_speed, delta, 5.0)
		if desired_velocity.length() > 8.0:
			face(desired_velocity)
			play("walk")
		if global_position.distance_to(lotus_goal) < 10.0:
			_daze()
		return
	desired_velocity = Vector2.ZERO
	play("sit" if body.sprite_frames.has_animation("sit_%d" % dir) else "idle")   # 그려 받은 앉은 동작(열매 먹기)이 있으면
	_mutter(delta, "lotus_dazed")


func _daze() -> void:
	lotus = Lotus.DAZED
	Sfx.at("eat", global_position, -8.0)
	Fx.text(global_position + Vector2(0, -44), "로토스를 먹었다", Color(0.95, 0.75, 0.95))
	drag_point = Interactable.new()
	drag_point.label = "%s 끌고 가기" % display_name
	drag_point.hold_time = 1.5
	drag_point.on_use = func(_by): bind()
	add_child(drag_point)
	if Game.level and Game.level.has_method("on_crew_dazed"):
		Game.level.on_crew_dazed(self)


## 오디세우스가 붙잡아 끌고 간다: 묶인 채 무조건 따라온다(로토스에 다시 끌리지 않음)
func bind() -> void:
	if lotus != Lotus.DAZED:
		return
	lotus = Lotus.BOUND
	if drag_point:
		drag_point.queue_free()
		drag_point = null
	Sfx.play("cry", -10.0)
	_mutter_t = 0.0
	_mutter(0.0, "lotus_bound")
	if Game.level and Game.level.has_method("on_crew_bound"):
		Game.level.on_crew_bound(self)


## 배에 묶어 태웠다 — 다시 보통 부하
func clear_lotus() -> void:
	lotus = Lotus.NONE
	if drag_point:
		drag_point.queue_free()
		drag_point = null


## 고향을 잊은 부하가 이따금 중얼거린다(글은 지금 챕터 글의 mutter.<이름> 목록에서 고름)
func _mutter(delta: float, key: String) -> void:
	_mutter_t -= delta
	if _mutter_t > 0.0:
		return
	_mutter_t = randf_range(4.0, 7.0)
	var lines: Array = Lines.list("mutter." + key)
	if not lines.is_empty():
		Fx.text(global_position + Vector2(0, -50), String(lines.pick_random()), Color(0.95, 0.8, 0.95))
