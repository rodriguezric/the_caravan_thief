class_name Actor
extends Node2D
## A character on the field. Origin = feet. Scripted scenes drive it with
## walk_to / hop / emote / gesture and friends; the field drives the player
## with input. Everything an actor does is visible: mouths move while they
## talk, they blink, nod, shake their heads, jump back in alarm, tremble,
## kneel, point, sneak, and kick up dust when they run.

const DIRS := [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]

var spec: Dictionary = {}
var dir := 0
var frame := 0
var moving := false
var anim_t := 0.0
var sprite: Sprite2D
var shadow: Sprite2D
var info: Dictionary = {}
var home_tile := Vector2i.ZERO
var walk_target: Variant = null
var wander_t := 0.0
var mood := ""
var pose := "walk"
var bubble: Sprite2D
var lift := 0.0
var walk_speed := 50.0
var walk_id := 0
## True while a script is walking this actor; the field leaves its animation alone.
var scripted := false
## Idle blinking: counts down to the next blink, then holds the eyes shut briefly.
var blink_t := 0.0
var blinking := false
## Mouth flaps while this actor's line is being typed.
var talking := false
var talk_t := 0.0
var mouth_open := false
## Poses that loop their own frames (waving, sneaking in place).
var pose_anim := false
var dust_t := 0.0
var _gesture_id := 0
var _key := ""


func _init(p_spec: Dictionary = {}) -> void:
	spec = p_spec
	shadow = Sprite2D.new()
	var kind: String = spec.get("kind", "human")
	var sw := 14
	if kind == "ox":
		sw = 30
	elif kind == "jackal":
		sw = 18
	elif kind == "crow":
		sw = 8
	elif spec.get("big", false):
		sw = 17
	shadow.texture = Art.shadow(sw, 5 if kind != "crow" else 3)
	shadow.modulate = Color(1, 1, 1, 0.28)
	shadow.position = Vector2(0, -1)
	shadow.visible = not spec.get("ghost", false)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	wander_t = randf_range(1.0, 3.0)
	blink_t = randf_range(1.5, 4.5)
	refresh()


func set_spec(s: Dictionary) -> void:
	spec = s
	refresh()


func face(d: int) -> void:
	if d != dir:
		dir = d
		refresh()


func face_toward(p: Vector2) -> void:
	var v := p - position
	if absf(v.x) > absf(v.y):
		face(2 if v.x > 0 else 3)
	else:
		face(0 if v.y > 0 else 1)


func set_mood(m: String) -> void:
	if m == mood:
		return
	mood = m
	refresh()
	# a mood change gets a tiny squash, so it reads at field size
	if not Game.reduced_motion():
		sprite.scale = Vector2(1.12, 0.9)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)


func set_pose(p: String) -> void:
	pose = p
	pose_anim = p in ["wave", "sneak", "run"]
	refresh()


func refresh() -> void:
	var td: int = [0, 1, 2, 2][dir]
	var m := mood
	if blinking:
		m += "+blink"
	if mouth_open:
		m += "+open"
	var f := frame if pose in ["walk", "run", "sneak", "wave"] or spec.get("kind", "human") != "human" else 0
	var key := "%d:%d:%s:%s" % [td, f, m, pose]
	if key == _key and sprite.texture != null:
		sprite.flip_h = dir == 3
		return
	_key = key
	sprite.texture = Art.person(spec, td, f, m, pose)
	sprite.offset = -ArtPeople.FOOT - Vector2(0, lift)
	sprite.flip_h = dir == 3


func _process(delta: float) -> void:
	_blink(delta)
	if talking:
		talk_t += delta
		var o := fmod(talk_t, 0.2) < 0.1
		if o != mouth_open:
			mouth_open = o
			refresh()
	elif mouth_open:
		mouth_open = false
		refresh()
	if moving or pose_anim or spec.get("kind", "") == "crow" and spec.get("flying", false):
		anim_t += delta * (8.0 if pose != "wave" else 4.0)
		var f := int(anim_t) % 4
		if f != frame:
			frame = f
			refresh()
	elif frame != 0:
		frame = 0
		anim_t = 0.0
		refresh()


