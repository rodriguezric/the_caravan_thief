class_name Cinema
extends Control
## Full-screen story vignettes over the field. Backdrops crossfade, and the
## people in them are real Actors (usually at 2x), so they blink, talk, walk,
## gesture and emote exactly as they do on the field. Procedural effects
## (embers, blowing sand, the blade's violet motes, stars, falling ash) play
## beneath the dialog box, and a dithered ink vignette can close in on a moment.

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float radius = 1.4;
uniform vec4 tint : source_color = vec4(0.106, 0.075, 0.125, 1.0);
void fragment() {
	vec2 p = floor(FRAGCOORD.xy);
	vec2 c = vec2(160.0, 90.0);
	vec2 d = (p - c) / vec2(160.0, 130.0);
	float r = length(d);
	float edge = step(radius, r);
	float dither = step(radius - 0.06, r) * step(0.5, fract((p.x + p.y) / 4.0));
	COLOR = vec4(tint.rgb, max(edge, dither));
}
"""

var bg: TextureRect
var back: ColorRect
## Everything that scrolls up while the dialog box is open (so the people in
## the vignette stay visible above it), as the field camera does.
var view: Control
var lift := 0.0
var actors: Node2D
var front: Node2D
var drawer: Node2D
var vig: ColorRect
var t := 0.0
var effect := ""
var effect_k := 0.5
var particles: Array = []
var anim_bg := ""
var anim_frames := 0
var anim_fps := 0.0
var cast := {}
var letterbox: Array = []


static func open(color: Color = Pal.INK) -> Cinema:
	var c := Cinema.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.back = ColorRect.new()
	c.back.color = color
	c.back.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(c.back)
	c.view = Control.new()
	c.view.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(c.view)
	c.bg = TextureRect.new()
	c.view.add_child(c.bg)
	c.drawer = Node2D.new()
	c.view.add_child(c.drawer)
	c.actors = Node2D.new()
	c.actors.y_sort_enabled = true
	c.view.add_child(c.actors)
	c.front = Node2D.new()
	c.view.add_child(c.front)
	c.drawer.draw.connect(c._draw_fx)
	c.vig = ColorRect.new()
	c.vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("radius", 1.4)
	c.vig.material = mat
	c.add_child(c.vig)
	Game.main.cine_layer.add_child(c)
	return c


func set_vignette(r: float, t_: float = 0.0) -> void:
	var mat := vig.material as ShaderMaterial
	if t_ <= 0.0:
		mat.set_shader_parameter("radius", r)
		return
	var cur = mat.get_shader_parameter("radius")
	var from: float = cur if cur != null else 1.2
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("radius", v), from, r, t_).set_trans(Tween.TRANS_SINE)
	await tw.finished


func letterbox_on() -> bool:
	return not letterbox.is_empty() and (letterbox[0] as ColorRect).position.y > -10.0


func bars(on: bool, t_: float = 0.4) -> void:
	## Cinematic letterbox bars sliding in from top and bottom.
	if letterbox.is_empty():
		for k in 2:
			var r := ColorRect.new()
			r.color = Pal.INK
			r.size = Vector2(320, 18)
			r.position = Vector2(0, -18 if k == 0 else 180)
			add_child(r)
			letterbox.append(r)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(letterbox[0], "position:y", 0.0 if on else -18.0, t_).set_trans(Tween.TRANS_SINE)
	tw.tween_property(letterbox[1], "position:y", 162.0 if on else 180.0, t_).set_trans(Tween.TRANS_SINE)
	await tw.finished


func show_bg(name: String, frame: int = 0, fade: float = 0.5) -> void:
	var tex := Art.cine(name, frame)
	if fade <= 0.0 or bg.texture == null:
		bg.texture = tex
		bg.modulate.a = 1.0
		if fade > 0.0:
			bg.modulate.a = 0.0
			await create_tween().tween_property(bg, "modulate:a", 1.0, fade).finished
		return
	var nb := TextureRect.new()
	nb.texture = tex
	nb.modulate.a = 0.0
	view.add_child(nb)
	view.move_child(nb, bg.get_index() + 1)
	await create_tween().tween_property(nb, "modulate:a", 1.0, fade).finished
	bg.queue_free()
	bg = nb


func animate_bg(name: String, frames: int, fps: float) -> void:
	anim_bg = name
	anim_frames = frames
	anim_fps = fps


func sprite(tex: Texture2D, pos: Vector2, bob: float = 0.0, on_top: bool = false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	if bob > 0.0:
		s.set_meta("bob", bob)
		s.set_meta("y", pos.y)
		s.set_meta("ph", randf() * TAU)
	(front if on_top else actors).add_child(s)
	return s


func person(id: String, pos: Vector2, dir: int = 0, mood: String = "", pose: String = "walk", k: float = 2.0) -> Actor:
	## Puts a real Actor in the vignette (by cast id or spec id), registered
	## under its id so story lines can make its mouth move.
	var spec := Data.spec(id)
	var a := Actor.new(spec)
	a.position = pos
	a.scale = Vector2(k, k)
	a.face(dir)
	a.mood = mood
	a.set_pose(pose)
	a.refresh()
	actors.add_child(a)
	cast[str(spec.get("id", id))] = a
	return a


func get_actor(id: String) -> Actor:
	var a: Actor = cast.get(id, null)
	if a != null and is_instance_valid(a):
		return a
	return null


func walk(a: Actor, to: Vector2, speed: float = 40.0) -> void:
	## Walks in vignette space (speed in screen pixels per second).
	if a == null:
		return
	await a.walk_to([to], speed / a.scale.x)


func move(s: Node2D, to: Vector2, t_: float, trans: int = Tween.TRANS_SINE) -> void:
	if s.has_meta("bob"):
		s.set_meta("y", to.y)
	var tw := create_tween()
	tw.tween_property(s, "position", to, t_).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func clear_sprites() -> void:
	for c in actors.get_children():
		c.queue_free()
	cast.clear()


func fade_node(n: CanvasItem, a: float, t_: float) -> void:
	await create_tween().tween_property(n, "modulate:a", a, t_).finished


func close(fade: float = 0.5) -> void:
	await create_tween().tween_property(self, "modulate:a", 0.0, fade).finished
	queue_free()


func _process(delta: float) -> void:
	t += delta
	var want := 30.0 if Game.main.dialog.visible and not letterbox_on() else 0.0
	lift = want if Game.reduced_motion() else move_toward(lift, want, delta * 110.0)
	view.position.y = -round(lift)
	if anim_bg != "":
		bg.texture = Art.cine(anim_bg, int(t * anim_fps) % anim_frames)
	for s in actors.get_children() + front.get_children():
		if s.has_meta("bob"):
			s.position.y = s.get_meta("y") + round(sin(t * 1.6 + s.get_meta("ph")) * s.get_meta("bob"))
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.t += delta
		p.pos += p.vel * delta
		if p.t > p.life:
			particles.remove_at(i)
	if effect != "":
		_spawn_particles(delta)
	drawer.queue_redraw()


func _spawn_particles(delta: float) -> void:
	var rate := effect_k * 40.0
	var n := int(rate * delta) + (1 if randf() < fmod(rate * delta, 1.0) else 0)
	for i in n:
		match effect:
			"stars":
				particles.append({"pos": Vector2(randf() * 320, randf() * 120), "vel": Vector2.ZERO, "t": 0.0, "life": 2.0, "c": Pal.WHITE, "kind": "twinkle"})
			"embers":
				particles.append({"pos": Vector2(randf_range(60, 260), 182), "vel": Vector2(randf_range(-8, 8), -randf_range(14, 34)), "t": 0.0, "life": 5.0,
					"c": Pal.CANDLE if randf() < 0.6 else Pal.LEMON, "kind": "dot"})
			"fire":
				particles.append({"pos": Vector2(randf_range(150, 170), 150), "vel": Vector2(randf_range(-6, 6), -randf_range(20, 40)), "t": 0.0, "life": 2.0,
					"c": Pal.CANDLE if randf() < 0.6 else Pal.LEMON, "kind": "dot"})
			"sand":
				particles.append({"pos": Vector2(-4, randf() * 180), "vel": Vector2(randf_range(120, 220), randf_range(-6, 10)), "t": 0.0, "life": 2.6,
					"c": Pal.SAND.lerp(Pal.CREAM, randf() * 0.5), "kind": "streak"})
			"omen":
				particles.append({"pos": Vector2(randf() * 320, randf_range(60, 182)), "vel": Vector2(randf_range(-6, 6), -randf_range(8, 22)), "t": 0.0, "life": 3.0,
					"c": Pal.OMEN if randf() < 0.7 else Pal.WHITE, "kind": "dot"})
			"dust":
				particles.append({"pos": Vector2(randf() * 320, randf() * 180), "vel": Vector2(randf_range(4, 12), randf_range(-2, 2)), "t": 0.0, "life": 4.0,
					"c": Pal.CREAM, "kind": "dot"})
			"ash":
				particles.append({"pos": Vector2(randf() * 320, -2), "vel": Vector2(randf_range(-6, 6), randf_range(10, 22)), "t": 0.0, "life": 9.0,
					"c": Pal.STONE.lerp(Pal.WHITE, randf() * 0.5), "kind": "dot"})
			"fireflies":
				particles.append({"pos": Vector2(randf() * 320, randf_range(90, 170)), "vel": Vector2(randf_range(-4, 4), randf_range(-4, 4)), "t": 0.0, "life": 3.0,
					"c": Pal.LEMON, "kind": "dot"})


func _draw_fx() -> void:
	for p in particles:
		var k: float = p.t / p.life
		var c: Color = p.c
		match p.kind:
			"streak":
				var v: Vector2 = p.vel
				drawer.draw_line(p.pos.round(), (p.pos - v * 0.04).round(), Color(c, 0.6 * (1.0 - k)), 1.0)
			"twinkle":
				drawer.draw_rect(Rect2(p.pos.round(), Vector2.ONE), Color(c, sin(k * PI)))
			_:
				drawer.draw_rect(Rect2(p.pos.round(), Vector2.ONE), Color(c, sin(k * PI)))
