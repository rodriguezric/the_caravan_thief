extends Node
## Debug autopilot. Set CT_TEST to a scenario; screenshots go to CT_OUT and
## saves to CT_DIR (never the player's own files).
##   story            play from CT_SCENE (default P1) to an ending with
##                    CT_AUTOPLAY on; CT_CHOICES / CT_ACT / CT_SWORD /
##                    CT_EXPLORE steer it. CT_STATE="var=n,flag,!flag,..." presets (!flag clears).
##   battle:<kind>    a sample battle, screenshots through its animations
##                    (CT_MENUS=1 without CT_AUTOPLAY: screenshots of its menus)
##   shell            title, endings, settings, records, achievements
##   slots            save slots: the old single save moving into slot 1,
##                    Load Game and New Game's slot lists (needs CT_DIR)
##   minigame:<kind>  one minigame (real logic, random presses)
##   cine:<name>      a backdrop, screenshot
##   touch            by touch: the field layout, the lock watchdog, drag
##                    scrolling in Settings/Achievements, a tap-the-screen minigame

var out := ""
var main: Node
var shooting := false
var shot_n := 0
var prefix := "shot"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	out = OS.get_environment("CT_OUT")
	main = Game.main
	_run.call_deferred(OS.get_environment("CT_TEST"))


func shot(name: String) -> void:
	if out == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _shoot_loop(every: float) -> void:
	shooting = true
	while shooting:
		await get_tree().create_timer(every, true, false, true).timeout
		if not shooting:
			break
		shot_n += 1
		await shot("%s_%03d" % [prefix, shot_n])


func wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _send(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)


func tap(action: String, t: float = 0.25) -> void:
	_send(action, true)
	await get_tree().process_frame
	await get_tree().process_frame
	_send(action, false)
	await wait(t)


func _preset() -> void:
	for kv in OS.get_environment("CT_STATE").split(",", false):
		if kv.contains(":"):
			var q := kv.split(":")
			match q[0]:
				"lore":
					Game.run.lore.append(q[1])
				"clue":
					Game.run.clues.append(q[1])
				"item":
					Game.run.items.append(q[1])
				"returned":
					Game.run.returned.append(q[1])
		elif kv.contains("="):
			var p := kv.split("=")
			if Game.VARS.has(p[0]):
				Game.run.vars[p[0]] = int(p[1])
			else:
				Game.set_flag(p[0], p[1])
		elif kv.begins_with("!"):
			Game.run.flags.erase(kv.substr(1))
		else:
			Game.set_flag(kv)


