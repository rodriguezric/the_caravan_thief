class_name ArtProps
## Wagons, crates, tents, stalls and shrine stones, drawn with the same shape
## tools and the same hand-placed light (hi() on top edges, shade() under).
## Placed on the field by their bottom centre so they y-sort with characters.


static func make(kind: String, v: int = 0) -> PixBuf:
	var b: PixBuf
	match kind:
		"wagon": b = wagon(v)
		"wagon_broken": b = wagon_broken()
		"wheel": b = wheel(v)
		"crate": b = crate(v)
		"barrel": b = barrel()
		"sacks": b = sacks(v)
		"chest": b = chest(v)
		"sealed_chest": b = sealed_chest(v)
		"tent": b = tent(v)
		"campfire": b = campfire(v)
		"embers": b = campfire(3)
		"lantern": b = lantern(v)
		"lamp_post": b = lamp_post(v)
		"well": b = well()
		"rock": b = rock(v)
		"boulder": b = boulder(v)
		"bush": b = bush(v)
		"dead_tree": b = dead_tree(v)
		"sign": b = sign_post()
		"stall": b = stall(v)
		"poster": b = poster(v)
		"bedroll": b = bedroll(v)
		"banner": b = banner(v)
		"statue": b = statue(v)
		"altar": b = altar(v)
		"sarcophagus": b = sarcophagus(v)
		"tomb_door": b = tomb_door(v)
		"rope_post": b = rope_post()
		"pillar": b = pillar(v)
		"rubble": b = rubble(v)
		"table": b = table(v)
		"stool": b = stool()
		"desk": b = desk(v)
		"rack": b = rack()
		"hay": b = hay()
		"trough": b = trough()
		"handcart": b = handcart()
		"pot": b = pot(v)
		"cushion": b = cushion(v)
		"sword_prop": b = sword_prop(v)
		"ledger_prop": b = ledger_prop()
		"payroll": b = payroll_chest()
		"fence": b = fence()
		"stairs": b = stairs()
		"waterskin": b = waterskin()
		_:
			b = PixBuf.new(4, 4)
	return b


static func _frame(b: PixBuf) -> PixBuf:
	b.outline()
	return b


# ---------------------------------------------------------------- caravan --

static func wagon(v: int) -> PixBuf:
	## A covered caravan wagon seen from the side: canvas hoops over a wooden
	## bed, two big wheels. v: canvas colour (0 cream, 1 striped, 2 the Factor's).
	var b := PixBuf.new(64, 46)
	var wood := Pal.WOOD.lerp(Pal.CLAY, 0.15)
	var canvas: Color = [Pal.CANVAS, Pal.CANVAS.lerp(Pal.CLAY, 0.25), Pal.WHITE.lerp(Pal.CANVAS, 0.5)][v % 3]
	# canvas cover
	b.ball(32, 18, 26, 15, canvas)
	b.rect(6, 18, 52, 12, canvas)
	for k in 4:
		var hx := 12 + k * 13
		b.rect(hx, 5 + int(absf(k - 1.5)), 1, 25, Pal.shade(canvas))
	if v % 3 == 1:
		for k in range(8, 56, 8):
			b.rect(k, 8, 3, 22, Pal.CLAY.lerp(canvas, 0.3))
	if v % 3 == 2:
		# the Factor's wagon: a brass seal painted on the canvas
		b.circ(32, 18, 5, Pal.BRASS.lerp(canvas, 0.3))
		b.circ(32, 18, 3, canvas)
		b.rect(31, 16, 2, 4, Pal.BRASS.lerp(canvas, 0.3))
	b.rect(6, 4 + 22, 52, 1, Pal.shade(canvas))
	# wooden bed
	b.rect(3, 29, 58, 7, wood)
	b.rect(3, 29, 58, 1, Pal.hi(wood))
	b.rect(3, 35, 58, 1, Pal.shade(wood))
	for k in range(8, 60, 10):
		b.rect(k, 30, 1, 5, Pal.shade(wood))
	# shaft
	b.rect(58, 33, 6, 2, Pal.shade(wood))
	_wheel_at(b, 15, 37, 8.0, wood, v)
	_wheel_at(b, 49, 37, 8.0, wood, v + 1)
	return _frame(b)


static func _wheel_at(b: PixBuf, x: float, y: float, r: float, wood: Color, spin: int) -> void:
	b.circ(x, y, r, Pal.shade(wood))
	b.circ(x, y, r - 1.6, Pal.INK2.lerp(wood, 0.25))
	for k in 6:
		var a := k * PI / 3.0 + spin * 0.3
		b.cap(x, y, x + cos(a) * (r - 1.5), y + sin(a) * (r - 1.5), 0.6, wood)
	b.circ(x, y, 1.6, Pal.BRASS.lerp(wood, 0.4))
	b.rect(x - r + 1, y - r + 1, 2, 1, Pal.hi(wood))


