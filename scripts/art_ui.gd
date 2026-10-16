class_name ArtUI
## Boxes, cursors, icons and emote bubbles. Box kinds map to meanings:
## box = default, bar_box = name tabs and small headers, omen_box = the blade
## speaking or showing, gold_box = rewards, red_box = danger, glow_box = trust
## and healing, dim_box = disabled.


static func make(name: String) -> PixBuf:
	match name:
		"box":
			return _box(Pal.DUST.lerp(Pal.CANVAS, 0.35), Pal.PANEL)
		"bar_box":
			return _box(Pal.CLAY.lerp(Pal.BRASS, 0.35), Pal.PANEL2)
		"omen_box":
			return _box(Pal.OMEN.lerp(Pal.PURPLE, 0.45), Pal.PLUM.lerp(Pal.INK, 0.55))
		"gold_box":
			return _box(Pal.BRASS.lerp(Pal.LEMON, 0.3), Pal.PANEL)
		"red_box":
			return _box(Pal.BLOOD.lerp(Pal.ROSE, 0.4), Pal.PANEL2)
		"glow_box":
			return _box(Pal.GLOW.lerp(Pal.SAGE, 0.5), Pal.PANEL2)
		"dim_box":
			return _box(Pal.INK2.lerp(Pal.DUST, 0.25), Pal.PANEL2)
		"cursor":
			var b := PixBuf.new(7, 9)
			b.ascii(["X......", "XX.....", "XWX....", "XWWX...", "XWWWX..", "XWWX...", "XWX....", "XX.....", "X......"], {"X": Pal.INK, "W": Pal.CANDLE})
			return b
		"cursor_r":
			var b := PixBuf.new(7, 9)
			b.ascii(["......X", ".....XX", "....XWX", "...XWWX", "..XWWWX", "...XWWX", "....XWX", ".....XX", "......X"], {"X": Pal.INK, "W": Pal.CANDLE})
			return b
		"down":
			var b := PixBuf.new(9, 7)
			b.ascii(["XXXXXXXXX", "XWWWWWWWX", ".XWWWWWX.", "..XWWWX..", "...XWX...", "....X....", "........."], {"X": Pal.INK, "W": Pal.CANDLE})
			return b
		"marker":
			var b := PixBuf.new(9, 9)
			b.ascii(["..XXXXX..", ".XWWWWWX.", "XWWWWWWWX", ".XWWWWWX.", "..XWWWX..", "...XWX...", "....X...."], {"X": Pal.INK, "W": Pal.CANDLE}, 0, 1)
			return b
		"target":
			var b := PixBuf.new(9, 9)
			b.ascii(["XXXXXXXXX", ".XWWWWWX.", "..XWWWX..", "...XWX...", "....X...."], {"X": Pal.INK, "W": Pal.CANDLE}, 0, 2)
			return b
		"target_omen":
			var b := PixBuf.new(9, 9)
			b.ascii(["XXXXXXXXX", ".XWWWWWX.", "..XWWWX..", "...XWX...", "....X...."], {"X": Pal.INK, "W": Pal.OMEN}, 0, 2)
			return b
		"now":
			var b := PixBuf.new(7, 5)
			b.ascii(["XXXXXXX", ".XWWWX.", "..XWX..", "...X..."], {"X": Pal.INK, "W": Pal.CANDLE})
			return b
		"pip_on":
			var b := PixBuf.new(7, 7)
			b.ascii([".XXX.", "XWGGX", "XGGGX", "XGGGX", ".XXX."], {"X": Pal.INK, "G": Pal.GLOW, "W": Pal.WHITE}, 1, 1)
			return b
		"pip_off":
			var b := PixBuf.new(7, 7)
			b.ascii([".XXX.", "XGGGX", "XGGGX", "XGGGX", ".XXX."], {"X": Pal.INK, "G": Pal.INK2}, 1, 1)
			return b
		"pip_omen":
			var b := PixBuf.new(7, 7)
			b.ascii([".XXX.", "XWGGX", "XGGGX", "XGGGX", ".XXX."], {"X": Pal.INK, "G": Pal.OMEN, "W": Pal.WHITE}, 1, 1)
			return b
		"lock":
			var b := PixBuf.new(9, 10)
			b.ascii(["..XXX..", ".X...X.", ".X...X.", "XXXXXXX", "XSSSSSX", "XSSWSSX", "XSSSSSX", "XXXXXXX"], {"X": Pal.INK, "S": Pal.STONE, "W": Pal.INK2}, 1, 1)
			return b
		"check":
			var b := PixBuf.new(9, 9)
			b.ascii(["......X", ".....XX", "X...XX.", "XX.XX..", ".XXX...", "..X...."], {"X": Pal.GLOW}, 1, 2)
			return b
		"coin":
			var b := PixBuf.new(9, 9)
			b.ascii(["..XXX..", ".XWYYX.", "XWYYYYX", "XYYXYYX", "XYYYYYX", ".XYYYX.", "..XXX.."], {"X": Pal.INK, "Y": Pal.BRASS, "W": Pal.LEMON}, 1, 1)
			return b
		"heart":
			var b := PixBuf.new(9, 9)
			b.ascii([".XX.XX.", "XWRRRRX", "XRRRRRX", ".XRRRX.", "..XRX..", "...X..."], {"X": Pal.INK, "R": Pal.BLOOD, "W": Pal.WHITE}, 1, 1)
			return b
		"eye":
			var b := PixBuf.new(11, 9)
			b.ascii(["...XXXXX...", "..XOOOOOX..", ".XOOXXXOOX.", "XOOXXWXXOOX", ".XOOXXXOOX.", "..XOOOOOX..", "...XXXXX..."], {"X": Pal.INK, "O": Pal.OMEN, "W": Pal.WHITE}, 0, 1)
			return b
		"i_attack":
			var b := PixBuf.new(9, 9)
			b.ascii(["......XX", ".....XWX", "....XWX.", "X..XWX..", "XXXWX...", ".XXX....", ".XXXX...", "XX..X..."], {"X": Pal.INK, "W": Pal.BLOOD.lerp(Pal.WHITE, 0.3)}, 0, 0)
			b.outline()
			return b
		"i_guard":
			var b := PixBuf.new(9, 9)
			b.ascii(["XXXXXXX", "XWWWWWX", "XWWWWWX", "XWWWWWX", ".XWWWX.", "..XWX..", "...X..."], {"X": Pal.INK, "W": Pal.SKY}, 1, 1)
			return b
		"i_skill":
			var b := PixBuf.new(9, 9)
			b.ascii(["...X...", "...X...", ".XXWXX.", "XXWWWXX", ".XXWXX.", "...X...", "...X..."], {"X": Pal.CANDLE, "W": Pal.WHITE}, 1, 1)
			b.outline()
			return b
		"i_flee":
			var b := PixBuf.new(9, 9)
			b.ascii(["....X..", "...XX..", "XXXWWX.", "XWWWWWX", "XXXWWX.", "...XX..", "....X.."], {"X": Pal.INK, "W": Pal.CREAM}, 1, 1)
			return b
		"i_steal":
			var b := PixBuf.new(9, 9)
			b.ascii(["..XXX..", ".XYYYX.", "XYYXYYX", "XYYYYYX", ".XYYYX.", "..XXX.."], {"X": Pal.INK, "Y": Pal.BRASS}, 1, 2)
			return b
		"i_hostile":
			var b := PixBuf.new(9, 9)
			b.ascii(["X.....X", ".X...X.", "..XOX..", "...O...", "..XOX..", ".X...X.", "X.....X"], {"X": Pal.OMEN, "O": Pal.WHITE}, 1, 1)
			return b
		"key_z", "key_x", "key_arrows", "key_shift":
			return _key(name.substr(4))
		"arrow_up", "arrow_down", "arrow_left", "arrow_right":
			return _arrow(name.substr(6), Pal.CANDLE)
	if name.begins_with("t_"):
		return touch(name.substr(2))
	if name.begins_with("emote_"):
		return _emote(name.substr(6))
	if name.begins_with("item_"):
		return item_icon(name.substr(5))
	if name.begins_with("skill_"):
		return skill_icon(name.substr(6))
	if name.begins_with("weapon_"):
		return skill_icon(name)
	if name.begins_with("stat_"):
		return stat_icon(name.substr(5))
	return PixBuf.new(1, 1)


