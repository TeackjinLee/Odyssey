class_name Hud
extends CanvasLayer
## 게임 화면 UI. 한 장의 Control에 매 프레임 직접 그린다(640×360 기준, 글자는 화면 해상도로 선명하게).
## 좌상단 초상화·체력·스태미나 / 그 아래 부대 상태 / 퀘스트 / 우상단 미니맵 / 하단 무기·스킬 슬롯 /
## 보스 체력 / 상호작용 표시 / 힌트 / 대화창 / 챕터 제목 / 조작법(F1).

signal restart_requested
signal menu_requested
signal checkpoint_requested

const GOLD := Color(0.95, 0.78, 0.38)
const PANEL := Color(0.06, 0.05, 0.07, 0.72)
const EDGE := Color(0.62, 0.48, 0.24, 0.9)

var canvas: Control
var boss: Actor = null
var objective_title := ""
var objective_text := ""
var hint_text := ""
var hint_time := 0.0
var dialogue: Array = []
var dialogue_i := 0
var dialogue_done: Callable
var dialogue_auto := 0.0
var title_time := 0.0
var title_lines: Array = []
var show_help := false
var overlay := ""
var overlay_stats: Dictionary = {}
var _portraits := {}
var _buttons: Array = []
## 튜토리얼 카드: 글, ✓ 표시 남은 시간, 깜빡일 하단 슬롯
var tut_text := ""
var tut_done := 0.0
var tut_slot := -1
var tut_t := 0.0
## 연출: 위아래 검은 띠 + 자막, 화면 페이드(0 투명 ~ 1 검정)
var cinematic := false
var fade_a := 0.0
var _fade_target := 0.0
var _fade_speed := 1.0
var caption_text := ""
var caption_time := 0.0
var caption_len := 1.0
var _bars := 0.0
var pause_menu: PauseMenu = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)
	add_child(canvas)
	Game.hud = self
	Game.objective_changed.connect(func(t, s): objective_title = t; objective_text = s)
	Game.hint.connect(func(s): hint_text = s; hint_time = 8.0)
	Game.boss_changed.connect(func(a): boss = a)
	Game.dialogue_requested.connect(_on_dialogue)
	Game.chapter_cleared.connect(func(st): _show_overlay("clear", st))
	Game.player_died.connect(func(): _show_overlay("dead", Game.stats))
	Game.tutorial_changed.connect(_on_tutorial)


func _on_tutorial(text: String, done: bool, slot: int) -> void:
	if done:
		if tut_text != "":
			tut_done = 1.1
			Sfx.play("ui_ok", -8.0)
		tut_slot = -1
		return
	tut_text = text
	tut_done = 0.0
	tut_slot = slot
	tut_t = 0.0


func fade_to(a: float, time: float) -> void:
	_fade_target = a
	_fade_speed = absf(a - fade_a) / maxf(time, 0.001)


func caption(text: String, time: float) -> void:
	caption_text = text
	caption_time = time
	caption_len = time


func show_title(lines: Array) -> void:
	title_lines = lines
	title_time = 4.0


func _process(delta: float) -> void:
	hint_time = max(0.0, hint_time - delta)
	title_time = max(0.0, title_time - delta)
	tut_t += delta
	fade_a = move_toward(fade_a, _fade_target, _fade_speed * delta)
	caption_time = max(0.0, caption_time - delta)
	_bars = move_toward(_bars, 1.0 if cinematic else 0.0, delta * 2.0)
	if tut_done > 0.0:
		tut_done -= delta
		if tut_done <= 0.0:
			tut_text = ""
	if dialogue.size() > 0 and Game.autoplay:
		dialogue_auto += delta
		if dialogue_auto > 0.25:
			dialogue_auto = 0.0
			_advance_dialogue()
	canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if pause_menu:
		return
	if event.is_action_pressed("pause") and overlay == "":
		open_pause()
		get_viewport().set_input_as_handled()
		return
	if dialogue.size() > 0:
		var adv := event.is_action_pressed("interact") or event.is_action_pressed("dodge") or event.is_action_pressed("attack")
		if adv:
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("help"):
		show_help = not show_help
		get_viewport().set_input_as_handled()


