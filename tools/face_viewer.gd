extends Control
## Face viewer: look at any character in any mood, at the sizes the game
## shows them (the dialog portrait, a 3x close-up actor, 1x field sprites),
## and hear them say a line in that mood in the real dialog box.
##   ./faces                    start on Rook
##   ./faces mara worried       start on a character and mood
##   ./faces rook sad "Any line you like."
## Lines come from the story itself (what that character actually says in that
## mood), so you see the expressions as they are used. Press C to copy the
## current selection ("rook / worried / walk / front") to paste into a request.

const MOODS := ["", "smile", "smirk", "grin", "laugh", "sly", "sad", "cry", "worried", "shock", "scared",
	"angry", "determined", "hurt", "closed", "sleep", "omen", "hollow"]
const POSES := ["walk", "idle", "ready", "point", "cross", "hips", "shrug", "think", "wave", "laugh", "facepalm",
	"cower", "bow", "fist", "reach", "hold_up", "kneel", "sit", "slump", "hurt", "guard", "victory"]
const FACING := [[0, "front"], [2, "right"], [3, "left"], [1, "back"]]
const SAMPLES := ["Well. That's not how I pictured my morning going.",
	"Listen. I'm only going to say this once, so you'd better be paying attention, because the second time costs extra and the third time costs a finger.",
	"Oh. Oh no. Oh, that's bad."]
const STORY_FILES := ["res://scripts/story/story_act1.gd", "res://scripts/story/story_act2.gd", "res://scripts/story/story_act3.gd"]

var ids: Array = []
var ci := 0
var mi := 0
var pi := 0
var fi := 0
var li := 0
var custom := ""
## who -> mood -> [lines]
var lines: Dictionary = {}
var big: Actor
var small: Array = []
var stage: Node2D
var info: Array = []
var typer: NinePatchRect
var typed: Label
var edit_text := ""
var busy := false
var _typed_frame := -1
var _keys := {}