# ------------------------------------------------------------ touch controls --
# Drawn small like everything else and scaled up whole-number by the shell.
# "_on" variants are the pressed look: the face sinks a pixel and brightens.

static func touch(name: String) -> PixBuf:
	var on := name.ends_with("_on")
	if on:
		name = name.trim_suffix("_on")
	var face := Pal.PANEL.lerp(Pal.DUST, 0.3)
	var rim := Pal.DUST.lerp(Pal.CANVAS, 0.35)
	var lit := Pal.CANDLE
	if name.begins_with("pad"):
		# a chunky cross; the pressed arm lights up
		var b := PixBuf.new(37, 37)
		var press := name.substr(4) if name.length() > 3 else ""
		b.rect(12, 1, 13, 35, Pal.INK)
		b.rect(1, 12, 35, 13, Pal.INK)
		b.rect(13, 2, 11, 33, rim)
		b.rect(2, 13, 33, 11, rim)
		b.rect(14, 3, 9, 31, face)
		b.rect(3, 14, 31, 9, face)
		b.rect(14, 3, 9, 1, face.lerp(rim, 0.5))
		b.rect(3, 14, 31, 1, face.lerp(rim, 0.5))
		var arms := {"up": Rect2(14, 3, 9, 11), "down": Rect2(14, 23, 9, 11), "left": Rect2(3, 14, 11, 9), "right": Rect2(23, 14, 11, 9)}
		if arms.has(press):
			var r: Rect2 = arms[press]
			b.rect(r.position.x, r.position.y, r.size.x, r.size.y, face.lerp(lit, 0.35))
		b.ball(18.5, 18.5, 3, 3, Pal.PANEL2)
		var tri := {"up": ["..X..", ".XXX.", "XXXXX"], "down": ["XXXXX", ".XXX.", "..X.."], "left": ["..X", ".XX", "XXX", ".XX", "..X"], "right": ["X..", "XX.", "XXX", "XX.", "X.."]}
		var at := {"up": Vector2i(16, 6), "down": Vector2i(16, 28), "left": Vector2i(6, 16), "right": Vector2i(28, 16)}
		for d in tri:
			b.ascii(tri[d], {"X": Pal.WHITE if d == press else lit}, at[d].x, at[d].y)
		return b
	if name == "joy_base":
		# the floating stick's ring: a dark well with four candle ticks
		var b := PixBuf.new(37, 37)
		b.circ(18.5, 18.5, 18, Pal.INK)
		b.circ(18.5, 18.5, 17, rim)
		b.circ(18.5, 18.5, 15.5, Color(Pal.PANEL2, 0.75))
		b.circ(18.5, 18.5, 9, Color(Pal.PANEL, 0.6))
		for t in [Vector2i(17, 4), Vector2i(17, 31), Vector2i(4, 17), Vector2i(31, 17)]:
			b.rect(t.x, t.y, 3, 3, lit)
		return b
	if name == "joy_knob":
		# the thumb knob; brightens (on) when pushed far enough to run
		var b := PixBuf.new(19, 19)
		b.circ(9.5, 10.5, 8.5, Pal.INK)
		b.circ(9.5, 9.5, 8, rim)
		b.circ(9.5, 9.5, 6.5, face.lerp(lit, 0.45) if on else face)
		b.rect(6, 4, 5, 1, face.lerp(Pal.WHITE, 0.3))
		b.circ(9.5, 9.5, 2, lit if not on else Pal.WHITE)
		return b
	if name in ["a", "b"]:
		var b := PixBuf.new(21, 21)
		var dy := 1 if on else 0
		b.circ(10.5, 11.5, 9.5, Pal.INK)
		b.circ(10.5, 10.5 + dy, 9, rim if name == "a" else Pal.CLAY.lerp(Pal.BRASS, 0.35))
		b.circ(10.5, 10.5 + dy, 7.5, face.lerp(lit, 0.3) if on else face)
		b.rect(6, 4 + dy, 6, 1, face.lerp(Pal.WHITE, 0.25))
		var g: PackedStringArray = (PixFont.GLYPHS[name.to_upper()] as String).split("|")
		for y in g.size():
			for x in g[y].length():
				if g[y][x] == "#":
					b.pset(9 + x, 7 + y + dy, Pal.WHITE if on else Pal.TEXT)
		return b
	if name == "menu":
		# same size and shape as A/B, so it can share B's spot
		var b := PixBuf.new(21, 21)
		var dy := 1 if on else 0
		b.circ(10.5, 11.5, 9.5, Pal.INK)
		b.circ(10.5, 10.5 + dy, 9, Pal.CANDLE.lerp(Pal.PLUM, 0.45))
		b.circ(10.5, 10.5 + dy, 7.5, face.lerp(lit, 0.3) if on else face)
		b.rect(6, 4 + dy, 6, 1, face.lerp(Pal.WHITE, 0.25))
		b.rect(7, 7 + dy, 2, 7, Pal.WHITE if on else lit)
		b.rect(12, 7 + dy, 2, 7, Pal.WHITE if on else lit)
		return b
	if name.begins_with("arrow_"):
		var d := name.substr(6)
		var b := PixBuf.new(25, 25)
		var dy := 1 if on else 0
		b.circ(12.5, 13.5, 11.5, Pal.INK)
		b.circ(12.5, 12.5 + dy, 11, rim)
		b.circ(12.5, 12.5 + dy, 9.5, face.lerp(lit, 0.3) if on else face)
		var g := PixBuf.new(9, 9)
		g.ascii(["....X....", "...XXX...", "..XXXXX..", ".XXXXXXX.", "XXXXXXXXX", "...XXX...", "...XXX...", "...XXX..."], {"X": Pal.WHITE if on else lit})
		match d:
			"down":
				g.img.flip_y()
			"left":
				g.img.rotate_90(COUNTERCLOCKWISE)
			"right":
				g.img.rotate_90(CLOCKWISE)
		b.blit(g, 8, 8 + dy)
		return b
	if name.begins_with("big_"):
		# a wide pill with a word on it: HOLD, MASH, TAP
		var word := name.substr(4).to_upper()
		var tw := 0
		for ch in word:
			tw += (PixFont.GLYPHS[ch] as String).split("|")[0].length() + 1
		var w := maxi(40, tw + 14)
		var b := PixBuf.new(w, 21)
		var dy := 1 if on else 0
		b.rect(2, 1, w - 4, 19, Pal.INK)
		b.rect(1, 2, w - 2, 17, Pal.INK)
		b.rect(2, 2 + dy, w - 4, 16, rim)
		b.rect(3, 3 + dy, w - 6, 14, face.lerp(lit, 0.3) if on else face)
		b.rect(4, 4 + dy, w - 8, 1, face.lerp(Pal.WHITE, 0.25))
		var x := (w - tw) / 2 + 1
		for ch in word:
			var g: PackedStringArray = (PixFont.GLYPHS[ch] as String).split("|")
			for y in g.size():
				for xx in g[y].length():
					if g[y][xx] == "#":
						b.pset(x + xx, 7 + y + dy, Pal.WHITE if on else lit)
			x += g[0].length() + 1
		return b
	return PixBuf.new(1, 1)


