class_name ArtCine
## Full-screen story vignettes (320x180), painted with the same tools, palette
## and Bayer dithering as everything else. Moving parts (people, the crow,
## firelight, the blade's visions) are added on top by Cinema.
## Most scenes leave a ground band from about y 140 for people to stand on.

const W := 320
const H := 180
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
const DUSK_SKY := [Color("2b1f3a"), Color("5a3a52"), Color("a35f4e"), Color("d89a5a")]
const NIGHT := [Color("120d1c"), Color("1e1a33"), Color("2b2a48"), Color("3c2f4a")]
const DAY := [Color("8fa0a8"), Color("b8b49a"), Color("dccb9a")]
const DAWN := [Color("3c2f4a"), Color("7a5a6e"), Color("c88a6a"), Color("ecc890")]


static func make(name: String, frame: int) -> PixBuf:
	match name:
		"title": return title(frame)
		"title_caravan": return title_caravan()
		"ink": return ink_card()
		"saltway": return saltway(frame)
		"waystation": return waystation()
		"night_camp": return night_camp(frame)
		"wagon_inside": return wagon_inside(frame)
		"omen_void": return omen_void(frame)
		"vision": return vision(frame)
		"rookery": return rookery(frame)
		"town": return town(frame)
		"campfire": return campfire_bg(frame)
		"shrine": return shrine(frame)
		"gorge": return gorge(frame)
		"gorge_fall": return gorge_fall(frame)
		"pass_night": return pass_night(frame)
		"tomb": return tomb(frame)
		"pass_dawn": return pass_dawn(frame)
		"shop": return shop()
		"tavern": return tavern(frame)
		"memory": return memory(frame)
		"road_far": return road_far(frame)
		"sea_road": return sea_road(frame)
		"parchment": return parchment()
	return PixBuf.new(W, H)


# ---------------------------------------------------------------- helpers --

static func gradient(b: PixBuf, cols: Array, y0: int = 0, y1: int = H) -> void:
	for y in range(y0, y1):
		for x in W:
			var t := clampf(float(y - y0) / (y1 - y0), 0.0, 0.999) * (cols.size() - 1)
			var i := int(t)
			var f := t - i
			b.img.set_pixel(x, y, cols[i] if f * 16.0 <= BAYER[y % 4][x % 4] else cols[mini(i + 1, cols.size() - 1)])


static func stars(b: PixBuf, n: int, y1: int, seed: int, twinkle: int = -1) -> void:
	for i in n:
		var x := int(Pal.hash2(i, 1, seed) * W)
		var y := int(Pal.hash2(i, 2, seed) * y1)
		if twinkle >= 0 and (i + twinkle) % 7 == 0:
			continue
		b.pset(x, y, Pal.WHITE.lerp(Pal.NAVY, Pal.hash2(i, 3, seed) * 0.7))


static func ridge(b: PixBuf, base: int, amp: float, freq: float, ph: float, c: Color, top_c: Color = Color(0, 0, 0, 0)) -> void:
	for x in W:
		var top := int(base - absf(sin(x * freq + ph)) * amp - sin(x * freq * 3.1 + ph) * amp * 0.25)
		for y in range(maxi(0, top), H):
			b.pset(x, y, c)
		if top_c.a > 0.0:
			b.pset(x, top, top_c)


static func mesa(b: PixBuf, base: int, c: Color, seed: int) -> void:
	## Flat-topped desert mesas in silhouette.
	for x in W:
		var h := 4.0 + Pal.noise(x * 0.5, seed, seed) * 3.0
		var m := Pal.hash2(x / 40, seed, 3)
		if m > 0.55:
			var e := float(x % 40)
			var edge := minf(e, 40.0 - e)
			h += minf(edge * 2.0, 18.0 + m * 10.0)
		for y in range(int(base - h), H):
			b.pset(x, y, c)