static func wagon_broken() -> PixBuf:
	## The stranded wagon: tilted onto a cracked axle, one wheel lying beside.
	var b := PixBuf.new(66, 46)
	var w := wagon(1)
	var img := w.img.duplicate() as Image
	var tmp := PixBuf.new(66, 46)
	# shear the wagon down at the back to fake the tilt
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				var dy := int((64 - x) / 16.0) if x < 30 else 0
				tmp.pset(x + 1, y + dy - 2, c)
	b.blit(tmp, 0, 0)
	# cover the fallen wheel area with the axle stub and dirt
	b.rect(10, 38, 12, 5, Pal.CLAY.lerp(Pal.DUST, 0.5))
	b.rect(12, 37, 4, 2, Pal.shade(Pal.WOOD))
	return b


static func wheel(v: int) -> PixBuf:
	## A loose wheel lying flat (v 0) or leaning upright (v 1).
	var b := PixBuf.new(20, 20)
	var wood := Pal.WOOD.lerp(Pal.CLAY, 0.15)
	if v == 0:
		b.ell(10, 14, 9, 4, Pal.shade(wood))
		b.ell(10, 14, 7, 2.8, Pal.INK2.lerp(wood, 0.3))
		b.line(3, 14, 17, 14, wood)
		b.line(6, 12, 14, 16, wood)
		b.line(6, 16, 14, 12, wood)
		b.circ(10, 14, 1.4, Pal.BRASS)
	else:
		_wheel_at(b, 10, 10, 8.5, wood, 1)
		b.rect(8, 6, 4, 1, Pal.RED.lerp(wood, 0.3))
	return _frame(b)


static func crate(v: int) -> PixBuf:
	var b := PixBuf.new(18, 18)
	var w := Pal.WOOD.lerp(Pal.SAND, 0.3) if v == 0 else Pal.WOOD.lerp(Pal.CLAY, 0.2)
	b.rect(1, 3, 16, 14, w)
	b.rect(1, 3, 16, 3, Pal.hi(w))
	b.rect(1, 6, 16, 1, Pal.shade(w))
	b.line(2, 7, 15, 16, Pal.shade(w))
	b.rect(1, 16, 16, 1, Pal.shade(w))
	b.rect(1, 3, 1, 14, Pal.shade(w))
	b.rect(16, 3, 1, 14, Pal.shade(w))
	if v == 1:
		b.rect(6, 10, 5, 3, Pal.CANVAS)
		b.pset(8, 11, Pal.RED)
	return _frame(b)


static func barrel() -> PixBuf:
	var b := PixBuf.new(16, 20)
	var w := Pal.WOOD.lerp(Pal.CLAY, 0.1)
	b.ball(8, 11, 7, 8, w)
	b.ell(8, 4, 6, 2, Pal.shade(w))
	b.ell(8, 4, 5, 1.4, Pal.WOOD.lerp(Pal.BARK, 0.4))
	b.rect(1, 7, 14, 1, Pal.SLATE)
	b.rect(1, 15, 14, 1, Pal.SLATE)
	return _frame(b)


static func sacks(v: int) -> PixBuf:
	var b := PixBuf.new(24, 16)
	var s := Pal.CANVAS.lerp(Pal.DUST, 0.25)
	b.ball(8, 10, 7, 5, s)
	b.ball(17, 11, 6, 4.5, Pal.shade(s).lerp(s, 0.5))
	if v != 0:
		b.ball(12, 5, 5, 4, s)
		b.rect(11, 1, 2, 2, Pal.LEATHER)
	b.rect(6, 5, 3, 1, Pal.LEATHER)
	b.pset(9, 11, Pal.ORANGE)
	b.pset(10, 12, Pal.LEMON)
	return _frame(b)


static func chest(v: int) -> PixBuf:
	## An ordinary strongbox (v 1: open, coins inside).
	var b := PixBuf.new(18, 16)
	var w := Pal.WOOD.lerp(Pal.CLAY, 0.2)
	b.rect(1, 6, 16, 9, w)
	b.rect(1, 6, 16, 1, Pal.hi(w))
	b.rect(1, 9, 16, 1, Pal.BRASS.lerp(w, 0.3))
	if v == 1:
		b.rect(2, 2, 14, 5, Pal.shade(w))
		b.rect(3, 5, 12, 2, Pal.BRASS)
		b.pset(5, 5, Pal.LEMON)
		b.pset(10, 5, Pal.LEMON)
	else:
		b.ball(9, 6, 8, 3, w)
		b.rect(8, 8, 2, 3, Pal.BRASS)
	return _frame(b)