static func app_icon() -> PixBuf:
	## The project icon (32x32): the blade, point down, on a dusk tile, with
	## its violet stone and a crow's silhouette against the sky.
	var b := PixBuf.new(32, 32)
	var top := Pal.DUSK.lerp(Pal.CLAY, 0.25)
	var bottom := Pal.INK
	for y in 32:
		for x in 32:
			var cx := minf(x, 31 - x)
			var cy := minf(y, 31 - y)
			if cx + cy < 3 or (cx < 1 or cy < 1):
				continue
			var t := clampf((y - 4) / 22.0, 0.0, 1.0)
			b.pset(x, y, top if t * 16.0 <= ArtCine.BAYER[y % 4][x % 4] else bottom)
	for x in range(3, 29):
		b.pset(x, 1, Pal.CLAY.lerp(Pal.CANDLE, 0.4))
	# the sun going down behind the dunes
	b.ell(16, 22, 9, 6, Pal.CANDLE.lerp(Pal.CLAY, 0.4))
	b.rect(2, 22, 28, 8, Pal.INK2.lerp(Pal.DUNE, 0.25))
	for x in range(2, 30):
		b.pset(x, 22 + int(sin(x * 0.5) * 1.2), Pal.DUNE.lerp(Pal.INK2, 0.3))
	# the blade
	var steel := Pal.STEEL.lerp(Pal.INK2, 0.3)
	b.rect(15, 9, 3, 18, steel)
	b.rect(16, 10, 1, 16, Pal.OMEN.lerp(steel, 0.3))
	b.rect(14, 27, 5, 1, steel)
	b.pset(16, 28, steel)
	b.rect(11, 7, 11, 2, Pal.BRASS.lerp(Pal.INK2, 0.2))
	b.pset(11, 9, Pal.BRASS.lerp(Pal.INK2, 0.2))
	b.pset(21, 9, Pal.BRASS.lerp(Pal.INK2, 0.2))
	b.rect(15, 3, 3, 4, Pal.LEATHER)
	b.rect(15, 2, 3, 2, Pal.OMEN)
	b.pset(15, 2, Pal.WHITE)
	# a crow
	b.ascii(["X...X", ".XXX.", "..X.."], {"X": Pal.INK}, 4, 5)
	b.outline()
	return b


