class_name Fx
## 전투 이펙트: 피해 숫자, 불똥, 검 궤적, 퍼지는 고리. 모두 레벨의 fx_layer(맨 위)에 그린다.


static func _layer() -> Node:
	return Game.level.fx_layer if Game.level else null


static func damage_number(pos: Vector2, amount: float, friendly: bool) -> void:
	text(pos, str(roundi(amount)), Color(1, 0.55, 0.45) if friendly else Color(1, 0.95, 0.7))


static func text(pos: Vector2, s: String, color: Color) -> void:
	var layer := _layer()
	if layer == null:
		return
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 3)
	l.position = pos + Vector2(-12 + randf_range(-4, 4), -8)
	l.size = Vector2(24, 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 100
	layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 16, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.tween_callback(l.queue_free)


static func spark(pos: Vector2, color: Color, count := 6) -> void:
	var layer := _layer()
	if layer == null:
		return
	var b := Burst.new()
	b.position = pos
	b.color = color
	for i in count:
		var a := randf() * TAU
		b.parts.append([Vector2.ZERO, Vector2.RIGHT.rotated(a) * randf_range(50, 130)])
	layer.add_child(b)


static func slash(owner: Actor, reach: float, arc_deg: float, color: Color, reverse := false, width := 5.0) -> void:
	var layer := _layer()
	if layer == null:
		return
	var s := Slash.new()
	s.position = owner.global_position + Vector2(0, -14)
	s.base_angle = owner.facing.angle()
	s.reach = reach
	s.arc = deg_to_rad(arc_deg)
	s.color = color
	s.reverse = reverse
	s.width = width
	layer.add_child(s)


static func ring(pos: Vector2, radius: float, color: Color, duration := 0.45) -> void:
	var layer := _layer()
	if layer == null:
		return
	var r := Ring.new()
	r.position = pos
	r.max_radius = radius
	r.color = color
	r.duration = duration
	layer.add_child(r)


class Burst:
	extends Node2D
	var color := Color.WHITE
	var parts: Array = []
	var t := 0.0

	func _ready() -> void:
		z_index = 90

	func _process(delta: float) -> void:
		t += delta
		for p in parts:
			p[0] += p[1] * delta
			p[1] *= 0.86
		queue_redraw()
		if t > 0.28:
			queue_free()

	func _draw() -> void:
		var c := color
		c.a = 1.0 - t / 0.28
		for p in parts:
			draw_line(p[0], p[0] - p[1] * 0.03, c, 1.0)


class Slash:
	extends Node2D
	var base_angle := 0.0
	var reach := 24.0
	var arc := 2.0
	var color := Color.WHITE
	var reverse := false
	var width := 5.0
	var t := 0.0
	const LIFE := 0.16

	func _ready() -> void:
		z_index = 80

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if t > LIFE:
			queue_free()

	func _draw() -> void:
		var k := t / LIFE
		var n := 14
		var pts := PackedVector2Array()
		var inner := PackedVector2Array()
		var sweep: float = clamp(k * 2.2, 0.0, 1.0)
		for i in n + 1:
			var u := float(i) / n * sweep
			var a := base_angle + (u - 0.5) * arc * (-1.0 if reverse else 1.0)
			var r := reach * (0.92 + 0.08 * sin(u * PI))
			var w := width * sin(u * PI) * (1.0 - k * 0.6)
			var dirv := Vector2(cos(a), sin(a) * 0.72)
			pts.append(dirv * r)
			inner.append(dirv * (r - w))
		inner.reverse()
		var poly := pts + inner
		var c := color
		c.a = 0.85 * (1.0 - k)
		if poly.size() >= 3:
			draw_colored_polygon(poly, c)


class Ring:
	extends Node2D
	var max_radius := 40.0
	var color := Color.WHITE
	var duration := 0.45
	var t := 0.0

	func _ready() -> void:
		z_index = 5

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if t > duration:
			queue_free()

	func _draw() -> void:
		var k := t / duration
		var r := max_radius * (0.3 + 0.7 * k)
		var c := color
		c.a = 1.0 - k
		var pts := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.5))
		draw_polyline(pts, c, 2.0)
