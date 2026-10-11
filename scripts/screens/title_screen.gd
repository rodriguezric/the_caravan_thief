class_name TitleScreen
extends Control
## Title: the Saltway at dusk, a caravan crossing the horizon. The letters
## surface one by one over a low hum. Now and then Rook walks along the road
## below with the crow circling him. Continue (when there's a save), New
## Game, Endings, Achievements, Records, Settings, Quit.

var t := 0.0
var bg: TextureRect
var drawer: Node2D
var letters: Array = []
var menu: Menu
var walker: Sprite2D
var walk_x := -60.0
var save_line: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	bg = TextureRect.new()
	bg.texture = Art.cine("title", 0)
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_fx)
	add_child(drawer)
	walker = Sprite2D.new()
	walker.centered = false
	walker.offset = -ArtPeople.FOOT
	add_child(walker)
	var word := "THE CARAVAN THIEF"
	var x := 160.0 - Art.text_width(word, 2) / 2.0 - 16
	for i in word.length():
		var l := Art.shadow_label(word[i], Pal.CANDLE.lerp(Pal.LEMON, 0.35), 2)
		l.position = Vector2(x, 20)
		l.modulate.a = 0.0
		add_child(l)
		letters.append(l)
		x += Art.text_width(word[i], 2) + (2 if word[i] != " " else 0)
	var sub := Art.shadow_label("~  SWORD STORIES  ~", Pal.OMEN.lerp(Pal.WHITE, 0.4))
	sub.position = Vector2(160 - Art.text_width(sub.text) / 2.0, 6)
	sub.modulate.a = 0.0
	sub.name = "sub"
	add_child(sub)
	var v := Art.label("v" + str(ProjectSettings.get_setting("application/config/version", "0.0.0")), Pal.TEXT_DIM)
	v.position = Vector2(6, 168)
	add_child(v)


func _process(delta: float) -> void:
	t += delta
	bg.texture = Art.cine("title", int(t * 2.0) % 4)
	# Rook walks the road now and then, the crow wheeling above him
	walk_x += delta * 30.0
	if walk_x > 700.0:
		walk_x = -60.0
	walker.position = Vector2(walk_x, 150)
	walker.texture = Art.person(Data.spec("rook_sword"), 2, int(t * 8.0) % 4, "", "walk")
	drawer.queue_redraw()


func _draw_fx() -> void:
	# the crow circling over Rook
	if walk_x > -40 and walk_x < 360:
		var cp := Vector2(walk_x + cos(t * 1.4) * 22.0, 104 + sin(t * 2.8) * 5.0)
		var up := fmod(t, 0.3) < 0.15
		drawer.draw_rect(Rect2(cp.round(), Vector2(3, 1)), Pal.INK)
		drawer.draw_rect(Rect2(cp.round() + Vector2(-2, -1 if up else 1), Vector2(2, 1)), Pal.INK)
		drawer.draw_rect(Rect2(cp.round() + Vector2(3, -1 if up else 1), Vector2(2, 1)), Pal.INK)
	# dust drifting across the road
	for i in 16:
		var p := Vector2(fmod(Pal.hash2(i, 3) * 320 + t * (8.0 + Pal.hash2(i, 4) * 10.0), 330.0) - 5, 130 + Pal.hash2(i, 5) * 45)
		drawer.draw_rect(Rect2(p.round(), Vector2.ONE), Color(Pal.SAND, 0.4))


func run() -> String:
	# The title surfaces slowly, letter by letter, over a low hum.
	Sfx.play("hum", 1.0, -4.0)
	var step := 0.0 if Game.reduced_motion() else 0.09
	for i in letters.size():
		var l: Label = letters[i]
		var tw := create_tween()
		tw.tween_interval(step * i)
		tw.tween_property(l, "modulate:a", 1.0, 0.7 if step > 0.0 else 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(step * letters.size() + 0.4).timeout
	var sub: Label = get_node("sub")
	create_tween().tween_property(sub, "modulate:a", 1.0, 0.6)
	var keys := []
	var opts := []
	if Game.has_save():
		keys.append("continue")
		opts.append("Continue")
	keys.append_array(["new", "endings", "achievements", "records", "settings", "quit"])
	opts.append_array(["New Game", "Endings", "Achievements", "Records", "Settings", "Quit"])
	menu = Menu.make(self, opts, Vector2(118, 186), Vector2(84, opts.size() * 10 + 7))
	menu.cancellable = false
	menu.index = 0
	menu.set_entries(opts)
	var mt := create_tween()
	mt.tween_property(menu, "position:y", 48.0, 0.35 if step > 0.0 else 0.01).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await mt.finished
	save_line = Art.shadow_label("", Pal.TEXT_DIM)
	add_child(save_line)
	menu.moved.connect(func(i: int) -> void:
		save_line.text = Game.save_summary() if keys[i] == "continue" else ""
		save_line.position = Vector2(160 - Art.text_width(save_line.text) / 2.0, menu.position.y + menu.size.y + 3))
	menu.moved.emit(menu.index)
	var kl := Art.label("Arrows move   Z ok   X back", Pal.TEXT_DIM)
	kl.position = Vector2(314 - Art.text_width(kl.text), 168)
	add_child(kl)
	while true:
		var r := await menu.ask()
		if r < 0:
			continue
		if keys[r] == "new" and Game.has_save():
			var c: int = await Game.main.dialog.ask("Start a new journey? Your saved one will be overwritten when you reach the first scene.", ["Keep my journey", "Start over"])
			if c != 1:
				continue
		return keys[r]
	return "quit"