static func ground(b: PixBuf, top: int, c: Color, top_c: Color, rough: float = 2.0) -> void:
	## Foreground ground for people to stand on, darkening toward the bottom.
	for x in W:
		var t := top + int(Pal.noise(x * 0.7, 2.0, 3.0) * rough)
		for y in range(t, H):
			var col := c
			if y == t:
				col = top_c
			elif Pal.hash2(x, y, 6) > 0.94:
				col = Pal.shade(c)
			b.pset(x, y, col.lerp(Pal.INK, (y - t) / 90.0))


static func sun(b: PixBuf, x: float, y: float, r: float, c: Color) -> void:
	for yy in range(int(y - r * 2), int(y + r * 2)):
		for xx in range(int(x - r * 2), int(x + r * 2)):
			var d := Vector2(xx - x, yy - y).length() / (r * 2.0)
			if d < 1.0 and BAYER[posmod(yy, 4)][posmod(xx, 4)] < (1.0 - d) * 6.0:
				b.pset(xx, yy, b.pget(xx, yy).lerp(c, 0.35))
	b.ball(x, y, r, r, c)


static func moon(b: PixBuf, x: float, y: float, r: float) -> void:
	b.ball(x, y, r, r, Pal.CREAM.lerp(Pal.WHITE, 0.3))
	b.circ(x - r * 0.3, y + r * 0.2, r * 0.25, Pal.shade(Pal.CREAM))
	b.circ(x + r * 0.35, y - r * 0.3, r * 0.15, Pal.shade(Pal.CREAM))


static func glow_pool(b: PixBuf, cx: float, cy: float, rx: float, ry: float, c: Color, k: float = 0.2) -> void:
	for y in range(maxi(0, int(cy - ry)), mini(H, int(cy + ry))):
		for x in range(maxi(0, int(cx - rx)), mini(W, int(cx + rx))):
			var d := Vector2((x - cx) / rx, (y - cy) / ry).length()
			if d < 1.0 and BAYER[y % 4][x % 4] < (1.0 - d) * 10.0:
				b.pset(x, y, b.pget(x, y).lerp(c, k))


static func vignette(b: PixBuf, strength: float = 1.4) -> void:
	for y in H:
		for x in W:
			var d := Vector2((x - 160) / 160.0, (y - 90) / 110.0).length()
			if Pal.hash2(x, y, 7) < (d - 0.5) * strength:
				b.pset(x, y, b.pget(x, y).lerp(Pal.INK, 0.55))


static func caravan_silhouette(b: PixBuf, x0: int, base: int, c: Color, n: int) -> void:
	## Wagons and oxen in a line along the horizon.
	for k in n:
		var x := x0 + k * 34
		b.ball(x, base - 9, 11, 7, c)
		b.rect(x - 11, base - 9, 22, 5, c)
		b.circ(x - 6, base - 2, 3, c)
		b.circ(x + 6, base - 2, 3, c)
		b.ball(x + 17, base - 6, 5, 3.5, c)
		b.rect(x + 13, base - 4, 1, 4, c)
		b.rect(x + 20, base - 4, 1, 4, c)


# ----------------------------------------------------------------- scenes --

static func title(frame: int) -> PixBuf:
	## The Saltway at dusk: mesas, the road. The caravan crossing the horizon
	## is a separate sprite (title_caravan) the title screen drives along.
	var b := PixBuf.new(W, H)
	gradient(b, DUSK_SKY, 0, 118)
	stars(b, 40, 40, 5, frame)
	sun(b, 236, 100, 14, Pal.CANDLE.lerp(Pal.LEMON, 0.3))
	mesa(b, 112, Pal.DUSK.lerp(Pal.INK, 0.35), 3)
	ridge(b, 120, 4, 0.03, 1.0, Pal.DUSK.lerp(Pal.INK, 0.55))
	ground(b, 128, Pal.DUNE.lerp(Pal.INK, 0.45), Pal.CANDLE.lerp(Pal.DUNE, 0.4))
	# the road winding toward the viewer
	for y in range(128, H):
		var t := float(y - 128) / (H - 128)
		var cx := 160.0 + sin(t * 3.0) * 30.0
		var hw := 6.0 + t * 46.0
		for x in range(int(cx - hw), int(cx + hw)):
			if Pal.hash2(x, y, 9) > 0.15:
				b.pset(x, y, Pal.DIRT.lerp(Pal.INK, 0.35 + t * 0.2))
	return b


