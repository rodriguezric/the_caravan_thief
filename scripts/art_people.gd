class_name ArtPeople
## One renderer for every humanoid (the chibi rig from Protektor/Greywater),
## extended with action poses and held weapons so cutscenes and battles can
## act instead of stand. Thieves, scouts and custodians are just data: colours,
## a hair style, clothes, accessories and a weapon.
## Specs with a "kind" other than "human" (jackal, crow, ox) go to
## ArtCreatures, which follows the same canvas, origin and rules.
##
## Canvas: 48 x 40, feet at (24, 36). The extra room around the classic 32 x 32
## figure is for blades, spears and bows. Origin for placement is FOOT.
## dir: 0 = down, 1 = up, 2 = side: a three-quarter view turned to the right
## (flipped for left). frame: 0..3 walk cycle (or a pose's own frames).
## mood changes only the face (see _face). pose: see POSES.

const W := 48
const H := 40
const CX := 24.0
const BY := 36.0
const FOOT := Vector2(24, 37)
const HEAD_K := 1.28
## Hair cut close enough to show the head's shape from every side.
const SHORT_STYLES := ["short", "spiky", "messy", "slick", "bun", "cropped"]
## Poses the renderer understands. Battle poses are side-view; cutscene
## gestures work front and side.
const POSES := ["walk", "run", "sneak", "sit", "lie", "kneel", "crouch", "idle", "ready", "windup", "strike", "follow",
	"thrust", "hurt", "guard", "cast", "throw", "shoot", "aim", "dodge", "victory", "point", "cross", "hips", "shrug",
	"think", "wave", "reach", "cower", "facepalm", "laugh", "bow", "hold_up", "pick", "carry", "slump", "fist"]


static func render(s: Dictionary, dir: int, frame: int, mood: String = "", pose: String = "walk") -> PixBuf:
	if s.get("kind", "human") != "human":
		return ArtCreatures.render(s, dir, frame, mood, pose)
	if pose == "lie" or pose == "down":
		return _lying(s, dir, frame, mood)
	var b := PixBuf.new(W, H)
	_draw(b, s, dir, frame, mood, pose)
	b.outline()
	if s.get("ghost", false):
		_ghostly(b)
	return b


static func _lying(s: Dictionary, dir: int, frame: int, mood: String) -> PixBuf:
	## Knocked down or asleep: the standing figure turned on its side, settled
	## onto the baseline.
	var tmp := PixBuf.new(48, 48)
	var m := mood if mood != "" else "closed"
	_draw(tmp, s, 0 if dir == 1 else dir, 0, m, "lie_src")
	tmp.outline()
	tmp.img.rotate_90(COUNTERCLOCKWISE)
	var used := tmp.img.get_used_rect()
	var b := PixBuf.new(W, H)
	var ox := int(CX - used.size.x / 2.0) - used.position.x
	var oy := int(BY) - (used.position.y + used.size.y - 1)
	b.blit(tmp, ox, oy)
	if s.get("ghost", false):
		_ghostly(b)
	return b


static func _ghostly(b: PixBuf) -> void:
	b.recolor(func(x: int, y: int, c: Color) -> Color:
		var l := c.get_luminance()
		var g := Pal.OMEN.lerp(Pal.NAVY, 0.6 - l * 0.6)
		return Color(g, 0.75 if (x + y) % 2 == 0 or l > 0.4 else 0.5))


# --------------------------------------------------------------- pose data --

