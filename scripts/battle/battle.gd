class_name Battle
extends Control
## Side-view turn-based battles, built to feel physical.
##
## Turn order is by speed and shown as a strip of faces at the top. Enemies
## choose what they mean to do at the start of each round; Rook's
## Foreknowledge (once he carries the blade) shows those intents ahead of time.
## Commands follow the series' six families: ATTACK, SKILL (techniques, TP),
## SWORD (the blade's arts: free, strong, and each use raises Suspicion), ITEM,
## GUARD and ACT (steal, talk, run, and whatever this fight's objective needs).
##
## Every action is choreographed: wind-up, dash with afterimages, impact with
## hit-stop, a camera punch, sparks and bouncing numbers, knockback, and a hop
## home. Criticals slow time; Thousand Hands stops it.
##
## A battle is a definition dictionary (see BattleDefs and the story) plus
## optional async hooks: intro(b), on_turn(b, turn) -> resolution,
## on_act(b, unit, act_id) -> resolution, on_ko(b, unit) -> resolution,
## thresholds [{unit, below, fn(b) -> resolution}]. A resolution is {} to keep
## fighting, or {outcome, title, note, ...} to end it.
## Objectives: defeat (default), escape (survive `turns` rounds or run for it),
## protect (keep `units` standing: losses are casualties, not defeat),
## persuade (fill a meter with ACT > Talk), disarm (nonlethal foes kneel).

const ENEMY_SLOTS := [Vector2(88, 126), Vector2(50, 114), Vector2(124, 112), Vector2(58, 134), Vector2(120, 134)]
const PARTY_SLOTS := {1: [Vector2(252, 126)], 2: [Vector2(238, 128), Vector2(282, 114)],
	3: [Vector2(226, 130), Vector2(264, 114), Vector2(298, 130)], 4: [Vector2(218, 130), Vector2(250, 114), Vector2(282, 130), Vector2(306, 112)],
	5: [Vector2(212, 132), Vector2(238, 112), Vector2(264, 132), Vector2(290, 112), Vector2(308, 134)]}

var def: Dictionary
var bg: TextureRect
var stage: Node2D
var units_node: Node2D
var fx: Fx
var tint: ColorRect
var ui_root: Control
var help_box: NinePatchRect
var help_l: Label
var obj_box: NinePatchRect
var obj_l: Label
var meter_bar: ColorRect
var timeline: Control
var status_box: NinePatchRect
var status_rows: Array = []
var cursor: Sprite2D
var cmd_menu: Menu
var party: Array = []
var enemies: Array = []
var order: Array = []
var turn := 0
var t := 0.0
var bg_frames := 1
var stats := {"dealt": 0, "taken": 0, "turns": 0}
var changes: Array = []
var loot: Array = []
var casualties: Array = []
var spared: Array = []
var killed: Array = []
var foreknown := false
var fk_charges := 0
var meter := 0
var phase := "entering"
var zoom := 1.0
var _thresholds_done := {}
var _active: BattleUnit = null
var _tap_pick := -1
var _tap_units: Array = []
var objective := "defeat"


# ------------------------------------------------------------------ setup --

func setup(p_def: Dictionary) -> void:
	def = p_def
	set_anchors_preset(Control.PRESET_FULL_RECT)
	objective = def.get("objective", {}).get("kind", "defeat")
	bg = TextureRect.new()
	bg.texture = Art.battle_bg(def.get("bg", "road"), 0)
	add_child(bg)
	bg_frames = ArtBattle.frames(def.get("bg", "road"))
	stage = Node2D.new()
	add_child(stage)
	units_node = Node2D.new()
	units_node.y_sort_enabled = true
	stage.add_child(units_node)
	fx = Fx.new()
	fx.z_index = 10
	stage.add_child(fx)
	tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(Pal.OMEN, 0.0)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	var plist: Array = def.get("party", ["rook"])
	for i in plist.size():
		var pd: Dictionary = plist[i] if plist[i] is Dictionary else BattleDefs.member(plist[i])
		var u := BattleUnit.new()
		var slots: Array = PARTY_SLOTS[mini(5, plist.size())]
		u.setup("party", pd, pd.get("pos", slots[mini(i, slots.size() - 1)]))
		units_node.add_child(u)
		party.append(u)
	var elist: Array = def.get("enemies", [])
	for i in elist.size():
		var ed: Dictionary = elist[i]
		if not ed.has("id"):
			ed.id = "e%d" % i
		var u := BattleUnit.new()
		u.setup("enemy", ed, ed.get("pos", ENEMY_SLOTS[i % ENEMY_SLOTS.size()]))
		u.mood = ed.get("mood", "")
		units_node.add_child(u)
		enemies.append(u)
	var hostile: bool = Game.hostile_allies() and not def.get("no_hostile", false)
	for u: BattleUnit in party:
		u.set_hostile(hostile and u.id != "rook" and not u.ai)
	fk_charges = 3 if Game.flag("has_sword") and _rook() != null else 0
	_build_ui()


func _rook() -> BattleUnit:
	for u: BattleUnit in party:
		if u.id == "rook":
			return u
	return null


func unit(id: String) -> BattleUnit:
	for u: BattleUnit in party + enemies:
		if u.id == id:
			return u
	return null


func living(units: Array) -> Array:
	return units.filter(func(u: BattleUnit) -> bool: return u.alive and u.hp > 0)


func fighters(units: Array) -> Array:
	## Living units that count for defeat (protected NPCs don't).
	return living(units).filter(func(u: BattleUnit) -> bool: return not u.ai)


func _build_ui() -> void:
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	timeline = Control.new()
	timeline.position = Vector2(4, 2)
	ui_root.add_child(timeline)
	help_box = Art.make_box("bar_box")
	help_box.position = Vector2(6, 22)
	help_box.size = Vector2(308, 15)
	ui_root.add_child(help_box)
	help_l = Art.label(def.get("title", ""), Pal.TEXT)
	help_l.position = Vector2(6, 2)
	help_l.size = Vector2(296, 10)
	help_l.clip_text = true
	help_box.add_child(help_l)
	obj_box = Art.make_box("box")
	obj_box.size = Vector2(110, 18)
	obj_box.position = Vector2(206, 2)
	ui_root.add_child(obj_box)
	obj_l = Art.label("", Pal.CANDLE)
	obj_l.position = Vector2(5, 3)
	obj_l.size = Vector2(100, 10)
	obj_l.clip_text = true
	obj_box.add_child(obj_l)
	meter_bar = ColorRect.new()
	meter_bar.color = Pal.GLOW
	meter_bar.position = Vector2(4, 14)
	meter_bar.size = Vector2(0, 2)
	obj_box.add_child(meter_bar)
	status_box = Art.make_box("box")
	status_box.position = Vector2(106, 138)
	status_box.size = Vector2(210, 40)
	ui_root.add_child(status_box)
	var shown := party.filter(func(u: BattleUnit) -> bool: return not u.ai)
	if shown.size() > 3:
		status_box.position.y = 132
		status_box.size.y = 46
	for i in shown.size():
		var u: BattleUnit = shown[i]
		var y := 4 + i * 11
		var nl := Art.label(u.uname, Pal.OMEN.lerp(Pal.WHITE, 0.3) if u.hostile else Pal.TEXT)
		nl.position = Vector2(10, y)
		nl.size = Vector2(56, 10)
		nl.clip_text = true
		status_box.add_child(nl)
		var back := ColorRect.new()
		back.color = Pal.INK
		back.position = Vector2(68, y + 3)
		back.size = Vector2(58, 5)
		status_box.add_child(back)
		var lag := ColorRect.new()
		lag.color = Pal.WHITE
		lag.position = Vector2(1, 1)
		lag.size = Vector2(56, 3)
		back.add_child(lag)
		var bar := ColorRect.new()
		bar.color = Pal.GLOW.lerp(Pal.SAGE, 0.3)
		bar.position = Vector2(1, 1)
		bar.size = Vector2(56, 3)
		back.add_child(bar)
		var hp_l := Art.label("", Pal.TEXT)
		hp_l.position = Vector2(130, y)
		status_box.add_child(hp_l)
		var tp_l := Art.label("", Pal.SKY.lerp(Pal.WHITE, 0.3))
		tp_l.position = Vector2(172, y)
		status_box.add_child(tp_l)
		var arrow := TextureRect.new()
		arrow.texture = Art.ui("cursor")
		arrow.position = Vector2(2, y)
		arrow.visible = false
		status_box.add_child(arrow)
		status_rows.append({"u": u, "name": nl, "bar": bar, "lag": lag, "hp": hp_l, "tp": tp_l, "arrow": arrow, "shown_hp": u.hp})
	cursor = Sprite2D.new()
	cursor.texture = Art.ui("target")
	cursor.visible = false
	cursor.z_index = 40
	add_child(cursor)
	_refresh_status(true)
	_refresh_objective()


func _refresh_status(instant: bool = false) -> void:
	for r in status_rows:
		var u: BattleUnit = r.u
		(r.hp as Label).text = "%d/%d" % [u.hp, u.max_hp]
		(r.tp as Label).text = "TP %d" % u.tp if u.max_tp > 0 else ""
		var k := float(u.hp) / float(maxi(1, u.max_hp))
		var bar: ColorRect = r.bar
		var lag: ColorRect = r.lag
		bar.color = Pal.GLOW.lerp(Pal.SAGE, 0.3) if k > 0.5 else (Pal.LEMON if k > 0.2 else Pal.BLOOD)
		if instant:
			bar.size.x = 56.0 * k
			lag.size.x = 56.0 * k
		else:
			# the bar drops at once; a white chunk shows what was lost, then drains
			if 56.0 * k < bar.size.x:
				bar.size.x = 56.0 * k
				var tw := create_tween()
				tw.tween_interval(0.35)
				tw.tween_property(lag, "size:x", 56.0 * k, 0.4).set_trans(Tween.TRANS_SINE)
			else:
				lag.size.x = 56.0 * k
				create_tween().tween_property(bar, "size:x", 56.0 * k, 0.35).set_trans(Tween.TRANS_SINE)
		(r.name as Label).add_theme_color_override("font_color", Pal.TEXT_DIM if u.hp <= 0 else (Pal.OMEN.lerp(Pal.WHITE, 0.3) if u.hostile else Pal.TEXT))
		(r.arrow as TextureRect).visible = u == _active


func _refresh_objective() -> void:
	var o: Dictionary = def.get("objective", {})
	var text := ""
	match objective:
		"defeat":
			text = o.get("text", "DEFEAT THEM")
		"escape":
			var left := int(o.get("turns", 3)) - turn + 1
			text = o.get("text", "SURVIVE") + " %d" % maxi(0, left) if o.has("turns") else o.get("text", "GET AWAY")
		"protect":
			text = o.get("text", "PROTECT THE CREW")
		"persuade":
			text = o.get("text", "TALK THEM DOWN")
		"disarm":
			text = o.get("text", "DISARM, DON'T KILL")
		_:
			text = o.get("text", "")
	obj_l.text = text
	obj_box.size.x = maxf(60.0, Art.text_width(text) + 12.0)
	obj_box.position.x = 316 - obj_box.size.x
	meter_bar.visible = objective == "persuade"
	if objective == "persuade":
		var need := int(o.get("need", 3))
		create_tween().tween_property(meter_bar, "size:x", (obj_box.size.x - 8.0) * clampf(float(meter) / need, 0.0, 1.0), 0.3)