# ── 일시정지 메뉴 ─────────────────────────────────────
func open_pause() -> void:
	if pause_menu:
		return
	pause_menu = PauseMenu.new()
	pause_menu.resumed.connect(_on_resume)
	pause_menu.restart_requested.connect(func(): restart_requested.emit())
	pause_menu.checkpoint_requested.connect(func(): checkpoint_requested.emit())
	pause_menu.menu_requested.connect(func(): menu_requested.emit())
	add_child(pause_menu)
	show_help = false
	get_tree().paused = true
	Sfx.play("ui", -8.0)


func _on_resume() -> void:
	pause_menu = null
	get_tree().paused = dialogue.size() > 0 or overlay != ""


# ── 대화 ─────────────────────────────────────────────
func _on_dialogue(lines: Array, on_done: Callable) -> void:
	dialogue = lines
	dialogue_i = 0
	dialogue_done = on_done
	get_tree().paused = true


func _advance_dialogue() -> void:
	dialogue_i += 1
	Sfx.play("ui", -14.0)
	if dialogue_i >= dialogue.size():
		dialogue = []
		get_tree().paused = false
		if dialogue_done.is_valid():
			dialogue_done.call()


# ── 결과 화면 ─────────────────────────────────────────
func _show_overlay(kind: String, st: Dictionary) -> void:
	overlay = kind
	overlay_stats = st
	get_tree().paused = true
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	var labels := [["처음부터", func(): restart_requested.emit()], ["타이틀로", func(): menu_requested.emit()]]
	if kind == "clear":
		labels[0][0] = "챕터 다시 하기"
	elif not Game.checkpoint.is_empty():
		labels.push_front(["체크포인트에서 다시", func(): checkpoint_requested.emit()])
	for i in labels.size():
		var b := Button.new()
		b.text = labels[i][0]
		b.position = Vector2(320 - (labels.size() * 140 - 12) / 2.0 + i * 140, 262 if kind == "clear" else 238)
		b.size = Vector2(128, 20)
		b.add_theme_font_size_override("font_size", 8)
		b.pressed.connect(labels[i][1])
		canvas.add_child(b)
		_buttons.append(b)
		if i == 0:
			b.grab_focus()
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS


# ── 그리기 ────────────────────────────────────────────
func _text(pos: Vector2, s: String, size := 9, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f: Font = Game.ui_font
	canvas.draw_string_outline(f, pos, s, align, width, size, 3, Color(0, 0, 0, 0.85))
	canvas.draw_string(f, pos, s, align, width, size, color)


func _panel(r: Rect2) -> void:
	canvas.draw_rect(r, PANEL)
	canvas.draw_rect(r, EDGE, false, 1.0)


func _bar(r: Rect2, k: float, color: Color) -> void:
	canvas.draw_rect(r.grow(1), Color(0, 0, 0, 0.8))
	canvas.draw_rect(r, Color(0.18, 0.12, 0.1))
	canvas.draw_rect(Rect2(r.position, Vector2(r.size.x * clamp(k, 0.0, 1.0), r.size.y)), color)
	canvas.draw_rect(Rect2(r.position, Vector2(r.size.x * clamp(k, 0.0, 1.0), 1)), color.lightened(0.35))


func _portrait(path: String) -> Texture2D:
	if not _portraits.has(path):
		_portraits[path] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[path]


func _draw_hud() -> void:
	var p: Player = Game.player
	if _bars > 0.0:
		_draw_cinematic()
	if p and Game.level and not cinematic:
		_draw_player(p)
		_draw_squad()
		_draw_quest()
		_draw_minimap(p)
		_draw_slots(p)
		_draw_boss()
		_draw_interact(p)
		_draw_tutorial()
		_draw_hint()
	if fade_a > 0.0:
		canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, fade_a))
	_draw_title()
	if show_help:
		_draw_help()
	if dialogue.size() > 0:
		_draw_dialogue()
	if overlay != "":
		_draw_overlay()


