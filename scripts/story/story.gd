class_name Story
extends Node
## The story director. The scenes are written like a screenplay in the act
## scripts (StoryAct1..3) using the helpers here: say/choose for dialogue,
## walk/face/emote/gesture/hop for staging, explore/until for field segments,
## cine for full-screen vignettes, battle/minigame for the set pieces.
## Story is also the World's event handler and forwards talk / examine /
## trigger / exit / spotted to the act being played.
##
## play() runs scenes in order from Game.run.scene, saving at the start of
## each, until an ending is reached; it returns the ending record.

var part: StoryPart
var acts := {}
var _jump := ""
## True while until() lets the player roam: the World's lock watchdog only
## acts then (any lock left over at that point has leaked).
var roaming := false


var m: Node:
	get:
		return Game.main

var w: World:
	get:
		return Game.main.world


func _ready() -> void:
	acts = {"act1": StoryAct1.new(), "act2": StoryAct2.new(), "act3": StoryAct3.new()}
	for k in acts:
		acts[k].s = self
		add_child(acts[k])


func prepare_jump(scene: String) -> void:
	## ./run_scene: give a jumped-to scene the state it would plausibly have.
	_jump = scene
	var i := Data.scene_index(scene)
	if i >= 3:
		Game.set_flag("has_sword")
		Game.add("reliance", 2, true)
		Game.set_flag("met_mara")
	if i >= 4:
		Game.set_flag("mara_joined")
		Game.add("mara", 2, true)
	if i >= 8:
		Game.add("suspicion", 3, true)


func act_for(scene: String) -> StoryPart:
	var i := Data.scene_index(scene)
	if i <= 3:
		return acts.act1
	if i <= 8:
		return acts.act2
	return acts.act3


func play() -> Dictionary:
	## Runs the story from the saved scene to an ending.
	var scene: String = Game.run.get("scene", "P1")
	while true:
		Game.run.scene = scene
		Game.save_run()
		part = act_for(scene)
		await _scene_card(scene)
		var next = await Callable(part, "scene_" + scene.to_lower()).call()
		if next is Dictionary:
			part = null
			await m.fade_out(0.6)
			m.clear_world()
			return next
		scene = str(next)
		if scene == "":
			return {}
	return {}


func _scene_card(scene: String) -> void:
	## Between scenes: the act banner (on a new act) and the scene's name,
	## time and place, over ink.
	var sd := Data.scene(scene)
	await m.fade_out(0.4)
	m.clear_world()
	var c := Cinema.open()
	var prev_act: String = str(Game.run.get("last_act", ""))
	var lines := []
	if sd.act != prev_act:
		lines.append([sd.act.to_upper(), Pal.OMEN.lerp(Pal.WHITE, 0.4), 1, 52])
		Game.run.last_act = sd.act
	lines.append([sd.title, Pal.CANDLE.lerp(Pal.LEMON, 0.3), 2, 74])
	lines.append(["%s  ~  %s" % [sd.place, sd.time], Pal.TEXT_DIM, 1, 102])
	var labels := []
	for ln in lines:
		var l := Art.shadow_label(ln[0], ln[1], ln[2])
		l.position = Vector2(160 - Art.text_width(ln[0], ln[2]) / 2.0, ln[3])
		l.modulate.a = 0.0
		c.add_child(l)
		labels.append(l)
	await m.fade_in(0.2)
	Sfx.play("hum", 1.0, -10.0)
	for i in labels.size():
		var tw := c.create_tween()
		tw.tween_interval(i * 0.3)
		tw.tween_property(labels[i], "modulate:a", 1.0, 0.5)
	await wait(1.6 if not Game.autoplay() else 0.3)
	await m.fade_out(0.5)
	c.queue_free()


func abort() -> void:
	## Quit to title from inside the story: rebuild the whole scene, which ends
	## every coroutine the scene had running. Autoloads (and the save) survive.
	Engine.set_meta("ct_skip_opening", true)
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


# ------------------------------------------------------- world handlers ----

func talk(n: Actor) -> void:
	if part:
		await part.talk(n)


func examine(ev: Dictionary) -> void:
	if part:
		await part.examine(ev)