static func sealed_chest(v: int) -> PixBuf:
	## The Factor's chest: long, wrapped in cream cloth, bound in chain, sealed
	## with a dozen wax seals. v 1: opened, cloth thrown back, the blade inside.
	var b := PixBuf.new(34, 20)
	var w := Pal.BARK.lerp(Pal.INK2, 0.2)
	var cloth := Pal.WHITE.lerp(Pal.CANVAS, 0.4)
	b.rect(1, 7, 32, 12, w)
	b.rect(1, 18, 32, 1, Pal.shade(w))
	if v == 0:
		b.ball(17, 7, 16, 4, cloth)
		b.rect(1, 7, 32, 5, cloth)
		b.rect(1, 11, 32, 1, Pal.shade(cloth))
		for x in [6, 16, 27]:
			b.rect(x, 3, 2, 16, Pal.SLATE)
			for y in range(4, 18, 3):
				b.pset(x, y, Pal.STEEL)
		for k in 6:
			var sx := 3 + k * 5.5
			b.circ(sx, 9 + (k % 2) * 4, 1.4, Pal.RED.lerp(Pal.ROSE, 0.3))
			b.pset(int(sx), 9 + (k % 2) * 4, Pal.hi(Pal.RED))
	else:
		b.rect(2, 8, 30, 8, Pal.INK2)
		b.rect(2, 8, 30, 2, cloth)
		# the blade lying in the cloth
		var steel := Pal.STEEL.lerp(Pal.INK2, 0.35)
		b.rect(9, 12, 21, 2, steel)
		for x in range(11, 29, 2):
			b.pset(x, 12, Pal.OMEN.lerp(steel, 0.25))
		b.rect(7, 10, 2, 6, Pal.BRASS.lerp(Pal.INK2, 0.35))
		b.rect(3, 12, 4, 2, Pal.LEATHER)
		b.pset(3, 12, Pal.OMEN)
		b.ball(17, 3, 16, 3, cloth)
	return _frame(b)


static func payroll_chest() -> PixBuf:
	var b := PixBuf.new(22, 18)
	var w := Pal.SLATE.lerp(Pal.WOOD, 0.3)
	b.rect(1, 6, 20, 11, w)
	b.ball(11, 6, 10, 3.5, w)
	b.rect(1, 6, 20, 1, Pal.hi(w))
	for x in [4, 17]:
		b.rect(x, 3, 2, 14, Pal.BRASS.lerp(w, 0.2))
	b.rect(9, 8, 4, 4, Pal.BRASS)
	b.pset(10, 9, Pal.INK)
	return _frame(b)


# ------------------------------------------------------------------- camp --

static func tent(v: int) -> PixBuf:
	## A canvas tent; v 1 is a striped merchant's tent, v 2 has its flap open.
	var b := PixBuf.new(40, 30)
	var c := Pal.CANVAS.lerp(Pal.DUST, 0.15) if v != 1 else Pal.CANVAS.lerp(Pal.CLAY, 0.2)
	b.tri(2, 28, 38, 28, 20, 3, c)
	b.tri(20, 3, 38, 28, 28, 28, Pal.shade(c))
	if v == 1:
		for k in range(4):
			b.line(20, 3, 6 + k * 8, 28, Pal.CLAY.lerp(c, 0.3))
	if v == 2:
		b.tri(14, 28, 26, 28, 20, 12, Pal.INK2)
		b.tri(20, 12, 14, 28, 10, 26, Pal.hi(c))
	else:
		b.line(20, 12, 20, 28, Pal.shade(c))
	b.rect(19, 0, 2, 4, Pal.WOOD)
	b.rect(1, 27, 38, 1, Pal.shade(c))
	return _frame(b)


static func campfire(v: int) -> PixBuf:
	## Stones, logs and a flickering fire (v 0..2), or just embers (v 3).
	var b := PixBuf.new(20, 20)
	for k in 7:
		var a := k * TAU / 7.0
		b.ball(10 + cos(a) * 7, 15 + sin(a) * 3, 2.0, 1.4, Pal.STONE.lerp(Pal.DUST, 0.3))
	b.cap(4, 16, 15, 13, 1.2, Pal.BARK)
	b.cap(5, 13, 16, 16, 1.2, Pal.WOOD)
	if v == 3:
		b.pset(9, 14, Pal.ORANGE)
		b.pset(11, 15, Pal.RED)
		b.pset(12, 14, Pal.ORANGE)
		return _frame(b)
	var flame := [Pal.RED.lerp(Pal.ORANGE, 0.4), Pal.ORANGE, Pal.LEMON]
	for k in 4:
		var fx := 6.5 + k * 2.4
		var hgt := 6 + int(Pal.hash2(k, v, 3) * 6)
		b.tri(fx - 2, 15, fx + 2, 15, fx + (v + k) % 3 - 1, 15 - hgt, flame[0])
		b.tri(fx - 1, 15, fx + 1, 15, fx + (v + k) % 2, 15 - hgt * 0.6, flame[1])
	b.rect(8, 12, 4, 3, flame[2])
	return _frame(b)


