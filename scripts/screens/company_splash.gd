class_name CompanySplash
extends Control
## The studio card shown once at launch, before the opening: the company name
## in the middle of an inky, vignetted screen. The letters surface one by one
## over a low hum (the style's title rule: fade, never drop), a candle-coloured
## rule draws out beneath them, a few embers rise, and it all fades away.
## Skippable with any confirm/cancel; skipping and finishing end the same way.

const NAME := "BAYERIAN"
const SCALE := 3
const STAGGER := 0.12
const HOLD := 1.3

var t := 0.0
var letters: Array = []
var rule := 0.0
var drawer: Node2D
var done := false
var fading := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.cine("ink", 0)
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_fx)
	add_child(drawer)
	var gap := SCALE * 2
	var total := 0.0
	for ch in NAME:
		total += Art.text_width(ch, SCALE) + gap
	total -= gap
	var x := 160.0 - total / 2.0
	for ch in NAME:
		var l := Art.shadow_label(ch, Pal.TEXT.lerp(Pal.CANDLE, 0.3), SCALE)
		l.position = Vector2(x, 90 - PixFont.SIZE * SCALE / 2.0 - 2).round()
		l.modulate.a = 0.0
		add_child(l)
		letters.append(l)
		x += Art.text_width(ch, SCALE) + gap


func _process(delta: float) -> void:
	t += delta
	drawer.queue_redraw()


func _draw_fx() -> void:
	# a thin candle-coloured rule growing outward under the name
	var half := 64.0 * rule
	if half >= 1.0:
		drawer.draw_rect(Rect2(Vector2(160 - half, 104).round(), Vector2(half * 2, 1)), Color(Pal.CANDLE, 0.85))
		drawer.draw_rect(Rect2(Vector2(160 - half * 0.5, 105).round(), Vector2(half, 1)), Color(Pal.CANDLE, 0.3))
	# embers drifting up, very slowly
	for i in 18:
		var p := Vector2(60 + Pal.hash2(i, 3) * 200, fmod(170.0 - t * (6.0 + Pal.hash2(i, 4) * 8.0) + Pal.hash2(i, 5) * 160.0, 160.0) + 10)
		var a := 0.35 + 0.35 * sin(t * 2.0 + i)
		drawer.draw_rect(Rect2(p.round(), Vector2.ONE), Color(Pal.CANDLE if i % 3 else Pal.WHITE, a * minf(1.0, t)))


func run() -> void:
	## Plays the card; returns once it has faded out (or been skipped).
	Sfx.play("hum", 1.0, -6.0)
	var reduced := Game.reduced_motion()
	for i in letters.size():
		var tw := create_tween()
		tw.tween_interval(0.0 if reduced else 0.3 + STAGGER * i)
		tw.tween_property(letters[i], "modulate:a", 1.0, 0.25 if reduced else 0.7).set_trans(Tween.TRANS_SINE)
	var rt := create_tween()
	rt.tween_interval(0.0 if reduced else 0.3 + STAGGER * letters.size())
	rt.tween_method(func(v: float) -> void: rule = v, 0.0, 1.0, 0.2 if reduced else 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var length := 0.3 + STAGGER * letters.size() + 0.7 + HOLD
	var e := 0.0
	await get_tree().process_frame
	while e < length:
		await get_tree().process_frame
		e += get_process_delta_time()
		if Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("cancel"):
			break
	await _finish()


func _finish() -> void:
	if done:
		return
	done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	await tw.finished
