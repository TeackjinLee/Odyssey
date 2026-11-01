extends Node
## 타이틀 메뉴 → 챕터 시작 → 클리어/사망 화면 → 다시 하기·타이틀.
## 검증용 인자(godot --path . -- <인자>):
##   --play         타이틀을 건너뛰고 바로 챕터 1
##   --auto         자동 플레이(봇이 퀘스트를 끝까지 진행)
##   --shot=경로     몇 초 뒤 화면을 PNG로 저장하고 종료 (--shot-at=초, 기본 3)
##   --start=gate   성문 경비대 앞에서 시작
##   --showcase     오디세우스 8방향(무기 장착)을 한 줄로 세워 보여 줌
##   --god          오디세우스가 죽지 않음(흐름 확인용)

const CHAPTERS := [
	["CHAPTER 1", "트로이의 목마", "트로이 성에 잠입하라", true],
	["CHAPTER 2", "귀환의 시작", "배를 몰아 이타카로", false],
	["CHAPTER 3", "외눈박이 거인", "폴리페모스의 동굴에서 탈출하라", false],
	["CHAPTER 4", "키르케의 섬", "돼지가 된 부하들을 구하라", false],
	["CHAPTER 5", "세이렌의 유혹", "노래를 견디고 해역을 빠져나가라", false],
	["CHAPTER 6", "이타카의 귀환", "왕좌와 가족을 되찾아라", false],
]

var level: Node = null
var hud: Hud = null
var menu: Control = null
var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("play") or args.has("auto") or args.has("start") or args.has("showcase"):
		start_chapter()
	else:
		_show_menu()
	if args.has("shot"):
		_take_shot(String(args["shot"]), float(args.get("shot-at", "3")), int(args.get("shots", "1")))
	if args.has("quit-after"):
		await get_tree().create_timer(float(args["quit-after"]), true, false, true).timeout
		_report_and_quit()


func start_chapter() -> void:
	_clear()
	get_tree().paused = false
	Game.reset_run()
	level = Chapter1Troy.new()
	add_child(level)
	hud = Hud.new()
	add_child(hud)
	hud.restart_requested.connect(start_chapter)
	hud.menu_requested.connect(_show_menu)
	var c: Array = CHAPTERS[0]
	hud.show_title([c[0], c[1], c[2]])
	if args.has("god"):
		level.player.max_hp = 99999.0
		level.player.hp = 99999.0
	if args.has("showcase"):
		_showcase()
	if args.get("start", "") == "gate":
		var lv: Chapter1Troy = level
		for e in lv.patrol_group:
			e.queue_free()
		lv.patrol_group.clear()
		lv.sinon.talk.enabled = false
		lv.player.position = Iso.grid_to_world(Vector2(18.5, 12.5))
		for m in lv.squad.members:
			m.position = lv.player.position + Vector2(randf_range(-20, 20), 20)
		lv._set_step(2)


func _showcase() -> void:
	var lv: Chapter1Troy = level
	lv.sinon.talk.enabled = false
	for e in lv.enemies():
		e.queue_free()
	var base := lv.player.position + Vector2(-150, -40)
	for d in 8:
		var n := Npc.new()
		n.setup("odysseus", "오디세우스", func(_b): pass)
		n.fixed_dir = d
		n.position = base + Vector2(d * 38, (d % 2) * 6)
		lv.world.add_child(n)
		n.talk.enabled = false
		n.weapons = WeaponLayer.new()
		n.weapons.attach(n)
	lv.player.position = base + Vector2(140, 60)
	if Game.autoplay:
		var dummy := Enemy.new()
		dummy.setup("trojan_sword")
		dummy.max_hp = 99999.0
		dummy.position = lv.player.position + Vector2(26, 6)
		lv.world.add_child(dummy)
		dummy.attack_cd = 9999.0


func _clear() -> void:
	get_tree().paused = false
	for n in [level, hud, menu]:
		if n and is_instance_valid(n):
			n.queue_free()
	level = null
	hud = null
	menu = null
	Game.level = null
	Game.player = null
	Game.squad = null


func _show_menu() -> void:
	_clear()
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)
	var key := TextureRect.new()
	key.texture = load("res://assets/ui/title_bg.png") if ResourceLoader.exists("res://assets/ui/title_bg.png") else null
	key.set_anchors_preset(Control.PRESET_FULL_RECT)
	key.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	key.modulate = Color(1, 1, 1, 0.45)
	menu.add_child(key)
	_label(menu, "ODYSSEY", Vector2(0, 46), 34, Color(0.95, 0.78, 0.38))
	_label(menu, "오디세우스의 귀환", Vector2(0, 92), 12, Color(0.9, 0.88, 0.82))
	for i in CHAPTERS.size():
		var c: Array = CHAPTERS[i]
		var b := Button.new()
		b.text = "%s  %s%s" % [c[0], c[1], "" if c[3] else "  (준비 중)"]
		b.disabled = not c[3]
		b.position = Vector2(190, 122 + i * 29)
		b.size = Vector2(260, 25)
		b.add_theme_font_size_override("font_size", 9)
		if c[3]:
			b.pressed.connect(start_chapter)
		menu.add_child(b)
	_label(menu, "WASD 이동 · 좌클릭 공격 · 우클릭 방패 · Space 구르기 · E 상호작용 · 1~4 부대 명령 · F1 조작법", Vector2(0, 300), 7, Color(0.75, 0.75, 0.75))
	_label(menu, "임시 픽셀아트는 tools/의 생성기로 만든 것이다. assets/의 그림을 같은 규칙으로 바꾸면 그대로 반영된다.", Vector2(0, 340), 6, Color(0.5, 0.5, 0.5))


func _label(parent: Control, s: String, pos: Vector2, size: int, color: Color) -> void:
	var l := Label.new()
	l.text = s
	l.position = pos
	l.size = Vector2(640, size + 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)


func _take_shot(path: String, delay: float, count := 1) -> void:
	await get_tree().create_timer(delay, true, false, true).timeout
	for i in count:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var p := path if count == 1 else path.replace(".png", "_%02d.png" % i)
		img.save_png(p)
		print("SHOT ", p)
		if count > 1:
			await get_tree().create_timer(0.04, true, false, true).timeout
	if not args.has("quit-after"):
		_report_and_quit()


func _report_and_quit() -> void:
	var lv = level
	var info := {"stats": Game.stats}
	if lv and is_instance_valid(lv):
		info["step"] = lv.get("step")
		info["capture"] = lv.get("capture")
		if Game.player:
			info["player_hp"] = Game.player.hp
		info["enemies_alive"] = lv.enemies().size()
		info["enemies"] = lv.enemies().map(func(e): return "%s %s %s %s" % [e.kind, Iso.world_to_grid(e.global_position).snapped(Vector2(0.1, 0.1)), e.phase, e.target != null])
		info["player_cell"] = Iso.world_to_grid(Game.player.global_position).snapped(Vector2(0.1, 0.1))
		info["squad_hp"] = Game.squad.members.map(func(m): return int(m.hp))
	print("REPORT ", JSON.stringify(info))
	get_tree().quit()
