class_name PauseMenu
extends Control
## 일시정지 메뉴(Esc)와 설정 화면. 게임 중에는 HUD가, 타이틀에서는 main.gd가 띄운다(settings_only면 설정만).
## 설정: 음량(전체·음악·효과음), 전체 화면, 키 바꾸기(버튼을 누르고 새 키를 누름, Esc 취소), 키 기본값.
## 바꾸는 즉시 Game.settings에 넣고 user://settings.json에 저장한다.

signal resumed
signal restart_requested
signal checkpoint_requested
signal menu_requested

const GOLD := Color(0.95, 0.78, 0.38)

var settings_only := false
var _page: Control
var _waiting_action := ""
var _waiting_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if settings_only:
		_show_settings()
	else:
		_show_main()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.72))
	var r := Rect2(48, 14, 544, 322) if _page and _page.name == "settings" else Rect2(200, 14, 240, 322)
	draw_rect(r, Color(0.05, 0.04, 0.05, 0.9))
	draw_rect(r, Color(0.62, 0.48, 0.24, 0.9), false, 1.0)


func _input(event: InputEvent) -> void:
	if _waiting_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode != KEY_ESCAPE:
				Game.rebind(_waiting_action, event.physical_keycode)
			_waiting_action = ""
			_show_settings()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if _page and _page.name == "settings" and not settings_only:
			_show_main()
		else:
			_close()


func _close() -> void:
	resumed.emit()
	queue_free()


func _new_page(page_name: String, title: String) -> Control:
	if _page:
		_page.queue_free()
	_page = Control.new()
	_page.name = page_name
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_page)
	queue_redraw()
	var l := Label.new()
	l.text = title
	l.position = Vector2(0, 24)
	l.size = Vector2(640, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	_page.add_child(l)
	return _page


func _button(parent: Control, text: String, pos: Vector2, size: Vector2, cb: Callable, font := 9) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", font)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _label(parent: Control, text: String, pos: Vector2, size := 9, color := Color.WHITE, width := 200.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, size + 6)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


# ── 일시정지 ──────────────────────────────────────────
func _show_main() -> void:
	var p := _new_page("main", "일시정지")
	var items := [["계속하기", _close], ["설정 · 키 바꾸기", _show_settings]]
	if not Game.checkpoint.is_empty():
		items.append(["체크포인트에서 다시", func(): checkpoint_requested.emit()])
	items.append(["처음부터", func(): restart_requested.emit()])
	items.append(["타이틀로", func(): menu_requested.emit()])
	var first: Button
	for i in items.size():
		var b := _button(p, items[i][0], Vector2(230, 80 + i * 32), Vector2(180, 24), items[i][1])
		if i == 0:
			first = b
	_label(p, "Esc — 계속하기\n진행은 체크포인트마다 저장된다", Vector2(0, 290), 7, Color(0.7, 0.7, 0.7), 640).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	first.grab_focus()


# ── 설정 ──────────────────────────────────────────────
func _show_settings() -> void:
	var p := _new_page("settings", "설정")
	var y := 58.0
	var first: Control
	for row in [["전체 음량", "vol_master"], ["음악", "vol_music"], ["효과음", "vol_sfx"]]:
		_label(p, row[0], Vector2(70, y), 8, GOLD, 80)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 100
		s.step = 10
		s.value = round(float(Game.settings.get(row[1], 1.0)) * 100.0)
		s.position = Vector2(140, y + 2)
		s.size = Vector2(120, 12)
		var pct := _label(p, "%d%%" % int(s.value), Vector2(266, y), 8, Color.WHITE, 40)
		var key: String = row[1]
		s.value_changed.connect(func(v):
			Game.settings[key] = v / 100.0
			pct.text = "%d%%" % int(v)
			Game.apply_settings()
			Game.save_settings()
			Sfx.play("ui", -6.0))
		p.add_child(s)
		if first == null:
			first = s
		y += 20
	var fs := CheckButton.new()
	fs.text = "전체 화면"
	fs.button_pressed = Game.settings.get("fullscreen", false)
	fs.position = Vector2(64, y)
	fs.add_theme_font_size_override("font_size", 8)
	fs.toggled.connect(func(on):
		Game.settings["fullscreen"] = on
		Game.apply_settings()
		Game.save_settings())
	p.add_child(fs)
	# 키 바꾸기: 두 줄로 9개씩
	_label(p, "키 바꾸기 — 바꿀 동작을 누르고 새 키를 누른다 (Esc 취소)", Vector2(314, 58), 7, GOLD, 280)
	var actions: Array = Game.REBIND
	for i in actions.size():
		var col := i / 9
		var row := i % 9
		var bx := 314.0 + col * 138.0
		var by := 74.0 + row * 19.0
		var action: String = actions[i][0]
		var waiting := action == _waiting_action
		var b := _button(p, "%s   %s" % [actions[i][1], "… 키를 누르세요" if waiting else Game.key_label(action)],
			Vector2(bx, by), Vector2(134, 16), func(): _wait_key(action), 7)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_button(p, "키 기본값으로", Vector2(314, 250), Vector2(120, 18), func():
		Game.reset_keys()
		_show_settings(), 8)
	_button(p, "뒤로", Vector2(260, 300), Vector2(120, 22), func():
		if settings_only:
			_close()
		else:
			_show_main())
	_label(p, "바꾼 키는 튜토리얼 카드·목표·알림·하단 슬롯·조작법에 바로 보인다.", Vector2(0, 276), 6, Color(0.6, 0.6, 0.6), 640).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if first:
		first.grab_focus()


func _wait_key(action: String) -> void:
	_waiting_action = action
	_show_settings()
