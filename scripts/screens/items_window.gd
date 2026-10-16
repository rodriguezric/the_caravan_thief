class_name ItemsWindow
extends Control
## Everything Rook carries, in one window over the pause menu, by category
## (Data.ITEM_CATS: supplies, goods, keepsakes). Left/Right change category,
## Up/Down pick, X closes. Each thing shows its icon, how many, and what it
## is; goods also show what they're worth, what they weigh and how badly
## they'd give him away. Supplies are only used in battle (ITEM).
## Touch: tap a tab, tap a row to pick it.

const ROW_H := 14
const ROWS := 10
const LIST := Rect2(6, 22, 132, 143)
const DETAIL := Rect2(142, 22, 172, 143)

var cat := 0
var index := 0
var ids: Array = []
var tabs: Array = []
var list_body: Control
var detail_body: Control
var cursor: ColorRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var head := Art.make_box("bar_box")
	head.position = Vector2(6, 4)
	head.size = Vector2(50, 16)
	add_child(head)
	var hl := Art.label("ITEMS", Pal.LEMON)
	hl.position = Vector2(7, 3)
	head.add_child(hl)
	var x := 66.0
	for c in Data.ITEM_CATS:
		var l := Art.label(c[1], Pal.TEXT_DIM)
		l.position = Vector2(x, 7)
		add_child(l)
		tabs.append(l)
		x += Art.text_width(c[1]) + 14
	# the load and the purse, top right
	var tail := "%d" % Game.v("coin")
	var cl := Art.label(tail, Pal.BRASS.lerp(Pal.LEMON, 0.3))
	cl.position = Vector2(314 - Art.text_width(tail), 7)
	add_child(cl)
	_icon_at(self, "stat_coin", Vector2(cl.position.x - 12, 7))
	var wt := "%d" % Game.weight()
	var wl := Art.label(wt, Pal.CREAM)
	wl.position = Vector2(cl.position.x - 20 - Art.text_width(wt), 7)
	add_child(wl)
	_icon_at(self, "stat_weight", Vector2(wl.position.x - 12, 7))
	var lp := Art.make_box("box")
	lp.position = LIST.position
	lp.size = LIST.size
	add_child(lp)
	cursor = ColorRect.new()
	cursor.color = Color(Pal.CANDLE, 0.16)
	cursor.size = Vector2(LIST.size.x - 8, ROW_H)
	lp.add_child(cursor)
	list_body = Control.new()
	list_body.position = Vector2(4, 4)
	lp.add_child(list_body)
	var dp := Art.make_box("box")
	dp.position = DETAIL.position
	dp.size = DETAIL.size
	add_child(dp)
	detail_body = Control.new()
	detail_body.position = Vector2(6, 5)
	dp.add_child(detail_body)
	# open on the first category that has anything in it
	for i in Data.ITEM_CATS.size():
		if not _ids_in(i).is_empty():
			cat = i
			break
	_fill()
	add_to_group("tap_targets")


