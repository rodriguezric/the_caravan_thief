class_name SettingsScreen
extends Control
## Settings: Audio (master, music, effects, voices), Accessibility and pacing
## (reduced motion, screen shake, text speed, battle speed), Controls (the
## bindings, read-only) and Data (reset settings, clear progress, clear
## everything; each names its scope and asks first).
## Changes apply immediately; destructive rows are never the default focus.

var rows: Array = []
var sel := 0
var t := 0.0
var labels: Array = []
var values: Array = []
var bars: Array = []
var cursor: TextureRect
var note: Label
var panel: NinePatchRect
var confirm_open := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.cine("rookery", 0)
	bg.modulate = Color(0.55, 0.55, 0.65)
	add_child(bg)
	var head := Art.make_box("bar_box")
	head.position = Vector2(6, 4)
	head.size = Vector2(70, 16)
	add_child(head)
	var hl := Art.label("SETTINGS", Pal.LEMON)
	hl.position = Vector2(7, 3)
	head.add_child(hl)
	rows = [
		{"kind": "header", "text": "AUDIO"},
		{"kind": "slider", "key": "master", "text": "Master volume"},
		{"kind": "slider", "key": "music", "text": "Music"},
		{"kind": "slider", "key": "sfx", "text": "Sound effects"},
		{"kind": "slider", "key": "voice", "text": "Voices (text blips)"},
		{"kind": "header", "text": "ACCESSIBILITY"},
		{"kind": "toggle", "key": "reduced_motion", "text": "Reduced motion"},
		{"kind": "toggle", "key": "shake", "text": "Screen shake"},
		{"kind": "choice", "key": "text_speed", "text": "Text speed", "opts": ["Slow", "Normal", "Fast"]},
		{"kind": "choice", "key": "battle_speed", "text": "Battle speed", "opts": ["Normal", "Fast"]},
		{"kind": "header", "text": "CONTROLS"},
		{"kind": "info", "text": "Move", "value": "Arrows / WASD / D-pad"},
		{"kind": "info", "text": "OK, talk, examine", "value": "Z / Enter / Space / (A)"},
		{"kind": "info", "text": "Back, pause menu", "value": "X / Esc / (B)"},
		{"kind": "info", "text": "Run", "value": "Shift / (X)"},
		{"kind": "info", "text": "Skip read lines", "value": "Hold Shift in dialog"},
		{"kind": "info", "text": "Touch", "value": "Stick on the left (push far: run)"},
		{"kind": "header", "text": "STORED DATA"},
		{"kind": "action", "key": "reset_settings", "text": "Reset settings to defaults"},
		{"kind": "action", "key": "clear_progress", "text": "Clear progress", "danger": true},
		{"kind": "action", "key": "clear_all", "text": "Clear all stored data", "danger": true},
	]
	panel = Art.make_box("box")
	panel.position = Vector2(6, 24)
	panel.size = Vector2(308, 136)
	panel.clip_contents = true
	add_child(panel)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var l := Art.label(r.text, Pal.CANDLE if r.kind == "header" else (Pal.BLOOD.lerp(Pal.WHITE, 0.3) if r.get("danger", false) else Pal.TEXT))
		l.position = Vector2(14 if r.kind != "header" else 6, 0)
		panel.add_child(l)
		labels.append(l)
		var v := Art.label("", Pal.TEXT_DIM if r.kind == "info" else Pal.LEMON)
		panel.add_child(v)
		values.append(v)
		var bar: ColorRect = null
		if r.kind == "slider":
			var back := ColorRect.new()
			back.color = Pal.INK
			back.size = Vector2(102, 5)
			panel.add_child(back)
			bar = ColorRect.new()
			bar.color = Pal.CANDLE
			bar.size = Vector2(0, 3)
			bar.position = Vector2(1, 1)
			back.add_child(bar)
			bars.append(back)
		else:
			bars.append(null)
	cursor = TextureRect.new()
	cursor.texture = Art.ui("cursor")
	panel.add_child(cursor)
	note = Art.label("Left/Right change   X back", Pal.TEXT_DIM)
	note.position = Vector2(6, 166)
	add_child(note)
	sel = 1
	_refresh()
	add_to_group("tap_targets")


func _row_y(i: int) -> float:
	## Rows scroll so the selection stays inside the panel.
	var first := clampi(sel - 6, 0, maxi(0, rows.size() - 12))
	return 4 + (i - first) * 10