func _blink(delta: float) -> void:
	## Every so often the eyes close for a moment; now and then twice in a row.
	if dir == 1 or mood in ["closed", "sleep", "hurt", "laugh"] or pose == "lie":
		if blinking:
			blinking = false
			refresh()
		return
	blink_t -= delta
	if blink_t > 0.0:
		return
	blinking = not blinking
	if blinking:
		blink_t = 0.12
	else:
		blink_t = 0.18 if randf() < 0.15 else randf_range(2.0, 5.0)
	refresh()


# ------------------------------------------------------------- scripting ---

func stop_walk() -> void:
	walk_id += 1
	moving = false
	scripted = false


func walk_to(points: Array, speed: float = -1.0) -> bool:
	## Walks through world positions (Vector2) in order. Returns false if
	## another walk (or stop_walk) interrupted it. Fast walks run, with dust.
	if speed < 0.0:
		speed = walk_speed
	walk_id += 1
	var my := walk_id
	scripted = true
	var was_pose := pose
	if speed >= 75.0 and pose == "walk":
		set_pose("run")
	for p in points:
		var target: Vector2 = p
		while position.distance_to(target) > 0.5:
			if my != walk_id or not is_inside_tree():
				if my == walk_id:
					scripted = false
				return false
			var v := target - position
			if absf(v.x) > absf(v.y):
				face(2 if v.x > 0 else 3)
			else:
				face(0 if v.y > 0 else 1)
			moving = true
			var dt := get_process_delta_time()
			var step := minf(speed * dt, v.length())
			position += v.normalized() * step
			if speed >= 75.0:
				dust_t -= dt
				if dust_t <= 0.0:
					dust_t = 0.12
					dust()
			await get_tree().process_frame
		if my != walk_id:
			return false
		position = target
	moving = false
	scripted = false
	if pose == "run" and was_pose == "walk":
		set_pose("walk")
	return true


func dust(n: int = 3) -> void:
	## Little puffs of road dust at the feet.
	var parent := get_parent()
	if parent == null:
		return
	for i in n:
		var d := Sprite2D.new()
		d.texture = Art.shadow(4, 3)
		d.modulate = Color(Pal.SAND.lerp(Pal.CREAM, 0.4), 0.55)
		d.position = position + Vector2(randf_range(-4, 4), -1)
		d.z_index = -1
		parent.add_child(d)
		var tw := d.create_tween().set_parallel(true)
		tw.tween_property(d, "position", d.position + Vector2(randf_range(-6, 6), randf_range(-5, -2)), 0.35)
		tw.tween_property(d, "modulate:a", 0.0, 0.35)
		tw.chain().tween_callback(d.queue_free)


