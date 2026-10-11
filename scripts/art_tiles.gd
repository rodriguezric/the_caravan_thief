class_name ArtTiles
## Field ground: one image per map, built pixel by pixel from the tile rows, so
## seams, wear and drifts of sand never visibly repeat. Walls are seen in 3/4
## view: the two wall rows above a floor become a 32 px face.
## Tiles: # wall, W window wall, D door, A arch (open doorway in a wall face),
## space void, . floor (by theme), = dirt track, s sand, g scrub, r rocky ground,
## : flagstones / cobbles, , rug, b bridge planks, c chasm, w well water,
## x rubble, p wooden deck.
## Themes: road, ruin, town, wagon, gorge, tomb.

const TILE := 16
const WALLS := "#WD "
const SOLID := "#WD wc"


static func is_wall(ch: String) -> bool:
	return WALLS.contains(ch)


static func is_solid(ch: String) -> bool:
	return SOLID.contains(ch)


static func ground(rows: Array, theme: String) -> Image:
	var tw: int = (rows[0] as String).length()
	var th: int = rows.size()
	var img := Image.create_empty(tw * TILE, th * TILE, false, Image.FORMAT_RGBA8)
	var at := func(tx: int, ty: int) -> String:
		if tx < 0 or ty < 0 or tx >= tw or ty >= th:
			return " "
		return (rows[ty] as String)[tx]
	for ty in th:
		for tx in tw:
			var ch: String = at.call(tx, ty)
			var below: String = at.call(tx, ty + 1)
			var below2: String = at.call(tx, ty + 2)
			var mode := "floor"
			if ch == " ":
				mode = "void"
			elif is_wall(ch):
				if not is_wall(below):
					mode = "face_low"
				elif not is_wall(below2) and below != " ":
					mode = "face_high"
				else:
					mode = "top"
			for ly in TILE:
				for lx in TILE:
					var x := tx * TILE + lx
					var y := ty * TILE + ly
					var c: Color
					match mode:
						"void":
							c = _void(theme, x, y)
						"top":
							c = _wall_top(theme, x, y)
						"face_high", "face_low":
							c = _wall_face(theme, ch, x, y, lx, ly + (0 if mode == "face_high" else TILE))
						_:
							c = _floor(theme, ch, x, y, lx, ly, at, tx, ty)
					img.set_pixel(x, y, c)
	# soft contact shadow under every wall face, and a dark lip where ground meets the chasm
	for ty in th:
		for tx in tw:
			var ch: String = at.call(tx, ty)
			if not is_wall(ch) and is_wall(at.call(tx, ty - 1)) and at.call(tx, ty - 1) != " ":
				for lx in TILE:
					for k in 3:
						var x := tx * TILE + lx
						var y := ty * TILE + k
						img.set_pixel(x, y, img.get_pixel(x, y).lerp(Pal.INK, 0.35 - k * 0.1))
			if ch == "c" and at.call(tx, ty - 1) != "c" and not is_wall(at.call(tx, ty - 1)):
				# the near cliff edge drops away: a lit lip, then a rock face
				for lx in TILE:
					for k in 6:
						var x := tx * TILE + lx
						var y := ty * TILE + k
						var rock := Pal.DUNE.lerp(Pal.CLAY, 0.3)
						var cc := Pal.hi(rock) if k == 0 else (rock if k < 3 else Pal.shade(rock))
						if Pal.hash2(x, y, 3) > 0.8:
							cc = Pal.shade(cc)
						img.set_pixel(x, y, cc)
	return img


static func water_overlay(rows: Array, theme: String, frame: int) -> Image:
	## Glints on well water and the haze rising from the chasm; the world flips
	## through frames.
	var tw: int = (rows[0] as String).length()
	var th: int = rows.size()
	var img := Image.create_empty(tw * TILE, th * TILE, false, Image.FORMAT_RGBA8)
	for ty in th:
		for tx in tw:
			var ch: String = (rows[ty] as String)[tx]
			if ch != "w" and ch != "c":
				continue
			for ly in TILE:
				for lx in TILE:
					var x := tx * TILE + lx
					var y := ty * TILE + ly
					if ch == "c":
						if Pal.hash2(x, y + frame * 3, 51) > 0.993:
							img.set_pixel(x, y, Color(Pal.CREAM, 0.25))
						continue
					var k := sin((x + frame * 4) * 0.35 + sin(y * 0.4) * 1.5) + sin(y * 0.9 - frame * 0.8)
					if k > 1.75 and (x + y) % 2 == 0:
						img.set_pixel(x, y, Color(Pal.hi(Pal.WATER), 0.7))
	return img