static func title_caravan() -> PixBuf:
	## The title's caravan on its own: four wagons and their oxen, 140 x 20,
	## wheels on the bottom row (the horizon sits at y 118 on the backdrop).
	var b := PixBuf.new(140, 20)
	caravan_silhouette(b, 12, 18, Pal.INK.lerp(Pal.DUSK, 0.2), 4)
	return b


static func ink_card() -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Pal.INK, Pal.INK.lerp(Pal.PLUM, 0.3), Pal.INK])
	return b


static func parchment() -> PixBuf:
	var b := PixBuf.new(W, H)
	for y in H:
		for x in W:
			var c := Pal.CANVAS.lerp(Pal.WHITE, 0.2 + Pal.noise(x, y, 4.0) * 0.1)
			if Pal.hash2(x, y, 3) > 0.97:
				c = Pal.shade(c)
			b.img.set_pixel(x, y, c)
	vignette(b, 1.8)
	return b


static func saltway(frame: int) -> PixBuf:
	## Afternoon on the trade road: hazy mesas, scrub, a long straight track.
	var b := PixBuf.new(W, H)
	gradient(b, DAY, 0, 110)
	mesa(b, 104, Pal.SKY.lerp(Pal.DUNE, 0.4), 11)
	ridge(b, 112, 5, 0.025, 0.3, Pal.DUNE.lerp(Pal.SKY, 0.3))
	ground(b, 118, Pal.SAND.lerp(Pal.DUNE, 0.3), Pal.hi(Pal.SAND))
	for y in range(118, H):
		var t := float(y - 118) / (H - 118)
		var hw := 10.0 + t * 80.0
		for x in range(int(160 - hw), int(160 + hw)):
			if Pal.hash2(x, y, 5) > 0.1:
				b.pset(x, y, Pal.DIRT.lerp(Pal.SAND, 0.35).lerp(Pal.INK, t * 0.3))
	for k in 18:
		var x := int(Pal.hash2(k, 1, 7) * W)
		var y := 122 + int(Pal.hash2(k, 2, 7) * 50)
		b.ball(x, y, 3, 2, Pal.SCRUB.lerp(Pal.INK, float(y - 120) / 120.0))
	# heat shimmer on the horizon
	for x in W:
		if (x + frame * 3) % 11 < 2:
			b.pset(x, 104 + int(sin(x * 0.2 + frame) * 1.0), Pal.hi(Pal.SKY))
	return b


static func waystation() -> PixBuf:
	## Dawn at the ruined waystation where Fen's crew camps.
	var b := PixBuf.new(W, H)
	gradient(b, DAWN, 0, 120)
	stars(b, 20, 30, 41)
	sun(b, 70, 110, 10, Pal.LEMON.lerp(Pal.CANDLE, 0.4))
	mesa(b, 112, Pal.DUSK.lerp(Pal.INK, 0.3), 17)
	# the broken arch of the old waystation
	var st := Pal.STONE.lerp(Pal.DUSK, 0.5)
	b.rect(190, 52, 14, 80, st)
	b.rect(262, 66, 14, 66, st)
	b.ball(233, 56, 40, 12, st)
	for y in range(48, 70):
		for x in range(206, 262):
			var d := Vector2((x - 233) / 28.0, (y - 66) / 12.0).length()
			if d < 1.0:
				b.pset(x, y, b.pget(x, 40).lerp(Pal.CANDLE, 0.1) if y > 60 else b.pget(x, y))
	ground(b, 132, Pal.DUNE.lerp(Pal.INK, 0.35), Pal.CANDLE.lerp(Pal.DUNE, 0.5))
	return b


