class_name TouchControls
extends Control
## On-screen controls for phones and tablets, drawn at window resolution by the
## Shell. They press the game's own input actions (accept / cancel / up / down
## / left / right / run), so every screen, battle and minigame works with them
## unchanged.
##
## - Hidden until the first touch; fade out again when a key or gamepad button
##   is used, so desktop players never see them.
## - Wide screens: the controls live in the side bars beside the game.
##   16:9 screens: they overlay the corners, semi-transparent.
## - Default layout: a floating joystick that appears only under your thumb
##   (touch anywhere on the left part of the screen; a small push walks, a
##   big push runs), B = back, a pause button, and tapping the game itself
##   presses OK (talks, advances dialog). There is no A button.
## - The top-right slot holds one button at a time, the same size either way:
##   MENU while walking around (opens the pause menu), B wherever "back"
##   exists (settings, lists, battle targets...), or nothing at all.
## - Minigames pick a layout (Game.touch_layout). Tap, hold and mash games
##   are played by touching anywhere on the screen; left/right games by
##   touching the left or right half. Arrow games follow the "touch_arrows"
##   setting: swipe anywhere (side bars included) in the arrow's direction,
##   four arrow buttons, or both (swipe on the picture, buttons beside it).
##   Up/down keep their buttons. Some add tilt.

const PAD_ART := 37
## The floating joystick: where it can be summoned (share of screen width
## from the left), the dead centre, and how far to push to run.
const JOY_REGION := 0.45
const JOY_DEAD := 0.2
const JOY_RUN := 0.7
## A direction counts once the stick leans this far toward it (diagonals ok).
const JOY_AXIS := 0.38
const SWIPE := 0.06
## Scrolling lists: a finger must travel this far (game pixels) before a
## touch counts as a drag instead of a tap; a flick keeps gliding, slowing
## by this factor each second.
const SCROLL_START := 5.0
const FLING_DECAY := 0.03
## Smallest each control may be, as a share of the screen height, whatever
## room the black side bars leave (they overhang the game if they must).
const MIN_PAD := 0.24
const MIN_BUTTON := 0.12
const MIN_BIG := 0.11
## A dead ring around every control (share of screen height): touches there
## do nothing, so a thumb that just misses never becomes a confirm.
const GUARD := 0.07

var active := false
var alpha := 0.0
var in_bars := false
var ck := 4.0
## Each control: {id, rect (window space), art, action, kind}
var controls: Array = []
## Which control each finger is holding, by touch index.
var fingers := {}
## Reference counts per action, so two sources can hold the same action.
var held := {}
## Joystick state: which finger holds it, its ring centre and knob, its size,
## and the directions it is pressing (with strength).
var joy_finger := -1
var joy_origin := Vector2.ZERO
var joy_knob := Vector2.ZERO
var joy_radius := 1.0
var joy_dirs := {}
## When the ring had to shift to stay on screen, the thumb's starting offset
## from its centre, so touching down never counts as a push.
var joy_offset := Vector2.ZERO
var joy_blocked := true
var running := false
var layout := ""
## The "touch_arrows" setting the controls were laid out for: 0 swipe,
## 1 buttons, 2 both.
var arrow_mode := 0
## 0..1: how far controls have faded aside for dialog or a tappable menu,
## and which ones: dialog hides pad, A and B; a menu or list hides pad and A
## (B stays for "back"). Pause always stays.
var dialog_fade := 0.0
var hidden_ids: Array = []
## What the shared top-right slot shows: "menu", "b" or "" (nothing).
var slot_mode := ""
var slot_alpha := {"menu": 0.0, "b": 0.0}
var tilt_base := Vector3.ZERO
var tilt_dirs := {}
var web_unlocked := false
## Drag-scrolling: the list's speed (game px/s) while a finger moves it, and
## the glide left over after a flick.
var scroll_v := 0.0
var scroll_t := 0.0
var fling_v := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func shell() -> Shell:
	return Game.shell


# ----------------------------------------------------------------- layout --

