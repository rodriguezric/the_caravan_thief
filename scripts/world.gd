class_name World
extends Node2D
## The field: generated ground, y-sorted props and characters, tile collision,
## talking, examining, step triggers and exits. Guards can patrol with lantern
## cones: step into the light with a clear line of sight and they see you
## (handler.spotted). Story scripts drive cutscenes through the helpers at the
## bottom (actor lookup, camera pans, tint, markers).

const TILE := 16
const SPEED := 62.0

var def: Dictionary
var rows: Array
var tw := 0
var th := 0
var solid := {}
var events := {}
var ents: Node2D
var decals: Node2D
var lights: Node2D
var player: Actor
var npcs: Array = []
var by_id := {}
var props := {}
var cam: Camera2D
var busy := false
var _event_end_frame := -10
var paused := false
var animated: Array = []
var hud: CanvasLayer
var tint: CanvasModulate
var handler: Object
var cam_follow := true
var cam_focus := Vector2.ZERO
var marker: Sprite2D
var fired := {}
var step_t := 0.0
var cam_bias := 0.0
var water: Sprite2D
var water_frame := -1
var hint: Sprite2D
## Stealth: guards with patrols and cones; how close the player came to being
## seen (0..1, drawn as an eye meter), and whether stealth is switched on.
var guards: Array = []
var stealth := false
var alert := 0.0
var alert_bar: Control
var spotted_once := false


func setup(map_def: Dictionary, tile: Vector2i, facing: int, p_handler: Object) -> void:
	def = map_def
	handler = p_handler
	rows = def.rows
	tw = (rows[0] as String).length()
	th = rows.size()
	tint = CanvasModulate.new()
	tint.color = def.get("tint", Color.WHITE)
	add_child(tint)
	var ground := Sprite2D.new()
	ground.centered = false
	ground.texture = Art.ground(def.id, rows, def.get("theme", "road"))
	add_child(ground)
	water = Sprite2D.new()
	water.centered = false
	water.texture = Art.water_overlay(def.id, rows, def.get("theme", "road"), 0)
	add_child(water)
	decals = Node2D.new()
	add_child(decals)
	ents = Node2D.new()
	ents.y_sort_enabled = true
	add_child(ents)
	lights = Node2D.new()
	add_child(lights)
	_build_tiles()
	_build_props()
	_build_npcs()
	player = Actor.new(Data.spec(def.get("player", "rook")))
	player.position = tile_center(tile)
	player.face(facing)
	player.visible = not def.get("no_player", false)
	ents.add_child(player)
	cam = Camera2D.new()
	add_child(cam)
	cam.position = _clamp_cam(player.position)
	cam.make_current()
	hud = CanvasLayer.new()
	hud.layer = 3
	add_child(hud)
	hint = Sprite2D.new()
	hint.texture = Art.ui("emote_!")
	hint.z_index = 30
	hint.visible = false
	hint.modulate.a = 0.85
	add_child(hint)
	stealth = def.get("stealth", false)
	if stealth:
		_build_alert_bar()
	if def.has("music"):
		Sfx.music(def.music)


func _clamp_cam(p: Vector2) -> Vector2:
	var mw := tw * TILE
	var mh := th * TILE
	var x := mw / 2.0 if mw <= 320 else clampf(p.x, 160.0, mw - 160.0)
	var y := mh / 2.0 + cam_bias * 0.5 if mh <= 180 else clampf(p.y, 90.0, mh - 90.0 + cam_bias)
	return Vector2(x, y)


func tile_char(p: Vector2) -> String:
	var t := Vector2i(floori(p.x / TILE), floori((p.y - 3) / TILE))
	if t.x < 0 or t.y < 0 or t.x >= tw or t.y >= th:
		return " "
	return (rows[t.y] as String)[t.x]


func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + 8, t.y * TILE + 12)


func tile_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori((p.y - 3) / TILE))


