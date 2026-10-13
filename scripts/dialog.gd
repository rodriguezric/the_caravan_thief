class_name DialogBox
extends Control
## Typewriter dialog box with portraits.
## `await dialog.say(lines, speaker, opts)`; `await dialog.ask(question, options, speaker, opts)`.
## opts: portrait (spec | icon name: "blade", "crew", "hunters"), mood,
## side ("left"/"right"), voice, color, auto (advance by itself),
## box ("box", "omen_box" for the blade, "bar_box" for narration asides).
## Lines already read can be skipped by holding Run (Shift); every line goes
## into a backlog the pause menu can show.

const TEXT_W := 292
const LINES := 3

var box: NinePatchRect
var text: Label
var name_box: NinePatchRect
var name_label: Label
var arrow: TextureRect
var pframe: NinePatchRect
var pic: TextureRect
var _armed := 0
var _portrait_key := ""
var _portrait_side := ""
var _talking := false
var _anim_t := 0.0
var _anim_portrait := ""
var _box_tween: Tween
var _portrait_tween: Tween
## True while putting up the first line of a conversation (the box just opened).
var _fresh := false
var _open := false
## Bumped whenever a line goes up; a pending close checks it hasn't changed.
var _close_id := 0
## How long the box lingers after a line before closing. A line that follows
## within this time reuses the open box and portrait instead of replaying
## their entrance, so a conversation opens once rather than on every line.
const CLOSE_GRACE := 0.2
var skip_all := false
## The last lines shown, oldest first: [speaker, text].
var backlog: Array = []
## The field actor of whoever is speaking, so their mouth moves too.
var speaker_actor: Node = null
## The speaker on show, so the face can blink and talk.
var _face_spec = null
var _face_mood := ""
var _blink_in := 2.5
var _blink_left := 0.0
var _face_state := ""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pframe = Art.make_box("box")
	pframe.size = Vector2(78, 78)
	pframe.z_index = 1
	pframe.position = Vector2(8, 40)
	add_child(pframe)
	pic = TextureRect.new()
	pic.position = Vector2(3, 3)
	pframe.add_child(pic)
	pframe.visible = false
	box = Art.make_box()
	box.position = Vector2(6, 128)
	box.size = Vector2(308, 46)
	add_child(box)
	text = Label.new()
	text.position = Vector2(8, 5)
	text.size = Vector2(TEXT_W, 38)
	box.add_child(text)
	name_box = Art.make_box("bar_box")
	name_box.position = Vector2(10, 116)
	name_box.size = Vector2(60, 15)
	add_child(name_box)
	name_label = Label.new()
	name_label.position = Vector2(5, 3)
	name_box.add_child(name_label)
	arrow = TextureRect.new()
	arrow.texture = Art.ui("down")
	arrow.position = Vector2(294, 36)
	box.add_child(arrow)
	visible = false


func _process(delta: float) -> void:
	if arrow.visible:
		arrow.position.y = 35 + (1 if fmod(Time.get_ticks_msec() / 1000.0, 0.6) < 0.3 else 0)
	_anim_t += delta
	if pframe.visible:
		# the speaker blinks now and then, and their mouth moves while text types
		if _face_spec != null:
			_blink_in -= delta
			if _blink_in <= 0.0:
				_blink_left = 0.12
				_blink_in = randf_range(1.8, 4.0)
			_blink_left = maxf(0.0, _blink_left - delta)
			var blink := _blink_left > 0.0
			var open := _talking and fmod(_anim_t, 0.2) < 0.1
			var state := "%d%d" % [int(blink), int(open)]
			if state != _face_state:
				_face_state = state
				pic.texture = Art.portrait(_face_spec, _face_mood, blink, open)
		# icon speakers animate only while they talk
		if _anim_portrait != "":
			pic.texture = Art.icon_portrait(_anim_portrait, int(_anim_t * 8.0) % 16 if _talking else 0)


func _pressed(action: String) -> bool:
	return Engine.get_process_frames() != _armed and Input.is_action_just_pressed(action)


