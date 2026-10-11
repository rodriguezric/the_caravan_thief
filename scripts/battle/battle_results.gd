class_name BattleResults
extends Control
## The one results screen every battle ends on, however it ended: won, talked
## down, escaped or lost. Numbers count up with ticks; below them, what the
## fight changed (Suspicion gained, friends struck, crew lost, things taken).

var s: Dictionary
var panel: NinePatchRect
var rows: Array = []


func setup(summary: Dictionary) -> void:
	s = summary


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var kind := "gold_box"
	match s.outcome:
		"defeat":
			kind = "red_box"
		"escaped":
			kind = "box"
		"objective":
			kind = "glow_box"
	var note_lines: Array = Art.wrap(str(s.note), 220) if str(s.note) != "" else []
	var extra := []
	for c in s.get("changes", []):
		extra.append([str(c), Pal.OMEN.lerp(Pal.WHITE, 0.35)])
	for l in s.get("loot", []):
		extra.append(["Got: " + str(l), Pal.GLOW])
	for c in s.get("casualties", []):
		extra.append([Data.spec(c).get("name", c) + " fell.", Pal.BLOOD.lerp(Pal.WHITE, 0.3)])
	for c in s.get("spared", []):
		extra.append([str(c) + " was spared.", Pal.SKY.lerp(Pal.WHITE, 0.3)])
	var stat_rows := [["Turns", s.turns], ["Damage dealt", s.dealt], ["Damage taken", s.taken]]
	var h := 40 + stat_rows.size() * 10 + note_lines.size() * 10 + (6 if note_lines.size() > 0 else 0) + mini(extra.size(), 6) * 10 + 16
	panel = Art.make_box(kind)
	panel.size = Vector2(236, h)
	panel.position = Vector2(42, maxf(4.0, 90 - h / 2.0))
	add_child(panel)
	var title_c := Pal.LEMON if s.outcome != "defeat" else Pal.BLOOD.lerp(Pal.WHITE, 0.35)
	var title := Art.shadow_label(str(s.title), title_c, 2)
	var tw_ := Art.text_width(str(s.title), 2)
	if tw_ > 224:
		title = Art.shadow_label(str(s.title), title_c, 1)
		tw_ = Art.text_width(str(s.title))
	title.position = Vector2(118 - tw_ / 2.0, 6)
	panel.add_child(title)
	var sub: String = {"victory": "BATTLE WON", "defeat": "BEATEN (BUT NOT FINISHED)", "escaped": "GOT AWAY", "objective": "OBJECTIVE MET"}.get(s.outcome, "BATTLE OVER")
	var sl := Art.label(sub, Pal.TEXT_DIM)
	sl.position = Vector2(118 - Art.text_width(sub) / 2.0, 27)
	panel.add_child(sl)
	var y := 40.0
	for r in stat_rows:
		var l := Art.label(r[0], Pal.TEXT)
		l.position = Vector2(12, y)
		panel.add_child(l)
		var v := Art.label("0", Pal.TEXT)
		v.position = Vector2(196, y)
		v.size = Vector2(28, 10)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.modulate.a = 0.0
		l.modulate.a = 0.0
		panel.add_child(v)
		rows.append([l, v, int(r[1])])
		y += 10
	if note_lines.size() > 0:
		y += 4
		for ln in note_lines:
			var nl := Art.label(ln, Pal.CREAM)
			nl.position = Vector2(12, y)
			panel.add_child(nl)
			y += 10
	for e in extra.slice(0, 6):
		var il := Art.label(e[0], e[1])
		il.position = Vector2(12, y)
		il.size = Vector2(212, 10)
		il.clip_text = true
		panel.add_child(il)
		y += 10
	var keys := Art.label("Z continue", Pal.TEXT_DIM)
	keys.name = "keys"
	keys.position = Vector2(224 - Art.text_width("Z continue"), h - 14)
	keys.visible = false
	panel.add_child(keys)


func _enter_tree() -> void:
	Game.main.hold_toasts = true


func _exit_tree() -> void:
	Game.main.hold_toasts = false


func run() -> void:
	if s.outcome in ["victory", "objective"]:
		Sfx.play("fanfare", 1.0, -6.0)
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(1, 0.2)
	await create_tween().tween_property(panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).finished
	var skip := false
	for r in rows:
		var l: Label = r[0]
		var v: Label = r[1]
		var target: int = r[2]
		l.modulate.a = 1.0
		v.modulate.a = 1.0
		if skip or Game.reduced_motion():
			v.text = str(target)
			continue
		var e := 0.0
		while e < 0.35:
			await get_tree().process_frame
			e += get_process_delta_time()
			var shown := int(target * minf(1.0, e / 0.35))
			if v.text != str(shown):
				v.text = str(shown)
				Sfx.play("tick", 1.0 + randf() * 0.2, -14.0)
			if Input.is_action_just_pressed("accept"):
				skip = true
				break
		v.text = str(target)
		v.scale = Vector2(1.6, 1.6)
		v.pivot_offset = Vector2(28, 5)
		create_tween().tween_property(v, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	Sfx.play("score", 1.0, -8.0)
	(panel.get_node("keys") as Label).visible = true
	await get_tree().process_frame
	var waited := 0.0
	while not Input.is_action_just_pressed("accept"):
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Game.autoplay() and waited > 0.5:
			print("[auto] battle %s: %s (%s)" % [s.id, s.outcome, s.title])
			break
	Sfx.play("confirm")