static func _params(pose: String, dir: int, frame: int, s: Dictionary) -> Dictionary:
	## Where everything goes for a pose. Coordinates are offsets from the feet
	## centre (CX, BY); in the side view +x is forward. near/far are the hands
	## in the side view; lh/rh in the front view (viewer's left/right).
	## Returns lean (upper body forward), crouch (whole figure lower), legs
	## mode, hands, optional elbows, weapon angle (radians, 0 = forward) and
	## which hand holds it.
	var side := dir == 2
	var p := {"lean": 0.0, "crouch": 0.0, "bob": 0.0, "legs": "stand", "step": 0, "head_dx": 0.0, "head_dy": 0.0,
		"near": Vector2(-3.6, -3.8), "far": Vector2(3.4, -3.8), "lh": Vector2(-4.8, -3.8), "rh": Vector2(4.8, -3.8),
		"wpn": NAN, "whand": "near", "swing": 0.0, "mood": "", "bow_draw": 0.0}
	var swing := 0.0
	if pose in ["walk", "run", "sneak"]:
		if frame == 1:
			p.step = 1
			p.bob = -1.0
			swing = 1.0
		elif frame == 3:
			p.step = 3
			p.bob = -1.0
			swing = -1.0
	var k := 1.8 if pose == "run" else 1.0
	p.near = Vector2(-3.6 + swing * k, -3.8)
	p.far = Vector2(3.4 - swing * k, -3.8)
	p.lh = Vector2(-4.8, -3.8 + swing)
	p.rh = Vector2(4.8, -3.8 - swing)
	p.swing = swing
	var wk: String = s.get("weapon", "")
	match pose:
		"run":
			p.lean = 1.0
		"sneak":
			p.crouch = 2.0
			p.lean = 1.0
			p.near = Vector2(2.0 + swing, -5.5)
			p.far = Vector2(4.5 - swing, -5.0)
			p.lh = Vector2(-4.0, -5.5)
			p.rh = Vector2(4.0, -5.5)
		"crouch":
			p.crouch = 3.0
			p.legs = "crouch"
			p.near = Vector2(2.0, -4.0)
			p.far = Vector2(4.0, -3.5)
			p.lh = Vector2(-3.5, -4.0)
			p.rh = Vector2(3.5, -4.0)
		"kneel":
			p.crouch = 3.0
			p.legs = "kneel"
			p.near = Vector2(1.5, -5.0)
			p.far = Vector2(3.5, -4.0)
			p.lh = Vector2(-3.0, -4.5)
			p.rh = Vector2(3.0, -4.5)
		"sit":
			p.crouch = 1.0
			p.legs = "sit"
			p.near = Vector2(-1.5, -4.0)
			p.far = Vector2(2.6, -3.6)
			p.lh = Vector2(-2.6, -3.6)
			p.rh = Vector2(2.6, -3.6)
		"lie_src":
			p.near = Vector2(-4.2, -3.6)
			p.far = Vector2(3.6, -3.6)
		"idle":
			# battle stance: weapon out, breathing on frames 0/1
			p.bob = 1.0 if frame % 2 == 1 else 0.0
			p.legs = "stride_small"
			p.near = Vector2(2.0, -4.6)
			p.far = Vector2(4.0, -5.0)
			p.wpn = -0.9
		"ready":
			p.crouch = 1.0
			p.lean = 1.0
			p.legs = "stride"
			p.near = Vector2(4.0, -5.5)
			p.far = Vector2(5.0, -5.0)
			p.wpn = -0.35
		"windup":
			p.lean = -1.0
			p.legs = "stride"
			p.near = Vector2(-5.5, -10.0)
			p.far = Vector2(3.0, -6.0)
			p.wpn = -2.5
		"strike":
			p.lean = 2.0
			p.crouch = 1.0
			p.legs = "lunge"
			p.near = Vector2(8.0, -6.5)
			p.far = Vector2(-1.0, -5.5)
			p.wpn = 0.1
		"follow":
			p.lean = 2.0
			p.crouch = 1.0
			p.legs = "lunge"
			p.near = Vector2(6.0, -2.5)
			p.far = Vector2(-1.5, -6.0)
			p.wpn = 1.1
		"thrust":
			p.lean = 3.0
			p.crouch = 1.0
			p.legs = "lunge"
			p.near = Vector2(9.0, -6.0)
			p.far = Vector2(6.0, -6.0)
			p.wpn = 0.0
		"hurt":
			p.lean = -2.0
			p.head_dy = -1.0
			p.legs = "stride_back"
			p.near = Vector2(-5.5, -6.5)
			p.far = Vector2(0.0, -9.0)
			p.lh = Vector2(-6.0, -7.0)
			p.rh = Vector2(6.0, -7.0)
			p.mood = "hurt"
			p.wpn = -2.0
		"guard":
			p.crouch = 1.0
			p.legs = "stride"
			p.near = Vector2(4.5, -8.0)
			p.far = Vector2(5.0, -6.0)
			p.wpn = -1.45
		"cast":
			p.lean = 0.0
			p.legs = "stride_small"
			p.near = Vector2(4.0, -13.0)
			p.far = Vector2(3.0, -5.0)
			p.lh = Vector2(-5.5, -12.0)
			p.rh = Vector2(5.5, -12.0)
		"throw":
			p.lean = 2.0
			p.legs = "lunge"
			p.near = Vector2(9.0, -7.0)
			p.far = Vector2(-2.0, -6.0)
		"shoot", "aim":
			# bow held out front in the far hand, string drawn to the cheek
			p.legs = "stride"
			p.far = Vector2(8.0, -8.0)
			p.near = Vector2(-1.0 if pose == "aim" else 3.0, -8.5)
			p.whand = "far"
			p.wpn = -1.5708
			p.bow_draw = 1.0 if pose == "aim" else 0.2
		"dodge":
			p.lean = -3.0
			p.legs = "stride_back"
			p.near = Vector2(-6.0, -5.0)
			p.far = Vector2(3.0, -7.0)
			p.wpn = -1.2
		"victory":
			p.near = Vector2(1.0, -15.0)
			p.far = Vector2(4.0, -4.0)
			p.lh = Vector2(-5.0, -4.0)
			p.rh = Vector2(5.0, -14.0)
			p.wpn = -1.5708
			p.mood = "grin"
		"point":
			p.near = Vector2(9.0, -8.5)
			p.rh = Vector2(8.0, -8.0)
			p.lh = Vector2(-4.8, -3.8)
		"reach":
			p.lean = 1.0
			p.near = Vector2(9.5, -7.0)
			p.far = Vector2(7.0, -7.5)
			p.rh = Vector2(5.0, -9.0)
			p.lh = Vector2(-5.0, -9.0)
		"cross":
			p.near = Vector2(1.5, -6.0)
			p.far = Vector2(2.5, -6.5)
			p.lh = Vector2(1.5, -6.0)
			p.rh = Vector2(-1.5, -6.5)
		"hips":
			p.near = Vector2(-2.5, -4.6)
			p.far = Vector2(2.5, -4.6)
			p.lh = Vector2(-3.4, -4.4)
			p.rh = Vector2(3.4, -4.4)
			p.elbow_out = true
		"shrug":
			p.head_dx = 0.0
			p.near = Vector2(-6.0, -8.0)
			p.far = Vector2(5.0, -8.0)
			p.lh = Vector2(-7.0, -8.0)
			p.rh = Vector2(7.0, -8.0)
		"think":
			p.near = Vector2(3.5, -9.5)
			p.far = Vector2(2.0, -5.0)
			p.rh = Vector2(1.6, -9.6)
			p.lh = Vector2(1.0, -5.6)
			p.head_dy = 0.0
		"wave":
			var wv := 1.0 if frame % 2 == 1 else 0.0
			p.near = Vector2(4.0 + wv, -14.0)
			p.rh = Vector2(6.0 + wv, -13.5)
		"cower":
			p.crouch = 3.0
			p.legs = "crouch"
			p.near = Vector2(1.0, -12.0)
			p.far = Vector2(3.0, -12.5)
			p.lh = Vector2(-4.0, -12.5)
			p.rh = Vector2(4.0, -12.5)
			p.mood = "scared"
		"facepalm":
			p.head_dy = 1.0
			p.near = Vector2(2.5, -12.0)
			p.rh = Vector2(0.5, -12.0)
		"laugh":
			p.head_dy = -1.0
			p.near = Vector2(1.0, -4.5)
			p.far = Vector2(3.0, -4.5)
			p.lh = Vector2(-2.6, -4.6)
			p.rh = Vector2(2.6, -4.6)
			p.mood = "laugh"
		"bow":
			# a showman's bow: torso and head dip forward, one arm sweeps out
			p.lean = 3.0
			p.head_dy = 3.0
			p.crouch = 1.0
			p.legs = "stride"
			p.near = Vector2(-6.5, -3.0)
			p.far = Vector2(3.0, -6.0)
			p.lh = Vector2(-7.5, -3.0)
			p.rh = Vector2(1.0, -6.5)
		"hold_up":
			p.near = Vector2(4.0, -11.0)
			p.far = Vector2(3.0, -10.0)
			p.rh = Vector2(4.0, -11.0)
			p.wpn = -1.45
			p.whand = "near"
		"pick":
			p.crouch = 2.0
			p.lean = 2.0
			p.legs = "crouch"
			p.near = Vector2(7.0, -6.0)
			p.far = Vector2(6.0, -5.0)
			p.lh = Vector2(-2.0, -6.0)
			p.rh = Vector2(2.0, -6.0)
		"carry":
			p.near = Vector2(4.0, -9.0)
			p.far = Vector2(5.0, -9.0)
			p.lh = Vector2(-4.0, -9.5)
			p.rh = Vector2(4.0, -9.5)
		"slump":
			p.head_dy = 1.5
			p.crouch = 1.0
			p.near = Vector2(-3.0, -2.6)
			p.far = Vector2(3.0, -2.6)
			p.lh = Vector2(-4.0, -2.4)
			p.rh = Vector2(4.0, -2.4)
		"fist":
			p.near = Vector2(3.0, -10.5)
			p.rh = Vector2(4.5, -11.0)
			p.mood = "determined"
	# weapons that are only shown in action poses
	if wk == "" or wk == "none":
		p.wpn = NAN
	if wk == "bow" and pose not in ["shoot", "aim", "victory", "guard", "idle", "ready"]:
		p.wpn = NAN
	if wk == "bow" and pose in ["idle", "ready", "guard"]:
		p.whand = "far"
		p.wpn = -1.5708
		p.far = Vector2(6.0, -7.0)
	if side == false and not is_nan(p.wpn):
		# front view: the weapon is held up in the viewer's right hand
		p.wpn = -1.5708 if pose in ["hold_up", "victory"] else NAN
	return p


# ------------------------------------------------------------------- draw --

