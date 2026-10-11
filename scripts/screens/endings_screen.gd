class_name EndingsScreen
extends Control
## The ending gallery and the anthology's memory, on three pages:
## ENDINGS (each found or a hint), LAST ROUTE (the decisive choices of the
## most recent journey, and which endings it could have reached), and
## LEGACY (what happened to the blade, every time).

const PAGES := ["ENDINGS", "LAST ROUTE", "LEGACY"]

var page := 0
var body: Control
var tabs: Array = []
var scroll := 0
var lines: Array = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.cine("parchment", 0)
	bg.modulate = Color(0.45, 0.4, 0.42)
	add_child(bg)
	var head := Art.make_box("bar_box")
	head.position = Vector2(6, 4)
	head.size = Vector2(64, 16)
	add_child(head)
	var hl := Art.label("ENDINGS", Pal.LEMON)
	hl.position = Vector2(7, 3)
	head.add_child(hl)
	var x := 80.0
	for p in PAGES:
		var l := Art.label(p, Pal.TEXT_DIM)
		l.position = Vector2(x, 7)
		add_child(l)
		tabs.append(l)
		x += Art.text_width(p) + 12
	var panel := Art.make_box("box")
	panel.position = Vector2(6, 24)
	panel.size = Vector2(308, 138)
	panel.clip_contents = true
	add_child(panel)
	body = Control.new()
	body.position = Vector2(10, 4)
	panel.add_child(body)
	var keys := Art.shadow_label("Left/Right page   Up/Down scroll   X back", Pal.TEXT_DIM)
	keys.position = Vector2(6, 166)
	add_child(keys)
	_fill()


func _line(text: String, col: Color = Pal.TEXT, indent: float = 0.0) -> void:
	for ln in Art.wrap(text, 286 - indent):
		lines.append([ln, col, indent])


func _fill() -> void:
	for c in body.get_children():
		c.queue_free()
	lines.clear()
	for i in tabs.size():
		(tabs[i] as Label).add_theme_color_override("font_color", Pal.LEMON if i == page else Pal.TEXT_DIM)
	match page:
		0:
			for e in Data.ENDINGS:
				var have := Game.has_ending(e[0])
				_line(("* " if have else "  ") + (e[1] if have else "? ? ?"), Pal.LEMON if have else Pal.TEXT_DIM)
				_line(e[2], Pal.CREAM if have else Pal.TEXT_DIM, 10)
				if have:
					_line("The blade: " + e[3], Pal.OMEN.lerp(Pal.WHITE, 0.35), 10)
		1:
			var r: Dictionary = Game.profile.last_route
			if r.is_empty():
				_line("Finish a journey to see the route you took, the choices that decided it, and what else was within reach.", Pal.CANDLE)
			else:
				_line("Ended: " + Data.ending(r.ending)[1], Pal.LEMON)
				var vv: Dictionary = r.get("vars", {})
				_line("Finesse %d   Suspicion %d   Loyalty %d" % [int(vv.get("finesse", 0)), int(vv.get("suspicion", 0)), int(vv.get("loyalty", 0))], Pal.CREAM)
				_line("Mara %s   Fen %s" % [_bond(int(vv.get("mara", 0))), _bond(int(vv.get("fen", 0)))], Pal.CREAM)
				var elig: Array = r.get("eligible", [])
				if elig.size() > 1:
					_line("Also within reach: " + ", ".join(elig.filter(func(x): return x != r.ending).map(func(x): return Data.ending(x)[1])), Pal.GLOW)
				_line("Decisive choices:", Pal.TEXT_DIM)
				for c in r.get("choices", []):
					_line("%s  %s" % [c.get("scene", ""), c.get("text", "")], Pal.TEXT, 6)
		2:
			var leg: Array = Game.profile.legacy
			if leg.is_empty():
				_line("The blade has no history with you yet.", Pal.CANDLE)
			for i in range(leg.size() - 1, -1, -1):
				var l: Dictionary = leg[i]
				_line("%d. %s" % [i + 1, l.get("name", "")], Pal.LEMON)
				_line("Rook: " + str(l.get("bearer", "")), Pal.CREAM, 10)
				_line("Closest bond: " + str(l.get("bond", "")), Pal.CREAM, 10)
				_line("The blade: %s. Marked: %s." % [l.get("sword", ""), l.get("mark", "unmarked")], Pal.OMEN.lerp(Pal.WHITE, 0.35), 10)
	scroll = 0
	_draw_lines()


func _bond(n: int) -> String:
	if n >= 5:
		return "devoted"
	if n >= 3:
		return "trusting"
	if n >= 1:
		return "warm"
	if n >= -1:
		return "wary"
	return "broken"


func _draw_lines() -> void:
	for c in body.get_children():
		c.queue_free()
	for i in range(scroll, mini(lines.size(), scroll + 13)):
		var ln: Array = lines[i]
		var l := Art.label(ln[0], ln[1])
		l.position = Vector2(ln[2], (i - scroll) * 10)
		body.add_child(l)


func run() -> void:
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			return
		var old := page
		if Input.is_action_just_pressed("right"):
			page = (page + 1) % PAGES.size()
		elif Input.is_action_just_pressed("left"):
			page = (page + PAGES.size() - 1) % PAGES.size()
		elif Input.is_action_just_pressed("down") and scroll < lines.size() - 13:
			scroll += 1
			Sfx.play("tick")
			_draw_lines()
		elif Input.is_action_just_pressed("up") and scroll > 0:
			scroll -= 1
			Sfx.play("tick")
			_draw_lines()
		if old != page:
			Sfx.play("blip")
			_fill()