static func lantern(v: int) -> PixBuf:
	var b := PixBuf.new(8, 12)
	b.rect(3, 0, 2, 2, Pal.SLATE)
	b.rect(1, 2, 6, 1, Pal.SLATE)
	b.rect(1, 3, 6, 6, Pal.CANDLE.lerp(Pal.LEMON, 0.3 if v % 2 == 0 else 0.5))
	b.rect(1, 3, 1, 6, Pal.SLATE)
	b.rect(6, 3, 1, 6, Pal.SLATE)
	b.rect(1, 9, 6, 1, Pal.SLATE)
	return _frame(b)


static func lamp_post(v: int) -> PixBuf:
	var b := PixBuf.new(12, 34)
	b.rect(5, 8, 2, 25, Pal.WOOD.lerp(Pal.BARK, 0.3))
	b.rect(3, 31, 6, 2, Pal.BARK)
	b.rect(5, 6, 6, 1, Pal.WOOD.lerp(Pal.BARK, 0.3))
	var l := lantern(v)
	b.blit(l, 4, 6)
	return _frame(b)


static func well() -> PixBuf:
	var b := PixBuf.new(30, 30)
	var stone := Pal.STONE.lerp(Pal.SAND, 0.25)
	b.ball(15, 22, 13, 6, stone)
	b.ell(15, 20, 10, 3.6, Pal.INK2)
	b.ell(15, 21, 8, 2.4, Pal.WATER.lerp(Pal.INK, 0.4))
	for k in 8:
		b.rect(3 + k * 3, 23 + (k % 2), 1, 2, Pal.shade(stone))
	b.rect(3, 4, 2, 18, Pal.WOOD)
	b.rect(25, 4, 2, 18, Pal.WOOD)
	b.rect(2, 3, 26, 2, Pal.WOOD.lerp(Pal.BARK, 0.2))
	b.rect(14, 5, 1, 9, Pal.CANVAS)
	b.rect(12, 13, 5, 4, Pal.WOOD)
	return _frame(b)


static func rock(v: int) -> PixBuf:
	var b := PixBuf.new(16, 12)
	var c := Pal.STONE.lerp(Pal.DUNE, 0.3 + 0.1 * (v % 3))
	b.ball(8, 7, 7 - v % 2, 4.5, c)
	if v % 2 == 0:
		b.ball(12, 9, 3, 2.4, Pal.shade(c))
	return _frame(b)


static func boulder(v: int) -> PixBuf:
	var b := PixBuf.new(30, 26)
	var c := Pal.DUNE.lerp(Pal.CLAY, 0.25 + v * 0.1)
	b.ball(15, 15, 13, 10, c)
	b.ball(22, 18, 6, 6, Pal.shade(c))
	b.line(8, 10, 14, 16, Pal.shade(c))
	b.rect(6, 23, 20, 1, Pal.shade(c))
	return _frame(b)


static func bush(v: int) -> PixBuf:
	var b := PixBuf.new(18, 14)
	var c := Pal.SCRUB.lerp(Pal.LEAF, 0.3 * (v % 2))
	for k in 5:
		b.ball(4 + k * 2.6, 9 - (k % 2) * 2, 3.4, 3.0, c)
	for k in 4:
		b.pset(4 + k * 3, 5 + k % 2, Pal.hi(c))
	if v == 2:
		b.pset(8, 7, Pal.RED)
		b.pset(12, 6, Pal.RED)
	return _frame(b)


static func dead_tree(v: int) -> PixBuf:
	var b := PixBuf.new(34, 44)
	var c := Pal.BARK.lerp(Pal.DUST, 0.3)
	b.cap(17, 43, 16, 20, 2.4, c)
	b.cap(16, 26, 7, 12, 1.4, c)
	b.cap(7, 12, 4, 6, 0.9, c)
	b.cap(16, 22, 27, 9, 1.4, c)
	b.cap(27, 9, 31, 7, 0.8, c)
	b.cap(22, 15, 22, 4, 0.9, c)
	if v == 1:
		# a crow on the branch
		b.ball(25, 6, 2.6, 2.0, Pal.INK2)
		b.pset(26, 5, Pal.OMEN)
	return _frame(b)


static func sign_post() -> PixBuf:
	var b := PixBuf.new(22, 26)
	b.rect(10, 6, 2, 19, Pal.WOOD)
	b.poly([Vector2(2, 3), Vector2(17, 3), Vector2(20, 6), Vector2(17, 9), Vector2(2, 9)], Pal.WOOD.lerp(Pal.SAND, 0.3))
	b.rect(4, 5, 10, 1, Pal.shade(Pal.WOOD))
	b.rect(4, 7, 7, 1, Pal.shade(Pal.WOOD))
	return _frame(b)


