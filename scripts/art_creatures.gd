class_name ArtCreatures
## The Saltway's animals, on the same 48 x 40 canvas as the people (feet at
## 24, 36), with the same outline rule and the same moods where they have
## faces: jackals that hunt the caravans, the crow that follows the blade,
## and the oxen that pull the wagons.
## Poses: walk (4 frames), idle, ready, strike (a lunge or bite), hurt, lie.

const CX := 24.0
const BY := 36.0


static func render(s: Dictionary, dir: int, frame: int, mood: String = "", pose: String = "walk") -> PixBuf:
	var b := PixBuf.new(48, 40)
	match s.get("kind", ""):
		"jackal":
			_jackal(b, s, dir, frame, mood, pose)
		"crow":
			_crow(b, s, dir, frame, mood, pose)
		"ox":
			_ox(b, s, dir, frame, mood, pose)
	b.outline()
	if pose == "lie" or pose == "down":
		var r := PixBuf.new(48, 40)
		var img := b.img.duplicate() as Image
		img.flip_y()
		var used := img.get_used_rect()
		r.img.blit_rect(img, used, Vector2i(int(CX - used.size.x / 2.0), int(BY) - used.size.y + 1))
		return r
	return b


static func _jackal(b: PixBuf, s: Dictionary, dir: int, frame: int, mood: String, pose: String) -> void:
	var fur: Color = s.get("fur", Pal.DUNE.lerp(Pal.CLAY, 0.25))
	var belly := Pal.SAND.lerp(Pal.CREAM, 0.4)
	var dark := Pal.shade(fur)
	var bob := 0.0
	var lean := 0.0
	var leg_a := [0.0, 0.0, 0.0, 0.0]
	if pose == "walk" or pose == "run":
		var ph := frame % 4
		leg_a = [[1.5, -1.5, -1.5, 1.5], [0.5, -0.5, -0.5, 0.5], [-1.5, 1.5, 1.5, -1.5], [-0.5, 0.5, 0.5, -0.5]][ph]
		bob = -1.0 if ph % 2 == 1 else 0.0
	elif pose == "idle":
		bob = 1.0 if frame % 2 == 1 else 0.0
	elif pose == "ready":
		bob = 2.0
		lean = -1.0
	elif pose == "strike" or pose == "follow" or pose == "thrust":
		lean = 5.0
		bob = -2.0
		leg_a = [3.0, 3.0, -3.0, -3.0]
	elif pose == "hurt":
		lean = -3.0
		bob = -1.0
	var flags := mood.split("+")
	var blink := flags.has("blink")
	if dir == 2 or dir == 3:
		var bx := CX - 2.0 + lean
		var body_y := BY - 8.0 + bob
		# tail, low and bushy
		b.ball(bx - 10.0, body_y - 1.0, 4.0, 2.0, dark)
		b.ball(bx - 13.0, body_y + 0.5, 2.2, 1.6, Pal.shade(dark))
		# far legs
		b.rect(bx - 6.0 + leg_a[1], body_y + 2, 2, BY - body_y - 2, dark)
		b.rect(bx + 5.0 + leg_a[3], body_y + 2, 2, BY - body_y - 2, dark)
		b.ball(bx, body_y, 8.5, 4.2, fur)
		b.ell(bx + 1.0, body_y + 2.6, 6.0, 1.6, belly)
		# near legs
		b.rect(bx - 4.0 + leg_a[0], body_y + 2, 2, BY - body_y - 2, fur)
		b.rect(bx + 7.0 + leg_a[2], body_y + 2, 2, BY - body_y - 2, fur)
		# head: long snout, big ears
		var hx := bx + 10.0 + lean * 0.4
		var hy := body_y - 5.0
		b.ball(hx, hy, 4.4, 3.8, fur)
		b.ball(hx + 4.6, hy + 1.6, 3.0, 1.8, fur)
		b.ell(hx + 4.8, hy + 2.6, 2.6, 0.9, belly)
		b.pset(int(hx + 7.4), int(hy + 1.0), Pal.INK)
		b.tri(hx - 3.0, hy - 2.0, hx - 0.5, hy - 2.6, hx - 2.5, hy - 8.0, fur)
		b.tri(hx - 0.5, hy - 2.6, hx + 2.0, hy - 2.0, hx + 0.5, hy - 8.4, fur)
		b.pset(int(hx - 1.6), int(hy - 5.0), Pal.ROSE)
		b.pset(int(hx + 0.6), int(hy - 5.4), Pal.ROSE)
		var ex := int(hx + 1.0)
		var ey := int(hy - 1.0)
		if blink or mood.begins_with("closed"):
			b.rect(ex, ey + 1, 2, 1, Pal.INK)
		elif mood.begins_with("hurt"):
			b.pset(ex, ey, Pal.INK)
			b.pset(ex + 1, ey + 1, Pal.INK)
		else:
			b.rect(ex, ey, 2, 2, Pal.LEMON.lerp(Pal.ORANGE, 0.3))
			b.pset(ex + 1, ey + 1, Pal.INK)
		if pose == "strike" or mood.contains("open") or mood.begins_with("angry"):
			b.rect(hx + 3.0, hy + 3.0, 4, 1, Pal.INK2)
			b.pset(int(hx + 4), int(hy + 3), Pal.WHITE)
			b.pset(int(hx + 6), int(hy + 3), Pal.WHITE)
	else:
		# front / back: a sitting jackal, ears up
		var body_y := BY - 7.0 + bob
		b.ball(CX, body_y, 5.0, 6.0, fur)
		b.ell(CX, body_y + 1.5, 3.0, 4.0, belly if dir == 0 else fur)
		b.rect(CX - 4, BY - 3, 2, 3, fur)
		b.rect(CX + 2, BY - 3, 2, 3, fur)
		var hy := body_y - 8.0
		b.ball(CX, hy, 4.6, 4.0, fur)
		b.tri(CX - 4.5, hy - 1.5, CX - 1.5, hy - 3.0, CX - 4.0, hy - 9.0, fur)
		b.tri(CX + 1.5, hy - 3.0, CX + 4.5, hy - 1.5, CX + 4.0, hy - 9.0, fur)
		if dir == 0:
			b.ball(CX, hy + 2.2, 2.4, 1.8, belly)
			b.pset(int(CX), int(hy + 1.6), Pal.INK)
			for ex in [int(CX - 3), int(CX + 1)]:
				if blink:
					b.rect(ex, hy - 0.0, 2, 1, Pal.INK)
				else:
					b.rect(ex, hy - 1.0, 2, 2, Pal.LEMON.lerp(Pal.ORANGE, 0.3))
					b.pset(ex + (1 if ex < CX else 0), int(hy), Pal.INK)
		else:
			b.ball(CX + 5.0, BY - 2.0, 3.0, 1.6, dark)