func relayout() -> void:
	## Places every control for the current window and layout.
	var sh := shell()
	if sh == null:
		return
	var win := get_viewport_rect().size
	var g := sh.game_rect
	var bar := g.position.x
	var target := maxf(1.0, roundf(win.y * 0.26 / PAD_ART))
	var min_k := ceilf(win.y * MIN_PAD / PAD_ART)
	var in_bar_k := floorf((bar - 8.0) / PAD_ART)
	in_bars = in_bar_k >= target * 0.55
	ck = minf(target, in_bar_k) if in_bars else target
	ck = maxf(ck, min_k)
	var m := 4.0 * ck
	controls.clear()
	var left_c: Vector2
	var right_c: Vector2
	if in_bars:
		left_c = Vector2(bar / 2.0, win.y * 0.62)
		right_c = Vector2(win.x - bar / 2.0, win.y * 0.62)
	else:
		left_c = Vector2(m + PAD_ART * ck / 2.0, win.y - m - PAD_ART * ck / 2.0)
		right_c = Vector2(win.x - m - PAD_ART * ck / 2.0, win.y - m - PAD_ART * ck / 2.0)
	# the shared top-right slot: MENU and B are the same size, same place
	var ss := 21.0 * _scale_for("b", 1.0)
	var slot_c := Vector2(win.x - bar / 2.0, maxf(win.y * 0.14, m + ss / 2.0)) if in_bars else Vector2(win.x - m - ss / 2.0, m + ss / 2.0)
	_add("menu", slot_c, "menu", "", "menu")
	_add("b", slot_c, "b", "cancel", "button")
	match layout:
		"ud":
			_add("up", left_c, "arrow_up", "up", "button", 1.4)
			_add("down", right_c, "arrow_down", "down", "button", 1.4)
		"arrows":
			if _arrow_buttons():
				var s := 25.0 * _scale_for("arrow_up", 1.0)
				# left/right stack diagonally so they fit a narrow side bar
				var dx := s * (0.25 if in_bars else 0.55)
				var dy := s * (0.55 if in_bars else 0.0)
				_add("left", left_c + Vector2(-dx, -dy), "arrow_left", "left", "button")
				_add("right", left_c + Vector2(dx, dy), "arrow_right", "right", "button")
				_add("up", right_c + Vector2(0, -s * 0.55), "arrow_up", "up", "button")
				_add("down", right_c + Vector2(0, s * 0.55), "arrow_down", "down", "button")
			# swiping needs no controls (see _swipe_zone)
		"lr", "hold", "mash", "tap", "touch":
			pass   # played by touching the screen itself (see _zone_action)
		_:
			# the joystick isn't a fixed control: it appears where you touch
			joy_radius = PAD_ART * ck / 2.0
	if in_bars and _bar_buttons():
		_bar_hits(win, bar)
	queue_redraw()


func _bar_hits(win: Vector2, bar: float) -> void:
	## In side-bar mode a minigame's buttons own their whole bar (or half of
	## it, with two per side), however small they're drawn: big thumb targets.
	var top := win.y * 0.22
	for side in [0, 1]:
		var x0 := 0.0 if side == 0 else win.x - bar
		var mine := controls.filter(func(c: Dictionary) -> bool:
			return c.kind == "button" and ((c.rect as Rect2).get_center().x < win.x / 2.0) == (side == 0))
		mine.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a.rect as Rect2).position.y < (b.rect as Rect2).position.y)
		var h := (win.y - top) / maxf(1.0, mine.size())
		for i in mine.size():
			mine[i].hit = Rect2(x0, top + h * i, bar, h)


func _arrow_buttons() -> bool:
	return arrow_mode != 0


func _bar_buttons() -> bool:
	## Whether this layout's buttons take over the side bars.
	return layout == "ud" or (layout == "arrows" and _arrow_buttons())


func _scale_for(art: String, k: float) -> float:
	## Whole-number scale for a control: its layout size, shrunk to fit a
	## narrow side bar, but never below its minimum share of the screen.
	var tex := Art.ui("t_" + art)
	var win := get_viewport_rect().size
	var sc := roundf(ck * k)
	if in_bars:
		var bar := shell().game_rect.position.x
		sc = minf(sc, floorf((bar - 6.0) / tex.get_width()))
	var ratio := MIN_BUTTON
	if art.begins_with("pad"):
		ratio = MIN_PAD
	elif art.begins_with("big_"):
		ratio = MIN_BIG
	elif art == "menu":
		ratio = MIN_BUTTON
	return maxf(maxf(1.0, sc), ceilf(win.y * ratio / tex.get_height()))