static func fence() -> PixBuf:
	var b := PixBuf.new(18, 14)
	for x in [2, 9, 15]:
		b.rect(x, 2, 2, 12, Pal.WOOD)
	b.rect(0, 5, 18, 2, Pal.WOOD.lerp(Pal.SAND, 0.2))
	b.rect(0, 9, 18, 2, Pal.WOOD.lerp(Pal.SAND, 0.2))
	return _frame(b)


static func bedroll(v: int) -> PixBuf:
	var b := PixBuf.new(26, 12)
	var c: Color = [Pal.SAGE, Pal.ROSE.lerp(Pal.DUST, 0.3), Pal.BLUE.lerp(Pal.DUST, 0.3), Pal.CLAY][v % 4]
	b.rect(2, 3, 22, 7, c)
	b.rect(2, 3, 22, 1, Pal.hi(c))
	b.rect(2, 9, 22, 1, Pal.shade(c))
	b.ball(5, 6, 3, 3, Pal.CANVAS)
	b.rect(14, 3, 1, 7, Pal.shade(c))
	return _frame(b)


static func hay() -> PixBuf:
	var b := PixBuf.new(20, 14)
	b.ball(10, 8, 9, 5, Pal.LEMON.lerp(Pal.DUNE, 0.4))
	for k in 8:
		b.pset(3 + k * 2, 5 + k % 3, Pal.shade(Pal.LEMON.lerp(Pal.DUNE, 0.4)))
	return _frame(b)


static func trough() -> PixBuf:
	var b := PixBuf.new(26, 12)
	b.rect(1, 3, 24, 8, Pal.WOOD)
	b.rect(3, 4, 20, 3, Pal.WATER)
	b.rect(1, 3, 24, 1, Pal.hi(Pal.WOOD))
	return _frame(b)


static func handcart() -> PixBuf:
	var b := PixBuf.new(30, 20)
	b.rect(2, 6, 20, 7, Pal.WOOD)
	b.rect(2, 6, 20, 1, Pal.hi(Pal.WOOD))
	b.rect(22, 9, 8, 1, Pal.WOOD)
	_wheel_at(b, 12, 14, 5.0, Pal.WOOD, 0)
	b.ball(8, 5, 5, 3, Pal.CANVAS)
	b.ball(15, 4, 4, 3, Pal.CANVAS.lerp(Pal.CLAY, 0.2))
	return _frame(b)


static func pot(v: int) -> PixBuf:
	var b := PixBuf.new(12, 14)
	var c := Pal.CLAY if v == 0 else Pal.CLAY.lerp(Pal.SAND, 0.4)
	b.ball(6, 8, 5, 5, c)
	b.rect(4, 2, 4, 3, c)
	b.rect(3, 2, 6, 1, Pal.hi(c))
	b.rect(2, 8, 8, 1, Pal.ORANGE.lerp(c, 0.3))
	return _frame(b)


static func waterskin() -> PixBuf:
	## A leather water bag with a stoppered neck and a strap, thrown in S6.
	var b := PixBuf.new(12, 12)
	var c := Pal.WOOD.lerp(Pal.CLAY, 0.35)
	b.ball(6, 7, 4, 4, c)
	b.rect(3, 5, 6, 1, Pal.hi(c))
	b.rect(3, 10, 6, 1, Pal.shade(c))
	b.rect(5, 1, 2, 3, Pal.shade(c))
	b.rect(5, 1, 2, 1, Pal.CANVAS)
	b.pset(2, 4, Pal.shade(Pal.WOOD))
	b.pset(3, 3, Pal.shade(Pal.WOOD))
	b.pset(4, 2, Pal.shade(Pal.WOOD))
	return _frame(b)


static func cushion(v: int) -> PixBuf:
	var b := PixBuf.new(14, 8)
	var c: Color = [Pal.ROSE, Pal.PURPLE, Pal.TEAL][v % 3]
	b.ball(7, 4, 6, 3, c)
	b.pset(7, 4, Pal.BRASS)
	return _frame(b)


# ------------------------------------------------------------------- town --

