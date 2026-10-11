class_name Pal
## The Caravan Thief's palette: dusk on the Saltway. Dust, sun-baked clay,
## faded canvas and lantern light. INK (a warm purple-black) is shared by
## shadows, outlines, pupils and the night, which ties every sprite into one
## set. Highlights lean toward old parchment (LIGHT_TINT).
##
## Reserved accents (the only saturated colours, one meaning each):
##   OMEN     the sword: its visions, its voice, Foreknowledge and Suspicion
##   BLOOD    damage and danger
##   GLOW     rewards, healing, trust gained
##   CANDLE   the interface: cursors, markers, "this is you / press here"

const INK := Color("1b1320")
const INK2 := Color("3b2c3c")
const WHITE := Color("ece2cc")
const CREAM := Color("d2c09a")
const PEACH := Color("b08f72")
const PINK := Color("a07478")
const ROSE := Color("8e4652")
const RED := Color("a63a32")
const ORANGE := Color("b8703a")
const HONEY := Color("b08a3e")
const LEMON := Color("dccb78")
const MINT := Color("7ea38c")
const SAGE := Color("687c5c")
const GRASS := Color("5f6b46")
const LEAF := Color("4a5a3e")
const PINE := Color("2f4238")
const TEAL := Color("3f6f6a")
const SKY := Color("8fa0a8")
const BLUE := Color("4a6688")
const LILAC := Color("7a6a88")
const PURPLE := Color("5a4470")
const PLUM := Color("3c2a46")
const NAVY := Color("2b3450")
const FROST := Color("bcc4c4")

const SKIN := Color("e0c4a6")
const SKIN2 := Color("b88a68")
const SKIN3 := Color("7c5640")

const WOOD := Color("7a5638")
const BARK := Color("4a3428")
const STONE := Color("a39a8e")
const SLATE := Color("6c6672")
const DIRT := Color("8a7050")
const WATER := Color("3a5862")

# The Saltway family: the setting's own colours.
const SAND := Color("c9a774")
const DUNE := Color("a8844e")
const DUST := Color("8c7258")
const CANVAS := Color("d8c8a0")
const CLAY := Color("a35f3e")
const SCRUB := Color("6a6a40")
const DUSK := Color("6e4a5e")
const BRASS := Color("c49a4a")
const AUBURN := Color("9a4e32")
const LEATHER := Color("6a4a32")
const STEEL := Color("8e9298")

# Reserved glows.
const OMEN := Color("b98cff")
const BLOOD := Color("e0483e")
const GLOW := Color("9cf08c")

# Interface.
const CANDLE := Color("e0a04a")
const TEXT := Color("ece2cc")
const TEXT_DIM := Color("857a86")
const PANEL := Color("2b1f2a")
const PANEL2 := Color("221822")

const LIGHT_TINT := Color("f0dfb4")


static func hi(c: Color) -> Color:
	return c.lerp(LIGHT_TINT, 0.45)


static func shade(c: Color) -> Color:
	return c.lerp(INK, 0.25)


static func deep(c: Color) -> Color:
	return c.lerp(INK, 0.45)


static func dark(c: Color) -> Color:
	## Outline colour: a darker version of the neighbouring colour.
	var d := c.lerp(INK, 0.62)
	d.a = 1.0
	return d


static func band(c: Color, l: float) -> Color:
	## Four lighting bands instead of smooth gradients.
	if l > 0.78:
		return hi(c)
	if l > 0.22:
		return c
	if l > -0.3:
		return shade(c)
	return deep(c)


static func hash2(x: int, y: int, s: int = 0) -> float:
	var n: int = x * 374761393 + y * 668265263 + s * 2246822519
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0


static func noise(x: float, y: float, s: float = 0.0) -> float:
	## Cheap layered sine noise in roughly -1..1.
	return (sin(x * 0.19 + sin(y * 0.11 + s) * 2.1) + sin(y * 0.23 + x * 0.07 + s * 1.7) * 0.7 + sin((x + y) * 0.051 + s * 0.3) * 0.5) / 2.2
