class_name ArtAchieve
## 24 x 24 achievement icons: a small object on a coloured medallion. Locked
## icons are the same picture pressed into dull ink.

const S := 24
const ENDING_COL := [Color("b98cff"), Color("9cf08c"), Color("a39a8e"), Color("d2c09a"), Color("c49a4a"), Color("efe6d2")]


static func icon(a: Dictionary, unlocked: bool) -> PixBuf:
	var b := PixBuf.new(S, S)
	var cat: String = a.get("cat", "choices")
	var ring: Color = {"endings": Pal.BRASS, "choices": Pal.CLAY, "battle": Pal.BLOOD.lerp(Pal.ROSE, 0.5), "craft": Pal.TEAL}.get(cat, Pal.BRASS)
	if a.get("icon", "") == "ending":
		ring = ENDING_COL[int(a.get("slot", 0)) % ENDING_COL.size()]
	b.circ(12, 12, 11, Pal.shade(ring))
	b.circ(12, 12, 9.5, Pal.PANEL.lerp(ring, 0.2))
	b.rect(6, 3, 12, 1, Pal.hi(ring).lerp(ring, 0.5))
	_motif(b, a.get("icon", ""), ring)
	b.outline()
	if not unlocked:
		b.recolor(func(_x: int, _y: int, c: Color) -> Color:
			var l := c.get_luminance()
			return Pal.INK2.lerp(Pal.TEXT_DIM, l * 0.6))
	return b


static func _motif(b: PixBuf, kind: String, ring: Color) -> void:
	var m := {"X": Pal.INK, "W": Pal.WHITE, "S": Pal.STEEL, "B": Pal.BRASS, "O": Pal.OMEN, "R": Pal.BLOOD, "C": Pal.CANVAS,
		"L": Pal.LEATHER, "G": Pal.GLOW, "Y": Pal.LEMON, "K": Pal.SKY, "D": Pal.DUST, "N": Pal.SKIN2, "P": Pal.CLAY}
	match kind:
		"ending", "sword":
			b.ascii(["....O....", "....L....", "....L....", "..BBBBB..", "...BSB...", "....S....", "....S....", "....S....", "....S....", "....O....", "....S....", "....S...."], m, 8, 5)
		"crown":
			b.ascii(["B..B..B", "BB.B.BB", "BBBBBBB", "BYBOBYB", "BBBBBBB"], m, 9, 9)
		"book":
			b.ascii(["CCCC.CCCC", "CDDC.CDDC", "CCCC.CCCC", "CDDC.CDDC", "CCCCBCCCC", "BBBBBBBBB"], m, 8, 9)
		"chest":
			b.ascii([".LLLLLLL.", "LLLLLLLLL", "BBBBYBBBB", "LLLLBLLLL", "LLLLLLLLL"], m, 8, 9)
		"eye":
			b.ascii(["..XXXXX..", ".XOOOOOX.", "XOOXXXOOX", "XOOXWXOOX", ".XOOOOOX.", "..XXXXX.."], m, 8, 9)
		"carve":
			b.ascii(["SSSSSSSS.", "S.......S", "S.W.W.W.S", "S.......S", "SSSSSSSS."], m, 8, 10)
		"heart":
			b.ascii([".RR.RR.", "RWRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."], m, 9, 9)
		"bag":
			b.ascii(["...LL...", "..L..L..", ".DDDDDD.", "DDDDDDDD", "DDDYDDDD", ".DDDDDD."], m, 8, 9)
		"hand":
			b.ascii([".N.N.N.", ".N.N.N.", "NNNNNN.", "NNNNNNN", ".NNNNN.", "..NNN.."], m, 9, 8)
		"poster":
			b.ascii(["CCCCCCC", "CRRRRRC", "CCDDDCC", "CCDXDCC", "CCDDDCC", "CXXXXXC", "CCCCCCC"], m, 9, 8)
		"ghost":
			b.ascii(["..OOO..", ".OOOOO.", "OOXOXOO", "OOOOOOO", "OOOOOOO", "O.O.O.O"], m, 9, 8)
		"door":
			b.ascii([".DDDDD.", "DXXXXXD", "DXXXXXD", "DXXXXBD", "DXXXXXD", "DXXXXXD"], m, 9, 8)
		"shield":
			b.ascii(["SSSSSSS", "SKKKKKS", "SKKBKKS", ".SKKKS.", "..SKS..", "...S..."], m, 9, 8)
		"coin":
			b.ascii(["..BBB..", ".BYYYB.", "BYYBYYB", "BYYBYYB", ".BYYYB.", "..BBB.."], m, 9, 9)
		"boot":
			b.ascii(["..LL..", "..LL..", "..LL..", "..LLLL", "LLLLLL"], m, 9, 10)
		"bow":
			b.ascii(["L....", ".L..W", "..L.W", "..L.W", "..L.W", ".L..W", "L...."], m, 10, 8)
		"tooth":
			b.ascii(["WWBWW", "WWBWW", ".W.W."], m, 10, 10)
		"skull":
			b.ascii([".WWWWW.", "WWWWWWW", "WXWWWXW", "WWWXWWW", ".WWWWW.", ".W.W.W."], m, 9, 8)
		"mask":
			b.ascii(["CCCCCCC", "CXCCCXC", "CCCCCCC", ".CCCCC."], m, 9, 10)
		"lock":
			b.ascii(["..SSS..", ".S...S.", ".S...S.", "BBBBBBB", "BBBXBBB", "BBBXBBB", "BBBBBBB"], m, 9, 7)