static func _void(theme: String, x: int, y: int) -> Color:
	return Pal.INK


static func _wall_top(theme: String, x: int, y: int) -> Color:
	match theme:
		"road", "gorge":
			# the top of the canyon wall: dusty rock with scrub tufts
			var n := Pal.noise(x * 1.3, y * 1.3, 4.0)
			var c := Pal.DUNE.lerp(Pal.INK, 0.35)
			if n > 0.35:
				c = Pal.DUNE.lerp(Pal.INK, 0.22)
			elif n < -0.4:
				c = Pal.CLAY.lerp(Pal.INK, 0.5)
			if Pal.hash2(x, y, 5) > 0.985:
				c = Pal.SCRUB.lerp(Pal.INK, 0.3)
			return c
		"town":
			# tiled roofs
			var c := Pal.CLAY.lerp(Pal.INK, 0.35)
			if y % 4 == 0:
				c = Pal.shade(c)
			if (x + (y / 4) * 3) % 7 == 0:
				c = Pal.deep(c)
			return c
		"wagon":
			return Pal.CANVAS.lerp(Pal.INK, 0.45) if (x / 5) % 2 == 0 else Pal.CANVAS.lerp(Pal.INK, 0.52)
	var base := Pal.SLATE.lerp(Pal.INK, 0.5)
	if (x / 32 + y / 32) % 2 == 0:
		base = base.lerp(Pal.INK, 0.12)
	if Pal.hash2(x, y, 9) > 0.99:
		base = Pal.SCRUB.lerp(Pal.INK, 0.4)
	return base


static func _wall_face(theme: String, ch: String, x: int, y: int, lx: int, fy: int) -> Color:
	## fy: 0..31 down the two-tile face.
	var c: Color
	match theme:
		"road", "gorge":
			# layered sandstone cliff, banded and cracked
			var band := (fy + int(sin(x * 0.11) * 2.0)) / 5
			var rock: Color = [Pal.DUNE, Pal.SAND.lerp(Pal.DUNE, 0.4), Pal.CLAY.lerp(Pal.DUNE, 0.5), Pal.DUNE.lerp(Pal.DUST, 0.4)][band % 4]
			c = rock
			if (fy + int(sin(x * 0.11) * 2.0)) % 5 == 0:
				c = Pal.shade(rock)
			if Pal.hash2(x / 3, y / 5, 7) > 0.93:
				c = Pal.deep(rock)
			if fy <= 1:
				c = Pal.hi(rock)
			elif fy >= 29:
				c = Pal.shade(Pal.DUST)
		"ruin", "tomb":
			# old masonry, big blocks, mortar gone, cracks
			var stone := Pal.STONE.lerp(Pal.SAND, 0.2) if theme == "ruin" else Pal.SLATE.lerp(Pal.STONE, 0.35)
			var row := fy / 8
			var o := 6 if row % 2 == 0 else 0
			c = stone.lerp(Pal.DUST, Pal.hash2((x + o) / 12, row + y / 32 * 4, 3) * 0.3)
			if fy % 8 == 0 or (x + o) % 12 == 0:
				c = Pal.shade(stone)
			if Pal.hash2(x, y, 11) > 0.985:
				c = Pal.deep(stone)
			if fy <= 1:
				c = Pal.hi(stone)
			elif fy >= 29:
				c = Pal.shade(stone).lerp(Pal.SCRUB, 0.3 if theme == "ruin" else 0.0)
		"town":
			# whitewashed plaster over a timber frame, stained at the foot
			var plaster := Pal.CANVAS.lerp(Pal.WHITE, 0.25)
			c = plaster
			if Pal.hash2(x / 2, y / 2, 5) > 0.93:
				c = plaster.lerp(Pal.SAND, 0.5)
			if fy <= 2 or fy >= 27 or x % 32 == 0 or x % 32 == 1:
				c = Pal.WOOD.lerp(Pal.BARK, 0.3)
			if fy == 3:
				c = Pal.shade(plaster)
			if fy >= 24 and fy < 27:
				c = plaster.lerp(Pal.DUST, 0.35)
		"wagon":
			var plank := Pal.WOOD.lerp(Pal.CLAY, 0.15)
			c = plank if fy % 5 != 0 else Pal.shade(plank)
			if (x + (fy / 5) * 7) % 19 == 0:
				c = Pal.shade(plank)
			if fy <= 6:
				c = Pal.CANVAS.lerp(Pal.DUST, 0.2) if (x / 6) % 2 == 0 else Pal.CANVAS.lerp(Pal.DUST, 0.35)
			if fy == 7:
				c = Pal.deep(plank)
		_:
			c = Pal.STONE
	if ch == "W":
		c = _window(theme, x, y, lx, fy, c)
	elif ch == "D":
		c = _door(theme, lx, fy, c)
	return c