static func stall(v: int) -> PixBuf:
	## A market stall with a striped awning and wares on the counter.
	var b := PixBuf.new(42, 36)
	var aw: Color = [Pal.CLAY, Pal.TEAL, Pal.PURPLE, Pal.SAGE][v % 4]
	b.rect(3, 10, 2, 24, Pal.WOOD)
	b.rect(37, 10, 2, 24, Pal.WOOD)
	b.poly([Vector2(0, 4), Vector2(42, 4), Vector2(40, 12), Vector2(2, 12)], aw)
	for k in range(0, 42, 6):
		b.poly([Vector2(k, 4), Vector2(k + 3, 4), Vector2(k + 3, 12), Vector2(k, 12)], Pal.CANVAS)
	for k in range(0, 42, 6):
		b.ball(k + 3, 12, 3, 1.6, aw if (k / 6) % 2 == 0 else Pal.CANVAS)
	b.rect(1, 22, 40, 10, Pal.WOOD.lerp(Pal.SAND, 0.2))
	b.rect(1, 22, 40, 1, Pal.hi(Pal.WOOD))
	var wares: Array = [[Pal.ORANGE, Pal.LEMON, Pal.RED], [Pal.BRASS, Pal.STEEL, Pal.BRASS], [Pal.PURPLE, Pal.ROSE, Pal.TEAL], [Pal.SCRUB, Pal.LEMON, Pal.GRASS]][v % 4]
	for k in 7:
		b.ball(6 + k * 5, 20, 2.2, 1.8, wares[k % 3])
	return _frame(b)


static func poster(v: int) -> PixBuf:
	## A wanted poster (v 0) or a notice (v 1), pinned to a wall.
	var b := PixBuf.new(14, 16)
	b.rect(1, 1, 12, 14, Pal.CANVAS.lerp(Pal.WHITE, 0.3))
	b.rect(1, 14, 12, 1, Pal.shade(Pal.CANVAS))
	if v == 0:
		b.rect(3, 2, 8, 1, Pal.RED)
		b.ball(7, 7, 3, 3, Pal.DUST)
		b.rect(5, 5, 4, 2, Pal.INK2)
		b.pset(6, 7, Pal.INK)
		b.pset(8, 7, Pal.INK)
		b.rect(7, 8, 2, 2, Pal.DUST.lerp(Pal.INK2, 0.3))
		b.rect(3, 11, 8, 1, Pal.INK2)
		b.rect(4, 13, 6, 1, Pal.INK2)
	else:
		for y in range(3, 13, 2):
			b.rect(3, y, 8 - (y % 4), 1, Pal.INK2.lerp(Pal.CANVAS, 0.3))
	b.pset(7, 1, Pal.SLATE)
	return _frame(b)


static func banner(v: int) -> PixBuf:
	var b := PixBuf.new(14, 26)
	var c: Color = [Pal.RED.lerp(Pal.ROSE, 0.3), Pal.TEAL, Pal.WHITE.lerp(Pal.CANVAS, 0.4)][v % 3]
	b.rect(1, 1, 12, 1, Pal.WOOD)
	b.poly([Vector2(2, 2), Vector2(12, 2), Vector2(12, 22), Vector2(7, 18), Vector2(2, 22)], c)
	b.rect(5, 6, 4, 4, Pal.BRASS.lerp(c, 0.3))
	return _frame(b)


static func table(v: int) -> PixBuf:
	var b := PixBuf.new(32, 20)
	var top := Pal.WOOD.lerp(Pal.PEACH, 0.15)
	b.rect(4, 11, 2, 8, Pal.shade(top))
	b.rect(26, 11, 2, 8, Pal.shade(top))
	b.rect(1, 4, 30, 9, top)
	b.rect(1, 4, 30, 1, Pal.hi(top))
	b.rect(1, 11, 30, 2, Pal.shade(top))
	if v == 1:
		# a spread of loot and coins
		b.ball(8, 7, 3, 1.5, Pal.BRASS)
		b.pset(9, 6, Pal.LEMON)
		b.rect(14, 6, 6, 3, Pal.PURPLE)
		b.rect(22, 6, 4, 3, Pal.CLAY)
	elif v == 2:
		b.rect(8, 6, 6, 4, Pal.CANVAS)
		b.ell(22, 8, 3, 1.5, Pal.WHITE)
	return _frame(b)


static func stool() -> PixBuf:
	var b := PixBuf.new(12, 12)
	b.rect(2, 3, 8, 3, Pal.WOOD)
	b.rect(2, 3, 8, 1, Pal.hi(Pal.WOOD))
	b.rect(3, 6, 1, 5, Pal.shade(Pal.WOOD))
	b.rect(8, 6, 1, 5, Pal.shade(Pal.WOOD))
	return _frame(b)


static func desk(v: int) -> PixBuf:
	## The Factor's writing desk inside his wagon: neat, cream, a closed ledger.
	var b := PixBuf.new(28, 22)
	var w := Pal.WOOD.lerp(Pal.INK2, 0.2)
	b.rect(1, 8, 26, 13, w)
	b.rect(1, 8, 26, 1, Pal.hi(w))
	b.rect(3, 11, 10, 8, Pal.shade(w))
	b.rect(15, 11, 10, 8, Pal.shade(w))
	b.pset(8, 15, Pal.BRASS)
	b.pset(20, 15, Pal.BRASS)
	if v == 0:
		b.rect(6, 4, 10, 4, Pal.CREAM)
		b.rect(6, 4, 2, 4, Pal.BRASS)
		b.rect(19, 3, 1, 5, Pal.WHITE)
		b.rect(18, 7, 3, 1, Pal.INK2)
	return _frame(b)