func trigger(id: String) -> void:
	if part:
		await part.trigger(id)


func exit(e: Dictionary) -> void:
	if part:
		await part.exit(e)


func spotted(who: Actor) -> void:
	if part:
		await part.spotted(who)


# --------------------------------------------------------------- speakers ---

func rook_spec() -> Dictionary:
	var sp := Data.spec("rook_sword" if Game.flag("has_sword") else "rook").duplicate()
	if Game.run.get("mark", "") != "":
		sp.mark = Game.run.mark
	return sp


func speaker(who: String, mood: String = "") -> Array:
	## Returns [display name, dialog opts].
	match who:
		"":
			return ["", {"voice": "narrator"}]
		"~":
			return ["", {"voice": "narrator", "color": Pal.SKY.lerp(Pal.WHITE, 0.45)}]
		"blade":
			return ["The Blade", {"voice": "blade", "box": "omen_box", "color": Pal.OMEN.lerp(Pal.WHITE, 0.45)}]
		"crew":
			return ["The Crew", {"portrait": "crew", "voice": "crew", "side": "left"}]
		"hunters":
			return ["Cream Hunters", {"portrait": "hunters", "voice": "hunter", "side": "left"}]
	var spec := rook_spec() if who == "rook" else Data.spec(who)
	var side := "right" if who == "rook" else "left"
	var opts := {"portrait": spec, "mood": mood, "side": side, "voice": spec.get("voice", "narrator")}
	return [spec.get("name", who.capitalize()), opts]


func say(who: String, text, mood: String = "", extra: Dictionary = {}) -> void:
	var sp := speaker(who, mood)
	var opts: Dictionary = sp[1]
	opts.merge(extra, true)
	var lines: Array = text if text is Array else [text]
	if who == "~":
		lines = lines.map(func(l): return "(" + str(l) + ")")
	var act = _actor_for(who)
	if act != null and mood != "":
		act.set_mood(ArtPortraits.field_mood(mood))
	m.dialog.speaker_actor = act
	await m.dialog.say(lines, sp[0], opts)
	m.dialog.speaker_actor = null


func narrate(text) -> void:
	await say("", text)


func think(text) -> void:
	await say("~", text)


func choose(question: String, options: Array, who: String = "", mood: String = "") -> int:
	## Options are strings or {text, need (bool), tag ("Loyalty 3")}. Options
	## whose need is false still show, greyed, with their requirement.
	var shown := []
	for o in options:
		if o is String:
			shown.append(o)
		else:
			var ok: bool = o.get("need", true)
			var t: String = o.text
			if o.has("tag"):
				t = "[%s] %s" % [o.tag, t]
			shown.append({"text": t, "enabled": ok})
	var sp := speaker(who, mood)
	if Game.autoplay():
		var r: int = await m.dialog.ask(question, shown, sp[0], sp[1])
		if shown[r] is Dictionary and not shown[r].get("enabled", true):
			for i in shown.size():
				if not (shown[i] is Dictionary) or shown[i].get("enabled", true):
					return i
		return r
	return await m.dialog.ask(question, shown, sp[0], sp[1])


func _actor_for(who: String):
	## Whoever is speaking, wherever they are: a battle unit, a vignette
	## actor, or a field actor.
	var b := current_battle()
	if b != null:
		return b.unit(who)
	for c in m.cine_layer.get_children():
		if c is Cinema and not c.is_queued_for_deletion():
			var a: Actor = c.get_actor(who)
			if a != null:
				return a
	if w == null or not is_instance_valid(w):
		return null
	if who == "rook":
		return w.player
	return w.by_id.get(who, null)


func current_battle() -> Battle:
	for c in m.battle_layer.get_children():
		if c is Battle and not c.is_queued_for_deletion():
			return c
	return null


# ------------------------------------------------------------ choreography --

func a(id: String) -> Actor:
	if w == null or not is_instance_valid(w):
		return null
	return w.actor(id)


func walk(id: String, tiles: Array, speed: float = 48.0) -> void:
	var act := a(id)
	if act == null:
		return
	var pts := []
	for t in tiles:
		pts.append(w.tile_center(t) if t is Vector2i else t)
	await act.walk_to(pts, speed)


