class_name StoryAct3
extends StoryPart
## Act III: Dominion, and the endings.
## S9 The Bridge Ambush: protect the crew, seize the payroll, or pursue the Factor.
## S10 Teeth of the Pass: the cost, counted. A door where there is only rock.
## S11 No Thief Can Reach: the Factor, the keystone choice, and an epilogue.

const NIGHT := Color(0.48, 0.48, 0.78)


# ======================================================================
# S9 THE BRIDGE AMBUSH
# ======================================================================

func gorge_map() -> Dictionary:
	var npcs := [
		{"who": "factor", "tile": Vector2i(26, 7), "dir": 3},
		{"who": "hunter", "id": "h1", "tile": Vector2i(27, 6), "dir": 3},
		{"who": "hunter", "id": "h2", "tile": Vector2i(28, 7), "dir": 3},
		{"who": "bracken", "tile": Vector2i(4, 7), "dir": 2},
	]
	if not Game.run.kills.has("fen"):
		npcs.append({"who": "fen", "tile": Vector2i(5, 6), "dir": 2})
	if Game.flag("mara_joined") and not Game.flag("mara_left"):
		npcs.append({"who": "mara", "tile": Vector2i(3, 6), "dir": 2})
	if not Game.flag("wick_gone"):
		npcs.append({"who": "wick", "tile": Vector2i(2, 7), "dir": 2})
	return {
		"id": "gorge", "name": "Gorge Bridge", "theme": "gorge", "music": "tension",
		"rows": [
			"################################",
			"################################",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
			"========bbbbbbbbbbbbbbbb========",
			"========bbbbbbbbbbbbbbbb========",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
			"rrrrrrrrccccccccccccccccrrrrrrrr",
		],
		"props": [
			{"kind": "rope_post", "tile": Vector2i(7, 5), "area": Rect2i()},
			{"kind": "rope_post", "tile": Vector2i(7, 8), "area": Rect2i()},
			{"kind": "rope_post", "tile": Vector2i(24, 5), "area": Rect2i()},
			{"kind": "rope_post", "tile": Vector2i(24, 8), "area": Rect2i()},
			{"kind": "wagon", "tile": Vector2i(30, 7), "v": 1, "area": Rect2i(28, 6, 4, 2), "id": "payroll"},
			{"kind": "boulder", "tile": Vector2i(2, 3), "v": 0},
			{"kind": "dead_tree", "tile": Vector2i(29, 4), "v": 1},
			{"kind": "bush", "tile": Vector2i(5, 10), "v": 0},
		],
		"npcs": npcs,
		"exits": [],
	}


func scene_s9() -> Variant:
	scene = "S9"
	var c := await s.cine("gorge", 0.6)
	c.animate_bg("gorge", 4, 2.0)
	c.effect = "sand"
	c.effect_k = 0.3
	s.sfx("wind", 1.0, -6.0)
	await s.narrate("Gorge Bridge: two hundred feet of rope and plank over a red canyon, and the wind trying its best to have the lot.")
	await c.close(0.6)
	await s.explore(gorge_map(), Vector2i(6, 7), 2)
	s.lock(true)
	await s.pan(Vector2i(26, 7), 1.0)
	await s.narrate("On the far side: the Factor, two hunters, and a strongbox wagon flying Ollo's colours. The caravan payroll, crossing under escort.")
	await s.pan_back(0.8)
	var trade: bool = Game.flag("trade_agreed") and not Game.run.kills.has("fen")
	if trade:
		await s.say("fen", "Walk with me, son. Slow. We hand it over and we never look back.", "")
		await s.walk("fen", [Vector2i(9, 6), Vector2i(13, 6)], 26.0)
		_s9_crew_onto_deck(false)
		await s.walk("player", [Vector2i(13, 7)], 30.0)
		await s.walk("factor", [Vector2i(18, 7)], 26.0)
		await s.say("factor", "Old Fen. You did the sum.", "smile")
		await s.say("fen", "Every man walks home. That's the price. The sword for every man walking home.", "")
		await s.say("factor", "Of course. Of course.", "smile")
		await s.wait(0.4)
		await s.say("factor", "...I'm afraid I lied about the 'no one else.' Ledgers must balance, you see.", "")
	else:
		# out onto the planks together, and he comes to meet them halfway
		_s9_crew_onto_deck(true)
		s.walk("factor", [Vector2i(18, 7)], 26.0)
		await s.walk("player", [Vector2i(13, 7)], 30.0)
		await s.wait(0.6)
		s.face("player", 2)
		await s.say("factor", "You came. Good. I do so hate chasing.", "smile")
		await s.say("factor", "Return what is kept, bearer, and these people may go home.", "")
		await s.say("rook", "And if I don't?", "determined")
		await s.say("factor", "Then I'm afraid ledgers must balance.", "")
	# the ambush: hunters climbing up from under the bridge on both sides
	s.sfx("alert", 1.0, -2.0)
	s.shake(1.5, 0.4)
	for k in 3:
		var h := s.spawn("hunter", Vector2i(10 + k * 4, 5 + (k % 2) * 3), 0 if k % 2 == 0 else 1)
		h.hop(10.0)
		s.sfx("whiff", 1.0 + k * 0.1, -6.0)
		await s.wait(0.18)
	for id in ["bracken", "wick", "mara", "fen"]:
		if s.a(id):
			s.a(id).emote("!")
	if s.a("mara"):
		s.a("mara").set_pose("aim")
	s.omen_pulse()
	# his part is done: he turns his back on it and strolls off toward the wagon
	s.face("factor", 2)
	s.walk("factor", [Vector2i(26, 7)], 18.0)
	await s.say("blade", "Now. Choose what you're reaching for.")
	var opts := ["Get the crew across. Everyone.", "The payroll wagon. Take it.", "The Factor. End this now."]
	var r := await s.choose("Hunters on the ropes, the crew on the planks, the payroll on the far side, and the Factor walking calmly away.", opts)
	var res: Dictionary
	match r:
		0:
			Game.set_flag("bridge", "protect")
			Game.choose("At the bridge, protected the crew.")
			Game.add("loyalty", 2)
			res = await _s9_protect()
		1:
			Game.set_flag("bridge", "payroll")
			Game.choose("At the bridge, went for the payroll.")
			Game.add("finesse", 1)
			Game.add("suspicion", 1)
			res = await _s9_payroll()
		2:
			Game.set_flag("bridge", "pursue")
			Game.choose("At the bridge, chased the Factor.")
			Game.add("suspicion", 1)
			res = await _s9_pursue()
	await _s9_after(res)
	return "S10"