func _add(id: String, center: Vector2, art: String, action: String, kind: String, k: float = 1.0) -> void:
	var tex := Art.ui("t_" + art)
	var sc := _scale_for(art, k)
	var sz := tex.get_size() * sc
	var win := get_viewport_rect().size
	var pos := (center - sz / 2.0).round()
	# keep every control fully on screen
	pos = pos.clamp(Vector2(2, 2), win - sz - Vector2(2, 2))
	var r := Rect2(pos, sz)
	var hit := r.grow(r.size.x * 0.12)
	controls.append({"id": id, "rect": r, "hit": hit, "guard": hit.grow(win.y * GUARD), "art": art, "action": action, "kind": kind, "scale": sc})


# ------------------------------------------------------------------ drawing --

func _process(delta: float) -> void:
	# "auto" = the usual pad and buttons, shown only when they're needed;
	# minigames ask for their own layout (or "pad" to keep it up throughout)
	var want := Game.touch_layout if Game.touch_layout != "" else "auto"
	var am := int(Game.settings.get("touch_arrows", 0))
	if want != layout or am != arrow_mode:
		_release_all()
		layout = want
		arrow_mode = am
		tilt_base = Input.get_accelerometer()
		relayout()
	if fling_v != 0.0:
		_fling(delta)
	var target := 1.0 if active else 0.0
	if not is_equal_approx(alpha, target):
		alpha = move_toward(alpha, target, delta * 4.0)
		queue_redraw()
	# while dialog is up the pad and buttons step aside (taps advance the
	# text, choices are tapped directly); they return when the box closes
	var want_hidden: Array = []
	if _dialog_up():
		want_hidden = ["pad", "a", "b"]
	elif _uses_pad() and _menu_up():
		want_hidden = ["pad", "a"]
	elif layout == "auto" and not _field_control():
		# cutscenes, battle animations, results, cards: nothing to steer, and
		# a tap still means OK
		want_hidden = ["pad", "a", "b"]
	if not want_hidden.is_empty():
		if want_hidden != hidden_ids:
			if dialog_fade == 0.0 or not hidden_ids.has("pad"):
				_joy_release()
			hidden_ids = want_hidden
			relayout()
	joy_blocked = not _uses_pad() or want_hidden.has("pad")
	if joy_blocked and joy_finger >= 0:
		_joy_release()
	var sm := _slot_mode()
	if sm != slot_mode:
		slot_mode = sm
		queue_redraw()
	for k in slot_alpha:
		var t := 1.0 if k == slot_mode else 0.0
		if not is_equal_approx(slot_alpha[k], t):
			slot_alpha[k] = move_toward(slot_alpha[k], t, delta * 6.0)
			queue_redraw()
	var dlg := 1.0 if not want_hidden.is_empty() else 0.0
	if not is_equal_approx(dialog_fade, dlg):
		dialog_fade = move_toward(dialog_fade, dlg, delta * 6.0)
		queue_redraw()
	if dialog_fade == 0.0 and dlg == 0.0 and not hidden_ids.is_empty():
		hidden_ids = []
		relayout()
	if active:
		_tilt()


func _draw() -> void:
	if alpha <= 0.0:
		return
	var a := alpha * (1.0 if in_bars else 0.6)
	if layout == "lr" and Game.touch_running:
		# the half of the screen being held lights faintly
		var win := get_viewport_rect().size
		for id in fingers.values():
			if id == "zone:left" or id == "zone:right":
				var x0 := 0.0 if id == "zone:left" else win.x / 2.0
				draw_rect(Rect2(x0, 0, win.x / 2.0, win.y), Color(Pal.CANDLE, 0.08 * alpha))
	if in_bars and _bar_buttons():
		# show each bar zone that acts as a button; it lights while held
		for c in controls:
			if c.kind != "button":
				continue
			var hr: Rect2 = (c.hit as Rect2).grow(-ck * 2)
			var on: bool = fingers.values().has(c.id)
			draw_rect(hr, Color(Pal.PANEL.lerp(Pal.CANDLE, 0.25 if on else 0.0), (0.55 if on else 0.35) * a))
			draw_rect(hr, Color(Pal.LILAC, 0.35 * a), false, maxf(1.0, ck * 0.5))
	for c in controls:
		var ca := a
		if slot_alpha.has(c.id):
			ca *= slot_alpha[c.id]
			if ca <= 0.01:
				continue
		elif _hides_for_dialog(c):
			ca *= 1.0 - dialog_fade
			if ca <= 0.01:
				continue
		var art: String = c.art
		if fingers.values().has(c.id):
			art += "_on"
		draw_texture_rect(Art.ui("t_" + art), c.rect, false, Color(1, 1, 1, ca))
	_draw_joystick(a)


