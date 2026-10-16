class_name SkillsWindow
extends Control
## How the crew fights, laid out like the Items window, one tab per crew
## member (whoever fights beside Rook right now) and, once he carries it,
## one for the blade. Each tab lists the fighter's weapon (their plain
## ATTACK, and a little of its story), their techniques with TP costs, and
## greyed out, the ones still to come. The blade's tab: Foreknowledge and its
## arts, with the Suspicion each one costs and the mastery each one needs.
## Left/Right change tab, Up/Down pick, X closes. Touch: tap a tab or a row.

const ROW_H := 14
const ROWS := 10
const LIST := Rect2(6, 22, 132, 143)
const DETAIL := Rect2(142, 22, 172, 143)

var cat := 0
var index := 0
var rows: Array = []
var tabs: Array = []
## Tab keys: crew ids, then "blade".
var keys: Array = []
var list_body: Control
var detail_body: Control
var cursor: ColorRect


func _init(first: String = "rook") -> void:
	keys = Game.main.story.party()
	if Game.flag("has_sword"):
		keys.append("blade")
	cat = maxi(0, keys.find(first))
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var head := Art.make_box("bar_box")
	head.position = Vector2(6, 4)
	head.size = Vector2(52, 16)
	add_child(head)
	var hl := Art.label("SKILLS", Pal.LEMON)
	hl.position = Vector2(7, 3)
	head.add_child(hl)
	var x := 66.0
	for k in keys:
		var t := "Blade" if k == "blade" else str(BattleDefs.member(k).name)
		var l := Art.label(t, Pal.TEXT_DIM)
		l.position = Vector2(x, 7)
		add_child(l)
		tabs.append(l)
		x += Art.text_width(t) + 14
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
	_fill()
	add_to_group("tap_targets")


func _rows_in(c: int) -> Array:
	## [{id, icon, name, right, lock (when it comes; "" when known)}]
	var key: String = keys[c]
	var out := []
	if key == "blade":
		out.append({"id": "foreknow", "icon": "skill_foreknow", "name": BattleDefs.FOREKNOW.name, "right": "x3", "lock": ""})
		for id in BattleDefs.SWORD_ARTS:
			var sk: Dictionary = BattleDefs.SKILLS[id]
			var t := int(sk.get("tier", 1))
			out.append({"id": id, "icon": "skill_" + id, "name": sk.name, "right": "+%d" % int(sk.get("suspicion", 1)),
				"lock": "" if Game.tier() >= t else "Comes when the blade's hold reaches %s." % ["", "Invitation", "Reliance", "Dominion"][t]})
		return out
	var w := BattleDefs.weapon_of(key)
	out.append({"id": "", "icon": "weapon_" + w, "name": BattleDefs.WEAPONS[w].name, "right": "", "lock": ""})
	for id in BattleDefs.member(key).skills:
		out.append({"id": id, "icon": "skill_" + id, "name": BattleDefs.SKILLS[id].name, "right": "%d TP" % BattleDefs.SKILLS[id].cost, "lock": ""})
	for l in BattleDefs.later(key):
		out.append({"id": l[0], "icon": "skill_" + l[0], "name": BattleDefs.SKILLS[l[0]].name, "right": "%d TP" % BattleDefs.SKILLS[l[0]].cost, "lock": l[1]})
	return out


func _top() -> int:
	return clampi(index - ROWS + 1, 0, maxi(0, rows.size() - ROWS))


func _fill() -> void:
	rows = _rows_in(cat)
	index = clampi(index, 0, maxi(0, rows.size() - 1))
	for i in tabs.size():
		(tabs[i] as Label).add_theme_color_override("font_color", Pal.LEMON if i == cat else Pal.TEXT_DIM)
	for c in list_body.get_children():
		c.queue_free()
	var top := _top()
	for i in range(top, mini(top + ROWS, rows.size())):
		var r: Dictionary = rows[i]
		var locked: bool = r.lock != ""
		var y := (i - top) * ROW_H
		var ic := ItemsWindow._icon_at(list_body, r.icon, Vector2(0, y))
		if locked:
			ic.modulate = Color(1, 1, 1, 0.4)
		var l := Art.label(str(r.name), Pal.TEXT_DIM if locked else Pal.TEXT)
		l.position = Vector2(16, y + 2)
		list_body.add_child(l)
		if r.right != "":
			var rc := Pal.TEXT_DIM if locked else (Pal.OMEN.lerp(Pal.WHITE, 0.3) if keys[cat] == "blade" else Pal.CREAM)
			var cl := Art.label(r.right, rc)
			cl.position = Vector2(LIST.size.x - 10 - Art.text_width(r.right), y + 2)
			list_body.add_child(cl)
	cursor.visible = not rows.is_empty()
	cursor.position = Vector2(4, 4 + (index - top) * ROW_H)
	_detail()


