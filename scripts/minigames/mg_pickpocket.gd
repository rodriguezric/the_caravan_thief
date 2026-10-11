class_name MgPickpocket
extends Minigame
## Pickpocketing: the mark stands with his back to you, purse on his belt.
## Hold Z to ease your hand in; let go whenever he starts to turn (his
## attention meter climbs into the red). Moving while he's alert is a twitch;
## three twitches and he catches your wrist.
## opts: mark (spec id), item (name shown), skill (0..1, from Finesse).

var reach := 0.0
var att := 0.0
var att_t := 0.0
var twitches := 0
var max_twitch := 3
var done := false
var caught := false
var mark_spec: Dictionary
var glance := 0.0
var shake_t := 0.0
var skill := 0.5
var fx: Fx


func configure() -> void:
	title_text = opts.get("title", "LIGHT FINGERS")
	help_text = opts.get("help", "Hold Z to slide your hand toward the purse. When he starts to turn (the eye fills red), let go and keep still. Three twitches and you're caught.")
	keys_text = "hold Z reach"
	bg_name = opts.get("bg", "saltway")
	song = "heist"
	mark_spec = Data.spec(opts.get("mark", "ollo"))
	skill = clampf(float(opts.get("skill", 0.5)), 0.0, 1.0)


func setup_game() -> void:
	fx = Fx.new()
	fx.z_index = 20
	add_child(fx)


func _game() -> Dictionary:
	while not done:
		var dt: float = await frame()
		att_t += dt
		# his attention wanders up and down, with the odd sudden glance
		att = clampf(0.45 + 0.4 * sin(att_t * (1.3 + att_t * 0.02)) + 0.25 * sin(att_t * 3.7 + 1.0) + glance, 0.0, 1.0)
		glance = maxf(0.0, glance - dt * 0.8)
		if randf() < dt * 0.25:
			glance = 0.5
		shake_t = maxf(0.0, shake_t - dt)
		if held("accept"):
			reach += dt * (0.22 + skill * 0.12)
			if att > 0.72:
				twitches += 1
				shake_t = 0.35
				Sfx.play("alert", 0.8 + twitches * 0.1, -6.0)
				Game.buzz(40)
				glance = 0.0
				att_t += 1.6
				reach = maxf(0.0, reach - 0.2)
				if twitches >= max_twitch:
					caught = true
					done = true
		if reach >= 1.0:
			done = true
			Sfx.play("steal", 1.0, -2.0)
			fx.burst(Vector2(178, 110), 16, [Pal.BRASS, Pal.LEMON, Pal.WHITE], Vector2(20, 70), Vector2(0.3, 0.6), {"up": 40.0, "acc": Vector2(0, 120), "shape": 1})
	await get_tree().create_timer(0.6).timeout
	var ok := not caught
	if ok and twitches == 0:
		Game.set_pflag("pick_perfect")
	Game.record("picks")
	return {"score": 100 - twitches * 30 if ok else 0, "raw": 100 - twitches * 30 if ok else 0, "perfect": ok and twitches == 0, "success": ok,
		"twitches": twitches, "detail": opts.get("item", "The purse") + (" is yours." if ok else " stays put."), "banner": "LIFTED!" if ok else "CAUGHT!"}


func auto_result(win: bool) -> Dictionary:
	return {"score": 100 if win else 0, "raw": 100 if win else 0, "perfect": win, "success": win, "twitches": 0 if win else 3}


func _draw_game(d: Node2D) -> void:
	var o := Vector2(randf_range(-1, 1), 0) if shake_t > 0.0 and not Game.reduced_motion() else Vector2.ZERO
	# the mark, from behind, three times life size; he turns his head as he looks
	var turn_dir := 1 if att > 0.6 else 1
	var tex_ := Art.person(mark_spec, 1 if att < 0.55 else 2, 0, "angry" if shake_t > 0.0 else "", "walk")
	var k := 4.0
	var base := Vector2(160, 160) + o
	tex(tex_, base + Vector2(0, -80), d, att >= 0.55 and turn_dir < 0, k)
	# the purse on his belt
	var purse := Vector2(178, 112) + o
	if not (done and not caught):
		d.draw_circle(purse, 7.0, Pal.LEATHER)
		d.draw_circle(purse + Vector2(-2, -2), 2.0, Pal.hi(Pal.LEATHER))
		d.draw_rect(Rect2(purse + Vector2(-3, -9), Vector2(6, 3)), Pal.BRASS)
	# Rook's hand sliding in from the bottom right
	var from := Vector2(320, 190)
	var hand := from.lerp(purse + Vector2(6, 4), reach)
	d.draw_line(from, hand, Data.CAST.rook.jacket, 9.0)
	d.draw_circle(hand, 5.0, Data.ROOK_SKIN)
	d.draw_rect(Rect2(hand + Vector2(-2, -1), Vector2(2, 1)), Pal.PINK)
	# his attention: an eye that fills, then turns red
	var ec := Vector2(40, 30)
	d.draw_circle(ec, 13.0, Pal.INK)
	d.draw_circle(ec, 11.0, Pal.WHITE.lerp(Pal.BLOOD, clampf((att - 0.4) * 2.0, 0.0, 1.0)))
	d.draw_circle(ec, 4.0 + att * 4.0, Pal.INK)
	bar(d, Vector2(20, 48), 40, 5, att, Pal.LEMON if att < 0.72 else Pal.BLOOD)
	d.draw_rect(Rect2(Vector2(20 + 40 * 0.72, 46), Vector2(1, 9)), Pal.WHITE)
	# reach progress and twitches
	bar(d, Vector2(220, 10), 90, 6, reach, Pal.BRASS)
	for k2 in max_twitch:
		d.draw_rect(Rect2(Vector2(220 + k2 * 12, 20), Vector2(8, 8)), Pal.INK)
		d.draw_rect(Rect2(Vector2(221 + k2 * 12, 21), Vector2(6, 6)), Pal.BLOOD if k2 < twitches else Pal.INK2)