func _draw_joystick(a: float) -> void:
	## The stick under your thumb while held; nothing otherwise.
	var base := Art.ui("t_joy_base")
	var knob := Art.ui("t_joy_knob_on" if running else "t_joy_knob")
	var bs := Vector2(joy_radius * 2.0, joy_radius * 2.0)
	var ks := bs * (19.0 / 37.0)
	if joy_finger >= 0:
		draw_texture_rect(base, Rect2((joy_origin - bs / 2.0).round(), bs), false, Color(1, 1, 1, a * 0.85))
		draw_texture_rect(knob, Rect2((joy_knob - ks / 2.0).round(), ks), false, Color(1, 1, 1, a))
		if running:
			# a little dust ring while running
			draw_arc(joy_origin, joy_radius * 1.08, 0, TAU, 40, Color(Pal.CREAM, 0.4 * a), maxf(1.0, ck * 0.75))


# -------------------------------------------------------------------- input --

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_set_active(false)
	elif event is InputEventJoypadButton and event.pressed:
		_set_active(false)
	elif event is InputEventScreenTouch:
		_touch(event)
	elif event is InputEventScreenDrag:
		_drag(event)


func _set_active(on: bool) -> void:
	if on == active:
		return
	active = on
	Game.touch_active = on
	if not on:
		_release_all()
	queue_redraw()


func _touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_set_active(true)
		_web_unlock()
		fling_v = 0.0
		var hit := _hit(e.position)
		var win := get_viewport_rect().size
		if hit.is_empty() and not joy_blocked and joy_finger < 0 and e.position.x < win.x * JOY_REGION:
			# the left part of the screen summons the joystick under the thumb
			fingers[e.index] = "joy"
			joy_finger = e.index
			joy_origin = e.position.clamp(Vector2(joy_radius + 2, joy_radius + 2), win - Vector2(joy_radius + 2, joy_radius + 2))
			joy_offset = e.position - joy_origin
			joy_knob = joy_origin
			Game.buzz(6)
			queue_redraw()
			return
		if hit.is_empty() and _swipe_zone():
			# an arrow minigame: a swipe anywhere (bars too) is an arrow
			fingers[e.index] = "swipe"
			set_meta("start_%d" % e.index, e.position)
			set_meta("swiped_%d" % e.index, false)
			return
		var zone := _zone_action(e.position)
		if hit.is_empty() and zone != "":
			# a minigame played by touching the screen (black bars included)
			fingers[e.index] = "zone:" + zone
			_press(zone)
			Game.buzz(8)
			queue_redraw()
			return
		if hit.is_empty() and _guarded(e.position):
			# just beside a control (or on an empty bar): ignore it entirely
			fingers[e.index] = "guard"
			return
		if hit.is_empty():
			# the game picture itself: OK (advance dialog, choose, start...)
			fingers[e.index] = "game"
			set_meta("start_%d" % e.index, e.position)
			set_meta("swiped_%d" % e.index, false)
			if _game_tap_allowed() and _scroll_target() != null:
				# a scrolling list: wait for the release to tell a tap from a drag
				set_meta("pending_%d" % e.index, true)
				set_meta("scrolling_%d" % e.index, false)
				set_meta("last_%d" % e.index, e.position)
				scroll_v = 0.0
				return
			if _game_tap_allowed():
				# menus and lists take the tap first; if one is open and the
				# tap misses it, nothing happens (no accidental confirm)
				match _offer_tap(Game.shell.to_game(e.position)):
					0:
						_press("accept")
						set_meta("accept_%d" % e.index, true)
						Game.buzz(8)
					1:
						Game.buzz(8)
			return
		fingers[e.index] = hit.id
		Game.buzz(10)
		match hit.kind:
			"menu":
				_pause()
			"button":
				_press(hit.action)
	else:
		var id: String = fingers.get(e.index, "")
		fingers.erase(e.index)
		match id:
			"":
				pass
			"joy":
				_joy_release()
			"game":
				if get_meta("pending_%d" % e.index, false):
					set_meta("pending_%d" % e.index, false)
					if get_meta("scrolling_%d" % e.index, false):
						# a flick keeps the list gliding; a drag that stopped doesn't
						fling_v = scroll_v if Time.get_ticks_msec() / 1000.0 - scroll_t < 0.1 else 0.0
					else:
						var start: Vector2 = get_meta("start_%d" % e.index, e.position)
						match _offer_tap(Game.shell.to_game(start)):
							0:
								_tap("accept")
								Game.buzz(8)
							1:
								Game.buzz(8)
				elif get_meta("accept_%d" % e.index, false):
					set_meta("accept_%d" % e.index, false)
					_release("accept")
			"menu":
				pass
			"swipe":
				# a flick too quick for any drag event still counts
				_swipe(e.index, e.position)
			_:
				if id.begins_with("zone:"):
					_release(id.substr(5))
				for c in controls:
					if c.id == id:
						_release(c.action)
		queue_redraw()