static func night_camp(frame: int) -> PixBuf:
	## The caravan's camp at the Dry Well: tents, wagons, lantern glints.
	var b := PixBuf.new(W, H)
	gradient(b, NIGHT, 0, 120)
	stars(b, 120, 100, 21, frame)
	moon(b, 270, 30, 9)
	mesa(b, 108, Pal.PLUM.lerp(Pal.INK, 0.5), 9)
	var sil := Pal.INK.lerp(Pal.PLUM, 0.25)
	caravan_silhouette(b, 40, 124, sil, 3)
	for k in 3:
		var tx := 180 + k * 44
		b.tri(tx - 18, 126, tx + 18, 126, tx, 100, sil)
	ground(b, 126, Pal.DUNE.lerp(Pal.INK, 0.6), Pal.DUNE.lerp(Pal.INK, 0.45))
	for k in 5:
		var lx := 30 + k * 64
		if (frame + k) % 4 != 0:
			glow_pool(b, lx, 116, 14, 10, Pal.CANDLE, 0.25)
			b.rect(lx - 1, 114, 2, 3, Pal.CANDLE.lerp(Pal.LEMON, 0.4))
	return b


static func wagon_inside(frame: int) -> PixBuf:
	## Inside the Factor's wagon: canvas ribs overhead, a single lantern pool.
	var b := PixBuf.new(W, H)
	for y in H:
		for x in W:
			var c: Color
			if y < 108:
				c = Pal.CANVAS.lerp(Pal.DUST, 0.35)
				if (x / 40) % 2 == 0 and x % 40 < 4:
					c = Pal.WOOD.lerp(Pal.INK2, 0.3)
			else:
				var plank := Pal.WOOD.lerp(Pal.PEACH, 0.15)
				c = plank if (y - 108) % 9 != 0 else Pal.shade(plank)
			b.img.set_pixel(x, y, c)
	glow_pool(b, 160, 100, 150, 90, Pal.CANDLE, 0.18 + (frame % 2) * 0.03)
	vignette(b, 1.8)
	return b


static func omen_void(frame: int) -> PixBuf:
	## Darkness with a cone of violet light from above, for presenting the blade.
	var b := PixBuf.new(W, H)
	gradient(b, [Pal.INK, Pal.PLUM.lerp(Pal.INK, 0.6), Pal.INK], 0, H)
	for y in H:
		var hw := 18.0 + y * 0.35
		for x in range(int(160 - hw), int(160 + hw)):
			var d := absf(x - 160) / hw
			if BAYER[y % 4][x % 4] < (1.0 - d) * (5.0 + (frame % 2)):
				b.pset(x, y, b.pget(x, y).lerp(Pal.OMEN, 0.18))
	b.ell(160, 160, 50, 8, Pal.PLUM.lerp(Pal.OMEN, 0.15))
	return b


static func vision(frame: int) -> PixBuf:
	## What the blade shows: a violet world with cracks running through it.
	var b := PixBuf.new(W, H)
	gradient(b, [Pal.INK, Pal.PURPLE.lerp(Pal.INK, 0.4), Pal.OMEN.lerp(Pal.PURPLE, 0.6), Pal.PURPLE.lerp(Pal.INK, 0.5)], 0, H)
	for k in 9:
		var x := Pal.hash2(k, 1, 77) * W
		var y := Pal.hash2(k, 2, 77) * H
		var a := Pal.hash2(k, 3, 77) * TAU + frame * 0.05
		for s in 40:
			x += cos(a) * 2.0
			y += sin(a) * 2.0
			a += (Pal.hash2(k, s, 78) - 0.5) * 0.9
			b.pset(int(x), int(y), Pal.OMEN.lerp(Pal.WHITE, 0.4))
	ground(b, 146, Pal.PLUM.lerp(Pal.INK, 0.4), Pal.OMEN.lerp(Pal.PLUM, 0.5), 1.0)
	return b


