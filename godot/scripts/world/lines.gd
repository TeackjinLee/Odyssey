class_name Lines
## 챕터 글(대사·튜토리얼 카드·목표·알림·이름): data/dialogue/<챕터>.json에서 읽는다. 글을 고칠 때 코드는 건드리지 않는다.
## 이름은 "묶음.이름" (예: "tut.move", "hint.waves"). 글 속 {동작}은 화면에 그릴 때 Game.keys_text가 지금 묶인 키로 바꾼다.

const COMMON := "res://data/dialogue/common.json"
static var _data := {}
static var _path := ""


static func use(path: String) -> void:
	if path == _path and not _data.is_empty():
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("글 파일을 못 엶: " + path)
		_data = {}
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	_data = {}
	# 모든 챕터가 같이 쓰는 글(영양 등) 위에 챕터 글을 얹는다(같은 묶음은 합침)
	var common: Variant = JSON.parse_string(FileAccess.get_file_as_string(COMMON))
	for src in [common, d]:
		if src is Dictionary:
			for k in src:
				if _data.has(k) and _data[k] is Dictionary and src[k] is Dictionary:
					_data[k].merge(src[k], true)
				else:
					_data[k] = src[k].duplicate(true) if src[k] is Dictionary or src[k] is Array else src[k]
	_path = path


static func get_value(id: String) -> Variant:
	var cur: Variant = _data
	for part in id.split("."):
		if cur is Dictionary and cur.has(part):
			cur = cur[part]
		else:
			push_warning("글 없음: " + id)
			return null
	return cur


## 글 하나. args가 있으면 % 서식(%d·%s)을 채운다.
static func t(id: String, args: Variant = null) -> String:
	var v: Variant = get_value(id)
	if not v is String:
		return "[" + id + "]"
	return v % args if args != null else v


## 글 목록(알림 여러 개 중 하나 고르기 등)
static func list(id: String) -> Array:
	var v: Variant = get_value(id)
	return v.duplicate(true) if v is Array else []


## 대사: [[말하는 이, 글], …]
static func say(id: String) -> Array:
	return list("say." + id)