func _s9_crew_onto_deck(with_fen: bool) -> void:
	## The crew follows Rook out onto the bridge deck (rows 6-7), a few planks
	## behind him, so the ambush catches them on the planks. Not awaited.
	var spots := {"bracken": Vector2i(10, 7), "wick": Vector2i(9, 7), "mara": Vector2i(9, 6)}
	if with_fen:
		spots["fen"] = Vector2i(11, 6)
	for id in spots:
		if s.a(id):
			s.walk(id, [spots[id]], 26.0)


func _crew_units() -> Array:
	## The crew members that ride along as protected fighters.
	var out := []
	if not Game.flag("wick_gone"):
		out.append(BattleDefs.member("wick").merged({"ai": true}))
	out.append(BattleDefs.member("bracken").merged({"ai": true}))
	return out


func _s9_protect() -> Dictionary:
	var party: Array = s.party()
	if not Game.run.kills.has("fen") and not party.has("fen"):
		party.append("fen")
	var units := party.duplicate()
	units.append_array(_crew_units())
	var res := await s.battle({
		"id": "s9_protect", "title": "Ambush on Gorge Bridge!", "bg": "bridge", "music": "boss",
		"party": units,
		"enemies": [BattleDefs.enemy("hunter"), BattleDefs.enemy("hunter_captain"), BattleDefs.enemy("hunter", {"spd": 13})],
		"objective": {"kind": "escape", "turns": 4, "text": "HOLD THE BRIDGE:", "win_title": "EVERYONE ACROSS", "units": ["wick", "bracken"],
			"note": "Plank by plank, the crew makes the far cliff."},
		"on_turn": func(b: Battle, turn: int) -> Dictionary:
			if turn == 2 and Game.flag("mara_left"):
				await _mara_returns(b)
			return {},
	})
	for c in res.get("casualties", []):
		_fall(c)
	if res.get("casualties", []).is_empty() and res.outcome != "defeat":
		Game.set_pflag("protector")
	return res


func _mara_returns(b: Battle) -> void:
	## If she left the crew, she comes back exactly once: on the ridge, at the bridge.
	await b.hide_ui()
	Sfx.play("arrow", 1.0, -2.0)
	var e := b._first(b.enemies)
	if e:
		await b.projectile(Vector2(160, -10), e.center(), "arrow", 0.25)
		await b.hit(e, 30, {"sure": true, "fx": "pierce"})
	await b.say("mara", "Don't. Say. Anything. I'm not here for you.", "angry")
	await b.say("mara", "I'm here for the boy.", "")
	await b.show_ui()


func _s9_payroll() -> Dictionary:
	var res := await s.battle({
		"id": "s9_payroll", "title": "The payroll, or the crew?", "bg": "bridge", "music": "boss",
		"party": s.party(),
		"enemies": [BattleDefs.enemy("hunter"), BattleDefs.enemy("guard"), BattleDefs.enemy("hunter", {"hp": 44})],
		"objective": {"kind": "escape", "text": "TAKE THE PAYROLL", "turns": 6, "win_title": "THE PAYROLL IS HIS"},
		"acts": [{"id": "seize", "name": "Seize the payroll", "desc": "Cut the strongbox loose and run with it.", "who": "rook", "once": true}],
		"on_act": func(b: Battle, u: BattleUnit, id: String) -> Dictionary:
			if id == "seize":
				if b.turn < 2:
					await b.msg("The escort's still on the wagon. Not yet!", 0.8)
					return {}
				b.pose("rook", "reach", 0.6)
				Sfx.play("coins", 1.0, -2.0)
				b.fx.burst(u.center(), 30, [Pal.BRASS, Pal.LEMON, Pal.WHITE], Vector2(30, 100), Vector2(0.4, 0.8), {"up": 50.0, "acc": Vector2(0, 140), "shape": 1})
				await b.say("rook", "Three months of wages for every guard on the Saltway. Now THAT'S a legend.", "grin")
				return {"outcome": "objective", "title": "THE PAYROLL IS HIS", "note": "Behind him, on the bridge, someone is shouting his name."}
			return {},
	})
	if res.outcome != "defeat":
		Game.give_item("payroll")
		Game.set_pflag("payroll")
		# the cost: someone held the bridge while he ran for the money
		_fall("bracken")
	return res


func _s9_pursue() -> Dictionary:
	var res := await s.battle({
		"id": "s9_pursue", "title": "After the Factor!", "bg": "bridge", "music": "boss",
		"party": s.party(),
		"enemies": [BattleDefs.enemy("hunter_captain"), BattleDefs.enemy("hunter")],
		"objective": {"kind": "defeat", "text": "CUT THROUGH"},
		"victory_note": "The Factor is on the far cliff. Waiting, it seems. With a knife against the rope.",
	})
	Game.set_pflag("pursuer")
	return res


func _fall(who: String) -> void:
	Game.set_flag(who + "_dead")
	if who == "wick":
		Game.set_flag("wick_gone")