static func rookery(frame: int) -> PixBuf:
	## The ruined watchtower the crew calls the Rookery, under a big moon.
	var b := PixBuf.new(W, H)
	gradient(b, NIGHT, 0, 130)
	stars(b, 140, 120, 33, frame)
	moon(b, 90, 40, 18)
	mesa(b, 118, Pal.PLUM.lerp(Pal.INK, 0.45), 13)
	var st := Pal.INK.lerp(Pal.SLATE, 0.3)
	b.rect(190, 30, 50, 110, st)
	for k in 5:
		if k % 2 == 0:
			b.rect(190 + k * 10, 24, 10, 7, st)
	b.tri(240, 40, 250, 140, 240, 140, st)
	b.rect(208, 60, 5, 12, Pal.CANDLE.lerp(Pal.ORANGE, 0.3) if frame % 3 != 0 else Pal.CANDLE)
	b.rect(222, 92, 5, 10, Pal.CANDLE.lerp(Pal.ORANGE, 0.5))
	# crows circling the top
	for k in 3:
		var a := frame * 0.4 + k * 2.1
		var p := Vector2(215 + cos(a) * 30, 18 + sin(a) * 6)
		b.ascii(["X.X", ".X."], {"X": Pal.INK}, int(p.x), int(p.y))
	ground(b, 138, Pal.DUNE.lerp(Pal.INK, 0.6), Pal.DUNE.lerp(Pal.INK, 0.4))
	return b


static func town(frame: int) -> PixBuf:
	## Kesh Crossing from the square: whitewashed walls, awnings, the border gate.
	var b := PixBuf.new(W, H)
	gradient(b, DAY, 0, 70)
	var walls := [Pal.CANVAS.lerp(Pal.WHITE, 0.2), Pal.SAND.lerp(Pal.WHITE, 0.3), Pal.CANVAS.lerp(Pal.CLAY, 0.2)]
	for k in 7:
		var x0 := k * 48 - 10
		var top := 40 + int(Pal.hash2(k, 4) * 30)
		var wc: Color = walls[k % 3]
		b.rect(x0, top, 46, 140 - top, wc)
		b.rect(x0, top, 46, 3, Pal.CLAY.lerp(Pal.INK, 0.2))
		b.rect(x0 + 44, top, 2, 140 - top, Pal.shade(wc))
		for wy in range(top + 10, 120, 22):
			b.rect(x0 + 12, wy, 8, 10, Pal.INK2)
			b.rect(x0 + 12, wy, 8, 1, Pal.WOOD)
		var aw: Color = [Pal.CLAY, Pal.TEAL, Pal.PURPLE][k % 3]
		for x in range(x0 + 2, x0 + 42):
			b.pset(x, 118, aw if (x / 4) % 2 == 0 else Pal.CANVAS)
			b.pset(x, 119, aw if (x / 4) % 2 == 0 else Pal.CANVAS)
	# the border gate and its banners
	b.rect(130, 30, 60, 110, Pal.STONE.lerp(Pal.SAND, 0.2))
	b.ball(160, 86, 18, 24, Pal.INK2)
	b.rect(142, 86, 36, 54, Pal.INK2)
	for k in 2:
		var bx := 136 + k * 40
		var flap := (frame + k) % 2
		b.rect(bx, 40, 8, 26 - flap, Pal.RED.lerp(Pal.ROSE, 0.3))
	ground(b, 140, Pal.SAND.lerp(Pal.STONE, 0.4), Pal.hi(Pal.SAND), 0.5)
	return b


static func campfire_bg(frame: int) -> PixBuf:
	## A camp in the hills at night, the fire's light breathing on the ground.
	var b := PixBuf.new(W, H)
	gradient(b, NIGHT, 0, 120)
	stars(b, 150, 110, 55, frame)
	ridge(b, 104, 12, 0.02, 2.0, Pal.PLUM.lerp(Pal.INK, 0.55))
	ridge(b, 122, 8, 0.035, 0.4, Pal.INK.lerp(Pal.PLUM, 0.2))
	ground(b, 132, Pal.DUNE.lerp(Pal.INK, 0.62), Pal.DUNE.lerp(Pal.INK, 0.5))
	glow_pool(b, 160, 152, 120 + (frame % 3) * 6, 34, Pal.CANDLE, 0.22)
	glow_pool(b, 160, 152, 60, 18, Pal.ORANGE, 0.2)
	return b


