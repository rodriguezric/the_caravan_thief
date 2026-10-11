class_name Opening
extends Control
## The opening: the Sword Stories prologue. In the dark, the blade falls
## point-first through the ages and buries itself in desert sand with a puff
## of dust; its violet stone opens like an eye; a crow lands on the guard.
## Three lines of text. Skippable at any point; skipping and finishing land in
## the same place.

var t := 0.0
var drawer: Node2D
var sword: Sprite2D
var crow: Sprite2D
var words: Label
var skip_l: Label
var done := false
var landed := false
var ground_y := 132.0
var eye_open := 0.0
var fx: Fx


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Pal.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_fx)
	add_child(drawer)
	sword = Sprite2D.new()
	sword.texture = Art.prop("sword_prop", 0)
	sword.position = Vector2(160, -80)
	add_child(sword)
	crow = Sprite2D.new()
	crow.centered = false
	crow.offset = -ArtPeople.FOOT
	crow.visible = false
	add_child(crow)
	fx = Fx.new()
	add_child(fx)
	words = Art.shadow_label("", Pal.CREAM)
	words.position = Vector2(0, 150)
	words.size = Vector2(320, 12)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.modulate.a = 0.0
	add_child(words)
	skip_l = Art.label("Z  skip", Pal.TEXT_DIM)
	skip_l.position = Vector2(276, 166)
	add_child(skip_l)


func _process(delta: float) -> void:
	t += delta
	drawer.queue_redraw()


func _draw_fx() -> void:
	# falling streaks of time behind the blade
	if not landed:
		for k in 30:
			var x := 60.0 + Pal.hash2(k, 1) * 200.0
			var y := fmod(t * (200.0 + Pal.hash2(k, 2) * 200.0) + Pal.hash2(k, 3) * 180.0, 200.0) - 10.0
			drawer.draw_line(Vector2(x, y), Vector2(x, y - 8), Color(Pal.OMEN, 0.25), 1.0)
	else:
		# the dune the blade fell into
		for x in 320:
			var top := ground_y + sin(x * 0.03) * 3.0 + absf(x - 160) * 0.05
			drawer.draw_rect(Rect2(Vector2(x, top), Vector2(1, 180 - top)), Pal.DUNE.lerp(Pal.INK, 0.55))
			drawer.draw_rect(Rect2(Vector2(x, top), Vector2(1, 1)), Pal.DUNE.lerp(Pal.INK, 0.3))
		if eye_open > 0.0:
			var c := sword.position + Vector2(0, -55)
			drawer.draw_circle(c, 10.0 * eye_open, Color(Pal.OMEN, 0.18))
			drawer.draw_circle(c, 5.0 * eye_open, Color(Pal.OMEN, 0.3))


func _say(text: String, hold: float) -> bool:
	words.text = text
	var tw := create_tween()
	tw.tween_property(words, "modulate:a", 1.0, 0.6)
	var e := 0.0
	while e < hold:
		await get_tree().process_frame
		e += get_process_delta_time()
		if _skip():
			return true
	await create_tween().tween_property(words, "modulate:a", 0.0, 0.4).finished
	return false


func _skip() -> bool:
	return Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("cancel")


func run() -> void:
	Sfx.play("wind", 1.0, -10.0)
	if await _say("SWORD STORIES", 1.6):
		return _finish()
	# 1: the blade falls through the ages
	Sfx.play("whisper", 0.7, -6.0)
	var e := 0.0
	while e < 1.6:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		e += dt
		sword.position.y = lerpf(-80.0, 60.0, ease(e / 1.6, 2.2))
		if _skip():
			return _finish()
	# 2: it lands, point first, in the sand
	landed = true
	sword.position.y = 72
	Sfx.play("thud", 0.8, -2.0)
	Game.main.shake(3.0, 0.4)
	fx.burst(Vector2(160, ground_y), 40, [Pal.SAND, Pal.DUNE, Pal.CREAM], Vector2(20, 90), Vector2(0.5, 1.2), {"up": 50.0, "acc": Vector2(0, 90), "size": 2.0, "size_end": 1.0})
	var tw := create_tween()
	tw.tween_property(sword, "position:y", 68.0, 0.08)
	tw.tween_property(sword, "position:y", 72.0, 0.12)
	e = 0.0
	while e < 0.8:
		await get_tree().process_frame
		e += get_process_delta_time()
		if _skip():
			return _finish()
	# 3: the stone opens like an eye
	Sfx.play("omen", 1.0, -4.0)
	create_tween().tween_method(func(v: float) -> void: eye_open = v, 0.0, 1.0, 0.8)
	if await _say("Every age has its blade.", 1.6):
		return _finish()
	# 4: a crow lands on the guard
	crow.visible = true
	crow.position = Vector2(340, 20)
	Sfx.play("caw", 1.0, -6.0)
	var ct := 0.0
	var from := crow.position
	var to := Vector2(166, 42)
	while ct < 1.0:
		await get_tree().process_frame
		ct += get_process_delta_time() / 0.9
		crow.position = from.lerp(to, minf(1.0, ct)).round()
		crow.texture = Art.person(Data.spec("crow"), 2, int(ct * 12) % 2, "", "fly")
		crow.flip_h = true
		if _skip():
			return _finish()
	crow.texture = Art.person(Data.spec("crow"), 2, 0, "", "walk")
	if await _say("Every blade, its bearer.", 1.6):
		return _finish()
	if await _say("This one wanted to be remembered.", 2.0):
		return _finish()
	_finish()


func _finish() -> void:
	## Skip and completion both end here, exactly once.
	if done:
		return
	done = true
	Sfx.play("confirm", 0.8, -14.0)
