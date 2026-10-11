class_name BattleUnit
extends Node2D
## One fighter on the battlefield: its numbers and its body. The body is the
## character's own chibi sprite at 2x in battle poses (idle breathing, ready,
## wind-up, strike, follow-through, hurt, guard, cast, shoot, dodge, victory,
## down). It blinks, its mouth moves when it speaks, it flashes when hit, and
## it can leave afterimages behind when it moves fast.
## When Suspicion runs high, allies flicker into violet-eyed thief shapes.

var id := ""
var uname := ""
var side := "enemy"
var spec: Dictionary = {}
var data: Dictionary = {}
var hp := 10
var max_hp := 10
var tp := 0
var max_tp := 0
var atk := 3
var def_ := 0
var spd := 8
var k := 2.0
var home := Vector2.ZERO
var mood := ""
var pose := "idle"
var frame := 0
var alive := true
var down := false
var ai := false
var hostile := false
## Buffs and ailments: name -> turns left (or charges).
var status := {}
## What this enemy means to do next (chosen at the start of each round).
var intent: Dictionary = {}
var body: Sprite2D
var shadow: Sprite2D
var ghost: Sprite2D
var t := 0.0
var blink_t := 2.0
var blinking := false
var talking := false
var talk_t := 0.0
var _pose_id := 0
var _key := ""
var lift := 0.0


func setup(p_side: String, d: Dictionary, pos: Vector2) -> void:
	side = p_side
	data = d
	id = d.get("id", "u")
	uname = d.get("name", id)
	spec = Data.spec(d.get("spec", id)).duplicate()
	if Game.run.get("mark", "") != "" and spec.get("weapon", "") == "sword":
		spec.mark = Game.run.mark
	max_hp = int(d.get("hp", 30))
	hp = int(d.get("hp_now", max_hp))
	max_tp = int(d.get("tp", 0))
	tp = max_tp
	atk = int(d.get("atk", 6))
	def_ = int(d.get("def", 1))
	spd = int(d.get("spd", 8))
	k = float(d.get("scale", 2.0))
	ai = d.get("ai", false)
	home = pos
	position = pos
	shadow = Sprite2D.new()
	var w := 30 if spec.get("kind", "human") == "human" else 40
	if spec.get("big", false):
		w = 36
	shadow.texture = Art.shadow(int(w * k / 2.0), 7)
	shadow.modulate = Color(1, 1, 1, 0.32)
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	body = Sprite2D.new()
	body.centered = false
	body.scale = Vector2(k, k)
	add_child(body)
	ghost = Sprite2D.new()
	ghost.centered = false
	ghost.scale = Vector2(k, k)
	ghost.visible = false
	add_child(ghost)
	blink_t = randf_range(1.0, 4.0)
	t = randf() * 3.0
	refresh()


func facing_left() -> bool:
	return side == "party"


func dir_sign() -> float:
	## +1 if this unit faces right (toward the party side), -1 if left.
	return -1.0 if facing_left() else 1.0


func refresh() -> void:
	var m := mood
	if blinking and pose not in ["hurt", "down"]:
		m += "+blink"
	if talking and fmod(talk_t, 0.2) < 0.1:
		m += "+open"
	var p := pose
	var f := frame
	if p == "idle" and spec.get("kind", "human") == "human":
		f = frame % 2
	var key := "%s:%d:%s" % [p, f, m]
	if key == _key:
		return
	_key = key
	body.texture = Art.person(spec, 2, f, m, p)
	body.offset = -ArtPeople.FOOT - Vector2(0, lift / k)
	body.flip_h = facing_left()
	ghost.flip_h = body.flip_h
	ghost.offset = body.offset
	if hostile and ghost.visible:
		# the same friend, washed violet, with the blade's light in their eyes
		ghost.texture = Art.person(spec, 2, f, "omen", p)
		ghost.modulate = Color(0.75, 0.5, 1.1)