func _roll_call(people: Array) -> String:
	## The names of whoever actually made it across, in the crew's old order
	## (Bracken first, Rook last), for the "All of them" line.
	var short := {"bracken": "Bracken", "wick": "Wick", "fen": "Fen", "mara": "Mara", "rook": "Rook"}
	var names := []
	for id in ["bracken", "wick", "fen", "mara", "rook"]:
		if people.has(id):
			names.append(short[id])
	if names.size() == 2:
		return "%s and %s" % names
	return ", ".join(PackedStringArray(names))


func _s9_after(res: Dictionary) -> void:
	match str(Game.fval("bridge", "")):
		"protect":
			var c := await s.cine("gorge", 0.5)
			c.animate_bg("gorge", 4, 2.0)
			s.music("hope", 1.0)
			var people := ["rook"]
			for id in ["fen", "mara", "wick", "bracken"]:
				if s.a(id) and not Game.flag(id + "_dead"):
					people.append(id)
			for i in people.size():
				var a := c.person(people[i], Vector2(-20 - i * 26, 156), 2, "", "run")
				if people[i] == "rook":
					a.set_spec(s.rook_spec())
				c.walk(a, Vector2(230 + i * 16, 156), 90.0)
			await s.wait(2.6)
			if Game.flag("bracken_dead") or Game.flag("wick_dead"):
				await s.narrate("Not everyone makes the far side. The canyon takes its share, the way it always has.")
			else:
				await s.narrate("All of them. Every one. %s: off the planks and onto the rock, as the hunters fall back into the wind." % _roll_call(people))
				for a in c.actors.get_children():
					if a is Actor:
						a.hop(6.0)
			await s.narrate("Behind them, the Factor watches from the far cliff. He raises a hand, politely, and turns away.")
			await c.close(0.6)
		"payroll":
			var c := await s.cine("gorge", 0.5)
			s.music("sad", 1.0)
			await s.narrate("He runs with the strongbox in his arms and doesn't look back. Not at the shouting. Not at the sound of the planks.")
			await s.narrate("When he does look back, Bracken is on his knees in the middle of the bridge, holding three hunters with a cart axle and a grin.")
			await s.say("bracken", "GO ON, then! Go on, Rook! Buy me a goat!", "laugh")
			s.sfx("rope_snap", 0.8, -2.0)
			s.shake(2.0, 0.6)
			await s.narrate("Then the ropes on that side go, and the canyon takes the rest.")
			Game.choose("Bracken held the bridge while Rook ran with the payroll. He fell.")
			await c.close(0.6)
		"pursue":
			var c := await s.cine("gorge", 0.4)
			c.animate_bg("gorge", 4, 3.0)
			var f := c.person("factor", Vector2(270, 72), 3)
			var rk := c.person("rook", Vector2(120, 78), 2, "determined", "run")
			rk.set_spec(s.rook_spec())
			await s.say("factor", "You see? It always reaches first. And it always, always falls.", "")
			s.sfx("rope_snap", 1.0, -2.0)
			s.shake(3.0, 0.8)
			await c.show_bg("gorge_fall", 0, 0.2)
			c.animate_bg("gorge_fall", 4, 4.0)
			rk.set_pose("hurt")
			await c.walk(rk, Vector2(150, 130), 120.0)
			rk.set_pose("cower")
			await s.narrate("The bridge drops away beneath him. He catches a rope, the blade in his other hand, swinging over two hundred feet of red air.")
			await s.narrate("By the time he's climbed back up, the crew is on the far side of the gorge, and the hunters have them.")
			await s.say("wick", "(far away) ROOK!", "scared")
			Game.set_flag("wick_captured")
			Game.set_flag("wick_gone")
			await s.narrate("On the cliff path, the Factor has dropped something. A page from his ledger, fluttering.")
			Game.add_clue("ledger")
			Game.add_lore("factor_page")
			await c.close(0.6)
	if res.get("outcome", "") == "defeat":
		Game.set_flag("injured")
		await s.narrate("The fight goes badly. They get off the bridge anyway, bleeding, which is the only way anyone has ever got off that bridge.")


# ======================================================================
# S10 TEETH OF THE PASS
# ======================================================================

func pass_map() -> Dictionary:
	var npcs := []
	if not Game.run.kills.has("fen") and not Game.flag("fen_left"):
		npcs.append({"who": "fen", "tile": Vector2i(9, 8), "dir": 2, "pose": "sit"})
	if Game.flag("mara_joined") and not Game.flag("mara_left") and not Game.run.kills.has("mara"):
		npcs.append({"who": "mara", "tile": Vector2i(15, 6), "dir": 1})
	if not Game.flag("wick_gone"):
		npcs.append({"who": "wick", "tile": Vector2i(13, 9), "dir": 0, "pose": "sit"})
	if not Game.flag("bracken_dead"):
		npcs.append({"who": "bracken", "tile": Vector2i(7, 10), "dir": 1})
	npcs.append({"who": "crow", "id": "crow", "tile": Vector2i(19, 4), "dir": 3, "silent": true})
	var props := [
		{"kind": "campfire", "tile": Vector2i(11, 8), "anim": 3, "fps": 6.0, "light": Pal.CANDLE, "lr": 46, "pulse": 5.0, "light_off": Vector2(0, -8)},
		{"kind": "boulder", "tile": Vector2i(3, 4), "v": 1},
		{"kind": "boulder", "tile": Vector2i(20, 9), "v": 0},
		{"kind": "rock", "tile": Vector2i(17, 11), "v": 0},
		{"kind": "dead_tree", "tile": Vector2i(19, 4), "v": 0},
		{"kind": "bedroll", "tile": Vector2i(14, 9), "v": 1, "decal": true},
		{"kind": "bedroll", "tile": Vector2i(8, 9), "v": 3, "decal": true},
	]
	var k := 0
	for who in ["bracken", "wick", "fen"]:
		if Game.flag(who + "_dead") or (who == "fen" and Game.run.kills.has("fen")):
			props.append({"kind": "rubble", "tile": Vector2i(3 + k * 2, 11), "v": k, "event": {"id": "cairn_" + who}})
			k += 1
	return {
		"id": "pass", "name": "The Pass of Teeth", "theme": "gorge", "music": "sad", "tint": NIGHT,
		"rows": [
			"########################",
			"########################",
			"rrrrrrrrrrrxxrrrrrrrrrrr",
			"rrrrrrrrrrxxxxrrrrrrrrrr",
			"rrrrrrrrrrrxxrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
			"rrrrrrrrrrrrrrrrrrrrrrrr",
		],
		"props": props,
		"npcs": npcs,
		"events": [{"tile": Vector2i(11, 1), "id": "cliff"}, {"tile": Vector2i(12, 1), "id": "cliff"}],
		"exits": [],
	}


