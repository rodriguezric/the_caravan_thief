class_name MgLockpick
extends Minigame
## Lockpicking: a cross-section of the lock, its pins bouncing on their
## springs. Press Z the instant a pin lifts into the shear line and it sets
## with a click. Mistime it and the pick slips (three slips and it snaps).
## opts: pins (3-6), speed (1.0 normal), title, help.

var pins := 4
var set_pins: Array = []
var cur := 0
var slips := 0
var max_slips := 3
var ph := 0.0
var speed := 1.0
var shake_t := 0.0
var flash_t := 0.0
var pin_jump := 0.0
var fx: Fx
var done := false

const LX := 70.0
const LY := 44.0
const LW := 180.0
const SHEAR := 76.0


func configure() -> void:
	title_text = opts.get("title", "PICK THE LOCK")
	help_text = opts.get("help", "Each pin bounces on its spring. Press Z when the pin's top crosses the gold line. Slip three times and the pick snaps.")
	keys_text = "Z set pin"
	bg_name = "wagon_inside"
	song = "heist"
	pins = clampi(int(opts.get("pins", 4)), 3, 6)
	speed = float(opts.get("speed", 1.0))


func setup_game() -> void:
	for i in pins:
		set_pins.append(false)
	fx = Fx.new()
	fx.z_index = 20
	add_child(fx)


func _pin_x(i: int) -> float:
	return LX + 26.0 + i * (LW - 40.0) / maxf(1.0, pins - 1)


func _pin_lift(i: int) -> float:
	## How far the current pin is pushed up (0 rest .. 1 top).
	var f := 1.7 * speed * (1.0 + i * 0.18)
	return 0.5 + 0.5 * sin(ph * f + i * 1.3)


func _game() -> Dictionary:
	while not done:
		var dt: float = await frame()
		ph += dt * 3.0
		shake_t = maxf(0.0, shake_t - dt)
		flash_t = maxf(0.0, flash_t - dt)
		pin_jump = maxf(0.0, pin_jump - dt * 6.0)
		if pressed("accept"):
			var top := _pin_top(cur)
			if absf(top - SHEAR) <= 4.5:
				set_pins[cur] = true
				Sfx.play("lockpin", 1.0 + cur * 0.08, -2.0)
				fx.burst(Vector2(_pin_x(cur), SHEAR), 10, [Pal.LEMON, Pal.WHITE, Pal.BRASS], Vector2(20, 60), Vector2(0.2, 0.4), {"shape": 1})
				flash_t = 0.12
				pin_jump = 1.0
				cur += 1
				Game.buzz(15)
				if cur >= pins:
					done = true
			else:
				slips += 1
				shake_t = 0.3
				Sfx.play("lock_fail", 1.0, -2.0)
				Game.buzz(40)
				fx.burst(Vector2(_pin_x(cur), 120), 8, [Pal.STEEL, Pal.WHITE], Vector2(30, 70), Vector2(0.2, 0.4))
				# a slip knocks the last set pin back down
				if cur > 0 and slips < max_slips:
					cur -= 1
					set_pins[cur] = false
				if slips >= max_slips:
					done = true
	await get_tree().create_timer(0.3).timeout
	if cur >= pins:
		Sfx.play("lock_open", 1.0, -2.0)
		await get_tree().create_timer(0.5).timeout
	var ok := cur >= pins
	if ok and slips == 0:
		Game.set_pflag("lock_perfect")
	Game.record("locks")
	return {"score": 100 - slips * 30 if ok else 10, "raw": 100 - slips * 30 if ok else 10, "perfect": ok and slips == 0, "success": ok,
		"slips": slips, "detail": "Clean." if ok and slips == 0 else ("Open." if ok else "The pick snapped."), "banner": "CLICK!" if ok else "SNAP!"}


func _pin_top(i: int) -> float:
	if set_pins[i]:
		return SHEAR
	if i != cur:
		return SHEAR + 22.0
	return SHEAR + 22.0 - _pin_lift(i) * 30.0


func auto_result(win: bool) -> Dictionary:
	return {"score": 100 if win else 10, "raw": 100 if win else 10, "perfect": win, "success": win, "slips": 0 if win else 3}


