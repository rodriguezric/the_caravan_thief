class_name MgLoot
extends Minigame
## The limited-time looting choice: the guard's back is turned for a few
## seconds. Move over the goods, grab what you can carry (weight), and run
## when the candle burns down. Heavy, fine things are worth more and are
## harder to explain later (evidence).
## opts: items (ids), capacity, time.

var items: Array = []
var taken: Array = []
var sel := 0
var capacity := 4
var time_left := 10.0
var time_max := 10.0
var done := false
var fx: Fx
var nudge := 0.0


func configure() -> void:
	title_text = opts.get("title", "GRAB WHAT YOU CAN")
	help_text = opts.get("help", "The guard's back is turned. Arrows move, Z grabs or puts back, X runs. Mind the weight: you can only carry so much, and some things are easier to explain than others.")
	keys_text = "Z grab  X go"
	bg_name = "wagon_inside"
	song = "heist"
	items = opts.get("items", ["purse", "saffron", "silk", "icon"])
	capacity = int(opts.get("capacity", 4))
	time_max = float(opts.get("time", 10.0))
	time_left = time_max


func setup_game() -> void:
	fx = Fx.new()
	fx.z_index = 20
	add_child(fx)


func _weight() -> int:
	var w := 0
	for id in taken:
		w += int(Data.item(id).weight)
	return w


func _game() -> Dictionary:
	while not done:
		var dt: float = await frame()
		time_left -= dt
		nudge = maxf(0.0, nudge - dt * 4.0)
		if pressed("right") or pressed("down"):
			sel = (sel + 1) % items.size()
			Sfx.play("blip")
		elif pressed("left") or pressed("up"):
			sel = (sel - 1 + items.size()) % items.size()
			Sfx.play("blip")
		elif pressed("accept"):
			var id: String = items[sel]
			if taken.has(id):
				taken.erase(id)
				Sfx.play("cancel")
			elif _weight() + int(Data.item(id).weight) <= capacity:
				taken.append(id)
				Sfx.play("coin")
				fx.burst(_slot(sel), 10, [Pal.BRASS, Pal.LEMON], Vector2(20, 50), Vector2(0.2, 0.5), {"up": 30.0, "shape": 1})
			else:
				Sfx.play("miss")
				nudge = 1.0
		elif pressed("cancel"):
			done = true
		if time_left <= 0.0:
			done = true
			Sfx.play("alert", 1.0, -4.0)
	var full := _weight() == capacity
	if full:
		Game.set_pflag("loot_full")
	return {"score": mini(100, _weight() * 100 / maxi(1, capacity)), "raw": _weight(), "perfect": full, "success": true, "taken": taken.duplicate(),
		"detail": "%d things, %d weight" % [taken.size(), _weight()], "banner": "AWAY!" if time_left > 0.0 else "TIME!"}


func auto_result(win: bool) -> Dictionary:
	var t := []
	var w := 0
	for id in items:
		if w + int(Data.item(id).weight) <= capacity:
			t.append(id)
			w += int(Data.item(id).weight)
	return {"score": 100, "raw": w, "perfect": w == capacity, "success": true, "taken": t if win else []}


func _slot(i: int) -> Vector2:
	var cols := mini(items.size(), 4)
	return Vector2(160 - (cols - 1) * 34 + (i % cols) * 68, 70 + (i / cols) * 52)


func _draw_game(d: Node2D) -> void:
	# the candle burning down: the time left
	var k := clampf(time_left / time_max, 0.0, 1.0)
	d.draw_rect(Rect2(Vector2(10, 20), Vector2(8, 120)), Pal.INK)
	d.draw_rect(Rect2(Vector2(11, 21 + 118 * (1.0 - k)), Vector2(6, 118 * k)), Pal.CANVAS)
	var fl := Vector2(14, 16 + 118 * (1.0 - k)) + Vector2(sin(t * 20.0), 0)
	d.draw_circle(fl, 3.0, Pal.CANDLE)
	d.draw_circle(fl + Vector2(0, -2), 1.5, Pal.LEMON)
	for i in items.size():
		var p := _slot(i)
		var id: String = items[i]
		var it := Data.item(id)
		var r := Rect2(p - Vector2(30, 22), Vector2(60, 44))
		d.draw_rect(r, Pal.INK)
		d.draw_rect(r.grow(-1), Pal.PANEL.lerp(Pal.WOOD, 0.3) if not taken.has(id) else Pal.PANEL.lerp(Pal.GLOW, 0.2))
		_draw_item(d, id, p + Vector2(0, -6))
		var nm := Art.font
		d.draw_string(nm, p + Vector2(-27, 18), str(it.name), HORIZONTAL_ALIGNMENT_LEFT, 56, PixFont.SIZE, Pal.TEXT if not taken.has(id) else Pal.GLOW)
		for w in int(it.weight):
			d.draw_rect(Rect2(p + Vector2(18 - w * 5, -19), Vector2(4, 4)), Pal.BRASS)
		if i == sel:
			var b := 1.0 if fmod(t, 0.5) < 0.25 else 0.0
			d.draw_rect(r.grow(2 + b), Pal.CANDLE, false, 1.0)
	# the bag
	var bx := Vector2(280, 150) + Vector2(randf_range(-2, 2) * nudge, 0)
	d.draw_circle(bx, 14.0, Pal.CANVAS.lerp(Pal.DUST, 0.3))
	d.draw_rect(Rect2(bx + Vector2(-5, -18), Vector2(10, 5)), Pal.LEATHER)
	bar(d, Vector2(250, 168), 60, 6, float(_weight()) / capacity, Pal.BRASS if _weight() < capacity else Pal.GLOW)
	var sel_it := Data.item(items[sel])
	d.draw_string(Art.font, Vector2(30, 172), str(sel_it.desc), HORIZONTAL_ALIGNMENT_LEFT, 210, PixFont.SIZE, Pal.CREAM)


func _draw_item(d: Node2D, id: String, p: Vector2) -> void:
	match id:
		"purse":
			d.draw_circle(p, 7.0, Pal.LEATHER)
			d.draw_rect(Rect2(p + Vector2(-3, -9), Vector2(6, 3)), Pal.BRASS)
		"seal_ring":
			d.draw_arc(p, 5.0, 0, TAU, 16, Pal.STEEL, 2.0)
			d.draw_rect(Rect2(p + Vector2(-2, -8), Vector2(4, 4)), Pal.STEEL.lerp(Pal.WHITE, 0.3))
		"saffron":
			d.draw_rect(Rect2(p - Vector2(9, 6), Vector2(18, 12)), Pal.RED.lerp(Pal.ROSE, 0.3))
			d.draw_rect(Rect2(p - Vector2(9, 6), Vector2(18, 2)), Pal.BRASS)
		"silk":
			d.draw_rect(Rect2(p - Vector2(12, 5), Vector2(24, 10)), Pal.PURPLE.lerp(Pal.OMEN, 0.3))
			d.draw_rect(Rect2(p - Vector2(12, 5), Vector2(4, 10)), Pal.PURPLE)
		"icon":
			d.draw_rect(Rect2(p - Vector2(5, 8), Vector2(10, 16)), Pal.WOOD)
			d.draw_circle(p + Vector2(0, -3), 3.0, Pal.LEMON)
		"payroll":
			d.draw_rect(Rect2(p - Vector2(10, 7), Vector2(20, 14)), Pal.SLATE)
			d.draw_rect(Rect2(p - Vector2(2, 3), Vector2(4, 4)), Pal.BRASS)
		_:
			d.draw_circle(p, 6.0, Pal.CANVAS)