static func shrine(frame: int) -> PixBuf:
	## The Shrine of the Unnamed: faceless statues against a red dusk.
	var b := PixBuf.new(W, H)
	gradient(b, [Color("2b1f3a"), Color("6e3a46"), Color("b8583e"), Color("e09050")], 0, 130)
	sun(b, 160, 118, 16, Pal.CANDLE.lerp(Pal.RED, 0.2))
	ridge(b, 118, 14, 0.018, 0.5, Pal.DUSK.lerp(Pal.INK, 0.4))
	var st := Pal.INK.lerp(Pal.DUSK, 0.25)
	for k in 5:
		var x := 30 + k * 64
		var h := 70 - absi(k - 2) * 8
		b.rect(x - 7, 136 - h + 14, 14, h - 14, st)
		b.ball(x, 136 - h + 8, 7, 8, st)
		b.rect(x - 1, 136 - h + 20, 2, h - 22, Pal.INK)
		b.rect(x - 6, 136 - h + 19, 12, 2, st)
	ground(b, 136, Pal.DUSK.lerp(Pal.INK, 0.5), Pal.CANDLE.lerp(Pal.DUSK, 0.6))
	return b


static func gorge(frame: int) -> PixBuf:
	## Gorge Bridge: a rope bridge over a red canyon, wind in the ropes.
	var b := PixBuf.new(W, H)
	gradient(b, DAY, 0, 60)
	# canyon walls on both sides
	for y in range(30, H):
		var depth := float(y - 30) / (H - 30)
		for x in W:
			var lw := 70.0 + sin(y * 0.08) * 10.0 - depth * 20.0
			var rw := 250.0 + sin(y * 0.07 + 1.0) * 10.0 + depth * 20.0
			var c: Color
			if x < lw or x > rw:
				var band := (y + int(sin(x * 0.1) * 3.0)) / 6
				c = [Pal.DUNE, Pal.CLAY.lerp(Pal.DUNE, 0.5), Pal.SAND.lerp(Pal.DUNE, 0.5)][band % 3]
				c = c.lerp(Pal.INK, depth * 0.3)
			else:
				c = Pal.CLAY.lerp(Pal.INK, 0.4 + depth * 0.55)
				if Pal.hash2(x / 2, y / 3, 13) > 0.92:
					c = c.lerp(Pal.DUNE, 0.2)
			b.img.set_pixel(x, y, c)
	# the bridge
	var sag := 1.0 + sin(frame * 0.8) * 0.6
	for x in range(40, 280):
		var t := (x - 40) / 240.0
		var y := 70.0 + sin(t * PI) * 12.0 * sag
		b.rect(x, y, 1, 3, Pal.WOOD.lerp(Pal.DUST, 0.2) if x % 5 != 0 else Pal.INK2)
		b.pset(x, int(y - 8 - sin(t * PI) * 2), Pal.CANVAS.lerp(Pal.LEATHER, 0.4))
		if x % 12 == 0:
			b.line(x, int(y - 8 - sin(t * PI) * 2), x, int(y), Pal.CANVAS.lerp(Pal.LEATHER, 0.4))
	return b


static func gorge_fall(frame: int) -> PixBuf:
	## The bridge's broken ropes hanging into the canyon.
	var b := gorge(0)
	for y in range(60, 100):
		for x in range(140, 200):
			b.pset(x, y, b.pget(x, 120))
	for k in 6:
		var x0 := 140 + k * 2
		for y in range(64, 64 + 40 + k * 4):
			b.pset(x0 + int(sin(y * 0.2 + frame + k) * 2.0), y, Pal.WOOD.lerp(Pal.DUST, 0.2))
	return b


