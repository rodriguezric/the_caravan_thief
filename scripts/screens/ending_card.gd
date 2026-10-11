class_name EndingCard
extends Control
## The ending card: the ending's name in big letters, then the legacy record
## the anthology keeps (what became of Rook, of his closest bond, and of the
## blade), and how many endings have been found. Always returns to the title.

var key := ""
var fresh := false
var info := {}
var t := 0.0
var drawer: Node2D
var parts: Array = []


func setup(p_key: String, p_fresh: bool, p_info: Dictionary) -> void:
	key = p_key
	fresh = p_fresh
	info = p_info


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.cine("ink", 0)
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_fx)
	add_child(drawer)
	var e := Data.ending(key)
	var lines := Art.wrap(str(e[1]).to_upper(), 150)
	var y := 18.0
	for ln in lines:
		var big := Art.shadow_label(ln, Pal.CANDLE.lerp(Pal.LEMON, 0.35), 2)
		big.position = Vector2(160 - Art.text_width(ln, 2) / 2.0, y)
		big.modulate.a = 0.0
		add_child(big)
		parts.append(big)
		y += 22
	y += 6
	var rows := [["Rook", info.get("bearer", "")], ["Closest bond", info.get("bond", "")], ["The blade", info.get("sword", e[3])]]
	for r in rows:
		var hl := Art.label(r[0], Pal.TEXT_DIM)
		hl.position = Vector2(24, y)
		hl.modulate.a = 0.0
		add_child(hl)
		parts.append(hl)
		var wrapped := Art.wrap(str(r[1]), 200)
		for w in wrapped:
			var vl := Art.label(w, Pal.OMEN.lerp(Pal.WHITE, 0.4) if r[0] == "The blade" else Pal.CREAM)
			vl.position = Vector2(96, y)
			vl.modulate.a = 0.0
			add_child(vl)
			parts.append(vl)
			y += 10
		y += 2
	y += 4
	if fresh:
		var nw := Art.label("NEW ENDING", Pal.GLOW)
		nw.position = Vector2(160 - Art.text_width("NEW ENDING") / 2.0, y)
		nw.modulate.a = 0.0
		add_child(nw)
		parts.append(nw)
	for k in Data.ENDINGS.size():
		var pip := TextureRect.new()
		pip.texture = Art.ui("pip_on" if Game.has_ending(Data.ENDINGS[k][0]) else "pip_off")
		pip.position = Vector2(160 - Data.ENDINGS.size() * 5 + k * 10, y + 12)
		add_child(pip)
	var found := Art.label("%d / %d endings found" % [Game.endings_found(), Data.ENDINGS.size()], Pal.TEXT_DIM)
	found.position = Vector2(160 - Art.text_width(found.text) / 2.0, y + 22)
	add_child(found)
	var keys := Art.label("Z  return to title", Pal.TEXT_DIM)
	keys.position = Vector2(314 - Art.text_width(keys.text), 168)
	add_child(keys)


func _process(delta: float) -> void:
	t += delta
	drawer.queue_redraw()


func _draw_fx() -> void:
	# violet motes drifting up, as from the blade, wherever it went
	for i in 40:
		var p := Vector2(Pal.hash2(i, 3) * 320, fmod(180.0 - t * (6.0 + Pal.hash2(i, 4) * 12.0) + Pal.hash2(i, 5) * 180.0, 180.0)).round()
		drawer.draw_rect(Rect2(p, Vector2.ONE), Color(Pal.OMEN if i % 3 else Pal.CANDLE, 0.55))


func run() -> void:
	Sfx.music("ending", 1.0)
	Sfx.play("bell", 0.8, -8.0)
	for i in parts.size():
		create_tween().tween_property(parts[i], "modulate:a", 1.0, 0.6).set_delay(i * 0.12)
	await get_tree().create_timer(0.8).timeout
	if fresh:
		Sfx.play("fanfare", 1.0, -8.0)
	var waited := 0.0
	while not Input.is_action_just_pressed("accept") and not Input.is_action_just_pressed("cancel"):
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Game.autoplay() and waited > 1.0:
			break
	Sfx.play("confirm")
