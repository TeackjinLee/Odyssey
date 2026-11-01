class_name Enemy
extends Actor
## 트로이 병사. 순찰/대기 → 발견(주변 동료에게 알림) → 추적 → 공격 예고(붉게 깜빡임) → 공격 → 회복.
## 방패병은 상대가 휘두르는 걸 보면 막고, 궁수는 거리를 벌려 쏘며, 체력이 낮으면 잠깐 물러난다.
## 수비대장은 경직 저항(강공격·패링에만 경직)이 있고 세 번째 공격마다 내려찍어 주변을 친다.

const KINDS := {
	"trojan_sword": {"name": "트로이 검병", "hp": 42.0, "speed": 54.0, "reach": 21.0, "dmg": 8.0, "windup": 0.45, "dur": 0.36, "arc": 120.0, "shield": true, "cd": 1.3},
	"trojan_spear": {"name": "트로이 창병", "hp": 38.0, "speed": 52.0, "reach": 34.0, "dmg": 10.0, "windup": 0.55, "dur": 0.42, "arc": 45.0, "shield": true, "cd": 1.6},
	"trojan_archer": {"name": "트로이 궁수", "hp": 26.0, "speed": 50.0, "reach": 160.0, "dmg": 7.0, "windup": 0.65, "dur": 0.3, "arc": 0.0, "shield": false, "cd": 2.2, "ranged": true},
	"trojan_captain": {"name": "성문 수비대장 아게노르", "hp": 300.0, "speed": 50.0, "reach": 27.0, "dmg": 13.0, "windup": 0.6, "dur": 0.45, "arc": 140.0, "shield": true, "cd": 0.9, "boss": true},
}

var kind := "trojan_sword"
var cfg: Dictionary = {}
var target: Actor = null
var alerted := false
var phase := "idle"
var phase_time := 0.0
var attack_cd := 0.0
var scan := 0.0
var home := Vector2.ZERO
var patrol: Array = []
var patrol_i := 0
var strafe_sign := 1.0
var strikes := 0
var retreated := false
var aggro_range := 125.0
var hit_done := false
var slam := false
var _seen_attack := -1.0

## 한 대상을 동시에 노리는 근접 공격 수 상한 (나머지는 둘레를 돌며 기회를 본다)
const MAX_ATTACKERS := 2


func _attackers_on(t: Actor) -> int:
	var n := 0
	for e in Game.level.enemies():
		if e != self and e.target == t and (e.phase == "windup" or e.phase == "strike") and not e.cfg.get("ranged", false):
			n += 1
	return n


func setup(k: String) -> void:
	kind = k
	cfg = KINDS[k]
	sheet = k
	team = Team.TROJAN
	display_name = cfg["name"]
	max_hp = cfg["hp"]
	walk_speed = cfg["speed"]
	run_speed = cfg["speed"] * 1.45
	has_shield = cfg["shield"]
	poise = cfg.get("boss", false)
	head_height = 58.0 if poise else 46.0
	strafe_sign = 1.0 if randf() < 0.5 else -1.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	home = global_position
	attack_cd = randf_range(0.2, 0.9)


func alert(t: Actor) -> void:
	if t == null:
		return
	target = t
	if alerted:
		return
	alerted = true
	if phase == "idle":
		phase = "chase"
	if cfg.get("boss", false):
		Game.boss_changed.emit(self)
	for e in Game.level.enemies():
		if e != self and not e.alerted and e.global_position.distance_to(global_position) < 150.0:
			e.alert(t)


func think(delta: float) -> void:
	attack_cd -= delta
	phase_time += delta
	scan -= delta
	if scan <= 0.0:
		scan = 0.3
		_pick_target()
	match phase:
		"windup":
			_windup(delta)
			return
		"strike":
			_strike()
			return
		"block":
			play("block")
			if target:
				face(target.global_position - global_position)
			if phase_time > 0.6:
				_set_phase("chase")
			return
		"retreat":
			if target:
				var away := (global_position - target.global_position).normalized()
				desired_velocity = nav_velocity(global_position + away * 60.0, run_speed, delta)
				face(desired_velocity)
				play("run")
			if phase_time > 1.3:
				_set_phase("chase")
			return
	if target == null or not target.is_alive():
		target = null
		_idle_patrol(delta)
		return
	var d := Combat.ground_dist(global_position, target.global_position)
	var to := target.global_position - global_position
	# 방패병: 상대가 나를 향해 휘두르면 막는다
	if has_shield and target.state == St.ATTACK and d < 42.0 and target.facing.dot(-to.normalized()) > 0.5 and _seen_attack != target.state_time:
		_seen_attack = target.state_time
		if target.state_time < 0.12 and randf() < (0.45 if not poise else 0.3):
			_set_phase("block")
			set_state(St.BLOCK)
			return
	if hp < max_hp * 0.28 and not retreated and not poise and randf() < 0.5:
		retreated = true
		_set_phase("retreat")
		return
	if cfg.get("ranged", false):
		var los: bool = Game.level.line_clear(global_position, target.global_position, 1.0)
		var back := global_position - to.normalized() * 50.0
		var cornered: bool = Game.level.is_blocked_world(back) or not Game.level.line_clear(global_position, back, 3.0)
		if d < 75.0 and not cornered:
			desired_velocity = nav_velocity(back, walk_speed, delta)
		elif d < 75.0 and attack_cd <= 0.0:
			_start_windup()
			return
		elif d > cfg["reach"] or not los:
			desired_velocity = nav_velocity(target.global_position, walk_speed, delta)
		elif attack_cd <= 0.0:
			_start_windup()
			return
		else:
			desired_velocity = Vector2(-to.y, to.x).normalized() * 22.0 * strafe_sign
	else:
		if d > cfg["reach"] + 2.0:
			var speed: float = run_speed if d > 90.0 else walk_speed
			desired_velocity = nav_velocity(target.global_position, speed, delta, cfg["reach"] * 0.7)
		elif attack_cd <= 0.0 and _attackers_on(target) < MAX_ATTACKERS:
			_start_windup()
			return
		else:
			desired_velocity = Vector2(-to.y, to.x).normalized() * 18.0 * strafe_sign - to.normalized() * 6.0
			if randf() < 0.01:
				strafe_sign = -strafe_sign
	face(to)
	if desired_velocity.length() > 8.0:
		play("run" if desired_velocity.length() > walk_speed + 1.0 else "walk")
	else:
		play("idle")


