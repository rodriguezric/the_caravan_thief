extends Node
## Root of the game shell. Owns the layers (field, battles, cinematics, UI),
## the screen flow (company card -> opening -> title -> continue / new game /
## endings / achievements / records / settings / quit), fades and wipes, the
## pause menu, toasts, and the little notes that pop up when a choice changes
## something. The story lives in Story; main is the stage.

const WIPE_SHADER := """
shader_type canvas_item;
uniform float progress = 0.0;
uniform vec4 tint : source_color = vec4(0.106, 0.075, 0.125, 1.0);
void fragment() {
	vec2 p = floor(FRAGCOORD.xy);
	// diagonal slashes, like a blade cutting across the screen
	float band = fract((p.x * 0.5 + p.y) / 24.0);
	float sweep = (p.x + p.y * 0.9) / 480.0;
	float t = progress * 2.0 - sweep;
	COLOR = vec4(tint.rgb, step(band, t));
}
"""

var world: World
var world_root: Node2D
var battle_layer: CanvasLayer
var cine_layer: CanvasLayer
var ui: CanvasLayer
var dialog: DialogBox
var fade_rect: ColorRect
var wipe: ColorRect
var story: Story
var notes: VBoxContainer
var shake_t := 0.0
var shake_amt := 0.0
var _toasts: Array = []
var _toasting := false
var in_story := false
## Toasts wait while a results or ending screen is up, so they never cover it.
var hold_toasts := false
## Bumped whenever something takes over the screen (a fade to ink, a new
## cutscene), so a pending "back to the field" reveal knows to stand down.
var screen_claim := 0


func _ready() -> void:
	Game.main = self
	_setup_input()
	world_root = Node2D.new()
	add_child(world_root)
	battle_layer = CanvasLayer.new()
	battle_layer.layer = 5
	add_child(battle_layer)
	cine_layer = CanvasLayer.new()
	cine_layer.layer = 8
	add_child(cine_layer)
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	dialog = DialogBox.new()
	ui.add_child(dialog)
	notes = VBoxContainer.new()
	notes.position = Vector2(6, 22)
	notes.add_theme_constant_override("separation", 1)
	ui.add_child(notes)
	wipe = ColorRect.new()
	wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = WIPE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	wipe.material = mat
	ui.add_child(wipe)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(Pal.INK, 1.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade_rect)
	story = Story.new()
	add_child(story)
	Sfx.prerender(["title", "camp", "battle", "victory", "road"])
	if OS.get_environment("CT_TEST") != "" and not Engine.has_meta("ct_skip_opening"):
		# the autotest lives on the root so it survives a scene reload
		if get_tree().root.get_node_or_null("Autotest") == null:
			var at: Node = load("res://tools/autotest.gd").new()
			at.name = "Autotest"
			get_tree().root.add_child.call_deferred(at)
		return
	if "--faces" in OS.get_cmdline_user_args():
		# ./faces: the character / expression viewer (tools/face_viewer.gd)
		Game.testing = true
		cine_layer.add_child(load("res://tools/face_viewer.gd").new())
		fade_in(0.2)
		return
	var sc := _arg("--scene=")
	if sc != "":
		# ./run_scene S6: jump straight into a scene (nothing saved)
		Game.testing = true
		Game.new_run()
		Game.run.scene = sc
		story.prepare_jump(sc)
		await play_story()
		get_tree().quit()
		return
	boot()


func boot() -> void:
	## Company card, opening, then title. Back from the story via the pause
	## menu, the scene is rebuilt and goes straight to the title.
	if Engine.has_meta("ct_skip_opening"):
		Engine.remove_meta("ct_skip_opening")
		title()
		return
	await company_splash()
	await opening()
	title()


