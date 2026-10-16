class_name PauseMenu
extends Control
## The field pause menu (X / Esc). The crew's status is always the open pane:
## a face (it blinks; Rook's eyes go violet as Suspicion climbs), fighting
## numbers, weapon, and for Rook the story's variables, purse and load; for
## the others, their trust and techniques, each with its icon. Left/Right
## turn to the next crew member. The menu: resume, items and skills (their
## own windows, by category), the dialog log, achievements, settings, or save
## and quit to the title.

var menu: Menu
var info: NinePatchRect
var info_body: Control
var pic: TextureRect
var pic_spec := {}
var pic_mood := ""
var blink_t := 2.0
## Whose status is showing (an index into crew), and whether a window is
## open over the menu (taps and Left/Right then belong to it).
var crew: Array = ["rook"]
var who := 0
var busy := false
var showing_log := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	info = Art.make_box("box")
	info.position = Vector2(96, 6)
	info.size = Vector2(218, 168)
	add_child(info)
	info_body = Control.new()
	info_body.position = Vector2(6, 4)
	info.add_child(info_body)
	if Game.main and Game.main.story:
		crew = Game.main.story.party()
	_status()
	set_meta("tap_priority", 1)
	add_to_group("tap_targets")


func _clear() -> void:
	for c in info_body.get_children():
		c.queue_free()


func _l(text: String, pos: Vector2, col: Color = Pal.TEXT) -> Label:
	var l := Art.label(text, col)
	l.position = pos
	info_body.add_child(l)
	return l


func _meter(pos: Vector2, k: float, col: Color) -> void:
	var back := ColorRect.new()
	back.color = Pal.INK
	back.position = pos
	back.size = Vector2(60, 5)
	info_body.add_child(back)
	var f := ColorRect.new()
	f.color = col
	f.position = Vector2(1, 1)
	f.size = Vector2(58 * clampf(k, 0.0, 1.0), 3)
	back.add_child(f)


static func bond_word(n: int) -> String:
	if n >= 5:
		return "devoted"
	if n >= 3:
		return "trusting"
	if n >= 1:
		return "warm"
	if n >= -1:
		return "wary"
	return "hostile"


func _status() -> void:
	_clear()
	showing_log = false
	var id: String = crew[who]
	var me := BattleDefs.member(id)
	# the face, in a frame
	var frame := ColorRect.new()
	frame.color = Pal.INK
	frame.size = Vector2(52, 48)
	info_body.add_child(frame)
	pic_spec = Game.main.story.rook_spec() if id == "rook" else Data.spec(id)
	if id == "rook":
		pic_mood = "omen" if Game.hostile_allies() else ("worried" if Game.v("suspicion") >= 4 else "")
	else:
		var t := Game.v(id)
		pic_mood = "angry" if t <= -2 else ("smile" if t >= 3 else "")
	pic = TextureRect.new()
	pic.texture = _face(false)
	pic.position = ((frame.size - pic.texture.get_size()) / 2.0).floor()
	frame.add_child(pic)
	_l(str(me.name), Vector2(58, 1), Pal.CANDLE)
	if crew.size() > 1:
		# whose page this is, and the way to the others
		var pg := "%d/%d" % [who + 1, crew.size()]
		_icon("cursor_r", Vector2(172, 1))
		_l(pg, Vector2(188 - Art.text_width(pg) / 2.0, 1), Pal.TEXT_DIM)
		_icon("cursor", Vector2(198, 1))
	var s := Data.scene(str(Game.run.get("scene", "P1")))
	if id == "rook":
		_l(s.act, Vector2(58, 12), Pal.TEXT_DIM)
		_l(s.title, Vector2(58, 22), Pal.LEMON)
		_stat(["stat_blade", "Blade", Game.tier_name() if Game.flag("has_sword") else "not his"], Vector2(58, 35),
			Pal.OMEN.lerp(Pal.WHITE, 0.3), 146)
	else:
		var t := Game.v(id)
		_icon("stat_trust", Vector2(58, 13))
		_l("Trust", Vector2(71, 12), Pal.TEXT_DIM)
		_meter(Vector2(104, 15), (t + 5) / 11.0, Pal.GLOW.lerp(Pal.SAGE, 0.3) if t >= 0 else Pal.ROSE)
		_l(bond_word(t), Vector2(170, 12), Pal.GLOW.lerp(Pal.WHITE, 0.4) if t >= 0 else Pal.ROSE.lerp(Pal.WHITE, 0.35))
		_l(s.title, Vector2(58, 24), Pal.TEXT_DIM)
	# how they fight (what BattleDefs.member gives the battle right now),
	# two to a row, each with its icon
	var y := 54.0
	var w := BattleDefs.weapon_of(id)
	var cells := [["stat_hp", "HP", str(me.hp)], ["stat_tp", "TP", str(me.tp)],
		["stat_atk", "Attack", str(me.atk)], ["stat_def", "Defence", str(me["def"])],
		["stat_spd", "Speed", str(me.spd)]]
	for i in cells.size():
		_stat(cells[i], Vector2((i % 2) * 106, y + (i / 2) * 12))
	_icon("weapon_" + w, Vector2(106, y + 22))
	_l(BattleDefs.WEAPONS[w].name, Vector2(121, y + 24), Pal.CREAM)
	y += 40
	_rule(y)
	y += 5
	if id == "rook":
		# the story's variables, the purse and the load
		var vars := [["stat_finesse", "Finesse", "finesse", Pal.CANDLE], ["stat_suspicion", "Suspicion", "suspicion", Pal.OMEN],
			["stat_loyalty", "Loyalty", "loyalty", Pal.GLOW]]
		for i in vars.size():
			var r: Array = vars[i]
			_icon(r[0], Vector2(0, y + i * 12))
			_l(r[1], Vector2(13, y + i * 12), Pal.TEXT_DIM)
			_meter(Vector2(62, y + i * 12 + 3), Game.v(r[2]) / 10.0, r[3])
		_stat(["stat_coin", "Coin", str(Game.v("coin"))], Vector2(130, y), Pal.BRASS.lerp(Pal.LEMON, 0.3), 76)
		_stat(["stat_weight", "Load", str(Game.weight())], Vector2(130, y + 12), Pal.CREAM, 76)
		_stat(["stat_evidence", "Evidence", str(Game.evidence())], Vector2(130, y + 24),
			Pal.BLOOD.lerp(Pal.WHITE, 0.3) if Game.evidence() >= 4 else Pal.CREAM, 76)
		y += 40
		_l("Lore %d   Vault clues %d/3" % [Game.run.get("lore", []).size(), Game.run.get("clues", []).size()], Vector2(0, y), Pal.TEXT_DIM)
	else:
		# their techniques, two to a row
		var sks: Array = me.skills
		for i in sks.size():
			var p := Vector2((i % 2) * 106, y + (i / 2) * 15)
			_icon("skill_" + str(sks[i]), p)
			_l(BattleDefs.SKILLS[sks[i]].name, p + Vector2(16, 2), Pal.TEXT)


