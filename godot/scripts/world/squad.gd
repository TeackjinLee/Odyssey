class_name Squad
extends Node
## 오디세우스의 부하 부대: 명령 상태와 진형.
## 넓은 곳에서는 오디세우스 뒤로 V자로 퍼지고, 진형 자리가 막히는 좁은 길에서는 지나온 길(trail)을 따라 한 줄로 선다.

signal mode_changed(mode: int)

enum Mode { FOLLOW, HOLD, FOCUS, REGROUP }
const MODE_NAMES := ["따라오기", "위치 사수", "집중 공격", "후퇴·집결"]
const MODE_SHOUTS := ["따라와라!", "자리를 지켜라!", "저놈을 노려라!", "물러나 모여라!"]
const WIDE_SLOTS := [Vector2(-22, -16), Vector2(-22, 16), Vector2(-40, 0), Vector2(-40, -30), Vector2(-40, 30)]

var members: Array = []
var mode: int = Mode.FOLLOW
var focus_target: Actor = null
var regroup_time := 0.0
var trail: Array = []
var heading := Vector2(0, 1)
var narrow := false
## 부대 특수 명령(5): 검병 방패벽 · 창병 창 던지기 · 궁병 일제 사격. 셋이 쿨타임 하나를 같이 쓴다
const SPECIAL_CD := 18.0
var special_cd := 0.0


func add_member(c: Companion) -> void:
	members.append(c)
	c.squad_index = members.size() - 1


func _physics_process(delta: float) -> void:
	special_cd = maxf(0.0, special_cd - delta)
	var p: Player = Game.player
	if p == null:
		return
	if trail.is_empty() or trail[0].distance_to(p.global_position) > 6.0:
		trail.push_front(p.global_position)
		if trail.size() > 48:
			trail.pop_back()
	if p.velocity.length() > 20.0:
		heading = heading.lerp(p.velocity.normalized(), 0.12).normalized()
	if mode == Mode.FOCUS and (focus_target == null or not is_instance_valid(focus_target) or not focus_target.is_alive()):
		set_mode(Mode.FOLLOW)
	if mode == Mode.REGROUP:
		regroup_time -= delta
		if regroup_time <= 0.0:
			set_mode(Mode.FOLLOW)
	narrow = _check_narrow(p)


func set_mode(m: int) -> void:
	mode = m
	mode_changed.emit(m)


func command(m: int, aim_pos: Vector2) -> void:
	var p: Player = Game.player
	match m:
		Mode.HOLD:
			for c in members:
				c.hold_anchor = c.global_position
		Mode.FOCUS:
			focus_target = _pick_focus(aim_pos, p.global_position)
			if focus_target == null:
				Game.show_hint("집중 공격할 적이 근처에 없다")
				return
			Fx.ring(focus_target.global_position, 26.0, Color(1, 0.3, 0.2), 0.5)
		Mode.REGROUP:
			regroup_time = 2.5
	set_mode(m)
	Fx.text(p.global_position + Vector2(0, -60), MODE_SHOUTS[m], Color(0.7, 0.85, 1.0))
	Sfx.play("shout", -10.0)


## 부대 특수 명령: 서 있는 부하마다 병과 기술을 쓴다(aim_pos = 조준한 곳).
func special(aim_pos: Vector2) -> void:
	var p: Player = Game.player
	var ready := members.filter(func(c): return c.state != Actor.St.DOWNED)
	if ready.is_empty():
		return
	if special_cd > 0.0:
		Game.show_hint("부대 특수 명령 준비 중 (%d초)" % ceili(special_cd))
		return
	special_cd = SPECIAL_CD
	var shouts := {}
	for c in ready:
		shouts[c.role] = true
		c.special(aim_pos)
	var words := []
	for r in ["sword", "spear", "archer"]:
		if shouts.has(r):
			words.append({"sword": "방패벽!", "spear": "창을 던져라!", "archer": "일제 사격!"}[r])
	Fx.text(p.global_position + Vector2(0, -60), " ".join(words), Color(0.7, 0.85, 1.0))
	Sfx.play("shout", -6.0)


func _pick_focus(aim_pos: Vector2, from: Vector2) -> Actor:
	var best: Actor = null
	var best_d := 90.0
	for e in Game.level.enemies():
		var d: float = e.global_position.distance_to(aim_pos)
		if d < best_d:
			best_d = d
			best = e
	if best:
		return best
	best_d = 220.0
	for e in Game.level.enemies():
		var d: float = e.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = e
	return best


func slot_for(c: Companion) -> Vector2:
	var p: Player = Game.player
	var i: int = clamp(c.squad_index, 0, WIDE_SLOTS.size() - 1)
	if narrow:
		return trail_point(20.0 + 17.0 * i)
	var o: Vector2 = WIDE_SLOTS[i]
	var side := Vector2(-heading.y, heading.x)
	return p.global_position + heading * o.x + side * o.y


func _check_narrow(p: Player) -> bool:
	var side := Vector2(-heading.y, heading.x)
	for i in min(members.size(), WIDE_SLOTS.size()):
		var o: Vector2 = WIDE_SLOTS[i]
		var s := p.global_position + heading * o.x + side * o.y
		if Game.level.is_blocked_world(s) or not Game.level.line_clear(p.global_position, s, 3.0):
			return true
	return false


func trail_point(dist: float) -> Vector2:
	var acc := 0.0
	for i in range(1, trail.size()):
		var seg: float = trail[i - 1].distance_to(trail[i])
		if acc + seg >= dist:
			return trail[i - 1].lerp(trail[i], (dist - acc) / max(seg, 0.01))
		acc += seg
	return trail[trail.size() - 1] if trail.size() > 0 else Game.player.global_position
