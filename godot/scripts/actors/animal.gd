class_name Animal
extends Node2D
## 사냥감(docs/NUTRITION.md §4.2): 집 둘레를 어슬렁거리다가 오디세우스가 다가오거나(달리면 더 멀리서) 맞으면 달아난다.
## 놀라면 울어서 주변 보초가 의심한다. 잡으면 그 자리에 고기(FoodSource)가 남는다.
## 그룹 "animals" — Combat이 오디세우스·부하(그리스)의 공격에만 넣는다. 적·부하 AI는 신경 쓰지 않는다.
## 그림은 아직 코드로 그린 임시 그림(_draw). 받으면 assets/sprites/animal_<종류>.png로 바꾼다(ART_PLAN C-ANI-*).

const KINDS := {
	"chicken": {"hp": 8.0, "walk": 22.0, "flee": 92.0, "scare": 60.0, "food": "chicken", "cry": "cluck", "size": 1.4},
	"goat": {"hp": 28.0, "walk": 18.0, "flee": 100.0, "scare": 75.0, "food": "goat", "cry": "bleat", "size": 1.6},
	"sheep": {"hp": 30.0, "walk": 16.0, "flee": 80.0, "scare": 70.0, "food": "sheep", "cry": "bleat", "size": 1.7},
	"boar": {"hp": 60.0, "walk": 20.0, "flee": 105.0, "scare": 80.0, "food": "boar", "cry": "bleat", "size": 1.8},
	"deer": {"hp": 34.0, "walk": 20.0, "flee": 125.0, "scare": 110.0, "food": "deer", "cry": "bleat", "size": 1.9},
}
## 놀라 울 때 보초가 듣는 거리·의심 양
const CRY_RADIUS := 100.0
const CRY_SUSPICION := 0.35

var kind := "chicken"
var cfg: Dictionary = {}
var team := -1
var hp := 8.0
var home := Vector2.ZERO
var wander_radius := 50.0
var _goal := Vector2.ZERO
var _wait := 0.0
var _flee_t := 0.0
var _flee_from := Vector2.ZERO
var _knock := Vector2.ZERO
var _flash := 0.0
var _t := 0.0
var _left := false
var _moving := false
var _cry_cd := 0.0
var _dead := false


func setup(k: String) -> Animal:
	kind = k
	cfg = KINDS[k]
	hp = cfg["hp"]
	return self


func _ready() -> void:
	add_to_group("animals")
	home = global_position
	_goal = home
	_wait = randf_range(0.5, 2.5)
	_t = randf() * 10.0


func is_alive() -> bool:
	return not _dead


## Actor.take_hit과 같은 모양(Combat·화살이 부른다)
func take_hit(dmg: float, src = null, kb := 60.0, _heavy := false, _ranged := false) -> String:
	if _dead:
		return "miss"
	hp -= dmg
	_flash = 1.0
	var from: Vector2 = src.global_position if src and is_instance_valid(src) else global_position - Vector2(1, 0)
	_knock = (global_position - from).normalized() * kb * 0.6
	Fx.impact("hit", global_position + Vector2(0, -6), Color(1, 0.5, 0.4), 5)
	_scare(from)
	if hp <= 0.0:
		_die()
		return "killed"
	return "hit"


func _scare(from: Vector2) -> void:
	_flee_from = from
	_flee_t = 2.5
	if _cry_cd <= 0.0:
		_cry_cd = 2.0
		Sfx.at(cfg["cry"], global_position, -8.0)
		if Game.level:
			Game.level.noise(global_position, CRY_RADIUS, CRY_SUSPICION)


func _die() -> void:
	_dead = true
	remove_from_group("animals")
	var meat := FoodSource.new().setup(cfg["food"], "meat")
	meat.position = position
	get_parent().add_child(meat)
	Sfx.at(cfg["cry"], global_position, -6.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 6.0)
	_cry_cd -= delta
	if _dead:
		queue_redraw()
		return
	var p: Node2D = Game.player
	if p and is_instance_valid(p) and p.is_alive():
		var d := global_position.distance_to(p.global_position)
		var scare: float = cfg["scare"] * (1.6 if p.get("running") else 1.0)
		if d < scare:
			_scare(p.global_position)
	var vel := Vector2.ZERO
	if _flee_t > 0.0:
		_flee_t -= delta
		var away := (global_position - _flee_from).normalized()
		# 이리저리 꺾으며 달아남
		away = away.rotated(sin(_t * 5.0) * 0.6)
		vel = away * cfg["flee"]
		if _flee_t <= 0.0:
			home = global_position
			_goal = home
			_wait = 1.0
	else:
		_wait -= delta
		if _wait <= 0.0 and global_position.distance_to(_goal) < 3.0:
			_goal = home + Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5)) * wander_radius
			_wait = randf_range(1.5, 4.0)
		if _wait <= 0.0 or global_position.distance_to(_goal) >= 3.0:
			var to := _goal - global_position
			if to.length() > 2.0:
				vel = to.normalized() * cfg["walk"]
	vel += _knock
	_knock = _knock.move_toward(Vector2.ZERO, 300.0 * delta)
	_moving = vel.length() > 4.0
	if _moving:
		_left = vel.x < 0.0
		var next := global_position + vel * delta
		if Game.level and Game.level.is_blocked_world(next):
			# 막히면 미끄러지듯 한 축만, 그것도 막히면 방향을 바꿈
			var nx := global_position + Vector2(vel.x, 0) * delta
			var ny := global_position + Vector2(0, vel.y) * delta
			if not Game.level.is_blocked_world(nx):
				next = nx
			elif not Game.level.is_blocked_world(ny):
				next = ny
			else:
				next = global_position
				_goal = home
				_flee_from = global_position + vel
		global_position = next
	queue_redraw()