static func _box(border: Color, panel: Color) -> PixBuf:
	var b := PixBuf.new(12, 12)
	b.rect(1, 0, 10, 12, Pal.INK)
	b.rect(0, 1, 12, 10, Pal.INK)
	b.rect(1, 1, 10, 10, border)
	b.rect(2, 2, 8, 8, panel)
	b.rect(2, 2, 8, 1, panel.lerp(border, 0.3))
	return b


static func _key(k: String) -> PixBuf:
	var w: int = 11 if k.length() == 1 else 5 + (PixFont.GLYPHS.get(k[0].to_upper(), "####") as String).split("|")[0].length() * 3
	var b := PixBuf.new(w, 11)
	b.rect(0, 0, w, 10, Pal.INK)
	b.rect(1, 1, w - 2, 8, Pal.CREAM)
	b.rect(1, 8, w - 2, 1, Pal.PEACH)
	return b


static func _arrow(d: String, c: Color, dim: bool = false) -> PixBuf:
	## A chunky arrow button used by the rhythm and QTE minigames.
	d = d.split("_")[0]
	var b := PixBuf.new(15, 15)
	var col := c.lerp(Pal.INK2, 0.6) if dim else c
	b.ball(7.5, 7.5, 7, 7, col)
	var rows := ["...X...", "..XXX..", ".XXXXX.", "XXXXXXX", "..XXX..", "..XXX..", "..XXX.."]
	var g := PixBuf.new(7, 7)
	g.ascii(rows, {"X": Pal.INK if not dim else Pal.INK2})
	match d:
		"down":
			g.img.flip_y()
		"left":
			g.img.rotate_90(COUNTERCLOCKWISE)
		"right":
			g.img.rotate_90(CLOCKWISE)
	b.blit(g, 4, 4)
	b.outline()
	return b