func _line(text: String, y: float, col: Color, x: float = 0.0) -> float:
	for w in Art.wrap(text, 158 - int(x)):
		var l := Art.label(w, col)
		l.position = Vector2(x, y)
		detail_body.add_child(l)
		y += 10
	return y


func _tagged(icon: String, text: String, pos: Vector2, col: Color = Pal.CREAM) -> float:
	## A small icon with a word after it; returns where the word ends.
	ItemsWindow._icon_at(detail_body, icon, pos + Vector2(0, 1))
	var l := Art.label(text, col)
	l.position = pos + Vector2(12, 0)
	detail_body.add_child(l)
	return pos.x + 12 + Art.text_width(text)


func _detail() -> void:
	for c in detail_body.get_children():
		c.queue_free()
	if rows.is_empty():
		return
	var r: Dictionary = rows[index]
	var key: String = keys[cat]
	var locked: bool = r.lock != ""
	var big := ItemsWindow._icon_at(detail_body, r.icon, Vector2.ZERO)
	big.scale = Vector2(2, 2)
	if locked:
		big.modulate = Color(1, 1, 1, 0.45)
	var nm := Art.label(str(r.name), Pal.TEXT_DIM if locked else (Pal.OMEN.lerp(Pal.WHITE, 0.3) if key == "blade" else Pal.CANDLE))
	nm.position = Vector2(34, 3)
	detail_body.add_child(nm)
	var sub := "The blade's art" if key == "blade" else ("%s's weapon" % BattleDefs.member(key).name if r.id == "" else str(BattleDefs.member(key).name))
	var sl := Art.label(sub, Pal.TEXT_DIM)
	sl.position = Vector2(34, 14)
	detail_body.add_child(sl)
	var y := 34.0
	if r.id == "":
		# the weapon: the plain ATTACK, and a little of its story
		var me := BattleDefs.member(key)
		var w: Dictionary = BattleDefs.WEAPONS[BattleDefs.weapon_of(key)]
		var x := _tagged("stat_atk", "ATK %d" % int(me.atk), Vector2(0, y)) + 10
		var al := Art.label("ATTACK" if w.attack == "Attack" else "ATTACK: " + str(w.attack), Pal.TEXT_DIM)
		al.position = Vector2(x, y)
		detail_body.add_child(al)
		y += 13
		_line(str(w.desc), y, Pal.TEXT.lerp(Pal.TEXT_DIM, 0.2))
		return
	var sk: Dictionary = BattleDefs.FOREKNOW if r.id == "foreknow" else BattleDefs.SKILLS[r.id]
	var x := 0.0
	if r.id == "foreknow":
		x = _tagged("stat_blade", "3 a battle", Vector2(x, y), Pal.OMEN.lerp(Pal.WHITE, 0.3)) + 10
	elif sk.get("sword", false):
		x = _tagged("stat_suspicion", "+%d Suspicion" % int(sk.get("suspicion", 1)), Vector2(x, y), Pal.OMEN.lerp(Pal.WHITE, 0.3)) + 10
	else:
		x = _tagged("stat_tp", "%d TP" % int(sk.cost), Vector2(x, y)) + 10
	var tl := Art.label(BattleDefs.TARGETS.get(sk.get("target", "enemy"), ""), Pal.TEXT_DIM)
	tl.position = Vector2(x, y)
	detail_body.add_child(tl)
	y += 13
	_line(str(sk.desc), y, Pal.CREAM)
	if locked:
		_line(r.lock, 112, Pal.TEXT_DIM)


func _move(d: int) -> void:
	if rows.is_empty():
		return
	var old := index
	index = clampi(index + d, 0, rows.size() - 1)
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
	if r.has_point(p) and not rows.is_empty():
		var i := _top() + int((p.y - r.position.y) / ROW_H)
		if i < rows.size() and i != index:
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
			_switch((cat + keys.size() - 1) % keys.size())
		elif Input.is_action_just_pressed("right"):
			_switch((cat + 1) % keys.size())
		elif Input.is_action_just_pressed("up"):
			_move(-1)
		elif Input.is_action_just_pressed("down"):
			_move(1)
