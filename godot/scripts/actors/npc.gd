class_name Npc
extends Actor
## 말을 걸 수 있는 인물. 오디세우스가 가까이 오면 그쪽을 본다. 싸움에는 끼지 않는다.

var talk: Interactable
var fixed_dir := -1
var fixed_anim := "idle"
## 쇼케이스: 여러 동작을 돌아가며 보여 줄 때(쉼표로 이은 --anim), 동작마다 머무는 시간
var cycle: PackedStringArray = []
var cycle_time := 0.9
var _cycle_t := 0.0
var _cycle_i := 0
var play_speed := 1.0
## 쇼케이스: 0 이상이면 그 프레임에 멈춰 세운다(--frame=N)
var freeze_frame := -1
var weapons: WeaponLayer


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
	if fixed_dir >= 0:
		face(Iso.dir_vector(fixed_dir))
		if freeze_frame >= 0:
			play(fixed_anim)
			body.pause()
			body.frame = freeze_frame
		elif cycle.size() > 1:
			_cycle_t += _delta
			if _cycle_t >= cycle_time or anim_base == "idle":
				_cycle_t = 0.0
				play(cycle[_cycle_i % cycle.size()], true, play_speed)
				_cycle_i += 1
		else:
			play(fixed_anim)
		return
	var p: Player = Game.player
	if p and p.global_position.distance_to(global_position) < 90.0:
		face(p.global_position - global_position)
	play("idle")


func _update_visual() -> void:
	super._update_visual()
	if weapons:
		weapons.update()


func _separation() -> Vector2:
	return Vector2.ZERO
