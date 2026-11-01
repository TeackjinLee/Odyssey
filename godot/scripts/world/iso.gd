class_name Iso
## 아이소메트릭 격자(2:1 마름모) ↔ 화면(월드) 좌표 변환과 8방향 계산.
## 격자 좌표는 연속값: 칸 (i, j)의 중심은 (i + 0.5, j + 0.5).

static var origin := Vector2(32, 0)
static var ex := Vector2(32, 16)
static var ey := Vector2(-32, 16)


static func setup(layer: TileMapLayer) -> void:
	var c0 := layer.map_to_local(Vector2i(0, 0))
	ex = layer.map_to_local(Vector2i(1, 0)) - c0
	ey = layer.map_to_local(Vector2i(0, 1)) - c0
	origin = c0 - (ex + ey) * 0.5


static func grid_to_world(g: Vector2) -> Vector2:
	return origin + ex * g.x + ey * g.y


static func world_to_grid(p: Vector2) -> Vector2:
	var q := p - origin
	var det := ex.x * ey.y - ey.x * ex.y
	return Vector2((q.x * ey.y - ey.x * q.y) / det, (ex.x * q.y - q.x * ex.y) / det)


static func cell_of(p: Vector2) -> Vector2i:
	var g := world_to_grid(p)
	return Vector2i(floori(g.x), floori(g.y))


static func cell_center(c: Vector2i) -> Vector2:
	return grid_to_world(Vector2(c) + Vector2(0.5, 0.5))


## 화면 방향 → 0=동 1=남동 2=남 3=남서 4=서 5=북서 6=북 7=북동
static func dir8(v: Vector2) -> int:
	if v.length_squared() < 0.0001:
		return 2
	return posmod(roundi(v.angle() / (PI / 4.0)), 8)


static func dir_vector(d: int) -> Vector2:
	return Vector2.RIGHT.rotated(d * PI / 4.0)