func scene_s10() -> Variant:
	scene = "S10"
	var c := await s.cine("pass_night", 0.6)
	c.animate_bg("pass_night", 4, 1.5)
	c.effect = "stars"
	c.effect_k = 0.2
	s.music("sad", 1.0)
	await s.narrate("The Pass of Teeth: a crooked road through peaks like a broken jaw. They climb until they can't, and make camp under the rock.")
	var lost := []
	for who in ["bracken", "wick"]:
		if Game.flag(who + "_dead"):
			lost.append(Data.spec(who).name)
	if Game.flag("wick_captured"):
		await s.narrate("Wick isn't with them. The hunters have him, and the Factor has the hunters.")
	if not lost.is_empty():
		await s.narrate("They build a cairn for %s. Nobody knows the right words. Fen says some anyway." % " and ".join(lost))
	await c.close(0.6)
	await s.explore(pass_map(), Vector2i(11, 10), 1)
	s.lock(true)
	await _s10_reckoning()
	s.lock(false)
	await s.say("", "Talk to whoever's still here. When you're ready, look at the cliff face to the north.", "", {"color": Pal.CANDLE.lerp(Pal.WHITE, 0.4)})
	s.marker(Vector2i(11, 2))
	await s.until(func() -> bool: return Game.flag("s10_done"))
	return "S11"


func _s10_reckoning() -> void:
	## The blade speaks plainly now, more or less, depending on how much it's been used.
	var r := s.a("player")
	if Game.tier() >= 3:
		r.set_mood("omen")
		s.omen_pulse()
		await s.say("blade", "Look at them. Every one of them has a price. The old man's is his own skin. The scout's is her sister. The boy's is you.")
		await s.say("blade", "Keep me, and you'll never need anyone. Keep me, and they'll sing about you until the road turns to sand.")
		await s.think("His own eyes feel wrong. Too wide. Too much violet at the edges of everything.")
		r.set_mood("")
	elif Game.tier() == 2:
		s.sfx("whisper", 0.7, -6.0)
		await s.say("blade", "We're almost there. You and I. Don't let them make you small again.")
	else:
		s.sfx("whisper", 0.6, -10.0)
		await s.say("blade", "...You hold me like you're afraid of me. Good. You're the first in a while.")


func _s10_talk(n: Actor) -> void:
	match n.info.get("who", ""):
		"mara":
			var k := Game.bump_talk("mara_s10")
			if k > 1:
				await s.say("mara", "Get some rest, Rook. Tomorrow he comes. He always comes.", "")
				return
			if Game.flag("confessed"):
				await s.say("mara", "I've been watching it, like we said. Every night. It's quieter when you're tired.", "")
				await s.say("mara", "And it's louder every time you use it. I don't think you notice anymore. I do.", "worried")
			elif Game.run.items.has("letter"):
				await s.say("mara", "My letter's gone. The one to my sister. I wonder where it went.", "angry")
				await s.think("It's in his coat. He'd forgotten. She hasn't.")
			elif Game.fval("s1", "") == "help":
				await s.say("mara", "You know what I keep thinking about? That wheel. You walked down off that ridge and lifted a wagon for nothing.", "smile")
				await s.say("mara", "Whoever that was. I liked him.", "")
			else:
				await s.say("mara", "I still don't know if I trust you. But I trust that thing less.", "")
			if Game.fval("bridge", "") == "payroll":
				n.set_mood("angry")
				await s.say("mara", "And I watched you run past Bracken with your arms full of money.", "angry")
		"fen":
			var k := Game.bump_talk("fen_s10")
			if k > 1:
				await s.say("fen", "Bread. Roof. People who'd notice. That's all it ever was, son.", "")
				return
			if Game.flag("trade_agreed"):
				await s.say("fen", "I tried to buy us home. I thought I could balance his ledger. You can't. Nobody can.", "sad")
			elif Game.flag("spared_fen"):
				await s.say("fen", "You lowered it. At the Rookery. Whatever it showed you, you lowered it.", "")
				await s.say("fen", "Hold on to that. It might be the only thing that's yours.", "smile")
			else:
				await s.say("fen", "That man in Varn. The one with the hands on his grave. Do you know who he was?", "")
				await s.say("fen", "My brother. He wanted to be a legend too.", "sad")
				Game.add_lore("fen_brother")
		"wick":
			await s.say("wick", "Are we going to be okay, Rook? You'd say if we weren't. You'd do the bow and say something stupid.", "worried")
			s.a("player").gesture("bow", 1.0)
			await s.say("rook", "Something stupid. There. We're fine.", "smile")
			n.set_mood("smile")
		"bracken":
			if Game.flag("wick_dead"):
				await s.say("bracken", "He was going to learn the bow. The real one.", "cry")
			else:
				await s.say("bracken", "My knee says snow. My knee has never once been right. I hope it's right.", "")
		"crow":
			await s.think("The crow. It's been here since the waystation. Waiting, like everything else.")