func run_to(id: String, tiles: Array) -> void:
	await walk(id, tiles, 96.0)


func sneak(id: String, tiles: Array) -> void:
	var act := a(id)
	if act == null:
		return
	act.set_pose("sneak")
	await walk(id, tiles, 34.0)
	if is_instance_valid(act):
		act.set_pose("walk")


func face(id: String, d: int) -> void:
	var act := a(id)
	if act:
		act.face(d)


func face_to(id: String, other: String) -> void:
	var act := a(id)
	var o := a(other)
	if act and o:
		act.face_toward(o.position)


func emote(id: String, kind: String, hold: float = 1.0) -> void:
	var act = _actor_for(id) if id != "player" else a("player")
	if act != null and act is Actor:
		act.emote(kind, hold)


func mood(id: String, md: String) -> void:
	var act = _actor_for(id)
	if act != null:
		act.set_mood(md)


func pose(id: String, p: String) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		act.set_pose(p)


func gesture(id: String, p: String, hold: float = 1.0) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		act.gesture(p, hold)


func hop(id: String, h: float = 4.0) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		await act.hop(h)


func jump_back(id: String) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		await act.jump_back()


func nod(id: String) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		act.nod()


func shake_head(id: String) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		act.shake_head()


func tremble(id: String, t: float = 0.6) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		act.tremble(t)


func shake_actor(id: String, t: float = 0.3) -> void:
	var act = _actor_for(id)
	if act != null and act is Actor:
		act.shake(t)


func pan(target, t: float = 0.7) -> void:
	var p: Vector2
	if target is Vector2i:
		p = w.tile_center(target)
	elif target is String:
		p = a(target).position
	else:
		p = target
	await w.pan_to(p, t)


func pan_back(t: float = 0.6) -> void:
	await w.pan_back(t)


func wait(t: float) -> void:
	await m.get_tree().create_timer(t).timeout


func hide(id: String) -> void:
	var act := a(id)
	if act:
		act.visible = false


func show(id: String) -> void:
	var act := a(id)
	if act:
		act.visible = true


func place(id: String, tile: Vector2i, d: int = -1, p: String = "") -> void:
	var act := a(id)
	if act == null:
		return
	act.position = w.tile_center(tile)
	act.visible = true
	if d >= 0:
		act.face(d)
	if p != "":
		act.set_pose(p)


func spawn(who: String, tile: Vector2i, d: int = 0, extra: Dictionary = {}) -> Actor:
	var n := {"who": who, "tile": tile, "dir": d}
	n.merge(extra, true)
	return w.add_npc(n)


func music(name: String, fade: float = 1.0) -> void:
	Sfx.music(name, fade)


func sfx(name: String, pitch: float = 1.0, db: float = -6.0) -> void:
	Sfx.play(name, pitch, db)


func flash(c: Color = Pal.WHITE, t: float = 0.3) -> void:
	await m.flash(c, t)


func shake(amt: float = 2.0, t: float = 0.5) -> void:
	m.shake(amt, t)


func lock(on: bool) -> void:
	if w:
		if on:
			w.hold("story")
		else:
			w.release("story")


func marker(tile: Vector2i) -> void:
	if w:
		w.show_marker(tile)


func unmarker() -> void:
	if w:
		w.hide_marker()


func omen_pulse() -> void:
	## The blade stirs: a violet flash, a low tone, a shiver in the picture.
	Sfx.play("omen", 1.0, -8.0)
	m.flash(Pal.OMEN, 0.35, 0.35)
	shake(1.0, 0.3)
	var r := a("player")
	if r:
		r.flash(Color(1.6, 1.2, 2.2), 0.4)


# --------------------------------------------------------- field segments --

func explore(map_def: Dictionary, tile: Vector2i, dir: int = 0) -> World:
	await m.fade_out(0.35)
	if not map_def.has("player"):
		map_def.player = "rook_sword" if Game.flag("has_sword") else "rook"
	m.load_map(map_def, tile, dir)
	if Game.run.get("mark", "") != "" and Game.flag("has_sword"):
		w.player.set_spec(rook_spec())
	# no walking while the map fades in: a key still held from the last
	# screen would move Rook before the scene can stage anyone
	w.hold("fade")
	await m.fade_in(0.35)
	w.release("fade")
	if map_def.has("name"):
		w.show_area_name()
	return w


