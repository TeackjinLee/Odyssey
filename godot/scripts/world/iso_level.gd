class_name IsoLevel
extends Node2D
## 챕터 맵의 공통 틀: 바닥 타일, 막힌 칸(충돌·길찾기), 소품 배치, 깊이 정렬, 가림 투명화, 조명, 카메라.
## 챕터는 이 클래스를 상속해 build()(지형·소품)와 start()(인물·퀘스트)만 채운다.

const FLOOR_ROWS := {"cobble": 0, "plaza": 1, "dirt": 2, "grass": 3, "road": 4, "ash": 5}

var W := 36
var H := 36
var floor_kind: Dictionary = {}
var solid: Dictionary = {}
var cell_shapes: Dictionary = {}

var ground: TileMapLayer
var world: Node2D
var fx_layer: Node2D
var camera: Camera2D
var canvas_mod: CanvasModulate
var astar := AStarGrid2D.new()
var solids_body: StaticBody2D
var occluders: Array = []
var lights: Array = []
var player: Player
var squad: Squad
var chapter_title := ""
var _source_id := 0
var _cam_pos := Vector2.ZERO


func _ready() -> void:
	Game.level = self
	ground = TileMapLayer.new()
	ground.tile_set = _make_tileset()
	ground.z_index = -10
	add_child(ground)
	Iso.setup(ground)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	fx_layer = Node2D.new()
	fx_layer.z_index = 50
	add_child(fx_layer)
	solids_body = StaticBody2D.new()
	solids_body.collision_layer = 1
	add_child(solids_body)
	canvas_mod = CanvasModulate.new()
	add_child(canvas_mod)
	build()
	_apply_floor()
	_build_astar()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	add_child(camera)
	_set_camera_limits()
	squad = Squad.new()
	add_child(squad)
	Game.squad = squad
	start()
	if player:
		_cam_pos = player.global_position
		camera.global_position = _cam_pos
		camera.make_current()


func build() -> void:
	pass


func start() -> void:
	pass


# ── 지형 ─────────────────────────────────────────────
func fill(rect: Rect2i, kind: String) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			floor_kind[Vector2i(x, y)] = kind


func set_solid(c: Vector2i, on := true) -> void:
	if on:
		if solid.has(c):
			return
		solid[c] = true
		var poly := CollisionPolygon2D.new()
		var g := Vector2(c)
		poly.polygon = PackedVector2Array([
			Iso.grid_to_world(g), Iso.grid_to_world(g + Vector2(1, 0)),
			Iso.grid_to_world(g + Vector2(1, 1)), Iso.grid_to_world(g + Vector2(0, 1)),
		])
		solids_body.add_child(poly)
		cell_shapes[c] = poly
	else:
		solid.erase(c)
		if cell_shapes.has(c):
			cell_shapes[c].queue_free()
			cell_shapes.erase(c)
	if astar.region.size != Vector2i.ZERO and astar.is_in_boundsv(c):
		astar.set_point_solid(c, on)


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(64, 32)
	var src := TileSetAtlasSource.new()
	src.texture = AssetLibrary.texture("res://assets/env/floor_atlas.png")
	src.texture_region_size = Vector2i(64, 32)
	_source_id = ts.add_source(src)
	var variants: int = int(AssetLibrary.env()["floor_atlas"]["variants"])
	for r in FLOOR_ROWS.size():
		for v in variants:
			src.create_tile(Vector2i(v, r))
	return ts


func _apply_floor() -> void:
	var variants: int = int(AssetLibrary.env()["floor_atlas"]["variants"])
	for x in W:
		for y in H:
			var c := Vector2i(x, y)
			var kind: String = floor_kind.get(c, "cobble")
			var v := int(abs(hash(c)) % variants)
			ground.set_cell(c, _source_id, Vector2i(v, FLOOR_ROWS[kind]))


func _build_astar() -> void:
	astar.region = Rect2i(0, 0, W, H)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for c in solid:
		if astar.is_in_boundsv(c):
			astar.set_point_solid(c, true)


# ── 소품·조명 ────────────────────────────────────────
func add_prop(prop_name: String, cell: Vector2i, blocking := true, occlude := true) -> Sprite2D:
	var meta: Dictionary = AssetLibrary.prop(prop_name)
	var fp := Vector2(meta["footprint"][0], meta["footprint"][1])
	var s := Sprite2D.new()
	s.texture = AssetLibrary.prop_texture(prop_name)
	s.centered = false
	s.offset = -Vector2(meta["anchor"][0], meta["anchor"][1])
	s.position = Iso.grid_to_world(Vector2(cell) + fp * 0.5)
	world.add_child(s)
	if blocking:
		for x in int(fp.x):
			for y in int(fp.y):
				set_solid(cell + Vector2i(x, y))
	if occlude:
		occluders.append(s)
	return s