func _drag(e: InputEventScreenDrag) -> void:
	var id: String = fingers.get(e.index, "")
	if id == "joy":
		_joy_move(e.position)
	elif id == "game" and get_meta("pending_%d" % e.index, false):
		_scroll_drag(e)
	elif id == "swipe":
		_swipe(e.index, e.position)


func _swipe(index: int, p: Vector2) -> void:
	## Once a finger has travelled far enough, taps the arrow it moved
	## toward (one arrow per touch).
	if get_meta("swiped_%d" % index, true):
		return
	var v: Vector2 = p - get_meta("start_%d" % index, p)
	if v.length() > get_viewport_rect().size.y * SWIPE:
		set_meta("swiped_%d" % index, true)
		var d := ("right" if v.x > 0 else "left") if absf(v.x) > absf(v.y) else ("down" if v.y > 0 else "up")
		_tap(d)
		Game.buzz(8)


func _scroll_target() -> Node:
	## The list a vertical drag should scroll (a tap target with scroll_by), if any.
	for n in get_tree().get_nodes_in_group("tap_targets"):
		if is_instance_valid(n) and n.is_inside_tree() and n.has_method("scroll_by") and (not n is CanvasItem or n.is_visible_in_tree()):
			return n
	return null


func _scroll_drag(e: InputEventScreenDrag) -> void:
	var k := maxf(0.001, Game.shell.game_scale)
	if not get_meta("scrolling_%d" % e.index, false):
		var start: Vector2 = get_meta("start_%d" % e.index, e.position)
		if absf(e.position.y - start.y) / k < SCROLL_START:
			return
		set_meta("scrolling_%d" % e.index, true)
	var last: Vector2 = get_meta("last_%d" % e.index, e.position)
	set_meta("last_%d" % e.index, e.position)
	# content follows the finger: dragging up scrolls further down the list
	var dy := -(e.position.y - last.y) / k
	var tgt := _scroll_target()
	if tgt == null:
		return
	tgt.scroll_by(dy)
	var now := Time.get_ticks_msec() / 1000.0
	var dt := now - scroll_t
	scroll_t = now
	if dt > 0.0 and dt < 0.1:
		scroll_v = lerpf(scroll_v, dy / dt, 0.5)
	else:
		scroll_v = 0.0


func _fling(delta: float) -> void:
	var tgt := _scroll_target()
	if tgt == null:
		fling_v = 0.0
		return
	tgt.scroll_by(fling_v * delta)
	fling_v *= pow(FLING_DECAY, delta)
	if absf(fling_v) < 8.0:
		fling_v = 0.0


func _hit(p: Vector2) -> Dictionary:
	if alpha <= 0.01 and not active:
		return {}
	for c in controls:
		if not _shown(c):
			continue
		if (c.hit as Rect2).has_point(p):
			return c
	return {}