static func pass_night(frame: int) -> PixBuf:
	## The Pass of Teeth: jagged peaks against stars.
	var b := PixBuf.new(W, H)
	gradient(b, NIGHT, 0, 140)
	stars(b, 160, 120, 61, frame)
	moon(b, 250, 26, 7)
	for x in W:
		var h := 40.0 + absf(sin(x * 0.045)) * 50.0 + Pal.hash2(x / 7, 3) * 14.0
		if (x / 7) % 3 == 0:
			h += 12.0 * (1.0 - absf(float(x % 7) - 3.0) / 3.5)
		for y in range(int(150 - h), H):
			b.pset(x, y, Pal.INK.lerp(Pal.SLATE, 0.25))
	ground(b, 142, Pal.SLATE.lerp(Pal.INK, 0.55), Pal.SLATE.lerp(Pal.INK, 0.35))
	return b


static func pass_dawn(frame: int) -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, DAWN, 0, 140)
	sun(b, 160, 126, 18, Pal.LEMON.lerp(Pal.CANDLE, 0.3))
	for x in W:
		var h := 40.0 + absf(sin(x * 0.045)) * 50.0 + Pal.hash2(x / 7, 3) * 14.0
		if (x / 7) % 3 == 0:
			h += 12.0 * (1.0 - absf(float(x % 7) - 3.0) / 3.5)
		for y in range(int(150 - h), H):
			b.pset(x, y, Pal.DUSK.lerp(Pal.INK, 0.45))
	ground(b, 142, Pal.DUNE.lerp(Pal.INK, 0.5), Pal.CANDLE.lerp(Pal.DUNE, 0.5))
	return b


static func tomb(frame: int) -> PixBuf:
	## Inside the tomb in the rock: carved niches, torchlight, a long dark.
	var b := PixBuf.new(W, H)
	for y in H:
		for x in W:
			var st := Pal.SLATE.lerp(Pal.STONE, 0.25)
			var row := y / 10
			var o := 8 if row % 2 == 0 else 0
			var c := st.lerp(Pal.INK, 0.3 + Pal.hash2((x + o) / 16, row, 3) * 0.2)
			if y % 10 == 0 or (x + o) % 16 == 0:
				c = Pal.shade(c)
			if y > 136:
				c = Pal.SLATE.lerp(Pal.INK, 0.5)
			b.img.set_pixel(x, y, c)
	for k in 4:
		var nx := 30 + k * 80
		b.rect(nx, 50, 30, 50, Pal.INK.lerp(Pal.SLATE, 0.2))
		b.ball(nx + 15, 50, 15, 8, Pal.INK.lerp(Pal.SLATE, 0.2))
	for k in 2:
		var tx := 70 + k * 180
		glow_pool(b, tx, 90, 60 + (frame % 2) * 4, 60, Pal.CANDLE, 0.22)
		b.rect(tx - 1, 76, 3, 10, Pal.WOOD)
		b.rect(tx - 2, 72, 5, 4, Pal.CANDLE.lerp(Pal.LEMON, (frame % 3) * 0.2))
	vignette(b, 1.5)
	return b


static func shop() -> PixBuf:
	## Dosha's shop: shelves of other people's things, a lamp, a curtain.
	var b := PixBuf.new(W, H)
	for y in H:
		for x in W:
			var c := Pal.PLUM.lerp(Pal.WOOD, 0.4)
			if y > 120:
				c = Pal.WOOD.lerp(Pal.INK, 0.3) if (y - 120) % 8 != 0 else Pal.WOOD.lerp(Pal.INK, 0.45)
			b.img.set_pixel(x, y, c)
	for row in 3:
		var sy := 30 + row * 30
		b.rect(10, sy, 300, 3, Pal.WOOD)
		for k in 18:
			var ix := 16 + k * 16 + int(Pal.hash2(k, row) * 4)
			var cols := [Pal.BRASS, Pal.CLAY, Pal.TEAL, Pal.CANVAS, Pal.ROSE, Pal.STEEL]
			var c: Color = cols[(k + row) % cols.size()]
			b.ball(ix, sy - 5, 4, 5, c)
	glow_pool(b, 160, 120, 140, 70, Pal.CANDLE, 0.2)
	vignette(b, 1.6)
	return b