func _place(tex: Texture2D, pos: Vector2, parent: Node = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = -Vector2(tex.get_width() * 0.5, tex.get_height()).floor()
	s.position = pos
	(parent if parent else ents).add_child(s)
	return s


func _shadow(pos: Vector2, w: int, h: int) -> void:
	var s := Sprite2D.new()
	s.texture = Art.shadow(w, h)
	s.modulate = Color(1, 1, 1, 0.25)
	s.position = pos
	decals.add_child(s)


func add_light(pos: Vector2, r: int, c: Color, pulse: float = 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Art.light(r, c)
	s.position = pos
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	lights.add_child(s)
	if pulse > 0.0:
		s.set_meta("pulse", pulse)
		s.set_meta("phase", randf() * TAU)
		animated.append(s)
	return s


func _build_tiles() -> void:
	for y in th:
		for x in tw:
			var ch: String = (rows[y] as String)[x]
			if ArtTiles.is_solid(ch):
				solid[Vector2i(x, y)] = true


func _build_props() -> void:
	for p in def.get("props", []):
		add_prop(p)
	for e in def.get("events", []):
		events[e.tile] = e


func add_prop(p: Dictionary) -> Sprite2D:
	var t: Vector2i = p.tile
	var pos: Vector2 = Vector2(t.x * TILE + 8, (t.y + 1) * TILE) + p.get("offset", Vector2.ZERO)
	var tex := Art.prop(p.kind, p.get("v", 0))
	var s: Sprite2D
	if p.get("decal", false):
		s = _place(tex, pos, decals)
	else:
		s = _place(tex, pos)
		if p.get("shadow", true) and tex.get_width() > 12 and p.get("wall", false) == false:
			_shadow(pos + Vector2(0, -1), int(tex.get_width() * 0.8), 5)
	if p.has("lift"):
		s.offset.y -= p.lift
	if p.get("flip", false):
		s.flip_h = true
	if p.has("id"):
		props[p.id] = s
	if p.has("anim"):
		s.set_meta("kind", p.kind)
		s.set_meta("frames", p.anim)
		s.set_meta("fps", p.get("fps", 3.0))
		animated.append(s)
	if p.has("light"):
		var lp: Vector2 = pos + p.get("light_off", Vector2(0, -tex.get_height() * 0.6))
		var l := add_light(lp, p.get("lr", 18), p.light, p.get("pulse", 0.0))
		if p.has("id"):
			s.set_meta("light", l)
	var area: Rect2i = p.get("area", Rect2i(t.x, t.y, 1, 1) if not p.get("decal", false) and not p.get("wall", false) else Rect2i())
	for yy in range(area.position.y, area.end.y):
		for xx in range(area.position.x, area.end.x):
			solid[Vector2i(xx, yy)] = true
			if p.has("event"):
				events[Vector2i(xx, yy)] = p.event
	if p.has("event") and area.size == Vector2i.ZERO:
		events[t] = p.event
	return s


func remove_prop(id: String) -> void:
	if props.has(id):
		var s: Sprite2D = props[id]
		if s.has_meta("light"):
			(s.get_meta("light") as Node).queue_free()
		s.queue_free()
		props.erase(id)


func _build_npcs() -> void:
	for n in def.get("npcs", []):
		add_npc(n)


func add_npc(n: Dictionary) -> Actor:
	var spec: Dictionary = n.spec if n.has("spec") else Data.spec(n.who)
	var a := Actor.new(spec)
	a.info = n
	a.home_tile = n.tile
	a.position = tile_center(n.tile) + n.get("offset", Vector2.ZERO)
	a.face(n.get("dir", 0))
	if n.has("mood"):
		a.mood = n.mood
	if n.has("pose"):
		a.set_pose(n.pose)
	a.refresh()
	a.visible = not n.get("hidden", false)
	ents.add_child(a)
	npcs.append(a)
	if n.has("id"):
		by_id[n.id] = a
	elif n.has("who"):
		by_id[n.who] = a
	if n.has("patrol"):
		_make_guard(a, n)
	return a


func remove_npc(id: String) -> void:
	if by_id.has(id):
		var a: Actor = by_id[id]
		npcs.erase(a)
		by_id.erase(id)
		for g in guards:
			if g.actor == a:
				(g.cone as Node).queue_free()
				guards.erase(g)
				break
		a.queue_free()


func show_area_name(text: String = "") -> void:
	if text == "":
		text = def.get("name", "")
	if text == "":
		return
	var b := Art.make_box("bar_box")
	var l := Label.new()
	l.text = text
	l.position = Vector2(6, 3)
	b.add_child(l)
	b.size = Vector2(Art.text_width(text) + 14, 15)
	b.position = Vector2(-b.size.x, 6)
	hud.add_child(b)
	var tw_ := b.create_tween()
	tw_.tween_property(b, "position:x", 6.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_.tween_interval(2.0)
	tw_.tween_property(b, "position:x", -b.size.x - 4, 0.3)
	tw_.tween_callback(b.queue_free)


# ---------------------------------------------------------------- update ---

func _process(delta: float) -> void:
	_animate(delta)
	_update_npcs(delta)
	if stealth:
		_update_guards(delta)
	var want := 34.0 if Game.main.dialog.visible else 0.0
	if Game.main.dialog.visible and Game.reduced_motion():
		cam_bias = want
	cam_bias = move_toward(cam_bias, want, delta * 120.0)
	var target := _clamp_cam((player.position if cam_follow else cam_focus) + Vector2(0, cam_bias))
	cam.position = cam.position.lerp(target, minf(1.0, delta * 8.0)) if not cam_follow else target
	cam.position = cam.position.round()
	_update_hint()
	if busy or paused or Game.main.dialog.visible or not player.visible:
		if not player.scripted:
			player.moving = false
		return
	var v := Input.get_vector("left", "right", "up", "down")
	if v.length() > 0.2:
		var d: int
		if absf(v.x) > absf(v.y):
			d = 2 if v.x > 0 else 3
		else:
			d = 0 if v.y > 0 else 1
		player.face(d)
		var running := Input.is_action_pressed("run")
		var spd := SPEED * (1.6 if running else 1.0)
		if def.get("sneak", false) and not running:
			spd *= 0.8
		var step := v.normalized() * spd * delta
		var before := player.position
		_try_move(Vector2(step.x, 0))
		_try_move(Vector2(0, step.y))
		var moved := player.position.distance_to(before)
		player.moving = moved > 0.01
		var want_pose := "run" if running else ("sneak" if def.get("sneak", false) else "walk")
		if player.pose != want_pose and player.pose in ["walk", "run", "sneak"]:
			player.set_pose(want_pose)
		if moved > 0.01:
			step_t += moved
			if step_t > 18.0:
				step_t = 0.0
				var tch := tile_char(player.position)
				Sfx.play("step", randf_range(0.85, 1.1) * (1.15 if tch in ":xb" else 1.0), -20.0 if not def.get("sneak", false) or running else -28.0)
				if running:
					player.dust()
			_after_step()
	else:
		player.moving = false
		if player.pose == "run":
			player.set_pose("sneak" if def.get("sneak", false) else "walk")
	if busy or Engine.get_process_frames() - _event_end_frame <= 1:
		return
	if Input.is_action_just_pressed("accept"):
		_interact()
	elif Input.is_action_just_pressed("cancel"):
		run(Game.main.field_menu)


func _try_move(d: Vector2) -> void:
	var p := player.position + d
	if not blocked(p, player):
		player.position = p


func blocked(p: Vector2, who: Node2D) -> bool:
	for c in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, -1), Vector2(5, -1)]:
		var q: Vector2 = p + c
		var t := Vector2i(floori(q.x / TILE), floori(q.y / TILE))
		if t.x < 0 or t.y < 0 or t.x >= tw or t.y >= th or solid.has(t):
			return true
	for n: Actor in npcs:
		if n == who or not n.visible or n.info.get("ghost", false):
			continue
		if absf(n.position.x - p.x) < 11 and absf(n.position.y - p.y) < 7:
			return true
	if who != player and player.visible and absf(player.position.x - p.x) < 11 and absf(player.position.y - p.y) < 7:
		return true
	return false


func _after_step() -> void:
	var t := tile_of(player.position)
	for e in def.get("exits", []):
		if (e.rect as Rect2i).has_point(t):
			run(handler.exit.bind(e))
			return
	for tr in def.get("triggers", []):
		if (tr.rect as Rect2i).has_point(t) and not fired.has(tr.id):
			if tr.get("once", true):
				fired[tr.id] = true
			run(handler.trigger.bind(tr.id))
			return


func run(co: Callable) -> void:
	## Runs an async event with player control locked until it finishes.
	if busy:
		return
	busy = true
	if not player.scripted:
		player.moving = false
	await co.call()
	if is_instance_valid(self):
		busy = false
		_event_end_frame = Engine.get_process_frames()


func _update_npcs(delta: float) -> void:
	for n: Actor in npcs:
		if n.scripted or n.info.has("patrol"):
			continue
		if not n.info.get("wander", false) or busy or paused:
			if n.walk_target == null:
				n.moving = false
			continue
		if n.walk_target == null:
			n.moving = false
			n.wander_t -= delta
			if n.wander_t <= 0:
				n.wander_t = randf_range(1.5, 4.0)
				var d := randi() % 4
				var target: Vector2 = n.position + Actor.DIRS[d] * TILE
				var home := tile_center(n.home_tile)
				if target.distance_to(home) <= TILE * n.info.get("range", 2.5) and not blocked(target, n):
					n.face(d)
					n.walk_target = target
		else:
			var tgt: Vector2 = n.walk_target
			var step := (tgt - n.position).limit_length(28.0 * delta)
			if blocked(n.position + step, n):
				n.walk_target = null
				continue
			n.position += step
			n.moving = true
			if n.position.distance_to(tgt) < 0.5:
				n.position = tgt
				n.walk_target = null


func _animate(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for s in animated:
		if not is_instance_valid(s):
			continue
		if s.has_meta("pulse"):
			s.modulate.a = 0.75 + 0.25 * sin(t * s.get_meta("pulse") + s.get_meta("phase"))
		elif s.has_meta("frames"):
			s.texture = Art.prop(s.get_meta("kind"), int(t * s.get_meta("fps")) % int(s.get_meta("frames")))
	if marker:
		marker.position.y = marker.get_meta("y") + (1.0 if fmod(t, 0.6) < 0.3 else -1.0)
	var wf := int(t * 3.0) % 4
	if wf != water_frame:
		water_frame = wf
		water.texture = Art.water_overlay(def.id, rows, def.get("theme", "road"), wf)


# ---------------------------------------------------------------- stealth --

func _make_guard(a: Actor, n: Dictionary) -> void:
	var cone := Sprite2D.new()
	var r: int = n.get("vision", 58)
	cone.texture = Art.cone(r, Pal.CANDLE.lerp(Pal.LEMON, 0.3))
	cone.centered = false
	cone.offset = Vector2(0, -r / 2.0)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	cone.material = m
	cone.z_index = 1
	lights.add_child(cone)
	var pts := []
	for t in n.patrol:
		pts.append(tile_center(t))
	guards.append({"actor": a, "cone": cone, "pts": pts, "i": 0, "wait": n.get("pause", 1.2), "r": float(r), "speed": n.get("speed", 26.0)})


func _update_guards(delta: float) -> void:
	var seen := false
	for g in guards:
		var a: Actor = g.actor
		if not is_instance_valid(a) or not a.visible:
			continue
		var cone: Sprite2D = g.cone
		if not busy and not paused and not Game.main.dialog.visible and not a.scripted:
			if g.wait > 0.0:
				g.wait -= delta
				a.moving = false
			elif not g.pts.is_empty():
				var target: Vector2 = g.pts[g.i]
				var v: Vector2 = target - a.position
				if v.length() < 0.6:
					a.position = target
					g.i = (g.i + 1) % g.pts.size()
					g.wait = a.info.get("pause", 1.2)
					var nxt: Vector2 = g.pts[g.i]
					a.face_toward(nxt)
				else:
					a.face_toward(target)
					a.position += v.limit_length(float(g.speed) * delta)
					a.moving = true
		var fwd: Vector2 = Actor.DIRS[a.dir]
		cone.position = a.position + Vector2(0, -8) + fwd * 4
		cone.rotation = fwd.angle()
		if _sees(a, fwd, g.r) and player.visible and not busy and not paused:
			seen = true
	if seen:
		alert = minf(1.0, alert + delta * 1.6)
	else:
		alert = maxf(0.0, alert - delta * 0.5)
	_draw_alert()
	if alert >= 1.0 and not busy:
		alert = 0.0
		spotted_once = true
		var who: Actor = null
		for g in guards:
			if _sees(g.actor, Actor.DIRS[(g.actor as Actor).dir], g.r):
				who = g.actor
		if handler.has_method("spotted"):
			run(handler.spotted.bind(who))


func _sees(a: Actor, fwd: Vector2, r: float) -> bool:
	var to := player.position - a.position
	var d := to.length()
	if d > r or d < 1.0:
		return false
	if absf(fwd.angle_to(to)) > 0.55:
		return false
	# solid tiles (walls, crates, wagons) block the light
	var steps := int(d / 6.0)
	for i in range(1, steps):
		var p := a.position + to * (float(i) / steps) + Vector2(0, -4)
		if solid.has(Vector2i(floori(p.x / TILE), floori(p.y / TILE))):
			return false
	return true


func _build_alert_bar() -> void:
	alert_bar = Control.new()
	alert_bar.position = Vector2(296, 6)
	hud.add_child(alert_bar)
	var eye := TextureRect.new()
	eye.texture = Art.ui("eye")
	eye.name = "eye"
	alert_bar.add_child(eye)
	var back := ColorRect.new()
	back.color = Pal.INK
	back.position = Vector2(0, 11)
	back.size = Vector2(11, 3)
	alert_bar.add_child(back)
	var fill := ColorRect.new()
	fill.name = "fill"
	fill.color = Pal.CANDLE
	fill.position = Vector2(0, 11)
	fill.size = Vector2(0, 3)
	alert_bar.add_child(fill)


func _draw_alert() -> void:
	if alert_bar == null:
		return
	var fill: ColorRect = alert_bar.get_node("fill")
	fill.size.x = 11.0 * alert
	fill.color = Pal.CANDLE if alert < 0.6 else Pal.BLOOD
	var eye: TextureRect = alert_bar.get_node("eye")
	eye.modulate.a = 0.4 + alert * 0.6
	alert_bar.position.x = 296 + (randf_range(-1, 1) if alert > 0.6 and not Game.reduced_motion() else 0.0)


# ------------------------------------------------------------- interact ----

func _front() -> Vector2:
	return player.position + Actor.DIRS[player.dir] * 12 + Vector2(0, -3)


func _target_in_front() -> Variant:
	var front := _front()
	for n: Actor in npcs:
		if n.visible and not n.info.get("silent", false) and n.position.distance_to(front + Vector2(0, 3)) < 13:
			return n
	var t := Vector2i(floori(front.x / TILE), floori(front.y / TILE))
	if events.has(t):
		return events[t]
	return null


func _update_hint() -> void:
	## A small "!" over Rook's head when there's something to talk to or look at.
	var show: bool = player.visible and not busy and not paused and not Game.main.dialog.visible
	if show:
		var tgt = _target_in_front()
		show = tgt != null and not (tgt is Dictionary and tgt.get("quiet", false))
	hint.visible = show
	if show:
		var t := Time.get_ticks_msec() / 1000.0
		hint.position = player.position + Vector2(7, -40 + (1 if fmod(t, 0.6) < 0.3 else 0))


func _interact() -> void:
	var tgt = _target_in_front()
	if tgt is Actor:
		run(_talk.bind(tgt))
	elif tgt is Dictionary:
		run(handler.examine.bind(tgt))


func _talk(n: Actor) -> void:
	n.walk_target = null
	n.moving = false
	var was := n.dir
	if not n.info.get("no_turn", false) and n.pose in ["walk", "idle"]:
		n.face_toward(player.position)
	player.face_toward(n.position)
	await handler.talk(n)
	if is_instance_valid(n) and n.info.get("turn_back", true) and n.info.get("wander", false) == false:
		n.face(was)


# --------------------------------------------------------------- helpers ---

func actor(id: String) -> Actor:
	if id == "player" or id == "rook":
		return player
	return by_id.get(id, null)


func pan_to(p: Vector2, t: float = 0.8) -> void:
	cam_follow = false
	var from := cam.position
	cam_focus = p
	var tw_ := create_tween()
	tw_.tween_method(func(v: Vector2) -> void: cam_focus = v, from, p, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw_.finished


func pan_back(t: float = 0.6) -> void:
	await pan_to(player.position, t)
	cam_follow = true


func zoom(k: float, t: float = 0.5) -> void:
	## Push the camera in for a dramatic beat (and back out with zoom(1)).
	if Game.reduced_motion():
		cam.zoom = Vector2(k, k)
		return
	await create_tween().tween_property(cam, "zoom", Vector2(k, k), t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished


func set_tint(c: Color, t: float = 0.6) -> void:
	var tw_ := create_tween()
	tw_.tween_property(tint, "color", c, t)
	await tw_.finished


func show_marker(tile: Vector2i) -> void:
	if marker == null:
		marker = Sprite2D.new()
		marker.texture = Art.ui("marker")
		marker.z_index = 30
		add_child(marker)
	marker.position = tile_center(tile) + Vector2(0, -22)
	marker.set_meta("y", marker.position.y)
	marker.visible = true


func hide_marker() -> void:
	if marker:
		marker.visible = false


func prop_sprite(id: String) -> Sprite2D:
	return props.get(id, null)