func _build_timeline(list: Array, current: int) -> void:
	for c in timeline.get_children():
		c.queue_free()
	var x := 0.0
	for i in mini(list.size(), 10):
		var u: BattleUnit = list[i]
		var chip := NinePatchRect.new()
		chip.texture = Art.ui("box" if u.side == "party" else "red_box")
		chip.patch_margin_left = 4
		chip.patch_margin_right = 4
		chip.patch_margin_top = 4
		chip.patch_margin_bottom = 4
		chip.size = Vector2(18, 18)
		chip.position = Vector2(x, 0 if i == current else 1)
		var ic := TextureRect.new()
		ic.texture = Art.head_icon(u.spec, u.mood, u.hostile)
		ic.position = Vector2(1, 1)
		chip.add_child(ic)
		if u.side == "enemy" and foreknown and not u.intent.is_empty():
			var ii := TextureRect.new()
			ii.texture = Art.ui(_intent_icon(u.intent))
			ii.position = Vector2(10, 9)
			chip.add_child(ii)
		if i < current:
			chip.modulate = Color(0.5, 0.5, 0.55, 0.7)
		if i == current:
			var now := TextureRect.new()
			now.texture = Art.ui("now")
			now.position = Vector2(6, 18)
			chip.add_child(now)
			chip.scale = Vector2(1.15, 1.15)
			chip.pivot_offset = Vector2(9, 9)
		timeline.add_child(chip)
		x += 20.0
	timeline.size = Vector2(x, 20)


func _intent_icon(i: Dictionary) -> String:
	match i.get("kind", "hit"):
		"buff":
			return "i_guard"
		"debuff", "seal", "claim", "drain":
			return "i_skill"
	return "i_attack"


# ---------------------------------------------------------------- process --

func _process(delta: float) -> void:
	t += delta
	if bg_frames > 1:
		bg.texture = Art.battle_bg(def.get("bg", "road"), int(t * 3.0) % bg_frames)
	if cursor.visible:
		cursor.position.y = cursor.get_meta("y") + (1 if fmod(t, 0.5) < 0.25 else 0)
	_update_intent_marks()


var _marks := {}


func _update_intent_marks() -> void:
	## Intent icons hover over enemies whose next move is known.
	for e: BattleUnit in enemies:
		var show: bool = e.alive and not e.intent.is_empty() and (foreknown or e.intent.get("telegraph", false)) and phase != "results"
		var m: Sprite2D = _marks.get(e.id, null)
		if show and m == null:
			m = Sprite2D.new()
			m.z_index = 30
			add_child(m)
			_marks[e.id] = m
			m.scale = Vector2(0.2, 0.2)
			create_tween().tween_property(m, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		if m != null:
			m.visible = show
			if show:
				m.texture = Art.ui(_intent_icon(e.intent))
				m.position = (e.head() + Vector2(0, -8 + (1 if fmod(t + e.id.hash() % 5, 0.8) < 0.4 else 0))).round()
				m.modulate = Color(1, 1, 1, 1) if not e.intent.get("telegraph", false) or foreknown else Color(Pal.BLOOD.lerp(Pal.WHITE, 0.4), 1)


# ------------------------------------------------------------------- flow --

func run() -> Dictionary:
	Engine.time_scale = Game.battle_speed()
	Sfx.music(def.get("music", "battle"), 0.6)
	ui_root.modulate.a = 0.0
	# everyone takes their stance: enemies slide in from the left, the crew
	# from the right, and land with a little dust
	for u: BattleUnit in party + enemies:
		var from := u.home + Vector2(-90 if u.side == "enemy" else 90, 0)
		u.position = from
		u.set_pose("walk" if u.spec.get("kind", "human") != "human" else "run")
		var tw := u.create_tween()
		tw.tween_interval(randf() * 0.15)
		tw.tween_property(u, "position", u.home, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			u.set_pose("ready")
			u.squash(1.2, 0.85)
			fx.burst(u.position, 5, [Pal.SAND, Pal.CREAM], Vector2(10, 30), Vector2(0.2, 0.4), {"up": 10.0, "dir": PI if u.side == "party" else 0.0, "spread": 0.8}))
		tw.tween_interval(0.3)
		tw.tween_callback(func() -> void: u.set_pose("idle"))
	await wait(0.6)
	create_tween().tween_property(ui_root, "modulate:a", 1.0, 0.3)
	await banner(def.get("title", "A fight!"), 1.0, "red_box")
	if def.has("intro"):
		var r: Dictionary = await def.intro.call(self)
		if not r.is_empty():
			return await _finish(r)
	while true:
		turn += 1
		stats.turns = turn
		_refresh_objective()
		if def.has("on_turn"):
			var r: Dictionary = await def.on_turn.call(self, turn)
			if not r.is_empty():
				return await _finish(r)
		foreknown = false
		for e: BattleUnit in living(enemies):
			_choose_intent(e)
		order = _turn_order()
		for i in order.size():
			var u: BattleUnit = order[i]
			if not u.alive or u.hp <= 0:
				continue
			_active = u
			_build_timeline(order, i)
			_refresh_status()
			var r := await _take_turn(u)
			if r.is_empty() and has_meta("pending"):
				r = get_meta("pending")
				remove_meta("pending")
			if not r.is_empty():
				return await _finish(r)
			var end := _check_end()
			if not end.is_empty():
				return await _finish(end)
		_active = null
		# end of round
		for u: BattleUnit in party + enemies:
			u.tick_status()
			if u.side == "party" and u.alive:
				u.tp = mini(u.max_tp, u.tp + 1)
		_refresh_status()
		if objective == "escape" and def.get("objective", {}).has("turns") and turn >= int(def.objective.turns):
			return await _finish({"outcome": "escaped", "title": def.objective.get("win_title", "GOT AWAY"), "note": def.objective.get("note", "")})
	return {}


func _turn_order() -> Array:
	var list := living(party + enemies)
	for u: BattleUnit in list:
		var s := float(u.spd) + randf_range(0.0, 3.0)
		if u.has("pinned"):
			s -= 100.0
		u.set_meta("init", s)
	list.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return float(a.get_meta("init")) > float(b.get_meta("init")))
	return list


func _check_end() -> Dictionary:
	if fighters(party).is_empty():
		return {"outcome": "defeat", "title": def.get("defeat_title", "DEFEATED"), "note": def.get("defeat_note", "")}
	var standing := living(enemies).filter(func(e: BattleUnit) -> bool: return not e.down)
	if standing.is_empty():
		if objective == "persuade" or objective == "disarm":
			return {"outcome": "victory", "title": def.get("victory_title", "DISARMED"), "note": def.get("victory_note", "")}
		return {"outcome": "victory", "title": def.get("victory_title", "VICTORY"), "note": def.get("victory_note", "")}
	if objective == "persuade" and meter >= int(def.get("objective", {}).get("need", 3)):
		return {"outcome": "objective", "title": def.objective.get("win_title", "TALKED DOWN"), "note": def.objective.get("note", "")}
	return {}


func _take_turn(u: BattleUnit) -> Dictionary:
	if u.has("dazed"):
		u.status.erase("dazed")
		await msg("%s is dazed and can't act!" % u.uname, 0.0)
		fx.orbit(u.head() + Vector2(0, -4), 6, [Pal.LEMON, Pal.WHITE], Vector2(6, 9), 6.0, 0.9, {"size": 1.0})
		u.set_pose("hurt", 0.6)
		Sfx.play("debuff", 1.2, -10.0)
		await wait(0.8)
		return {}
	if u.side == "enemy" and fighters(party).size() > 0:
		if u.has("caltrops") or _field_caltrops():
			await _caltrop_hit(u)
			if u.hp <= 0:
				return {}
		return await _enemy_act(u)
	if u.ai:
		return await _ally_auto(u)
	return await _player_turn(u)


func _field_caltrops() -> bool:
	return int(get_meta("caltrops", 0)) > 0


# ----------------------------------------------------------- player turn --

func _player_turn(u: BattleUnit) -> Dictionary:
	_refresh_status()
	u.set_pose("ready")
	u.squash(0.9, 1.1)
	Sfx.play("turn", 1.0, -10.0)
	_highlight(u, true)
	await msg("%s's turn." % u.uname, 0.0)
	if Game.autoplay():
		var r := await _auto_turn(u)
		_highlight(u, false)
		return r
	while true:
		var is_rook := u.id == "rook"
		var opts := [{"text": "ATTACK"}, {"text": "SKILL", "enabled": not u.data.get("skills", []).is_empty()},
			{"text": "SWORD", "enabled": is_rook and Game.flag("has_sword") and not u.has("sealed")},
			{"text": "ITEM", "enabled": _supply_list().size() > 0}, {"text": "GUARD"}, {"text": "ACT", "enabled": not _act_list(u).is_empty()}]
		cmd_menu = Menu.make(ui_root, opts, Vector2(4, 138), Vector2(100, 37), 2)
		cmd_menu.cancellable = false
		_pop_in(cmd_menu)
		cmd_menu.moved.connect(func(i: int) -> void:
			help_l.text = ["Strike with your weapon.", "Use a technique (costs TP).", "Call on the blade. Free, strong, and it raises Suspicion." if not u.has("sealed") else "SEALED. The blade will not answer.",
				"Use something from your pack.", "Brace. Take less damage and recover 2 TP.", "Steal, talk, run, or do what this fight needs."][i])
		var c := await cmd_menu.ask()
		cmd_menu.queue_free()
		var plan := {}
		match c:
			0:
				var tgt := await choose_target(_targets_for(u, "enemy"))
				if tgt != null:
					plan = {"cmd": "attack", "target": tgt}
			1:
				var sk := await _sub_menu(u, "skills")
				if not sk.is_empty():
					var tgt := await _pick_for(u, sk)
					if tgt != null or sk.target in ["all", "party", "self"]:
						plan = {"cmd": "skill", "skill": sk, "target": tgt}
			2:
				var sk := await _sub_menu(u, "sword")
				if not sk.is_empty():
					if sk.id == "foreknow":
						await foreknowledge(u)
						continue
					var tgt := await _pick_for(u, sk)
					if tgt != null or sk.target in ["all", "party", "self"]:
						plan = {"cmd": "skill", "skill": sk, "target": tgt}
			3:
				var it := await _sub_menu(u, "items")
				if not it.is_empty():
					var tgt: BattleUnit = null
					if it.target == "ally":
						tgt = await choose_target(living(party))
					elif it.target == "enemy":
						tgt = await choose_target(living(enemies))
					if tgt != null or it.target == "party":
						plan = {"cmd": "item", "item": it, "target": tgt}
			4:
				plan = {"cmd": "guard"}
			5:
				var a := await _sub_menu(u, "act")
				if not a.is_empty():
					var tgt: BattleUnit = null
					if a.get("target", "") == "enemy":
						tgt = await choose_target(living(enemies))
						if tgt == null:
							continue
					plan = {"cmd": "act", "act": a, "target": tgt}
		if plan.is_empty():
			continue
		_highlight(u, false)
		return await _execute(u, plan)
	return {}


