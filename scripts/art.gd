extends Node
## Art autoload: every texture in the game is generated here on first use and
## cached by a string key. Frames, moods, poses and variants are just more keys.

const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

var cache := {}
var font: FontFile
var theme: Theme


func _ready() -> void:
	font = PixFont.build()
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = PixFont.SIZE
	theme.set_color("font_color", "Label", Pal.TEXT)
	get_tree().root.theme = theme
	# Controls under CanvasLayers don't inherit the window theme, so make the
	# pixel font the engine-wide default too.
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = PixFont.SIZE
	var d := ThemeDB.get_default_theme()
	d.default_font = font
	d.default_font_size = PixFont.SIZE
	d.set_color("font_color", "Label", Pal.TEXT)


func _cached(key: String, gen: Callable) -> Texture2D:
	if not cache.has(key):
		var r = gen.call()
		cache[key] = r.tex() if r is PixBuf else ImageTexture.create_from_image(r)
	return cache[key]


func _spec_key(spec: Dictionary) -> String:
	return "%s%s%s" % [spec.get("id", str(spec.hash())), spec.get("variant", ""), spec.get("mark", "")]


func person(spec: Dictionary, dir: int, frame: int, mood: String = "", pose: String = "walk") -> Texture2D:
	return _cached("p:%s:%d:%d:%s:%s" % [_spec_key(spec), dir, frame, mood, pose], func(): return ArtPeople.render(spec, dir, frame, mood, pose))


func person_image(spec: Dictionary, dir: int, frame: int, mood: String = "", pose: String = "walk") -> Image:
	return person(spec, dir, frame, mood, pose).get_image()


func silhouette(spec: Dictionary, dir: int, frame: int, mood: String, pose: String, c: Color) -> Texture2D:
	## A flat single-colour copy of a sprite: afterimages, hit flashes, the
	## "thief" shapes that allies turn into when Suspicion runs high.
	return _cached("sil:%s:%d:%d:%s:%s:%s" % [_spec_key(spec), dir, frame, mood, pose, c.to_html()], func():
		var b := ArtPeople.render(spec, dir, frame, mood, pose)
		b.recolor(func(_x: int, _y: int, _c: Color) -> Color: return c)
		return b)


func portrait(spec: Dictionary, mood: String = "", blink: bool = false, open: bool = false, zoom: int = 3) -> Texture2D:
	return _cached("pt:%s:%s:%d%d:%d" % [_spec_key(spec), mood, int(blink), int(open), zoom], func(): return ArtPortraits.from_sprite(spec, mood, blink, open, zoom))


func head_icon(spec: Dictionary, mood: String = "", hostile: bool = false) -> Texture2D:
	## 14 x 14 head for the turn-order bar.
	return _cached("hi:%s:%s:%d" % [_spec_key(spec), mood, int(hostile)], func(): return ArtPortraits.head_icon(spec, mood, hostile))


func icon_portrait(kind: String, frame: int) -> Texture2D:
	return _cached("pti:%s:%d" % [kind, frame], func(): return ArtPortraits.icon(kind, frame))


func prop(kind: String, v: int = 0) -> Texture2D:
	return _cached("prop:%s:%d" % [kind, v], func(): return ArtProps.make(kind, v))


func ground(id: String, rows: Array, theme_name: String) -> Texture2D:
	return _cached("ground:" + id, func(): return ArtTiles.ground(rows, theme_name))


func water_overlay(id: String, rows: Array, theme_name: String, frame: int) -> Texture2D:
	return _cached("water:%s:%d" % [id, frame], func(): return ArtTiles.water_overlay(rows, theme_name, frame))


func cine(name: String, frame: int = 0) -> Texture2D:
	return _cached("cine:%s:%d" % [name, frame], func(): return ArtCine.make(name, frame))


func battle_bg(name: String, frame: int = 0) -> Texture2D:
	return _cached("bbg:%s:%d" % [name, frame], func(): return ArtBattle.backdrop(name, frame))


func gen(key: String, maker: Callable) -> Texture2D:
	## Cache any generated PixBuf/Image under a key (for one-off art).
	return _cached("gen:" + key, maker)


func shadow(w: int, h: int) -> Texture2D:
	return _cached("shadow:%d:%d" % [w, h], func():
		var b := PixBuf.new(w, h)
		b.ell(w / 2.0, h / 2.0, w / 2.0, h / 2.0, Pal.INK)
		return b)


func light(r: int, c: Color) -> Texture2D:
	## Dithered radial glow, for additive lamps, campfires and the blade.
	return _cached("light:%d:%s" % [r, c.to_html()], func():
		var b := PixBuf.new(r * 2, r * 2)
		for y in r * 2:
			for x in r * 2:
				var d := Vector2(x + 0.5 - r, (y + 0.5 - r) * 1.3).length() / r
				if d >= 1.0:
					continue
				var k := (1.0 - d) * (1.0 - d)
				var lv := int(k * 4.0 * 16.0)
				var q := lv / 16
				if lv % 16 > BAYER[y % 4][x % 4]:
					q += 1
				if q > 0:
					b.pset(x, y, Color(c, minf(1.0, q * 0.12)))
		return b)


func cone(r: int, c: Color) -> Texture2D:
	## A guard's lantern cone pointing right: dithered wedge of light.
	return _cached("cone:%d:%s" % [r, c.to_html()], func():
		var b := PixBuf.new(r, r)
		for y in r:
			for x in r:
				var v := Vector2(x + 0.5, y + 0.5 - r / 2.0)
				var d := v.length() / r
				if d >= 1.0 or absf(v.angle()) > 0.5:
					continue
				var k := 1.0 - d
				var lv := int(k * 3.0 * 16.0)
				var q := lv / 16
				if lv % 16 > BAYER[y % 4][x % 4]:
					q += 1
				if q > 0:
					b.pset(x, y, Color(c, minf(1.0, q * 0.1)))
		return b)


func achievement(a: Dictionary, unlocked: bool) -> Texture2D:
	return _cached("ach:%s:%d" % [a.get("id", ""), int(unlocked)], func(): return ArtAchieve.icon(a, unlocked))


func ui(name: String) -> Texture2D:
	return _cached("ui:" + name, func(): return ArtUI.make(name))


func number(text: String, c: Color, big: bool = false) -> Texture2D:
	return _cached("num:%s:%s:%d" % [text, c.to_html(), int(big)], func(): return ArtUI.number(text, c, big))


func make_box(kind: String = "box") -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = ui(kind)
	n.patch_margin_left = 4
	n.patch_margin_right = 4
	n.patch_margin_top = 4
	n.patch_margin_bottom = 4
	return n


func label(text: String, color: Color = Pal.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


func shadow_label(text: String, color: Color = Pal.TEXT, size_k: int = 1) -> Label:
	var l := label(text, color)
	if size_k > 1:
		l.add_theme_font_size_override("font_size", PixFont.SIZE * size_k)
	l.add_theme_color_override("font_shadow_color", Pal.INK)
	l.add_theme_constant_override("shadow_offset_x", size_k)
	l.add_theme_constant_override("shadow_offset_y", size_k)
	return l


func text_width(text: String, size_k: int = 1) -> int:
	return int(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE * size_k).x)


func wrap(text: String, width: float) -> Array:
	## Word-wraps to lines no wider than width, measured with the real font.
	var lines := []
	for para in text.split("\n"):
		var cur := ""
		for w in para.split(" ", false):
			var trial := w if cur == "" else cur + " " + w
			if text_width(trial) > width and cur != "":
				lines.append(cur)
				cur = w
			else:
				cur = trial
		lines.append(cur)
	return lines