func _arg(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""


func _setup_input() -> void:
	var binds := {
		"accept": [KEY_Z, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER, KEY_J],
		"cancel": [KEY_X, KEY_ESCAPE, KEY_BACKSPACE],
		"up": [KEY_UP, KEY_W],
		"down": [KEY_DOWN, KEY_S],
		"left": [KEY_LEFT, KEY_A],
		"right": [KEY_RIGHT, KEY_D],
		"run": [KEY_SHIFT],
	}
	var pads := {"accept": [JOY_BUTTON_A], "cancel": [JOY_BUTTON_B, JOY_BUTTON_START], "up": [JOY_BUTTON_DPAD_UP],
		"down": [JOY_BUTTON_DPAD_DOWN], "left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT], "run": [JOY_BUTTON_X]}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for k in binds[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		for b in pads.get(action, []):
			var j := InputEventJoypadButton.new()
			j.button_index = b
			InputMap.action_add_event(action, j)
	for pair in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)


func _process(delta: float) -> void:
	if shake_t > 0.0 and Game.shake_on():
		shake_t -= delta
		var a := int(ceilf(shake_amt * minf(1.0, shake_t * 4.0)))
		var o := Vector2(randi_range(-a, a), randi_range(-a, a))
		world_root.position = o
		cine_layer.offset = o
		battle_layer.offset = o
	else:
		shake_t = 0.0
		world_root.position = Vector2.ZERO
		cine_layer.offset = Vector2.ZERO
		battle_layer.offset = Vector2.ZERO


func shake(amount: float, t: float) -> void:
	shake_amt = maxf(amount, shake_amt if shake_t > 0 else 0.0)
	shake_t = maxf(t, shake_t)


# ------------------------------------------------------------ screen flow --

func company_splash() -> void:
	var c := CompanySplash.new()
	cine_layer.add_child(c)
	await fade_in(0.6)
	await c.run()
	c.queue_free()
	fade_rect.color = Color(Pal.INK, 1.0)


func opening() -> void:
	var o := Opening.new()
	cine_layer.add_child(o)
	await fade_in(0.4)
	await o.run()
	await fade_out(0.4)
	o.queue_free()


func title() -> void:
	in_story = false
	Sfx.music("title", 1.5)
	clear_world()
	var t := TitleScreen.new()
	cine_layer.add_child(t)
	await fade_in(0.8)
	var choice: String = await t.run()
	await fade_out(0.5)
	t.queue_free()
	match choice:
		"continue":
			if Game.load_run(Game.slot):
				await play_story()
			title()
		"new":
			Game.new_run()
			await play_story()
			title()
		"endings":
			await open_screen(EndingsScreen.new())
			title()
		"settings":
			await open_screen(SettingsScreen.new())
			title()
		"records":
			await open_screen(RecordsScreen.new())
			title()
		"achievements":
			await open_screen(AchievementsScreen.new())
			title()
		"quit":
			get_tree().quit()


func open_screen(s: Control) -> void:
	cine_layer.add_child(s)
	await fade_in(0.3)
	await s.run()
	await fade_out(0.3)
	s.queue_free()


func play_story() -> void:
	in_story = true
	var result: Dictionary = await story.play()
	in_story = false
	if result.is_empty():
		return
	# Achievements the ending unlocks would toast over the ending's big title
	# (top right is where both live), so hold them until the card is gone.
	hold_toasts = true
	var fresh := Game.record_ending(result.ending, result)
	var card := EndingCard.new()
	card.setup(result.ending, fresh, result)
	clear_world()
	cine_layer.add_child(card)
	await fade_in(0.8)
	await card.run()
	await fade_out(0.6)
	card.queue_free()
	hold_toasts = false


func _drop_cinemas() -> void:
	for c in cine_layer.get_children():
		if c is Cinema:
			c.queue_free()


func clear_world() -> void:
	if world:
		world.queue_free()
		world = null
	for c in cine_layer.get_children():
		if c is Cinema:
			c.queue_free()
	dialog.close()


# ------------------------------------------------------------- field flow --

func load_map(map_def: Dictionary, tile: Vector2i, dir: int) -> World:
	if world:
		world.queue_free()
	world = World.new()
	world_root.add_child(world)
	world.setup(map_def, tile, dir, story)
	return world


func wipe_in() -> void:
	var mat := wipe.material as ShaderMaterial
	if Game.reduced_motion():
		mat.set_shader_parameter("progress", 1.0)
		return
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.45)
	await tw.finished


