class_name AssetLibrary
## 스프라이트 시트·환경 그림을 읽어 캐시한다. 그림을 진짜 아트로 바꿔도 같은 규칙(.json)만 지키면 코드는 그대로다.
##  - 캐릭터: assets/sprites/<이름>.png + .json  (한 줄 = 한 방향, 열 = 동작 프레임)
##  - 환경: assets/env/env.json  (소품별 그림·기준점·발자국)

static var _frames := {}
static var _anchors := {}
static var _meta := {}
static var _env: Dictionary = {}
static var _tex := {}


static func character_frames(sheet: String) -> SpriteFrames:
	if _frames.has(sheet):
		return _frames[sheet]
	var tex: Texture2D = load("res://assets/sprites/%s.png" % sheet)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/%s.json" % sheet))
	var fw: int = int(meta["frame"][0])
	var fh: int = int(meta["frame"][1])
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anims: Dictionary = meta["anims"]
	for anim_name in anims:
		var a: Dictionary = anims[anim_name]
		for d in 8:
			var key := "%s_%d" % [anim_name, d]
			sf.add_animation(key)
			sf.set_animation_speed(key, float(a["fps"]))
			sf.set_animation_loop(key, bool(a["loop"]))
			for i in int(a["frames"]):
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2((int(a["start"]) + i) * fw, d * fh, fw, fh)
				sf.add_frame(key, at)
	_frames[sheet] = sf
	_anchors[sheet] = Vector2(meta["anchor"][0], meta["anchor"][1])
	_meta[sheet] = meta
	return sf


## 시트를 몇 배로 그릴지 (그려 받은 고해상도 시트는 0.5 등)
static func character_scale(sheet: String) -> float:
	character_frames(sheet)
	return float(_meta[sheet].get("scale", 1.0))


## 손 위치 표: hands[동작][프레임][방향] = [오른손 x, y, 왼손 x, y] (없으면 빈 사전)
static func character_hands(sheet: String) -> Dictionary:
	character_frames(sheet)
	return _meta[sheet].get("hands", {})


## 그려 받은 동작 이름들 (손 위치가 그림의 실제 주먹을 따라감)
static func character_drawn(sheet: String) -> Array:
	character_frames(sheet)
	return _meta[sheet].get("drawn", [])


## 칼·방패를 몸과 함께 그린 동작들 — 이 동작 동안은 따로 그린 무기를 숨긴다
static func character_armed(sheet: String) -> Array:
	character_frames(sheet)
	return _meta[sheet].get("armed", [])


static var _weapons: Dictionary = {}


static func weapons() -> Dictionary:
	if _weapons.is_empty():
		_weapons = JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/weapons.json"))
	return _weapons


static func weapon_texture(file: String) -> Texture2D:
	return texture("res://assets/weapons/" + file)


static func character_anchor(sheet: String) -> Vector2:
	character_frames(sheet)
	return _anchors[sheet]


static func env() -> Dictionary:
	if _env.is_empty():
		_env = JSON.parse_string(FileAccess.get_file_as_string("res://assets/env/env.json"))
	return _env


static func prop(name: String) -> Dictionary:
	return env()["props"][name]


static func texture(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path]


static func prop_texture(name: String) -> Texture2D:
	return texture("res://assets/env/" + String(prop(name)["file"]))


static func fire_frames() -> SpriteFrames:
	if _frames.has("__fire"):
		return _frames["__fire"]
	var meta: Dictionary = prop("fire")
	var tex := texture("res://assets/env/fire.png")
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 12.0)
	var fw: int = int(meta["frame"][0])
	for i in int(meta["frames"]):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, int(meta["frame"][1]))
		sf.add_frame("default", at)
	_frames["__fire"] = sf
	return sf


static var _light: Texture2D


static func light_texture() -> Texture2D:
	if _light == null:
		var g := GradientTexture2D.new()
		g.width = 256
		g.height = 256
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		grad.add_point(0.45, Color(1, 1, 1, 0.45))
		g.gradient = grad
		_light = g
	return _light