func _open_box(kind: String) -> void:
	box.texture = Art.ui(kind)
	_fresh = not _open
	if _open:
		return
	_open = true
	visible = true
	if _box_tween:
		_box_tween.kill()
	box.position.y = 186 if not Game.reduced_motion() else 128
	_box_tween = create_tween()
	_box_tween.tween_property(box, "position:y", 128.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	_close_id += 1
	_open = false
	visible = false
	pframe.visible = false
	_portrait_key = ""
	name_box.visible = false


func _close_soon() -> void:
	## Close unless another line arrives first.
	_close_id += 1
	var id := _close_id
	arrow.visible = false
	await get_tree().create_timer(CLOSE_GRACE).timeout
	if id == _close_id and _open:
		close()


func _set_portrait(opts: Dictionary) -> void:
	var p = opts.get("portrait", null)
	var mood_changed := false
	if p == null:
		pframe.visible = false
		_portrait_key = ""
		_anim_portrait = ""
		_face_spec = null
		return
	var side: String = opts.get("side", "left")
	var key := ""
	if p is String:
		_anim_portrait = p
		key = p
		pic.texture = Art.icon_portrait(p, 0)
		pic.position = Vector2(7, 7)
		_face_spec = null
		pframe.texture = Art.ui("omen_box" if p == "blade" else "bar_box")
	else:
		_anim_portrait = ""
		var mood: String = opts.get("mood", "")
		mood_changed = mood != _face_mood
		pic.texture = Art.portrait(p, mood)
		pic.position = Vector2(3, 3)
		_face_spec = p
		_face_mood = mood
		_face_state = "00"
		pframe.texture = Art.ui("box")
		key = "%s:%s" % [p.get("id", ""), p.get("variant", "")]
	var x := 8.0 if side == "left" else 234.0
	var changed := key != _portrait_key or side != _portrait_side or not pframe.visible
	# mid-conversation, speakers swap in gently; only the first face of a
	# conversation gets the full slide-in
	var swap := not _fresh
	_portrait_key = key
	_portrait_side = side
	pframe.visible = true
	if _portrait_tween:
		_portrait_tween.kill()
	pframe.scale = Vector2.ONE
	if not changed:
		pframe.position = Vector2(x, 40)
		pframe.modulate.a = 1.0
	if changed and Game.reduced_motion():
		pframe.position = Vector2(x, 40)
		pframe.modulate.a = 1.0
	elif changed and swap:
		# a new speaker mid-conversation: a quick, small cross-fade, no bounce
		pframe.position = Vector2(x + (-6 if side == "left" else 6), 40)
		pframe.modulate.a = 0.3
		_portrait_tween = create_tween().set_parallel(true)
		_portrait_tween.tween_property(pframe, "position:x", x, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_portrait_tween.tween_property(pframe, "modulate:a", 1.0, 0.1)
	elif changed:
		pframe.position = Vector2(x + (-30 if side == "left" else 30), 40)
		pframe.modulate.a = 0.0
		_portrait_tween = create_tween().set_parallel(true)
		_portrait_tween.tween_property(pframe, "position:x", x, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_portrait_tween.tween_property(pframe, "modulate:a", 1.0, 0.12)
	elif mood_changed:
		# same speaker, new expression: a little squash
		pframe.scale = Vector2(1.06, 0.94)
		pframe.pivot_offset = pframe.size / 2.0
		_portrait_tween = create_tween()
		_portrait_tween.tween_property(pframe, "scale", Vector2.ONE, 0.12)
	name_box.position.x = 10.0 if side == "left" else 310.0 - name_box.size.x


func paginate(line: String) -> Array:
	## Word-wraps into pages of LINES lines that fit TEXT_W.
	var pages := []
	for para in line.split("\n"):
		var words := para.split(" ", false)
		var lines := []
		var cur := ""
		for w in words:
			var trial := w if cur == "" else cur + " " + w
			if Art.text_width(trial) > TEXT_W and cur != "":
				lines.append(cur)
				cur = w
			else:
				cur = trial
		if cur != "":
			lines.append(cur)
		for i in range(0, lines.size(), LINES):
			pages.append("\n".join(lines.slice(i, i + LINES)))
	return pages


func _prepare(speaker: String, opts: Dictionary) -> void:
	_close_id += 1
	_open_box(opts.get("box", "box"))
	_set_portrait(opts)
	name_box.visible = speaker != ""
	name_label.text = speaker
	name_box.size.x = Art.text_width(speaker) + 12
	if pframe.visible:
		name_box.position.x = 10.0 if _portrait_side == "left" else 310.0 - name_box.size.x
		name_box.position.y = 116
	else:
		name_box.position = Vector2(10, 116)
	text.add_theme_color_override("font_color", opts.get("color", Pal.TEXT if speaker != "" else Pal.CREAM))


func show_line(line: String, speaker: String = "", opts: Dictionary = {}) -> void:
	## Puts a page up at once, untyped, and leaves the box open (the face viewer).
	_prepare(speaker, opts)
	text.text = line
	text.visible_characters = -1
	arrow.visible = false


func say(lines: Array, speaker: String = "", opts: Dictionary = {}) -> void:
	_prepare(speaker, opts)
	var pages := []
	for l in lines:
		pages.append_array(paginate(str(l)))
		backlog.append([speaker, str(l)])
	while backlog.size() > 80:
		backlog.pop_front()
	for i in pages.size():
		var key := str((speaker + "|" + str(pages[i])).hash())
		var skipping: bool = Input.is_action_pressed("run") and Game.is_read(key)
		var auto: bool = (opts.get("auto", false) and i == pages.size() - 1) or Game.autoplay() or skipping
		await _type(pages[i], opts.get("voice", "narrator"), auto, skipping)
		Game.mark_read(key)
		if auto:
			await get_tree().create_timer(0.12 if Game.autoplay() else opts.get("auto_delay", 0.05)).timeout
			continue
		arrow.visible = true
		_armed = Engine.get_process_frames()
		while not (_pressed("accept") or _pressed("cancel") or skip_all):
			await get_tree().process_frame
		Sfx.play("blip", 1.3, -10.0)
		arrow.visible = false
	if not opts.get("keep", false):
		_close_soon()


func _type(line: String, voice: String, auto: bool, instant: bool = false) -> void:
	text.text = line
	text.visible_characters = 0
	arrow.visible = false
	_armed = Engine.get_process_frames()
	if instant:
		text.visible_characters = -1
		return
	_talking = true
	_set_actor_talking(true)
	var t := 0.0
	var hold := 0.0
	var n := 0
	var count := 0
	while n < line.length():
		await get_tree().process_frame
		if skip_all:
			break
		if _pressed("accept") and not auto:
			break
		var dt := get_process_delta_time()
		if hold > 0.0:
			hold -= dt
			continue
		t += dt * Game.text_cps()
		while n < mini(int(t), line.length()):
			n += 1
			var ch := line[n - 1]
			if ch != " " and ch != "\n":
				count += 1
				if count % 2 == 1:
					Sfx.voice(voice, count)
			if ch in ".!?" and n < line.length() and line[n] in " \n":
				hold = 0.16
				t = n
				break
			if ch in ",;:" or ch == "—":
				hold = 0.07
				t = n
				break
		text.visible_characters = n
	text.visible_characters = -1
	_talking = false
	_set_actor_talking(false)


func _set_actor_talking(on: bool) -> void:
	if speaker_actor != null and is_instance_valid(speaker_actor):
		speaker_actor.talking = on
		if not on:
			speaker_actor.talk_t = 0.0


func ask(question: String, options: Array, speaker: String = "", opts: Dictionary = {}) -> int:
	# _prepare also cancels the previous line's pending close
	_prepare(speaker, opts)
	# wrap the question like any other line; earlier pages wait for a press,
	# the last page stays up under the choices
	var pages := paginate(question)
	for i in pages.size():
		await _type(pages[i], opts.get("voice", "narrator"), false)
		if i < pages.size() - 1:
			if Game.autoplay():
				await get_tree().create_timer(0.12).timeout
				continue
			arrow.visible = true
			_armed = Engine.get_process_frames()
			while not (_pressed("accept") or _pressed("cancel")):
				await get_tree().process_frame
			Sfx.play("blip", 1.3, -10.0)
			arrow.visible = false
	var w := 0
	for o in options:
		w = maxi(w, Art.text_width(o if o is String else o.text))
	w = mini(w, 280)
	var h := options.size() * 10 + 7
	var m := Menu.make(self, options, Vector2(maxf(6.0, 312 - w - 22), (112 if name_box.visible else 124) - h), Vector2(w + 20, h))
	m.cancellable = false
	m.scale = Vector2(1, 0.2)
	m.pivot_offset = Vector2(0, h)
	create_tween().tween_property(m, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	backlog.append([speaker, question])
	var r: int
	if Game.autoplay():
		await get_tree().create_timer(0.25).timeout
		r = clampi(Game.next_choice(), 0, options.size() - 1)
		print("[auto] choice: ", options[r] if options[r] is String else options[r].text)
	else:
		r = await m.ask()
	m.queue_free()
	if not opts.get("keep", false):
		_close_soon()
	return r