func _s10_examine(ev: Dictionary) -> void:
	var id: String = ev.get("id", "")
	if id.begins_with("cairn_"):
		var who := id.substr(6)
		await s.think("A pile of stones for %s. The wind is already moving the small ones." % Data.spec(who).name)
		return
	if id != "cliff":
		await super.examine(ev)
		return
	s.unmarker()
	var clues: Array = Game.run.clues
	if clues.size() >= 2:
		await s.narrate("He lays the map scrap, the ledger page and the shrine's words side by side, and looks at the rock.")
		s.sfx("rumble", 0.8, -6.0)
		s.shake(1.0, 0.6)
		var door := s.w.add_prop({"kind": "tomb_door", "tile": Vector2i(11, 1), "v": 0, "wall": true, "offset": Vector2(8, 4), "id": "door"})
		door.modulate.a = 0.0
		door.create_tween().tween_property(door, "modulate:a", 1.0, 1.4)
		await s.wait(1.4)
		Game.set_flag("found_door")
		await s.narrate("There. Exactly where the map put it: the outline of a door, carved so finely into the cliff that the wind has never found the seam. And on it, two figures with no faces.")
		if clues.size() >= 3:
			s.w.add_light(door.position + Vector2(0, -20), 30, Pal.OMEN, 2.0)
			await s.say("blade", "No. Not there. Anywhere but there.")
			await s.think("The blade is afraid. He didn't know it could be.")
	else:
		await s.think("Just rock. Old, cold rock. If there was ever a door here, he doesn't know how to see it.")
	Game.set_flag("s10_done")


# ======================================================================
# S11 NO THIEF CAN REACH
# ======================================================================

func scene_s11() -> Variant:
	scene = "S11"
	var c := await s.cine("pass_dawn", 0.6)
	s.music("tension", 1.0)
	var people := ["rook"]
	for id in ["fen", "mara", "bracken", "wick"]:
		if _here(id):
			people.append(id)
	var xs := [170, 214, 246, 278, 300]
	var actors := {}
	for i in people.size():
		var a := c.person(people[i], Vector2(xs[i], 156 - (i % 2) * 6), 3)
		if people[i] == "rook":
			a.set_spec(s.rook_spec())
		actors[people[i]] = a
	await s.narrate("Dawn on the Pass of Teeth. Up the road from the gorge, unhurried, comes a man in cream.")
	var f := c.person("factor", Vector2(-20, 156), 2)
	var hs := []
	for k in 2:
		hs.append(c.person("hunter", Vector2(-50 - k * 24, 150 + k * 8), 2))
	if Game.flag("wick_captured"):
		var wk := c.person("wick", Vector2(-80, 156), 2, "scared")
		c.walk(wk, Vector2(40, 156), 30.0)
	c.walk(f, Vector2(90, 156), 30.0)
	for i in hs.size():
		c.walk(hs[i], Vector2(60 - i * 24, 150 + i * 8), 30.0)
	await s.wait(2.6)
	await s.say("factor", "Good morning. You found the door, I see. Or you didn't. Either way, here we all are.", "smile")
	if Game.flag("wick_captured"):
		await s.say("factor", "The boy is quite well. He'll walk home the moment the ledger balances.", "")
		await s.say("wick", "Rook, don't give it to him! Don't- he says it'll eat you either way!", "scared")
	await s.say("factor", "I'll ask one last time, because it's polite. Return what is kept.", "")
	actors.rook.set_mood("determined")
	actors.rook.set_pose("ready")
	s.sfx("sword_draw", 1.0, -2.0)
	await s.say("rook", "No thief can reach it, right? Let's see.", "determined")
	await c.close(0.4)
	var res := await s.battle(_factor_battle())
	var persuaded: bool = res.outcome == "objective"
	Game.set_flag("factor_beaten", res.outcome == "victory")
	Game.set_flag("factor_persuaded", persuaded)
	if Game.flag("wick_captured") and res.outcome != "defeat":
		Game.set_flag("wick_captured", false)
		Game.set_flag("wick_gone", false)
	return await _keystone(res)


func _here(id: String) -> bool:
	if Game.run.kills.has(id) or Game.flag(id + "_dead"):
		return false
	match id:
		"mara":
			return Game.flag("mara_joined") and not Game.flag("mara_left")
		"wick":
			return not Game.flag("wick_gone")
		"fen":
			return not Game.flag("fen_left")
	return true


func _factor_battle() -> Dictionary:
	var talk := [
		{"id": "bearer", "label": "You were a bearer.", "text": "\"You were a bearer once. You told me so.\"", "good": true, "need": func() -> bool: return Game.run.lore.has("factor_who"),
			"reply": [["factor", "I was. A long time ago. I wanted to keep things.", "sad"]]},
		{"id": "keep", "label": "What did you want?", "text": "\"What did you want to keep? Before all this?\"", "good": true, "worth": 1, "need": func() -> bool: return Game.lore_count() >= 2,
			"reply": [["factor", "...A house. A wife. A little girl who sang. I kept them so carefully that they left.", "sad"]]},
		{"id": "door", "label": "Let me close the door.", "text": "\"There's a door in the Teeth. Let me close it.\"", "good": true, "worth": 2, "need": func() -> bool: return Game.flag("found_door"),
			"reply": [["factor", "Close it? From which side, thief?", "shock"]]},
		{"id": "wick", "label": "Let the boy go.", "text": "\"Let the boy go. He's not in your ledger.\"", "good": true, "need": func() -> bool: return Game.flag("wick_captured"),
			"reply": [["factor", "Everyone is in my ledger, eventually. But... very well.", ""]]},
		{"id": "threat", "label": "I'll take your ledger.", "text": "\"I'll take your ledger next. Your name in it.\"", "good": false,
			"reply": [["factor", "My name was the first one in it.", "smile"]]},
	]
	return {
		"id": "s11_factor", "title": "The Factor", "bg": "pass_dawn", "music": "boss",
		"party": s.party(),
		"enemies": [BattleDefs.enemy("factor", {"pos": Vector2(84, 128)}), BattleDefs.enemy("hunter", {"pos": Vector2(44, 112), "hp": 56}), BattleDefs.enemy("hunter", {"pos": Vector2(124, 112), "hp": 44})],
		"objective": {"kind": "persuade" if Game.lore_count() >= 2 else "defeat", "need": 4, "who": "factor", "text": "REACH HIM" if Game.lore_count() >= 2 else "DEFEAT THE FACTOR",
			"win_title": "THE LEDGER CLOSES", "note": "The Factor sits down in the road, very carefully, like a man much older than he looks.",
			"talk_desc": "He's listening. He always listens."},
		"talk": talk,
		"victory_title": "THE FACTOR KNEELS",
		"victory_note": "His robes are still spotless. He seems surprised by that.",
		"thresholds": [{"unit": "e0", "below": 0.5, "fn": func(b: Battle) -> Dictionary:
			await b.say("factor", "You're using it more. Can you feel it? Every time you reach for it, it reaches back.", "")
			await b.say("blade", "Don't listen. Strike.")
			return {}}],
	}