static func _draw(b: PixBuf, s: Dictionary, dir: int, frame: int, mood: String, pose: String) -> void:
	var cx := CX
	var by := BY
	var skin: Color = s.get("skin", Pal.SKIN)
	var hair: Color = s.get("hair", Pal.BARK)
	var top: Color = s.get("top", Pal.BLUE)
	var bottom: Color = s.get("bottom", Pal.SLATE)
	var shoes: Color = s.get("shoes", Pal.BARK)
	var style: String = s.get("style", "short")
	var jacket: Variant = s.get("jacket", null)
	var side := dir == 2
	var back := dir == 1
	var p := _params(pose, dir, frame, s)
	var big: bool = s.get("big", false)
	var tall: bool = s.get("tall", false)
	var broad: bool = s.get("broad", false) or big
	if p.mood != "" and (mood == "" or mood.begins_with("+")):
		mood = p.mood + mood
	var lean: float = p.lean if side else 0.0
	var crouch: float = p.crouch
	var bob: float = p.bob + crouch
	var lift := 2.0 if tall else 0.0
	var hx: float = cx + lean + (p.head_dx if side else 0.0)
	var hy: float = by - 14.0 - lift + bob + p.head_dy
	var head := [hx, hy, 6.4, 5.8]
	var tx: float = cx + lean * 0.6
	var ty: float = by - 5.0 + bob - lift * 0.5
	var trx := 5.0 if big else (4.4 if broad else 4.0)
	var sh_x := 4.8 if big else (4.3 if broad else 3.8)
	var sleeve: Color = jacket if jacket != null else top
	if s.has("robe"):
		sleeve = s.robe

	# --- behind the body -------------------------------------------------
	b.scale_about(Vector2(hx, hy), HEAD_K)
	if style == "long":
		b.ball(hx - (1.0 if side else 0.0), hy + 3.5, 6.4, 6.0, Pal.shade(hair))
	if style == "curly":
		for i in 5:
			var a := PI * 0.1 + i * PI * 0.8 / 4.0
			b.circ(hx + cos(a) * 6.4 - (1.0 if side else 0.0), hy + sin(a) * 3.5 + 1.5, 2.4, Pal.shade(hair))
	if style == "ponytail" and not back:
		var px := hx - 6.5 if side else hx + 6.6
		b.ball(px, hy + 2.0, 2.6, 4.2, Pal.shade(hair))
		b.ball(px + (-1.0 if side else 0.8), hy + 5.5, 1.8, 2.4, Pal.shade(hair))
	if style == "braid" and side:
		# the braid swings behind the back in the side view
		for k in 4:
			b.ball(hx - 5.2 - k * 0.3, hy + 3.0 + k * 2.2, 1.7, 1.3, Pal.shade(hair))
	b.scale_about(Vector2.ZERO, 1.0)
	var cloak: Variant = s.get("cloak", s.get("cape", null))
	if cloak != null and not back:
		var cc: Color = cloak
		var cl := 1.5 if side else 0.0
		b.poly([Vector2(tx - 4.5, ty - 4), Vector2(tx + 4.5, ty - 4), Vector2(tx + 6.0 - cl * 1.5, by - 0.5), Vector2(tx - 6.5 - cl, by - 0.5)], Pal.shade(cc))
	if s.get("quiver", false) and not back:
		# quiver and unstrung bow across the back
		var qx := tx - (4.5 if side else -3.5)
		b.rect(qx - 1, ty - 8, 3, 7, Pal.LEATHER)
		b.rect(qx - 1, ty - 9, 1, 2, Pal.CREAM)
		b.rect(qx + 1, ty - 10, 1, 2, Pal.CREAM)
	if s.get("hood", false) and back:
		b.ball(cx, by - 9.0 + bob, 4.6, 2.4, s.get("hoodc", top))
	if side and pose != "lie_src":
		# far arm, half hidden behind the body
		var fs := Vector2(tx + 2.8, ty - 2.0)
		var fh: Vector2 = Vector2(cx, by) + p.far + Vector2(lean * 0.5, bob)
		b.cap(fs.x, fs.y, fh.x, fh.y, 1.2, Pal.shade(sleeve))
		if p.whand == "far" and not is_nan(p.wpn):
			_weapon(b, s, fh, p.wpn, true, p)
		b.circ(fh.x, fh.y + 0.4, 1.2, Pal.shade(skin))

	# --- legs --------------------------------------------------------------
	_legs(b, s, p, side, back, bottom, shoes, cx, by, lean, crouch)

	# --- body --------------------------------------------------------------
	if s.has("robe"):
		var rc: Color = s.robe
		b.poly([Vector2(tx - 3.8, ty - 3.5), Vector2(tx + 3.8, ty - 3.5), Vector2(tx + 5.2, by - 0.2), Vector2(tx - 5.2, by - 0.2)], rc)
		b.ball(tx, ty - 1.0, trx, 3.4 + lift * 0.4, rc)
		b.rect(tx - 5.0, by - 1.2, 10.4, 1, Pal.shade(rc))
		if not back:
			b.rect(tx - 0.5 + (1.0 if side else 0.0), ty - 3, 1, by - ty + 2, Pal.shade(rc))
			b.rect(tx - 3.5, ty + 0.3, 7, 1, s.get("sashc", Pal.shade(rc)))
		if s.get("patches", false):
			# one blue patch he never quite gave up
			b.rect(tx + (2 if side else -4), ty - 1, 2, 2, Pal.BLUE)
	elif jacket != null:
		b.ball(tx, ty, trx, 3.2 + lift * 0.3, jacket)
		if not back:
			if side:
				b.rect(tx, ty - 3, 2, 5, top)
				b.pset(int(tx) - 1, int(ty) - 2, Pal.shade(jacket))
			else:
				b.rect(tx - 1, ty - 3, 2, 5, top)
				b.pset(int(tx) - 2, int(ty) - 2, Pal.shade(jacket))
				b.pset(int(tx) + 1, int(ty) - 2, Pal.shade(jacket))
		if s.get("coat_long", false):
			# traveling coat tails flapping behind the knees
			var flap := 1.0 if (frame % 2 == 1 and pose in ["walk", "run"]) else 0.0
			if side:
				b.poly([Vector2(tx - 4.0, ty + 1.0), Vector2(tx - 0.5, ty + 1.0), Vector2(tx - 1.5, by - 1.5), Vector2(tx - 5.0 - flap - lean * 0.5, by - 1.0)], Pal.shade(jacket))
			elif not back:
				b.poly([Vector2(tx - 4.2, ty + 0.5), Vector2(tx - 1.2, ty + 0.5), Vector2(tx - 1.6, by - 1.5), Vector2(tx - 4.8, by - 1.5)], jacket)
				b.poly([Vector2(tx + 1.2, ty + 0.5), Vector2(tx + 4.2, ty + 0.5), Vector2(tx + 4.8, by - 1.5), Vector2(tx + 1.6, by - 1.5)], jacket)
			else:
				b.poly([Vector2(tx - 4.2, ty + 0.5), Vector2(tx + 4.2, ty + 0.5), Vector2(tx + 4.8, by - 1.5), Vector2(tx - 4.8, by - 1.5)], jacket)
				b.rect(tx - 0.5, ty + 1, 1, by - ty - 2.5, Pal.shade(jacket))
		if s.get("patches", false):
			var px := int(tx) + (2 if side else -3)
			b.rect(px, int(ty), 2, 2, Pal.BLUE.lerp(Pal.SKY, 0.45))
			b.pset(px + (-5 if side else 5), int(ty) + 3, Pal.DUST)
			b.pset(px + (-4 if side else 4), int(ty) + 3, Pal.DUST)
	else:
		b.ball(tx, ty, trx, 3.2 + lift * 0.3, top)
	if s.get("armor", false):
		# layered leather: a darker breastplate band and crossing straps
		var lc := Pal.LEATHER.lerp(Pal.BARK, 0.3)
		b.rect(tx - 3.5, ty - 1.5, 7, 2, lc)
		b.rect(tx - 3.5, ty - 1.5, 7, 1, Pal.hi(lc).lerp(lc, 0.5))
		if not back:
			b.line(int(tx) - 3, int(ty) - 3, int(tx) + 2, int(ty) + 1, Pal.deep(lc))
		b.rect(tx - (5.5 if not side else 2.0), ty - 3.5, 2.5, 1.6, lc)
		if not side:
			b.rect(tx + 3.0, ty - 3.5, 2.5, 1.6, lc)
	if s.get("floral", false):
		for q in [Vector2(-2, -1), Vector2(2, 0), Vector2(0, 1), Vector2(-1, 2)]:
			b.pset(int(tx + q.x), int(ty + q.y), Pal.PINK)
	if s.get("skirt", false):
		b.poly([Vector2(tx - 3.5, ty + 0.5), Vector2(tx + 3.5, ty + 0.5), Vector2(tx + 5, by - 1.5), Vector2(tx - 5, by - 1.5)], bottom)
		b.rect(tx - 4.5, by - 2.5, 9.5, 1, Pal.shade(bottom))
	elif not s.has("robe"):
		b.rect(tx - 3.5, ty + 1, 7, 1.5, Pal.shade(bottom))
	if s.get("belt", false):
		b.rect(tx - 3.5, ty + 0.5, 7, 1, Pal.INK2)
		b.pset(int(tx) + (1 if side else 0), int(ty + 0.5), Pal.BRASS)
	if s.get("sheath", false):
		# the blade's scabbard at the hip; its grasping guard and violet stone
		var sx := tx - (3.0 if side else -3.5)
		b.line(int(sx), int(ty) + 1, int(sx) - (4 if side else -2), int(by) - 1, Pal.LEATHER.lerp(Pal.INK2, 0.4))
		b.rect(sx - 1, ty - 0.5, 3, 1, Pal.BRASS.lerp(Pal.INK2, 0.3))
		b.pset(int(sx), int(ty) - 1, Pal.OMEN)
	if s.get("sash", false) and not back:
		var sc: Color = s.get("sashc", Pal.RED)
		b.line(int(tx) - 3, int(ty) - 2, int(tx) + 2, int(ty) + 1, sc)
		b.line(int(tx) - 2, int(ty) - 2, int(tx) + 3, int(ty) + 1, sc)
	if s.get("apron", false) and not back:
		b.rect(tx - 2 + (0.5 if side else 0.0), ty - 1, 4, 4.5, Pal.WHITE)
	if s.get("jewel", false) and not back:
		b.pset(int(tx), int(ty) - 2, Pal.BRASS)
		b.pset(int(tx) - 1, int(ty) - 3, Pal.BRASS)
		b.pset(int(tx) + 1, int(ty) - 3, Pal.BRASS)
	if s.get("hood", false) and not back:
		b.rect(tx - 3.5, ty - 3.2, 7, 1.4, s.get("hoodc", top))
	if cloak != null and back:
		var cc2: Color = cloak
		b.poly([Vector2(tx - 4.8, ty - 4), Vector2(tx + 4.8, ty - 4), Vector2(tx + 6.0, by - 0.5), Vector2(tx - 6.0, by - 0.5)], cc2)
		b.rect(tx - 0.5, ty - 3, 1, by - ty + 2, Pal.shade(cc2))
	if cloak != null and not back:
		# clasp at the collar
		b.rect(tx - 3.0, ty - 3.6, 6, 1.2, cloak)
		b.pset(int(tx) + (1 if side else 0), int(ty) - 3, Pal.BRASS)
	if s.get("quiver", false) and back:
		b.rect(tx + 1, ty - 9, 3, 8, Pal.LEATHER)
		for k in 3:
			b.pset(int(tx) + 1 + k, int(ty) - 10, Pal.CREAM)
	if s.get("scarf", null) != null:
		b.rect(tx - 3.5, ty - 3.4, 7, 1.6, s.scarf)
		if not back:
			b.rect(tx + (1.0 if not side else -2.0), ty - 2.0, 1.5, 3, Pal.shade(s.scarf))
	if s.get("dress", false):
		b.poly([Vector2(tx - 3.8, ty - 2.0), Vector2(tx + 3.8, ty - 2.0), Vector2(tx + 5.5, by - 0.5), Vector2(tx - 5.5, by - 0.5)], top)
		b.rect(tx - 5.0, by - 1.5, 10.5, 1, Pal.shade(top))
		if not back:
			b.pset(int(tx) + (1 if side else 0), int(ty) - 1, Pal.hi(top))

	# --- arms (front and back view) ------------------------------------------
	if not side:
		var ls := Vector2(tx - sh_x, ty - 2.0)
		var rs := Vector2(tx + sh_x, ty - 2.0)
		var lh: Vector2 = Vector2(cx, by) + p.lh + Vector2(0, bob)
		var rh: Vector2 = Vector2(cx, by) + p.rh + Vector2(0, bob)
		if back:
			var t := lh
			lh = Vector2(2 * cx - rh.x, rh.y)
			rh = Vector2(2 * cx - t.x, t.y)
		if pose == "sit" or pose == "lie_src":
			lh = Vector2(cx - 2.6, by - 3.6 + bob)
			rh = Vector2(cx + 2.6, by - 3.6 + bob)
		var hips: bool = p.get("elbow_out", false)
		_arm(b, ls, lh, sleeve, Vector2(ls.x - 2.2, ls.y + 2.0) if hips else Vector2.INF)
		_arm(b, rs, rh, sleeve, Vector2(rs.x + 2.2, rs.y + 2.0) if hips else Vector2.INF)
		if not is_nan(p.wpn) and not back:
			_weapon(b, s, rh, p.wpn, false, p)
		b.circ(lh.x, lh.y, 1.2, skin)
		b.circ(rh.x, rh.y, 1.2, skin)
		_hand_marks(b, s, lh, rh)

	# --- head --------------------------------------------------------------
	b.scale_about(Vector2(hx, hy), HEAD_K)
	b.ball(hx, hy, 6.4, 5.8, skin)
	_hair(b, s, style, hair, dir, hx, hy, head)
	if s.get("hat", "") == "hood":
		# a hood frames the face, so it goes on before the face does
		_hat(b, s, dir, hx, hy)
	if not back:
		_face(b, s, dir, mood, hx, hy, skin, head)
		if side:
			# the near ear, where the hair stops at the back of the head
			b.ball(hx - 5.4, hy + 1.2, 1.3, 1.6, skin)
			b.rect(hx - 5.6, hy + 0.9, 0.8, 1.0, Pal.shade(skin))
			if s.get("earring", false):
				b.pset(int(b._x(hx - 5.4)), int(b._y(hy + 2.6)), Pal.BRASS)
	b.scale_about(Vector2(hx, hy), HEAD_K)
	_hair_front(b, s, style, hair, dir, hx, hy, head)
	if style != "curly" and style != "bald":
		_soften_hair(b, hair)
		# one small sheen on the crown instead of a broad highlight slab
		var sheen := hair.lerp(Pal.hi(hair), 0.6)
		var so := -0.6 if side else 0.0
		b.rect(hx - 3.6 + so, hy - 5.8, 3.0, 0.9, sheen)
		b.rect(hx - 5.0 + so, hy - 4.9, 1.2, 0.9, sheen)
	elif style == "bald" and not s.has("hat"):
		# a shaved head still catches the light
		b.rect(hx - 3.4 + (-0.6 if side else 0.0), hy - 5.0, 2.4, 0.9, Pal.hi(skin).lerp(skin, 0.4))
	if s.has("hat") and s.hat != "hood":
		_hat(b, s, dir, hx, hy)
	b.scale_about(Vector2.ZERO, 1.0)
	if s.get("beard", false) and not back:
		var bx := hx + (1.2 if side else 0.0)
		var bc: Color = s.get("beardc", s.get("hair", Pal.BARK))
		b.ball(bx, hy + 7.2, 4.6, 3.2, bc)
		b.rect(bx - 1.5, hy + 5.6, 3, 1, Pal.shade(bc))
		if mood.begins_with("grin") or mood.begins_with("laugh") or mood.contains("+open"):
			b.rect(bx - 1, hy + 6.4, 2, 1, Pal.INK2)
			if s.get("brass_tooth", false):
				b.pset(int(bx), int(hy + 6.4), Pal.BRASS)
	if s.get("mask", false) and not back:
		# a cloth mask over nose and mouth
		var mx := hx + (1.2 if side else 0.0)
		var mc: Color = s.get("maskc", Pal.CREAM)
		b.rect(mx - (4.0 if side else 5.0), hy + 3.4, 8.0 if side else 10.0, 3.2, mc)
		b.rect(mx - (4.0 if side else 5.0), hy + 6.0, 8.0 if side else 10.0, 0.8, Pal.shade(mc))

	if side and pose != "lie_src":
		# near arm, in front of the body
		var ns := Vector2(tx - 3.2 + (2.0 if p.near.x > 2.0 else 0.0), ty - 2.0)
		var nh: Vector2 = Vector2(cx, by) + p.near + Vector2(lean * 0.5, bob)
		if pose == "sit":
			nh = Vector2(cx - 1.5, by - 4.0 + bob)
		_arm(b, ns, nh, sleeve, Vector2.INF)
		if p.whand == "near" and not is_nan(p.wpn):
			_weapon(b, s, nh, p.wpn, true, p)
		elif s.get("weapon", "") == "bow" and p.whand == "far" and p.bow_draw > 0.0:
			pass
		b.circ(nh.x, nh.y + 0.4, 1.2, skin)
		if s.get("rope", false):
			b.pset(int(nh.x), int(nh.y + 1.0), Pal.PINK.lerp(skin, 0.3))
		if pose == "sit":
			b.circ(cx + 2.6, by - 3.6 + bob, 1.2, Pal.shade(skin))
	if s.get("weapon", "") == "cane" and is_nan(p.wpn) and pose in ["walk", "idle", "slump"] and not back:
		# Fen's walking stick, planted on the ground beside him
		var chx := cx + (5.5 if side else 6.0)
		b.rect(chx, by - 9 + bob, 1, 9 - bob, Pal.WOOD)
		b.rect(chx - 1, by - 10 + bob, 2, 1, Pal.BRASS)


