class_name FoodSource
extends Interactable
## 먹을 것이 있는 지점(docs/NUTRITION.md §4): 채집(나무·덤불·좌판·항아리) · 고기(잡은 동물이 남김) · 낚시터.
## 음식 값은 data/food.json. 길게 눌러 먹고, 다 먹으면 regrow초 뒤 다시 열린다(0이면 사라짐).

var food_id := ""
var info: Dictionary = {}
var left := 1
var _regrow_t := 0.0
var _t := 0.0
## 그림: "" 아무것도 안 그림(소품이 보임) · "fruit" 열매 점 · "meat" 고기 한 점 · "bob" 낚시찌
var look := ""
var fruit_color := Color(0.75, 0.25, 0.45)


func setup(id: String, look_kind := "") -> FoodSource:
	food_id = id
	info = Nutrition.food(id)
	look = look_kind
	left = int(info.get("servings", 1))
	label = "%s %s" % [info.get("name", id), info.get("verb", "먹기")]
	hold_time = 3.5 if info.get("kind", "") == "fish" else (1.0 if info.get("kind", "") == "meat" else 0.7)
	radius = 26.0
	on_use = _eat
	return self


func _ready() -> void:
	super._ready()
	add_to_group("food")
	z_index = 1 if look == "bob" else 0


func _eat(by) -> void:
	if not by is Player:
		return
	by.eat(food_id)
	if info.get("kind", "") == "fish":
		Sfx.at("splash", global_position, -8.0)
	left -= 1
	if left > 0:
		return
	enabled = false
	var regrow := float(info.get("regrow", 0))
	if regrow > 0.0:
		_regrow_t = regrow
	else:
		queue_free()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not enabled and _regrow_t > 0.0:
		_regrow_t -= delta
		if _regrow_t <= 0.0:
			enabled = true
			left = int(info.get("servings", 1))
	if look != "":
		queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	match look:
		"fruit":
			for i in left:
				var p := Vector2(-4 + i * 6, -3 + sin(_t * 2.0 + i) * 0.5)
				draw_circle(p, 2.0, Color(0.1, 0.05, 0.05))
				draw_circle(p, 1.4, fruit_color)
				draw_rect(Rect2(p + Vector2(-0.5, -1.4), Vector2(1, 1)), Color(1, 1, 1, 0.7))
		"meat":
			draw_circle(Vector2(0, -2), 4.5, Color(0.12, 0.05, 0.04))
			draw_circle(Vector2(0, -2), 3.6, Color(0.72, 0.28, 0.22))
			draw_circle(Vector2(-1, -3), 1.4, Color(0.95, 0.75, 0.65))
			draw_line(Vector2(3, -1), Vector2(7, 1), Color(0.9, 0.88, 0.8), 2.0)
		"bob":
			var y := sin(_t * 2.4) * 1.2
			for r in [5.0, 8.0]:
				var a := 0.35 * (1.0 - fmod(_t * 0.5 + r * 0.1, 1.0))
				draw_arc(Vector2(0, 2), r, 0, TAU, 16, Color(0.8, 0.9, 1.0, a), 1.0)
			draw_rect(Rect2(-1.5, -4 + y, 3, 3), Color(0.9, 0.2, 0.15))
			draw_rect(Rect2(-1.5, -1 + y, 3, 2), Color(0.95, 0.95, 0.9))
			draw_line(Vector2(0, -4 + y), Vector2(-14, -22), Color(0.8, 0.8, 0.75, 0.5), 1.0)
