class_name Actor
extends CharacterBody2D
## 모든 인물(오디세우스·부하·트로이 병사·NPC)의 공통: 체력·스태미나, 8방향 애니메이션, 피격·방어·패링·경직·사망.
## 하위 클래스는 think(delta)에서 desired_velocity와 상태만 정한다. 위치는 발 밑(깊이 정렬 기준)이다.

signal died(actor: Actor)
signal hurt(actor: Actor, amount: float)

enum Team { GREEK, TROJAN }
enum St { IDLE, MOVE, ATTACK, BLOCK, DODGE, HIT, DEAD, DOWNED, INTERACT, BOW }

var sheet := "greek_sword"
var team: int = Team.GREEK
var display_name := ""
var max_hp := 60.0
var hp := 60.0
var max_stamina := 100.0
var stamina := 100.0
var walk_speed := 58.0
var run_speed := 100.0
var has_shield := true
var poise := false
var damage_mult := 1.0
var show_health_bar := true
var head_height := 46.0

var facing := Vector2(0, 1)
var dir := 2
var state: int = St.IDLE
var state_time := 0.0
var stagger_time := 0.0
var knock := Vector2.ZERO
var invuln := 0.0
var block_time := 0.0
var flash := 0.0
var telegraph := 0.0
var anim_base := ""
var desired_velocity := Vector2.ZERO
var stamina_rest := 0.0
var since_hurt := 99.0

var body: AnimatedSprite2D
var shadow: Sprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("actors")
	hp = max_hp
	stamina = max_stamina
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	_shape.shape = circle
	add_child(_shape)
	shadow = Sprite2D.new()
	shadow.texture = AssetLibrary.texture("res://assets/env/shadow.png")
	add_child(shadow)
	body = AnimatedSprite2D.new()
	body.centered = false
	add_child(body)
	set_sheet(sheet)
	play("idle")


func set_sheet(s: String) -> void:
	sheet = s
	if body == null:
		return
	body.sprite_frames = AssetLibrary.character_frames(s)
	body.offset = -AssetLibrary.character_anchor(s)
	if anim_base != "":
		var a := anim_base
		anim_base = ""
		play(a, true)


func is_alive() -> bool:
	return state != St.DEAD and state != St.DOWNED


func set_state(s: int) -> void:
	state = s
	state_time = 0.0


func face(v: Vector2) -> void:
	if v.length_squared() < 0.01:
		return
	facing = v.normalized()
	var nd := Iso.dir8(facing)
	if nd != dir:
		dir = nd
		_refresh_dir()


func play(anim: String, restart := false, speed := 1.0) -> void:
	anim_base = anim
	body.speed_scale = speed
	var key := "%s_%d" % [anim, dir]
	if body.animation != key or restart:
		body.play(key)


## 방향만 바뀌면 같은 프레임에서 이어 그린다.
func _refresh_dir() -> void:
	if anim_base == "" or body == null:
		return
	var key := "%s_%d" % [anim_base, dir]
	if body.animation == key:
		return
	var f := body.frame
	var p := body.frame_progress
	var playing := body.is_playing()
	body.play(key)
	body.set_frame_and_progress(f, p)
	if not playing:
		body.pause()


func anim_length(anim: String) -> float:
	var key := "%s_0" % anim
	var sf := body.sprite_frames
	return sf.get_frame_count(key) / sf.get_animation_speed(key)


## 동작을 duration초에 맞춰 재생한다.
func play_timed(anim: String, duration: float) -> void:
	play(anim, true, anim_length(anim) / max(duration, 0.05))


func _physics_process(delta: float) -> void:
	state_time += delta
	invuln = max(0.0, invuln - delta)
	flash = max(0.0, flash - delta * 6.0)
	block_time = block_time + delta if state == St.BLOCK else 0.0
	stamina_rest += delta
	update_buff(delta)
	since_hurt += delta
	if team == Team.GREEK and since_hurt > 5.0 and is_alive():
		hp = min(max_hp, hp + max_hp * 0.04 * delta)
	if stamina_rest > 0.7:
		stamina = min(max_stamina, stamina + 28.0 * delta)
	desired_velocity = Vector2.ZERO
	if state == St.HIT:
		if state_time >= stagger_time:
			set_state(St.IDLE)
	if state != St.HIT and state != St.DEAD:
		think(delta)
	knock = knock.move_toward(Vector2.ZERO, 520.0 * delta)
	velocity = desired_velocity + knock + _separation()
	move_and_slide()
	_update_visual()


func think(_delta: float) -> void:
	pass


func use_stamina(amount: float) -> bool:
	if stamina < amount * 0.5:
		return false
	stamina = max(0.0, stamina - amount)
	stamina_rest = 0.0
	return true


func _separation() -> Vector2:
	if not is_alive():
		return Vector2.ZERO
	var push := Vector2.ZERO
	for o in get_tree().get_nodes_in_group("actors"):
		if o == self or not o.is_alive():
			continue
		var d: Vector2 = global_position - o.global_position
		var l := d.length()
		if l < 13.0:
			push += (d / max(l, 0.1)) * (13.0 - l) if l > 0.1 else Vector2(randf() - 0.5, randf() - 0.5)
	return push * 7.0