func _draw_player(p: Player) -> void:
	_panel(Rect2(6, 6, 178, 60))
	var tex := _portrait("res://assets/ui/portrait_%s.png" % p.sheet)   # 입은 옷의 초상화가 있으면 그것
	if tex == null:
		tex = _portrait("res://assets/ui/portrait_odysseus.png")
	if tex == null:
		tex = _portrait("res://assets/ui/portrait_odysseus_sword.png")
	canvas.draw_rect(Rect2(9, 9, 42, 42), Color(0.2, 0.15, 0.12))
	if tex:
		canvas.draw_texture_rect(tex, Rect2(10, 10, 40, 40), false)
	canvas.draw_rect(Rect2(9, 9, 42, 42), GOLD, false, 1.0)
	_text(Vector2(56, 17), "Lv.1  오디세우스", 9, GOLD)
	_bar(Rect2(56, 22, 122, 7), p.hp / p.max_hp, Color(0.85, 0.18, 0.16))
	_text(Vector2(56, 29), "%d / %d" % [ceili(p.hp), int(p.max_hp)], 6, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 122)
	_bar(Rect2(56, 33, 122, 4), p.stamina / p.max_stamina, Color(0.35, 0.7, 0.95))
	var buff := "  ·  함성 효과" if p.buff_time > 0.0 else ""
	_text(Vector2(56, 45), ("검과 방패" if p.weapon == "sword" else "활") + buff, 7, Color(0.85, 0.85, 0.85))
	_draw_food(p.nutrition)


## 영양 막대 셋(docs/NUTRITION.md §8): 탄(체력 회복) · 단(힘) · 지(완충, 60 넘으면 느려짐) + 걸린 효과
func _draw_food(n: Nutrition) -> void:
	var rows := [["탄", n.carb, Color(0.95, 0.75, 0.3)], ["단", n.protein, Color(0.9, 0.42, 0.4)], ["지", n.fat, Color(0.95, 0.9, 0.72)]]
	for i in rows.size():
		var x := 10.0 + i * 58.0
		_text(Vector2(x, 57), rows[i][0], 6, rows[i][2])
		var r := Rect2(x + 9, 53, 44, 3)
		_bar(r, rows[i][1] / 100.0, rows[i][2])
		if i == 2:   # 지방: 60 눈금(넘으면 느려짐)
			canvas.draw_rect(Rect2(r.position.x + r.size.x * Nutrition.FAT_HEAVY / 100.0, r.position.y - 1, 1, r.size.y + 2), Color(1, 0.45, 0.35))
		elif i == 0 and n.carb < Nutrition.LOW or i == 1 and n.protein < Nutrition.PROTEIN_OK:
			var a := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
			canvas.draw_rect(r.grow(1), Color(1, 0.3, 0.25, a), false, 1.0)
	var eff := n.effects()
	if not eff.is_empty():
		_text(Vector2(10, 64), " · ".join(eff), 6, Color(1, 0.55, 0.45))


func _draw_squad() -> void:
	var sq: Squad = Game.squad
	if sq == null or sq.members.is_empty():
		return
	var y := 72.0
	_panel(Rect2(6, y, 150, 14 + sq.members.size() * 27))
	var mode_colors := [Color(0.6, 0.85, 1), Color(0.95, 0.85, 0.4), Color(1, 0.45, 0.35), Color(0.6, 1, 0.6)]
	_text(Vector2(11, y + 10), "부대 명령: " + Squad.MODE_NAMES[sq.mode], 8, mode_colors[sq.mode])
	y += 15
	for c in sq.members:
		var tex := _portrait(c.portrait)
		canvas.draw_rect(Rect2(10, y, 22, 22), Color(0.2, 0.15, 0.12))
		if tex:
			canvas.draw_texture_rect(tex, Rect2(10, y, 22, 22), false)
		canvas.draw_rect(Rect2(10, y, 22, 22), EDGE, false, 1.0)
		_text(Vector2(36, y + 8), "%s · %s" % [c.display_name, Companion.ROLE_NAMES[c.role]], 7)
		_bar(Rect2(36, y + 11, 110, 4), c.hp / c.max_hp, Color(0.35, 0.75, 1.0))
		var st := ""
		var col := Color(0.8, 0.8, 0.8)
		if c.state == Actor.St.DOWNED:
			st = "쓰러짐 — 가까이 가서 %s 길게" % Game.key_label("interact")
			col = Color(1, 0.45, 0.4)
		elif c.state == Actor.St.ATTACK or (c.target and c.target.is_alive()):
			st = "교전 중"
			col = Color(1, 0.75, 0.5)
		else:
			st = "대기" if sq.mode == Squad.Mode.HOLD else "이동"
		_text(Vector2(36, y + 22), st, 6, col)
		y += 27