func until(cond: Callable) -> void:
	## Lets the player roam until the condition holds (set by event handlers).
	## Automated runs let the act take its canonical next step instead.
	var idle := 0
	if w and w.locks.has("story"):
		# every act unlocks before roaming; a lock left on here leaked
		push_warning("Story: until() reached with the story lock still held; releasing it")
		w.release("story")
	roaming = true
	while not cond.call():
		await m.get_tree().process_frame
		if Game.autoplay() and is_instance_valid(w) and not w.busy and part:
			idle += 1
			if idle > 20:
				idle = 0
				# not through w.run(): the act may free this world mid-step
				var aw := w
				aw.hold("autoplay")
				await part.autoplay()
				if is_instance_valid(aw):
					aw.release("autoplay")
	# let the event that set the condition finish before the script moves on
	while is_instance_valid(w) and w.busy:
		await m.get_tree().process_frame
	roaming = false


# ------------------------------------------------------------- vignettes ---

func cine(bg: String = "", fade: float = 0.5) -> Cinema:
	var c := Cinema.open()
	# from a dark screen (after a battle, a scene card) the cutscene comes up
	# out of the dark; otherwise it dissolves in over what's there
	var dark: bool = m.fade_rect.color.a > 0.01
	c.modulate.a = 1.0 if dark else 0.0
	if bg != "":
		c.show_bg(bg, 0, 0.0)
	if dark:
		m.fade_in(fade)
	else:
		c.create_tween().tween_property(c, "modulate:a", 1.0, fade)
	await wait(fade)
	for old in m.cine_layer.get_children():
		if old is Cinema and old != c:
			old.queue_free()
	return c


func battle(def: Dictionary) -> Dictionary:
	var r: Dictionary = await m.battle(def)
	for k in r.get("killed", []):
		Game.killed(k)
	return r


func minigame(kind: String, opts: Dictionary = {}) -> Dictionary:
	return await m.minigame(kind, opts)


func party(extra: Array = []) -> Array:
	## Who fights beside Rook right now.
	var p := ["rook"]
	if Game.flag("mara_joined") and not Game.flag("mara_left") and not Game.run.kills.has("mara"):
		p.append("mara")
	if not Game.run.kills.has("fen") and Game.flag("fen_fights"):
		p.append("fen")
	for e in extra:
		if not p.has(e):
			p.append(e)
	return p


func the_end(text: String) -> void:
	## The sign-off line, over ink, before the ending card.
	var c := await cine("ink", 0.4)
	var l := Art.shadow_label(text, Pal.CREAM, 1)
	l.position = Vector2(160 - Art.text_width(text) / 2.0, 84)
	l.modulate.a = 0.0
	c.add_child(l)
	await c.create_tween().tween_property(l, "modulate:a", 1.0, 0.8).finished
	await wait(2.0 if not Game.autoplay() else 0.2)


# ------------------------------------------------------------- endings -----

func eligible() -> Array:
	## Which endings Rook's journey has earned, checked before the keystone
	## choice. Keep and Sell are always possible; the others need a pattern.
	var out := []
	var kills: Array = Game.run.get("kills", [])
	if Game.v("finesse") >= 6 and Game.v("suspicion") >= 6:
		out.append("legendary")
	if Game.v("loyalty") >= 6 and Game.flag("confessed") and Game.fval("bridge", "") == "protect" and Game.flag("mara_joined") and not Game.flag("mara_left") and not kills.has("mara"):
		out.append("honor")
	if Game.lore_count() >= 2 and Game.run.get("clues", []).size() >= 3:
		out.append("vault")
	if Game.run.get("returned", []).size() >= 2 and Game.v("refusals") >= 2 and not kills.has("fen") and not kills.has("mara"):
		out.append("empty")
	out.append("fence")
	out.append("claimed")
	return out