func _run(scenario: String) -> void:
	var every := float(OS.get_environment("CT_SHOT_EVERY")) if OS.get_environment("CT_SHOT_EVERY") != "" else 0.0
	if scenario == "story":
		prefix = "story"
		Game.new_run()
		var sc := OS.get_environment("CT_SCENE")
		if sc != "":
			Game.run.scene = sc
			main.story.prepare_jump(sc)
		_preset()
		if every > 0.0:
			_shoot_loop(every)
		var t0 := Time.get_ticks_msec()
		await main.play_story()
		shooting = false
		print("[auto] story done in %.1fs; endings: %s" % [(Time.get_ticks_msec() - t0) / 1000.0, ", ".join(Game.profile.endings.keys())])
		print("[auto] vars: ", Game.profile.last_route.get("vars", {}), "  achievements: ", Game.achieved.size())
		get_tree().quit()
		return
	if scenario.begins_with("battle:"):
		var kind := scenario.substr(7)
		prefix = "battle_" + kind
		Game.new_run()
		Game.run.scene = OS.get_environment("CT_SCENE") if OS.get_environment("CT_SCENE") != "" else "S5"
		Game.set_flag("has_sword")
		Game.set_flag("mara_joined")
		Game.set_flag("fen_fights")
		_preset()
		var enemies := []
		match kind:
			"jackals":
				enemies = [BattleDefs.enemy("jackal"), BattleDefs.enemy("jackal"), BattleDefs.enemy("jackal")]
			"hunters":
				enemies = [BattleDefs.enemy("hunter"), BattleDefs.enemy("hunter_captain"), BattleDefs.enemy("guard")]
			"factor":
				enemies = [BattleDefs.enemy("factor")]
		if every > 0.0:
			_shoot_loop(every)
		if OS.get_environment("CT_MENUS") != "":
			# without the autopilot: open each sub-menu of the first turn and
			# screenshot it (skills, then sword or item, then item)
			var peek := func() -> void:
				await wait(4.0)
				await shot("menu_cmd")
				for i in 3:
					for k in [["right"], ["down"], ["down", "right"]][i]:
						await tap(k)
					await tap("accept")
					await wait(0.4)
					await shot("menu_sub_%d" % i)
					await tap("cancel")
					await wait(0.3)
					await tap("up")
					await tap("left")
				get_tree().quit()
			peek.call()
		var r: Dictionary = await main.battle({"id": "test", "title": "A test of steel", "bg": OS.get_environment("CT_BG") if OS.get_environment("CT_BG") != "" else "road",
			"party": main.story.party(), "enemies": enemies})
		shooting = false
		print("[auto] battle result: ", r.outcome, " turns ", r.turns)
		get_tree().quit()
		return
	if scenario.begins_with("cine:"):
		for nm in scenario.substr(5).split(","):
			var c := Cinema.open()
			c.show_bg(nm, 0, 0.0)
			main.fade_rect.color.a = 0.0
			await wait(0.2)
			await shot("cine_" + nm)
			c.queue_free()
		get_tree().quit()
		return
	if scenario.begins_with("bbg:"):
		for nm in scenario.substr(4).split(","):
			var r := TextureRect.new()
			r.texture = Art.battle_bg(nm, 0)
			main.cine_layer.add_child(r)
			main.fade_rect.color.a = 0.0
			await wait(0.2)
			await shot("bbg_" + nm)
			r.queue_free()
		get_tree().quit()
		return
	if scenario.begins_with("minigame:"):
		var kind := scenario.substr(9)
		Game.new_run()
		var mashing := true
		var masher := func() -> void:
			while mashing:
				await tap(["accept", "left", "right", "up", "down", "accept"][randi() % 6], randf_range(0.05, 0.3))
		masher.call()
		if out != "":
			prefix = "mg_" + kind
			_shoot_loop(1.0)
		var r: Dictionary = await main.minigame(kind, {})
		mashing = false
		shooting = false
		print("[auto] minigame %s: %s" % [kind, r])
		get_tree().quit()
		return
	if scenario.begins_with("map:"):
		# load a field map from an act and screenshot it
		var parts := scenario.substr(4).split(".")
		Game.new_run()
		var act: Node = main.story.acts[parts[0]]
		var def: Dictionary = act.call(parts[1] + "_map")
		main.story.part = act
		main.load_map(def, Vector2i(int(OS.get_environment("CT_X")) if OS.get_environment("CT_X") != "" else 2, int(OS.get_environment("CT_Y")) if OS.get_environment("CT_Y") != "" else 3), 0)
		main.fade_rect.color.a = 0.0
		await wait(0.6)
		await shot("map_" + parts[1])
		get_tree().quit()
		return
	match scenario:
		"check":
			var n := 0
			for p in load("res://tools/check.gd").scan("res://scripts") + load("res://tools/check.gd").scan("res://tools"):
				var sc = load(p)
				n += 1
				if sc == null or not sc.can_instantiate():
					print("FAILED ", p)
			print("checked ", n, " scripts")
			get_tree().quit()
		"shell":
			main.fade_rect.color.a = 0.0
			main.title()
			await wait(3.5)
			await shot("shell_title")
			for scr in [EndingsScreen.new(), SettingsScreen.new(), RecordsScreen.new(), AchievementsScreen.new()]:
				main.cine_layer.add_child(scr)
				await wait(0.5)
				await shot("shell_" + scr.get_class() + str(shot_n))
				shot_n += 1
				scr.queue_free()
			get_tree().quit()
		"slots":
			# an old single-file save, as written before slots existed
			for i in Game.SLOTS:
				Game.clear_save(i)
			Game.new_run()
			Game.run.scene = "S2"
			Game.run.time = 1234.0
			Game._write_json(Game._path(Game.OLD_SAVE_PATH), Game.run)
			Game._migrate_old_save()
			print("slots after migration: ", range(Game.SLOTS).map(func(i): return Game.has_slot(i)),
				" old file left: ", FileAccess.file_exists(Game._path(Game.OLD_SAVE_PATH)), " summary: ", Game.save_summary())
			main.fade_rect.color.a = 0.0
			main.title()
			await wait(5.0)
			await shot("slots_title")
			for a in ["down", "accept"]:
				await tap(a)
			await wait(0.4)
			await shot("slots_load")
			await tap("cancel")
			await wait(0.3)
			for a in ["down", "accept"]:
				await tap(a)
			await wait(0.4)
			await shot("slots_new")
			await tap("accept")  # the first free slot (2) is preselected
			await wait(4.0)
			print("slot picked: ", Game.slot + 1, " slots now: ", range(Game.SLOTS).map(func(i): return Game.has_slot(i)),
				" latest: ", Game.latest_slot() + 1)
			print("load slot 1: ", Game.load_run(0), " -> slot ", Game.slot + 1, " scene ", Game.run.scene, " time ", Game.clock(Game.run.time))
			get_tree().quit()
		"pause":
			Game.new_run()
			_preset()
			Game.run.scene = "S5"
			var act: Node = main.story.acts.act2
			main.story.part = act
			main.load_map(act.kesh_map(), Vector2i(10, 9), 0)
			main.fade_rect.color.a = 0.0
			main.in_story = true
			await wait(0.4)
			main.dialog.backlog = [["Rook", "Ladies. Gentlemen. Wick."], ["", "The Saltway runs four hundred miles."]]
			main.world.run(main.field_menu)
			await wait(0.6)
			await shot("pause_status")
			# the other crew members' pages
			await tap("right")
			await wait(0.3)
			await shot("pause_status_2")
			await tap("right")
			await wait(0.3)
			await shot("pause_status_3")
			await tap("right")
			# the items window, every category
			await tap("down")
			await tap("accept")
			await wait(0.3)
			await shot("items_1")
			await tap("right")
			await wait(0.2)
			await shot("items_2")
			await tap("down")
			await wait(0.2)
			await shot("items_2b")
			await tap("right")
			await wait(0.2)
			await shot("items_3")
			await tap("cancel")
			await wait(0.3)
			# the skills window, every tab
			await tap("down")
			await tap("accept")
			await wait(0.3)
			await shot("skills_1")
			await tap("down")
			await tap("down")
			await tap("down")
			await wait(0.2)
			await shot("skills_1_locked")
			for i in 3:
				await tap("right")
				await wait(0.2)
				await shot("skills_%d" % (i + 2))
			await tap("down")
			await wait(0.2)
			await shot("skills_last_row2")
			await tap("cancel")
			await wait(0.3)
			await tap("down")
			await wait(0.3)
			await shot("pause_log")
			get_tree().quit()
		"touch":
			await _touch_test()
			get_tree().quit()
		"balance":
			# each key fight several times with a sensible autopilot
			var cases := [
				["S1", "", "act1", "_jackal_battle", []],
				["S1", "", "act1", "_ridge_battle", []],
				["S1", "", "act1", "_rob_battle", []],
				["S3", "has_sword", "act1", "_hunter_battle", [["rook"]]],
				["S4", "has_sword,fen_fights", "act2", "_gate_battle", []],
				["S11", "has_sword,mara_joined,fen_fights", "act3", "_factor_battle", []],
			]
			var only := OS.get_environment("CT_ONLY")
			for c in cases:
				if only != "" and not str(c[3]).contains(only):
					continue
				var wins := 0
				var notes := []
				for k in int(OS.get_environment("CT_N")) if OS.get_environment("CT_N") != "" else 3:
					Game.new_run()
					Game.run.scene = c[0]
					for f in str(c[1]).split(",", false):
						Game.set_flag(f)
					_preset()
					var act: Node = main.story.acts[c[2]]
					main.story.part = act
					var def: Dictionary = act.callv(c[3], c[4])
					var r: Dictionary = await main.battle(def)
					if r.outcome != "defeat":
						wins += 1
					notes.append("%s/%dt/-%d" % [r.outcome, r.turns, r.taken])
				print("[balance] %s %s: %d wins  %s" % [c[0], c[3], wins, ", ".join(notes)])
			get_tree().quit()
		"icon":
			var img: Image = ArtUI.app_icon().img
			img.resize(256, 256, Image.INTERPOLATE_NEAREST)
			img.save_png(ProjectSettings.globalize_path("res://icon.png"))
			print("[auto] wrote icon.png")
			get_tree().quit()
		"opening":
			if every > 0.0:
				prefix = "opening"
				_shoot_loop(every)
			await main.opening()
			get_tree().quit()
		_:
			print("[auto] unknown scenario ", scenario)
			get_tree().quit()