static func _window(theme: String, x: int, y: int, lx: int, fy: int, wall: Color) -> Color:
	if fy < 7 or fy > 21 or lx < 3 or lx > 12:
		return wall
	var frame := Pal.WOOD.lerp(Pal.BARK, 0.3)
	if fy == 7 or fy == 21 or lx == 3 or lx == 12:
		return frame
	if theme == "town":
		# shutters half open, warm inside
		if lx < 5 or lx > 10:
			return Pal.TEAL.lerp(Pal.SLATE, 0.3) if fy % 3 != 0 else Pal.shade(Pal.TEAL)
		return Pal.CANDLE.lerp(Pal.ORANGE, 0.4) if Pal.hash2(x / 16, y / 16, 4) > 0.4 else Pal.INK2
	# an arrow slit onto the sky
	if lx >= 7 and lx <= 8:
		return Pal.SKY.lerp(Pal.DUSK, float(fy - 7) / 14.0)
	return wall


static func _door(theme: String, lx: int, fy: int, wall: Color) -> Color:
	if lx < 2 or lx > 13 or fy < 6:
		return wall
	var c := Pal.WOOD.lerp(Pal.CLAY, 0.15)
	if theme in ["ruin", "tomb"]:
		# an open arch, dark beyond
		if lx == 2 or lx == 13 or fy == 6:
			return Pal.shade(wall)
		return Pal.INK.lerp(Pal.INK2, 0.3 if fy > 26 else 0.0)
	if lx == 2 or lx == 13 or fy == 6:
		return Pal.deep(c)
	if lx == 11 and fy == 19:
		return Pal.BRASS
	return c if lx % 4 != 1 else Pal.shade(c)


static func _floor(theme: String, ch: String, x: int, y: int, lx: int, ly: int, at: Callable, tx: int, ty: int) -> Color:
	var n := Pal.noise(x, y, 2.0)
	var hs := Pal.hash2(x, y)
	var c: Color
	match ch:
		",":
			var rug := Pal.ROSE.lerp(Pal.PLUM, 0.3)
			c = rug
			var edge_x: bool = at.call(tx - 1, ty) != "," and lx < 2 or at.call(tx + 1, ty) != "," and lx > 13
			var edge_y: bool = at.call(tx, ty - 1) != "," and ly < 2 or at.call(tx, ty + 1) != "," and ly > 13
			if edge_x or edge_y:
				c = Pal.BRASS.lerp(Pal.ROSE, 0.4)
			elif (x + y) % 6 == 0 or (x - y) % 6 == 0:
				c = rug.lerp(Pal.LEMON, 0.14)
		":":
			var stone := Pal.STONE.lerp(Pal.SAND, 0.25) if theme != "tomb" else Pal.SLATE.lerp(Pal.STONE, 0.4)
			var o := 4 if (y / 8) % 2 == 0 else 0
			c = stone.lerp(Pal.DUST, Pal.hash2((x + o) / 8, y / 8, 3) * 0.35)
			if (x + o) % 8 == 0 or y % 8 == 0:
				c = Pal.shade(stone)
			if hs > 0.99:
				c = Pal.SCRUB
		"=":
			# a wheel-rutted dirt track
			c = Pal.DIRT.lerp(Pal.SAND, 0.3 + n * 0.15)
			var ru := ly % 16
			if ru == 4 or ru == 11:
				c = Pal.shade(Pal.DIRT)
			if hs > 0.96:
				c = Pal.DIRT.lerp(Pal.STONE, 0.4)
			c = _blend_edge(c, ch, at, tx, ty, lx, ly, Pal.SAND.lerp(Pal.DIRT, 0.3))
		"s":
			c = Pal.SAND.lerp(Pal.DUNE, 0.2 + n * 0.25)
			if (y + int(sin(x * 0.2) * 3.0)) % 9 == 0:
				c = Pal.SAND.lerp(Pal.DUNE, 0.55)
			if hs > 0.97:
				c = Pal.hi(Pal.SAND)
		"g":
			c = Pal.SAND.lerp(Pal.SCRUB, 0.45 + n * 0.2)
			if hs > 0.93:
				c = Pal.SCRUB.lerp(Pal.LEAF, 0.4)
			elif hs < 0.04:
				c = Pal.SCRUB.lerp(Pal.LEMON, 0.3)
		"r":
			c = Pal.DUST.lerp(Pal.SAND, 0.4 + n * 0.2)
			if Pal.hash2(x / 3, y / 3, 6) > 0.86:
				c = Pal.STONE.lerp(Pal.DUST, 0.3)
				if Pal.hash2(x / 3, y / 3 + 1, 6) <= 0.86:
					c = Pal.shade(c)
		"x":
			c = Pal.STONE.lerp(Pal.DUST, 0.4 + n * 0.2)
			if Pal.hash2(x / 4, y / 3, 12) > 0.75:
				c = Pal.STONE.lerp(Pal.SAND, 0.2)
				if ly % 3 == 2:
					c = Pal.shade(c)
		"b":
			# bridge planks across the gorge, gaps between them
			var plank := Pal.WOOD.lerp(Pal.DUST, 0.25)
			var row := x / 6
			c = plank.lerp(Pal.BARK, Pal.hash2(row, 0, 3) * 0.25)
			if x % 6 == 0:
				c = Pal.INK.lerp(Pal.BARK, 0.3) if Pal.hash2(row, 1, 4) > 0.3 else Pal.deep(plank)
			if ly == 1 or ly == 14:
				c = Pal.LEATHER.lerp(Pal.CANVAS, 0.3)
		"p":
			var plank := Pal.WOOD.lerp(Pal.PEACH, 0.2)
			var row := y / 5
			c = plank.lerp(Pal.BARK, Pal.hash2(row, (x + row * 11) / 20, 3) * 0.2)
			if y % 5 == 0:
				c = Pal.shade(plank)
			elif (x + row * 11) % 20 == 0:
				c = Pal.deep(plank)
		"c":
			# the gorge: rock faces falling away into dark
			var depth := clampf(float(ly + (0 if at.call(tx, ty - 1) != "c" else 16)) / 32.0, 0.0, 1.0)
			c = Pal.CLAY.lerp(Pal.INK, 0.55 + depth * 0.4)
			if Pal.hash2(x / 2, y / 4, 13) > 0.88:
				c = c.lerp(Pal.DUNE, 0.15)
		"w":
			c = Pal.WATER.lerp(Pal.INK, 0.2 + n * 0.1)
		_:
			c = _base_floor(theme, x, y, lx, ly, n, hs)
	return c


