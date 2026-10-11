extends SceneTree
## Quick art check without the game running:
## godot --headless --path . -s tools/peek.gd -- <out_dir> <what>
## what: people | poses | moods | creatures


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp"
	var what: String = args[1] if args.size() > 1 else "people"
	var cells := []
	match what:
		"people":
			for id in ["rook", "rook_sword", "mara", "fen", "factor", "wick", "bracken", "dosha", "ollo", "guard", "hunter", "pilgrim", "pilgrim_kid", "priest", "bearer", "townswoman"]:
				for d in [0, 2, 1]:
					cells.append([Data.spec(id), d, 0, "", "walk"])
				cells.append([Data.spec(id), 2, 1, "", "walk"])
		"poses":
			var ps := ["idle", "ready", "windup", "strike", "follow", "thrust", "hurt", "guard", "cast", "throw", "dodge", "victory", "lie"]
			for id in ["rook_sword", "mara", "fen", "guard", "hunter", "bracken", "wick", "factor_ledger"]:
				for p in ps:
					cells.append([Data.spec(id), 2, 0, "", p])
		"gestures":
			var gs := ["point", "cross", "hips", "shrug", "think", "wave", "cower", "facepalm", "laugh", "bow", "hold_up", "kneel", "sit", "sneak", "pick", "slump", "fist", "reach"]
			for id in ["rook_sword", "mara", "fen"]:
				for g in gs:
					cells.append([Data.spec(id), 0, 0, "", g])
				for g in gs:
					cells.append([Data.spec(id), 2, 0, "", g])
		"moods":
			var ms := ["", "smile", "smirk", "grin", "sad", "cry", "worried", "shock", "scared", "angry", "determined", "hurt", "laugh", "sly", "closed", "omen", "+open"]
			for id in ["rook", "mara", "fen", "factor", "wick"]:
				for m in ms:
					cells.append([Data.spec(id), 0, 0, m, "walk"])
		"creatures":
			for id in ["jackal", "crow", "ox"]:
				for p in ["walk", "idle", "ready", "strike", "hurt", "lie"]:
					for d in [2, 0]:
						cells.append([Data.spec(id), d, 1 if p == "walk" else 0, "", p])
	var cols := 16 if what != "people" else 16
	if what == "poses":
		cols = 13
	if what == "moods":
		cols = 17
	if what == "gestures":
		cols = 18
	var rows := int(ceil(cells.size() / float(cols)))
	var img := Image.create_empty(cols * 50, rows * 42, false, Image.FORMAT_RGBA8)
	img.fill(Pal.SAND.lerp(Pal.DUST, 0.3))
	for i in cells.size():
		var c: Array = cells[i]
		var b := ArtPeople.render(c[0], c[1], c[2], c[3], c[4])
		img.blend_rect(b.img, Rect2i(0, 0, 48, 40), Vector2i((i % cols) * 50 + 1, (i / cols) * 42 + 1))
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/%s.png" % [out, what])
	print("saved ", what)
	quit()