func _icon(id: String, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.ui(id)
	t.position = pos
	info_body.add_child(t)
	return t


func _stat(cell: Array, pos: Vector2, col: Color = Pal.LEMON, width: float = 100.0) -> void:
	## [icon, label, value] in a cell: icon, the word, the value at the right.
	_icon(cell[0], pos)
	_l(cell[1], pos + Vector2(13, 0), Pal.TEXT_DIM)
	_l(cell[2], pos + Vector2(width - 6 - Art.text_width(cell[2]), 0), col)


func _rule(y: float) -> void:
	var r := ColorRect.new()
	r.color = Color(Pal.TEXT_DIM, 0.35)
	r.position = Vector2(0, y)
	r.size = Vector2(204, 1)
	info_body.add_child(r)


func _face(shut: bool) -> Texture2D:
	return Art.portrait(pic_spec, pic_mood, shut, false, 2)


func _turn(d: int) -> void:
	## Left/Right (or the arrows): the next crew member's page.
	if crew.size() < 2 or showing_log:
		return
	who = (who + d + crew.size()) % crew.size()
	Sfx.play("blip")
	_status()


func _process(delta: float) -> void:
	if not busy and menu and menu.active:
		if Input.is_action_just_pressed("left"):
			_turn(-1)
		elif Input.is_action_just_pressed("right"):
			_turn(1)
	# the portrait blinks now and then, like the talking portraits do
	if not is_instance_valid(pic):
		return
	blink_t -= delta
	if blink_t <= 0.0:
		var shut := blink_t > -0.12
		pic.texture = _face(shut)
		if not shut:
			blink_t = randf_range(2.0, 5.0)


func tap(p: Vector2) -> bool:
	## Touch: the arrows by the name turn the page.
	if busy or showing_log or crew.size() < 2:
		return false
	var o := info.position + info_body.position
	if Rect2(o + Vector2(166, -2), Vector2(16, 14)).has_point(p):
		_turn(-1)
		return true
	if Rect2(o + Vector2(193, -2), Vector2(16, 14)).has_point(p):
		_turn(1)
		return true
	return false


func _log() -> void:
	_clear()
	showing_log = true
	var bl: Array = Game.main.dialog.backlog
	var lines := []
	for e in bl:
		for w in Art.wrap(("%s: " % e[0] if e[0] != "" else "") + str(e[1]), 204):
			lines.append([w, Pal.TEXT if e[0] != "" else Pal.CREAM])
	var start := maxi(0, lines.size() - 16)
	for i in range(start, lines.size()):
		_l(lines[i][0], Vector2(0, (i - start) * 10), lines[i][1])


func _window(w: Control) -> void:
	busy = true
	add_child(w)
	await w.run()
	w.queue_free()
	busy = false


func run() -> String:
	var opts := ["Resume", "Items", "Skills", "Log", "Achievements", "Settings", "Save & quit"]
	menu = Menu.make(self, opts, Vector2(6, 6), Vector2(86, opts.size() * 10 + 7))
	menu.scale = Vector2(1, 0.2)
	create_tween().tween_property(menu, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	menu.moved.connect(func(i: int) -> void:
		if i == 3:
			_log()
		elif showing_log:
			_status())
	while true:
		var r := await menu.ask()
		match r:
			-1, 0:
				return "resume"
			1:
				await _window(ItemsWindow.new())
				_status()
			2:
				await _window(SkillsWindow.new(crew[who]))
			3:
				_log()
			4:
				await _window(AchievementsScreen.new())
			5:
				await _window(SettingsScreen.new())
			6:
				var c: int = await Game.main.dialog.ask("Quit to the title? Your journey is saved in slot %d at the start of this scene." % (Game.slot + 1), ["Keep playing", "Save & quit"])
				if c == 1:
					return "title"
	return "resume"