func _draw_quest() -> void:
	if objective_text == "":
		return
	var y: float = 84.0 + Game.squad.members.size() * 27 + 12
	_panel(Rect2(6, y, 200, 36 + objective_text.count("\n") * 10))
	_text(Vector2(11, y + 11), objective_title, 8, GOLD)
	canvas.draw_multiline_string(Game.ui_font, Vector2(11, y + 23), "▸ " + Game.keys_text(objective_text), HORIZONTAL_ALIGNMENT_LEFT, 192, 8, 2 + objective_text.count("\n"), Color(1, 1, 1))


func _draw_minimap(p: Player) -> void:
	var center := Vector2(592, 50)
	var radius := 42.0
	var lvl: IsoLevel = Game.level
	canvas.draw_circle(center, radius + 3, Color(0, 0, 0, 0.8))
	canvas.draw_circle(center, radius, Color(0.22, 0.2, 0.18, 0.92))
	var pg := Iso.world_to_grid(p.global_position)
	var k := 2.6
	for c in lvl.solid:
		var d := Vector2(c) + Vector2(0.5, 0.5) - pg
		var m := center + Vector2((d.x - d.y) * k, (d.x + d.y) * k * 0.5)
		if m.distance_to(center) < radius - 2:
			var sea: bool = lvl.floor_kind.get(c, "") in ["water", "sand"]
			canvas.draw_rect(Rect2(m - Vector2(1.5, 1), Vector2(3, 2)), Color(0.2, 0.34, 0.55) if sea else Color(0.55, 0.5, 0.42))
	for a in get_tree().get_nodes_in_group("actors"):
		if not a.is_alive() or a == p:
			continue
		var g := Iso.world_to_grid(a.global_position) - pg
		var m := center + Vector2((g.x - g.y) * k, (g.x + g.y) * k * 0.5)
		if m.distance_to(center) < radius - 2:
			canvas.draw_circle(m, 1.6, Color(1, 0.3, 0.25) if a.team == Actor.Team.TROJAN else Color(0.4, 0.75, 1))
	for sm in Game.side_markers:
		var g := Iso.world_to_grid(sm) - pg
		var m := center + Vector2((g.x - g.y) * k, (g.x + g.y) * k * 0.5)
		if m.distance_to(center) < radius - 3:
			canvas.draw_arc(m, 2.6, 0, TAU, 12, Color(0.55, 0.85, 1.0, 0.9), 1.0)
	if Game.quest_marker != Vector2.INF:
		var g := Iso.world_to_grid(Game.quest_marker) - pg
		var m := center + Vector2((g.x - g.y) * k, (g.x + g.y) * k * 0.5)
		if m.distance_to(center) > radius - 5:
			m = center + (m - center).normalized() * (radius - 5)
		var blink := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008)
		canvas.draw_circle(m, 3.0, Color(1, 0.85, 0.2, blink))
	canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -3), center + Vector2(2.5, 2.5), center + Vector2(-2.5, 2.5)]), GOLD)
	canvas.draw_arc(center, radius + 1, 0, TAU, 48, GOLD, 1.5)
	_text(Vector2(center.x - 40, center.y + radius + 11), "트로이 성내", 7, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 80)