static func rack() -> PixBuf:
	var b := PixBuf.new(22, 26)
	b.rect(2, 4, 2, 21, Pal.WOOD)
	b.rect(18, 4, 2, 21, Pal.WOOD)
	b.rect(2, 8, 18, 2, Pal.WOOD)
	b.rect(2, 20, 18, 2, Pal.WOOD)
	for x in [6, 11, 15]:
		b.rect(x, 1, 1, 22, Pal.WOOD.lerp(Pal.SAND, 0.2))
		b.tri(x - 1, 2, x + 2, 2, x + 0.5, -1, Pal.STEEL)
	return _frame(b)


# ---------------------------------------------------------- ruins & tomb --

static func statue(v: int) -> PixBuf:
	## A weathered statue of a sword-bearer, its face worn completely away.
	## v 0 standing, v 1 kneeling, v 2 broken off at the waist.
	var b := PixBuf.new(26, 46)
	var st := Pal.STONE.lerp(Pal.DUST, 0.2)
	b.rect(3, 38, 20, 7, Pal.shade(st))
	b.rect(3, 38, 20, 1, Pal.hi(st))
	if v == 2:
		b.ball(13, 33, 7, 5, st)
		b.rect(6, 28, 14, 3, Pal.shade(st))
		return _frame(b)
	var kneel := v == 1
	var by := 38.0
	var top := 8.0 if not kneel else 14.0
	b.poly([Vector2(8, top + 9), Vector2(18, top + 9), Vector2(20, by), Vector2(6, by)], st)
	b.ball(13, top + 3, 5, 5.5, st)
	b.ball(13, top + 4, 3.5, 3.6, Pal.shade(st))
	# the blade, point down, hands resting on the pommel
	b.rect(12, top + 12, 2, by - top - 13, Pal.shade(st))
	b.rect(9, top + 11, 8, 2, st)
	b.ball(13, top + 10, 3, 2, Pal.hi(st))
	for k in 5:
		b.pset(int(7 + k * 3), int(top + 18 + (k % 2) * 6), Pal.deep(st))
	return _frame(b)


static func altar(v: int) -> PixBuf:
	var b := PixBuf.new(32, 22)
	var st := Pal.STONE.lerp(Pal.SLATE, 0.2)
	b.rect(3, 8, 26, 13, st)
	b.rect(1, 6, 30, 3, Pal.hi(st))
	b.rect(3, 20, 26, 1, Pal.shade(st))
	# carved inscription rows
	for y in [12, 15, 18]:
		for x in range(6, 26, 2):
			if Pal.hash2(x, y, 31) > 0.35:
				b.pset(x, y, Pal.deep(st))
	if v == 1:
		# a violet light pooled where the blade was laid
		b.rect(6, 5, 20, 1, Pal.OMEN)
	return _frame(b)


static func sarcophagus(v: int) -> PixBuf:
	var b := PixBuf.new(36, 18)
	var st := Pal.SLATE.lerp(Pal.STONE, 0.3)
	b.rect(1, 5, 34, 12, st)
	b.rect(1, 3, 34, 4, Pal.hi(st))
	b.rect(1, 16, 34, 1, Pal.shade(st))
	if v == 1:
		b.rect(4, 4, 28, 2, Pal.INK2)
	for x in range(4, 33, 4):
		b.pset(x, 11, Pal.shade(st))
	return _frame(b)


static func tomb_door(v: int) -> PixBuf:
	## The door in the rock that the map promised: v 0 sealed, v 1 open.
	var b := PixBuf.new(40, 44)
	var st := Pal.SLATE.lerp(Pal.DUNE, 0.25)
	b.rect(2, 4, 36, 40, st)
	b.ball(20, 6, 18, 6, st)
	b.rect(6, 8, 28, 36, Pal.shade(st))
	if v == 1:
		b.rect(8, 10, 24, 34, Pal.INK)
		b.ball(20, 11, 12, 3, Pal.INK)
	else:
		b.rect(8, 10, 24, 34, Pal.deep(st))
		b.rect(19, 10, 2, 34, Pal.INK2)
		# the faceless bearer carved in relief
		b.ball(14, 18, 2.5, 3, st)
		b.rect(12, 21, 5, 10, st)
		b.ball(26, 18, 2.5, 3, st)
		b.rect(24, 21, 5, 10, st)
		b.rect(18, 34, 4, 3, Pal.BRASS.lerp(st, 0.5))
	for x in range(3, 38, 5):
		b.pset(x, 6 + int(Pal.hash2(x, 2) * 3), Pal.deep(st))
	return _frame(b)