func _draw_game(d: Node2D) -> void:
	var sh := Vector2(randf_range(-2, 2), 0) if shake_t > 0.0 and not Game.reduced_motion() else Vector2.ZERO
	var o := sh
	# the lock body: brass housing, a cut-away showing pin chambers
	var brass := Pal.BRASS.lerp(Pal.INK2, 0.2)
	d.draw_rect(Rect2(Vector2(LX - 8, LY - 10) + o, Vector2(LW + 16, 110)), Pal.shade(brass))
	d.draw_rect(Rect2(Vector2(LX - 6, LY - 8) + o, Vector2(LW + 12, 106)), brass)
	d.draw_rect(Rect2(Vector2(LX - 6, LY - 8) + o, Vector2(LW + 12, 2)), Pal.hi(brass))
	# the plug (cylinder) below the shear line
	d.draw_rect(Rect2(Vector2(LX, SHEAR) + o, Vector2(LW, 52)), Pal.STEEL.lerp(Pal.INK2, 0.35))
	d.draw_rect(Rect2(Vector2(LX, SHEAR + 50) + o, Vector2(LW, 2)), Pal.shade(Pal.STEEL))
	# the gold shear line
	d.draw_rect(Rect2(Vector2(LX, SHEAR - 1) + o, Vector2(LW, 2)), Pal.LEMON if flash_t <= 0.0 else Pal.WHITE)
	for i in pins:
		var x := _pin_x(i)
		var top := _pin_top(i)
		var chamber := Rect2(Vector2(x - 5, LY) + o, Vector2(10, SHEAR + 48 - LY))
		d.draw_rect(chamber, Pal.INK.lerp(Pal.INK2, 0.5))
		# spring above the driver pin
		var spring_bottom := top - 14.0 - (pin_jump * 4.0 if i == cur - 1 else 0.0)
		var y := LY + 2.0
		while y < spring_bottom - 1.0:
			d.draw_line(Vector2(x - 3, y) + o, Vector2(x + 3, y + 2) + o, Pal.STEEL, 1.0)
			y += 3.0
		# driver pin (upper) and key pin (lower)
		var drv := Pal.STEEL if not set_pins[i] else Pal.GLOW.lerp(Pal.STEEL, 0.4)
		d.draw_rect(Rect2(Vector2(x - 4, spring_bottom) + o, Vector2(8, 14)), drv)
		d.draw_rect(Rect2(Vector2(x - 4, spring_bottom) + o, Vector2(8, 1)), Pal.hi(drv))
		d.draw_rect(Rect2(Vector2(x - 4, top) + o, Vector2(8, 16)), Pal.BRASS.lerp(Pal.LEMON, 0.3))
		d.draw_rect(Rect2(Vector2(x - 4, top + 15) + o, Vector2(8, 1)), Pal.shade(Pal.BRASS))
		if i == cur and not done:
			# the pick lifting this pin
			var tip := Vector2(x, top + 18) + o
			d.draw_line(Vector2(LX - 40, SHEAR + 40) + o, tip + Vector2(-6, 4), Pal.STEEL, 2.0)
			d.draw_line(tip + Vector2(-6, 4), tip, Pal.hi(Pal.STEEL), 2.0)
			var near := absf(top - SHEAR) <= 4.5
			if near:
				d.draw_rect(Rect2(Vector2(x - 6, SHEAR - 3) + o, Vector2(12, 6)), Color(Pal.LEMON, 0.35))
	# tension wrench
	d.draw_rect(Rect2(Vector2(LX - 30, SHEAR + 44) + o, Vector2(34, 3)), Pal.SLATE)
	# slips left
	for k in max_slips:
		var c := Pal.BLOOD if k < slips else Pal.INK2
		d.draw_rect(Rect2(Vector2(270 + k * 12, 160), Vector2(8, 8)), Pal.INK)
		d.draw_rect(Rect2(Vector2(271 + k * 12, 161), Vector2(6, 6)), c)
	for i in pins:
		d.draw_rect(Rect2(Vector2(20 + i * 10, 160), Vector2(8, 8)), Pal.INK)
		d.draw_rect(Rect2(Vector2(21 + i * 10, 161), Vector2(6, 6)), Pal.GLOW if set_pins[i] else Pal.INK2)