static func _arm(b: PixBuf, sh: Vector2, hand: Vector2, c: Color, elbow: Vector2) -> void:
	if elbow != Vector2.INF:
		b.cap(sh.x, sh.y, elbow.x, elbow.y, 1.2, c)
		b.cap(elbow.x, elbow.y, hand.x, hand.y, 1.2, c)
	else:
		b.cap(sh.x, sh.y, hand.x, hand.y, 1.2, c)


static func _hand_marks(b: PixBuf, s: Dictionary, lh: Vector2, rh: Vector2) -> void:
	if s.get("rope", false):
		# old rope burns across the backs of his hands
		b.pset(int(lh.x), int(lh.y + 0.5), Pal.PINK.lerp(s.get("skin", Pal.SKIN), 0.3))
		b.pset(int(rh.x), int(rh.y + 0.5), Pal.PINK.lerp(s.get("skin", Pal.SKIN), 0.3))


static func _legs(b: PixBuf, s: Dictionary, p: Dictionary, side: bool, back: bool, bottom: Color, shoes: Color, cx: float, by: float, lean: float, crouch: float) -> void:
	var lstep := -1.0 if p.step == 1 else 0.0
	var rstep := -1.0 if p.step == 3 else 0.0
	var legs: String = p.legs
	var lh := 3.0
	if s.has("robe"):
		# robes cover the legs; only the shoes peek out
		var o := 1.0 if side else 0.0
		b.rect(cx - 3 + o + lstep * -1.0, by - 1, 2.5, 1, shoes)
		b.rect(cx + 1 + o + rstep * -1.0, by - 1, 2.5, 1, shoes)
		return
	match legs:
		"sit":
			b.rect(cx - 3, by - 3, 2, 2, bottom)
			b.rect(cx + 1, by - 3, 2, 2, bottom)
		"kneel":
			if side:
				b.rect(cx + 1.0, by - 3, 2, 3, bottom)
				b.rect(cx + 1.0, by - 1, 3, 1, shoes)
				b.rect(cx - 4.0, by - 1.5, 5, 1.5, Pal.shade(bottom))
				b.rect(cx - 5.0, by - 1, 1.5, 1, Pal.shade(shoes))
			else:
				b.rect(cx - 3, by - 2, 2, 2, bottom)
				b.rect(cx + 1, by - 2, 2, 2, Pal.shade(bottom))
				b.rect(cx - 3, by - 1, 2, 1, shoes)
		"crouch":
			b.rect(cx - 4, by - 2, 3, 2, bottom)
			b.rect(cx + 1, by - 2, 3, 2, bottom)
			b.rect(cx - 4, by - 1, 3, 1, shoes)
			b.rect(cx + 1, by - 1, 3, 1, shoes)
		"stride", "stride_small", "lunge", "stride_back":
			if not side:
				b.rect(cx - 4, by - 3, 2, 3, bottom)
				b.rect(cx - 4, by - 1, 2, 1, shoes)
				b.rect(cx + 2, by - 3, 2, 3, bottom)
				b.rect(cx + 2, by - 1, 2, 1, shoes)
				return
			var spread: float = {"stride": 3.5, "stride_small": 2.2, "lunge": 5.0, "stride_back": 3.5}[legs]
			var shift: float = {"stride": 0.0, "stride_small": 0.0, "lunge": 1.0, "stride_back": -1.5}[legs]
			var hip := Vector2(cx + lean * 0.4, by - 3.2 - 0.0)
			var front := Vector2(cx + shift + spread, by - 0.6)
			var rear := Vector2(cx + shift - spread, by - 0.6)
			b.cap(hip.x + 0.5, hip.y, rear.x, rear.y, 1.0, Pal.shade(bottom))
			b.rect(rear.x - 1.5, by - 1, 3, 1, Pal.shade(shoes))
			b.cap(hip.x - 0.5, hip.y, front.x, front.y, 1.0, bottom)
			b.rect(front.x - 1.0, by - 1, 3, 1, shoes)
		_:
			lh = maxf(1.0, 3.0 - crouch)
			if side:
				# both legs show; the stride reaches toward the walking direction and
				# the lifted foot rises a pixel, so the step reads with depth
				var la := 1.0 if p.step == 1 else (-1.0 if p.step == 3 else 0.0)
				b.rect(cx + 0.5 - la, by - lh, 2, lh + rstep, Pal.shade(bottom))
				b.rect(cx + 0.5 - la, by - 1 + rstep, 3, 1, Pal.shade(shoes))
				b.rect(cx - 2.5 + la, by - lh, 2, lh + lstep, bottom)
				b.rect(cx - 2.5 + la, by - 1 + lstep, 3, 1, shoes)
			else:
				var o := 1.0 if crouch > 1.5 else 0.0
				b.rect(cx - 3 - o, by - lh, 2, lh + lstep, bottom)
				b.rect(cx - 3 - o, by - 1 + lstep, 2, 1, shoes)
				b.rect(cx + 1 + o, by - lh, 2, lh + rstep, bottom)
				b.rect(cx + 1 + o, by - 1 + rstep, 2, 1, shoes)


