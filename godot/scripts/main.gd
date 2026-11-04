extends Node
## 타이틀 메뉴 → 챕터 시작 → 클리어/사망 화면 → 다시 하기·타이틀.
## 검증용 인자(godot --path . -- <인자>):
##   --play         타이틀을 건너뛰고 바로 챕터 1
##   --continue     저장된 마지막 체크포인트(user://save.json)에서 바로 이어 하기
##   --auto         자동 플레이(봇이 퀘스트를 끝까지 진행, 들키면 싸워서 지나감)
##   --auto=stealth 잠입 봇: 알아채지 못한 적은 활·뒤 처치로 조용히 쓰러뜨리며 지나감(경보 0이 목표)
##   --shot=경로     몇 초 뒤 화면을 PNG로 저장하고 종료 (--shot-at=초, 기본 3)
##   --start=gate   성문 경비대 앞에서 시작
##   --start=winch  성문 경비대를 치운 뒤 권양기 앞에서 시작
##   --start=ending 성문 거점을 다 차지한 것으로 하고 바로 엔딩(부두 → 출항 → 챕터 2 예고)
##   --showcase     오디세우스 8방향(무기 장착)을 한 줄로 세워 보여 줌
##   --god          오디세우스가 죽지 않음(흐름 확인용)
##   --menu=pause   1초 뒤 일시정지 메뉴를 띄움 (--menu=settings는 설정 화면)
##   --at=x,y       오디세우스를 그 칸에 옮겨 놓음(맵 화면 확인용, 적은 그대로)

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
	if args.has("continue") and not Game.progress.get("checkpoint", {}).is_empty():
		Game.checkpoint = Game.progress["checkpoint"].duplicate(true)
		start_chapter(true)
	elif args.has("play") or args.has("auto") or args.has("start") or args.has("showcase"):
		start_chapter()
	else:
		_show_menu()
	if args.has("menu") and hud:
		# 검증용(--menu=pause|settings): 일시정지 메뉴·설정 화면을 띄운 채로
		await get_tree().create_timer(1.0, true, false, true).timeout
		hud.open_pause()
		if args["menu"] == "settings":
			hud.pause_menu._show_settings()
	if args.has("shot"):
		_take_shot(String(args["shot"]), float(args.get("shot-at", "3")), int(args.get("shots", "1")))
	if args.has("quit-after"):
		await get_tree().create_timer(float(args["quit-after"]), true, false, true).timeout
		_report_and_quit()


## from_checkpoint면 마지막 체크포인트(Game.checkpoint)의 기록·골라서 하는 목표로 그 자리부터 다시 시작한다.
func start_chapter(from_checkpoint := false) -> void:
	_clear()
	get_tree().paused = false
	var cp: Dictionary = Game.checkpoint if from_checkpoint else {}
	Game.reset_run()
	Game.checkpoint = {}
	if not cp.is_empty():
		Game.stats = cp["stats"].duplicate()
		for k in Game.stats:   # 저장 파일(JSON)에서 읽으면 수가 실수로 온다
			if k != "time" and Game.stats[k] is float:
				Game.stats[k] = int(Game.stats[k])
		Game.stats["retries"] = Game.stats.get("retries", 0) + 1
	Game.apply_chapter_outfit(1)
	level = Chapter1Troy.new()
	add_child(level)
	hud = Hud.new()
	add_child(hud)
	hud.restart_requested.connect(start_chapter)
	hud.menu_requested.connect(_show_menu)
	hud.checkpoint_requested.connect(func(): start_chapter(true))
	if not cp.is_empty():
		(level as Chapter1Troy).restore_checkpoint(cp)
		return
	var c: Array = CHAPTERS[0]
	hud.show_title([c[0], c[1], c[2]])
	if args.has("god"):
		level.player.max_hp = 99999.0
		level.player.hp = 99999.0
	if args.has("showcase"):
		_showcase()
	if args.has("at"):
		var xy := String(args["at"]).split(",")
		level.player.position = Iso.grid_to_world(Vector2(float(xy[0]), float(xy[1])))
		level.sinon.talk.enabled = false
	if args.get("start", "") == "gate":
		(level as Chapter1Troy).skip_to_gate()
	elif args.get("start", "") == "winch":
		(level as Chapter1Troy).skip_to_winch()
	elif args.get("start", "") == "ending":
		(level as Chapter1Troy).skip_to_ending()