func _guarded(p: Vector2) -> bool:
	## True for touches in the dead ring around a control, or on the empty
	## black bars beside the game: these never count as a tap on the game.
	if not Game.shell.game_rect.has_point(p):
		return true
	var win := get_viewport_rect().size
	for c in controls:
		if not _shown(c):
			continue
		if (c.guard as Rect2).has_point(p):
			return true
	return false


func _dialog_open() -> bool:
	var m: Node = Game.main
	return m != null and is_instance_valid(m) and m.dialog.visible


func _dialog_up() -> bool:
	var m: Node = Game.main
	return m != null and is_instance_valid(m) and m.dialog.visible and _uses_pad()


func _uses_pad() -> bool:
	return layout in ["auto", "pad", "board"]


func _field_control() -> bool:
	## The player is walking around: the one time the pad is really needed.
	var m: Node = Game.main
	if m == null or not is_instance_valid(m) or not m.in_story or m.dialog.visible:
		return false
	var w: World = m.world
	if w == null or not is_instance_valid(w) or not w.visible or w.busy or not w.player.visible:
		return false
	if m.battle_layer.get_child_count() > 0:
		return false
	for c in m.cine_layer.get_children():
		if c is Cinema or c is Minigame:
			return false
	return true


func _hides_for_dialog(c: Dictionary) -> bool:
	return hidden_ids.has(c.id)


func _shown(c: Dictionary) -> bool:
	## Whether a control is currently on screen (and so can be touched).
	if slot_alpha.has(c.id):
		return c.id == slot_mode
	return not (_hides_for_dialog(c) and dialog_fade > 0.5)


func _slot_mode() -> String:
	## MENU only while walking around; B only where "back" means something.
	if layout == "board":
		return "b"   # backgammon: B swaps the dice
	if not _uses_pad() or _dialog_up():
		return ""
	if _menu_up():
		return "b" if _back_available() else ""
	if layout == "auto" and _field_control():
		return "menu"
	return ""


func _back_available() -> bool:
	for n in get_tree().get_nodes_in_group("tap_targets"):
		if not is_instance_valid(n) or not n.is_inside_tree():
			continue
		if n is Menu:
			if n.active and n.cancellable:
				return true
		elif not n is CanvasItem or n.is_visible_in_tree():
			return true
	return false


func _menu_up() -> bool:
	## A tappable menu or list is open (they're operated by tapping instead).
	for n in get_tree().get_nodes_in_group("tap_targets"):
		if is_instance_valid(n) and n.is_inside_tree() and (not n is CanvasItem or n.is_visible_in_tree()):
			return true
	return false


func _offer_tap(game_pos: Vector2) -> int:
	## Offers a tap on the picture to whatever is tappable right now (menus,
	## lists, battle targets). 0 = nothing tappable, 1 = taken, 2 = missed.
	var targets := get_tree().get_nodes_in_group("tap_targets").filter(func(n: Node) -> bool:
		return is_instance_valid(n) and n.is_inside_tree() and (not n is CanvasItem or n.is_visible_in_tree()))
	if targets.is_empty():
		return 0
	targets.sort_custom(func(a: Node, b: Node) -> bool: return int(a.get_meta("tap_priority", 0)) > int(b.get_meta("tap_priority", 0)))
	for t in targets:
		if t.tap(game_pos):
			return 1
	return 2


static func confirm() -> void:
	## For tap targets: the second tap on a selected row means OK.
	if Game.shell and Game.shell.touch:
		Game.shell.touch._tap("accept")


func _zone_action(p: Vector2) -> String:
	## While a touch-the-screen minigame is being played, the action a touch
	## at p holds down: OK anywhere, or left/right by half of the screen.
	if not Game.touch_running or _menu_up() or _dialog_open():
		return ""
	match layout:
		"hold", "mash", "tap":
			return "accept"
		"lr":
			return "left" if p.x < get_viewport_rect().size.x / 2.0 else "right"
	return ""


func _swipe_zone() -> bool:
	## While an arrow minigame is being played (and swiping is on), touches
	## anywhere but on a button are swipes.
	return layout == "arrows" and arrow_mode != 1 and Game.touch_running and not _menu_up() and not _dialog_open()