static func _emote(kind: String) -> PixBuf:
	## Speech-bubble emotes that pop over a character's head.
	var b := PixBuf.new(13, 13)
	b.ball(6.5, 5.5, 6, 5, Pal.WHITE)
	b.tri(4, 9, 8, 9, 5, 12.5, Pal.WHITE)
	var m := {"X": Pal.INK, "R": Pal.BLOOD, "B": Pal.BLUE, "O": Pal.OMEN, "Y": Pal.BRASS, "L": Pal.CANDLE}
	match kind:
		"!":
			b.ascii(["X", "X", "X", ".", "X"], m, 6, 3)
		"!!":
			b.ascii(["X.X", "X.X", "X.X", "...", "X.X"], m, 5, 3)
		"?":
			b.ascii([".XX.", "X..X", "..X.", "....", "..X."], m, 5, 3)
		"...":
			b.ascii(["X.X.X"], m, 4, 6)
		"heart":
			b.ascii(["RR.RR", "RRRRR", ".RRR.", "..R.."], m, 4, 3)
		"sweat":
			b.ascii(["..B", ".BB", "BBB", ".B."], m, 5, 3)
		"note":
			b.ascii(["..XX", "..X.", "..X.", "XXX.", "XX.."], m, 4, 3)
		"anger":
			b.ascii(["R.R", ".R.", "R.R"], m, 5, 4)
		"omen":
			b.ascii([".OOO.", "OXXXO", "OXOXO", "OXXXO", ".OOO."], m, 4, 3)
		"coin":
			b.ascii([".YYY.", "YYXYY", "YYXYY", ".YYY."], m, 4, 3)
		"idea":
			b.ascii([".LLL.", "LLLLL", ".LLL.", "..X..", "..X.."], m, 4, 2)
		"zzz":
			b.ascii(["XXX..", "..X..", ".X...", "XXX.X"], m, 4, 3)
		"music":
			b.ascii(["..XX", "..X.", "..X.", "XXX.", "XX.."], m, 4, 3)
	b.outline()
	return b


static func number(n: String, c: Color, big: bool = false) -> PixBuf:
	## Damage and heal numbers; big ones are drawn twice the size for crits.
	var glyphs: Array = []
	var w := 1
	for ch in n:
		var g: PackedStringArray = (PixFont.GLYPHS.get(ch, "") as String).split("|")
		glyphs.append(g)
		w += g[0].length() + 1
	var k := 2 if big else 1
	var b := PixBuf.new(w * k + 2, 10 * k + 1)
	var x := 1
	for g in glyphs:
		for y in g.size():
			for xx in g[y].length():
				if g[y][xx] == "#":
					b.rect((x + xx) * k, (y + 1) * k - (k - 1), k, k, Pal.hi(c) if y < 2 else c)
		x += (g[0] as String).length() + 1
	b.outline()
	return b


# ------------------------------------------------------------------ icons --
# 14 x 14, a 12 x 12 drawing with one outline pass round it: every carried
# thing and supply (Art.ui("item_<id>")), every skill and blade art
# (Art.ui("skill_<id>")) and every crew weapon (Art.ui("weapon_<kind>")).

static func icon_pal() -> Dictionary:
	## The letters the icons are drawn with.
	return {"I": Pal.INK2, "W": Pal.WHITE, "C": Pal.CREAM, "Y": Pal.LEMON, "O": Pal.ORANGE, "H": Pal.HONEY,
		"S": Pal.STEEL, "s": Pal.STEEL.lerp(Pal.WHITE, 0.5), "D": Pal.WOOD, "B": Pal.BARK, "R": Pal.RED, "r": Pal.ROSE,
		"b": Pal.BLOOD, "G": Pal.GLOW, "M": Pal.MINT, "g": Pal.SAGE, "N": Pal.NAVY, "U": Pal.BLUE, "K": Pal.LEATHER,
		"A": Pal.STONE, "X": Pal.SLATE, "P": Pal.CANVAS, "p": Pal.DUST, "Z": Pal.BRASS, "z": Pal.BRASS.lerp(Pal.INK, 0.35),
		"V": Pal.OMEN, "v": Pal.PURPLE, "L": Pal.LILAC, "F": Pal.FROST, "E": Pal.SAND, "e": Pal.DUNE, "k": Pal.SKY,
		"Q": Pal.CLAY, "c": Pal.CANDLE, "q": Pal.PLUM, "n": Pal.SKIN}


const _UNKNOWN := ["............", "...CCCCC....", "..CC...CC...", "......CC....", ".....CC.....", ".....CC.....",
	"............", ".....CC....."]