# ----------------------------------------------------------------- weapons --

static func weapon_tip(s: Dictionary, hand: Vector2, angle: float) -> Vector2:
	## Where the business end of a held weapon is (for battle effects).
	var l := weapon_length(s.get("weapon", ""))
	return hand + Vector2(cos(angle), sin(angle)) * l


static func weapon_length(kind: String) -> float:
	return {"dagger": 6.0, "sword": 13.0, "spear": 16.0, "club": 9.0, "cane": 10.0, "hook": 9.0, "sling": 4.0, "ledger": 0.0}.get(kind, 0.0)


static func _weapon(b: PixBuf, s: Dictionary, hand: Vector2, angle: float, side: bool, p: Dictionary) -> void:
	var kind: String = s.get("weapon", "")
	var d := Vector2(cos(angle), sin(angle))
	var n := Vector2(-d.y, d.x)
	match kind:
		"dagger":
			var steel := Pal.STEEL
			b.cap(hand.x + d.x * 1.5, hand.y + d.y * 1.5, hand.x + d.x * 6.0, hand.y + d.y * 6.0, 0.7, steel)
			b.pset(int(hand.x + d.x * 3.0 - n.x * 0.5), int(hand.y + d.y * 3.0 - n.y * 0.5), Pal.hi(steel))
			b.cap(hand.x - n.x * 1.4 + d.x, hand.y - n.y * 1.4 + d.y, hand.x + n.x * 1.4 + d.x, hand.y + n.y * 1.4 + d.y, 0.5, Pal.BRASS)
			b.cap(hand.x - d.x * 1.5, hand.y - d.y * 1.5, hand.x, hand.y, 0.6, Pal.LEATHER)
		"sword":
			# the cursed blade: dark steel, a violet vein, a guard like grasping fingers
			var steel := Pal.STEEL.lerp(Pal.INK2, 0.35)
			var tip := hand + d * 13.0
			b.cap(hand.x + d.x * 1.5, hand.y + d.y * 1.5, tip.x, tip.y, 1.0, steel)
			for k in range(3, 12, 2):
				var q := hand + d * k
				b.pset(int(q.x), int(q.y), Pal.OMEN.lerp(steel, 0.25))
			var e := hand + d * 6.0 - n * 0.9
			b.pset(int(e.x), int(e.y), Pal.hi(steel))
			var g0 := hand + d * 1.2 - n * 2.6
			var g1 := hand + d * 1.2 + n * 2.6
			b.cap(g0.x, g0.y, g1.x, g1.y, 0.6, Pal.BRASS.lerp(Pal.INK2, 0.35))
			b.pset(int(g0.x + d.x * 1.2), int(g0.y + d.y * 1.2), Pal.BRASS.lerp(Pal.INK2, 0.35))
			b.pset(int(g1.x + d.x * 1.2), int(g1.y + d.y * 1.2), Pal.BRASS.lerp(Pal.INK2, 0.35))
			var pm := hand - d * 2.2
			b.cap(hand.x, hand.y, pm.x, pm.y, 0.6, Pal.LEATHER)
			b.pset(int(pm.x), int(pm.y), Pal.OMEN)
			if s.get("mark", "") != "":
				# the mark Rook carved: a single bright scratch near the guard
				var mk := hand + d * 3.0 + n * 0.6
				b.pset(int(mk.x), int(mk.y), Pal.CREAM)
		"spear":
			var shaft := Pal.WOOD
			var base := hand - d * 7.0
			var tip := hand + d * 13.0
			b.cap(base.x, base.y, tip.x, tip.y, 0.6, shaft)
			b.tri(tip.x - n.x * 1.6, tip.y - n.y * 1.6, tip.x + n.x * 1.6, tip.y + n.y * 1.6, tip.x + d.x * 4.0, tip.y + d.y * 4.0, Pal.STEEL)
			b.pset(int(tip.x - d.x), int(tip.y - d.y), Pal.RED.lerp(Pal.CANVAS, 0.3))
		"hook":
			var tip := hand + d * 8.0
			b.cap(hand.x, hand.y, tip.x, tip.y, 0.7, Pal.STEEL)
			var hk := tip - n * 2.5 - d * 1.5
			b.cap(tip.x, tip.y, hk.x, hk.y, 0.6, Pal.STEEL)
			b.cap(hand.x - d.x * 1.5, hand.y - d.y * 1.5, hand.x, hand.y, 0.6, Pal.CREAM)
		"club":
			var tip := hand + d * 8.0
			b.cap(hand.x - d.x, hand.y - d.y, tip.x, tip.y, 0.9, Pal.WOOD)
			b.circ(tip.x, tip.y, 2.0, Pal.WOOD.lerp(Pal.BARK, 0.3))
			b.pset(int(tip.x - 1), int(tip.y - 1), Pal.hi(Pal.WOOD))
			b.pset(int(tip.x + 1), int(tip.y), Pal.STEEL)
		"cane":
			var tip := hand + d * 10.0
			b.cap(hand.x - d.x, hand.y - d.y, tip.x, tip.y, 0.6, Pal.WOOD)
			b.circ(hand.x - d.x * 1.5, hand.y - d.y * 1.5, 1.0, Pal.BRASS)
		"sling":
			var tip := hand + d * 4.0 + n * 1.0
			b.line(int(hand.x), int(hand.y), int(tip.x), int(tip.y), Pal.LEATHER)
			b.circ(tip.x, tip.y, 1.0, Pal.LEATHER.lerp(Pal.STONE, 0.3))
		"bow":
			# a recurved bow, held upright in the hand, string to the draw hand
			var top_ := hand + Vector2(0.5, -8.0)
			var bot := hand + Vector2(0.5, 8.0)
			var bc := Pal.WOOD.lerp(Pal.CLAY, 0.25)
			b.cap(hand.x, hand.y, top_.x + 1.5, top_.y + 2.5, 0.7, bc)
			b.cap(top_.x + 1.5, top_.y + 2.5, top_.x, top_.y, 0.6, bc)
			b.cap(hand.x, hand.y, bot.x + 1.5, bot.y - 2.5, 0.7, bc)
			b.cap(bot.x + 1.5, bot.y - 2.5, bot.x, bot.y, 0.6, bc)
			var draw_x: float = hand.x - 2.0 - float(p.get("bow_draw", 0.0)) * 6.0
			b.line(int(top_.x), int(top_.y), int(draw_x), int(hand.y), Pal.CREAM.lerp(Pal.WHITE, 0.3))
			b.line(int(bot.x), int(bot.y), int(draw_x), int(hand.y), Pal.CREAM.lerp(Pal.WHITE, 0.3))
			if p.get("bow_draw", 0.0) > 0.5:
				b.rect(draw_x, hand.y, hand.x + 4 - draw_x, 1, Pal.WOOD.lerp(Pal.CREAM, 0.4))
				b.pset(int(hand.x + 4), int(hand.y), Pal.STEEL)
		"ledger":
			b.rect(hand.x - 2, hand.y - 3, 4, 5, Pal.CREAM)
			b.rect(hand.x - 2, hand.y - 3, 1, 5, Pal.BRASS)