func _keystone(res: Dictionary) -> Dictionary:
	var elig: Array = Game.main.story.eligible()
	var c := await s.cine("pass_dawn", 0.5)
	s.music("omen", 1.0)
	var rk := c.person("rook", Vector2(170, 156), 3, "", "hold_up")
	rk.set_spec(s.rook_spec())
	var f := c.person("factor", Vector2(90, 156), 2, "sad", "kneel")
	if res.outcome == "defeat":
		f.set_pose("walk")
		await s.narrate("Rook is on his knees in the road. The Factor stands over him, dusting off his sleeves, and waits.")
	else:
		await s.narrate("The Factor kneels in the road. The hunters have fled. The wind has stopped, as if the pass were holding its breath.")
	for id in ["mara", "fen", "wick", "bracken"]:
		if _here(id):
			c.person(id, Vector2(230 + ["mara", "fen", "wick", "bracken"].find(id) * 22, 154), 3)
	await s.say("blade", "Choose.")
	await s.narrate("Everything comes to this. What he takes. What he keeps. What he owns.")
	var opts := []
	var keys := []
	opts.append("\"Keep it. It's mine.\"")
	keys.append("legendary" if elig.has("legendary") and Game.flag("factor_beaten") else "claimed")
	if elig.has("honor"):
		opts.append("\"Mara. You carry it.\"")
		keys.append("honor")
	if elig.has("vault") and Game.flag("found_door"):
		opts.append("\"I'll seal it behind the door.\"")
		keys.append("vault")
	if elig.has("empty"):
		opts.append("Drop it in the dust and walk away.")
		keys.append("empty")
	opts.append("\"Dosha will pay. Everything has a price.\"")
	keys.append("fence")
	var r := await s.choose("The blade waits in his hand. Everyone waits.", opts)
	var key: String = keys[r]
	Game.choose("At the Pass of Teeth: " + str(opts[r]))
	await c.close(0.6)
	var rec: Dictionary
	match key:
		"legendary":
			rec = await _end_legendary()
		"honor":
			rec = await _end_honor()
		"vault":
			rec = await _end_vault()
		"empty":
			rec = await _end_empty()
		"fence":
			rec = await _end_fence()
		_:
			rec = await _end_claimed()
	rec.ending = key
	rec.eligible = elig
	if Game.run.get("kills", []).is_empty():
		Game.set_pflag("clean")
	if Game.lore_count() >= 3:
		Game.set_pflag("lore_all")
	return rec


func _bond() -> String:
	if Game.run.kills.has("mara") or Game.run.kills.has("fen"):
		return "He killed the people who'd have noticed if he didn't come back."
	if Game.v("mara") >= Game.v("fen") and Game.flag("mara_joined"):
		return "Mara: %s." % PauseMenu.bond_word(Game.v("mara"))
	return "Old Fen: %s." % PauseMenu.bond_word(Game.v("fen"))


# ------------------------------------------------------------- endings ---

func _end_legendary() -> Dictionary:
	# they won't let him keep it, so he takes it from them too
	var c := await s.cine("pass_dawn", 0.4)
	var foes := []
	for id in ["mara", "fen", "bracken"]:
		if _here(id):
			foes.append(id)
	if not foes.is_empty():
		var who: String = foes[0]
		await s.say(who, "Put it down, Rook. Please. We can still walk home.", "worried")
		await s.say("blade", "They'll take me. They'll take your name. Everyone you've ever known is a thief.")
		await s.say("rook", "Everyone. Everyone's a thief.", "omen")
		await c.close(0.3)
		var enemies := []
		var slots := [Vector2(84, 126), Vector2(46, 114), Vector2(122, 114)]
		for i in foes.size():
			enemies.append(BattleDefs.enemy("mara" if foes[i] == "mara" else ("fen" if foes[i] == "fen" else "guard"),
				{"spec": foes[i], "name": Data.spec(foes[i]).name, "nonlethal": true, "ko": "kneel", "pos": slots[i]}))
		await s.battle({"id": "s11_friends", "title": "No friends. No thieves.", "bg": "pass_dawn", "music": "boss",
			"party": ["rook"], "enemies": enemies, "objective": {"kind": "disarm", "text": "TAKE IT ALL"}, "no_hostile": true,
			"victory_title": "UNREACHABLE", "victory_note": "One by one, they go down on their knees in the road. None of them reaches for the blade again."})
	else:
		await c.close(0.3)
	var c2 := await s.cine("tavern", 0.8)
	c2.animate_bg("tavern", 2, 1.0)
	s.music("legend", 1.0)
	var rk := c2.person("rook", Vector2(160, 160), 0, "", "sit")
	rk.set_spec(s.rook_spec())
	c2.person("crow", Vector2(196, 150), 3)
	await s.narrate("They sing about him now. In Varn, in Kesh, in taverns all down the Saltway. THE ROOK. The thief no lock could hold and no friend could stop.")
	await s.narrate("Every song is different. In every one, he's alone.")
	rk.set_mood("sad")
	await s.say("blade", "There. A name that outlives you. I keep my promises.")
	await s.narrate("He drinks in every tavern that sings about him, at a table for one, with a sword across his knees and a crow on the chair beside him.")
	await s.the_end("THE LEGENDARY THIEF")
	return {"bearer": "Became the legend of the Saltway, sung in every tavern, and drank alone in all of them.",
		"bond": "His friends knelt in the road at the Pass of Teeth. None of them said his name again.",
		"sword": "Kept by Rook. His only companion, to the end."}