func _ready() -> void:
	size = Vector2(320, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in Data.CAST:
		ids.append(id)
	_harvest()
	var bg := ColorRect.new()
	bg.color = Pal.SAND.lerp(Pal.DUST, 0.3)
	bg.size = Vector2(320, 180)
	add_child(bg)
	var top := ColorRect.new()
	top.color = Pal.INK
	top.size = Vector2(320, 39)
	add_child(top)
	for i in 4:
		var l := Art.shadow_label("", Pal.LEMON if i == 0 else (Pal.TEXT if i < 3 else Pal.TEXT_DIM))
		l.position = Vector2(4, 1 + i * 9)
		add_child(l)
		info.append(l)
	var help := ["Up/Dn char   Lt/Rt mood", "Z talk   N line   T type", "P pose   F turn   C copy", "X quit"]
	for i in help.size():
		var l := Art.label(help[i], Pal.CANDLE.lerp(Pal.WHITE, 0.3) if i < 3 else Pal.TEXT_DIM)
		l.position = Vector2(316 - Art.text_width(help[0]), 1 + i * 9)
		add_child(l)
	stage = Node2D.new()
	add_child(stage)
	_build_typer()
	# start where the command line says
	var who := _arg("--who=")
	if who != "" and ids.has(who):
		ci = ids.find(who)
	var md := _arg("--mood=")
	if md in ["neutral", "none"]:
		md = ""
	if MOODS.has(md):
		mi = MOODS.find(md)
	custom = _arg("--text=")
	_rebuild()
	if OS.get_environment("CT_FACES_TOUR") != "":
		_tour(OS.get_environment("CT_FACES_TOUR"))


func _tour(out: String) -> void:
	## Automated check: steps through a few selections, talks, saves screenshots.
	var shot := func(n: String) -> void:
		await get_tree().create_timer(0.3).timeout
		get_viewport().get_texture().get_image().save_png("%s/faces_%s.png" % [out, n])
		print("[faces] shot ", n, ": ", describe())
	await shot.call("start")
	_step_mood(1)
	_refresh()
	await shot.call("mood")
	ci = ids.find("mara")
	_rebuild()
	pi = POSES.find("point")
	fi = 1
	_refresh()
	await shot.call("mara")
	_talk()
	await get_tree().create_timer(0.6).timeout
	await shot.call("talking")
	_step_mood(1)
	await shot.call("midline_mood")
	while busy:
		await get_tree().process_frame
	await shot.call("after")
	custom = "A line I typed myself, to see how it wraps across the box when it runs long enough to need a second line."
	_refresh()
	await shot.call("custom")
	# the same through real key presses: Down (next character), Right (mood), P, F, N
	var press := func(k: int, uni: int = 0) -> void:
		for down in [true, false]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			ev.keycode = k
			ev.unicode = uni if down else 0
			ev.pressed = down
			Input.parse_input_event(ev)
			await get_tree().process_frame
			await get_tree().process_frame
	for k in [KEY_DOWN, KEY_RIGHT, KEY_P, KEY_F, KEY_N]:
		await press.call(k)
	await shot.call("keys")
	await press.call(KEY_T)
	for ch in "Zany fox, x marks it.":
		await press.call(OS.find_keycode_from_string(ch.to_upper()) if ch != " " else KEY_SPACE, ch.unicode_at(0))
	await shot.call("typing")
	await press.call(KEY_ENTER)
	await get_tree().create_timer(0.4).timeout
	await shot.call("typed_talk")
	get_tree().quit()


func _arg(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""


func _harvest() -> void:
	## Every s.say("who", "text", "mood") in the story, grouped by speaker and mood.
	var re := RegEx.new()
	re.compile('s\\.say\\("([a-z_]+)",\\s*"((?:[^"\\\\]|\\\\.)*)"(?:,\\s*"([a-z_]*)")?')
	for path in STORY_FILES:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		for m in re.search_all(f.get_as_text()):
			var who := m.get_string(1)
			var md := m.get_string(3)
			var txt := m.get_string(2).replace("\\\"", "\"").replace("\\n", "\n")
			if not lines.has(who):
				lines[who] = {}
			if not lines[who].has(md):
				lines[who][md] = []
			lines[who][md].append(txt)


func _who() -> String:
	return ids[ci]


func _mood() -> String:
	return MOODS[mi]


func _spec() -> Dictionary:
	return Data.spec(_who())


func _pool() -> Array:
	## [lines, where they came from]
	var by: Dictionary = lines.get(_who(), {})
	if custom != "":
		return [[custom], "your line"]
	if by.get(_mood(), []).size() > 0:
		return [by[_mood()], "said in this mood in the story"]
	var any := []
	for k in by:
		any.append_array(by[k])
	if any.size() > 0:
		return [any, "said in other moods (none in this one)"]
	return [SAMPLES, "sample line (never speaks in the story)"]


func _line() -> String:
	var p: Array = _pool()[0]
	return p[li % p.size()]


func _opts() -> Dictionary:
	var sp := _spec()
	return {"portrait": sp, "mood": _mood(), "side": "right" if _who().begins_with("rook") else "left",
		"voice": sp.get("voice", "narrator"), "auto": true, "keep": true}


func _name() -> String:
	return str(_spec().get("name", _who().capitalize()))


func _rebuild() -> void:
	## New character: new actors on the stage.
	for c in stage.get_children():
		c.queue_free()
	small.clear()
	var sp := _spec()
	big = Actor.new(sp)
	big.position = Vector2(160, 122)
	big.scale = Vector2(3, 3)
	stage.add_child(big)
	var right := _who().begins_with("rook")
	var sx := 44.0 if right else 252.0
	for d in [0, 2]:
		var a := Actor.new(sp)
		a.position = Vector2(sx + (0 if d == 0 else 26), 104)
		a.face(d)
		stage.add_child(a)
		small.append(a)
	var lbl := Art.label("in the field", Pal.INK2)
	lbl.position = Vector2(sx - 20, 106)
	stage.add_child(lbl)
	li = 0
	_refresh()


func _refresh() -> void:
	var md := _mood()
	var fm := ArtPortraits.field_mood(md)
	for a in [big] + small:
		a.mood = fm
		a.set_pose(POSES[pi])
	big.face(FACING[fi][0])
	if not busy:
		Game.main.dialog.show_line(Game.main.dialog.paginate(_line())[0], _name(), _opts())
	var pool := _pool()
	var used: int = lines.get(_who(), {}).get(md, []).size()
	info[0].text = "%s  (%s)  %d/%d" % [_name().to_upper(), _who(), ci + 1, ids.size()]
	info[1].text = "mood: %s  %d/%d  used %dx" % [md if md != "" else "neutral", mi + 1, MOODS.size(), used]
	info[2].text = "pose: %s   facing: %s" % [POSES[pi], FACING[fi][1]]
	info[3].text = "line %d/%d: %s" % [li % (pool[0] as Array).size() + 1, (pool[0] as Array).size(), pool[1]]


func _process(_delta: float) -> void:
	# the small field actors talk along with the big one
	for a in small:
		if a.talking != big.talking:
			a.talking = big.talking
			if not big.talking:
				a.talk_t = 0.0
	if typer.visible:
		# long lines scroll: show the end being typed
		var shown := edit_text
		while shown != "" and Art.text_width(shown) > 270:
			shown = shown.substr(1)
		typed.text = shown + ("_" if fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.4 else "")
		return
	if Engine.get_process_frames() == _typed_frame:
		return
	_poll()


func describe() -> String:
	return "%s / %s / %s / %s" % [_who(), _mood() if _mood() != "" else "neutral", POSES[pi], FACING[fi][1]]


func _key(k: int) -> bool:
	## Letter keys aren't game actions; catch the moment they go down.
	var down := Input.is_physical_key_pressed(k)
	var was: bool = _keys.get(k, false)
	_keys[k] = down
	return down and not was


func _poll() -> void:
	## The game draws inside a SubViewport, so like the rest of the game this
	## reads Input instead of waiting for input events.
	var keys := {}
	for k in [KEY_N, KEY_P, KEY_F, KEY_T, KEY_C]:
		keys[k] = _key(k)
	if busy:
		# mood can change mid-line, to compare; X cuts the line short
		if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right"):
			_step_mood(-1 if Input.is_action_just_pressed("left") else 1)
			var d: DialogBox = Game.main.dialog
			d._face_mood = _mood()
			d._face_state = ""
			_announce()
		elif Input.is_action_just_pressed("cancel"):
			Game.main.dialog.skip_all = true
		return
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("down"):
		ci = posmod(ci + (-1 if Input.is_action_just_pressed("up") else 1), ids.size())
		Sfx.play("cursor")
		_rebuild()
		_announce()
	elif Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right"):
		_step_mood(-1 if Input.is_action_just_pressed("left") else 1)
		li = 0
		_refresh()
		_announce()
	elif Input.is_action_just_pressed("accept"):
		_talk()
	elif Input.is_action_just_pressed("cancel"):
		get_tree().quit()
	elif keys[KEY_N]:
		custom = ""
		li += 1
		Sfx.play("cursor")
		_refresh()
	elif keys[KEY_P]:
		pi = posmod(pi + (-1 if Input.is_key_pressed(KEY_SHIFT) else 1), POSES.size())
		_refresh()
		_announce()
	elif keys[KEY_F]:
		fi = (fi + 1) % FACING.size()
		_refresh()
		_announce()
	elif keys[KEY_T]:
		edit_text = custom
		typer.visible = true
		_typed_frame = Engine.get_process_frames()
	elif keys[KEY_C]:
		DisplayServer.clipboard_set(describe())
		Sfx.play("confirm")
		print("[faces] copied: ", describe())


func _step_mood(by: int) -> void:
	mi = posmod(mi + by, MOODS.size())
	Sfx.play("cursor")
	var fm := ArtPortraits.field_mood(_mood())
	for a in [big] + small:
		a.set_mood(fm)
	if busy:
		_refresh()


func _announce() -> void:
	print("[faces] ", describe())


func _talk() -> void:
	busy = true
	var d: DialogBox = Game.main.dialog
	d.skip_all = false
	d.speaker_actor = big
	big.lunge(2.0)
	await d.say([_line()], _name(), _opts())
	d.speaker_actor = null
	d.skip_all = false
	busy = false
	_refresh()


func _build_typer() -> void:
	typer = Art.make_box("glow_box")
	typer.size = Vector2(296, 34)
	typer.position = Vector2(12, 3)
	var l := Art.label("Type a line. Enter plays it, Esc cancels.", Pal.TEXT)
	l.position = Vector2(8, 4)
	typer.add_child(l)
	var field := ColorRect.new()
	field.color = Pal.INK
	field.position = Vector2(6, 16)
	field.size = Vector2(284, 12)
	typer.add_child(field)
	typed = Art.label("", Pal.CREAM)
	typed.position = Vector2(9, 17)
	typed.size = Vector2(278, 10)
	typed.clip_text = true
	typer.add_child(typed)
	typer.visible = false
	add_child(typer)
	# key events reach the window, not the game's SubViewport: a catcher on
	# the window root collects the typed characters
	var catcher := TypeCatcher.new()
	catcher.viewer = self
	get_tree().root.add_child.call_deferred(catcher)


func type_key(e: InputEventKey) -> void:
	_typed_frame = Engine.get_process_frames()
	match e.physical_keycode:
		KEY_ENTER, KEY_KP_ENTER:
			typer.visible = false
			custom = edit_text.strip_edges()
			li = 0
			_refresh()
			if custom != "":
				_talk()
		KEY_ESCAPE:
			typer.visible = false
		KEY_BACKSPACE:
			edit_text = edit_text.left(-1)
		_:
			if e.unicode >= 32:
				edit_text += char(e.unicode)


class TypeCatcher extends Node:
	var viewer: Node

	func _input(e: InputEvent) -> void:
		if not is_instance_valid(viewer):
			queue_free()
			return
		if viewer.typer.visible and e is InputEventKey and e.pressed:
			viewer.type_key(e)
			get_viewport().set_input_as_handled()