func _finger(pos: Vector2, pressed: bool, index: int = 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _drag_to(pos: Vector2, index: int = 0) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	Input.parse_input_event(e)


func _to_window(p: Vector2) -> Vector2:
	return Game.shell.game_rect.position + p * Game.shell.game_scale


func _swipe(from: Vector2, to: Vector2, steps: int = 8) -> void:
	## A finger drag in game pixels, then let go.
	_finger(_to_window(from), true)
	await get_tree().process_frame
	for i in steps:
		_drag_to(_to_window(from.lerp(to, (i + 1) / float(steps))))
		await get_tree().process_frame
	_finger(_to_window(to), false)
	await wait(0.4)


func _touch_test() -> void:
	var sh: Shell = Game.shell
	Game.new_run()
	_preset()
	Game.run.scene = "S5"
	var act: Node = main.story.acts.act2
	main.story.part = act
	main.load_map(act.kesh_map(), Vector2i(10, 9), 0)
	main.fade_rect.color.a = 0.0
	main.in_story = true
	await wait(0.4)
	# a thumb on the stick turns touch on; let go and the stick is gone
	_finger(_to_window(Vector2(40, 120)), true)
	await wait(0.2)
	_finger(_to_window(Vector2(40, 120)), false)
	await wait(0.8)
	print("[auto] touch on: ", Game.touch_active, " controls: ", sh.touch.controls.map(func(c): return c.id))
	await shot("touch_field")
	# the watchdog: a leaked lock while roaming frees Rook after a few seconds
	var w: World = main.world
	main.story.roaming = true
	w.hold("event")
	await wait(World.STUCK_LIMIT + 0.6)
	print("[auto] leaked lock after %.0fs: %s (busy=%s)" % [World.STUCK_LIMIT + 0.6, w.locks.keys(), w.busy])
	w.hold("menu")
	await wait(World.STUCK_LIMIT + 0.6)
	print("[auto] menu lock (explained) kept: ", w.locks.keys())
	w.release("menu")
	main.story.roaming = false
	# drag scrolling
	var ss := SettingsScreen.new()
	main.cine_layer.add_child(ss)
	await wait(0.4)
	var sel0 := ss.sel
	await _swipe(Vector2(150, 140), Vector2(150, 50))
	print("[auto] settings: dragged up -> scroll %.0f of %.0f, sel %d -> %d" % [ss.scroll, ss._max_scroll(), sel0, ss.sel])
	await shot("touch_settings_scrolled")
	await _swipe(Vector2(150, 50), Vector2(150, 160))
	print("[auto] settings: dragged back -> scroll %.0f" % ss.scroll)
	ss.queue_free()
	var acs := AchievementsScreen.new()
	main.cine_layer.add_child(acs)
	await wait(0.4)
	await _swipe(Vector2(150, 130), Vector2(150, 50))
	await wait(0.6)
	print("[auto] achievements: dragged up -> scroll %.0f" % acs.scroll)
	await shot("touch_achievements_scrolled")
	acs.queue_free()
	# items: a tap on a row still picks it
	Game.run.items = ["ledger", "map", "poster", "letter"]
	var iw := ItemsWindow.new()
	main.cine_layer.add_child(iw)
	iw.cat = 2
	iw._fill()
	await wait(0.3)
	var row := ItemsWindow.LIST.position + Vector2(30, 4 + 2 * ItemsWindow.ROW_H + 6)
	_finger(_to_window(row), true)
	await get_tree().process_frame
	_finger(_to_window(row), false)
	await wait(0.3)
	print("[auto] items: tapped row 3 -> index ", iw.index)
	await _swipe(row, row + Vector2(0, -40))
	print("[auto] items: short list ignores a drag -> top ", iw.top, " index ", iw.index)
	iw.queue_free()
	# a tap-the-screen minigame: the title card, and a touch on the black bar
	main.clear_world()
	main.in_story = false
	main.minigame("lockpick")
	await wait(0.8)   # (test runs skip the card after 0.6s of the game)
	await shot("touch_lockpick_card")
	print("[auto] lockpick layout: ", sh.touch.layout, " controls: ", sh.touch.controls.map(func(c): return c.id))
	var bar := Vector2(sh.game_rect.position.x * 0.5, sh.game_rect.get_center().y)
	_finger(bar, true)
	await get_tree().process_frame
	_finger(bar, false)
	await wait(4.0)
	print("[auto] playing: ", Game.touch_running)
	_finger(bar, true, 1)
	await get_tree().process_frame
	await get_tree().process_frame
	print("[auto] touch on the side bar holds OK: ", Input.is_action_pressed("accept"))
	await shot("touch_lockpick_play")
	_finger(bar, false, 1)
	await wait(0.3)
	await wait(6.0)
	# the loot grab: stick on the left, a tap anywhere else grabs
	var done := [false]
	var run_loot := func():
		await main.minigame("loot", {"time": 30.0})
		done[0] = true
	run_loot.call()
	await wait(3.0)
	var lg: Array = main.cine_layer.find_children("*", "MgLoot", true, false)
	if lg.is_empty():
		print("[auto] loot: no game found")
		return
	var right := _to_window(Vector2(250, 90))
	_finger(right, true)
	await get_tree().process_frame
	_finger(right, false)
	await wait(0.3)
	print("[auto] loot: tapped the picture -> taken ", lg[0].taken)
	await shot("touch_loot")