# -------------------------------------------------------------------- hair --

static func _hair(b: PixBuf, s: Dictionary, style: String, hair: Color, dir: int, hx: float, hy: float, head: Array) -> void:
	if style == "bald":
		return
	var side := dir == 2
	if dir == 1:
		b.ball(hx, hy - 0.5, 6.7, 6.0, hair, head[0], head[1], head[2], head[3])
		if style == "braid":
			for k in 5:
				b.ball(hx, hy + 4.5 + k * 2.0, 1.6, 1.2, hair)
			b.pset(int(b._x(hx)), int(b._y(hy + 14.0)), Pal.BRASS)
	elif style in SHORT_STYLES:
		# short cuts follow the head's own outline all the way down the back and
		# sides; the face is cut out of it afterwards, so the silhouette stays round
		b.ball(hx, hy, 6.4, 5.8, hair, head[0], head[1], head[2], head[3])
		b.ball(hx - (0.2 if side else 0.0), hy - 0.9, 6.6, 5.4, hair, head[0], head[1], head[2], head[3])
	elif side:
		# crown plus the back of the head wrapping round the far-left side, kept
		# inside the head's curve so nothing juts out at the back
		b.ball(hx - 0.2, hy - 1.2, 6.6, 5.2, hair, head[0], head[1], head[2], head[3])
		b.ball(hx - 4.4, hy - 0.6, 2.0, 3.2, hair, head[0], head[1], head[2], head[3])
	else:
		b.ball(hx, hy - 1.4, 6.8, 5.0, hair, head[0], head[1], head[2], head[3])
	match style:
		"bun":
			b.ball(hx - (2.0 if side else 0.0), hy - 6.5, 2.8, 2.4, hair)
		"spiky":
			for i in 3:
				var sx := hx - 4.0 + i * 4.0 - (1.5 if side else 0.0)
				b.tri(sx - 2.5, hy - 4, sx + 2.5, hy - 4, sx - 1.0, hy - 8.5, hair)
		"cropped":
			# Rook: short and dark, a few stubborn tufts at the crown
			b.tri(hx - 3.0 - (1.0 if side else 0.0), hy - 5.0, hx + 0.5 - (1.0 if side else 0.0), hy - 5.4, hx - 2.0 - (1.5 if side else 0.0), hy - 7.6, hair)
			b.tri(hx + 0.0 - (1.0 if side else 0.0), hy - 5.4, hx + 3.5 - (1.0 if side else 0.0), hy - 5.0, hx + 1.0 - (1.5 if side else 0.0), hy - 7.2, hair)
		"twin":
			if not side:
				b.ball(hx - 7.2, hy + 2.5, 2.4, 3.2, hair)
				b.ball(hx + 7.2, hy + 2.5, 2.4, 3.2, hair)
			else:
				b.ball(hx - 7.4, hy + 2.5, 2.4, 3.2, hair)
				b.ball(hx + 6.8, hy + 2.5, 1.8, 3.0, Pal.shade(hair))
		"long":
			if dir == 0:
				b.rect(hx - 6.5, hy - 1, 2, 7, hair)
				b.rect(hx + 4.5, hy - 1, 2, 7, hair)
			elif side:
				b.rect(hx - 7.0, hy - 1, 3, 7, hair)
				b.rect(hx + 5.5, hy - 1, 1.5, 6, hair)
			elif dir == 1:
				b.ball(hx, hy + 3, 6.5, 6, hair)
		"braid":
			if dir == 0:
				# the braid falls forward over her right shoulder
				b.rect(hx - 6.6, hy - 1, 1.8, 5, hair)
				for k in 5:
					b.ball(hx + 5.6 + (k % 2) * 0.4, hy + 2.0 + k * 1.9, 1.6, 1.2, hair)
				b.pset(int(b._x(hx + 5.8)), int(b._y(hy + 11.4)), Pal.BRASS)
			elif side:
				b.rect(hx - 6.8, hy - 1, 2.2, 5, hair)
		"ponytail":
			b.ball(hx + (-3.0 if side else 0.0), hy - 5.2, 3.0, 2.0, hair)
			if dir == 1:
				b.ball(hx, hy + 2.0, 2.6, 4.6, hair)
				b.rect(hx - 1.5, hy - 3.0, 3, 2, Pal.shade(hair))
			elif dir == 0:
				b.rect(hx - 6.6, hy - 1, 1.8, 5, hair)
				b.rect(hx + 4.8, hy - 1, 1.8, 5, hair)
			else:
				b.rect(hx - 6.8, hy - 1, 2.2, 5, hair)
				b.rect(hx + 5.6, hy - 1, 1.4, 4, hair)
		"curly":
			for i in 6:
				var a := PI + 0.1 + i * (PI - 0.2) / 5.0
				var px := hx + cos(a) * 6.4 - (0.8 if side else 0.0)
				var py := hy - 1.2 + sin(a) * 5.0
				b.circ(px, py, 2.3, hair)
				b.pset(int(px) - 1, int(py) - 1, Pal.hi(hair))
			if dir == 1:
				for i in 4:
					b.circ(hx - 4.5 + i * 3.0, hy + 3.0, 2.0, Pal.shade(hair))
		"slick":
			b.ball(hx - (1.0 if side else 0.0), hy - 2.6, 6.6, 4.4, hair, head[0], head[1], head[2], head[3])
			for k in 3:
				b.rect(hx - 4 + k * 3 - (1.0 if side else 0.0), hy - 6, 1, 3, Pal.shade(hair))
		"messy":
			b.tri(hx - 4, hy - 5, hx - 1, hy - 5, hx - 3.5, hy - 8, hair)
			b.tri(hx + 0, hy - 5.5, hx + 3, hy - 5.5, hx + 2.5, hy - 8.5, hair)
		"thin":
			# Fen: grey hair thinning on top, kept at the sides and back
			pass


