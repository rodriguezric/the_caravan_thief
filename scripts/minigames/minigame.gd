class_name Minigame
extends Control
## Base for every minigame: a title card with how-to-play, a countdown, the
## game itself, and a result banner. Works full-screen on the field and as an
## interjection inside battles (in_battle). Subclasses implement _game() and
## draw in _draw_game(d) on a pixel-true drawer.
## play() returns {id, score (0-100 or raw), raw, perfect, success, ...}.

var opts: Dictionary = {}
var in_battle := false
var t := 0.0
var drawer: Node2D
var bg: TextureRect
var hud: Control
var running := false
var id := "minigame"
var title_text := "MINIGAME"
var help_text := ""
var keys_text := ""
var bg_name := "ink"
var song := "minigame"
var keep_song := false
## Touch layout for this game (see TouchControls) and optional tilt steering.
var touch_layout := ""
var touch_tilt := ""
const TOUCH := {"lockpick": ["tap", ""], "pickpocket": ["hold", ""], "loot": ["pad", ""]}


static func create(kind: String, p_opts: Dictionary = {}) -> Minigame:
	var g: Minigame
	match kind:
		"lockpick":
			g = MgLockpick.new()
		"pickpocket":
			g = MgPickpocket.new()
		"loot":
			g = MgLoot.new()
		_:
			g = Minigame.new()
	g.id = kind
	g.opts = p_opts
	var t: Array = TOUCH.get(kind, ["", ""])
	g.touch_layout = t[0]
	g.touch_tilt = t[1]
	g.configure()
	return g


func configure() -> void:
	pass


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	bg = TextureRect.new()
	bg.texture = Art.cine(bg_name, 0)
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(func() -> void: _draw_game(drawer))
	add_child(drawer)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	setup_game()


func setup_game() -> void:
	pass


func _process(delta: float) -> void:
	t += delta
	tick(delta)
	drawer.queue_redraw()


func tick(_delta: float) -> void:
	pass


func _draw_game(_d: Node2D) -> void:
	pass


func play() -> Dictionary:
	if not keep_song:
		Sfx.music(song, 0.4)
	var prev_layout := Game.touch_layout
	Game.touch_layout = touch_layout
	Game.touch_tilt = touch_tilt
	await _title_card()
	await _countdown()
	running = true
	Game.touch_running = true
	var res: Dictionary
	var auto := OS.get_environment("CT_AUTOPLAY")
	if auto != "":
		# automated test runs: let the game run briefly, then resolve it
		await get_tree().create_timer(float(OS.get_environment("CT_AUTOPLAY_T")) if OS.get_environment("CT_AUTOPLAY_T") != "" else 1.0).timeout
		res = auto_result(auto == "win")
	else:
		res = await _game()
	running = false
	Game.touch_running = false
	res.id = id
	await _result_banner(res)
	Game.record_minigame(id, int(res.get("raw", res.get("score", 0))))
	Achievements.check()
	Game.touch_layout = prev_layout
	Game.touch_tilt = ""
	return res


func _title_card() -> void:
	var box := Art.make_box("gold_box")
	var lines: Array = Art.wrap(help_text, 220)
	box.size = Vector2(240, 44 + lines.size() * 10)
	box.position = Vector2(40, 90 - box.size.y / 2.0)
	box.z_index = 50
	add_child(box)
	var big := Art.shadow_label(title_text, Pal.LEMON, 2)
	var w := Art.text_width(title_text, 2)
	if w > 228:
		big = Art.shadow_label(title_text, Pal.LEMON, 1)
		w = Art.text_width(title_text)
	big.position = Vector2(120 - w / 2.0, 6)
	box.add_child(big)
	var y := 28.0
	for ln in lines:
		var l := Art.label(ln, Pal.TEXT)
		l.position = Vector2(10, y)
		box.add_child(l)
		y += 10
	var k := Art.label(keys_text + "      Z start", Pal.TEXT_DIM)
	k.position = Vector2(120 - Art.text_width(k.text) / 2.0, y + 4)
	box.add_child(k)
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2(1, 0.2)
	create_tween().tween_property(box, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("pop")
	await get_tree().process_frame
	await get_tree().process_frame
	while not Input.is_action_just_pressed("accept"):
		if OS.get_environment("CT_TEST") != "" and t > 0.6:
			break
		await get_tree().process_frame
	Sfx.play("confirm")
	await create_tween().tween_property(box, "modulate:a", 0.0, 0.15).finished
	box.queue_free()


func _countdown() -> void:
	for s in ["3", "2", "1", "GO!"]:
		var l := Art.shadow_label(s, Pal.LEMON if s != "GO!" else Pal.GLOW, 3)
		l.position = Vector2(160 - Art.text_width(s, 3) / 2.0, 70)
		l.pivot_offset = Vector2(Art.text_width(s, 3) / 2.0, 15)
		l.scale = Vector2(1.6, 1.6)
		l.z_index = 50
		add_child(l)
		Sfx.play("blip" if s != "GO!" else "confirm", 1.0 if s != "GO!" else 1.2)
		var tw := l.create_tween()
		tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.25 if s != "GO!" else 0.15)
		tw.tween_property(l, "modulate:a", 0.0, 0.12)
		tw.tween_callback(l.queue_free)
		await get_tree().create_timer(0.45 if s != "GO!" else 0.2).timeout