static func item_icon(id: String) -> PixBuf:
	var rows: Array
	match id:
		# --- what Rook carries off -------------------------------------------
		"purse":
			rows = ["....KK.KK...",
					".....KKK....",
					"....ZKKKZ...",
					"...KKKKKKK..",
					"..KKKRRRKKK.",
					"..KKRKKKRKK.",
					".KKKKKKKKKKK",
					".KKKZZZZKKKK",
					".KKKKKKKKKKK",
					"..KKKKKKKKK.",
					"...KKKKKKK..",
					"............"]
		"seal_ring":
			rows = ["............",
					"...SSSSSS...",
					"...SFFFFS...",
					"...SFXXFS...",
					"...SSSSSS...",
					"..SS....SS..",
					".SS......SS.",
					".S........S.",
					".SS......SS.",
					"..SS....SS..",
					"...SSSSSS...",
					"............"]
		"saffron":
			rows = ["............",
					"............",
					"..RRRRRRRR..",
					".RrrrrrrrrR.",
					".ZZZZZZZZZZ.",
					".RRRRZZRRRR.",
					".RRRRYYRRRR.",
					".RRRRRRRRRR.",
					".RRRRRRRRRR.",
					".rrrrrrrrrr.",
					"..O..O.O..O.",
					".O..O....O.."]
		"silk":
			rows = ["............",
					"..vvvvvvvv..",
					".vLLLLLLLLv.",
					"vLvvLLLLLLLv",
					"vvLvvvvvvvvv",
					"vLvvLLLLLLLv",
					".vLLLLLLLLv.",
					"..vvvvvvvvL.",
					"..........L.",
					".........L..",
					"........L...",
					"............"]
		"icon":
			rows = ["....DDDD....",
					"...DZZZZD...",
					"..DZYYYYZD..",
					"..DYYnnYYD..",
					"..DYnnnnYD..",
					"..DYYnnYYD..",
					"..DUUUUUUD..",
					"..DUUUUUUD..",
					"..DUUZUUUD..",
					"..DUUUUUUD..",
					"..DDDDDDDD..",
					"............"]
		"ledger":
			rows = ["............",
					".KKKKKKKKK..",
					".KKKKKKKKKC.",
					".KKKKKKKKKC.",
					".KZZZZZZKKC.",
					".KZqqqqZKKC.",
					".KZZZZZZKKC.",
					".KKKKKKKKKC.",
					".KKKKKKKKZC.",
					".KKKKKKKKZC.",
					"..CCCCCCCCC.",
					"............"]
		"map":
			rows = ["............",
					".PPPPPP.PP..",
					".PPpPPPPPPP.",
					".PPPpPPPPPP.",
					"..PPPpppPPP.",
					".PPPPPPPpPP.",
					".PPPPPPPPpP.",
					".PPPPPPPPIP.",
					".PPPPPPPPIP.",
					"..PPP.PPPPP.",
					"...P....PP..",
					"............"]
		"poster":
			rows = [".....b......",
					".PPPPPPPPPP.",
					".PIIIIIIIIP.",
					".PPPPPPPPPP.",
					".PPPPnnPPPP.",
					".PPPnnnnPPP.",
					".PPPPnnPPPP.",
					".PPPIIIIPPP.",
					".PPPPPPPPPP.",
					".PbbbbbbbbP.",
					".PPPPPPPPPP.",
					"............"]
		"letter":
			rows = ["............",
					"............",
					".CCCCCCCCCC.",
					".CPCCCCCCPC.",
					".CCPCCCCPCC.",
					".CCCPCCPCCC.",
					".CCCCPRPCCC.",
					".CCCCRRRCCC.",
					".CCCCCRCCCC.",
					".CCCCCCCCCC.",
					"............",
					"............"]
		"payroll":
			rows = ["...Y.YY.Y...",
					"..YYYYYYYY..",
					".ZZZZZZZZZZ.",
					".DDDDDDDDDD.",
					".ZZZZZZZZZZ.",
					".DDDDYYDDDD.",
					".DDDDzzDDDD.",
					".DDDDDDDDDD.",
					".ZDDDDDDDDZ.",
					".ZZZZZZZZZZ.",
					"............",
					"............"]
		# --- supplies --------------------------------------------------------
		"bread":
			rows = ["............",
					"............",
					"....HHHH....",
					"..HHCHHCHH..",
					".HHCHHCHHCH.",
					".HHHHHHHHHH.",
					".DHHHHHHHHD.",
					".DDHHHHHHDD.",
					"..DDDDDDDD..",
					"............",
					"............",
					"............"]
		"salve":
			rows = ["............",
					"............",
					"...KKKKKK...",
					"...KKKKKK...",
					"...PPPPPP...",
					"..FMMMMMMF..",
					"..FMWMMMMF..",
					"..FMWMMgMF..",
					"..FMMMMgMF..",
					"..FMMMMMMF..",
					"...FFFFFF...",
					"............"]
		"tonic":
			rows = [".....KK.....",
					".....FF.....",
					".....FF.....",
					"....FFFF....",
					"...FHHHHF...",
					"...FWHHHF...",
					"...FWPPHF...",
					"...FHPPHF...",
					"...FHHHHF...",
					"...FHHHHF...",
					"....FFFF....",
					"............"]
		"smoke":
			rows = ["...A...A....",
					"..A.A.A.A...",
					"...A...A.A..",
					"....A.A.....",
					".....A......",
					"....XXXX....",
					"...XWXXXX...",
					"...XXXXXX...",
					"...XXXXXX...",
					"....XXXX....",
					"............",
					"............"]
		"sand":
			rows = ["....KK......",
					".....KK.....",
					"....EEEE....",
					"...EEEEEE...",
					"..EEeEEEEE..",
					"..EEEEEeEE..",
					"..EEEEEEEE..",
					"...EEEEEE...",
					"............",
					".e.E..e..E..",
					"..E.e..E....",
					"............"]
		_:
			rows = _UNKNOWN
	var b := PixBuf.new(14, 14)
	b.ascii(rows, icon_pal(), 1, 1)
	b.outline()
	return b


