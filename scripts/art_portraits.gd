class_name ArtPortraits
## Dialog portraits are the characters' own field sprites, zoomed in on the head
## and shoulders, so the face you talk to is the face you walk beside. Speakers
## without a body get animated icons in the same pixel style: the Blade (an
## eye in a violet stone that opens while it speaks) and the crew talking at
## once.

const S := 72
const CROP := Rect2i(12, 10, 24, 24)

## Dialog moods that the field sprite's face doesn't have, mapped to ones it does.
const FIELD_MOOD := {"flat": "", "smug": "smirk"}


static func field_mood(mood: String) -> String:
	return FIELD_MOOD.get(mood, mood)


static func from_sprite(s: Dictionary, mood: String = "", blink: bool = false, open: bool = false, zoom: int = 3) -> PixBuf:
	var m: String = field_mood(mood)
	if blink:
		m += "+blink"
	if open:
		m += "+open"
	var src := ArtPeople.render(s, 0, 0, m)
	var crop_r := CROP
	if s.get("tall", false):
		crop_r = Rect2i(12, 8, 24, 24)
	match s.get("kind", "human"):
		"jackal":
			crop_r = Rect2i(12, 11, 24, 24)
		"crow":
			crop_r = Rect2i(12, 16, 24, 24)
		"ox":
			crop_r = Rect2i(22, 10, 24, 24)
	var crop := src.img.get_region(crop_r)
	crop.resize(crop_r.size.x * zoom, crop_r.size.y * zoom, Image.INTERPOLATE_NEAREST)
	var b := PixBuf.new(crop.get_width(), crop.get_height())
	b.img = crop
	return b


static func head_icon(s: Dictionary, mood: String, hostile: bool) -> PixBuf:
	## The head alone at 1:1, in a 16 x 16 tile, for turn-order chips. Hostile
	## allies (high Suspicion) show the blade's violet in their eyes instead.
	var src := ArtPeople.render(s, 2 if s.get("kind", "human") != "human" else 0, 0, "omen" if hostile else mood)
	var r := Rect2i(16, 12, 16, 16)
	if s.get("tall", false):
		r = Rect2i(16, 10, 16, 16)
	match s.get("kind", "human"):
		"jackal":
			r = Rect2i(26, 16, 16, 16)
		"crow":
			r = Rect2i(18, 18, 16, 16)
	var b := PixBuf.new(16, 16)
	b.img.blit_rect(src.img, r, Vector2i.ZERO)
	if hostile:
		b.recolor(func(_x: int, _y: int, c: Color) -> Color:
			if absf(c.r - Pal.OMEN.r) < 0.02 and absf(c.g - Pal.OMEN.g) < 0.02:
				return c
			return c.lerp(Pal.ROSE.lerp(Pal.INK, 0.3), 0.55))
	return b


static func icon(kind: String, frame: int) -> PixBuf:
	var b := PixBuf.new(S, S)
	var c := S / 2.0
	match kind:
		"blade":
			# the stone in the pommel: an eye that opens while it speaks
			b.rect(4, 4, S - 8, S - 8, Pal.PLUM.lerp(Pal.INK, 0.6))
			for k in 26:
				var px := int(6 + Pal.hash2(k, 1) * (S - 12))
				var py := int(6 + Pal.hash2(k, 2) * (S - 12))
				b.pset(px, py, Pal.OMEN.lerp(Pal.INK, 0.4 + Pal.hash2(k, 3) * 0.5))
			# grasping brass guard around the stone
			var brass := Pal.BRASS.lerp(Pal.INK2, 0.3)
			for k in 5:
				var a := PI * 0.15 + k * PI * 0.175
				var p0 := Vector2(c + cos(a) * 20.0, c + sin(a) * 20.0)
				var p1 := Vector2(c + cos(a) * 12.0, c + sin(a) * 12.0)
				b.cap(p0.x, p0.y, p1.x, p1.y, 2.0, brass)
				var q0 := Vector2(c + cos(-a) * 20.0, c + sin(-a) * 20.0)
				var q1 := Vector2(c + cos(-a) * 12.0, c + sin(-a) * 12.0)
				b.cap(q0.x, q0.y, q1.x, q1.y, 2.0, Pal.shade(brass))
			b.ball(c, c, 13.0, 13.0, Pal.PURPLE.lerp(Pal.OMEN, 0.35))
			var open: float = [0.0, 0.5, 1.0, 1.0, 0.8, 1.0, 0.5, 0.2][frame % 8]
			var lid := 9.0 * open
			if lid >= 1.0:
				b.ell(c, c, 10.0, lid, Pal.INK)
				b.ell(c, c, 8.0, maxf(0.5, lid - 1.5), Pal.OMEN)
				b.ell(c + (frame % 3) - 1.0, c, 3.0, minf(lid, 6.0), Pal.INK)
				b.pset(int(c) - 2, int(c) - 2, Pal.WHITE)
			else:
				b.rect(c - 10, c, 20, 1, Pal.INK)
		"crew":
			# the whole crew talking over each other
			b.rect(4, 4, S - 8, S - 8, Pal.PANEL2)
			var specs := ["fen", "wick", "bracken"]
			for k in specs.size():
				var src := ArtPeople.render(Data.spec(specs[k]), 0, 0, "+open" if (frame + k) % 2 == 0 else "")
				var r := Rect2i(14, 10, 20, 20)
				var img := src.img.get_region(r)
				img.resize(40, 40, Image.INTERPOLATE_NEAREST)
				var tmp := PixBuf.new(40, 40)
				tmp.img = img
				b.blit(tmp, 2 + k * 15, 18 + (k % 2) * 4)
		"hunters":
			b.rect(4, 4, S - 8, S - 8, Pal.PANEL2)
			for k in 3:
				var src := ArtPeople.render(Data.spec("hunter"), 0, 0, "")
				var img := src.img.get_region(Rect2i(14, 10, 20, 20))
				img.resize(40, 40, Image.INTERPOLATE_NEAREST)
				var tmp := PixBuf.new(40, 40)
				tmp.img = img
				b.blit(tmp, 2 + k * 15, 18 + (k % 2) * 4 - (1 if (frame + k) % 4 == 0 else 0))
	b.outline()
	return b
