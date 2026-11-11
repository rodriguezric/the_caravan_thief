class_name ArtBattle
## Battle backdrops: a scene's sky and horizon over a perspective floor for the
## fighters to stand on (enemies on the left, the party on the right). The
## floor is lit in a band where the fighters stand and darkens at the bottom,
## under the status windows, so numbers and menus stay readable.
## Animated backdrops have 4 frames (firelight, wind, stars).

const W := 320
const H := 180
const HORIZON := 92
const FRAMES := {"road": 1, "camp": 4, "wagon": 2, "rookery": 4, "alley": 2, "bridge": 4, "shrine": 1, "pass": 4, "tomb": 2, "campfire": 4, "vision": 4}


static func frames(name: String) -> int:
	return FRAMES.get(name, 1)


static func backdrop(name: String, frame: int) -> PixBuf:
	var b := PixBuf.new(W, H)
	match name:
		"road":
			b.blit(ArtCine.saltway(frame), 0, -22)
			_floor(b, Pal.SAND.lerp(Pal.DUNE, 0.25), Pal.DIRT.lerp(Pal.SAND, 0.3), "sand", frame)
		"camp":
			b.blit(ArtCine.night_camp(frame), 0, -30)
			_floor(b, Pal.DUNE.lerp(Pal.INK, 0.5), Pal.DUNE.lerp(Pal.INK, 0.38), "sand", frame)
			_lanterns(b, frame)
		"wagon":
			b.blit(ArtCine.wagon_inside(frame), 0, -18)
			_floor(b, Pal.WOOD.lerp(Pal.INK, 0.25), Pal.WOOD.lerp(Pal.PEACH, 0.1), "planks", frame)
		"rookery":
			b.blit(ArtCine.rookery(frame), 0, -44)
			_floor(b, Pal.STONE.lerp(Pal.INK, 0.5), Pal.STONE.lerp(Pal.INK, 0.35), "flags", frame)
		"alley":
			b.blit(ArtCine.alley(frame), 0, -46)
			_floor(b, Pal.SAND.lerp(Pal.STONE, 0.4), Pal.hi(Pal.SAND).lerp(Pal.STONE, 0.3), "cobbles", frame)
		"bridge":
			b.blit(ArtCine.gorge(frame), 0, 0)
			_bridge_floor(b, frame)
		"shrine":
			b.blit(ArtCine.shrine(frame), 0, -40)
			_floor(b, Pal.DUSK.lerp(Pal.INK, 0.45), Pal.CANDLE.lerp(Pal.DUSK, 0.55), "flags", frame)
		"pass":
			b.blit(ArtCine.pass_night(frame), 0, -46)
			_floor(b, Pal.SLATE.lerp(Pal.INK, 0.5), Pal.SLATE.lerp(Pal.INK, 0.3), "rock", frame)
		"pass_dawn":
			b.blit(ArtCine.pass_dawn(frame), 0, -46)
			_floor(b, Pal.DUNE.lerp(Pal.INK, 0.45), Pal.CANDLE.lerp(Pal.DUNE, 0.45), "rock", frame)
		"tomb":
			b.blit(ArtCine.tomb(frame), 0, -20)
			_floor(b, Pal.SLATE.lerp(Pal.INK, 0.45), Pal.SLATE.lerp(Pal.STONE, 0.3), "flags", frame)
		"campfire":
			b.blit(ArtCine.campfire_bg(frame), 0, -36)
			_floor(b, Pal.DUNE.lerp(Pal.INK, 0.55), Pal.DUNE.lerp(Pal.INK, 0.4), "sand", frame)
		"vision":
			b.blit(ArtCine.vision(frame), 0, -40)
			_floor(b, Pal.PLUM.lerp(Pal.INK, 0.4), Pal.OMEN.lerp(Pal.PLUM, 0.6), "flags", frame)
		_:
			ArtCine.gradient(b, ArtCine.NIGHT, 0, HORIZON)
			_floor(b, Pal.DUNE.lerp(Pal.INK, 0.5), Pal.DUNE.lerp(Pal.INK, 0.4), "sand", frame)
	return b


static func _floor(b: PixBuf, base: Color, lit: Color, kind: String, frame: int) -> void:
	## A ground plane from the horizon down, with perspective lines, a lit band
	## where the fighters stand (y 100-130), and dark beneath for the UI.
	for y in range(HORIZON, H):
		var depth := float(y - HORIZON) / (H - HORIZON)
		var z := 1.0 / maxf(0.06, depth)
		for x in W:
			var wx := (x - 160) * z * 0.05
			var c := base
			var band := clampf(1.0 - absf(y - 116) / 22.0, 0.0, 1.0)
			if _bayer(x, y) < band * 12.0:
				c = lit
			match kind:
				"sand":
					if Pal.hash2(int(wx * 3), int(z * 6), 4) > 0.9:
						c = Pal.shade(c)
				"planks":
					if posmod(int(z * 8), 3) == 0:
						c = Pal.shade(c)
				"flags":
					if posmod(int(z * 5), 2) == 0 and posmod(int(wx), 2) == 0 or absf(fmod(wx, 2.0)) < 0.08:
						c = Pal.shade(c)
				"cobbles":
					if posmod(int(wx * 2) + int(z * 4), 2) == 0:
						c = c.lerp(Pal.DUST, 0.15)
					if absf(fmod(wx * 2.0, 1.0)) < 0.1:
						c = Pal.shade(c)
				"rock":
					if Pal.hash2(int(wx * 2), int(z * 4), 7) > 0.8:
						c = Pal.shade(c)
			if y >= 134:
				c = c.lerp(Pal.INK, clampf((y - 134) / 30.0, 0.0, 0.7))
			b.img.set_pixel(x, y, c)
	# soft horizon line
	for x in W:
		b.pset(x, HORIZON, b.pget(x, HORIZON).lerp(Pal.INK, 0.3))


static func _bayer(x: int, y: int) -> int:
	return ArtCine.BAYER[y % 4][x % 4]


static func _lanterns(b: PixBuf, frame: int) -> void:
	for k in 3:
		var x := 40 + k * 120
		ArtCine.glow_pool(b, x, 104, 30, 12, Pal.CANDLE, 0.12 + ((frame + k) % 2) * 0.04)


static func _bridge_floor(b: PixBuf, frame: int) -> void:
	## Planks running across the frame over the drop, rope rails behind and
	## in front, swaying a pixel in the wind.
	var sway := 1 if frame % 4 >= 2 else 0
	for y in range(98, 136):
		for x in W:
			var plank := Pal.WOOD.lerp(Pal.DUST, 0.2)
			var c := plank.lerp(Pal.BARK, Pal.hash2(x / 7, 0, 3) * 0.25)
			if x % 7 == 0:
				c = Pal.INK.lerp(Pal.CLAY, 0.3)
			if y == 98 or y == 135:
				c = Pal.shade(plank)
			b.img.set_pixel(x, y + sway, c)
	for y in range(136 + sway, H):
		for x in W:
			b.img.set_pixel(x, y, Pal.CLAY.lerp(Pal.INK, 0.75))
	for x in W:
		b.pset(x, 92 + sway + int(sin(x * 0.05) * 1.5), Pal.CANVAS.lerp(Pal.LEATHER, 0.4))
		if x % 40 == 0:
			b.rect(x, 86 + sway, 3, 14, Pal.WOOD.lerp(Pal.BARK, 0.2))