static func tavern(frame: int) -> PixBuf:
	## A tavern at night, for a legend drinking alone.
	var b := PixBuf.new(W, H)
	for y in H:
		for x in W:
			var c := Pal.WOOD.lerp(Pal.BARK, 0.4)
			if x % 26 == 0:
				c = Pal.shade(c)
			if y > 126:
				c = Pal.BARK.lerp(Pal.INK, 0.3)
			b.img.set_pixel(x, y, c)
	# wanted posters plastered on the wall, all of them him
	for k in 7:
		var p := ArtProps.poster(0)
		b.blit(p, 30 + k * 40 + int(Pal.hash2(k, 1) * 8), 30 + int(Pal.hash2(k, 2) * 30))
	glow_pool(b, 160, 120, 90, 50, Pal.CANDLE, 0.22 + (frame % 2) * 0.02)
	vignette(b, 1.6)
	return b


static func memory(frame: int) -> PixBuf:
	## A memory that isn't Rook's: a battlefield in another age, washed violet.
	var b := PixBuf.new(W, H)
	gradient(b, [Pal.INK, Pal.PURPLE.lerp(Pal.INK, 0.5), Pal.LILAC.lerp(Pal.OMEN, 0.3)], 0, 130)
	for k in 14:
		var x := 10 + k * 23
		var h := 20 + int(Pal.hash2(k, 5) * 30)
		b.rect(x, 130 - h, 2, h, Pal.INK.lerp(Pal.PURPLE, 0.3))
		b.rect(x - 4, 130 - h, 10, 6, Pal.INK.lerp(Pal.PURPLE, 0.3) if k % 3 != 0 else Color(0, 0, 0, 0))
	ground(b, 130, Pal.PLUM.lerp(Pal.INK, 0.4), Pal.OMEN.lerp(Pal.PLUM, 0.6))
	for k in 30:
		var x := int(Pal.hash2(k, 1, frame) * W)
		var y := int(Pal.hash2(k, 2, frame) * 130)
		b.pset(x, y, Pal.OMEN.lerp(Pal.WHITE, 0.5))
	return b


static func road_far(frame: int) -> PixBuf:
	## A long empty road into the morning, for someone walking away.
	var b := PixBuf.new(W, H)
	gradient(b, DAWN, 0, 118)
	sun(b, 160, 112, 12, Pal.LEMON.lerp(Pal.CANDLE, 0.3))
	mesa(b, 114, Pal.DUSK.lerp(Pal.INK, 0.35), 29)
	ground(b, 120, Pal.DUNE.lerp(Pal.INK, 0.4), Pal.CANDLE.lerp(Pal.DUNE, 0.4), 0.5)
	for y in range(120, H):
		var t := float(y - 120) / (H - 120)
		var hw := 2.0 + t * 70.0
		for x in range(int(160 - hw), int(160 + hw)):
			if Pal.hash2(x, y, 9) > 0.12:
				b.pset(x, y, Pal.DIRT.lerp(Pal.INK, 0.25 + t * 0.2))
	return b


static func sea_road(frame: int) -> PixBuf:
	## Beyond the border: the road running down to a grey sea.
	var b := PixBuf.new(W, H)
	gradient(b, [Color("6e7e8a"), Color("a8b0a8"), Color("d8d0b0")], 0, 96)
	for y in range(96, 130):
		for x in W:
			var c := Pal.WATER.lerp(Pal.SKY, 0.4)
			if (x + frame * 2 + y * 3) % 17 == 0:
				c = Pal.hi(c)
			b.img.set_pixel(x, y, c)
	ground(b, 128, Pal.SCRUB.lerp(Pal.DUNE, 0.5), Pal.hi(Pal.SCRUB))
	return b