static func _soften_hair(b: PixBuf, hair: Color) -> void:
	## Hair keeps its base colour with only a gentle shade: the dome lighting's
	## bright band read as a pale slab against the forehead. Tails and buns
	## drawn in the darker tone get the same treatment.
	var dark := Pal.shade(hair)
	var swap := [[Pal.hi(hair), hair], [Pal.deep(hair), dark], [Pal.hi(dark), dark], [Pal.deep(dark), Pal.shade(dark)]]
	var same := func(a: Color, c: Color) -> bool:
		return a.a > 0.5 and absf(a.r - c.r) < 0.01 and absf(a.g - c.g) < 0.01 and absf(a.b - c.b) < 0.01
	for y in b.h:
		for x in b.w:
			var c := b.img.get_pixel(x, y)
			for sw in swap:
				if same.call(c, sw[0]):
					b.pset(x, y, sw[1])
					break


static func _flatten_face(b: PixBuf, skin: Color, ey: int) -> void:
	## Faces stay the bright skin colour: no shading at all above the eye line,
	## and below it only a soft shade along the jaw (never the deep band).
	var tones := [skin, Pal.shade(skin), Pal.deep(skin), Pal.hi(skin)]
	var is_skin := func(c: Color) -> bool:
		if c.a < 0.5:
			return false
		for t: Color in tones:
			if absf(c.r - t.r) < 0.01 and absf(c.g - t.g) < 0.01 and absf(c.b - t.b) < 0.01:
				return true
		return false
	var src := b.img.duplicate() as Image
	for y in range(maxi(0, ey - 8), mini(b.h, ey + 9)):
		for x in b.w:
			var c := src.get_pixel(x, y)
			if not is_skin.call(c):
				continue
			var jaw_edge: bool = y >= ey + 3 and (y + 1 >= b.h or not is_skin.call(src.get_pixel(x, y + 1)))
			b.pset(x, y, Pal.shade(skin) if jaw_edge else skin)


static func _hair_front(b: PixBuf, s: Dictionary, style: String, hair: Color, dir: int, hx: float, hy: float, head: Array) -> void:
	## Fringes and the like that fall over the face.
	if dir == 1:
		return
	var side := dir == 2
	match style:
		"ponytail":
			var o := 1.5 if side else 0.0
			b.tri(hx - 6 + o, hy - 3.5, hx - 0.5 + o, hy - 4.2, hx - 4.8 + o, hy - 0.5, hair)
		"curly":
			var o := 1.0 if side else 0.0
			b.ball(hx - 3.5 + o, hy - 3.6, 2.2, 1.6, hair)
			b.ball(hx + 1.5 + o, hy - 3.9, 2.4, 1.6, hair)
		"short", "bun", "twin", "long", "spiky", "slick", "braid":
			# a soft hairline: a band across the top of the forehead with a few
			# swept locks dipping onto it, turned with the head in the side view
			var o := 1.4 if side else 0.0
			b.ball(hx + o * 0.5, hy - 3.8, 5.8 if not side else 5.4, 1.5, hair, head[0], head[1], head[2], head[3])
			b.tri(hx - 5.8 + o, hy - 3.6, hx - 1.8 + o, hy - 3.8, hx - 4.6 + o, hy - 1.4, hair)
			b.tri(hx - 2.2 + o, hy - 3.8, hx + 2.4 + o, hy - 3.8, hx - 0.6 + o, hy - 2.0, hair)
			b.tri(hx + 2.0 + o, hy - 3.8, hx + 5.8 + o * 0.6, hy - 3.6, hx + 4.6 + o * 0.6, hy - 1.8, hair)
		"cropped":
			# short dark fringe, swept to one side
			var o := 1.4 if side else 0.0
			b.ball(hx + o * 0.5, hy - 4.0, 5.8 if not side else 5.4, 1.3, hair, head[0], head[1], head[2], head[3])
			b.tri(hx - 5.0 + o, hy - 3.8, hx + 1.0 + o, hy - 4.0, hx - 3.8 + o, hy - 1.8, hair)
			b.tri(hx + 0.5 + o, hy - 4.0, hx + 5.4 + o * 0.6, hy - 3.6, hx + 4.4 + o * 0.6, hy - 2.4, hair)
		"messy":
			var o := 1.0 if side else 0.0
			b.tri(hx - 2.5 + o, hy - 4.6, hx + 2.0 + o, hy - 4.6, hx - 0.5 + o, hy - 2.4, hair)


# -------------------------------------------------------------------- face --