func _result_banner(res: Dictionary) -> void:
	var score: int = int(res.get("score", 0))
	var word := "MISS..."
	var col := Pal.BLOOD.lerp(Pal.WHITE, 0.3)
	if res.get("perfect", false):
		word = "PERFECT!"
		col = Pal.GLOW
	elif score >= 70:
		word = "GREAT!"
		col = Pal.LEMON
	elif res.get("success", false) or score >= 40:
		word = "OKAY!"
		col = Pal.CREAM
	if res.has("banner"):
		word = res.banner
	var l := Art.shadow_label(word, col, 3)
	l.position = Vector2(160 - Art.text_width(word, 3) / 2.0, 62)
	l.pivot_offset = Vector2(Art.text_width(word, 3) / 2.0, 15)
	l.scale = Vector2(0.2, 0.2)
	l.z_index = 50
	add_child(l)
	var sub := Art.shadow_label(res.get("detail", ""), Pal.TEXT)
	sub.position = Vector2(160 - Art.text_width(sub.text) / 2.0, 96)
	sub.z_index = 50
	add_child(sub)
	Sfx.play("fanfare" if res.get("perfect", false) else ("score" if score >= 40 else "miss"), 1.0, -4.0)
	if res.get("perfect", false):
		Game.buzz(40)
		get_tree().create_timer(0.15).timeout.connect(Game.buzz.bind(40))
	if res.get("perfect", false):
		var f := Fx.new()
		f.z_index = 49
		add_child(f)
		f.burst(Vector2(160, 70), 50, [Pal.LEMON, Pal.BRASS, Pal.CANDLE, Pal.WHITE, Pal.GLOW], Vector2(30, 90), Vector2(1.0, 2.0),
			{"up": 60.0, "acc": Vector2(0, 50), "drag": 0.97, "shape": 3, "size": 2.0, "wobble": 30.0})
	await create_tween().tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).finished
	await get_tree().create_timer(1.3).timeout


func _game() -> Dictionary:
	return {"score": 100, "perfect": true, "success": true}


func auto_result(win: bool) -> Dictionary:
	## What an automated run reports. Subclasses add their own fields.
	return {"score": 100 if win else 20, "raw": 100 if win else 20, "perfect": win, "success": win}


# ---------------------------------------------------------------- helpers --

func pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)


func held(action: String) -> bool:
	return Input.is_action_pressed(action)


func frame() -> float:
	await get_tree().process_frame
	return get_process_delta_time()


func tex(texture: Texture2D, pos: Vector2, d: Node2D, flip: bool = false, k: float = 1.0) -> void:
	## Draws a texture centred at pos, on whole pixels.
	var sz := texture.get_size() * k
	var r := Rect2((pos - sz / 2.0).round(), sz)
	if flip:
		r.size.x = -r.size.x
		r.position.x += sz.x
	d.draw_texture_rect(texture, r, false)


func bar(d: Node2D, pos: Vector2, w: float, h: float, k: float, col: Color) -> void:
	d.draw_rect(Rect2(pos, Vector2(w, h)), Pal.INK)
	d.draw_rect(Rect2(pos + Vector2(1, 1), Vector2((w - 2) * clampf(k, 0.0, 1.0), h - 2)), col)


func hud_label(text: String, pos: Vector2, col: Color = Pal.TEXT) -> Label:
	var l := Art.shadow_label(text, col)
	l.position = pos
	hud.add_child(l)
	return l