static func _crow(b: PixBuf, s: Dictionary, dir: int, frame: int, mood: String, pose: String) -> void:
	## The crow that keeps turning up near the blade. One OMEN eye.
	var c := Pal.INK2.lerp(Pal.PLUM, 0.3)
	var flying: bool = pose == "fly" or (pose == "walk" and s.get("flying", false))
	var cy := BY - 5.0 - (10.0 if flying else 0.0)
	var flags := mood.split("+")
	if flying:
		var up := frame % 2 == 0
		b.ball(CX, cy, 4.0, 2.6, c)
		b.ball(CX + 4.0, cy - 1.5, 2.2, 2.0, c)
		b.tri(CX + 6.0, cy - 2.0, CX + 6.0, cy - 0.5, CX + 9.0, cy - 1.0, Pal.STONE.lerp(Pal.INK2, 0.4))
		if up:
			b.tri(CX - 3.0, cy - 1.0, CX + 2.0, cy - 1.0, CX - 6.0, cy - 9.0, Pal.shade(c))
		else:
			b.tri(CX - 3.0, cy + 0.0, CX + 2.0, cy + 0.0, CX - 7.0, cy + 6.0, Pal.shade(c))
		b.tri(CX - 3.0, cy, CX - 3.0, cy + 1.0, CX - 8.0, cy + 2.0, Pal.shade(c))
		b.pset(int(CX + 4.6), int(cy - 2.0), Pal.OMEN)
		return
	b.ball(CX, cy, 3.6, 3.2, c)
	b.tri(CX - 2.0, cy + 1.0, CX - 2.0, cy + 2.0, CX - 7.0, cy + 4.0, Pal.shade(c))
	b.ball(CX + 2.4, cy - 3.6, 2.4, 2.2, c)
	b.tri(CX + 4.4, cy - 4.4, CX + 4.4, cy - 2.6, CX + 7.6, cy - 3.4, Pal.STONE.lerp(Pal.INK2, 0.4))
	b.rect(CX - 1, BY - 2, 1, 2, Pal.STONE.lerp(Pal.INK2, 0.5))
	b.rect(CX + 1, BY - 2, 1, 2, Pal.STONE.lerp(Pal.INK2, 0.5))
	if not flags.has("blink"):
		b.pset(int(CX + 3.0), int(cy - 4.0), Pal.OMEN)
	b.rect(CX - 2.4, cy - 1.6, 3.0, 0.9, Pal.hi(c).lerp(c, 0.5))


static func _ox(b: PixBuf, s: Dictionary, dir: int, frame: int, mood: String, pose: String) -> void:
	## A patient caravan ox, seen from the side.
	var hide := Pal.CANVAS.lerp(Pal.DUST, 0.45)
	var dark := Pal.shade(hide)
	var ph := frame % 4
	var la: float = [0.0, 1.0, 0.0, -1.0][ph] if pose == "walk" else 0.0
	var by := BY
	b.rect(CX - 10 + la, by - 6, 3, 6, dark)
	b.rect(CX + 6 - la, by - 6, 3, 6, dark)
	b.ball(CX - 1.0, by - 10.0, 12.0, 6.0, hide)
	b.ball(CX - 6.0, by - 12.0, 5.0, 4.0, hide)
	b.ell(CX - 2.0, by - 6.4, 8.0, 1.6, Pal.shade(hide))
	b.rect(CX - 7 - la, by - 6, 3, 6, hide)
	b.rect(CX + 8 + la, by - 6, 3, 6, hide)
	b.rect(CX - 7 - la, by - 1, 3, 1, Pal.INK2)
	b.rect(CX + 8 + la, by - 1, 3, 1, Pal.INK2)
	var hx := CX + 12.0
	var hy := by - 12.0
	b.ball(hx, hy, 4.0, 3.6, hide)
	b.ball(hx + 2.6, hy + 2.0, 2.6, 2.2, Pal.PEACH.lerp(hide, 0.4))
	b.tri(hx - 2.0, hy - 3.0, hx + 1.0, hy - 3.0, hx - 4.0, hy - 6.0, Pal.CREAM)
	b.tri(hx + 0.5, hy - 3.0, hx + 3.0, hy - 3.0, hx + 4.0, hy - 6.5, Pal.CREAM)
	if not mood.contains("blink"):
		b.pset(int(hx + 1), int(hy - 1), Pal.INK)
	b.rect(CX - 14, by - 13, 1, 6, dark)
	b.pset(int(CX - 14), int(by - 7), Pal.INK2)