func hop(height: float = 4.0, t: float = 0.22) -> void:
	var tw := create_tween()
	tw.tween_method(_set_lift, 0.0, height, t * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_lift, height, 0.0, t * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if height >= 6.0:
		land()


func land() -> void:
	## Squash on landing, then spring back.
	if Game.reduced_motion():
		return
	sprite.scale = Vector2(1.18, 0.84)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dust(2)


func _set_lift(v: float) -> void:
	lift = v
	sprite.offset.y = -ArtPeople.FOOT.y - lift


func jump_back(dist: float = 10.0) -> void:
	## Startled: a hop backwards, away from where they're facing.
	var away: Vector2 = -DIRS[dir] * dist
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position", position + away, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_lift, 0.0, 5.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_method(_set_lift, 5.0, 0.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	land()


func lunge(dist: float = 6.0) -> void:
	## A sudden step toward where they face, and back: grabbing, threatening.
	var to: Vector2 = DIRS[dir] * dist
	var tw := create_tween()
	tw.tween_property(sprite, "position", to, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.12)
	tw.tween_property(sprite, "position", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_SINE)
	await tw.finished


func nod(times: int = 2) -> void:
	for i in times:
		sprite.position.y = 1
		await get_tree().create_timer(0.11).timeout
		sprite.position.y = 0
		await get_tree().create_timer(0.11).timeout


func shake_head(times: int = 2) -> void:
	## Looks left and right, quickly, then back.
	var was := dir
	if was == 1:
		return
	for i in times:
		face(2)
		await get_tree().create_timer(0.1).timeout
		face(3)
		await get_tree().create_timer(0.1).timeout
	face(was)


func look_around(times: int = 1) -> void:
	var was := dir
	for i in times:
		face(3)
		await get_tree().create_timer(0.35).timeout
		face(2)
		await get_tree().create_timer(0.35).timeout
		face(0)
		await get_tree().create_timer(0.25).timeout
	face(was)


func tremble(t: float = 0.6) -> void:
	if Game.reduced_motion():
		return
	var tw := create_tween()
	var n := int(t / 0.05)
	for i in n:
		tw.tween_property(sprite, "position:x", 0.5 * (1 if i % 2 == 0 else -1), 0.05)
	tw.tween_property(sprite, "position:x", 0.0, 0.05)
	await tw.finished


func sigh() -> void:
	## Shoulders drop a pixel, a "..." bubble, then back.
	var was := pose
	set_pose("slump")
	emote("...", 0.8)
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		set_pose(was if was != "slump" else "walk")


func spin(times: int = 1) -> void:
	for i in times:
		for d in [2, 1, 3, 0]:
			face(d)
			await get_tree().create_timer(0.07).timeout


func gesture(p: String, hold: float = 1.0, back_to: String = "walk") -> void:
	## Strike a pose for a moment (point, shrug, think, bow, fist...), with a
	## small pop so it reads, then return to standing. Doesn't block unless
	## awaited; a newer gesture cancels the return of an older one.
	_gesture_id += 1
	var my := _gesture_id
	set_pose(p)
	if not Game.reduced_motion():
		sprite.scale = Vector2(0.92, 1.1)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
	if hold <= 0.0:
		return
	await get_tree().create_timer(hold).timeout
	if my == _gesture_id and is_inside_tree() and pose == p:
		set_pose(back_to)


func emote(kind: String, hold: float = 1.2) -> void:
	## Pops a bubble over the head; doesn't block.
	if bubble:
		bubble.queue_free()
	bubble = Sprite2D.new()
	bubble.texture = Art.ui("emote_" + kind)
	var top := -38.0 if not spec.get("tall", false) else -40.0
	if spec.get("kind", "human") == "ox":
		top = -30.0
	elif spec.get("kind", "human") in ["crow", "jackal"]:
		top = -24.0
	bubble.position = Vector2(6, top)
	bubble.z_index = 20
	add_child(bubble)
	bubble.scale = Vector2(0.2, 0.2)
	var b := bubble
	Sfx.play("pop", 1.0 + randf() * 0.2, -14.0)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.25, 1.25), 0.08)
	tw.tween_property(b, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(hold)
	tw.tween_property(b, "modulate:a", 0.0, 0.2)
	tw.tween_callback(b.queue_free)


func shake(t: float = 0.3, amp: float = 1.0) -> void:
	if Game.reduced_motion():
		return
	var tw := create_tween()
	var n := int(t / 0.04)
	for i in n:
		tw.tween_property(sprite, "position:x", amp * (1 if i % 2 == 0 else -1), 0.04)
	tw.tween_property(sprite, "position:x", 0.0, 0.04)


func afterimage_field(c: Color = Pal.SKY, life: float = 0.35) -> void:
	## A fading silhouette left where the actor stood (dodges, dashes).
	var parent := get_parent()
	if parent == null:
		return
	var g := Sprite2D.new()
	g.centered = false
	g.texture = Art.silhouette(spec, [0, 1, 2, 2][dir], frame, mood, pose, c)
	g.offset = sprite.offset
	g.flip_h = sprite.flip_h
	g.position = position
	g.scale = scale
	g.modulate.a = 0.6
	parent.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, life)
	tw.tween_callback(g.queue_free)


func flash(c: Color = Color(3, 3, 3), t: float = 0.15) -> void:
	sprite.modulate = c
	create_tween().tween_property(sprite, "modulate", Color.WHITE, t)


func fade(to: float, t: float = 0.4) -> void:
	await create_tween().tween_property(self, "modulate:a", to, t).finished