static func _icon_at(parent: Node, id: String, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.ui(id)
	t.position = pos
	parent.add_child(t)
	return t


static func _ids_in(c: int) -> Array:
	var key: String = Data.ITEM_CATS[c][0]
	var out := []
	if key == "supply":
		for id in Data.SUPPLIES:
			if Game.supply(id) > 0:
				out.append(id)
	else:
		for id in Game.run.get("items", []):
			if Data.item(id).get("cat", "keep") == key and not out.has(id):
				out.append(id)
	return out


static func info(id: String) -> Dictionary:
	return Data.SUPPLIES[id] if Data.SUPPLIES.has(id) else Data.item(id)


func _top() -> int:
	return clampi(index - ROWS + 1, 0, maxi(0, ids.size() - ROWS))


func _fill() -> void:
	ids = _ids_in(cat)
	index = clampi(index, 0, maxi(0, ids.size() - 1))
	for i in tabs.size():
		(tabs[i] as Label).add_theme_color_override("font_color", Pal.LEMON if i == cat else Pal.TEXT_DIM)
	for c in list_body.get_children():
		c.queue_free()
	if ids.is_empty():
		var l := Art.label("Nothing.", Pal.TEXT_DIM)
		l.position = Vector2(4, 2)
		list_body.add_child(l)
	var top := _top()
	for i in range(top, mini(top + ROWS, ids.size())):
		var id: String = ids[i]
		var y := (i - top) * ROW_H
		_icon_at(list_body, "item_" + id, Vector2(0, y))
		var l := Art.label(str(info(id).name), Pal.TEXT)
		l.position = Vector2(16, y + 2)
		l.size = Vector2(LIST.size.x - 44, 10)
		l.clip_text = true
		list_body.add_child(l)
		if Data.SUPPLIES.has(id):
			var n := "x%d" % Game.supply(id)
			var nl := Art.label(n, Pal.CREAM)
			nl.position = Vector2(LIST.size.x - 10 - Art.text_width(n), y + 2)
			list_body.add_child(nl)
	cursor.visible = not ids.is_empty()
	cursor.position = Vector2(4, 4 + (index - top) * ROW_H)
	_detail()


func _tagged(icon: String, text: String, pos: Vector2, col: Color = Pal.CREAM) -> float:
	## A small icon with a word after it; returns where the word ends.
	_icon_at(detail_body, icon, pos + Vector2(0, 1))
	var l := Art.label(text, col)
	l.position = pos + Vector2(12, 0)
	detail_body.add_child(l)
	return pos.x + 12 + Art.text_width(text)


func _detail() -> void:
	for c in detail_body.get_children():
		c.queue_free()
	if ids.is_empty():
		var l := Art.label("Nothing of this kind.", Pal.TEXT_DIM)
		detail_body.add_child(l)
		return
	var id: String = ids[index]
	var d := info(id)
	var big := _icon_at(detail_body, "item_" + id, Vector2.ZERO)
	big.scale = Vector2(2, 2)
	var nm := Art.label(str(d.name), Pal.CANDLE)
	nm.position = Vector2(34, 3)
	detail_body.add_child(nm)
	var sub: String = Data.ITEM_CATS[cat][1]
	if Data.SUPPLIES.has(id):
		sub += "   x%d" % Game.supply(id)
	var sl := Art.label(sub, Pal.TEXT_DIM)
	sl.position = Vector2(34, 14)
	detail_body.add_child(sl)
	var y := 34.0
	if not Data.SUPPLIES.has(id):
		# what it's worth, what it weighs, how badly it gives Rook away
		var x := 0.0
		if int(d.get("value", 0)) > 0:
			x = _tagged("stat_value", str(d.value), Vector2(x, y), Pal.BRASS.lerp(Pal.LEMON, 0.3)) + 10
		x = _tagged("stat_weight", "%d" % int(d.get("weight", 0)), Vector2(x, y)) + 10
		var ev := int(d.get("evidence", 0))
		_tagged("stat_evidence", ["harmless", "suspicious", "telling", "damning"][clampi(ev, 0, 3)], Vector2(x, y),
			Pal.BLOOD.lerp(Pal.WHITE, 0.3) if ev >= 3 else (Pal.CREAM if ev > 0 else Pal.TEXT_DIM))
		y += 13
	for line in Art.wrap(str(d.desc), 158):
		var l := Art.label(line, Pal.CREAM)
		l.position = Vector2(0, y)
		detail_body.add_child(l)
		y += 10
	var how := ""
	if Data.SUPPLIES.has(id):
		how = "Used in battle (ITEM)"
	elif d.has("owner"):
		how = "Belongs to " + str(Data.spec(d.owner).name)
	elif d.get("lore", false):
		how = "Part of the story"
	var hl := Art.label(how, Pal.TEXT_DIM)
	hl.position = Vector2(0, 122)
	detail_body.add_child(hl)


func _move(d: int) -> void:
	if ids.is_empty():
		return
	var old := index
	index = clampi(index + d, 0, ids.size() - 1)
	if index != old:
		Sfx.play("blip")
		_fill()


func _switch(c: int) -> void:
	if c != cat:
		cat = c
		index = 0
		Sfx.play("blip")
		_fill()


func tap(p: Vector2) -> bool:
	for i in tabs.size():
		var l: Label = tabs[i]
		if Rect2(l.position - Vector2(3, 3), Vector2(Art.text_width(l.text) + 6, 14)).has_point(p):
			_switch(i)
			return true
	var r := Rect2(LIST.position + Vector2(4, 4), Vector2(LIST.size.x - 8, ROWS * ROW_H))
	if r.has_point(p) and not ids.is_empty():
		var i := _top() + int((p.y - r.position.y) / ROW_H)
		if i < ids.size() and i != index:
			index = i
			Sfx.play("blip")
			_fill()
	return true


func run() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		await get_tree().process_frame
		if Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			return
		if Input.is_action_just_pressed("left"):
			_switch((cat + Data.ITEM_CATS.size() - 1) % Data.ITEM_CATS.size())
		elif Input.is_action_just_pressed("right"):
			_switch((cat + 1) % Data.ITEM_CATS.size())
		elif Input.is_action_just_pressed("up"):
			_move(-1)
		elif Input.is_action_just_pressed("down"):
			_move(1)