static func skill_icon(id: String) -> PixBuf:
	var rows: Array
	match id:
		# --- Rook ------------------------------------------------------------
		"quickcut":
			rows = ["........s..s",
					".......s..s.",
					"....s.s..s..",
					"...s.s..s...",
					"..s.s..s....",
					".s.s..s.....",
					"s.s..s......",
					".s..s.......",
					"s..s........",
					"..s.........",
					".s..........",
					"............"]
		"feint":
			rows = ["...........s",
					"..........sS",
					"....L....sS.",
					"...L....sS..",
					"..L....sS...",
					".L..Z.sS....",
					".L...ZS.....",
					".L..K.Z.....",
					"..LK........",
					"..LL........",
					"...LLL......",
					"............"]
		"grit":
			rows = [".........E..",
					"......E.....",
					"..E.....e.E.",
					"....e.E.....",
					".E..EeE..e..",
					"...EEEEe....",
					"..eEEEEE.E..",
					".E.EEEE.....",
					"..nnnn..e...",
					".nnnnnn.....",
					".nnnnn......",
					"............"]
		"tumble":
			rows = ["....kkkk....",
					"..kk....kk..",
					".k........k.",
					".k..........",
					"k...........",
					"k........k..",
					"k.......kkk.",
					".k.....kkkkk",
					".k..........",
					"..kk....kk..",
					"....kkkk....",
					"............"]
		# --- the blade's arts ----------------------------------------------
		"omen_edge":
			rows = ["V.........VW",
					".V.......VsS",
					"........VsS.",
					"V.V....VsS..",
					".......sS...",
					"..Z...sS....",
					"...Z.sS.....",
					"....ZS......",
					"...K.Z......",
					"..K...Z.....",
					".V..........",
					"............"]
		"parry_sight":
			rows = [".SSSSSSSSSS.",
					".SFFFFFFFFS.",
					".SFFFFFFFFS.",
					".SFVVVVVVFS.",
					".SVvIIIIvVS.",
					".SVvIWWIvVS.",
					".SVvIIIIvVS.",
					"..SVVVVVVS..",
					"..SFFFFFFS..",
					"...SFFFFS...",
					"....SFFS....",
					".....SS....."]
		"thousand":
			rows = ["V....V....V.",
					".V...V...V..",
					"..V..V..V...",
					"...V.V.V....",
					"....VWV.....",
					"VVVVWWWVVVVV",
					"....VWV.....",
					"...V.V.V....",
					"..V..V..V...",
					".V...V...V..",
					"V....V....V.",
					"............"]
		"mine":
			rows = [".rr.rr......",
					"rbbrbbr.....",
					"rbWbbbr.....",
					".rbbbr......",
					"..rbr...V...",
					"...r...VV...",
					"......VVVVVV",
					".......VV..V",
					"........V..V",
					"...........V",
					"........VVVV",
					"............"]
		"foreknow":
			rows = ["............",
					"............",
					"...VVVVVV...",
					"..VvvvvvvV..",
					".VvvIIIIvvV.",
					"VvvIIWWIIvvV",
					"VvvIIWIIIvvV",
					".VvvIIIIvvV.",
					"..VvvvvvvV..",
					"...VVVVVV...",
					"............",
					"............"]
		# --- Mara ------------------------------------------------------------
		"pin":
			rows = ["..........PP",
					".........P.P",
					"........ePP.",
					".......e....",
					"......e.....",
					".....e......",
					"....e.......",
					"...e........",
					"..S.........",
					".Ss.........",
					"XXXXXXXX....",
					"............"]
		"volley":
			rows = [".P...P...P..",
					".e...e...e..",
					".e...e...e..",
					".e...e...e..",
					".e...e...e..",
					".e...e...e..",
					"SSS.SSS.SSS.",
					".S...S...S..",
					"............",
					"XXXXXXXXXXX.",
					"............",
					"............"]
		"dressing":
			rows = ["............",
					"....WWWW....",
					"....WGGW....",
					"....WGGW....",
					".WWWWGGWWWW.",
					".WGGGGGGGGW.",
					".WGGGGGGGGW.",
					".WWWWGGWWWW.",
					"....WGGW....",
					"....WGGW....",
					"....WWWW....",
					"............"]
		"cover":
			rows = [".SSSSSSSSSS.",
					".SkkkkkkkkS.",
					".SkWkkkkkkS.",
					".SkkkkkkkkS.",
					".SkkkkkkkkS.",
					"..SkkkkkkS..",
					"..SkkkkkkS..",
					"...SkkkkS...",
					"....SkkS....",
					".....SS.....",
					"............",
					"............"]
		# --- Fen -------------------------------------------------------------
		"caltrops":
			rows = ["............",
					"..S......S..",
					".SsS....SsS.",
					"..S......S..",
					".S.S....S.S.",
					"............",
					".....S......",
					"....SsS.....",
					".....S......",
					"....S.S.....",
					"............",
					"............"]
		"old_tale":
			rows = ["............",
					".CCCCCCCCCC.",
					"CCCCCCCCCCCC",
					"CCCCCCCCCCCC",
					"CCIICIICIICC",
					"CCCCCCCCCCCC",
					"CCCCCCCCCCCC",
					".CCCCCCCCCC.",
					"...CC.......",
					"..CC........",
					".C..........",
					"............"]
		"rally":
			rows = [".Z..........",
					".DRRRRRRR...",
					".DRRRRRRRR..",
					".DRRYRRRRR..",
					".DRRRRRRR...",
					".DRRRRRRRR..",
					".D..........",
					".D..........",
					".D..........",
					".D..........",
					".D..........",
					".D.........."]
		# --- Wick & Bracken --------------------------------------------------
		"pebbles":
			rows = ["...AA.......",
					"..AAA....A..",
					".........AA.",
					".AA..AA.....",
					"AAA.AWAA....",
					".A...AA..AA.",
					"........AAA.",
					"..AA.....A..",
					".AAAA.......",
					"..AA...AA...",
					".......AA...",
					"............"]
		"haymaker":
			rows = ["Y..........Y",
					".Y........Y.",
					"....nnnn....",
					"...nnnnnn...",
					"..nnBnBnn...",
					"..nnnnnnn...",
					"..nnnnnnn...",
					"...nnnnn....",
					"...KKKKK....",
					"...KKKKK....",
					".Y........Y.",
					"Y..........Y"]
		# --- the crew's weapons (their plain ATTACK) -------------------------
		"weapon_sword":
			rows = ["...........s",
					"..........sS",
					".........sS.",
					"........sS..",
					".......sS...",
					"..Z...sS....",
					"...Z.sS.....",
					"....ZS......",
					"...K.Z......",
					"..K...Z.....",
					".V..........",
					"............"]
		"weapon_dagger":
			rows = ["............",
					"............",
					"............",
					"........s...",
					".......sS...",
					"..Z...sS....",
					"...Z.sS.....",
					"....ZS......",
					"...K.Z......",
					"..K...Z.....",
					".K..........",
					"............"]
		"weapon_bow":
			rows = ["...D........",
					"...PDD......",
					"...P..D.....",
					"...P...D....",
					"...P...D....",
					"PPeeeeeeeeSs",
					"...P...D....",
					"...P...D....",
					"...P..D.....",
					"...PDD......",
					"...D........",
					"............"]
		"weapon_cane":
			rows = ["...DDDD.....",
					"..D....D....",
					"..D....D....",
					".......D....",
					".......D....",
					".......D....",
					".......D....",
					".......D....",
					".......D....",
					".......D....",
					".......D....",
					".......Z...."]
		"weapon_sling":
			rows = ["K...........",
					".K..........",
					"..K.........",
					"...K........",
					"....KKKK....",
					"....KAAK....",
					"....KAAK....",
					"....KKKK....",
					"........K...",
					".........K..",
					"..........K.",
					"...........K"]
		"weapon_club":
			rows = ["........DDD.",
					".......DDDDD",
					"......DDDBDD",
					".....DDDDDD.",
					"....DDDDD...",
					"...DDDD.....",
					"..DDD.......",
					".KK.........",
					"KK..........",
					"............",
					"............",
					"............"]
		_:
			rows = _UNKNOWN
	var b := PixBuf.new(14, 14)
	b.ascii(rows, icon_pal(), 1, 1)
	b.outline()
	return b


