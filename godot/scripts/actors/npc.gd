class_name Npc
extends Actor
## 말을 걸 수 있는 인물. 오디세우스가 가까이 오면 그쪽을 본다. 싸움에는 끼지 않는다.

var talk: Interactable


func setup(sheet_name: String, who: String, on_talk: Callable) -> void:
	sheet = sheet_name
	display_name = who
	show_health_bar = false
	talk = Interactable.new()
	talk.label = "%s와 대화" % who
	talk.radius = 34.0
	talk.on_use = on_talk
	add_child(talk)


func _ready() -> void:
	super._ready()
	remove_from_group("actors")
	add_to_group("npcs")


func think(_delta: float) -> void:
	var p: Player = Game.player
	if p and p.global_position.distance_to(global_position) < 90.0:
		face(p.global_position - global_position)
	play("idle")


func _separation() -> Vector2:
	return Vector2.ZERO