func wipe_out() -> void:
	var mat := wipe.material as ShaderMaterial
	if Game.reduced_motion():
		mat.set_shader_parameter("progress", 0.0)
		return
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.4)
	await tw.finished


func battle(def: Dictionary) -> Dictionary:
	## Runs a battle to its results screen. Returns the summary.
	if world:
		world.hold("battle")
	var prev_song := Sfx.current_song
	Sfx.play("sword_draw" if Game.flag("has_sword") else "slash", 1.0, -6.0)
	flash(Pal.WHITE, 0.15, 0.6)
	await wipe_in()
	_drop_cinemas()
	dialog.close()
	var b := Battle.new()
	battle_layer.add_child(b)
	b.setup(def)
	await get_tree().process_frame
	if world:
		world.visible = false
	await wipe_out()
	var summary: Dictionary = await b.run()
	await fade_out(0.4)
	b.queue_free()
	Engine.time_scale = 1.0
	Game.record_battle(summary)
	if world:
		world.visible = true
		world.release("battle")
	if prev_song != "" and not def.get("keep_music", false):
		Sfx.music(prev_song, 0.8)
	if not def.get("stay_dark", false):
		reveal_soon(0.4)
	return summary


func minigame(kind: String, opts: Dictionary = {}) -> Dictionary:
	## Runs one minigame full-screen. Returns its result.
	if world:
		world.hold("minigame")
	var prev_song := Sfx.current_song
	await fade_out(0.3)
	_drop_cinemas()
	var g := Minigame.create(kind, opts)
	cine_layer.add_child(g)
	await fade_in(0.3)
	var res: Dictionary = await g.play()
	await fade_out(0.3)
	g.queue_free()
	if world:
		world.release("minigame")
	if prev_song != "" and not opts.get("keep_music", false):
		Sfx.music(prev_song, 0.8)
	if not opts.get("stay_dark", false):
		reveal_soon(0.3)
	return res


func claim_screen() -> void:
	screen_claim += 1


func reveal_soon(t: float = 0.4) -> void:
	## Fade back in to the field after a battle or minigame, unless whatever
	## the story does next (a cutscene, a scene card) takes the screen first,
	## so the old field never flashes up in between.
	var c0 := screen_claim
	for i in 2:
		await get_tree().process_frame
	if screen_claim == c0:
		await fade_in(t)


func fade_out(t: float = 0.3, c: Color = Pal.INK) -> void:
	claim_screen()
	fade_rect.color = Color(c, fade_rect.color.a)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, t)
	await tw.finished


func fade_in(t: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, t)
	await tw.finished


func flash(c: Color, t: float, a: float = 0.85) -> void:
	if Game.reduced_motion():
		a *= 0.4
	fade_rect.color = Color(c, a)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, t)
	await tw.finished
	fade_rect.color = Color(Pal.INK, 0.0)


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


# ---------------------------------------------------------- choice notes --

func stat_note(name: String, delta: int) -> void:
	## A small tab that slides in at the top left when a choice moves one of
	## the story's variables: the name, an arrow, a colour by meaning.
	var label: String = Game.VAR_NAMES.get(name, name.to_upper())
	var up := delta > 0
	var arrow := "+" if up else "-"
	var n := absi(delta)
	var text := "%s %s" % [label, arrow.repeat(mini(n, 3))]
	var c := Pal.CREAM
	match name:
		"suspicion", "reliance":
			c = Pal.OMEN
		"loyalty", "mara", "fen":
			c = Pal.GLOW if up else Pal.BLOOD.lerp(Pal.WHITE, 0.3)
		"finesse":
			c = Pal.CANDLE
		"refusals":
			c = Pal.SKY
			text = "YOU REFUSED THE BLADE"
		"coin":
			c = Pal.BRASS
			text = "COIN %s%d" % [arrow, n]
	_note(text, c, "omen_box" if name in ["suspicion", "reliance"] else "bar_box")
	Sfx.play("buff" if up and name not in ["suspicion", "reliance"] else ("omen" if name in ["suspicion", "reliance"] and up else "debuff"), 1.2, -16.0)


