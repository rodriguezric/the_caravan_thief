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
## Ground that frays into its neighbours rather than meeting them at a seam.
const SOFT := ".:=sgrx"
const ROAD := 61  # "="


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
	# the map as character codes, and which codes are soft ground, for the
	# per-pixel blending below
	var grid := PackedInt32Array()
	for ty in th:
		for tx in tw:
			grid.append((rows[ty] as String).unicode_at(tx))
	var soft := PackedByteArray()
	soft.resize(65536)
	for i in SOFT.length():
		soft[SOFT.unicode_at(i)] = 1
	# how much track surrounds each tile; interpolated, it bridges road tiles
	# that only touch at a corner so a diagonal track stays one band
	var road := []
	for ty in th:
		var r := PackedFloat32Array()
		for tx in tw:
			var sum := 0.0
			for k in 9:
				if at.call(tx + k % 3 - 1, ty + k / 3 - 1) == "=":
					sum += 2.0 if k == 4 else 1.0
			r.append(sum / 10.0)
		road.append(r)
	var road_at := func(fx: float, fy: float) -> float:
		var x0 := clampi(floori(fx), 0, tw - 1)
		var y0 := clampi(floori(fy), 0, th - 1)
		var x1 := mini(x0 + 1, tw - 1)
		var y1 := mini(y0 + 1, th - 1)
		var ax := clampf(fx - floorf(fx), 0.0, 1.0)
		var ay := clampf(fy - floorf(fy), 0.0, 1.0)
		var top := lerpf(road[y0][x0], road[y0][x1], ax)
		var bot := lerpf(road[y1][x0], road[y1][x1], ax)
		return lerpf(top, bot, ay)
	for ty in th:
		for tx in tw:
			var ch: String = at.call(tx, ty)
			var below: String = at.call(tx, ty + 1)
			var below2: String = at.call(tx, ty + 2)
			# only tiles bordering different soft ground (or near a track) blend
			var mixed := false
			var near_road := false
			if SOFT.contains(ch):
				for k in 9:
					var nc: String = at.call(tx + k % 3 - 1, ty + k / 3 - 1)
					if nc != ch and SOFT.contains(nc):
						mixed = true
						near_road = near_road or nc == "=" or ch == "="
			var mode := "floor"
			var vote: Array[Vector3i] = []
			vote.resize(TILE / 2)
			# a window or door marked on either row of a two-tile face spans both
			var feat := ch
			if ch == " ":
				mode = "void"
			elif is_wall(ch):
				if not is_wall(below):
					mode = "face_low"
					var above: String = at.call(tx, ty - 1)
					if not "WD".contains(ch) and "WD".contains(above):
						feat = above
				elif not is_wall(below2) and below != " ":
					mode = "face_high"
					if not "WD".contains(ch) and "WD".contains(below):
						feat = below
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
							c = _wall_face(theme, feat, x, y, lx, ly + (0 if mode == "face_high" else TILE))
						_:
							# soft ground blends across tile corners (so a staircase of
							# road tiles reads as one diagonal band) and frays along a
							# ragged, dithered edge instead of stopping at the tile seam
							# (the vote runs once per 2x2 block, reused for the odd row)
							if mixed and lx % 2 == 0 and ly % 2 == 0:
								var gx := tx
								var gy := ty
								var edge := false
								var gc_road := false
								var wx := x + Pal.noise(x * 2.3, y * 2.3, 7.0) * 3.5 + (Pal.hash2(x, y, 31) - 0.5) * 3.0
								var wy := y + Pal.noise(y * 2.1, x * 2.1, 3.0) * 3.5 + (Pal.hash2(x, y, 32) - 0.5) * 3.0
								var fx := wx / TILE - 0.5
								var fy := wy / TILE - 0.5
								var x0 := floori(fx)
								var y0 := floori(fy)
								var ax := fx - x0
								var ay := fy - y0
								# bilinear vote among the four nearest tile centres
								var cs := PackedInt32Array([0, 0, 0, 0])
								var ws := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
								var total := 0.0
								for k in 4:
									var cx := x0 + k % 2
									var cy := y0 + k / 2
									if cx < 0 or cy < 0 or cx >= tw or cy >= th:
										continue
									var cc := grid[cy * tw + cx]
									if soft[cc] == 0:
										continue
									var wgt := (ax if k % 2 == 1 else 1.0 - ax) * (ay if k / 2 == 1 else 1.0 - ay)
									total += wgt
									for j in 4:
										if cs[j] == cc or cs[j] == 0:
											cs[j] = cc
											ws[j] += wgt
											break
								var bi := 0
								for j in range(1, 4):
									if ws[j] > ws[bi]:
										bi = j
								if cs[bi] != 0 and cs[bi] != grid[ty * tw + tx]:
									for k in 4:
										var cx := x0 + k % 2
										var cy := y0 + k / 2
										if cx >= 0 and cy >= 0 and cx < tw and cy < th and grid[cy * tw + cx] == cs[bi]:
											gx = cx
											gy = cy
											break
								edge = total > 0.0 and ws[bi] / total < 0.6
								if near_road and cs[bi] != ROAD and road_at.call(fx, fy) > 0.32:
									gc_road = true
								vote[lx / 2] = Vector3i(gx, gy, (1 if edge else 0) | (2 if gc_road else 0))
							var v := vote[lx / 2] if mixed else Vector3i(tx, ty, 0)
							var gc: String = "=" if v.z & 2 else at.call(v.x, v.y)
							c = _floor(theme, gc, x, y, lx, ly, at, v.x, v.y)
							if v.z & 1 and gc == "=":
								# the track's worn shoulder
								c = c.lerp(Pal.DIRT.lerp(Pal.INK, 0.2), 0.3)
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
	if lx < 2 or lx > 13 or fy < 3:
		return wall
	var c := Pal.WOOD.lerp(Pal.CLAY, 0.15)
	if theme in ["ruin", "tomb"]:
		# an open round-topped arch with a lit keystone ring, dark beyond
		var dx := absf(lx - 7.5)
		var top := 4 + int(roundf(pow(maxf(0.0, dx - 1.5), 2.0) / 3.0))
		if fy < top - 2:
			return wall
		if fy < top:
			return Pal.hi(wall) if fy == top - 2 else Pal.shade(wall)
		if lx == 2 or lx == 13:
			return Pal.shade(wall)
		if fy == top or lx == 3 or lx == 12:
			return Pal.INK2.lerp(Pal.SLATE, 0.25)
		return Pal.INK.lerp(Pal.INK2, 0.3 if fy > 26 else 0.0)
	if fy < 6:
		return wall
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
			# a worn dirt track: trodden patches, wheel scuffs and grit, no
			# tile-aligned ruts so it can bend and run diagonally
			c = Pal.DIRT.lerp(Pal.SAND, 0.32 + n * 0.12)
			var wear := Pal.noise(x * 0.7, y * 1.4, 11.0)
			if wear > 0.45:
				c = Pal.DIRT.lerp(Pal.SAND, 0.18)
			elif wear < -0.5:
				c = Pal.DIRT.lerp(Pal.DUST, 0.45)
			var cell := Vector2i(x / 6, y / 4)
			var hc := Pal.hash2(cell.x, cell.y, 41)
			if hc > 0.72 and y % 4 == 1 and x % 6 < 2 + int(hc * 4.0) % 3:
				c = Pal.shade(Pal.DIRT)
			if hs > 0.965:
				c = Pal.DIRT.lerp(Pal.STONE, 0.45)
			elif hs < 0.02:
				c = Pal.hi(Pal.DIRT.lerp(Pal.SAND, 0.4))
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
			# stony ground: dust strewn with pebbles that catch the light
			c = Pal.DUST.lerp(Pal.SAND, 0.45 + n * 0.18)
			if Pal.noise(x * 0.9, y * 0.9, 5.0) > 0.55:
				c = Pal.DUST.lerp(Pal.SAND, 0.3)
			c = _pebbles(c, x, y, 5, 0.55, Pal.STONE.lerp(Pal.DUST, 0.35))
		"x":
			# rubble: broken paving slabs, tilted and cracked, sand in the gaps
			c = Pal.DUST.lerp(Pal.SAND, 0.35 + n * 0.15)
			var row := y / 5
			var o := (row * 4) % 7
			var cx := (x + o) / 7
			var hc := Pal.hash2(cx, row, 12)
			var px := (x + o) % 7
			var py := y % 5
			var cut_l := int(Pal.hash2(cx, row, 13) * 2.0)
			var cut_r := 5 - int(Pal.hash2(cx, row, 14) * 2.0)
			var cut_b := 3 + int(Pal.hash2(cx, row, 15) * 2.0)
			if hc > 0.38 and px >= cut_l and px <= cut_r and py <= cut_b:
				var stone := Pal.STONE.lerp(Pal.SAND, 0.15 + Pal.hash2(cx, row, 16) * 0.25)
				c = stone
				if py == 0:
					c = Pal.hi(stone)
				elif py == cut_b or px == cut_r:
					c = Pal.shade(stone)
				if hc > 0.9 and px == 1 + py % 3:
					c = Pal.shade(stone)
			elif hc > 0.38 and py == cut_b + 1 and px >= cut_l and px <= cut_r:
				c = Pal.shade(c)
			else:
				c = _pebbles(c, x, y, 4, 0.7, Pal.STONE.lerp(Pal.DUST, 0.25))
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


static func _pebbles(c: Color, x: int, y: int, size: int, chance: float, stone: Color) -> Color:
	## A scatter of small stones, one at most per size x size cell, each with a
	## lit top and a shadow beneath.
	var cx := x / size
	var cy := y / size
	if Pal.hash2(cx, cy, 33) < chance:
		return c
	var sx := cx * size + 1 + int(Pal.hash2(cx, cy, 34) * (size - 2))
	var sy := cy * size + int(Pal.hash2(cx, cy, 35) * (size - 2))
	var w := 1 + int(Pal.hash2(cx, cy, 36) * 2.0)
	if x < sx or x >= sx + w:
		return c
	if y == sy:
		return Pal.hi(stone)
	if y == sy + 1:
		return stone if w > 1 and Pal.hash2(cx, cy, 37) > 0.4 else Pal.shade(c)
	if y == sy + 2 and w > 1:
		return Pal.shade(c)
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
