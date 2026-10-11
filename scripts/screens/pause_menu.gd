class_name PauseMenu
extends Control
## The field pause menu (X / Esc): resume, status (the story's variables in
## character language, the blade, what Rook carries, what he's learned), the
## dialog log, achievements, settings, or save and quit to the title.

var menu: Menu
var info: NinePatchRect
var info_body: Control


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
	_status()


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
	var s := Data.scene(str(Game.run.get("scene", "P1")))
	_l(s.act, Vector2(0, 0), Pal.TEXT_DIM)
	_l(s.title, Vector2(0, 10), Pal.LEMON)
	var y := 24.0
	for row in [["Finesse", "finesse", Pal.CANDLE], ["Suspicion", "suspicion", Pal.OMEN], ["Loyalty", "loyalty", Pal.GLOW]]:
		_l(row[0], Vector2(0, y))
		_meter(Vector2(64, y + 3), Game.v(row[1]) / 10.0, row[2])
		y += 10
	_l("Mara", Vector2(132, 24))
	_l(bond_word(Game.v("mara")) if Game.flag("met_mara") else "?", Vector2(166, 24), Pal.GLOW.lerp(Pal.WHITE, 0.4))
	_l("Fen", Vector2(132, 34))
	_l(bond_word(Game.v("fen")), Vector2(166, 34), Pal.GLOW.lerp(Pal.WHITE, 0.4))
	_l("Coin", Vector2(132, 44))
	_l(str(Game.v("coin")), Vector2(166, 44), Pal.BRASS)
	y = 58.0
	_l("The blade: " + (Game.tier_name() if Game.flag("has_sword") else "not yours"), Vector2(0, y), Pal.OMEN.lerp(Pal.WHITE, 0.3))
	y += 12
	var items: Array = Game.run.get("items", [])
	_l("Carrying (%d weight):" % Game.weight(), Vector2(0, y), Pal.TEXT_DIM)
	y += 10
	if items.is_empty():
		_l("nothing that isn't yours", Vector2(6, y), Pal.TEXT_DIM)
		y += 10
	for id in items.slice(0, 6):
		_l(str(Data.item(id).name), Vector2(6, y))
		y += 10
	var sup := []
	for id in Data.SUPPLIES:
		if Game.supply(id) > 0:
			sup.append("%s x%d" % [Data.SUPPLIES[id].name, Game.supply(id)])
	if not sup.is_empty():
		var l := _l("Pack: " + ", ".join(sup), Vector2(0, y + 2), Pal.CREAM)
		l.size = Vector2(204, 30)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		y += 22
	_l("Lore %d   Vault clues %d/3" % [Game.run.get("lore", []).size(), Game.run.get("clues", []).size()], Vector2(0, maxf(y + 4, 150)), Pal.TEXT_DIM)


func _log() -> void:
	_clear()
	var bl: Array = Game.main.dialog.backlog
	var lines := []
	for e in bl:
		for w in Art.wrap(("%s: " % e[0] if e[0] != "" else "") + str(e[1]), 204):
			lines.append([w, Pal.TEXT if e[0] != "" else Pal.CREAM])
	var start := maxi(0, lines.size() - 16)
	for i in range(start, lines.size()):
		_l(lines[i][0], Vector2(0, (i - start) * 10), lines[i][1])


func run() -> String:
	var opts := ["Resume", "Status", "Log", "Achievements", "Settings", "Save & quit"]
	menu = Menu.make(self, opts, Vector2(6, 6), Vector2(86, opts.size() * 10 + 7))
	menu.scale = Vector2(1, 0.2)
	create_tween().tween_property(menu, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	menu.moved.connect(func(i: int) -> void:
		if i == 2:
			_log()
		elif i == 1:
			_status())
	while true:
		var r := await menu.ask()
		match r:
			-1, 0:
				return "resume"
			1:
				_status()
			2:
				_log()
			3:
				var a := AchievementsScreen.new()
				add_child(a)
				await a.run()
				a.queue_free()
			4:
				var s := SettingsScreen.new()
				add_child(s)
				await s.run()
				s.queue_free()
			5:
				var c: int = await Game.main.dialog.ask("Quit to the title? Your journey is saved at the start of this scene.", ["Keep playing", "Save & quit"])
				if c == 1:
					return "title"
	return "resume"