func _auto_turn(u: BattleUnit) -> Dictionary:
	## Automated runs: CT_ACT=<act id> uses that ACT when offered; Rook uses
	## the blade's arts when CT_SWORD is set; otherwise everyone attacks.
	await wait(0.15)
	var want := OS.get_environment("CT_ACT")
	for a in _act_list(u):
		if a.id in want.split(","):
			print("[auto] act: ", a.id)
			var tgt: BattleUnit = living(enemies)[0] if a.get("target", "") == "enemy" else null
			return await _execute(u, {"cmd": "act", "act": a, "target": tgt})
	if u.id == "rook" and Game.flag("has_sword") and OS.get_environment("CT_SWORD") != "" and not u.has("sealed"):
		if fk_charges > 0 and not foreknown:
			await foreknowledge(u)
		var arts := _sword_list(u)
		if arts.size() > 0:
			var sk: Dictionary = arts[min(arts.size() - 1, turn % arts.size())]
			var tgt: BattleUnit = living(enemies)[0] if sk.target == "enemy" else (u if sk.target == "self" else null)
			return await _execute(u, {"cmd": "skill", "skill": sk, "target": tgt})
	if living(enemies).is_empty():
		return {}
	# a sensible player: patch up whoever's hurting, then spend TP, then hit
	var hurt := living(party).filter(func(p: BattleUnit) -> bool: return p.hp < p.max_hp * 0.4 and not p.ai)
	if not hurt.is_empty():
		for id in ["salve", "bread"]:
			if Game.supply(id) > 0:
				var it: Dictionary = Data.SUPPLIES[id].duplicate()
				it.id = id
				return await _execute(u, {"cmd": "item", "item": it, "target": hurt[0]})
		if u.data.get("skills", []).has("dressing") and u.tp >= 4:
			var sk: Dictionary = BattleDefs.SKILLS.dressing.duplicate()
			sk.id = "dressing"
			return await _execute(u, {"cmd": "skill", "skill": sk, "target": hurt[0]})
	var foe := _first(enemies)
	for sid in u.data.get("skills", []):
		var sk: Dictionary = BattleDefs.SKILLS[sid].duplicate()
		sk.id = sid
		if sk.kind == "dmg" and u.tp >= int(sk.cost) and randf() < 0.5:
			return await _execute(u, {"cmd": "skill", "skill": sk, "target": foe})
	return await _execute(u, {"cmd": "attack", "target": foe})