# ------------------------------------------------------------- stat icons --
# 10 x 10, for the status pane and the windows: hp, tp, atk, def, spd, coin,
# finesse, suspicion, loyalty, trust, weight, evidence.

static func stat_icon(id: String) -> PixBuf:
	var rows: Array
	match id:
		"hp":
			rows = [".bb.bb.", "bWbbbbb", "bbbbbbb", ".bbbbb.", "..bbb..", "...b..."]
		"tp":
			rows = ["...c...", "..cYc..", ".cYWYc.", "cYWWWYc", ".cYWYc.", "..cYc..", "...c..."]
		"atk":
			rows = ["......s", ".....sS", "....sS.", ".Z.sS..", "..ZS...", ".K.Z...", "K......"]
		"def":
			rows = ["SSSSSSS", "SsFFFFS", "SFFFFFS", "SFFFFFS", ".SFFFS.", "..SFS..", "...S..."]
		"spd":
			rows = ["k..k...", ".k..k..", "..k..k.", "...k..k", "..k..k.", ".k..k..", "k..k..."]
		"coin":
			rows = [".ZZZZ.", "ZYYYYZ", "ZYZZYZ", "ZYZZYZ", "ZYYYYZ", ".ZZZZ."]
		"finesse":
			rows = [".....cc", "....cYc", "...cYc.", "..cYc..", ".cYc...", "cc.....", "c......"]
		"suspicion":
			rows = ["..VVV..", ".VvvvV.", "VvIWIvV", ".VvvvV.", "..VVV.."]
		"loyalty":
			rows = ["...O...", "..OYO..", "..OYYO.", ".OYWYO.", "DD.D.DD", "..DDD.."]
		"trust":
			rows = [".GG.GG.", "GWGGGGG", "GGGGGGG", ".GGGGG.", "..GGG..", "...G..."]
		"weight":
			rows = ["..AAA..", ".A...A.", "AAAAAAA", "AAAAAAA", "AWAAAAA", ".AAAAA."]
		"evidence":
			rows = ["PPPPPP", "PbbbbP", "PPPPPP", "PPnnPP", "PnnnnP", "PPPPPP"]
		"value":
			rows = [".ZZZZ.", "ZYYYYZ", "ZYZZYZ", "ZYZZYZ", "ZYYYYZ", ".ZZZZ."]
		"blade":
			rows = ["......V", ".....VW", "....VW.", ".Z.VW..", "..ZV...", ".v.Z...", "V......"]
		_:
			rows = []
	var b := PixBuf.new(10, 10)
	b.ascii(rows, icon_pal(), 1, 1)
	b.outline()
	return b
