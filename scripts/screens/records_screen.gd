class_name RecordsScreen
extends Control
## Records: totals across every journey, and the thievery bests.
## Read-only; a fresh profile gets an honest empty state.

const PAGES := ["SUMMARY", "THIEVERY"]

var page := 0
var body: Control
var tabs: Array = []
var scroll := 0.0
var content_h := 0.0
## Room inside the panel for the page body.
const VIEW_H := 130.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.cine("shop", 0)
	bg.modulate = Color(0.55, 0.5, 0.55)
	add_child(bg)
	var head := Art.make_box("bar_box")
	head.position = Vector2(6, 4)
	head.size = Vector2(64, 16)
	add_child(head)
	var hl := Art.label("RECORDS", Pal.LEMON)
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
	add_to_group("tap_targets")


func tap(p: Vector2) -> bool:
	for i in tabs.size():
		var l: Label = tabs[i]
		if Rect2(l.position - Vector2(3, 3), Vector2(Art.text_width(l.text) + 6, 14)).has_point(p):
			if i != page:
				page = i
				Sfx.play("blip")
				_fill()
			return true
	return false


func scroll_by(dy: float) -> void:
	## Touch drag: slide a page that's taller than the panel.
	scroll = clampf(scroll + dy, 0.0, maxf(0.0, content_h - VIEW_H))
	body.position.y = 4 - roundf(scroll)


func _row(y: float, label: String, value: String, col: Color = Pal.TEXT) -> void:
	var l := Art.label(label, Pal.TEXT_DIM)
	l.position = Vector2(0, y)
	body.add_child(l)
	var v := Art.label(value, col)
	v.position = Vector2(286 - Art.text_width(value), y)
	body.add_child(v)


func _fill() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	var r: Dictionary = Game.profile.records
	for i in tabs.size():
		(tabs[i] as Label).add_theme_color_override("font_color", Pal.LEMON if i == page else Pal.TEXT_DIM)
	match page:
		0:
			var secs := int(float(r.get("play_time", 0.0)))
			_row(0, "Time on the road", "%d:%02d:%02d" % [secs / 3600, (secs / 60) % 60, secs % 60])
			_row(12, "Journeys begun / finished", "%d / %d" % [int(Game.profile.runs), int(Game.profile.finished)])
			_row(24, "Endings found", "%d / %d" % [Game.endings_found(), Data.ENDINGS.size()], Pal.LEMON)
			_row(36, "Battles fought", str(int(r.get("battles", 0))))
			_row(48, "Won / lost / got away", "%d / %d / %d" % [int(r.get("won", 0)), int(r.get("lost", 0)), int(r.get("fled", 0))])
			_row(60, "Damage dealt / taken", "%d / %d" % [int(r.get("damage", 0)), int(r.get("taken", 0))])
			_row(72, "The blade's arts used", str(int(r.get("sword_skills", 0))), Pal.OMEN.lerp(Pal.WHITE, 0.3))
			_row(84, "Foreknowledge", str(int(r.get("foreknowledge", 0))), Pal.OMEN.lerp(Pal.WHITE, 0.3))
			_row(96, "Friends who leapt to help", str(int(r.get("assists", 0))), Pal.GLOW)
			_row(108, "Achievements", "%d / %d" % [Game.achieved.size(), Achievements.defs().size()])
			if Game.profile.endings.is_empty() and int(r.get("battles", 0)) == 0:
				var e := Art.label("Nothing recorded yet. The road is waiting.", Pal.CANDLE)
				e.position = Vector2(286 - Art.text_width(e.text), 122)
				body.add_child(e)
		1:
			_row(0, "Locks picked", str(int(r.get("locks", 0))))
			_row(12, "Pockets picked", str(int(r.get("picks", 0))))
			_row(24, "Stolen mid-fight", str(int(r.get("steals", 0))))
			_row(36, "Best lock (100 is clean)", str(Game.best("lockpick")) if Game.best("lockpick") > 0 else "-", Pal.LEMON)
			_row(48, "Best lift (100 is clean)", str(Game.best("pickpocket")) if Game.best("pickpocket") > 0 else "-", Pal.LEMON)
			_row(60, "Heaviest haul", str(Game.best("loot")) if Game.best("loot") > 0 else "-", Pal.LEMON)
	content_h = 0.0
	for c in body.get_children():
		content_h = maxf(content_h, (c as Control).position.y + 12)
	scroll = 0.0
	body.position.y = 4


func run() -> void:
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			return
		if Input.is_action_pressed("down"):
			scroll_by(90.0 * get_process_delta_time())
		elif Input.is_action_pressed("up"):
			scroll_by(-90.0 * get_process_delta_time())
		var old := page
		if Input.is_action_just_pressed("right"):
			page = (page + 1) % PAGES.size()
		elif Input.is_action_just_pressed("left"):
			page = (page + PAGES.size() - 1) % PAGES.size()
		if old != page:
			Sfx.play("blip")
			_fill()