func _highlight(u: BattleUnit, on: bool) -> void:
	var to := u.home + (Vector2(-8 if u.side == "party" else 8, 0) if on else Vector2.ZERO)
	create_tween().tween_property(u, "position", to, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not on:
		u.set_pose("idle")


func _pop_in(m: Control) -> void:
	m.scale = Vector2(1, 0.2)
	m.pivot_offset = Vector2(0, m.size.y)
	create_tween().tween_property(m, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _targets_for(u: BattleUnit, kind: String) -> Array:
	var list := living(enemies).filter(func(e: BattleUnit) -> bool: return not e.down)
	if kind == "enemy" and u.id == "rook":
		# the blade shows friends as thieves: they can be targeted too
		for p: BattleUnit in living(party):
			if p.hostile:
				list.append(p)
	return list


func _pick_for(u: BattleUnit, sk: Dictionary) -> BattleUnit:
	match sk.target:
		"enemy":
			return await choose_target(_targets_for(u, "enemy") if sk.get("sword", false) else living(enemies).filter(func(e: BattleUnit) -> bool: return not e.down))
		"ally":
			return await choose_target(living(party))
	return null


func _supply_list() -> Array:
	var out := []
	for id in ["bread", "salve", "tonic", "smoke", "sand"]:
		if Game.supply(id) > 0:
			var s: Dictionary = Data.SUPPLIES[id].duplicate()
			s.id = id
			s.count = Game.supply(id)
			out.append(s)
	return out


func _sword_list(u: BattleUnit) -> Array:
	var out := []
	for id in BattleDefs.SWORD_ARTS:
		var sk: Dictionary = BattleDefs.SKILLS[id].duplicate()
		sk.id = id
		if Game.tier() >= int(sk.get("tier", 1)):
			out.append(sk)
	return out


func _act_list(u: BattleUnit) -> Array:
	var out := []
	if u.id == "rook" and not def.get("no_steal", false):
		out.append({"id": "steal", "name": "Steal", "desc": "Lift something from an enemy's pockets.", "target": "enemy"})
	if objective == "persuade" or def.has("talk"):
		out.append({"id": "talk", "name": "Talk", "desc": def.get("objective", {}).get("talk_desc", "Say something. Maybe the right thing.")})
	for a in def.get("acts", []):
		if a.get("who", "rook") in [u.id, "any"] and not (a.get("once", false) and has_meta("used_" + a.id)):
			out.append(a)
	if objective == "escape" or def.get("can_flee", false):
		out.append({"id": "run", "name": def.get("objective", {}).get("run_name", "Run for it"), "desc": "Try to get the crew out of here."})
	return out


func _sub_menu(u: BattleUnit, kind: String) -> Dictionary:
	var list := []
	var opts := []
	match kind:
		"skills":
			for sid in u.data.get("skills", []):
				var sk: Dictionary = BattleDefs.SKILLS[sid].duplicate()
				sk.id = sid
				list.append(sk)
				opts.append({"text": sk.name, "right": "%d TP" % sk.cost, "enabled": u.tp >= int(sk.cost)})
		"sword":
			list.append({"id": "foreknow", "name": "Foreknowledge", "desc": "See what every enemy means to do this round. Doesn't use your turn.", "target": "none"})
			opts.append({"text": "Foreknowledge", "right": "x%d" % fk_charges, "enabled": fk_charges > 0 and not foreknown})
			for sk in _sword_list(u):
				list.append(sk)
				opts.append({"text": sk.name, "right": "+%d" % int(sk.get("suspicion", 1))})
		"items":
			for s in _supply_list():
				list.append(s)
				opts.append({"text": s.name, "right": "x%d" % s.count})
		"act":
			for a in _act_list(u):
				list.append(a)
				opts.append({"text": a.name})
	if list.is_empty():
		return {}
	var h := opts.size() * 10 + 7
	var m := Menu.make(ui_root, opts, Vector2(106, 176 - h), Vector2(210, h))
	m.moved.connect(func(i: int) -> void:
		if i < list.size():
			var d: String = list[i].get("desc", "")
			if kind == "sword" and list[i].has("suspicion"):
				d = "[SUSPICION +%d] " % int(list[i].suspicion) + d
			help_l.text = d)
	_pop_in(m)
	var r := await m.ask()
	m.queue_free()
	if r < 0:
		return {}
	return list[r]


func choose_target(units: Array) -> BattleUnit:
	var alive := units.filter(func(x: BattleUnit) -> bool: return x.alive)
	if alive.is_empty():
		return null
	var idx := 0
	cursor.visible = true
	_tap_pick = -1
	_tap_units = alive
	set_meta("tap_priority", 5)
	add_to_group("tap_targets")
	await get_tree().process_frame
	var chosen: BattleUnit = null
	while true:
		if _tap_pick >= 0:
			if _tap_pick == idx:
				_tap_pick = -1
				chosen = alive[idx]
				break
			idx = _tap_pick
			_tap_pick = -1
			Sfx.play("blip")
		var u: BattleUnit = alive[idx]
		cursor.texture = Art.ui("target_omen" if u.side == "party" else "target")
		cursor.position = (u.head() + Vector2(0, -6)).round()
		cursor.set_meta("y", cursor.position.y)
		var info := "%s  %d/%d" % [u.uname, u.hp, u.max_hp]
		if u.side == "enemy" and foreknown and not u.intent.is_empty():
			info += "  > " + str(u.intent.get("name", "?"))
		if u.side == "party":
			info = "%s ...or is it? (an ally)" % u.uname
		help_l.text = info
		await get_tree().process_frame
		if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("down"):
			idx = (idx + 1) % alive.size()
			Sfx.play("blip")
		elif Input.is_action_just_pressed("left") or Input.is_action_just_pressed("up"):
			idx = (idx - 1 + alive.size()) % alive.size()
			Sfx.play("blip")
		elif Input.is_action_just_pressed("accept"):
			chosen = u
			break
		elif Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			break
	if chosen != null:
		Sfx.play("confirm")
	cursor.visible = false
	remove_from_group("tap_targets")
	return chosen


func tap(p: Vector2) -> bool:
	## Touch, while choosing a target: which fighter was tapped?
	for i in _tap_units.size():
		var u: BattleUnit = _tap_units[i]
		var r := Rect2(u.position + Vector2(-16 * u.k / 2.0, -32 * u.k), Vector2(32 * u.k / 2.0 * 2.0, 32 * u.k))
		if r.has_point(p):
			_tap_pick = i
			return true
	return false


# ---------------------------------------------------------------- execute --

func _execute(u: BattleUnit, p: Dictionary) -> Dictionary:
	phase = "executing"
	match p.cmd:
		"attack":
			var tgt: BattleUnit = p.target
			if tgt == null or not tgt.alive:
				tgt = _first(enemies)
			if tgt == null:
				return {}
			await banner(_attack_name(u), 0.5)
			await attack(u, tgt, 1.0)
			if tgt.side == "party":
				await _struck_ally(tgt)
			elif u.id == "rook":
				await _maybe_assist(u, tgt)
		"skill":
			var sk: Dictionary = p.skill
			if sk.get("sword", false):
				await _sword_art(u, sk, p.target)
			else:
				u.tp -= int(sk.cost)
				_refresh_status()
				await banner(sk.name, 0.6)
				await use_skill(u, sk, p.target)
				if u.id == "rook" and p.target != null and p.target.side == "enemy" and p.target.alive and sk.kind == "dmg":
					await _maybe_assist(u, p.target)
		"item":
			var it: Dictionary = p.item
			Game.add_supply(it.id, -1)
			await banner(it.name, 0.5)
			await use_item(u, it, p.target)
		"guard":
			await msg("%s braces." % u.uname, 0.0)
			u.status["guarding"] = 1
			u.tp = mini(u.max_tp, u.tp + 2)
			u.set_pose("guard")
			Sfx.play("guard", 1.0, -6.0)
			fx.ring(u.center(), 6, 22, 0.35, Pal.SKY.lerp(Pal.WHITE, 0.4), 1.0, 1.0)
			_refresh_status()
			await wait(0.5)
		"act":
			return await _do_act(u, p.act, p.target)
	phase = "planning"
	return {}


func _attack_name(u: BattleUnit) -> String:
	match u.data.get("style", "melee"):
		"bow":
			return "Arrow"
		"sling":
			return "Sling Stone"
	if u.spec.get("weapon", "") == "sword":
		return "Blade"
	if u.spec.get("weapon", "") == "cane":
		return "Cane Rap"
	if u.spec.get("weapon", "") == "club":
		return "Club"
	return "Attack"


func _first(units: Array) -> BattleUnit:
	for x: BattleUnit in units:
		if x.alive and x.hp > 0 and not x.down:
			return x
	return null


func roll_damage(src: BattleUnit, tgt: BattleUnit, power: float) -> int:
	var base := src.eff_atk() * power + randi_range(0, 3) - tgt.eff_def() * 0.8
	return maxi(1, int(round(base)))


func attack(u: BattleUnit, tgt: BattleUnit, power: float, hits: int = 1) -> void:
	## A basic attack in the attacker's own style.
	match u.data.get("style", "melee"):
		"bow":
			await shoot(u, tgt, power, "arrow")
		"sling":
			await shoot(u, tgt, power, "stone")
		"magic":
			await seal_strike(u, tgt, power)
		_:
			await melee(u, tgt, power, hits)


func melee(u: BattleUnit, tgt: BattleUnit, power: float, hits: int = 1, opts: Dictionary = {}) -> void:
	## Wind-up, dash in with afterimages, strike (with hit-stop and a camera
	## punch), follow through, hop home.
	var creature: bool = u.spec.get("kind", "human") != "human"
	u.set_pose("windup" if not creature else "ready")
	u.squash(0.85, 1.15, 0.12)
	Sfx.play("whiff", randf_range(1.1, 1.3), -14.0)
	await wait(0.14)
	var stand := tgt.position + Vector2(-u.dir_sign() * (26.0 + 6.0 * tgt.k), 1)
	if opts.get("short", false) or u.data.get("style", "") == "spear":
		stand = tgt.position + Vector2(-u.dir_sign() * 44.0, 1)
	await dash(u, stand, 0.13)
	for h in hits:
		u.set_pose("strike")
		u.squash(1.2, 0.85, 0.1)
		var crit: bool = randf() < float(u.data.get("crit", 0.06)) or opts.get("crit", false)
		_slash_fx(u, tgt, h)
		var dmg := roll_damage(u, tgt, power)
		await hit(tgt, dmg, {"crit": crit, "src": u, "fx": opts.get("fx", "slash")})
		if h < hits - 1:
			u.set_pose("windup")
			await wait(0.07)
	u.set_pose("follow")
	await wait(0.12)
	await hop_home(u)


func dash(u: BattleUnit, to: Vector2, t_: float) -> void:
	Sfx.play("dash", randf_range(0.9, 1.2), -10.0)
	fx.burst(u.position, 6, [Pal.SAND, Pal.CREAM], Vector2(20, 50), Vector2(0.2, 0.4), {"up": 15.0, "dir": PI if u.dir_sign() > 0 else 0.0, "spread": 0.6})
	var tw := create_tween()
	tw.tween_property(u, "position", to, t_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var e := 0.0
	while e < t_:
		u.afterimage(Pal.SKY.lerp(Pal.WHITE, 0.3) if u.side == "party" else Pal.CANDLE.lerp(Pal.RED, 0.35), 0.22)
		await wait(0.03)
		e += 0.03
	if tw.is_running():
		await tw.finished
	u.position = to


func hop_home(u: BattleUnit) -> void:
	if not is_instance_valid(u):
		return
	if u.position.distance_to(u.home) < 2.0:
		if u.alive and not u.down:
			u.set_pose("idle")
		return
	var from := u.position
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		u.position = from.lerp(u.home, k)
		u.set_lift(sin(k * PI) * 10.0), 0.0, 1.0, 0.26).set_trans(Tween.TRANS_SINE)
	await tw.finished
	u.set_lift(0.0)
	if u.alive and not u.down:
		u.set_pose("idle")
		u.squash(1.15, 0.88)
		fx.burst(u.position, 4, [Pal.SAND, Pal.CREAM], Vector2(10, 25), Vector2(0.2, 0.35), {"up": 8.0})


func _slash_fx(u: BattleUnit, tgt: BattleUnit, n: int) -> void:
	var c := tgt.center()
	var sword: bool = u.spec.get("weapon", "") == "sword"
	var col := Pal.OMEN if sword else Pal.WHITE
	var a0 := -2.4 if n % 2 == 0 else 0.7
	var a1 := 0.6 if n % 2 == 0 else -2.2
	if u.dir_sign() < 0:
		a0 = PI - a0
		a1 = PI - a1
	fx.slash(c, 14 + 2 * tgt.k, a0, a1, 0.24, col, 2.0)
	Sfx.play("slash" if u.spec.get("weapon", "") in ["sword", "dagger", "hook"] else "blunt", randf_range(0.9, 1.15), -4.0)


func shoot(u: BattleUnit, tgt: BattleUnit, power: float, kind: String = "arrow", opts: Dictionary = {}) -> void:
	## Draw, hold, loose: a projectile flies with a trail, and lands.
	if kind == "arrow":
		u.set_pose("aim")
		Sfx.play("bowstring", 1.0, -6.0)
		await wait(0.24)
		u.set_pose("shoot")
	else:
		u.set_pose("cast")
		await wait(0.12)
		u.set_pose("throw")
	u.squash(1.12, 0.9)
	Sfx.play("arrow" if kind == "arrow" else "whiff", randf_range(0.95, 1.1), -6.0)
	var from := u.center() + Vector2(u.dir_sign() * 14, -6)
	var to := tgt.center()
	await projectile(from, to, kind, 0.18)
	var crit: bool = randf() < float(u.data.get("crit", 0.06)) or opts.get("crit", false) or u.has("aiming")
	u.status.erase("aiming")
	await hit(tgt, roll_damage(u, tgt, power), {"crit": crit, "src": u, "fx": "pierce" if kind == "arrow" else "blunt"})
	await wait(0.1)
	u.set_pose("idle")


func projectile(from: Vector2, to: Vector2, kind: String, t_: float, arc: float = 0.0) -> void:
	var s := Sprite2D.new()
	s.texture = _projectile_tex(kind)
	s.position = from
	s.z_index = 20
	s.rotation = (to - from).angle()
	stage.add_child(s)
	var e := 0.0
	while e < t_:
		var dt := get_process_delta_time()
		e += dt
		var k := minf(1.0, e / t_)
		var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * arc)
		var prev := s.position
		s.position = p.round()
		if p != prev:
			s.rotation = (p - prev).angle()
		fx.particle(s.position, Vector2.ZERO, 0.18, Pal.CREAM if kind != "omen" else Pal.OMEN, {"size": 1.0})
		await get_tree().process_frame
	s.queue_free()


func _projectile_tex(kind: String) -> Texture2D:
	return Art.gen("proj_" + kind, func():
		var b: PixBuf
		match kind:
			"arrow":
				b = PixBuf.new(14, 5)
				b.rect(0, 2, 11, 1, Pal.WOOD.lerp(Pal.CREAM, 0.3))
				b.tri(10, 0, 10, 4, 13.5, 2, Pal.STEEL)
				b.rect(0, 1, 3, 1, Pal.CREAM)
				b.rect(0, 3, 3, 1, Pal.CREAM)
			"stone":
				b = PixBuf.new(5, 5)
				b.ball(2.5, 2.5, 2, 2, Pal.STONE)
			"sand":
				b = PixBuf.new(7, 7)
				for k in 6:
					b.pset(int(Pal.hash2(k, 1) * 6), int(Pal.hash2(k, 2) * 6), Pal.SAND)
			"omen":
				b = PixBuf.new(9, 9)
				b.ball(4.5, 4.5, 4, 4, Pal.OMEN)
				b.pset(3, 3, Pal.WHITE)
			_:
				b = PixBuf.new(3, 3)
				b.rect(0, 0, 3, 3, Pal.WHITE)
		b.outline()
		return b)


func seal_strike(u: BattleUnit, tgt: BattleUnit, power: float, opts: Dictionary = {}) -> void:
	## The Factor's way of hurting people: a brass seal stamped onto them.
	u.set_pose("cast")
	Sfx.play("magic", 0.7, -8.0)
	fx.rune(u.center() + Vector2(u.dir_sign() * 10, -10), 10, 0.6, Pal.BRASS)
	await wait(0.35)
	var c := tgt.center()
	fx.rune(c, 18, 0.7, Pal.BRASS.lerp(Pal.WHITE, 0.3))
	fx.ring(c, 30, 4, 0.3, Pal.BRASS, 2.0, 0.45)
	await wait(0.28)
	Sfx.play("seal", 1.0, -4.0)
	await hit(tgt, roll_damage(u, tgt, power), {"crit": opts.get("crit", false), "src": u, "fx": "seal"})
	u.set_pose("idle")


func hit(tgt: BattleUnit, dmg: int, opts: Dictionary = {}) -> void:
	## Everything that happens when a blow lands: evasion, parries, cover,
	## damage, flash, hit-stop, knockback, numbers, and knock-outs.
	var src: BattleUnit = opts.get("src", null)
	var c := tgt.center()
	# dodge
	if not opts.get("sure", false) and (tgt.has("evasive") or (src != null and randf() < float(tgt.data.get("evade", 0.0)))):
		await _dodge(tgt)
		return
	# parry and counter (the blade saw it coming)
	if tgt.has("counter") and src != null and src.side != tgt.side and not opts.get("no_counter", false):
		tgt.status.erase("counter")
		await _parry(tgt, src)
		return
	# cover: Mara steps in front
	if tgt.has("covered") and src != null and src.side != tgt.side:
		var coverer := unit(str(tgt.get_meta("cover_by", "")))
		tgt.status.erase("covered")
		if coverer != null and coverer.alive and coverer != tgt:
			await _cover_jump(coverer, tgt)
			tgt = coverer
			c = tgt.center()
	var crit: bool = opts.get("crit", false)
	if crit:
		dmg = int(dmg * 1.75)
	if tgt.has("guarding"):
		dmg = maxi(1, dmg / 2)
	if src != null and src.side == "enemy" and tgt.has("marked"):
		dmg = int(dmg * 1.25)
	tgt.hp = maxi(0, tgt.hp - dmg)
	if tgt.side == "party":
		stats.taken += dmg
		Sfx.play("hurt", 1.0, -10.0)
		Game.buzz(30)
	else:
		stats.dealt += dmg
		Game.buzz(15)
	_impact_fx(c, opts.get("fx", "slash"), crit)
	tgt.flash()
	tgt.set_pose("hurt", 0.35)
	if tgt.spec.get("kind", "human") == "human":
		tgt.set_mood("hurt")
		get_tree().create_timer(0.4).timeout.connect(func() -> void:
			if is_instance_valid(tgt) and tgt.alive and tgt.mood == "hurt":
				tgt.set_mood(""))
	# knockback, away from the attacker
	var away := Vector2(-tgt.dir_sign() * (6.0 if not crit else 12.0), 0)
	var kb := create_tween()
	kb.tween_property(tgt, "position", tgt.position + away, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	kb.tween_interval(0.12)
	kb.tween_property(tgt, "position", tgt.home if tgt.position.distance_to(tgt.home) < 60 else tgt.position, 0.2).set_trans(Tween.TRANS_SINE)
	popup(str(dmg), c + Vector2(0, -14), Pal.BLOOD.lerp(Pal.WHITE, 0.25) if tgt.side == "party" else Pal.WHITE, crit)
	punch(c, 0.08 if crit else 0.04)
	screen_shake(3.0 if crit else 1.5, 0.25 if crit else 0.15)
	if crit:
		await critical(c)
	else:
		await hitstop(0.06)
	_refresh_status()
	await _thresholds(tgt)
	if tgt.hp <= 0:
		await wait(0.15)
		await knock_out(tgt)
	else:
		await wait(0.18)


func _impact_fx(c: Vector2, kind: String, crit: bool) -> void:
	match kind:
		"slash", "pierce", "stab":
			fx.burst(c, 12 if not crit else 22, [Pal.WHITE, Pal.LEMON, Pal.STEEL], Vector2(40, 110), Vector2(0.15, 0.35), {"shape": 1, "size": 1.0})
			fx.burst(c, 5, [Pal.BLOOD, Pal.BLOOD.lerp(Pal.INK, 0.3)], Vector2(20, 60), Vector2(0.2, 0.4), {"acc": Vector2(0, 160), "up": 20.0})
		"blunt":
			fx.ring(c, 2, 20, 0.25, Pal.WHITE, 2.0, 1.0)
			fx.burst(c, 10, [Pal.WHITE, Pal.CREAM], Vector2(30, 80), Vector2(0.15, 0.3))
		"bite":
			fx.slash(c + Vector2(0, -4), 8, -2.6, -0.5, 0.2, Pal.WHITE, 2.0)
			fx.slash(c + Vector2(0, 4), 8, 0.5, 2.6, 0.2, Pal.WHITE, 2.0)
			fx.burst(c, 6, [Pal.BLOOD], Vector2(20, 60), Vector2(0.2, 0.4), {"acc": Vector2(0, 160)})
		"seal":
			fx.ring(c, 4, 26, 0.35, Pal.BRASS, 2.0, 1.0)
			fx.burst(c, 14, [Pal.BRASS, Pal.LEMON, Pal.WHITE], Vector2(20, 70), Vector2(0.3, 0.6), {"shape": 1})
		"omen":
			fx.burst(c, 22, [Pal.OMEN, Pal.WHITE, Pal.PURPLE], Vector2(40, 120), Vector2(0.2, 0.5), {"shape": 1})
			fx.ring(c, 4, 30, 0.35, Pal.OMEN, 2.0, 1.0)
	if crit:
		fx.ring(c, 6, 40, 0.4, Pal.LEMON, 2.0, 1.0)


func _dodge(tgt: BattleUnit) -> void:
	Sfx.play("miss_swing", 1.2, -6.0)
	tgt.set_pose("dodge", 0.4)
	tgt.afterimage(Pal.SKY, 0.35)
	var from := tgt.position
	var tw := create_tween()
	tw.tween_property(tgt, "position", from + Vector2(-tgt.dir_sign() * 14, -2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(tgt, "position", tgt.home, 0.22).set_trans(Tween.TRANS_SINE)
	popup("MISS", tgt.center() + Vector2(0, -16), Pal.SKY.lerp(Pal.WHITE, 0.4))
	await wait(0.4)


func _parry(tgt: BattleUnit, src: BattleUnit) -> void:
	## The blade turns the blow and answers it.
	tgt.set_pose("guard")
	Sfx.play("clash", 1.0, -2.0)
	var mid := (tgt.center() + src.center()) / 2.0
	fx.burst(mid, 24, [Pal.WHITE, Pal.LEMON, Pal.OMEN], Vector2(60, 140), Vector2(0.15, 0.4), {"shape": 1})
	fx.ring(mid, 4, 24, 0.25, Pal.OMEN, 2.0, 1.0)
	popup("PARRY", tgt.center() + Vector2(0, -18), Pal.OMEN.lerp(Pal.WHITE, 0.4))
	punch(mid, 0.06)
	await hitstop(0.12)
	tgt.set_pose("strike")
	tgt.afterimage(Pal.OMEN, 0.3)
	_slash_fx(tgt, src, 0)
	await hit(src, roll_damage(tgt, src, 1.2), {"src": tgt, "sure": true, "no_counter": true, "fx": "omen"})
	tgt.set_pose("idle")


func _cover_jump(coverer: BattleUnit, tgt: BattleUnit) -> void:
	await msg("%s steps in front of %s!" % [coverer.uname, tgt.uname], 0.0)
	coverer.set_pose("guard")
	var spot := tgt.position + Vector2(tgt.dir_sign() * 18, 2)
	await dash(coverer, spot, 0.12)
	fx.ring(coverer.center(), 6, 20, 0.3, Pal.GLOW, 1.0, 1.0)
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		if is_instance_valid(coverer):
			hop_home(coverer))


func critical(c: Vector2) -> void:
	## Time slows for a heartbeat; a CRITICAL stamp slams in.
	Sfx.play("crit", 1.0, -2.0)
	var stamp := Art.shadow_label("CRITICAL!", Pal.LEMON, 2)
	stamp.position = (c + Vector2(-Art.text_width("CRITICAL!", 2) / 2.0, -46)).round()
	stamp.z_index = 50
	stamp.pivot_offset = Vector2(Art.text_width("CRITICAL!", 2) / 2.0, 10)
	stamp.scale = Vector2(2.2, 2.2)
	stamp.modulate.a = 0.0
	add_child(stamp)
	var tw := stamp.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(stamp, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(stamp, "modulate:a", 1.0, 0.08)
	tw.tween_interval(0.5)
	tw.tween_property(stamp, "modulate:a", 0.0, 0.25)
	tw.tween_callback(stamp.queue_free)
	Game.main.flash(Pal.WHITE, 0.2, 0.5)
	await slowmo(0.25, 0.4)


func hitstop(dur: float) -> void:
	## Freeze everything for a few frames on impact. Overlapping stops and
	## slow-motions are counted, so the speed always comes back exactly.
	if Game.reduced_motion():
		return
	_stops += 1
	_apply_time()
	await get_tree().create_timer(dur, true, false, true).timeout
	_stops -= 1
	_apply_time()


func slowmo(k: float, dur: float) -> void:
	if Game.reduced_motion():
		await wait(0.2)
		return
	_slows += 1
	_slow_k = k
	_apply_time()
	await get_tree().create_timer(dur, true, false, true).timeout
	_slows -= 1
	_apply_time()


var _stops := 0
var _slows := 0
var _slow_k := 1.0


func _apply_time() -> void:
	var base := Game.battle_speed() if phase != "results" else 1.0
	if _stops > 0:
		Engine.time_scale = base * 0.02
	elif _slows > 0:
		Engine.time_scale = base * _slow_k
	else:
		Engine.time_scale = base


func punch(p: Vector2, amt: float = 0.05, t_: float = 0.22) -> void:
	## A quick camera push toward the point of impact, easing back out.
	if Game.reduced_motion():
		return
	var tw := create_tween()
	tw.tween_method(func(z: float) -> void:
		stage.scale = Vector2(z, z)
		stage.position = p - p * z, 1.0 + amt, 1.0, t_).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func popup(text: String, pos: Vector2, c: Color, big: bool = false) -> void:
	## Damage numbers pop out big, bounce once, and fade.
	var s := Sprite2D.new()
	s.texture = Art.number(text, c, big)
	s.position = pos.round() + Vector2(randf_range(-4, 4), 0)
	s.z_index = 45
	s.scale = Vector2(0.4, 0.4)
	add_child(s)
	var y0 := s.position.y
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(1.5, 1.5), 0.07)
	tw.tween_property(s, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(s, "position:y", y0 - 14, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "position:y", y0 - 8, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.45)
	tw.tween_property(s, "modulate:a", 0.0, 0.25)
	tw.tween_callback(s.queue_free)


func knock_out(u: BattleUnit) -> void:
	u.alive = u.data.get("nonlethal", false) and u.side == "enemy"
	match u.data.get("ko", "down") if u.side == "enemy" else "down":
		"flee":
			# beasts yelp and bolt
			u.alive = false
			Sfx.play("howl_short", 1.4, -8.0)
			u.set_pose("walk")
			var tw := create_tween()
			tw.tween_property(u, "position", u.position + Vector2(-200, 0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			u.scale.x = -1.0
			await wait(0.3)
			await msg("%s bolts!" % u.uname, 0.2)
			u.visible = false
		"kneel":
			# beaten but alive: they go down on one knee and stay there
			u.down = true
			u.hp = 0
			u.set_pose("kneel")
			u.set_mood("sad")
			Sfx.play("thud", 1.0, -6.0)
			fx.burst(u.position, 8, [Pal.SAND, Pal.CREAM], Vector2(20, 50), Vector2(0.2, 0.4), {"up": 10.0})
			if not spared.has(u.uname):
				spared.append(u.uname)
			await msg(u.data.get("ko_text", "%s drops to one knee." % u.uname), 0.6)
		_:
			u.alive = false
			u.down = true
			Sfx.play("enemy_die" if u.side == "enemy" else "thud", 1.0, -4.0)
			u.set_pose("down")
			u.squash(1.3, 0.7, 0.2)
			fx.burst(u.position, 10, [Pal.SAND, Pal.CREAM], Vector2(20, 60), Vector2(0.2, 0.5), {"up": 10.0})
			if u.side == "enemy":
				await msg(u.data.get("ko_text", "%s goes down." % u.uname), 0.4)
				var tw := create_tween()
				tw.tween_interval(0.4)
				tw.tween_property(u, "modulate:a", 0.0, 0.5)
			else:
				u.set_mood("closed")
				await msg("%s is down!" % u.uname, 0.6)
				if def.get("objective", {}).get("units", []).has(u.id) and not casualties.has(u.id):
					casualties.append(u.id)
	if def.has("on_ko"):
		var r: Dictionary = await def.on_ko.call(self, u)
		if not r.is_empty():
			set_meta("pending", r)


func heal(u: BattleUnit, hp: int, tp: int = 0) -> void:
	var was_down := u.hp <= 0
	u.hp = mini(u.max_hp, u.hp + hp)
	u.tp = mini(u.max_tp, u.tp + tp)
	if was_down and u.hp > 0:
		u.alive = true
		u.down = false
		u.set_mood("")
		u.set_pose("idle")
	Sfx.play("heal")
	fx.burst(u.center(), 14, [Pal.GLOW, Pal.WHITE], Vector2(10, 30), Vector2(0.4, 0.8), {"up": 40.0, "shape": 1})
	fx.ring(u.position, 4, 22, 0.5, Pal.GLOW, 1.0, 0.4)
	if hp > 0:
		popup("+%d" % hp, u.center() + Vector2(0, -14), Pal.GLOW)
	if tp > 0:
		popup("+%d TP" % tp, u.center() + Vector2(0, -2), Pal.SKY.lerp(Pal.WHITE, 0.3))
	_refresh_status()
	await wait(0.45)


func apply_status(u: BattleUnit, s: String, turns: int = 2) -> void:
	u.status[s] = turns
	var words := {"exposed": "EXPOSED", "dazed": "DAZED", "evasive": "EVASIVE", "counter": "WATCHING", "weak": "WEAKENED",
		"rallied": "RALLIED", "pinned": "PINNED", "marked": "MARKED", "guarding": "GUARD", "sealed": "SEALED", "aiming": "AIMING", "covered": "COVERED"}
	var good := s in ["evasive", "counter", "rallied", "guarding", "aiming", "covered"]
	popup(words.get(s, s.to_upper()), u.head() + Vector2(0, -6), Pal.GLOW.lerp(Pal.WHITE, 0.3) if good else Pal.CANDLE)
	Sfx.play("buff" if good else "debuff", 1.0, -8.0)


func msg(text: String, hold: float = 0.6) -> void:
	help_l.text = text
	if hold > 0.0:
		await wait(hold)


func banner(text: String, hold: float = 0.6, box: String = "gold_box") -> void:
	## The action's name slams in at the top centre (and away).
	var b := Art.make_box(box)
	b.size = Vector2(Art.text_width(text) + 20, 18)
	b.position = Vector2(160 - b.size.x / 2.0, 42)
	b.z_index = 40
	b.pivot_offset = b.size / 2.0
	add_child(b)
	var l := Art.label(text, Pal.WHITE)
	l.position = Vector2(10, 4)
	b.add_child(l)
	b.scale = Vector2(1.5, 0.2)
	b.modulate.a = 0.0
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(b, "modulate:a", 1.0, 0.08)
	tw.tween_interval(maxf(0.2, hold))
	tw.tween_property(b, "modulate:a", 0.0, 0.2)
	tw.tween_callback(b.queue_free)
	help_l.text = text
	await wait(0.2)


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func screen_shake(amt: float = 2.0, t_: float = 0.3) -> void:
	Game.main.shake(amt, t_)


func flash(c: Color, t_: float = 0.25) -> void:
	await Game.main.flash(c, t_)


func set_tint(c: Color, a: float, t_: float = 0.3) -> void:
	await create_tween().tween_property(tint, "color", Color(c, a), t_).finished


# ------------------------------------------------------------ techniques --

func use_skill(u: BattleUnit, sk: Dictionary, tgt: BattleUnit) -> void:
	match sk.get("anim", ""):
		"flurry":
			await melee(u, tgt, float(sk.power), int(sk.get("hits", 3)))
			if tgt.alive and tgt.hp > 0:
				popup("%d HITS" % int(sk.get("hits", 3)), tgt.head() + Vector2(0, -16), Pal.CANDLE)
		"feint":
			# a ghost of Rook lunges one way, the target swings at it, Rook stabs
			u.set_pose("ready")
			var ghost_spot := tgt.position + Vector2(-u.dir_sign() * 30, -10)
			u.afterimage(Pal.SKY, 0.6)
			var g := Sprite2D.new()
			g.texture = Art.silhouette(u.spec, 2, 0, "", "strike", Pal.SKY.lerp(Pal.WHITE, 0.4))
			g.centered = false
			g.scale = Vector2(u.k, u.k)
			g.offset = -ArtPeople.FOOT
			g.flip_h = u.facing_left()
			g.position = u.position
			g.modulate.a = 0.7
			stage.add_child(g)
			var tw := create_tween()
			tw.tween_property(g, "position", ghost_spot, 0.15)
			await tw.finished
			tgt.set_pose("strike" if tgt.spec.get("kind", "human") == "human" else "strike", 0.3)
			Sfx.play("whiff", 0.8, -6.0)
			var tw2 := create_tween()
			tw2.tween_property(g, "modulate:a", 0.0, 0.2)
			tw2.tween_callback(g.queue_free)
			await wait(0.2)
			await melee(u, tgt, float(sk.power), 1, {"fx": "stab"})
			if tgt.alive and tgt.hp > 0:
				apply_status(tgt, "exposed", 2)
		"throw":
			u.set_pose("throw")
			Sfx.play("whiff", 1.3, -8.0)
			await projectile(u.center(), tgt.head(), "sand", 0.2, 12.0)
			fx.burst(tgt.head(), 18, [Pal.SAND, Pal.CREAM, Pal.DUNE], Vector2(20, 70), Vector2(0.3, 0.6), {"acc": Vector2(0, 80)})
			await hit(tgt, roll_damage(u, tgt, float(sk.power)), {"src": u, "fx": "blunt", "sure": true})
			if tgt.alive and tgt.hp > 0:
				apply_status(tgt, "dazed", 1)
			u.set_pose("idle")
		"tumble":
			u.set_pose("dodge")
			var tw := create_tween()
			tw.tween_property(u, "position", u.home + Vector2(14, 0), 0.12)
			tw.tween_property(u, "position", u.home, 0.18)
			for i in 4:
				u.afterimage(Pal.SKY, 0.3)
				await wait(0.06)
			apply_status(u, "evasive", 1)
			u.set_pose("idle")
		"pin":
			await shoot(u, tgt, float(sk.power), "arrow")
			if tgt.alive and tgt.hp > 0:
				fx.shard(tgt.position + Vector2(-6, 0), 8, 1.5, 0.8, Pal.STEEL)
				apply_status(tgt, "pinned", 2)
		"volley":
			u.set_pose("aim")
			Sfx.play("bowstring", 0.9, -6.0)
			await wait(0.25)
			u.set_pose("shoot")
			for i in 5:
				Sfx.play("arrow", randf_range(0.9, 1.2), -10.0)
				projectile(u.center() + Vector2(u.dir_sign() * 10, -8), u.center() + Vector2(u.dir_sign() * (40 + i * 10), -120), "arrow", 0.25)
				await wait(0.06)
			await wait(0.3)
			for e: BattleUnit in living(enemies).filter(func(x: BattleUnit) -> bool: return not x.down):
				await projectile(e.center() + Vector2(10, -110), e.center(), "arrow", 0.15)
				hit(e, roll_damage(u, e, float(sk.power)), {"src": u, "fx": "pierce"})
				await wait(0.08)
			await wait(0.5)
			u.set_pose("idle")
		"heal":
			u.set_pose("cast")
			await dash(u, tgt.position + Vector2(-u.dir_sign() * -14, 0) if tgt != u else u.position, 0.12)
			fx.orbit(tgt.center(), 14, [Pal.CANVAS, Pal.WHITE], Vector2(8, 14), 8.0, 0.7, {"rise": -10.0})
			await heal(tgt, int(sk.power))
			await hop_home(u)
		"cover":
			tgt.status["covered"] = 2
			tgt.set_meta("cover_by", u.id)
			u.set_pose("guard", 0.6)
			fx.ring(tgt.center(), 6, 24, 0.4, Pal.GLOW, 1.0, 1.0)
			apply_status(tgt, "covered", 2)
			await wait(0.5)
		"caltrops":
			u.set_pose("throw")
			Sfx.play("coins", 0.7, -8.0)
			for e: BattleUnit in living(enemies):
				for i in 4:
					fx.shard(e.position + Vector2(randf_range(-16, 16), randf_range(-2, 3)), 4, 1.0, 3.0, Pal.STEEL, i * 0.04)
			set_meta("caltrops", 3)
			await msg("Iron spikes litter the ground.", 0.6)
			u.set_pose("idle")
		"tale":
			u.set_pose("think")
			for i in 3:
				fx.particle(u.head() + Vector2(-10, -4), Vector2(-30 - i * 8, -10 + i * 6), 0.9, Pal.CREAM, {"size": 2.0, "shape": 2})
				Sfx.voice("fen", i)
				await wait(0.15)
			tgt.set_mood("worried" if tgt.spec.get("kind", "human") == "human" else "")
			apply_status(tgt, "weak", 3)
			await wait(0.4)
			u.set_pose("idle")
		"rally":
			u.set_pose("fist")
			Sfx.play("buff", 0.9, -4.0)
			fx.burst(u.head(), 10, [Pal.BRASS, Pal.LEMON], Vector2(20, 50), Vector2(0.3, 0.6), {"up": 20.0, "shape": 1})
			for p: BattleUnit in living(party):
				p.status["rallied"] = 3
				p.set_pose("victory", 0.5)
				p.squash(0.85, 1.2)
				fx.orbit(p.center(), 8, [Pal.CANDLE, Pal.WHITE], Vector2(8, 12), 5.0, 0.8, {"rise": -20.0})
			await wait(0.6)
			popup("RALLIED", u.head() + Vector2(0, -8), Pal.GLOW)
			u.set_pose("idle")
		"pebbles":
			u.set_pose("throw")
			for e: BattleUnit in living(enemies).filter(func(x: BattleUnit) -> bool: return not x.down):
				projectile(u.center(), e.center(), "stone", 0.2, 16.0)
				await wait(0.1)
				hit(e, roll_damage(u, e, float(sk.power)), {"src": u, "fx": "blunt"})
			await wait(0.5)
			u.set_pose("idle")
		"haymaker":
			u.set_pose("windup")
			for i in 4:
				u.squash(0.9 - i * 0.03, 1.1 + i * 0.03, 0.1)
				Sfx.play("whiff", 0.6 + i * 0.1, -14.0)
				await wait(0.12)
			await melee(u, tgt, float(sk.power), 1, {"fx": "blunt"})
			screen_shake(4.0, 0.4)
		_:
			match sk.kind:
				"dmg":
					if sk.target == "all":
						for e: BattleUnit in living(enemies):
							await attack(u, e, float(sk.power))
					else:
						await attack(u, tgt, float(sk.power))
				"heal":
					await heal(tgt if tgt else u, int(sk.power))


func use_item(u: BattleUnit, it: Dictionary, tgt: BattleUnit) -> void:
	if it.get("smoke", false):
		u.set_pose("throw")
		Sfx.play("smoke", 1.0, -4.0)
		for p: BattleUnit in living(party):
			fx.burst(p.center(), 26, [Pal.STONE, Pal.CREAM, Pal.SLATE], Vector2(10, 40), Vector2(0.8, 1.5), {"size": 3.0, "size_end": 6.0, "shape": 2, "up": 6.0})
			p.status["evasive"] = 1
		await wait(0.8)
		await msg("The crew vanishes into the smoke.", 0.5)
		u.set_pose("idle")
		return
	if it.has("stun"):
		u.set_pose("throw")
		await projectile(u.center(), tgt.head(), "sand", 0.2, 12.0)
		fx.burst(tgt.head(), 18, [Pal.SAND, Pal.CREAM], Vector2(20, 70), Vector2(0.3, 0.6), {"acc": Vector2(0, 80)})
		apply_status(tgt, "dazed", 1)
		await wait(0.4)
		u.set_pose("idle")
		return
	u.set_pose("cast", 0.4)
	Sfx.play("gulp")
	await heal(tgt if tgt else u, int(it.get("heal", 0)), int(it.get("tp", 0)))


# ---------------------------------------------------------- the blade ----

func _sword_art(u: BattleUnit, sk: Dictionary, tgt: BattleUnit) -> void:
	Game.add("suspicion", int(sk.get("suspicion", 1)))
	Game.add("reliance", 1, true)
	Game.record("sword_skills")
	changes.append("Suspicion +%d" % int(sk.get("suspicion", 1)))
	await banner(sk.name, 0.6, "omen_box")
	Sfx.play("omen", 1.0, -6.0)
	match sk.anim:
		"omen_edge":
			await omen_edge(u, tgt, float(sk.power))
		"parry":
			u.set_pose("guard")
			await set_tint(Pal.OMEN, 0.18, 0.15)
			fx.rune(u.center(), 18, 0.8, Pal.OMEN)
			u.status["counter"] = 1
			popup("WATCHING", u.head() + Vector2(0, -8), Pal.OMEN.lerp(Pal.WHITE, 0.3))
			await wait(0.5)
			await set_tint(Pal.OMEN, 0.0, 0.3)
		"thousand":
			await thousand_hands(u, float(sk.power))
			Game.set_pflag("thousand")
		"mine":
			await mine(u, tgt, float(sk.power), float(sk.get("drain", 0.5)))
	if tgt != null and tgt.side == "party" and tgt != u and sk.target == "enemy":
		await _struck_ally(tgt)
	if Game.tier() >= 3:
		Game.set_pflag("dominion")


func omen_edge(u: BattleUnit, tgt: BattleUnit, power: float) -> void:
	## The world slows and goes violet; a ghost of Rook moves first along the
	## path the blade has seen; Rook follows it exactly, and it always lands.
	await set_tint(Pal.OMEN, 0.22, 0.15)
	Sfx.play("vision", 1.3, -10.0)
	var stand := tgt.position + Vector2(-u.dir_sign() * (26.0 + 6.0 * tgt.k), 1)
	var g := Sprite2D.new()
	g.texture = Art.silhouette(u.spec, 2, 0, "omen", "strike", Pal.OMEN)
	g.centered = false
	g.scale = Vector2(u.k, u.k)
	g.offset = -ArtPeople.FOOT
	g.flip_h = u.facing_left()
	g.position = u.position
	g.modulate.a = 0.0
	stage.add_child(g)
	var tw := create_tween()
	tw.tween_property(g, "modulate:a", 0.7, 0.1)
	tw.tween_property(g, "position", stand, 0.35).set_trans(Tween.TRANS_SINE)
	await tw.finished
	fx.slash(tgt.center(), 18, -2.4, 0.6, 0.4, Pal.OMEN, 1.0)
	await wait(0.2)
	create_tween().tween_property(g, "modulate:a", 0.0, 0.25)
	u.set_pose("windup")
	await wait(0.08)
	await dash(u, stand, 0.09)
	u.set_pose("strike")
	_slash_fx(u, tgt, 0)
	await hit(tgt, roll_damage(u, tgt, power), {"crit": true, "src": u, "sure": true, "fx": "omen"})
	g.queue_free()
	u.set_pose("follow")
	await set_tint(Pal.OMEN, 0.0, 0.25)
	await hop_home(u)


func thousand_hands(u: BattleUnit, power: float) -> void:
	## Time stops for everyone but the bearer.
	Sfx.play("timestop", 1.0, -2.0)
	Sfx.music_volume(-40.0, 0.15)
	await set_tint(Pal.PLUM, 0.6, 0.12)
	for x: BattleUnit in party + enemies:
		if x != u:
			x.body.modulate = Color(0.55, 0.45, 0.75)
	var targets := living(enemies).filter(func(e: BattleUnit) -> bool: return not e.down)
	u.set_pose("ready")
	await wait(0.2)
	# Rook blinks from enemy to enemy, leaving violet cuts hanging in the air
	var cuts := []
	for e: BattleUnit in targets:
		u.afterimage(Pal.OMEN, 0.5)
		u.position = e.position + Vector2(-u.dir_sign() * 30, 1)
		u.set_pose("strike" if cuts.size() % 2 == 0 else "follow")
		u.afterimage(Pal.OMEN, 0.6)
		Sfx.play("slash", 1.4 + cuts.size() * 0.1, -6.0)
		var c := e.center()
		fx.line(c + Vector2(-16, -12), c + Vector2(16, 12), 1.4, Pal.OMEN, 2.0)
		fx.line(c + Vector2(16, -12), c + Vector2(-16, 12), 1.4, Pal.WHITE, 1.0)
		cuts.append(e)
		await wait(0.16)
	u.position = u.home
	u.set_pose("victory")
	await wait(0.35)
	# and then time starts again
	Sfx.play("timego", 1.0, -2.0)
	Sfx.music_volume(Sfx.MUSIC_DB, 0.4)
	for x: BattleUnit in party + enemies:
		x.body.modulate = Color.WHITE
	Game.main.flash(Pal.OMEN.lerp(Pal.WHITE, 0.5), 0.3, 0.7)
	await set_tint(Pal.PLUM, 0.0, 0.1)
	screen_shake(4.0, 0.5)
	for e: BattleUnit in cuts:
		hit(e, roll_damage(u, e, power), {"src": u, "sure": true, "no_counter": true, "fx": "omen", "crit": randf() < 0.3})
	await wait(1.0)
	u.set_pose("idle")


func mine(u: BattleUnit, tgt: BattleUnit, power: float, drain: float) -> void:
	## Violet threads pull the target's life across into Rook.
	u.set_pose("cast")
	await set_tint(Pal.OMEN, 0.2, 0.2)
	var hp_before := tgt.hp
	for i in 10:
		var p0 := tgt.center() + Vector2(randf_range(-8, 8), randf_range(-10, 10))
		fx.particle(p0, (u.center() - p0) * 2.2, 0.45, Pal.OMEN, {"size": 1.0, "delay": i * 0.03})
	Sfx.play("whisper", 0.8, -4.0)
	await wait(0.4)
	await hit(tgt, roll_damage(u, tgt, power), {"src": u, "sure": true, "no_counter": true, "fx": "omen"})
	var got := int((hp_before - tgt.hp) * drain)
	if got > 0:
		await heal(u, got)
	await set_tint(Pal.OMEN, 0.0, 0.3)
	u.set_pose("idle")


func foreknowledge(u: BattleUnit) -> void:
	## The eye in the stone opens. Everyone's next move is laid bare.
	fk_charges -= 1
	foreknown = true
	Game.record("foreknowledge")
	Game.add("fk_uses", 1, true)
	Achievements.check()
	Sfx.play("omen", 1.2, -4.0)
	var eye := Sprite2D.new()
	eye.texture = Art.ui("eye")
	eye.position = Vector2(160, 80)
	eye.scale = Vector2(1, 0)
	eye.z_index = 60
	add_child(eye)
	await set_tint(Pal.OMEN, 0.25, 0.12)
	var tw := create_tween()
	tw.tween_property(eye, "scale", Vector2(6, 6), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(eye, "scale", Vector2(6, 0), 0.15)
	tw.tween_callback(eye.queue_free)
	await tw.finished
	for e: BattleUnit in living(enemies):
		if e.intent.is_empty():
			continue
		var tg: BattleUnit = e.intent.get("tgt", null)
		if tg != null and is_instance_valid(tg):
			fx.line(e.head(), tg.head(), 1.6, Pal.OMEN, 1.0)
		fx.ring(e.center(), 4, 18, 0.4, Pal.OMEN, 1.0, 1.0)
	await set_tint(Pal.OMEN, 0.0, 0.4)
	_build_timeline(order, order.find(u))
	var lines := []
	for e: BattleUnit in living(enemies):
		if not e.intent.is_empty():
			var tg: BattleUnit = e.intent.get("tgt", null)
			lines.append("%s: %s%s" % [e.uname, e.intent.get("name", "?"), (" > " + tg.uname) if tg != null and is_instance_valid(tg) else ""])
	await msg(" | ".join(lines), 1.2)


func _struck_ally(a: BattleUnit) -> void:
	## Rook hit a friend because the blade showed him a thief.
	Game.set_pflag("turned")
	Game.add("loyalty", -1)
	if a.id in ["mara", "fen"]:
		Game.add(a.id, -2)
	changes.append("Struck %s" % a.uname)
	a.set_hostile(false)
	if a.alive:
		a.set_mood("shock")
		await say(a.id, ["Rook?!", "It's me! What are you doing?", "...What did that thing show you?"][randi() % 3], "shock")
		a.set_mood("")
	a.set_hostile(true)


func _maybe_assist(u: BattleUnit, tgt: BattleUnit) -> void:
	## Loyalty pays: a friend follows up Rook's blow.
	if not tgt.alive or tgt.hp <= 0 or tgt.down:
		return
	for p: BattleUnit in living(party):
		if p == u or p.hostile or p.ai:
			continue
		var trust := Game.v(p.id) if p.id in ["mara", "fen"] else 2
		var chance := clampf(Game.v("loyalty") * 0.045 + trust * 0.04, 0.0, 0.55)
		if randf() < chance:
			Game.record("assists")
			Achievements.check()
			Sfx.play("assist", 1.0, -4.0)
			await banner("%s: ASSIST!" % p.uname, 0.4, "glow_box")
			if p.data.get("style", "melee") in ["bow", "sling"]:
				await shoot(p, tgt, 0.6, "arrow" if p.data.style == "bow" else "stone")
			else:
				await melee(p, tgt, 0.6)
			return


func _thresholds(u: BattleUnit) -> void:
	for th in def.get("thresholds", []):
		var key := "%s_%s" % [th.unit, th.below]
		if _thresholds_done.has(key) or th.unit != u.id:
			continue
		if float(u.hp) / u.max_hp <= float(th.below):
			_thresholds_done[key] = true
			var r: Dictionary = await th.fn.call(self)
			if not r.is_empty():
				set_meta("pending", r)


func _caltrop_hit(u: BattleUnit) -> void:
	var n := int(get_meta("caltrops", 0))
	if n <= 0:
		return
	set_meta("caltrops", n - 1)
	fx.burst(u.position, 6, [Pal.STEEL, Pal.WHITE], Vector2(20, 50), Vector2(0.2, 0.3), {"up": 20.0})
	u.set_pose("hurt", 0.3)
	await hit(u, maxi(2, u.max_hp / 14), {"sure": true, "no_counter": true, "fx": "stab"})


# ------------------------------------------------------------------- acts --

func _do_act(u: BattleUnit, a: Dictionary, tgt: BattleUnit) -> Dictionary:
	match a.id:
		"steal":
			await banner("Steal", 0.4)
			await steal(u, tgt)
		"talk":
			return await _talk(u)
		"run":
			await banner(a.name, 0.4)
			var o: Dictionary = def.get("objective", {})
			var chance := 0.35 + Game.v("finesse") * 0.06 + (0.25 if turn >= int(o.get("run_after", 2)) else 0.0)
			if def.get("no_escape", false):
				chance = 0.0
			for p: BattleUnit in living(party):
				p.set_pose("run")
			Sfx.play("dash", 1.0, -6.0)
			if randf() < chance or Game.autoplay():
				for p: BattleUnit in living(party):
					var tw := create_tween()
					tw.tween_property(p, "position", p.position + Vector2(140, 0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					p.afterimage(Pal.SKY, 0.3)
				await wait(0.6)
				Game.set_pflag("escaped")
				return {"outcome": "escaped", "title": o.get("win_title", "GOT AWAY"), "note": o.get("note", "")}
			for p: BattleUnit in living(party):
				var tw := create_tween()
				tw.tween_property(p, "position", p.home + Vector2(20, 0), 0.2)
				tw.tween_property(p, "position", p.home, 0.2)
			await wait(0.4)
			for p: BattleUnit in living(party):
				p.set_pose("idle")
			await msg(o.get("fail_text", "They cut you off!"), 0.8)
		_:
			set_meta("used_" + a.id, true)
			if def.has("on_act"):
				var r: Dictionary = await def.on_act.call(self, u, a.id)
				return r
	return {}


func steal(u: BattleUnit, tgt: BattleUnit) -> void:
	## Dash in, a quick hand, a jingle, and away.
	if tgt == null:
		return
	u.set_pose("sneak")
	var stand := tgt.position + Vector2(-u.dir_sign() * 22.0, 2)
	await dash(u, stand, 0.12)
	u.set_pose("reach")
	await wait(0.12)
	var item: String = tgt.data.get("steal", "")
	var chance := 0.45 + Game.v("finesse") * 0.06
	if item != "" and not tgt.has_meta("robbed") and randf() < chance:
		tgt.set_meta("robbed", true)
		Sfx.play("steal", 1.0, -4.0)
		fx.burst(tgt.center(), 14, [Pal.BRASS, Pal.LEMON, Pal.WHITE], Vector2(20, 70), Vector2(0.3, 0.6), {"up": 40.0, "acc": Vector2(0, 120), "shape": 1})
		var nm := ""
		if Data.SUPPLIES.has(item):
			Game.add_supply(item, 1)
			nm = Data.SUPPLIES[item].name
		else:
			Game.give_item(item)
			nm = Data.item(item).name
			loot.append(nm)
		popup("GOT IT", tgt.head() + Vector2(0, -8), Pal.BRASS.lerp(Pal.WHITE, 0.3))
		Game.record("steals")
		Achievements.check()
		await msg("Rook lifts %s!" % nm, 0.5)
		tgt.set_mood("shock")
		tgt.squash(1.1, 0.9)
	else:
		Sfx.play("miss", 1.0, -6.0)
		tgt.set_mood("angry")
		popup("NOTHING", tgt.head() + Vector2(0, -8), Pal.TEXT_DIM)
		await msg("Nothing worth taking." if item == "" or tgt.has_meta("robbed") else "%s catches his wrist!" % tgt.uname, 0.5)
	await hop_home(u)


func _talk(u: BattleUnit) -> Dictionary:
	var opts: Array = def.get("talk", [])
	var avail := opts.filter(func(o: Dictionary) -> bool: return not has_meta("said_" + o.id) and (not o.has("need") or o.need.call()))
	if avail.is_empty():
		await msg("There's nothing left to say.", 0.8)
		return {}
	var texts := avail.map(func(o: Dictionary) -> String: return o.text)
	texts.append("(Say nothing.)")
	var r := await ask("What do you say?", texts)
	if r >= avail.size():
		return {}
	var o: Dictionary = avail[r]
	set_meta("said_" + o.id, true)
	u.set_pose("point" if o.get("good", false) else "shrug", 1.0)
	await say(u.id, o.text, "")
	for line in o.get("reply", []):
		await say(line[0], line[1], line[2] if line.size() > 2 else "")
	if o.get("good", false):
		meter += int(o.get("worth", 1))
		Sfx.play("buff", 1.0, -6.0)
		fx.ring(unit(def.get("objective", {}).get("who", "")).center() if unit(def.get("objective", {}).get("who", "")) else Vector2(80, 100), 4, 24, 0.4, Pal.GLOW, 1.0, 1.0)
	else:
		meter = maxi(0, meter - 1)
		Sfx.play("debuff", 1.0, -6.0)
	_refresh_objective()
	if o.has("fn"):
		var rr: Dictionary = await o.fn.call(self)
		if not rr.is_empty():
			return rr
	return _check_end()


# ------------------------------------------------------------- enemies --

func _choose_intent(e: BattleUnit) -> void:
	var moves: Array = e.data.get("moves", [{"name": "Attack", "power": 1.0}])
	var total := 0.0
	for m in moves:
		total += float(m.get("weight", 1.0))
	var r := randf() * total
	var mv: Dictionary = moves[0]
	for m in moves:
		r -= float(m.get("weight", 1.0))
		if r <= 0.0:
			mv = m
			break
	if e.data.has("pattern"):
		mv = moves[(turn - 1) % moves.size()]
	var intent := mv.duplicate()
	intent.tgt = _enemy_target(e, mv)
	intent.telegraph = mv.get("kind", "") == "claim"
	e.intent = intent


func _enemy_target(e: BattleUnit, mv: Dictionary) -> BattleUnit:
	if mv.get("target", "one") == "self":
		return e
	var list := living(party)
	if list.is_empty():
		return null
	var rook := _rook()
	if (mv.get("target", "") == "bearer" or e.data.get("focus", "") == "bearer" and randf() < 0.6) and rook != null and rook.alive and Game.flag("has_sword"):
		return rook
	for p: BattleUnit in list:
		if p.has("marked") and randf() < 0.7:
			return p
	if def.get("objective", {}).get("kind", "") == "protect" and randf() < 0.45:
		var prot := list.filter(func(p: BattleUnit) -> bool: return p.ai)
		if not prot.is_empty():
			return prot[randi() % prot.size()]
	return list[randi() % list.size()]


func _enemy_act(e: BattleUnit) -> Dictionary:
	if e.down:
		return {}
	var mv := e.intent if not e.intent.is_empty() else {"name": "Attack", "power": 1.0}
	e.intent = {}
	var tgt: BattleUnit = mv.get("tgt", null)
	if tgt == null or not is_instance_valid(tgt) or not tgt.alive or tgt.hp <= 0:
		tgt = _enemy_target(e, mv)
	if tgt == null:
		return {}
	await banner(mv.get("name", "Attack"), 0.45, "red_box")
	if mv.has("text"):
		await msg("%s %s" % [e.uname, mv.text], 0.6)
	match mv.get("kind", "hit"):
		"buff":
			e.set_pose("cast" if e.spec.get("kind", "human") == "human" else "ready", 0.6)
			if mv.get("fx", "") == "howl":
				Sfx.play("howl", 1.2, -6.0)
				fx.ring(e.head(), 4, 30, 0.6, Pal.CREAM, 1.0, 0.6)
			apply_status(e, mv.get("status", "guarding"), 2)
			await wait(0.5)
		"debuff":
			e.set_pose("cast" if e.spec.get("kind", "human") == "human" else "ready", 0.6)
			fx.line(e.head(), tgt.head(), 0.5, Pal.CANDLE, 1.0)
			await wait(0.3)
			apply_status(tgt, mv.get("status", "weak"), 3)
			await wait(0.4)
		"seal":
			e.set_pose("cast", 0.8)
			fx.rune(tgt.center(), 20, 1.0, Pal.BRASS)
			await wait(0.4)
			Sfx.play("seal", 0.8, -2.0)
			screen_shake(2.0, 0.3)
			apply_status(tgt, "sealed", 2)
			await msg("The blade falls silent. SWORD is sealed.", 0.8)
		"drain":
			await seal_strike(e, tgt, float(mv.get("power", 1.0)))
			var took := mini(tgt.tp, 4)
			tgt.tp -= took
			if took > 0:
				popup("-%d TP" % took, tgt.center(), Pal.SKY)
			_refresh_status()
		"claim":
			var k := 1.0 + Game.v("suspicion") * 0.08 + Game.v("reliance") * 0.04
			e.set_pose("reach" if e.spec.get("kind", "human") == "human" else "strike")
			await set_tint(Pal.BRASS, 0.18, 0.2)
			for i in 12:
				var p0 := tgt.center() + Vector2(randf_range(-10, 10), randf_range(-12, 12))
				fx.particle(p0, (e.center() - p0) * 1.8, 0.5, Pal.OMEN, {"size": 1.0, "delay": i * 0.03})
			await wait(0.4)
			await seal_strike(e, tgt, float(mv.get("power", 1.4)) * k)
			await set_tint(Pal.BRASS, 0.0, 0.3)
		"multi":
			await melee(e, tgt, float(mv.get("power", 0.7)), int(mv.get("hits", 2)))
		_:
			if e.data.get("style", "melee") in ["bow", "sling"] or mv.get("fx", "") == "arrow":
				await shoot(e, tgt, float(mv.get("power", 1.0)), "arrow" if e.data.get("style", "") == "bow" else "stone")
			elif e.data.get("style", "") == "magic":
				await seal_strike(e, tgt, float(mv.get("power", 1.0)))
			else:
				await melee(e, tgt, float(mv.get("power", 1.0)), 1, {"fx": mv.get("fx", "slash")})
			if mv.has("status") and tgt.alive and tgt.hp > 0 and randf() < float(mv.get("chance", 1.0)):
				apply_status(tgt, mv.status, 2)
	if has_meta("pending"):
		var r: Dictionary = get_meta("pending")
		remove_meta("pending")
		return r
	return {}


func _ally_auto(u: BattleUnit) -> Dictionary:
	## Crew members the player doesn't steer (the ones being protected) still fight.
	var tgt := _first(enemies)
	if tgt == null:
		return {}
	if u.hp < u.max_hp / 3 and randf() < 0.5:
		await msg("%s ducks behind cover." % u.uname, 0.0)
		u.status["guarding"] = 1
		u.set_pose("guard")
		await wait(0.5)
		return {}
	await banner(_attack_name(u), 0.4)
	await attack(u, tgt, 0.8)
	if has_meta("pending"):
		var r: Dictionary = get_meta("pending")
		remove_meta("pending")
		return r
	return {}


# ------------------------------------------------------ cutscene helpers --

func hide_ui() -> void:
	await create_tween().tween_property(ui_root, "modulate:a", 0.0, 0.2).finished


func show_ui() -> void:
	await create_tween().tween_property(ui_root, "modulate:a", 1.0, 0.2).finished


func say(who: String, text, mood: String = "", extra: Dictionary = {}) -> void:
	await Game.main.story.say(who, text, mood, extra)


func ask(question: String, options: Array, who: String = "") -> int:
	return await Game.main.story.choose(question, options, who)


func move(id: String, to: Vector2, t_: float = 0.4) -> void:
	var u := unit(id)
	if u == null:
		return
	await create_tween().tween_property(u, "position", to, t_).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished


func pose(id: String, p: String, hold: float = 0.0) -> void:
	var u := unit(id)
	if u:
		u.set_pose(p, hold)


func mood(id: String, m: String) -> void:
	var u := unit(id)
	if u:
		u.set_mood(m)


func hop(id: String, h: float = 10.0) -> void:
	var u := unit(id)
	if u == null:
		return
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: u.set_lift(v), 0.0, h, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: u.set_lift(v), h, 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	u.squash(1.15, 0.88)


func emote(id: String, kind: String) -> void:
	var u := unit(id)
	if u == null:
		return
	var b := Sprite2D.new()
	b.texture = Art.ui("emote_" + kind)
	b.position = (u.head() + Vector2(12, -4)).round()
	b.z_index = 45
	b.scale = Vector2(0.2, 0.2)
	add_child(b)
	Sfx.play("pop", 1.0 + randf() * 0.2, -12.0)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(b, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(1.2)
	tw.tween_property(b, "modulate:a", 0.0, 0.2)
	tw.tween_callback(b.queue_free)


func remove(id: String, how: String = "fade") -> void:
	var u := unit(id)
	if u == null:
		return
	u.alive = false
	u.hp = 0
	match how:
		"run":
			u.set_pose("run" if u.spec.get("kind", "human") == "human" else "walk")
			var tw := create_tween()
			tw.tween_property(u, "position", u.position + Vector2(-220 if u.side == "enemy" else 220, 0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await tw.finished
		_:
			await create_tween().tween_property(u, "modulate:a", 0.0, 0.4).finished
	u.visible = false


func add_unit(side: String, d: Dictionary, pos: Vector2, enter_from: float = 0.0) -> BattleUnit:
	## Someone joins the fight mid-battle (running in from the edge).
	var u := BattleUnit.new()
	u.setup(side, d, pos)
	units_node.add_child(u)
	if side == "party":
		party.append(u)
	else:
		enemies.append(u)
	if enter_from != 0.0:
		u.position = pos + Vector2(enter_from, 0)
		u.set_pose("run")
		var tw := create_tween()
		tw.tween_property(u, "position", pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw.finished
		u.set_pose("idle")
		u.squash(1.2, 0.85)
	return u


# --------------------------------------------------------------- results --

func _finish(r: Dictionary) -> Dictionary:
	phase = "results"
	_stops = 0
	_slows = 0
	cursor.visible = false
	for m in _marks.values():
		(m as Node).queue_free()
	_marks.clear()
	Engine.time_scale = 1.0
	await set_tint(Pal.OMEN, 0.0, 0.01)
	var outcome: String = r.get("outcome", "victory")
	await hide_ui()
	# a last beat on the battlefield before the results
	match outcome:
		"victory", "objective":
			Sfx.music("victory", 0.3)
			for p: BattleUnit in living(party):
				p.set_pose("victory")
				p.set_mood("grin" if p.id == "rook" else "smile")
				p.squash(0.85, 1.2)
				fx.burst(p.head(), 8, [Pal.LEMON, Pal.WHITE, Pal.CANDLE], Vector2(20, 60), Vector2(0.4, 0.8), {"up": 40.0, "shape": 1})
			await wait(0.9)
		"defeat":
			Sfx.music("defeat", 0.5)
			Game.set_pflag("fail_forward")
			await set_tint(Pal.BLOOD.lerp(Pal.INK, 0.5), 0.35, 0.6)
			await wait(0.6)
		"escaped":
			await wait(0.3)
	if stats.taken == 0 and outcome in ["victory", "objective"]:
		Game.set_pflag("untouchable")
	for e: BattleUnit in enemies:
		if not e.alive and not e.data.get("nonlethal", false) and e.data.get("ko", "down") == "down" and e.spec.get("kind", "human") == "human":
			killed.append(e.id)
	var summary := {
		"outcome": outcome, "title": r.get("title", "VICTORY"), "note": r.get("note", ""),
		"turns": stats.turns, "dealt": stats.dealt, "taken": stats.taken,
		"changes": changes + r.get("changes", []), "loot": loot + r.get("loot", []), "casualties": casualties, "spared": spared,
		"killed": killed, "id": def.get("id", ""), "meter": meter,
	}
	for k in r:
		if not summary.has(k):
			summary[k] = r[k]
	var res := BattleResults.new()
	res.setup(summary)
	res.z_index = 60
	add_child(res)
	await res.run()
	return summary