func _draw() -> void:
	var s: float = cfg.get("size", 1.0)
	var f := -1.0 if _left else 1.0
	var bob := absf(sin(_t * (14.0 if _flee_t > 0.0 else 8.0))) * (1.5 if _moving else 0.0)
	var tint := Color(1, 1, 1).lerp(Color(1, 0.4, 0.4), _flash)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s * f, s))
	draw_circle(Vector2(0, 0), 6.0, Color(0, 0, 0, 0.25))
	var o := Vector2(0, -bob)
	if kind == "chicken":
		var leg := 1.0 if _moving and fmod(_t * 8.0, 1.0) > 0.5 else 0.0
		draw_line(Vector2(-1, -1), Vector2(-1 - leg, 0), Color(0.9, 0.6, 0.2), 1.0)
		draw_line(Vector2(1, -1), Vector2(1 + leg, 0), Color(0.9, 0.6, 0.2), 1.0)
		draw_circle(o + Vector2(0, -5), 4.2, Color(0.15, 0.1, 0.08))
		draw_circle(o + Vector2(0, -5), 3.5, Color(0.92, 0.88, 0.8) * tint)
		draw_circle(o + Vector2(-3.5, -6.5), 1.6, Color(0.85, 0.8, 0.72) * tint)   # 꼬리
		draw_circle(o + Vector2(3, -8.5), 2.2, Color(0.95, 0.92, 0.85) * tint)    # 머리
		draw_rect(Rect2(o + Vector2(2.4, -11.6), Vector2(1.6, 1.4)), Color(0.85, 0.15, 0.12))   # 볏
		draw_rect(Rect2(o + Vector2(5, -8.8), Vector2(1.6, 1)), Color(0.95, 0.65, 0.15))   # 부리
		draw_rect(Rect2(o + Vector2(3.4, -9.4), Vector2(0.8, 0.8)), Color(0.05, 0.05, 0.05))
	else:
		var wool: Color = {"goat": Color(0.82, 0.78, 0.7), "sheep": Color(0.92, 0.9, 0.85),
			"boar": Color(0.35, 0.27, 0.22), "deer": Color(0.62, 0.42, 0.26)}.get(kind, Color(0.8, 0.8, 0.8))
		var dark := wool.darkened(0.45)
		var step := sin(_t * (14.0 if _flee_t > 0.0 else 8.0)) * (2.0 if _moving else 0.0)
		for lx in [-5.0, -2.5, 3.0, 5.5]:
			var sw := step if int(lx) % 2 == 0 else -step
			draw_line(o + Vector2(lx, -5), Vector2(lx + sw * 0.5, 0), dark, 1.5)
		draw_rect(Rect2(o + Vector2(-8, -12), Vector2(15, 8)), Color(0.12, 0.09, 0.07))
		draw_rect(Rect2(o + Vector2(-7, -11), Vector2(13, 6)), wool * tint)
		draw_rect(Rect2(o + Vector2(-7, -11), Vector2(13, 1)), wool.lightened(0.25) * tint)
		draw_rect(Rect2(o + Vector2(5, -15), Vector2(5, 5)), Color(0.12, 0.09, 0.07))
		draw_rect(Rect2(o + Vector2(6, -14), Vector2(4, 3)), wool * tint)
		draw_rect(Rect2(o + Vector2(8, -13.5), Vector2(1, 1)), Color(0.05, 0.05, 0.05))
		if kind == "goat":
			draw_line(o + Vector2(6.5, -15), o + Vector2(4.5, -18), Color(0.35, 0.3, 0.25), 1.2)   # 뿔
			draw_line(o + Vector2(9, -11), o + Vector2(9, -9), Color(0.5, 0.45, 0.4), 1.0)        # 수염
		elif kind == "deer":
			draw_line(o + Vector2(7, -15), o + Vector2(6, -20), Color(0.45, 0.35, 0.25), 1.0)
			draw_line(o + Vector2(6.5, -18), o + Vector2(4, -19), Color(0.45, 0.35, 0.25), 1.0)
		elif kind == "boar":
			draw_rect(Rect2(o + Vector2(9.5, -12), Vector2(1.5, 1)), Color(0.95, 0.92, 0.85))       # 엄니
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