static func _blend_edge(c: Color, ch: String, at: Callable, tx: int, ty: int, lx: int, ly: int, edge: Color) -> Color:
	## Ragged edges where a track meets other ground.
	var j := int(Pal.hash2(tx * 16 + lx, ty * 16 + ly, 21) * 3.0)
	if at.call(tx - 1, ty) != ch and lx < j or at.call(tx + 1, ty) != ch and lx > 15 - j:
		return edge
	if at.call(tx, ty - 1) != ch and ly < j or at.call(tx, ty + 1) != ch and ly > 15 - j:
		return edge
	return c


static func _base_floor(theme: String, x: int, y: int, lx: int, ly: int, n: float, hs: float) -> Color:
	var c: Color
	match theme:
		"wagon":
			var plank := Pal.WOOD.lerp(Pal.PEACH, 0.2)
			var row := y / 5
			c = plank.lerp(Pal.BARK, Pal.hash2(row, (x + row * 11) / 22, 3) * 0.2)
			if y % 5 == 0 or (x + row * 11) % 22 == 0:
				c = Pal.shade(plank)
		"ruin", "tomb":
			var stone := Pal.STONE.lerp(Pal.DUST, 0.35) if theme == "ruin" else Pal.SLATE.lerp(Pal.STONE, 0.3)
			c = stone.lerp(Pal.SAND, n * 0.15 + 0.1)
			if (x + (y / 12) * 5) % 12 == 0 or y % 12 == 0:
				c = Pal.shade(stone)
			if hs > 0.985:
				c = Pal.SCRUB
			elif hs < 0.01:
				c = Pal.deep(stone)
		"town":
			var stone := Pal.SAND.lerp(Pal.STONE, 0.4)
			var o := 3 if (y / 6) % 2 == 0 else 0
			c = stone.lerp(Pal.DUST, Pal.hash2((x + o) / 6, y / 6, 3) * 0.3)
			if (x + o) % 6 == 0 or y % 6 == 0:
				c = Pal.shade(stone)
		_:
			c = Pal.SAND.lerp(Pal.DUST, 0.3 + n * 0.2)
			if hs > 0.96:
				c = Pal.shade(c)
	return c