func _game_tap_allowed() -> bool:
	## Tapping the picture presses OK, except while a minigame is being played
	## (stray taps would count as inputs), unless it's a tap-to-play minigame
	## or one steered with the stick (the loot grab has no A button: a tap
	## away from the stick is OK).
	return not Game.touch_running or layout in ["tap", "pad"] or _menu_up() or _dialog_open()


func _joy_move(p: Vector2) -> void:
	## Analog: each direction is pressed with a strength from how far the
	## stick leans that way, so walking works in any direction. Pushed past
	## JOY_RUN of the ring, Pumpkin Man runs. Drag beyond the ring and the
	## ring follows the thumb.
	p -= joy_offset
	var v := p - joy_origin
	if v.length() > joy_radius:
		joy_origin += v.normalized() * (v.length() - joy_radius)
		v = p - joy_origin
	joy_knob = p
	var k := v.length() / joy_radius
	var want := {}
	if k > JOY_DEAD:
		var n := v.normalized()
		var push := clampf((k - JOY_DEAD) / (1.0 - JOY_DEAD), 0.0, 1.0)
		for pair in [["right", n.x], ["left", -n.x], ["down", n.y], ["up", -n.y]]:
			if pair[1] > JOY_AXIS:
				want[pair[0]] = clampf(pair[1] * maxf(push, 0.5), 0.4, 1.0)
	for d in ["up", "down", "left", "right"]:
		if want.has(d):
			Input.action_press(d, want[d])
		elif joy_dirs.has(d):
			Input.action_release(d)
	joy_dirs = want
	var run := not want.is_empty() and k >= JOY_RUN
	if run != running:
		running = run
		if run:
			_press("run")
			Game.buzz(12)
		else:
			_release("run")
	queue_redraw()


func _joy_release() -> void:
	for d in joy_dirs:
		Input.action_release(d)
	joy_dirs.clear()
	if running:
		_release("run")
	running = false
	joy_finger = -1
	queue_redraw()


func _pause() -> void:
	## Opens the pause menu on the field; anywhere else it acts as Back.
	var m: Node = Game.main
	if m == null:
		return
	var w: World = m.world
	if w and is_instance_valid(w) and w.visible and not w.busy and not m.dialog.visible and m.in_story:
		w.run(m.field_menu)
	else:
		_tap("cancel")


func _tilt() -> void:
	## Tilt steering for the balance / steering minigames. Measured from how
	## the phone was held when the minigame started.
	var mode := Game.touch_tilt
	var want := {}
	if mode != "":
		var acc := Input.get_accelerometer()
		if acc != Vector3.ZERO:
			var d := acc - tilt_base
			if d.x < -1.6:
				want["left"] = true
			elif d.x > 1.6:
				want["right"] = true
			if mode == "xy":
				if d.y < -1.6:
					want["up"] = true
				elif d.y > 1.6:
					want["down"] = true
	for a in tilt_dirs.keys():
		if not want.has(a):
			_release(a)
			tilt_dirs.erase(a)
	for a in want:
		if not tilt_dirs.has(a):
			_press(a)
			tilt_dirs[a] = true


func _web_unlock() -> void:
	## Web builds: go fullscreen and ask for motion permission (iOS) on the
	## first touch, which counts as the user gesture browsers require.
	if web_unlocked or not OS.has_feature("web"):
		return
	web_unlocked = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	JavaScriptBridge.eval("if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') { DeviceMotionEvent.requestPermission().catch(function(){}); }", true)


# -------------------------------------------------------------- actions ----

func _press(action: String) -> void:
	if action == "":
		return
	held[action] = int(held.get(action, 0)) + 1
	if int(held[action]) == 1:
		Input.action_press(action)


func _release(action: String) -> void:
	if action == "" or not held.has(action):
		return
	held[action] = int(held[action]) - 1
	if int(held[action]) <= 0:
		held.erase(action)
		Input.action_release(action)


func _tap(action: String) -> void:
	## A quick press and release, two frames apart so "just pressed" is seen.
	_press(action)
	await get_tree().process_frame
	await get_tree().process_frame
	_release(action)


func _release_all() -> void:
	for a in held.keys():
		Input.action_release(a)
	held.clear()
	fingers.clear()
	for d in joy_dirs:
		Input.action_release(d)
	joy_dirs.clear()
	joy_finger = -1
	running = false
	tilt_dirs.clear()
	queue_redraw()