func _draw_slots(p: Player) -> void:
	var slots := [
		["검" if p.weapon == "sword" else "활", Game.key_label("switch_weapon") + " 교체", 0.0, p.weapon == "sword"],
		["연타" if p.weapon == "sword" else "조준", Game.key_label("attack") + "/클릭", 0.0, true],
		["강공격", Game.key_label("heavy"), p.heavy_cd / Player.HEAVY_CD, p.weapon == "sword"],
		["방패", Game.key_label("block") + "/우클릭", 0.0, p.weapon == "sword"],
		["구르기", Game.key_label("dodge"), 0.0, p.stamina >= 11.0],
		["함성", Game.key_label("skill"), p.skill_cd / Player.SKILL_CD, true],
		["미끼", Game.key_label("decoy"), p.decoy_cd / Player.DECOY_CD, true],
		["부대기술", Game.key_label("cmd_special"), Game.squad.special_cd / Squad.SPECIAL_CD, not Game.squad.members.is_empty()],
	]
	var w := 34.0
	var x0 := 320.0 - slots.size() * (w + 4) * 0.5
	var y := 318.0
	for i in slots.size():
		var s: Array = slots[i]
		var r := Rect2(x0 + i * (w + 4), y, w, w)
		canvas.draw_rect(r, Color(0.08, 0.06, 0.06, 0.85))
		canvas.draw_rect(r, GOLD if s[3] else Color(0.4, 0.35, 0.3), false, 1.0)
		if i == tut_slot and tut_done <= 0.0:
			var pulse := 0.5 + 0.5 * sin(tut_t * 8.0)
			canvas.draw_rect(r.grow(2.0 + pulse * 2.0), Color(1.0, 0.9, 0.4, 0.5 + 0.5 * pulse), false, 1.5)
		var cd: float = s[2]
		if cd > 0.0:
			canvas.draw_rect(Rect2(r.position.x, r.position.y + w * (1.0 - cd), w, w * cd), Color(0, 0, 0, 0.65))
		_text(r.position + Vector2(0, 17), s[0], 8, Color(1, 1, 1) if s[3] else Color(0.55, 0.55, 0.55), HORIZONTAL_ALIGNMENT_CENTER, w)
		_text(r.position + Vector2(0, w - 4), s[1], 6, GOLD, HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_boss() -> void:
	if boss == null or not is_instance_valid(boss) or not boss.is_alive():
		return
	var r := Rect2(190, 14, 260, 7)
	_text(Vector2(190, 11), boss.display_name, 8, Color(1, 0.75, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 260)
	_bar(r, boss.hp / boss.max_hp, Color(0.75, 0.15, 0.2))


func _draw_interact(p: Player) -> void:
	var it: Interactable = Game.level.find_interactable(p.global_position)
	if it == null or dialogue.size() > 0:
		return
	var sp: Vector2 = get_viewport().get_canvas_transform() * (it.global_position + Vector2(0, -56))
	var label := "[%s] " % Game.key_label("interact") + it.label + ("  (누르고 있기)" if it.progress >= 0.0 else "  (길게)" if it.hold_time > 0.0 else "")
	var f: Font = Game.ui_font
	var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10
	var r := Rect2(sp.x - tw / 2, sp.y - 10, tw, 13)
	_panel(r)
	_text(Vector2(r.position.x, sp.y), label, 8, Color(1, 0.95, 0.8), HORIZONTAL_ALIGNMENT_CENTER, tw)
	if it.progress >= 0.0:
		_bar(Rect2(r.position.x + 2, r.end.y + 2, tw - 4, 3), it.progress, Color(0.45, 0.75, 1.0))
	elif p.state == Actor.St.INTERACT and p.interact_target == it and it.hold_time > 0.0:
		_bar(Rect2(r.position.x + 2, r.end.y + 2, tw - 4, 3), p.interact_progress / it.hold_time, GOLD)


## 튜토리얼 카드: 하단 슬롯 위. 할 일을 마치면 초록 ✓로 바뀌었다 사라진다.
func _draw_tutorial() -> void:
	if tut_text == "":
		return
	var done := tut_done > 0.0
	var a: float = clamp(tut_done, 0.0, 1.0) if done else clamp(tut_t * 4.0, 0.0, 1.0)
	var text := Game.keys_text(tut_text)
	var lines := text.count("\n") + 1
	var h := 18.0 + lines * 11.0
	var r := Rect2(160, 274 - h, 320, h)
	canvas.draw_rect(r, Color(0.05, 0.04, 0.05, 0.86 * a))
	var edge := Color(0.45, 0.95, 0.5, a) if done else Color(GOLD, a * (0.75 + 0.25 * sin(tut_t * 5.0)))
	canvas.draw_rect(r, edge, false, 1.0)
	_text(r.position + Vector2(8, 11), "✓ 완료" if done else "튜토리얼", 7, edge)
	canvas.draw_multiline_string(Game.ui_font, r.position + Vector2(8, 24), text, HORIZONTAL_ALIGNMENT_LEFT, 304, 8, lines,
		Color(0.7, 0.7, 0.7, a) if done else Color(1, 1, 1, a))


func _draw_hint() -> void:
	if hint_time <= 0.0 or hint_text == "":
		return
	var a: float = clamp(hint_time, 0.0, 1.0)
	var hint_s := Game.keys_text(hint_text)
	# 길면 두 줄로 접는다(아래 슬롯과 겹치지 않게 위로 늘림)
	var two: bool = Game.ui_font.get_string_size(hint_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x > 490.0
	var r := Rect2(70, 290 - (11 if two else 0), 500, 29 if two else 18)
	canvas.draw_rect(r, Color(0, 0, 0, 0.55 * a))
	canvas.draw_multiline_string(Game.ui_font, Vector2(75, r.position.y + 12), hint_s, HORIZONTAL_ALIGNMENT_CENTER, 490, 8, 2,
		Color(1, 0.92, 0.7, a))


## 연출 화면: 위아래 검은 띠, 아래 띠 위 자막, 건너뛰기 안내
func _draw_cinematic() -> void:
	var h := 30.0 * _bars
	canvas.draw_rect(Rect2(0, 0, 640, h), Color(0, 0, 0))
	canvas.draw_rect(Rect2(0, 360 - h, 640, h), Color(0, 0, 0))
	if caption_time > 0.0 and caption_text != "":
		var a: float = clamp(min(caption_time, caption_len - caption_time) * 2.0, 0.0, 1.0)
		_text(Vector2(0, 360 - h - 14), caption_text, 10, Color(1, 0.95, 0.85, a), HORIZONTAL_ALIGNMENT_CENTER, 640)
	if cinematic and dialogue.is_empty():
		_text(Vector2(0, 360 - 10), _advance_keys() + " — 건너뛰기", 6, Color(0.7, 0.7, 0.7, 0.8 * _bars), HORIZONTAL_ALIGNMENT_RIGHT, 630)


func _draw_title() -> void:
	if title_time <= 0.0 or title_lines.is_empty():
		return
	var a: float = clamp(min(title_time, 4.0 - title_time) * 1.5, 0.0, 1.0)
	canvas.draw_rect(Rect2(0, 120, 640, 76), Color(0, 0, 0, 0.55 * a))
	_text(Vector2(0, 140), title_lines[0], 10, Color(GOLD, a), HORIZONTAL_ALIGNMENT_CENTER, 640)
	_text(Vector2(0, 166), title_lines[1], 20, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 640)
	_text(Vector2(0, 186), title_lines[2], 9, Color(0.85, 0.85, 0.85, a), HORIZONTAL_ALIGNMENT_CENTER, 640)


func _draw_dialogue() -> void:
	var line: Array = dialogue[dialogue_i]
	var r := Rect2(70, 262, 500, 62)
	canvas.draw_rect(r, Color(0.05, 0.04, 0.05, 0.9))
	canvas.draw_rect(r, GOLD, false, 1.0)
	_text(r.position + Vector2(10, 14), line[0], 9, GOLD)
	canvas.draw_multiline_string(Game.ui_font, r.position + Vector2(10, 30), Game.keys_text(line[1]), HORIZONTAL_ALIGNMENT_LEFT, 480, 9, 3, Color.WHITE)
	_text(r.end + Vector2(-150, -6), _advance_keys() + " ▶", 7, Color(0.8, 0.8, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, 144)


## 대화 넘기기·연출 건너뛰기 키(상호작용 / 구르기 / 공격)
func _advance_keys() -> String:
	return "%s / %s / 클릭" % [Game.key_label("interact"), Game.key_label("dodge")]


func _draw_help() -> void:
	var r := Rect2(150, 40, 340, 270)
	canvas.draw_rect(r, Color(0.04, 0.03, 0.04, 0.92))
	canvas.draw_rect(r, GOLD, false, 1.0)
	_text(r.position + Vector2(0, 16), Game.keys_text("조작법  ({help} 닫기 · {pause} 일시정지·키 바꾸기)"), 10, GOLD, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var k := func(a): return Game.key_label(a)
	var rows := [
		["%s%s%s%s" % [k.call("move_up"), k.call("move_left"), k.call("move_down"), k.call("move_right")], "이동 (%s 달리기)" % k.call("run")],
		["%s / 좌클릭" % k.call("attack"), "검 3연타 (누르고 있던 입력은 다음 타로 이어짐)"],
		[k.call("heavy"), "강공격 — 방패를 부수고 크게 밀어냄"], ["%s / 우클릭" % k.call("block"), "방패 막기 — 막는 순간 0.2초는 패링"],
		[k.call("dodge"), "구르기 (무적, 공격 후딜 취소)"], [k.call("switch_weapon"), "검 ↔ 활 (활: 누르고 있다가 놓아 발사)"],
		[k.call("interact"), "대화·조사 / 길게: 권양기, 쓰러진 부하 일으키기"], [k.call("skill"), "전투의 함성 — 아군 회복·공격력 증가, 주변 적 경직"],
		[k.call("decoy"), "미끼 던지기 — 떨어진 곳으로 보초가 살피러 간다"],
		["%s %s %s %s" % [k.call("cmd_follow"), k.call("cmd_hold"), k.call("cmd_focus"), k.call("cmd_regroup")], "부대: 따라오기 · 위치 사수 · 집중 공격 · 후퇴·집결"],
		[k.call("cmd_special"), "부대 특수 명령 — 검병 방패벽 · 창병 창 던지기 · 궁병 일제 사격"],
		["조준", "마우스 쪽 / %s·%s·방향키를 쓰면 이동·바라보는 쪽의 적" % [k.call("attack"), k.call("block")]],
	]
	for i in rows.size():
		var y: float = r.position.y + 38 + i * 19
		_text(Vector2(r.position.x + 14, y), rows[i][0], 8, GOLD)
		_text(Vector2(r.position.x + 90, y), rows[i][1], 8)


const CHECKPOINT_NAMES := {"stealth": "잠입 시작", "merge": "부하 합류", "winch": "권양기 앞"}


## 클리어 결과: 시간·처치·들킨 횟수·경보·골라서 하는 목표, 경보 없이 끝내면 칭호
func _draw_clear_result() -> void:
	var st := overlay_stats
	_text(Vector2(0, 92), "CHAPTER 1 클리어", 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 640)
	_text(Vector2(0, 120), "트로이의 성문을 열었다", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 640)
	var title := ""
	if st.get("alarms", 0) == 0 and st.get("detected", 0) == 0:
		title = "칭호 「보이지 않는 자」 — 한 번도 들키지 않고 성문까지"
	elif st.get("alarms", 0) == 0:
		title = "칭호 「밤의 그림자」 — 경보 종 한 번 울리지 않고 성문까지"
	if title != "":
		_text(Vector2(0, 148), title, 10, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 640)
	else:
		_text(Vector2(0, 148), "경보 종을 한 번도 울리지 않고 끝내면 칭호를 얻는다", 8, Color(0.7, 0.7, 0.7), HORIZONTAL_ALIGNMENT_CENTER, 640)
	var t: float = st.get("time", 0.0)
	var rows := [
		"시간 %d분 %02d초   ·   처치 %d (조용히 %d)" % [int(t) / 60, int(t) % 60, st.get("kills", 0), st.get("silent", 0)],
		"들킨 횟수 %d   ·   경보 %d   ·   부하가 쓰러진 횟수 %d   ·   체크포인트에서 다시 %d" % [st.get("detected", 0), st.get("alarms", 0), st.get("downs", 0), st.get("retries", 0)],
		"골라서 하는 목표   %s 정찰병 구출   ·   %s 무기고 불태우기" % ["●" if st.get("scout", false) else "○", "●" if st.get("armory", false) else "○"],
	]
	for i in rows.size():
		_text(Vector2(0, 178 + i * 16), rows[i], 8, Color(0.9, 0.9, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 640)
	_text(Vector2(0, 240), "다음: CHAPTER 2 — 귀환의 시작 (준비 중)", 7, Color(0.65, 0.65, 0.65), HORIZONTAL_ALIGNMENT_CENTER, 640)


func _draw_overlay() -> void:
	canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.7))
	if overlay == "clear":
		_draw_clear_result()
		return
	_text(Vector2(0, 150), "오디세우스가 쓰러졌다", 18, Color(1, 0.5, 0.45), HORIZONTAL_ALIGNMENT_CENTER, 640)
	if not Game.checkpoint.is_empty():
		_text(Vector2(0, 228), "체크포인트: " + CHECKPOINT_NAMES.get(Game.checkpoint["id"], "") + "  (골라서 하는 목표는 그대로)", 7, Color(0.55, 0.85, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 640)
	var t: float = overlay_stats.get("time", 0.0)
	_text(Vector2(0, 212), "처치 %d   ·   부하가 쓰러진 횟수 %d   ·   %d분 %02d초" % [overlay_stats.get("kills", 0), overlay_stats.get("downs", 0), int(t) / 60, int(t) % 60], 8, Color(0.9, 0.9, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 640)