static func pillar(v: int) -> PixBuf:
	var b := PixBuf.new(16, 42)
	var st := Pal.STONE.lerp(Pal.SAND, 0.2)
	var h := 40 if v == 0 else 22
	b.rect(3, 42 - h, 10, h - 2, st)
	b.rect(3, 42 - h, 3, h - 2, Pal.hi(st))
	b.rect(10, 42 - h, 3, h - 2, Pal.shade(st))
	b.rect(1, 39, 14, 3, Pal.shade(st))
	if v == 0:
		b.rect(1, 2, 14, 3, Pal.hi(st))
	else:
		b.tri(3, 42 - h, 13, 42 - h, 8, 42 - h - 3, st)
	return _frame(b)


static func rubble(v: int) -> PixBuf:
	var b := PixBuf.new(22, 12)
	var st := Pal.STONE.lerp(Pal.DUST, 0.3)
	for k in 5:
		b.ball(3 + k * 4 + Pal.hash2(k, v) * 2, 8 - Pal.hash2(k, v, 3) * 3, 2.6, 2.0, st if k % 2 == 0 else Pal.shade(st))
	return _frame(b)


static func rope_post() -> PixBuf:
	## A bridge post with its rope rail.
	var b := PixBuf.new(10, 24)
	b.rect(3, 4, 4, 20, Pal.WOOD.lerp(Pal.BARK, 0.2))
	b.rect(3, 4, 4, 1, Pal.hi(Pal.WOOD))
	b.rect(2, 8, 6, 2, Pal.CANVAS.lerp(Pal.LEATHER, 0.4))
	return _frame(b)


static func stairs() -> PixBuf:
	var b := PixBuf.new(32, 20)
	var st := Pal.STONE.lerp(Pal.SAND, 0.2)
	for k in 4:
		b.rect(k * 2, 4 + k * 4, 32 - k * 4, 4, st if k % 2 == 0 else Pal.shade(st))
		b.rect(k * 2, 4 + k * 4, 32 - k * 4, 1, Pal.hi(st))
	return _frame(b)


# ------------------------------------------------------------- close-ups --

static func sword_prop(v: int) -> PixBuf:
	## The blade presented on its own, large, for close-ups: point down, the
	## grasping guard, the violet stone. v 1: carved with ROOK, v 2: a crow.
	var b := PixBuf.new(40, 120)
	var steel := Pal.STEEL.lerp(Pal.INK2, 0.3)
	b.poly([Vector2(16, 30), Vector2(24, 30), Vector2(23, 108), Vector2(20, 118), Vector2(17, 108)], steel)
	b.rect(16, 30, 2, 78, Pal.hi(steel))
	b.rect(23, 30, 1, 78, Pal.shade(steel))
	for y in range(34, 106, 3):
		b.rect(19.5, y, 1, 2, Pal.OMEN.lerp(steel, 0.2 + 0.2 * sin(y * 0.3)))
	var br := Pal.BRASS.lerp(Pal.INK2, 0.25)
	# the guard: two hands of brass fingers grasping the blade
	b.rect(6, 25, 28, 5, br)
	b.rect(6, 25, 28, 1, Pal.hi(br))
	for k in 4:
		b.rect(6 + k * 2, 30, 1, 5 - k, br)
		b.rect(33 - k * 2, 30, 1, 5 - k, br)
	b.rect(17, 6, 6, 19, Pal.LEATHER)
	for y in range(7, 24, 3):
		b.rect(17, y, 6, 1, Pal.shade(Pal.LEATHER))
	b.ball(20, 5, 5, 5, Pal.PURPLE.lerp(Pal.OMEN, 0.4))
	b.ball(20, 5, 3, 3, Pal.OMEN)
	b.pset(18, 3, Pal.WHITE)
	if v == 1:
		for x in [9, 11, 13, 15, 25, 27, 29, 31]:
			b.pset(x, 27, Pal.CREAM)
	elif v == 2:
		b.ascii(["X...X", ".XXX.", "..X.."], {"X": Pal.CREAM}, 25, 26)
	return _frame(b)


static func ledger_prop() -> PixBuf:
	var b := PixBuf.new(40, 30)
	b.rect(2, 2, 36, 26, Pal.CREAM.lerp(Pal.WHITE, 0.3))
	b.rect(19, 2, 2, 26, Pal.shade(Pal.CREAM))
	for y in range(6, 26, 3):
		b.rect(5, y, 11, 1, Pal.INK2.lerp(Pal.CREAM, 0.4))
		b.rect(24, y, 6 + (y % 5), 1, Pal.INK2.lerp(Pal.CREAM, 0.4))
		b.rect(32, y, 3, 1, Pal.RED.lerp(Pal.CREAM, 0.3))
	b.rect(2, 2, 36, 1, Pal.hi(Pal.CREAM))
	b.rect(2, 27, 36, 1, Pal.BRASS)
	return _frame(b)