func _pick_target() -> void:
	var best: Actor = null
	var best_d := INF
	var radius := 240.0 if alerted else aggro_range
	for a in Game.level.greeks():
		var d := global_position.distance_to(a.global_position)
		if a is Player:
			d *= 0.8
		if d < radius and d < best_d and (d < 40.0 or Game.level.line_clear(global_position, a.global_position, 1.0)):
			best_d = d
			best = a
	if best:
		if not alerted:
			alert(best)
		target = best
	elif alerted and target and not target.is_alive():
		target = null


func _idle_patrol(delta: float) -> void:
	if patrol.size() > 0:
		var goal: Vector2 = patrol[patrol_i]
		if global_position.distance_to(goal) < 8.0:
			patrol_i = (patrol_i + 1) % patrol.size()
		desired_velocity = nav_velocity(goal, walk_speed * 0.6, delta)
		face(desired_velocity)
		play("walk" if desired_velocity.length() > 4.0 else "idle")
	elif alerted:
		desired_velocity = nav_velocity(home, walk_speed, delta, 8.0)
		face(desired_velocity)
		play("walk" if desired_velocity.length() > 4.0 else "idle")
	else:
		play("idle")


func _set_phase(p: String) -> void:
	phase = p
	phase_time = 0.0
	if state != St.HIT:
		set_state(St.IDLE)


func _start_windup() -> void:
	_set_phase("windup")
	slam = poise and strikes % 3 == 2
	var anim := "heavy" if slam else ("bow" if cfg.get("ranged", false) else "attack1")
	set_state(St.ATTACK)
	play(anim, true)
	body.pause()
	body.frame = 0 if anim != "bow" else 1


func _windup(_delta: float) -> void:
	var w: float = cfg["windup"] * (1.3 if slam else 1.0)
	telegraph = clamp(phase_time / w, 0.0, 1.0)
	if target and phase_time < w * 0.6:
		face(target.global_position - global_position)
	if phase_time >= w:
		telegraph = 0.0
		_set_phase("strike")
		set_state(St.ATTACK)
		hit_done = false
		if cfg.get("ranged", false):
			body.frame = 2
		else:
			play_timed("heavy" if slam else ["attack1", "attack2", "attack3"][strikes % 3 if poise else randi() % 2], cfg["dur"] * (1.4 if slam else 1.0))
			Sfx.play("swing", -14.0)


func _strike() -> void:
	var dur: float = cfg["dur"] * (1.4 if slam else 1.0)
	if not cfg.get("ranged", false) and phase_time < dur * 0.35:
		desired_velocity = facing * 70.0 * (1.0 - phase_time / (dur * 0.35))
	if not hit_done and phase_time >= dur * 0.35:
		hit_done = true
		if cfg.get("ranged", false):
			if target and target.is_alive():
				Combat.shoot(self, target.global_position + target.velocity * 0.2, cfg["dmg"], 250.0)
			body.frame = 3
		elif slam:
			var c := global_position + facing * 14.0
			Combat.area(self, c, 46.0, cfg["dmg"] * 1.3, 200.0)
			Fx.ring(c, 46.0, Color(1, 0.6, 0.3), 0.4)
			Game.shake(5.0)
		else:
			Combat.melee(self, cfg["reach"], cfg["arc"], cfg["dmg"], 80.0)
			Fx.slash(self, cfg["reach"], cfg["arc"], Color(1, 0.45, 0.35), strikes % 2 == 1, 4.0)
	if phase_time >= dur + 0.3:
		strikes += 1
		attack_cd = cfg["cd"] * randf_range(0.8, 1.3)
		_set_phase("chase")


func on_interrupted() -> void:
	telegraph = 0.0
	if phase == "windup" or phase == "strike" or phase == "block":
		phase = "chase"
		phase_time = 0.0
		attack_cd = max(attack_cd, 0.5)


func _die() -> void:
	super._die()
	Sfx.play("death", -10.0)
	remove_from_group("enemies")
	await get_tree().create_timer(5.0).timeout
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)