static func _face(b: PixBuf, s: Dictionary, dir: int, mood: String, hx: float, hy: float, skin: Color, head: Array) -> void:
	var side := dir == 2
	var fx := hx + (1.2 if side else 0.0)
	var fy := hy + 1.4
	# Light the face as a taller form centred above it, so shadow only reaches
	# the chin and jaw line instead of crossing the cheeks and mouth.
	b.ball(fx, fy, 5.0 if side else 5.3, 4.2, skin, fx - 0.6, fy - 2.6, 7.2, 7.4)
	# Big chibi eyes, drawn at 1:1 so every eye pixel stays crisp.
	b.scale_about(Vector2.ZERO, 1.0)
	var ix := int(hx)
	var ey := int(hy) + 1
	_flatten_face(b, skin, ey)
	var iris: Color = s.get("eye", Pal.INK2.lerp(Pal.SKY, 0.5))
	# Talking variants ride along on the mood: "sad+blink", "+open", ...
	var flags := mood.split("+")
	mood = flags[0]
	var blink := flags.has("blink")
	var open := flags.has("open")
	if s.get("hollow", false) and mood == "":
		mood = "hollow"
	var narrow: bool = s.get("narrow", false)
	var brow := Pal.shade(skin).lerp(Pal.INK2, 0.5)
	# three-quarter: both eyes, the face's centre line turned toward the right
	var eyes: Array = [ix - 1, ix + 4] if side else [ix - 4, ix + 2]
	for i in eyes.size():
		var ex: int = eyes[i]
		var inner := 1 if i == 0 else 0
		var outer := 0 if i == 0 else 1
		var em := "closed" if blink and mood not in ["laugh", "hurt"] else mood
		match em:
			"closed", "sleep":
				b.rect(ex, ey + 2, 2, 1, Pal.INK)
			"hollow":
				b.rect(ex, ey + 1, 2, 2, Pal.INK2)
				b.pset(ex + 1, ey + 2, Pal.OMEN.lerp(Pal.INK2, 0.3))
			"omen":
				# the sword looking out through someone's eyes
				b.rect(ex, ey, 2, 3, Pal.INK)
				b.rect(ex, ey + 1, 2, 1, Pal.OMEN)
				b.pset(ex + outer, ey, Pal.WHITE)
			"shock", "scared":
				b.rect(ex, ey, 2, 3, Pal.WHITE)
				b.pset(ex + inner, ey + 1, Pal.INK)
				if em == "scared":
					b.pset(ex + inner, ey - 1, brow)
			"sad", "cry", "worried":
				b.rect(ex, ey + 1, 2, 2, Pal.INK)
				b.pset(ex, ey + 1, Pal.WHITE)
				b.pset(ex + inner, ey - 1, brow)
				if em == "worried":
					b.pset(ex + outer, ey, Pal.INK2.lerp(skin, 0.5))
				if em == "cry":
					b.pset(ex + 1, ey + 3, Pal.SKY)
					b.pset(ex + 1, ey + 4, Pal.hi(Pal.SKY))
			"angry", "determined":
				b.rect(ex, ey + 1, 2, 2, Pal.INK)
				b.pset(ex + inner, ey + 1, Pal.WHITE)
				# angry brows slope down toward the nose: inner end low, outer end high
				b.pset(ex + inner, ey, Pal.INK2)
				b.pset(ex + outer, ey - 1 if em == "angry" else ey, Pal.INK2)
			"hurt":
				# squeezed shut: > <
				if i == 0:
					b.pset(ex, ey, Pal.INK)
					b.pset(ex + 1, ey + 1, Pal.INK)
					b.pset(ex, ey + 2, Pal.INK)
				else:
					b.pset(ex + 1, ey, Pal.INK)
					b.pset(ex, ey + 1, Pal.INK)
					b.pset(ex + 1, ey + 2, Pal.INK)
			"laugh":
				# happy closed eyes, curved up
				b.rect(ex, ey + 1, 2, 1, Pal.INK)
				b.pset(ex + (-1 if i == 0 else 2), ey + 2, Pal.INK)
			"sly", "smirk_sly":
				b.rect(ex, ey + 1, 2, 2, Pal.INK)
				b.rect(ex, ey + 1, 2, 1, Pal.INK2.lerp(skin, 0.4))
				b.pset(ex + outer, ey + 2, iris)
			_:
				if narrow:
					b.rect(ex, ey + 1, 2, 2, Pal.INK)
					b.pset(ex + outer, ey + 1, Pal.WHITE)
					b.pset(ex + inner, ey + 2, iris)
					b.pset(ex + inner, ey, Pal.INK2.lerp(skin, 0.55))
				else:
					b.rect(ex, ey, 2, 3, Pal.INK)
					b.pset(ex, ey, Pal.WHITE)
					b.pset(ex + 1, ey + 2, iris)
		if s.get("glasses", false):
			b.rect(ex - 1, ey - 1, 4, 1, Pal.INK2)
	if s.get("scar", false):
		var so := -4 if side else 0
		b.pset(ix + 4 + so, ey + 1, Pal.ROSE.lerp(skin, 0.4))
		b.pset(ix + 5 + so, ey + 2, Pal.ROSE.lerp(skin, 0.4))
	if s.get("mask", false):
		return
	var blush := Pal.PINK.lerp(Pal.ROSE, 0.3)
	var mouth := Pal.shade(skin).lerp(Pal.INK2, 0.4)
	# the mouth sits on the face's centre line, which turns with the head
	var mx := ix + 2 if side else ix - 1
	if mood not in ["hollow", "omen"] and not s.get("adult", false):
		if side:
			b.rect(ix - 3, ey + 3, 2, 1, blush)
			b.pset(ix + 6, ey + 3, blush)
		else:
			b.rect(ix - 6, ey + 3, 2, 1, blush)
			b.rect(ix + 4, ey + 3, 2, 1, blush)
	if s.get("freckles", false):
		b.pset(ix - (2 if side else 5), ey + 3, Pal.CLAY.lerp(skin, 0.4))
		b.pset(ix + (5 if side else 3), ey + 3, Pal.CLAY.lerp(skin, 0.4))
	var my := ey + 4
	if s.get("mustache", false):
		b.rect(mx - 1, ey + 4, 4, 1, Pal.deep(s.get("hair", Pal.BARK)))
		my = ey + 5
	if s.get("beard", false):
		return
	match mood:
		"smile":
			b.pset(mx, my, Pal.INK2)
			b.pset(mx + 1, my, Pal.INK2)
		"smirk", "sly":
			b.pset(mx, my, Pal.INK2)
			b.pset(mx + 1, my, Pal.INK2)
			b.pset(mx + 2, my - 1, Pal.INK2)
		"grin", "laugh":
			# a small upside-down trapezoid in the dark outline colour, no teeth
			b.rect(mx - 1, my, 4, 1, Pal.INK2)
			b.rect(mx, my + 1, 2, 1, Pal.INK2)
			if s.get("brass_tooth", false):
				b.pset(mx + 1, my, Pal.BRASS)
		"sad", "cry", "worried":
			b.pset(mx, my + 1, Pal.INK2)
			b.pset(mx + 1, my, mouth)
		"shock", "scared":
			b.rect(mx, my, 2, 2, Pal.INK2)
		"angry", "determined":
			b.rect(mx, my, 2, 1, Pal.INK2)
		"hurt":
			b.rect(mx - 1, my, 3, 1, Pal.INK2)
			b.pset(mx, my, Pal.ROSE.lerp(Pal.INK2, 0.35))
		_:
			if s.get("smile", false) and mood == "":
				b.pset(mx, my, Pal.INK2)
				b.pset(mx + 1, my, Pal.INK2)
			else:
				b.pset(mx + 1, my, mouth)
	if open and mood not in ["grin", "laugh", "shock", "scared"]:
		b.rect(mx, my, 2, 2, Pal.INK2)
		b.pset(mx, my + 1, Pal.ROSE)
	elif open and mood in ["grin", "laugh"]:
		# talking: the trapezoid opens one row deeper, dark rim around the tongue
		b.rect(mx - 1, my + 1, 4, 1, Pal.INK2)
		b.rect(mx, my + 1, 2, 1, Pal.ROSE)
		b.rect(mx, my + 2, 2, 1, Pal.INK2)


# -------------------------------------------------------------------- hats --

static func _hat(b: PixBuf, s: Dictionary, dir: int, hx: float, hy: float) -> void:
	## Hats sit on the head (head-scaled coordinates) and never hide the eyes.
	var side := dir == 2
	var back := dir == 1
	var o := -0.6 if side else 0.0
	var hc: Color = s.get("hatc", Pal.PLUM)
	match s.hat:
		"helm":
			# a caravan guard's iron cap with a brow band
			b.ball(hx + o, hy - 3.6, 6.9, 4.6, hc)
			b.rect(hx - 6.8 + o, hy - 3.2, 13.6, 1.4, Pal.shade(hc))
			b.rect(hx - 0.5 + o + (1.5 if side else 0.0), hy - 8.0, 1.0, 1.2, Pal.hi(hc))
			if not back:
				b.rect(hx - 0.6 + (2.0 if side else 0.0), hy - 3.0, 1.2, 2.0, Pal.shade(hc))
		"hood":
			# a deep cloth hood: covers crown and sides, face left open
			b.ball(hx + o, hy - 1.0, 7.4, 6.8, hc)
			b.rect(hx - 6.4 + o, hy - 4.6, 12.8, 1.0, Pal.shade(hc))
		"turban":
			b.ball(hx + o, hy - 4.2, 7.2, 4.4, hc)
			for k in 3:
				b.rect(hx - 6.0 + o, hy - 6.4 + k * 1.6, 12.0, 0.6, Pal.shade(hc))
			b.circ(hx + 2.0 + o, hy - 6.0, 1.2, Pal.RED.lerp(hc, 0.3))
		"scarf":
			# a headscarf tied at the back, hair hidden
			b.ball(hx + o, hy - 2.4, 7.0, 5.0, hc)
			b.rect(hx - 6.6 + o, hy - 0.8, 13.2, 1.2, Pal.shade(hc))
			if side:
				b.tri(hx - 6.0, hy - 1.0, hx - 4.0, hy + 0.5, hx - 8.6, hy + 3.5, Pal.shade(hc))
			for k in 4:
				b.pset(int(b._x(hx - 4.0 + k * 2.6 + o)), int(b._y(hy - 4.2)), Pal.BRASS.lerp(hc, 0.3))
		"floppy":
			# Wick's cap, a size too big and slipping over one eyebrow
			b.ball(hx + o + 0.6, hy - 4.6, 7.0, 3.4, hc)
			b.ball(hx + o + (3.5 if not side else -2.5), hy - 6.0, 3.0, 2.4, Pal.shade(hc))
			if not back:
				b.rect(hx - 5.0 + o + (2.0 if side else 0.0), hy - 2.8, 9.0, 1.0, Pal.shade(hc))
		"cap":
			b.ball(hx + o, hy - 4.6, 6.6, 3.2, hc)
			b.rect(hx - 6.6 + o, hy - 3.8, 13.2, 1.2, Pal.shade(hc))
		"wide":
			# a sun hat with a broad brim
			b.ball(hx + o, hy - 4.0, 9.0, 1.8, Pal.shade(hc))
			b.ball(hx + o, hy - 5.6, 5.4, 3.2, hc)
			b.rect(hx - 4.8 + o, hy - 4.4, 9.6, 0.9, Pal.RED.lerp(hc, 0.4))
