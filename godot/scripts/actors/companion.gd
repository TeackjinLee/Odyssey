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
		return
	attack_cd -= delta
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


func _choose_target() -> Actor:
	var sq: Squad = Game.squad
	var p: Player = Game.player
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
			Sfx.play("swing", -16.0)
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