func _update_visual() -> void:
	var c := Color(1, 1, 1)
	if telegraph > 0.0:
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.03)
		c = c.lerp(Color(1.9, 0.45, 0.35), telegraph * pulse)
	if flash > 0.0:
		c = c.lerp(Color(3, 3, 3), flash)
	body.modulate = c
	queue_redraw()


func _draw() -> void:
	if not show_health_bar or not is_alive() or hp >= max_hp:
		return
	var w := 20.0
	var y := -head_height - 6.0
	draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 4), Color(0, 0, 0, 0.75))
	var col := Color(0.35, 0.75, 1.0) if team == Team.GREEK else Color(0.9, 0.2, 0.18)
	draw_rect(Rect2(-w / 2, y, w * hp / max_hp, 2), col)


## 결과: "miss" "blocked" "parried" "hit" "killed"
func take_hit(dmg: float, src: Node2D, kb := 60.0, heavy := false, ranged := false) -> String:
	if not is_alive() or invuln > 0.0:
		return "miss"
	var from_dir := facing
	if src:
		from_dir = (src.global_position - global_position).normalized()
	if state == St.BLOCK and has_shield and facing.dot(from_dir) > 0.15:
		if block_time < 0.2 and not ranged and not heavy and src is Actor:
			(src as Actor).stagger(0.9)
			Fx.spark(global_position + from_dir * 8 + Vector2(0, -16), Color(1, 0.85, 0.3), 12)
			Fx.text(global_position + Vector2(0, -head_height), "패링!", Color(1, 0.85, 0.3))
			Sfx.play("parry")
			return "parried"
		var cost := 45.0 if heavy else dmg * 1.6
		stamina -= cost
		stamina_rest = 0.0
		if stamina > 0.0:
			knock = -from_dir * kb * 0.45
			Fx.spark(global_position + from_dir * 8 + Vector2(0, -16), Color(1, 0.95, 0.75), 6)
			Sfx.play("block")
			return "blocked"
		stamina = 0.0
		dmg *= 0.5
		Fx.text(global_position + Vector2(0, -head_height), "가드 붕괴", Color(1, 0.5, 0.3))
		stagger(0.75)
	hp -= dmg
	since_hurt = 0.0
	flash = 1.0
	knock = -from_dir * kb
	Fx.damage_number(global_position + Vector2(0, -head_height + 6), dmg, team == Team.GREEK)
	Fx.spark(global_position + Vector2(0, -18), Color(1, 0.4, 0.3) if team == Team.TROJAN else Color(1, 0.75, 0.6), 7)
	Sfx.play("hit_heavy" if heavy else "hit")
	hurt.emit(self, dmg)
	if hp <= 0.0:
		hp = 0.0
		_die()
		return "killed"
	if not poise or heavy:
		stagger(0.38 if heavy else 0.2)
	return "hit"


func stagger(t: float) -> void:
	if not is_alive():
		return
	telegraph = 0.0
	on_interrupted()
	set_state(St.HIT)
	stagger_time = t
	play("hit", true)


func on_interrupted() -> void:
	pass


func _die() -> void:
	telegraph = 0.0
	on_interrupted()
	set_state(St.DEAD)
	play("death", true)
	_shape.set_deferred("disabled", true)
	died.emit(self)


func heal(amount: float) -> void:
	if is_alive():
		hp = min(max_hp, hp + amount)


# ── 길찾기 이동 ────────────────────────────────────────
var buff_time := 0.0
var _path := PackedVector2Array()
var _path_goal := Vector2.INF
var _path_timer := 0.0


## goal까지 갈 속도. 직선으로 막히면 격자 A*로 돌아간다.
func nav_velocity(goal: Vector2, speed: float, delta: float, stop_dist := 4.0) -> Vector2:
	var level = Game.level
	var to := goal - global_position
	var dist := to.length()
	if dist < stop_dist:
		_path.clear()
		return Vector2.ZERO
	var arrive: float = min(speed, dist * 5.0)
	if level.line_clear(global_position, goal):
		_path.clear()
		return to / dist * arrive
	_path_timer -= delta
	if _path.is_empty() or _path_timer <= 0.0 or _path_goal.distance_to(goal) > 24.0:
		_path = level.find_path(global_position, goal)
		_path_goal = goal
		_path_timer = 0.6
	while _path.size() > 0 and global_position.distance_to(_path[0]) < 7.0:
		_path.remove_at(0)
	if _path.size() > 1 and level.line_clear(global_position, _path[1]):
		_path.remove_at(0)
	if _path.is_empty():
		return to / dist * arrive
	return (_path[0] - global_position).normalized() * speed


func update_buff(delta: float) -> void:
	if buff_time > 0.0:
		buff_time -= delta
		damage_mult = 1.35
	else:
		damage_mult = 1.0