func item_note(id: String, got: bool) -> void:
	_note(("GOT: " if got else "LOST: ") + str(Data.item(id).name), Pal.BRASS.lerp(Pal.LEMON, 0.4), "gold_box")
	Sfx.play("coin", 1.0, -10.0)


func lore_note(id: String) -> void:
	_note("A VAULT CLUE" if id == "clue" else "LORE LEARNED", Pal.OMEN.lerp(Pal.WHITE, 0.4), "omen_box")
	Sfx.play("chime" if id != "clue" else "jingle", 0.9, -10.0)


func _note(text: String, c: Color, box: String) -> void:
	# in battle the top of the screen belongs to the turn order and help line
	notes.position = Vector2(6, 40) if story.current_battle() != null else Vector2(6, 22)
	var b := Art.make_box(box)
	b.custom_minimum_size = Vector2(Art.text_width(text) + 12, 14)
	var l := Art.label(text, c)
	l.position = Vector2(6, 2)
	b.add_child(l)
	notes.add_child(b)
	b.modulate.a = 0.0
	var tw := b.create_tween()
	tw.tween_property(b, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(l, "position:x", 6.0, 0.2).from(-10.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(b, "modulate:a", 0.0, 0.3)
	tw.tween_callback(b.queue_free)


# ------------------------------------------------------------------ toasts --

func toast_achievement(a: Dictionary) -> void:
	if a.is_empty():
		return
	_toasts.append(a)
	if not _toasting:
		_show_toasts()


func _show_toasts() -> void:
	## A gold card slides in at the top right; queued so they never overlap.
	_toasting = true
	while not _toasts.is_empty():
		while hold_toasts:
			await get_tree().process_frame
		var a: Dictionary = _toasts.pop_front()
		var box := Art.make_box("gold_box")
		box.size = Vector2(160, 30)
		box.position = Vector2(330, 4)
		ui.add_child(box)
		ui.move_child(box, fade_rect.get_index())
		var ic := TextureRect.new()
		ic.position = Vector2(4, 3)
		ic.texture = Art.achievement(a, true)
		box.add_child(ic)
		var h := Art.label("ACHIEVEMENT UNLOCKED", Pal.TEXT_DIM)
		h.position = Vector2(32, 3)
		box.add_child(h)
		var n := Art.label(str(a.name), Pal.LEMON)
		n.position = Vector2(32, 15)
		n.clip_text = true
		box.add_child(n)
		box.size.x = maxf(160.0, minf(310.0, Art.text_width(str(a.name)) + 40.0))
		n.size = Vector2(box.size.x - 36, 10)
		Sfx.play("jingle", 1.0, -6.0)
		var tw := box.create_tween()
		tw.tween_property(box, "position:x", 316.0 - box.size.x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(2.6)
		tw.tween_property(box, "position:x", 330.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# a hold that starts mid-toast (an ending card coming up) tucks this one
		# away at once and shows it again from the start once the hold lifts
		while tw.is_running() and not hold_toasts:
			await get_tree().process_frame
		if tw.is_running():
			tw.kill()
			var away := box.create_tween()
			away.tween_property(box, "position:x", 330.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			await away.finished
			_toasts.push_front(a)
		box.queue_free()
	_toasting = false


# ------------------------------------------------------------- pause menu --

func field_menu() -> void:
	world.hold("menu")
	Sfx.play("confirm")
	var p := PauseMenu.new()
	ui.add_child(p)
	# beneath the dialog box, so any text it brings up reads on top
	ui.move_child(p, dialog.get_index())
	var r: String = await p.run()
	p.queue_free()
	if r == "title":
		story.abort()
		return
	if is_instance_valid(world):
		world.release("menu")