func _showcase() -> void:
	var lv: Chapter1Troy = level
	lv.sinon.talk.enabled = false
	for e in lv.enemies():
		e.queue_free()
	var base := lv.player.position + Vector2(-150, -40)
	for d in 8:
		var n := Npc.new()
		n.setup(Game.outfit, "오디세우스", func(_b): pass)
		n.fixed_dir = d
		n.cycle = String(args.get("anim", "idle")).split(",")
		n.fixed_anim = n.cycle[0]
		n.play_speed = float(args.get("speed", 1.0))
		n.freeze_frame = int(args.get("frame", -1))
		n.cycle_time = float(args.get("hold", 0.9))
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
	Bgm.play("theme", 2.0)
	Bgm.amb_stop_all()
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
	_label(menu, "ODYSSEY", Vector2(0, 30), 34, Color(0.95, 0.78, 0.38))
	_label(menu, "오디세우스의 귀환", Vector2(0, 76), 12, Color(0.9, 0.88, 0.82))
	var y := 98.0
	var first: Button = null
	# 이어 하기: 저장된 마지막 체크포인트(user://save.json)
	var saved: Dictionary = Game.progress.get("checkpoint", {})
	if not saved.is_empty():
		var cb := _menu_button("이어 하기 — CHAPTER 1 · 체크포인트: %s" % Hud.CHECKPOINT_NAMES.get(saved.get("id", ""), "?"), y, func():
			Game.checkpoint = saved.duplicate(true)
			start_chapter(true))
		first = cb
		y += 29
	for i in CHAPTERS.size():
		var c: Array = CHAPTERS[i]
		var done := "  ✓" if Game.is_cleared(i + 1) else ""
		var b := _menu_button("%s  %s%s%s" % [c[0], c[1], done, "" if c[3] else "  (준비 중)"], y, start_chapter)
		b.disabled = not c[3]
		if first == null and c[3]:
			first = b
		y += 23
	_menu_button("설정 · 키 바꾸기", y + 4, func():
		var pm := PauseMenu.new()
		pm.settings_only = true
		pm.resumed.connect(func(): if first: first.grab_focus())
		menu.add_child(pm))
	if first:
		first.grab_focus()
	_label(menu, Game.keys_text("{move_up}{move_left}{move_down}{move_right} 이동 · {attack}/좌클릭 공격 · {block}/우클릭 방패 · {dodge} 구르기 · {interact} 상호작용 · {cmd_follow}~{cmd_special} 부대 명령 · {help} 조작법 · {pause} 일시정지"), Vector2(0, 300), 7, Color(0.75, 0.75, 0.75))
	_label(menu, Game.keys_text("마우스 없이: 메뉴는 방향키·WASD로 고르고 Enter/{interact}, 조준은 {attack}·{block}·방향키를 쓰면 바라보는 쪽의 적"), Vector2(0, 314), 7, Color(0.75, 0.75, 0.75))
	_label(menu, "임시 픽셀아트는 tools/의 생성기로 만든 것이다. assets/의 그림을 같은 규칙으로 바꾸면 그대로 반영된다.", Vector2(0, 340), 6, Color(0.5, 0.5, 0.5))


func _menu_button(text: String, y: float, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(190, y)
	b.size = Vector2(260, 20)
	b.add_theme_font_size_override("font_size", 9)
	b.pressed.connect(cb)
	menu.add_child(b)
	return b


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
		info["gate_open"] = lv.get("gate_open")
		info["ending"] = lv.get("ending_done")
		if Game.player:
			info["player_hp"] = Game.player.hp
		info["enemies_alive"] = lv.enemies().size()
		info["enemies"] = lv.enemies().map(func(e): return "%s %s %s %s" % [e.kind, Iso.world_to_grid(e.global_position).snapped(Vector2(0.1, 0.1)), e.phase, e.target != null])
		info["player_cell"] = Iso.world_to_grid(Game.player.global_position).snapped(Vector2(0.1, 0.1))
		info["squad_hp"] = Game.squad.members.map(func(m): return int(m.hp))
	print("REPORT ", JSON.stringify(info))
	# 소리를 멈추고 오디오 스레드가 놓을 때까지 두 프레임 기다린 뒤 끝낸다(끝낼 때 남는 재생 경고 줄이기)
	Sfx.clear()
	Bgm.clear()
	for p in Game.get_children():
		if p is AudioStreamPlayer:
			p.free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