func _process(delta: float) -> void:
	t += delta
	var changed := false
	blink_t -= delta
	if blink_t <= 0.0:
		blinking = not blinking
		blink_t = 0.12 if blinking else randf_range(2.0, 5.0)
		changed = true
	if talking:
		talk_t += delta
		changed = true
	if pose == "idle" or (pose == "walk" and spec.get("kind", "human") != "human"):
		# breathing: the chest rises and falls about twice a second
		var f := int(t * (2.0 if spec.get("kind", "human") == "human" else 5.0)) % 4
		if f != frame:
			frame = f
			changed = true
	if changed:
		refresh()
	if hostile and alive:
		# now and then the blade shows Rook what this friend "really" is
		var on := fmod(t + id.hash() % 7, 4.0) < 0.45
		if on != ghost.visible:
			ghost.visible = on
			_key = ""
			refresh()
	elif ghost.visible:
		ghost.visible = false


func set_pose(p: String, hold: float = 0.0) -> void:
	## Change pose; with hold > 0, return to idle afterwards (unless something
	## else changed the pose in the meantime).
	_pose_id += 1
	var my := _pose_id
	pose = p
	frame = 0
	_key = ""
	refresh()
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout
		if my == _pose_id and is_inside_tree() and alive and not down:
			pose = "idle"
			_key = ""
			refresh()


func set_mood(m: String) -> void:
	mood = m
	_key = ""
	refresh()


func set_hostile(on: bool) -> void:
	hostile = on
	if not on:
		ghost.visible = false


func set_lift(v: float) -> void:
	lift = v
	body.offset.y = -ArtPeople.FOOT.y - lift / k
	ghost.offset = body.offset


func center() -> Vector2:
	## Middle of the body, in battle coordinates.
	var h := 28.0 if spec.get("kind", "human") == "human" else 18.0
	if spec.get("tall", false):
		h = 32.0
	return position + Vector2(0, -h * k * 0.5)


func head() -> Vector2:
	var h := 30.0 if spec.get("kind", "human") == "human" else 22.0
	if spec.get("tall", false):
		h = 33.0
	return position + Vector2(0, -h * k)


func weapon_tip() -> Vector2:
	## Roughly where the weapon's point is in the current pose.
	return center() + Vector2(dir_sign() * 14.0 * k, -4.0)


func flash(c: Color = Color(4, 4, 4), t_: float = 0.14) -> void:
	body.modulate = c
	create_tween().tween_property(body, "modulate", Color.WHITE, t_)


func afterimage(c: Color = Pal.SKY, life: float = 0.28) -> void:
	## A fading copy of the current frame left behind where the body is.
	var parent := get_parent()
	if parent == null:
		return
	var g := Sprite2D.new()
	g.centered = false
	g.texture = Art.silhouette(spec, 2, frame if pose == "idle" else 0, mood, pose, c)
	g.scale = body.scale
	g.offset = body.offset
	g.flip_h = body.flip_h
	g.position = position
	g.modulate.a = 0.45
	g.z_index = z_index - 1
	parent.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, life)
	tw.tween_callback(g.queue_free)


func squash(x: float, y: float, t_: float = 0.16) -> void:
	if Game.reduced_motion():
		return
	body.scale = Vector2(k * x, k * y)
	ghost.scale = body.scale
	var tw := create_tween()
	tw.tween_property(body, "scale", Vector2(k, k), t_).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ghost, "scale", Vector2(k, k), t_)


func has(s: String) -> bool:
	return int(status.get(s, 0)) > 0


func tick_status() -> void:
	for s in status.keys():
		if s in ["counter", "covered", "caltrops"]:
			continue
		status[s] = int(status[s]) - 1
		if int(status[s]) <= 0:
			status.erase(s)


func eff_atk() -> int:
	var a := float(atk)
	if has("rallied"):
		a *= 1.3
	if has("weak"):
		a *= 0.7
	return int(round(a))


func eff_def() -> int:
	var d := float(def_)
	if has("exposed"):
		d *= 0.3
	if has("guarding"):
		d = d * 2.0 + 3.0
	return int(round(d))