func add_fire(parent: Node2D, local_pos: Vector2, scale_k := 1.0, with_light := true) -> AnimatedSprite2D:
	var f := AnimatedSprite2D.new()
	f.sprite_frames = AssetLibrary.fire_frames()
	f.centered = false
	var meta: Dictionary = AssetLibrary.prop("fire")
	f.offset = -Vector2(meta["anchor"][0], meta["anchor"][1])
	f.position = local_pos
	f.scale = Vector2(scale_k, scale_k)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	f.material = mat
	f.flip_h = randf() < 0.5
	f.speed_scale = randf_range(0.8, 1.25)
	f.play("default")
	f.frame = randi() % 8
	parent.add_child(f)
	if with_light:
		add_light(parent.global_position + local_pos + Vector2(0, -8), Color(1.0, 0.55, 0.25), 1.1 * scale_k, 0.9 + 0.5 * scale_k)
	return f


## 위로 피어오르며 커지고 흐려지는 연기 (불 위에 둔다)
func add_smoke(parent: Node2D, local_pos: Vector2, scale_k := 1.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = AssetLibrary.prop_texture("smoke")
	p.position = local_pos
	p.amount = 14
	p.lifetime = 3.6
	p.preprocess = 3.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(10, 2) * scale_k
	p.direction = Vector2(0.25, -1)
	p.spread = 12.0
	p.gravity = Vector2(4, 0)
	p.initial_velocity_min = 10.0 * scale_k
	p.initial_velocity_max = 16.0 * scale_k
	p.scale_amount_min = 0.7 * scale_k
	p.scale_amount_max = 1.0 * scale_k
	var grow := Curve.new()
	var meta: Dictionary = AssetLibrary.prop("smoke")
	var frames := int(meta.get("frames", 1))
	if frames > 1:
		# 받은 연기 그림: 한 입자가 사는 동안 프레임을 한 번 돈다(그림 자체가 커지며 흩어짐)
		var mat := CanvasItemMaterial.new()
		mat.particles_animation = true
		mat.particles_anim_h_frames = frames
		mat.particles_anim_v_frames = 1
		mat.particles_anim_loop = false
		p.material = mat
		p.anim_speed_min = 1.0
		p.anim_speed_max = 1.0
		grow.add_point(Vector2(0, 0.7))
		grow.add_point(Vector2(1, 1.6))
	else:
		grow.add_point(Vector2(0, 0.6))
		grow.add_point(Vector2(1, 3.2))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	fade.add_point(0.12, Color(1, 1, 1, 0.6))
	fade.add_point(0.6, Color(1, 1, 1, 0.35))
	p.color_ramp = fade
	parent.add_child(p)
	return p


## 불 위로 튀어 오르다 식는 불티
func add_embers(parent: Node2D, local_pos: Vector2, scale_k := 1.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = local_pos
	p.amount = 8
	p.lifetime = 1.4
	p.preprocess = 1.4
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(14, 4) * scale_k
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2(0, -6)
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 30.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	var cool := Gradient.new()
	cool.set_color(0, Color(1.0, 0.9, 0.5))
	cool.set_color(1, Color(0.8, 0.2, 0.05, 0.0))
	p.color_ramp = cool
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = mat
	parent.add_child(p)
	return p


## 불타는 집: 그을린 지붕 그림에 불꽃 여러 개(자리는 env.json의 fire_spots)와 연기·불티, 큰 불빛 하나
func add_burning_house(prop_name: String, cell: Vector2i) -> Sprite2D:
	var burnt := prop_name + "_burnt"
	var s := add_prop(burnt, cell)
	var spots: Array = AssetLibrary.prop(burnt).get("fire_spots", [])
	if spots.is_empty():
		return s
	var center := Vector2.ZERO
	for sp in spots:
		center += Vector2(sp[0], sp[1])
	center /= spots.size()
	add_smoke(s, center + Vector2(0, -30), 1.2)   # 먼저 넣어 불꽃 뒤에 그려지게
	for sp in spots:
		add_fire(s, Vector2(sp[0], sp[1]) + Vector2(randf_range(-3, 3), randf_range(-2, 2)), randf_range(0.6, 0.95), false)
	add_fire(s, center + Vector2(randf_range(-6, 6), -4), 1.15, false)
	add_embers(s, center + Vector2(0, -20))
	add_light(s.global_position + center + Vector2(0, -10), Color(1.0, 0.5, 0.2), 1.25, 2.2)
	return s


func add_light(pos: Vector2, color: Color, energy: float, size_k: float, flicker := true) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = AssetLibrary.light_texture()
	l.color = color
	l.energy = energy
	l.texture_scale = size_k
	l.position = pos
	add_child(l)
	lights.append([l, energy, randf() * TAU, flicker])
	return l


# ── 질의 ─────────────────────────────────────────────
func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func is_blocked_cell(c: Vector2i) -> bool:
	return not in_bounds(c) or solid.has(c)


func is_blocked_world(p: Vector2) -> bool:
	return is_blocked_cell(Iso.cell_of(p))


func line_clear(a: Vector2, b: Vector2, radius := 4.0) -> bool:
	var d := b - a
	var l := d.length()
	if l < 1.0:
		return not is_blocked_world(b)
	var perp := Vector2(-d.y, d.x) / l * radius
	var steps := int(ceil(l / 6.0))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / steps)
		if is_blocked_world(p) or is_blocked_world(p + perp) or is_blocked_world(p - perp):
			return false
	return true


func nearest_free(c: Vector2i) -> Vector2i:
	if not is_blocked_cell(c):
		return c
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if not is_blocked_cell(n):
					return n
	return c


func find_path(a: Vector2, b: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var ca := nearest_free(Iso.cell_of(a))
	var cb := nearest_free(Iso.cell_of(b))
	if not in_bounds(ca) or not in_bounds(cb):
		return out
	var ids := astar.get_id_path(ca, cb, true)
	for i in ids.size():
		if i == 0:
			continue
		out.append(Iso.cell_center(ids[i]))
	if out.size() > 0 and not is_blocked_world(b):
		out[out.size() - 1] = b
	return out


func find_interactable(pos: Vector2) -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for it in get_tree().get_nodes_in_group("interactable"):
		if not it.enabled:
			continue
		var d: float = it.global_position.distance_to(pos)
		if d < it.radius and d < best_d:
			best = it
			best_d = d
	return best


func enemies() -> Array:
	return get_tree().get_nodes_in_group("actors").filter(func(a): return a.team == Actor.Team.TROJAN and a.is_alive())


func greeks() -> Array:
	return get_tree().get_nodes_in_group("actors").filter(func(a): return a.team == Actor.Team.GREEK and a.is_alive())


# ── 매 프레임 ─────────────────────────────────────────
func _process(delta: float) -> void:
	Game.stats["time"] += delta
	_update_camera(delta)
	_update_occlusion(delta)
	var t := Time.get_ticks_msec() * 0.001
	for l in lights:
		if l[3]:
			l[0].energy = l[1] * (0.85 + 0.1 * sin(t * 7.0 + l[2]) + 0.05 * sin(t * 17.0 + l[2] * 2.0))


func _update_camera(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position + Vector2(0, -16)
	_cam_pos = _cam_pos.lerp(target, 1.0 - exp(-8.0 * delta))
	camera.global_position = _cam_pos.round()
	Game.shake_amount = max(0.0, Game.shake_amount - 30.0 * delta)
	var s := Game.shake_amount
	camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s)).round()


func _set_camera_limits() -> void:
	var pts := [Iso.grid_to_world(Vector2(0, 0)), Iso.grid_to_world(Vector2(W, 0)), Iso.grid_to_world(Vector2(0, H)), Iso.grid_to_world(Vector2(W, H))]
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	camera.limit_left = int(r.position.x) + 40
	camera.limit_right = int(r.end.x) - 40
	camera.limit_top = int(r.position.y) - 80
	camera.limit_bottom = int(r.end.y) - 20


## 플레이어 앞을 가리는 건물·성벽을 반투명하게.
func _update_occlusion(delta: float) -> void:
	if player == null:
		return
	var pp := player.global_position
	var probe := pp + Vector2(0, -14)
	for s in occluders:
		var target := 1.0
		if s.position.y > pp.y + 2.0 and absf(s.position.x - pp.x) < 140.0:
			# 그림 사각형이 아니라 실제로 칠해진 픽셀이 몸을 덮을 때만 (목마처럼 빈 곳이 많은 그림)
			if _covers(s, probe) or _covers(s, pp + Vector2(0, -4)) or _covers(s, pp + Vector2(0, -26)):
				target = 0.42
		s.modulate.a = move_toward(s.modulate.a, target, delta * 4.0)


var _alpha_images := {}


func _covers(s: Sprite2D, p: Vector2) -> bool:
	var local := (p - s.position - s.offset).floor()
	var size := s.texture.get_size()
	if local.x < 0 or local.y < 0 or local.x >= size.x or local.y >= size.y:
		return false
	if not _alpha_images.has(s.texture):
		_alpha_images[s.texture] = s.texture.get_image()
	return _alpha_images[s.texture].get_pixel(int(local.x), int(local.y)).a > 0.5