func _end_honor() -> Dictionary:
	var c := await s.cine("pass_dawn", 0.5)
	s.music("hope", 1.0)
	var rk := c.person("rook", Vector2(160, 156), 3, "", "kneel")
	rk.set_spec(s.rook_spec())
	var mara_spec: Dictionary = Data.spec("mara").duplicate()
	mara_spec.weapon = "sword"
	mara_spec.variant = "sword"
	var m := c.person("mara", Vector2(120, 156), 2)
	await s.say("rook", "Mara. You watched it with me, every night. You never once reached for it.", "")
	await s.say("rook", "You carry it. Take it somewhere it can't hurt anyone who loves you.", "cry")
	await s.say("mara", "...And you?", "sad")
	await s.say("rook", "I'll be the man who lifted a wagon for nothing. Somebody told me she liked him.", "smile")
	m.set_spec(mara_spec)
	m.set_pose("hold_up")
	s.sfx("sword_draw", 0.8, -4.0)
	s.flash(Pal.OMEN, 0.4)
	await s.say("blade", "...Oh. A scout. You'll watch me very closely, won't you.")
	await s.say("mara", "Every night.", "determined")
	await c.close(0.6)
	var c2 := await s.cine("sea_road", 0.8)
	c2.animate_bg("sea_road", 4, 1.0)
	var m2 := c2.person("mara", Vector2(120, 150), 1)
	m2.set_spec(mara_spec)
	var r2 := c2.person("rook", Vector2(150, 160), 1)
	r2.set_spec(Data.spec("rook"))
	if not Game.run.kills.has("fen"):
		c2.person("fen", Vector2(180, 160), 1)
	if not Game.flag("wick_gone"):
		c2.person("wick", Vector2(206, 162), 1)
	await s.narrate("At the border road, she goes north, toward the grey sea and her sister and somewhere far away from every bearer who ever wanted anything.")
	c2.walk(m2, Vector2(160, 118), 18.0)
	await s.narrate("The crew walks home. All of them. Rook teaches Wick the bow, the real one, on the steps of the Rookery, and it's terrible, and everyone laughs.")
	await s.narrate("Mara writes, sometimes. The letters are mostly about how badly she sleeps.")
	await s.the_end("HONOR AMONG THIEVES")
	return {"bearer": "Went home to the Rookery with nothing but his crew, and never once missed the sword.",
		"bond": "Mara carried the curse away north, alone, and writes to him about how badly she sleeps.",
		"sword": "Carried away by Mara, toward the grey northern sea."}


func _end_vault() -> Dictionary:
	var c := await s.cine("tomb", 0.6)
	c.animate_bg("tomb", 2, 2.0)
	s.music("omen", 1.0)
	var rk := c.person("rook", Vector2(60, 156), 2)
	rk.set_spec(s.rook_spec())
	var sar := c.sprite(Art.prop("sarcophagus", 1), Vector2(200, 146))
	await s.narrate("The door in the Teeth opens for him, the way the shrine promised: only for the one who means to close it.")
	await c.walk(rk, Vector2(170, 156), 26.0)
	rk.set_pose("kneel")
	s.sfx("sword_draw", 0.6, -4.0)
	var sw := c.sprite(Art.prop("sword_prop", {"name": 1, "crow": 2}.get(Game.run.get("mark", ""), 0)), Vector2(200, 128), 1.0)
	sw.rotation = -PI / 2.0
	sw.scale = Vector2(0.5, 0.5)
	await s.say("blade", "No thief can reach me here. Not even you.")
	await s.say("rook", "That's the idea.", "smile")
	await s.say("blade", "...Someone will come. Someone always comes. Someone who wants something very badly.")
	await s.say("rook", "Then they'll have to want it through a door that only opens for people who mean to leave it shut.", "")
	await c.close(0.6)
	var c2 := await s.cine("pass_dawn", 0.6)
	s.music("ending", 1.0)
	await s.narrate("He stays a season in the pass, with the crow for company. He carves a statue at the door: a bearer, both hands on a sword, point down.")
	await s.narrate("He doesn't give it a face. Faces are how the blade finds you.")
	await s.narrate("Years from now, in some other age, someone will climb the Teeth looking for a door where there is only rock. Rook built that door. It's the only thing he ever made that will outlive him.")
	await s.the_end("THE UNREACHABLE VAULT")
	return {"bearer": "Built a tomb in the Pass of Teeth and carved a faceless bearer at its door.",
		"bond": _bond(),
		"sword": "Sealed in the tomb he built, where a later bearer will one day find it."}


