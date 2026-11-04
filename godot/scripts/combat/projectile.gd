class_name Projectile
extends Node2D
## 화살. 위치는 땅 위 지점이고 그림만 가슴 높이로 띄운다.

var shooter: Actor
var team := 0
var damage := 8.0
var velocity := Vector2.ZERO
## 화살이 날아가는 시간(사거리 = 속도 × LIFE)
const LIFE := 1.4

var life := LIFE
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = AssetLibrary.texture("res://assets/env/arrow.png")
	_sprite.position = Vector2(0, -16)
	_sprite.rotation = velocity.angle()
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	life -= delta
	position += velocity * delta
	if life <= 0.0:
		queue_free()
		return
	if Game.level and Game.level.is_blocked_world(position):
		Fx.spark(position + Vector2(0, -16), Color(0.8, 0.7, 0.5), 3)
		Sfx.at("arrow_hit", position, -12.0)
		queue_free()
		return
	# 방패벽(부대 특수 명령의 검병): 앞쪽에서 날아온 화살을 막는다
	for w in get_tree().get_nodes_in_group("shield_wall"):
		if w.team != team and Combat.ground_dist(position, w.global_position) < 20.0 \
				and w.facing.dot(-velocity.normalized()) > 0.1:
			Fx.spark(position + Vector2(0, -16), Color(1, 0.95, 0.75), 5)
			Sfx.at("block", position, -8.0)
			queue_free()
			return
	for a in Combat.targets(get_tree(), team):
		if a.team == team or not a.is_alive():
			continue
		if Combat.ground_dist(position, a.global_position) < 9.0:
			var r: String = a.take_hit(damage, self, 40.0, false, true)
			if r == "killed" and a.team == Actor.Team.TROJAN:
				Game.stats["kills"] += 1
			queue_free()
			return