func _refresh() -> void:
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y := _row_y(i)
		var l: Label = labels[i]
		l.position.y = y
		l.visible = y >= 0 and y < 128
		var v: Label = values[i]
		v.position = Vector2(180, y)
		v.visible = l.visible
		match r.kind:
			"slider":
				var val: float = Game.settings[r.key]
				v.text = "%d%%" % int(round(val * 100))
				v.position.x = 286
				var back: ColorRect = bars[i]
				back.position = Vector2(180, y + 3)
				back.visible = l.visible
				(back.get_child(0) as ColorRect).size.x = 100.0 * val
			"toggle":
				v.text = "On" if Game.settings[r.key] else "Off"
			"choice":
				v.text = "< %s >" % r.opts[int(Game.settings[r.key])]
			"info":
				v.text = r.value
				v.position.x = 140
			_:
				v.text = ""
	cursor.position = Vector2(4 - (1 if fmod(t, 0.5) < 0.25 else 0), _row_y(sel))


func tap(p: Vector2) -> bool:
	## Tap a row to select it; tap again to toggle or act. Tap along a volume
	## bar to set it directly; tap a choice's value to step through it.
	if confirm_open:
		return false
	var local := p - panel.position
	if not Rect2(Vector2.ZERO, panel.size).has_point(local):
		return false
	for i in rows.size():
		if not _selectable(i) or not Rect2(0, _row_y(i) - 1, panel.size.x, 10).has_point(local):
			continue
		var r: Dictionary = rows[i]
		var changed := false
		if r.kind == "slider" and local.x >= 176:
			Game.settings[r.key] = clampf(snappedf((local.x - 181.0) / 100.0, 0.1), 0.0, 1.0)
			Game.apply_settings()
			changed = true
		elif r.kind == "choice" and local.x >= 176:
			Game.settings[r.key] = (int(Game.settings[r.key]) + 1) % r.opts.size()
			changed = true
		elif i == sel:
			TouchControls.confirm()
		sel = i
		Sfx.play("blip")
		if changed:
			Game.save_settings()
		_refresh()
		return true
	return true


func _process(delta: float) -> void:
	t += delta
	cursor.position.x = 4 - (1 if fmod(t, 0.5) < 0.25 else 0)


func _selectable(i: int) -> bool:
	return rows[i].kind in ["slider", "toggle", "choice", "action"]


func run() -> void:
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if confirm_open:
			continue
		if Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			Game.save_settings()
			return
		var old := sel
		if Input.is_action_just_pressed("down"):
			var i := sel
			while true:
				i = (i + 1) % rows.size()
				if _selectable(i):
					break
			sel = i
		elif Input.is_action_just_pressed("up"):
			var i := sel
			while true:
				i = (i - 1 + rows.size()) % rows.size()
				if _selectable(i):
					break
			sel = i
		var r: Dictionary = rows[sel]
		var dx := int(Input.is_action_just_pressed("right")) - int(Input.is_action_just_pressed("left"))
		if dx != 0:
			match r.kind:
				"slider":
					Game.settings[r.key] = clampf(snappedf(float(Game.settings[r.key]) + dx * 0.1, 0.1), 0.0, 1.0)
					Game.apply_settings()
					# preview on the bus that changed
					if r.key == "voice":
						Sfx.voice("rook", 1)
					else:
						Sfx.play("blip")
				"toggle":
					Game.settings[r.key] = not Game.settings[r.key]
					Sfx.play("blip")
				"choice":
					Game.settings[r.key] = clampi(int(Game.settings[r.key]) + dx, 0, r.opts.size() - 1)
					Sfx.play("blip")
			_refresh()
		elif Input.is_action_just_pressed("accept"):
			match r.kind:
				"toggle":
					Game.settings[r.key] = not Game.settings[r.key]
					Sfx.play("confirm")
				"action":
					await _do_action(r.key)
			_refresh()
		if old != sel:
			Sfx.play("blip")
			_refresh()


func _do_action(key: String) -> void:
	confirm_open = true
	var d: DialogBox = Game.main.dialog
	var q := ""
	match key:
		"reset_settings":
			q = "Reset volume, motion, shake, text and battle speed to their defaults? Your progress is not touched."
		"clear_progress":
			q = "Clear progress? This deletes every saved journey, every ending, legacy record, record and achievement. Settings stay."
		"clear_all":
			q = "Clear ALL stored data? Progress, achievements, records AND settings will be deleted."
	var c: int = await d.ask(q, ["No, keep it", "Yes, delete"], "", {"box": "red_box" if key != "reset_settings" else "box"})
	if c == 1:
		match key:
			"reset_settings":
				Game.settings = Game.DEFAULT_SETTINGS.duplicate()
				Game.save_settings()
				Game.apply_settings()
			"clear_progress":
				Game.clear_progress()
			"clear_all":
				Game.clear_all()
		Sfx.play("confirm")
		await d.say(["Done."], "", {})
	else:
		Sfx.play("cancel")
	confirm_open = false