func _end_empty() -> Dictionary:
	var c := await s.cine("pass_dawn", 0.5)
	s.music("hope", 1.0)
	var rk := c.person("rook", Vector2(160, 156), 3, "", "hold_up")
	rk.set_spec(s.rook_spec())
	var f := c.person("factor", Vector2(90, 156), 2, "", "kneel")
	await s.say("blade", "You won't. You can't. You wanted a name.")
	await s.say("rook", "I wanted a lot of things. Turns out I wanted bread and a roof and people who'd notice.", "smile")
	rk.set_pose("walk")
	s.sfx("thud", 1.2, -4.0)
	var sw := c.sprite(Art.prop("sword_prop", 0), Vector2(150, 160))
	sw.rotation = PI / 2.0
	sw.scale = Vector2(0.4, 0.4)
	rk.set_spec(Data.spec("rook"))
	await s.narrate("It hits the road with a sound like any other piece of metal.")
	f.set_pose("walk")
	await s.say("factor", "...Nobody's ever done that. Not once, in all the years.", "shock")
	await s.say("factor", "I'll take it back to its box, then. Good luck, thief. I don't think you'll need it.", "smile")
	await c.close(0.6)
	var c2 := await s.cine("road_far", 0.6)
	var people := ["rook"]
	for id in ["mara", "fen", "wick", "bracken"]:
		if _here(id):
			people.append(id)
	for i in people.size():
		var a := c2.person(people[i], Vector2(140 + i * 18, 176), 1)
		c2.walk(a, Vector2(150 + i * 8, 136), 14.0)
	await s.narrate("They walk home with empty hands. No haul. No legend. No name on any poster.")
	await s.narrate("Somewhere behind them, a cream wagon rolls on toward the border, carrying a sealed box. Rook doesn't look back at it. He's busy. Wick wants to learn the bow.")
	await s.the_end("EMPTY HANDS")
	return {"bearer": "Left with nothing: no name, no coin, no blade. Only people who'd notice if he didn't come back.",
		"bond": _bond(),
		"sword": "Left in the dust of the pass; the Factor carried it back to its sealed chest."}


func _end_fence() -> Dictionary:
	var c := await s.cine("shop", 0.6)
	s.music("town", 1.0)
	var d := c.person("dosha", Vector2(110, 160), 2, "grin")
	var rk := c.person("rook", Vector2(200, 160), 3)
	rk.set_spec(s.rook_spec())
	await s.say("dosha", "Five hundred crowns. For a sword. I must be getting sentimental.", "smirk")
	await s.say("rook", "Sold.", "")
	s.sfx("coins", 1.0, -2.0)
	rk.set_spec(Data.spec("rook"))
	d.set_spec(Data.spec("dosha"))
	await s.say("blade", "...Ah. A merchant. Everything has a price. I'll find someone who wants me more than you did.")
	await c.close(0.6)
	var c2 := await s.cine("tavern", 0.6)
	var r2 := c2.person("rook", Vector2(160, 160), 0, "", "sit")
	await s.narrate("He's rich for a while. He buys Bracken's goats. He buys Fen a new stick with a brass top. He buys everyone drinks.")
	await s.narrate("Dosha sells the blade across the border, to a collector of beautiful things. Within the month, the collector has disappeared, and so has the blade.")
	r2.set_mood("worried")
	await s.narrate("Rook spends the rest of his life with his back to the wall, watching every tall man in cream who walks through the door.")
	await s.the_end("THE FENCE'S PRICE")
	return {"bearer": "Rich for a while. Never again sat with his back to a door.",
		"bond": _bond(),
		"sword": "Sold across the border to a collector of beautiful things, and then lost again."}


func _end_claimed() -> Dictionary:
	var c := await s.cine("pass_dawn", 0.5)
	s.music("omen", 1.0)
	var rk := c.person("rook", Vector2(160, 156), 3, "omen", "hold_up")
	rk.set_spec(s.rook_spec())
	var f := c.person("factor", Vector2(90, 156), 2, "smile")
	await s.say("rook", "It's mine. I took it. It's mine.", "omen")
	await s.say("factor", "Yes. Of course it is.", "smile")
	await s.say("factor", "And you are its. That's how keeping works, you see. I should know. I'm very good at it.", "")
	rk.set_pose("walk")
	rk.tremble(1.5)
	await s.say("blade", "There you are.")
	await c.close(0.6)
	var c2 := await s.cine("saltway", 0.6)
	c2.effect = "dust"
	var f2 := c2.person("factor", Vector2(-20, 154), 2)
	var newf: Dictionary = Data.spec("factor").duplicate()
	newf.id = "rook_factor"
	newf.name = "Rook"
	newf.skin = Data.ROOK_SKIN
	newf.robe = Color("efe6d2")
	newf.patches = true
	newf.jacket = Color("4a6688")
	var r2 := c2.person("factor", Vector2(-50, 158), 2)
	r2.set_spec(newf)
	c2.walk(f2, Vector2(380, 154), 22.0)
	c2.walk(r2, Vector2(350, 158), 22.0)
	await s.narrate("The cream caravan rolls on toward the border at dawn. Beside the old custodian walks a younger one, in spotless robes, with one blue patch on the sleeve that he has never quite been able to give up.")
	await s.narrate("He is very polite. He is very patient. He never, ever runs.")
	await s.the_end("THE BEARER CLAIMED")
	return {"bearer": "Became the Factor's apprentice custodian. Polite, patient, and kept.",
		"bond": _bond(),
		"sword": "Still in the cream caravan's sealed chest, with a new custodian."}


# --------------------------------------------------------------- routing --

func talk(n: Actor) -> void:
	match scene:
		"S10":
			await _s10_talk(n)
		_:
			await s.think("Not now.")


func examine(ev: Dictionary) -> void:
	match scene:
		"S10":
			await _s10_examine(ev)
		_:
			await super.examine(ev)


func autoplay() -> void:
	match scene:
		"S10":
			if explore_extras():
				for id in ["mara", "fen", "wick", "bracken"]:
					if s.a(id):
						await _s10_talk(s.a(id))
			await _s10_examine({"id": "cliff"})
