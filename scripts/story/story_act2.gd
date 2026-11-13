class_name StoryAct2
extends StoryPart
## Act II: Reliance.
## S4 The Rookery: the haul, Wick and the blade, a name carved, Mara at the gate.
## S5 Kesh Crossing: fence, wanted posters, giving things back, the Factor in a crowd.
## S6 Campfire Accusation: the blade shows Mara reaching for it.
## S7 The Shrine of the Unnamed: faceless statues, a memory, the Factor talks.
## S8 Fen's Bargain: trade the blade for the crew's lives?

const NIGHT := Color(0.5, 0.48, 0.78)


# ======================================================================
# S4 THE ROOKERY
# ======================================================================

func rookery_map(night: bool = true) -> Dictionary:
	var npcs := [
		{"who": "fen", "tile": Vector2i(8, 6), "dir": 0, "pose": "sit"},
		{"who": "bracken", "tile": Vector2i(14, 7), "dir": 3},
		{"who": "crow", "id": "crow", "tile": Vector2i(19, 2), "dir": 3, "silent": true},
	]
	if Game.flag("wick_sword") and not Game.flag("has_sword"):
		npcs.append({"who": "wick_sword", "id": "wick", "tile": Vector2i(2, 8), "dir": 2, "pose": "sit", "mood": "omen"})
	elif not Game.flag("wick_gone"):
		npcs.append({"who": "wick", "tile": Vector2i(12, 4), "dir": 0, "wander": true, "range": 2.0})
	return {
		"id": "rookery" + ("_n" if night else "_d"), "name": "The Rookery", "theme": "ruin", "music": "camp", "tint": NIGHT if night else Color.WHITE,
		"rows": [
			"######################",
			"######W#######W#######",
			"#::::::::::::::::::::#",
			"#::::::::::::::::::xx#",
			"#::,,,,,,::::::::xxx:#",
			"#::,,,,,,::::::::::::#",
			"#::::::::::::::::::::#",
			"#::::::::::::::::::::#",
			"#::::::::::::::::::::#",
			"#::::::::::::::::::::#",
			"##########::##########",
			"##########::##########",
			"ssssssssss==ssssssssss",
		],
		"props": [
			{"kind": "table", "tile": Vector2i(5, 5), "v": 1, "area": Rect2i(4, 5, 2, 1), "event": {"id": "haul"}},
			{"kind": "campfire", "tile": Vector2i(10, 7), "anim": 3, "fps": 7.0, "light": Pal.CANDLE, "lr": 46, "pulse": 5.0, "light_off": Vector2(0, -8)},
			{"kind": "bedroll", "tile": Vector2i(3, 8), "v": 0, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(16, 8), "v": 1, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(13, 9), "v": 2, "decal": true},
			{"kind": "stairs", "tile": Vector2i(18, 3), "area": Rect2i(17, 3, 3, 1), "event": {"id": "stairs"}},
			{"kind": "handcart", "tile": Vector2i(17, 8), "area": Rect2i(16, 8, 2, 1)},
			{"kind": "crate", "tile": Vector2i(1, 2), "v": 1},
			{"kind": "barrel", "tile": Vector2i(2, 2)},
			{"kind": "rack", "tile": Vector2i(11, 2), "event": {"id": "rack", "text": "Fen's rack of borrowed spears. He says 'borrowed'. Nobody has ever returned one."}},
			{"kind": "banner", "tile": Vector2i(4, 1), "v": 2, "wall": true},
			{"kind": "rubble", "tile": Vector2i(19, 9), "v": 1},
		],
		"npcs": npcs,
		"events": [{"tile": Vector2i(10, 10), "id": "gate", "text": "The tower gate. Bracken wedged a cart axle across it. It would stop a stiff breeze. Probably."}],
		"exits": [],
	}


func scene_s4() -> Variant:
	scene = "S4"
	Game.set_flag("fen_fights")
	s.music("camp")
	var c := await s.cine("rookery")
	c.animate_bg("rookery", 4, 2.0)
	c.effect = "embers"
	c.effect_k = 0.3
	var fen := c.person("fen", Vector2(110, 160), 2, "grin", "sit")
	var br := c.person("bracken", Vector2(170, 160), 3, "laugh")
	var rk := c.person("rook", Vector2(220, 162), 3, "grin")
	rk.set_spec(s.rook_spec())
	if not Game.flag("wick_sword"):
		c.person("wick", Vector2(140, 150), 0, "grin")
	await s.narrate("The Rookery: a broken watchtower on the edge of the badlands, which the crew has called home for three winters.")
	s.sfx("crowd", 1.0, -10.0)
	for i in 3:
		br.hop(6.0)
		await s.wait(0.32)
	await s.say("bracken", "WE ROBBED THE FACTOR! Nobody robs the Factor!", "laugh")
	fen.gesture("laugh", 1.2)
	await s.say("fen", "Nobody's ever tried, you great lump. That's not the same thing.", "laugh")
	rk.gesture("bow", 1.2)
	await s.say("rook", "The Rook of the Saltway thanks his public.", "grin")
	await c.close(0.6)
	await s.explore(rookery_map(), Vector2i(11, 8), 1)
	s.lock(true)
	if Game.flag("wick_sword") and not Game.flag("has_sword"):
		await _s4_wick()
	await _s4_haul()
	s.lock(false)
	s.marker(Vector2i(18, 4))
	await s.until(func() -> bool: return Game.flag("carved_done"))
	await _s4_mara()
	return "S5"


func _s4_wick() -> void:
	var wick := s.a("wick")
	await s.walk("player", [Vector2i(4, 8)], 50.0)
	s.face("player", 3)
	await s.think("Wick hasn't let go of it since the camp. Not to eat. Not to sleep. He's whispering to it.")
	wick.tremble(0.8)
	await s.say("wick", "It shows me things, Rook. Where Bracken's going to step. When Fen's going to cough. It's never wrong.", "omen")
	await s.say("wick", "It says you want it. It says you'll take it.", "scared")
	var r := await s.choose("Wick is holding the blade like a drowning man holds a rope.", ["Take it from him.", "Talk him down."])
	if r == 0:
		Game.choose("Took the blade from Wick by force.")
		Game.add("suspicion", 1)
		Game.set_flag("wick_hurt")
		await s.a("player").lunge(8.0)
		s.sfx("clash", 1.0, -4.0)
		s.shake(1.5, 0.3)
		wick.set_pose("lie")
		wick.set_spec(Data.spec("wick"))
		wick.set_mood("cry")
		await s.say("wick", "Ow! Rook- I wasn't- I wasn't going to...", "cry")
		await s.think("His hand closed on the hilt before he'd decided to reach. That's new.")
	else:
		Game.choose("Talked Wick into handing over the blade.")
		Game.add("loyalty", 1)
		s.a("player").set_pose("kneel")
		await s.say("rook", "Wick. Look at me, not it. It's heavy, isn't it? Heavier every hour.", "worried")
		wick.set_mood("cry")
		await s.say("wick", "...So heavy.", "cry")
		await s.say("rook", "Then give it here. I'm the one who wants a name. Let it bother me instead.", "smile")
		s.sfx("sword_draw", 0.8, -8.0)
		wick.set_spec(Data.spec("wick"))
		wick.set_mood("sad")
		await s.say("wick", "Sorry. I'm sorry. I don't know why I grabbed it.", "sad")
		s.a("player").set_pose("walk")
	Game.set_flag("has_sword")
	Game.add("reliance", 1, true)
	s.a("player").set_spec(s.rook_spec())
	s.omen_pulse()
	await s.say("blade", "There you are.")
	wick.set_pose("walk")
	wick.info["wander"] = true


func _s4_haul() -> void:
	await s.walk("player", [Vector2i(6, 6)], 50.0)
	s.face("player", 1)
	s.face_to("fen", "player")
	var items: Array = Game.run.items
	if items.is_empty():
		await s.say("fen", "Not much of a haul. One wagon, one book, one sword nobody can sell.", "")
	else:
		await s.say("fen", "Let's see what the Rook of the Saltway brought home.", "smile")
		for id in items:
			if id != "ledger":
				await s.say("fen", "%s. %s" % [Data.item(id).name, ["Nice.", "Dosha'll take that.", "Fancy.", "Huh."][items.find(id) % 4]], "")
	if Game.has_item("ledger"):
		s.a("fen").set_mood("worried")
		await s.say("fen", "And that book. That's not a merchant's ledger, Rook. Merchants count goods. That book counts people.", "worried")
	await s.say("fen", "We take the haul to Dosha in Kesh Crossing at first light. Sell it across the border before anyone looks for it.", "")
	if Game.flag("has_sword"):
		s.a("fen").gesture("point", 1.0)
		await s.say("fen", "The sword stays wrapped. You hear me? Wrapped, and quiet, and out of sight.", "angry")
	await s.say("", "Talk to the crew if you like. When you're ready, the stairs lead to the top of the tower.", "", {"color": Pal.CANDLE.lerp(Pal.WHITE, 0.4)})


func _s4_carve() -> void:
	s.unmarker()
	var c := await s.cine("rookery_top", 0.6)
	c.animate_bg("rookery_top", 4, 1.5)
	c.effect = "stars"
	c.effect_k = 0.2
	s.music("omen", 1.0)
	# on the flagstones with his back to the parapet; the crow on a merlon
	var rk := c.person("rook", Vector2(190, 156), 3, "", "sit")
	rk.set_spec(s.rook_spec())
	var crow := c.person("crow", Vector2(233, 97), 3)
	await s.narrate("The top of the tower. The whole badlands silver under the moon. Rook sits with the blade across his knees and doesn't sleep.")
	s.sfx("whisper", 0.7, -4.0)
	await s.say("blade", "You wanted a name.")
	rk.set_mood("shock")
	await s.say("rook", "...So you do talk.", "shock")
	await s.say("blade", "I listen. Mostly. You told the old man you wanted a name that outlives you. I can give you that.")
	await s.say("blade", "Carve it into me. I have outlived everyone who ever held me. I will outlive you too, and I will carry your name.")
	var r := await s.choose("The knife is already in his hand.", ["Carve ROOK into the guard.", "Carve a crow. Let them guess.", "Leave it unmarked."])
	match r:
		0:
			Game.run.mark = "name"
			Game.set_pflag("signed")
			Game.add("suspicion", 1)
			Game.choose("Carved his name into the blade.")
			rk.set_pose("pick")
			for k in 4:
				s.sfx("carve", 1.0 + k * 0.1, -6.0)
				rk.shake(0.15)
				await s.wait(0.3)
			s.flash(Pal.OMEN, 0.3)
			await s.say("blade", "ROOK. There. Now we are introduced.")
			await s.think("His name in the steel. Just four letters. They look like they've always been there.")
		1:
			Game.run.mark = "crow"
			Game.choose("Carved a crow into the blade instead of his name.")
			rk.set_pose("pick")
			for k in 3:
				s.sfx("carve", 1.2 + k * 0.1, -6.0)
				await s.wait(0.3)
			crow.emote("?")
			s.sfx("caw", 1.0, -6.0)
			await s.say("blade", "A bird. How shy. They'll know it's you. They always know.")
		2:
			Game.run.mark = ""
			Game.add("refusals", 1)
			Game.choose("Refused to put his name on the blade.")
			rk.set_mood("determined")
			await s.say("rook", "No. If you want my name, you'll have to earn it like everyone else. By hearing it in a song.", "determined")
			await s.say("blade", "...Everyone says that, the first night.")
	rk.set_spec(s.rook_spec())
	rk.set_mood("")
	rk.set_pose("sit")
	s.sfx("caw", 1.0, -6.0)
	crow.face(2)
	crow.set_pose("fly")
	c.walk(crow, Vector2(360, 10), 150.0)
	await s.wait(0.5)
	await s.narrate("On the parapet, the crow takes off, all at once, into the dark.")
	await c.close(0.6)
	s.a("player").set_spec(s.rook_spec())
	Game.set_flag("carved_done")


func _s4_mara() -> void:
	s.lock(true)
	s.music("tension", 1.0)
	s.sfx("caw", 1.2, -4.0)
	await s.wait(0.3)
	s.sfx("knock", 1.0, -2.0)
	for id in ["fen", "bracken"]:
		s.a(id).emote("!")
	if s.a("wick"):
		s.a("wick").emote("!")
	await s.say("bracken", "Someone at the gate.", "angry")
	s.a("bracken").gesture("ready", 1.5)
	await s.walk("player", [Vector2i(11, 8)], 60.0)
	var mara := s.spawn("mara", Vector2i(10, 12), 1)
	await s.walk("mara", [Vector2i(10, 10), Vector2i(10, 9)], 40.0)
	s.face("player", 3)
	s.face_to("mara", "player")
	Game.set_flag("met_mara")
	if Game.v("mara") >= 2:
		mara.set_mood("")
		await s.say("mara", "Hello, wheelwright.", "")
		await s.say("rook", "...Very good scout.", "smile")
		await s.say("mara", "The Factor dismissed me this morning. He said a thief walked through my camp and I didn't see him. He was right.", "sad")
		mara.gesture("cross", 1.4)
		await s.say("mara", "I don't want my job back. I want to know what was in that box. What I was guarding all the way from the salt flats.", "determined")
		var r := await s.choose("Mara stands at the gate, bow unstrung.", ["\"Join us.\"", "\"Go home, scout.\""])
		if r == 0:
			Game.add("loyalty", 1)
			Game.add("mara", 1)
			Game.choose("Invited Mara into the crew.")
			mara.gesture("laugh", 1.0)
			await s.say("mara", "Join a gang of thieves. My sister will love that.", "smile")
		else:
			Game.add("mara", -1)
			Game.choose("Told Mara to go home.")
			await s.say("mara", "I'll follow either way. I'd rather do it from inside the walls than outside them.", "")
	else:
		mara.set_pose("aim")
		await s.say("mara", "Blue coat. I followed your tracks for twenty miles.", "angry")
		await s.say("mara", "The Factor dismissed me for letting you walk through my camp. Give me back what you took. And whatever was in that box.", "angry")
		Game.set_flag("fen_fights")
		var res := await s.battle(_gate_battle())
		if res.outcome == "objective":
			Game.set_pflag("talked_down")
			Game.run.vars.mara = 1
			Game.choose("Talked Mara down at the gate.")
			await s.say("mara", "...Fine. I'm listening. I'm still angry, but I'm listening.", "")
		else:
			Game.run.vars.mara = -1
			Game.choose("Beat Mara at the gate.")
			mara.set_pose("kneel")
			await s.say("mara", "Fine. FINE. You win. I go where the box goes, thief, so get used to me.", "angry")
			mara.set_pose("walk")
	Game.set_flag("mara_joined")
	mara.set_pose("walk")
	await s.say("fen", "Well. Seems we're five.", "")
	await s.narrate("They sleep, eventually. Rook doesn't. Every time he closes his eyes, he sees the next few seconds before they happen.")


func _gate_battle() -> Dictionary:
	var carrying: bool = Game.run.items.filter(func(x): return x != "ledger").size() > 0
	return {
		"id": "s4_gate", "title": "Mara at the gate!", "bg": "rookery", "music": "tension",
		"party": ["rook", "fen"],
		"enemies": [BattleDefs.enemy("mara", {"pos": Vector2(80, 126), "hp": 96, "def": 4})],
		"objective": {"kind": "persuade", "need": 3, "who": "mara", "text": "TALK HER DOWN", "win_title": "SHE LOWERS THE BOW",
			"note": "Nobody had to bleed for it.", "talk_desc": "Words, instead of knives."},
		"no_hostile": true, "no_steal": false,
		"talk": [
			{"id": "dismissed", "label": "They threw you out.", "text": "\"The Factor threw you out, didn't he? For what we did.\"", "good": true,
				"reply": [["mara", "...Yes. Like I was the thief.", "sad"]]},
			{"id": "box", "label": "It isn't spice.", "text": "\"Whatever's in that box, it isn't spice. You know it isn't.\"", "good": true,
				"reply": [["mara", "I've guarded spice. Spice doesn't hum at night.", "worried"]]},
			{"id": "return", "label": "I'll give it back.", "text": "\"I'll give back what I took. To Ollo. You can watch me do it.\"", "good": true, "need": func() -> bool: return carrying,
				"reply": [["mara", "...You'd do that?", "shock"], ["rook", "If you'll stop pointing that at my face.", "smile"]]},
			{"id": "join", "label": "Come with us.", "text": "\"You're the best shot on the Saltway. Come and find out with us.\"", "good": true, "worth": 1, "need": func() -> bool: return Game.v("loyalty") >= 3,
				"reply": [["mara", "Flattery. From a thief.", "smirk"]]},
			{"id": "threat", "label": "Walk away.", "text": "\"Walk away, scout. While you can.\"", "good": false,
				"reply": [["mara", "Try me.", "angry"]]},
			{"id": "joke", "label": "Is it about the coat?", "text": "\"Is this about the coat? It's a very nice coat.\"", "good": false,
				"reply": [["mara", "It's about the HAND in my CARAVAN.", "angry"]]},
		],
	}


func _s4_talk(n: Actor) -> void:
	match n.info.get("who", ""):
		"fen":
			var k := Game.bump_talk("fen_s4")
			if k == 1:
				await s.say("fen", "Want to know how I got this knee?", "")
				await s.say("fen", "Stopped a cart wheel with it. The cart belonged to a man who wanted to be a legend. He was going too fast to see me.", "")
				n.set_mood("grin")
				await s.say("fen", "He's a legend now, all right. They tell his story in Varn. On the gallows steps.", "grin")
			else:
				await s.say("fen", "Get some sleep. Or at least lie down near some.", "smile")
		"bracken":
			var k := Game.bump_talk("bracken_s4")
			if k == 1:
				await s.say("bracken", "My share's going in the goat jar. Ten more jobs and I'll have a farm. Twelve, if the goats are fancy.", "smile")
			else:
				n.gesture("laugh", 1.0)
				await s.say("bracken", "We robbed the FACTOR!", "laugh")
		"wick":
			var k := Game.bump_talk("wick_s4")
			if Game.flag("wick_hurt"):
				n.face(3)
				await s.say("wick", "...My arm's fine. You don't have to keep looking at it.", "sad")
			elif k == 1:
				await s.say("wick", "If you carve your name on that sword, can I carve mine on my sling? WICK. Four letters. Same as ROOK.", "grin")
			else:
				await s.say("wick", "Teach me the bow tomorrow. The real one.", "smile")
		"crow":
			await s.think("The crow. It followed them all the way from the Dry Well.")
		_:
			await s.say("", "...")


# ======================================================================
# S5 KESH CROSSING
# ======================================================================

func kesh_map() -> Dictionary:
	var npcs := [
		{"who": "dosha", "tile": Vector2i(5, 3), "dir": 0},
		{"who": "priest", "tile": Vector2i(27, 3), "dir": 0},
		{"who": "ollo", "tile": Vector2i(23, 9), "dir": 2},
		{"who": "townsman", "id": "magistrate", "tile": Vector2i(24, 9), "dir": 3, "silent": true},
		{"who": "pilgrim", "id": "ysa", "tile": Vector2i(29, 13), "dir": 3, "pose": "sit"},
		{"who": "pilgrim_kid", "id": "tam", "tile": Vector2i(28, 14), "dir": 1, "wander": true, "range": 1.5},
		{"who": "fen", "tile": Vector2i(14, 3), "dir": 0},
		{"who": "bracken", "tile": Vector2i(16, 3), "dir": 0},
		{"who": "hunter", "id": "h1", "tile": Vector2i(31, 6), "dir": 3},
		{"who": "townswoman", "id": "tw1", "tile": Vector2i(10, 11), "dir": 0, "wander": true},
		{"who": "townsman", "id": "tm1", "tile": Vector2i(20, 14), "dir": 1, "wander": true},
		{"who": "townswoman", "id": "tw2", "tile": Vector2i(7, 14), "dir": 2, "wander": true},
	]
	if Game.flag("mara_joined") and not Game.flag("mara_left"):
		npcs.append({"who": "mara", "tile": Vector2i(17, 11), "dir": 0})
	if not Game.flag("wick_gone"):
		npcs.append({"who": "wick", "tile": Vector2i(12, 7), "dir": 0, "wander": true})
	return {
		"id": "kesh", "name": "Kesh Crossing", "theme": "town", "music": "town",
		"rows": [
			"####################################",
			"#####D#########D###W#######D########",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"::::::::::::::::::::::::::::::::::::",
			"####################################",
		],
		"props": [
			{"kind": "stall", "tile": Vector2i(5, 4), "v": 2, "area": Rect2i(4, 4, 3, 1), "event": {"id": "dosha"}},
			{"kind": "stall", "tile": Vector2i(9, 5), "v": 0, "area": Rect2i(8, 5, 3, 1), "event": {"id": "stall", "text": "Oranges from the coast, three days old. The stallholder swears they're one."}},
			{"kind": "stall", "tile": Vector2i(21, 5), "v": 1, "area": Rect2i(20, 5, 3, 1), "event": {"id": "stall", "text": "Brass pots, brass lamps, brass bells. A brass hand, fingers closed. Rook looks away from that one quickly."}},
			{"kind": "stall", "tile": Vector2i(10, 12), "v": 3, "area": Rect2i(9, 12, 3, 1), "event": {"id": "stall", "text": "Herbs and simples. The stallholder is asleep. Rook is a professional. He leaves her alone."}},
			{"kind": "well", "tile": Vector2i(18, 9), "area": Rect2i(17, 9, 2, 1), "event": {"id": "well", "text": "The town well. Coins glint at the bottom. Wishes. Some thief's retirement fund."}},
			{"kind": "poster", "tile": Vector2i(11, 1), "v": 0, "wall": true, "event": {"id": "poster"}},
			{"kind": "poster", "tile": Vector2i(22, 1), "v": 1, "wall": true, "event": {"id": "notice", "text": "BY ORDER OF THE BORDER: caravans crossing to the north kingdoms must show a merchant's seal. No seal, no crossing."}},
			{"kind": "lamp_post", "tile": Vector2i(13, 8)},
			{"kind": "lamp_post", "tile": Vector2i(26, 11)},
			{"kind": "banner", "tile": Vector2i(32, 1), "v": 0, "wall": true},
			{"kind": "banner", "tile": Vector2i(2, 1), "v": 1, "wall": true},
			{"kind": "crate", "tile": Vector2i(33, 4), "v": 0},
			{"kind": "barrel", "tile": Vector2i(34, 4)},
			{"kind": "pot", "tile": Vector2i(30, 2), "v": 0},
			{"kind": "pot", "tile": Vector2i(31, 2), "v": 1},
			{"kind": "sacks", "tile": Vector2i(2, 12), "v": 1},
		],
		"npcs": npcs,
		"events": [
			{"tile": Vector2i(15, 1), "id": "inn", "text": "The Brass Kettle. The crew's lodging tonight. Fen paid in advance, which tells you how much he trusts the crew."},
			{"tile": Vector2i(27, 1), "id": "temple", "text": "The road-temple. Pilgrims leave their shoes on the step. Rook does not look at the shoes."},
		],
		"triggers": [{"id": "gate", "rect": Rect2i(34, 7, 2, 4)}],
		"exits": [],
	}


func scene_s5() -> Variant:
	scene = "S5"
	var c := await s.cine("town", 0.6)
	c.animate_bg("town", 2, 1.0)
	s.music("town")
	s.sfx("crowd", 1.0, -10.0)
	await s.narrate("Kesh Crossing: the last town before the border. Everyone here is coming from somewhere worse or going somewhere better, and everyone is selling something on the way.")
	await c.close(0.5)
	await s.explore(kesh_map(), Vector2i(1, 9), 2)
	await s.say("fen", "Sell what you're selling at Dosha's. Keep your hood up and your sword wrapped. We leave by the east gate before dark.", "")
	await s.say("", "Explore Kesh Crossing. Dosha the fence is at the purple stall. The east gate leads on.", "", {"color": Pal.CANDLE.lerp(Pal.WHITE, 0.4)})
	await s.until(func() -> bool: return Game.flag("s5_leave"))
	await _s5_factor()
	return "S6"


func _s5_dosha() -> void:
	s.face_to("dosha", "player")
	if not Game.flag("met_dosha"):
		Game.set_flag("met_dosha")
		await s.say("dosha", "Fen's boy. The one who talks. I heard you robbed the Factor.", "smirk")
		await s.say("rook", "Heard from who?", "shock")
		await s.say("dosha", "Everybody, darling. There's a poster.", "laugh")
	while true:
		var opts := ["Sell", "Buy supplies", "Ask about the map on the wall", "Leave"]
		var r := await s.choose("Dosha's stall. Other people's things, neatly priced. You have %d coin." % Game.v("coin"), opts, "dosha")
		match r:
			0:
				await _dosha_sell()
			1:
				await _dosha_buy()
			2:
				await _dosha_map()
			_:
				await s.say("dosha", "Come back when you've stolen something interesting.", "smile")
				return


func _dosha_sell() -> void:
	var sellable: Array = Game.run.items.filter(func(x): return int(Data.item(x).get("value", 0)) > 0 and x != "ledger")
	if Game.has_item("ledger"):
		await s.say("dosha", "And put that cream book away. I don't touch the Factor's ledgers. Nobody does. Not even me.", "worried")
	if sellable.is_empty():
		await s.say("dosha", "Nothing I want, darling.", "")
		return
	var opts := sellable.map(func(x): return "%s  (%d)" % [Data.item(x).name, int(Data.item(x).value)])
	opts.append("Never mind")
	var r := await s.choose("Sell what?", opts, "dosha")
	if r >= sellable.size():
		return
	var id: String = sellable[r]
	var got := Game.sell_item(id)
	s.sfx("coins", 1.0, -4.0)
	Game.choose("Sold %s to Dosha." % Data.item(id).name)
	await s.say("dosha", "%d coin. Pleasure doing crimes with you." % got, "smile")
	if id == "icon":
		await s.think("A painted saint, worn smooth by a family's hands. Dosha drops it into a bucket of other saints.")


func _dosha_buy() -> void:
	var stock := [["salve", 15], ["smoke", 12], ["tonic", 10], ["sand", 8], ["bread", 4]]
	var opts := stock.map(func(x): return "%s  (%d)" % [Data.SUPPLIES[x[0]].name, x[1]])
	opts.append("Never mind")
	var r := await s.choose("Buy what? (%d coin)" % Game.v("coin"), opts, "dosha")
	if r >= stock.size():
		return
	if Game.v("coin") < int(stock[r][1]):
		await s.say("dosha", "That's not enough coin, darling. That's not even enough to be rude about.", "smirk")
		return
	Game.add("coin", -int(stock[r][1]), true)
	Game.add_supply(stock[r][0], 1)
	s.sfx("coin", 1.0, -6.0)
	await s.say("dosha", "Enjoy. No refunds. No questions.", "smile")


func _dosha_map() -> void:
	if Game.has_item("map"):
		await s.say("dosha", "You've got the map, darling. I don't have another one. I barely had that one.", "")
		return
	await s.say("dosha", "That? Half a map of the Pass of Teeth. Some old fool drew a door on it where there's only rock. Forty coin.", "")
	var r := await s.choose("The map scrap. A door, drawn where there's only rock.", [
		{"text": "Pay forty coin.", "need": Game.v("coin") >= 40},
		"Lift it while she's talking.", "Leave it."])
	match r:
		0:
			Game.add("coin", -40, true)
			s.sfx("coins", 1.0, -4.0)
			Game.give_item("map")
			Game.add_clue("map")
			await s.say("dosha", "Sold, to the man who likes doors.", "smile")
		1:
			var res := await s.minigame("pickpocket", {"mark": "dosha", "item": "The map scrap", "skill": Game.v("finesse") / 10.0 + 0.2, "bg": "town", "keep_music": true})
			if res.get("success", false):
				Game.give_item("map")
				Game.add_clue("map")
				Game.add("finesse", 1)
				Game.add("suspicion", 1, true)
				await s.say("dosha", "...and that's why the Brass Kettle waters its wine. Darling? Where did my map go?", "shock")
			else:
				await s.say("dosha", "Fingers. I can see your fingers. Sixty coin now, for the insult.", "angry")
		_:
			pass


func _s5_examine(ev: Dictionary) -> void:
	match ev.get("id", ""):
		"dosha":
			await _s5_dosha()
		"poster":
			if Game.flag("poster_done"):
				await s.think("The wall where the poster was.")
				return
			s.music("tension", 0.6)
			await s.narrate("A wanted poster. THE CARAVAN THIEF. FIFTY CROWNS, BY ORDER OF THE FACTOR. The drawing has a very large nose.")
			s.a("player").emote("!")
			await s.think("Fifty crowns. Fifty! Somebody drew him. Somebody's going to tell this story in Varn.")
			s.music("town", 0.6)
			var r := await s.choose("THE CARAVAN THIEF, it says. Him.", ["Tear it down before anyone looks too closely.", "Fold it up and keep it.", "Draw a better nose on it."])
			Game.set_flag("poster_done")
			match r:
				0:
					s.sfx("paper", 1.0, -4.0)
					Game.add("loyalty", 1, true)
					await s.think("He tears it into very small pieces. It feels like tearing up a letter addressed to him.")
				1:
					Game.give_item("poster")
					Game.set_pflag("poster")
					Game.add("suspicion", 1)
					Game.choose("Kept his own wanted poster.")
					await s.think("He folds it into his coat, over his heart. It's the first thing anyone's ever written about him.")
				2:
					s.sfx("carve", 1.4, -8.0)
					Game.add("finesse", 1)
					await s.think("A much more handsome nose. Also a little crown. It's important to be accurate.")
		_:
			await super.examine(ev)


func _s5_talk(n: Actor) -> void:
	match n.info.get("who", ""):
		"dosha":
			await _s5_dosha()
		"ollo":
			await _s5_ollo()
		"pilgrim":
			await _s5_ysa()
		"pilgrim_kid":
			await s.say("pilgrim_kid", "Mama says the saint will find us again. Saints are good at finding.", "smile" if not Game.has_item("icon") else "sad")
		"priest":
			await _s5_amsel()
		"hunter":
			await _s5_hunter()
		"mara":
			var k := Game.bump_talk("mara_s5")
			if k == 1:
				await s.say("mara", "Everyone in this town is selling something. I keep checking my pockets.", "")
				if Game.has_item("silk") or Game.has_item("saffron") or Game.has_item("seal_ring"):
					n.gesture("point", 1.0)
					await s.say("mara", "Ollo's over there, shouting at a magistrate. About his seal-ring. About his saffron. You could just... give them back.", "")
			else:
				await s.say("mara", "There are two hunters by the east gate pretending to buy figs. Nobody looks at figs that hard.", "worried")
		"fen":
			await s.say("fen", "Dosha first. Then we're gone. Kesh has a long memory and short gallows.", "")
		"bracken":
			await s.say("bracken", "They have a goat here with a hat on. I'm not saying anything. I'm just saying.", "smile")
		"wick":
			await s.say("wick", "Rook! There's a poster of you! You're FAMOUS!", "grin")
		"townsman", "townswoman":
			var lines := ["Caravan got robbed out by the Dry Well. They say the thief walked through walls.", "The Factor's men are everywhere. Polite as priests. Gives me the creeps.",
				"Border's closing to anyone without a merchant's seal. Bad week for honest folk.", "Did you hear? Fifty crowns for the Caravan Thief. I'd turn in my own brother for fifty."]
			await s.say(n.info.get("who", ""), lines[randi() % lines.size()], "")
		_:
			await s.say("", "...")


func _s5_ollo() -> void:
	var mine: Array = Game.run.items.filter(func(x): return Data.item(x).get("owner", "") == "ollo")
	if mine.is_empty():
		if Game.fval("s1", "") == "help":
			await s.say("ollo", "The wheelwright! Some thief took my stores at the Dry Well. Not you, obviously. You help with wheels.", "worried")
		else:
			await s.say("ollo", "Robbed! Robbed twice in one week! The magistrate says 'paperwork'. I say 'justice'.", "angry")
		return
	await s.say("ollo", "...and without my seal I can't cross! Twelve wagons rotting at the border because some THIEF-", "angry")
	var opts := ["Slip something back onto his cart when he isn't looking.", "Hand it to him. To his face.", "Walk away."]
	var r := await s.choose("Ollo's things are in your pack: " + ", ".join(mine.map(func(x): return Data.item(x).name)) + ".", opts)
	if r == 2:
		return
	var ids := mine.duplicate()
	if ids.size() > 1:
		var pick := ids.map(func(x): return Data.item(x).name)
		pick.append("All of it.")
		var p := await s.choose("Give back what?", pick)
		if p < ids.size():
			ids = [ids[p]]
	for id in ids:
		Game.return_item(id)
	Game.add("loyalty", 1)
	Game.add("suspicion", -1)
	Game.choose("Gave back %s to Ollo." % ", ".join(ids.map(func(x): return Data.item(x).name)))
	if r == 0:
		s.a("player").set_pose("sneak")
		await s.wait(0.6)
		s.a("player").set_pose("walk")
		s.sfx("coin", 0.8, -6.0)
		await s.narrate("A quick hand, a quiet drop. A minute later Ollo finds it and shrieks with joy and accuses the magistrate of having had it all along.")
		s.a("ollo").hop(6.0)
		s.a("ollo").emote("heart")
		if Game.flag("mara_joined"):
			Game.add("mara", 1)
	else:
		var o := s.a("ollo")
		o.jump_back()
		o.emote("!!")
		await s.say("rook", "These are yours. I took them. I'm giving them back. Please don't scream.", "worried")
		await s.say("ollo", "...", "shock")
		await s.say("ollo", "I don't understand it. I don't understand you. Take... take ten coin, as a reward for being the strangest thief alive.", "shock")
		Game.add("coin", 10)
		if Game.flag("mara_joined"):
			Game.add("mara", 2)
			if s.a("mara"):
				s.a("mara").emote("heart")


func _s5_ysa() -> void:
	if Game.has_item("icon"):
		await s.say("ysa", "Someone took our saint at the Dry Well. Tam's grandmother carved it. It's worth nothing. It's worth everything.", "sad")
		var r := await s.choose("The wooden saint is in your pack.", ["Give it back.", "Say nothing."])
		if r == 0:
			Game.return_item("icon")
			Game.add("loyalty", 1)
			Game.choose("Gave the pilgrims back their saint.")
			s.a("player").set_pose("kneel")
			await s.say("rook", "Found it on the road. Looks like it was trying to find you.", "smile")
			var tam := s.a("tam")
			tam.info["wander"] = false
			await s.walk("tam", [s.w.tile_of(s.a("player").position) + Vector2i(1, 0)], 70.0)
			tam.hop(7.0)
			tam.emote("heart")
			s.sfx("jingle", 1.0, -4.0)
			await s.say("pilgrim_kid", "THE SAINT! Mama, the saint came BACK!", "grin")
			s.a("ysa").set_mood("cry")
			await s.say("ysa", "Thank you. Thank you. May the road be kind to you, sailor.", "cry")
			s.a("player").set_pose("walk")
			await s.think("He doesn't feel like a legend. He feels better than that, and he doesn't know what it's called.")
		return
	if Game.run.sold.has("icon"):
		await s.say("ysa", "Our saint was stolen at the Dry Well. Tam keeps praying it'll come back.", "sad")
		await s.think("It's in a bucket at Dosha's stall, with a dozen others.")
		return
	await s.say("ysa", "The sailor from the road! Tam talks about you every night. The man who lifted the wagon.", "smile" if Game.fval("s1", "") == "help" else "")


func _s5_amsel() -> void:
	if Game.run.lore.has("amsel"):
		await s.say("priest", "Walk carefully, son. The road remembers everything.", "")
		return
	await s.say("priest", "You carry something heavy under that coat. No, don't tell me. Let an old priest tell you a story instead.", "")
	await s.say("priest", "Pilgrims say there is a sword that walks the roads of the world. Never the same road twice. Never the same age.", "")
	await s.say("priest", "It goes looking for the hand that wants the most. Then it gives that hand exactly what it wants. Every last drop.", "")
	await s.say("priest", "Kings, soldiers, children, saints. The stories never end well, and they never end. Someone always picks it up.", "sad")
	Game.add_lore("amsel")
	await s.think("He's talking to the sword. Not to me. He's looking at my hip the whole time.")


func _s5_hunter() -> void:
	if Game.flag("alley_done"):
		await s.say("hunter", "...", "")
		return
	await s.say("hunter", "Bearer. A word. In the alley, if you please. We are asked to be discreet.", "")
	var r := await s.choose("The hunter waits, hook folded politely at his belt.", ["Follow him into the alley.", "Walk away."])
	if r != 0:
		return
	Game.set_flag("alley_done")
	await s.say("hunter", "The Factor asks that you return what is kept. Nobody else need be hurt.", "")
	await s.say("rook", "And if I don't?", "smirk")
	await s.say("hunter", "Then we are asked to be less discreet.", "")
	var res := await s.battle({
		"id": "s5_alley", "title": "The alley of hooks!", "bg": "alley", "music": "battle",
		"party": s.party(),
		"enemies": [BattleDefs.enemy("hunter"), BattleDefs.enemy("hunter", {"hp": 40, "spd": 12})],
		"objective": {"kind": "defeat", "text": "LOSE THEM"},
		"victory_note": "One of them drops a brass token in the dust: a closed hand, and an inscription.",
	})
	if res.outcome != "defeat":
		await s.think("A brass token. On one side, a closed hand. On the other: WHAT IS KEPT IS NEVER LOST.")
		Game.add_lore("factor_token")
	else:
		Game.set_flag("injured")
		await s.narrate("They leave him in the alley with a split lip and a polite reminder. They don't take the sword. They never take the sword.")
	s.w.remove_npc("h1")


func _s5_trigger(id: String) -> void:
	if id != "gate" or Game.flag("s5_leave"):
		return
	var r := await s.choose("Leave Kesh Crossing by the east gate?", ["Leave now.", "Not yet."])
	if r == 0:
		Game.set_flag("s5_leave")
	else:
		s.w.fired.erase("gate")
		await push_back(2)


func _s5_factor() -> void:
	# a crowd, and in it, a man in spotless cream buying an apple
	s.lock(true)
	s.music("omen", 1.0)
	var f := s.spawn("factor", Vector2i(28, 8), 3)
	await s.pan(Vector2i(28, 8), 0.8)
	s.sfx("coin", 1.0, -10.0)
	await s.narrate("By the gate, a tall man in cream buys an apple. He counts out the exact coin, one at a time, and thanks the woman, and means it.")
	f.face(3)
	await s.wait(0.6)
	await s.narrate("Then he looks up, across the whole crowded square, straight at Rook. And smiles. As if they were old friends.")
	f.gesture("wave", 1.2)
	s.omen_pulse()
	await s.say("blade", "He knows me. He kept me for a long time. Do not let him keep me again.")
	var cart := s.spawn("ox", Vector2i(22, 9), 2)
	await s.walk("ox", [Vector2i(33, 9)], 50.0)
	s.w.remove_npc("factor")
	await s.wait(0.2)
	await s.narrate("A cart rolls between them. When it's passed, he's gone. Only the apple core, set neatly on the edge of the well.")
	await s.pan_back(0.6)
	s.w.remove_npc("ox")
	await s.say("fen", "Out. All of you. Now.", "angry")


# ======================================================================
# S6 CAMPFIRE ACCUSATION
# ======================================================================

func hillcamp_map() -> Dictionary:
	var npcs := [
		{"who": "fen", "tile": Vector2i(5, 7), "dir": 0, "pose": "lie", "mood": "sleep"},
		{"who": "bracken", "tile": Vector2i(13, 9), "dir": 0, "pose": "lie", "mood": "sleep"},
	]
	if not Game.flag("wick_gone"):
		npcs.append({"who": "wick", "tile": Vector2i(7, 10), "dir": 0, "pose": "lie", "mood": "sleep"})
	if Game.flag("mara_joined"):
		npcs.append({"who": "mara", "tile": Vector2i(15, 5), "dir": 1})
	return {
		"id": "hillcamp", "name": "The Hill Road", "theme": "road", "music": "tension", "tint": NIGHT,
		"rows": [
			"######################",
			"######################",
			"rrrrrsssssssssssssrrrr",
			"rrrsssssssssssssssssrr",
			"rssssssssssssssssssssr",
			"ssssssssssssssssssssss",
			"ssssssssssssssssssssss",
			"ssssssssssssssssssssss",
			"ssssssssssssssssssssss",
			"ssssssssssssssssssssss",
			"ssssssssssssssssssssss",
			"rssssssssssssssssssssr",
			"rrrrrrrrrrrrrrrrrrrrrr",
		],
		"props": [
			{"kind": "campfire", "tile": Vector2i(10, 7), "anim": 3, "fps": 6.0, "light": Pal.CANDLE, "lr": 48, "pulse": 5.0, "light_off": Vector2(0, -8)},
			{"kind": "bedroll", "tile": Vector2i(5, 7), "v": 0, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(13, 9), "v": 3, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(7, 10), "v": 1, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(9, 5), "v": 2, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(17, 8), "v": 1, "decal": true},
			{"kind": "sacks", "tile": Vector2i(18, 8), "v": 0, "id": "mara_pack", "event": {"id": "mara_pack"}},
			{"kind": "boulder", "tile": Vector2i(2, 4), "v": 1},
			{"kind": "dead_tree", "tile": Vector2i(19, 4), "v": 1},
			{"kind": "bush", "tile": Vector2i(3, 11), "v": 0},
		],
		"npcs": npcs,
		"exits": [],
	}


func scene_s6() -> Variant:
	scene = "S6"
	await s.explore(hillcamp_map(), Vector2i(9, 5), 0)
	s.lock(true)
	var r := s.a("player")
	r.set_pose("lie")
	r.set_mood("closed")
	await s.wait(0.6)
	s.sfx("whisper", 0.8, -6.0)
	if not Game.flag("mara_joined"):
		await _s6_nomara()
		return "S7"
	await s.say("blade", "Wake up. Wake up and watch her.")
	# the vision
	var c := await s.cine("vision", 0.3)
	c.animate_bg("vision", 4, 5.0)
	s.sfx("vision", 0.9, -4.0)
	var rk := c.person("rook", Vector2(200, 158), 3, "sleep", "lie")
	rk.set_spec(s.rook_spec())
	var m := c.person("mara", Vector2(80, 156), 2, "omen")
	# she crosses while the line is read, rather than in silence before it
	var crossing := [true]
	var cross := func() -> void:
		await c.walk(m, Vector2(170, 156), 48.0)
		m.set_pose("reach")
		s.sfx("heartbeat", 1.0, -2.0)
		crossing[0] = false
	cross.call()
	await s.narrate("In the violet dark, Mara crosses the camp without a sound. She kneels beside him. Her hand closes on the hilt at his side.")
	while crossing[0]:
		await get_tree().process_frame
	await s.wait(0.4)
	await c.close(0.2)
	s.flash(Pal.OMEN, 0.3)
	# and he wakes, and she's there
	r.set_mood("shock")
	r.set_pose("walk")
	r.jump_back()
	var mara := s.a("mara")
	mara.position = s.w.tile_center(Vector2i(10, 5))
	mara.face(3)
	mara.set_pose("reach")
	await s.wait(0.4)
	mara.emote("!")
	mara.set_pose("walk")
	mara.face_toward(r.position)
	s.music("tension", 0.5)
	await s.think("She's right there. Her hand was right there. Exactly where the blade showed him.")
	var choice := await s.choose("Mara stands over his bedroll, one hand still half-reached toward his side.", [
		"Confront her.", "Say nothing. Wait until she sleeps, and search her things.", "Tell her what the blade showed you."])
	match choice:
		0:
			await _s6_confront()
		1:
			await _s6_search()
		2:
			await _s6_confess()
	return "S7"


func _s6_nomara() -> void:
	await s.say("blade", "They're all asleep. Any one of them could take me. Any one of them would.")
	s.a("player").set_pose("walk")
	s.a("player").set_mood("worried")
	await s.think("Fen. Bracken. Wick. He watches each of them breathe, one at a time, until the fire burns out.")
	Game.add("suspicion", 1)


func _s6_confront() -> void:
	Game.choose("Confronted Mara over what the blade showed him.")
	Game.add("mara", -1)
	Game.add("suspicion", 1)
	var r := s.a("player")
	await r.lunge(8.0)
	s.sfx("whiff", 1.0, -4.0)
	await s.say("rook", "Looking for something?", "angry")
	await s.say("mara", "Your waterskin. Mine's empty, and yours was lying in the dirt.", "angry")
	await _s6_throw_waterskin()
	await s.narrate("She throws it at him. It hits him in the chest. It is, in fact, his waterskin.")
	await s.say("mara", "What did you think I wanted? ...Oh. Oh, I see.", "sad")
	s.a("mara").face(1)
	await s.walk("mara", [Vector2i(15, 5)], 40.0)
	var fen := s.a("fen")
	fen.set_pose("sit")
	fen.set_mood("")
	await s.say("fen", "Children. Some of us are trying to die of old age.", "")
	fen.set_pose("lie")


func _s6_throw_waterskin() -> void:
	## Mara lobs Rook's waterskin into his chest; it drops at his feet.
	var mara := s.a("mara")
	var r := s.a("player")
	# a step back first, so the throw has room to arc
	if mara.position.distance_to(r.position) < 24.0:
		var back := create_tween()
		back.tween_property(mara, "position", r.position + (mara.position - r.position).normalized() * 26.0, 0.25)
		await back.finished
	mara.face_toward(r.position)
	mara.set_pose("throw")
	var skin := Sprite2D.new()
	skin.texture = Art.prop("waterskin")
	skin.position = mara.position + Vector2(0, -16)
	skin.z_index = 5
	s.w.ents.add_child(skin)
	var hit := r.position + Vector2(0, -14)
	var start := skin.position
	var fly := create_tween()
	fly.tween_method(func(k: float) -> void:
		skin.position = start.lerp(hit, k) + Vector2(0, -10.0 * sin(k * PI))
		skin.rotation = k * TAU * 0.75, 0.0, 1.0, 0.35)
	await fly.finished
	s.sfx("thud", 1.4, -6.0)
	r.shake(0.2)
	r.jump_back(4.0)
	var drop := create_tween()
	drop.tween_property(skin, "position", r.position + Vector2(-8, -3), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.parallel().tween_property(skin, "rotation", PI * 1.5, 0.25)
	await drop.finished
	mara.set_pose("walk")
	skin.z_index = 0


func _s6_search() -> void:
	Game.choose("Searched Mara's things while she slept.")
	Game.set_pflag("searched")
	Game.add("suspicion", 2)
	var r := s.a("player")
	r.set_pose("lie")
	r.set_mood("closed")
	await s.say("mara", "...Sorry. Couldn't find my waterskin. Go back to sleep.", "")
	await s.walk("mara", [Vector2i(16, 8)], 40.0)
	s.a("mara").set_pose("lie")
	s.a("mara").set_mood("sleep")
	await s.wait(0.6)
	await s.narrate("An hour later, the fire is embers, and everyone is breathing slow.")
	r.set_mood("")
	r.set_pose("sneak")
	await s.sneak("player", [Vector2i(13, 6), Vector2i(17, 7)])
	r.face(0)
	var res := await s.minigame("pickpocket", {"mark": "mara", "item": "Mara's pack", "skill": Game.v("finesse") / 10.0 + 0.25, "bg": "campfire", "keep_music": true,
		"title": "HER THINGS", "help": "Hold Z to ease the pack open. When she stirs (the eye fills red), stop. Three stirs and she wakes."})
	if res.get("success", false):
		Game.add("finesse", 1)
		Game.give_item("letter")
		await s.narrate("A letter to her sister in Velt, mostly about how badly she sleeps on the road. A brass token: her dismissal from the Factor's service. And caught in the clasp of her cloak, a single cream thread.")
		s.omen_pulse()
		await s.say("blade", "Cream. His colour. She's his. They're all his, in the end.")
		await s.think("A thread. It could be from anywhere. From the wagon. From the camp. From anywhere.")
		await s.think("...Or from him.")
		Game.add_lore("cream_thread")
		r.set_pose("lie")
	else:
		var m := s.a("mara")
		m.set_pose("walk")
		m.set_mood("angry")
		m.emote("!!")
		r.jump_back()
		await s.say("mara", "Get your hands OUT of my pack.", "angry")
		await s.say("rook", "Mara, I can explain-", "scared")
		await s.say("mara", "You can't. That's the thing. You actually can't.", "cry")
		Game.add("mara", -3)
		Game.set_flag("mara_left")
		Game.choose("Mara caught him searching her pack, and left the crew.")
		m.set_pose("walk")
		await s.walk("mara", [Vector2i(21, 8)], 70.0)
		s.hide("mara")
		await s.say("fen", "...What did you do?", "worried")
		await s.think("The blade is warm against his side. Content.")


func _s6_confess() -> void:
	Game.choose("Confessed the blade's visions to Mara.")
	Game.set_flag("confessed")
	Game.set_pflag("confessed")
	Game.add("loyalty", 2)
	Game.add("mara", 2)
	Game.add("suspicion", -1)
	s.music("hope", 1.0)
	var r := s.a("player")
	r.set_pose("sit")
	s.a("mara").set_pose("sit")
	await s.say("rook", "Mara. The blade shows me things. What's about to happen. Where people are going to step.", "worried")
	await s.say("rook", "Tonight it showed me you. Reaching for it. While I slept.", "sad")
	await s.wait(0.4)
	await s.say("mara", "...I was reaching for your waterskin.", "")
	await s.say("rook", "I know. I know that now.", "sad")
	s.a("mara").shake_head()
	await s.say("mara", "It's lying to you. Or it's not lying, exactly. It's choosing what to show you.", "worried")
	await s.say("mara", "Then we watch it together. Both of us. Every night, if we have to. You don't carry that alone.", "smile")
	s.a("mara").emote("heart")
	s.sfx("whisper", 0.6, -10.0)
	await s.say("blade", "...She will take me from you. You know she will.")
	await s.think("For the first time, the blade sounds less sure of itself.")


# ======================================================================
# S7 THE SHRINE OF THE UNNAMED
# ======================================================================

func shrine_map() -> Dictionary:
	var npcs := [
		{"who": "fen", "tile": Vector2i(11, 10), "dir": 1},
		{"who": "bracken", "tile": Vector2i(14, 10), "dir": 1},
		{"who": "crow", "id": "crow", "tile": Vector2i(22, 4), "dir": 3, "silent": true},
	]
	if Game.flag("mara_joined") and not Game.flag("mara_left"):
		npcs.append({"who": "mara", "tile": Vector2i(9, 6), "dir": 1})
	if not Game.flag("wick_gone"):
		npcs.append({"who": "wick", "tile": Vector2i(16, 6), "dir": 1})
	return {
		"id": "shrine", "name": "The Shrine of the Unnamed", "theme": "ruin", "music": "omen", "tint": Color(1.0, 0.82, 0.74),
		"rows": [
			"##########################",
			"##########################",
			"rrrr::::::::::::::::::rrrr",
			"rrr::::::::::::::::::::rrr",
			"rr::::::::::::::::::::::rr",
			"rr::::::::::::::::::::::rr",
			"rrr::::::::::::::::::::rrr",
			"rrrrrrrrrr::::::rrrrrrrrrr",
			"ssrrrrrrrrr::::rrrrrrrrrss",
			"sssssrrrrrr::::rrrrrrsssss",
			"ssssssssss::::::ssssssssss",
			"ssssssssss::::::ssssssssss",
			"sssssssssss====sssssssssss",
		],
		"props": [
			{"kind": "statue", "tile": Vector2i(4, 2), "v": 0, "event": {"id": "statue"}},
			{"kind": "statue", "tile": Vector2i(8, 2), "v": 1, "event": {"id": "statue"}},
			{"kind": "statue", "tile": Vector2i(17, 2), "v": 2, "event": {"id": "statue2"}},
			{"kind": "statue", "tile": Vector2i(21, 2), "v": 0, "event": {"id": "statue"}},
			{"kind": "altar", "tile": Vector2i(13, 4), "area": Rect2i(12, 4, 2, 1), "id": "altar", "event": {"id": "altar"}},
			{"kind": "pillar", "tile": Vector2i(11, 2), "v": 0},
			{"kind": "pillar", "tile": Vector2i(14, 2), "v": 0},
			{"kind": "dead_tree", "tile": Vector2i(23, 6), "v": 0},
			{"kind": "rubble", "tile": Vector2i(3, 5), "v": 0},
			{"kind": "rubble", "tile": Vector2i(20, 6), "v": 1},
		],
		"npcs": npcs,
		"exits": [],
	}


func scene_s7() -> Variant:
	scene = "S7"
	await s.explore(shrine_map(), Vector2i(12, 11), 1)
	s.lock(true)
	await s.say("fen", "The high path. Longer, steeper, and nobody hunts it, because nobody's mad enough to take it.", "")
	await s.walk("player", [Vector2i(12, 8)], 50.0)
	await s.narrate("At the top: a terrace of old stone, and statues. Each one holds a sword, point down, both hands on the pommel. None of them has a face.")
	s.omen_pulse()
	await s.say("blade", "Oh. I remember this place.")
	s.lock(false)
	s.marker(Vector2i(13, 5))
	await s.until(func() -> bool: return Game.flag("read_altar"))
	await _s7_factor()
	return "S8"


func _s7_examine(ev: Dictionary) -> void:
	match ev.get("id", ""):
		"statue":
			await s.think("A bearer, cut in stone. The sword in its hands is the same sword at his hip, down to the grasping guard. The face has been worn away. Or chiselled.")
		"statue2":
			await s.think("This one's broken at the waist. Someone hit it, hard, a long time ago. The sword is gone from its hands.")
		"altar":
			s.unmarker()
			if not Game.flag("read_altar"):
				await s.narrate("The altar is carved with words, deep enough to survive centuries of wind:")
				await s.say("", "WHAT NO THIEF CAN REACH, NO THIEF CAN TAKE. THE DOOR IN THE TEETH OPENS ONLY FOR THE ONE WHO CLOSES IT.", "", {"box": "omen_box", "color": Pal.CREAM})
				Game.add_clue("inscription")
				Game.set_flag("read_altar")
				await s.think("The door in the Teeth. The Pass of Teeth. The door on the ledger page. The door on Dosha's map.")
				if Game.flag("has_sword") and not Game.flag("laid_sword"):
					var r := await s.choose("There's a long groove worn into the altar, the shape of a blade.", ["Lay the blade in the groove.", "Leave it at your side."])
					if r == 0:
						await _s7_memory()
		_:
			await super.examine(ev)


func _s7_memory() -> void:
	Game.set_flag("laid_sword")
	Game.set_pflag("memory")
	Game.add_lore("memory")
	var r := s.a("player")
	r.set_pose("kneel")
	s.sfx("sword_draw", 0.7, -6.0)
	s.w.add_light(s.w.tile_center(Vector2i(13, 4)) + Vector2(0, -8), 30, Pal.OMEN, 2.0)
	s.flash(Pal.OMEN, 0.5)
	var c := await s.cine("memory", 0.6)
	c.animate_bg("memory", 4, 3.0)
	c.effect = "omen"
	c.effect_k = 0.3
	s.music("omen", 1.0)
	var ghost := c.person("bearer", Vector2(160, 154), 0, "", "hold_up")
	await s.narrate("A battlefield, in some other age. Banners nobody remembers. And standing alone in the middle of it, a soldier with a sword Rook knows.")
	await s.say("bearer", "You're the new one, then. You have a thief's hands.", "")
	ghost.set_pose("walk")
	await s.say("bearer", "I wanted to never be beaten. That was all. Never to lose again. It gave me that. I won every fight I ever fought.", "")
	ghost.set_mood("sad")
	await s.say("bearer", "I won until there was nobody left to fight beside me. Then nobody left to fight. Then nobody.", "sad")
	await s.say("bearer", "It always gives you what you asked for. Ask carefully, thief.", "")
	ghost.fade(0.0, 1.2)
	await s.wait(1.2)
	await c.close(0.6)
	r.set_pose("walk")
	s.music("omen", 1.0)


func _s7_factor() -> void:
	s.lock(true)
	s.unmarker()
	s.sfx("caw", 1.0, -4.0)
	s.a("crow").emote("!")
	await s.wait(0.4)
	var f := s.spawn("factor", Vector2i(12, 12), 1)
	await s.walk("factor", [Vector2i(12, 9), Vector2i(12, 7)], 22.0)
	for id in ["bracken", "fen"]:
		var a := s.a(id)
		if a:
			a.face_toward(f.position)
			a.gesture("ready", 2.0)
	if s.a("mara"):
		s.a("mara").face_toward(f.position)
		s.a("mara").set_pose("aim")
	s.face_to("player", "factor")
	await s.say("factor", "Please. I'm not here to fight. I have never fought anyone in my life.", "smile")
	f.set_pose("sit")
	await s.narrate("He sits on the shrine steps, in his spotless robes, like a man who's walked a long way and finally found a bench.")
	await s.say("factor", "You may ask me three things. I've found that's usually enough, and never too many.", "")
	var asked := 0
	var done := false
	while asked < 3 and not done:
		var opts := [{"text": "\"What is it?\"", "need": not Game.run.lore.has("factor_what")},
			{"text": "\"What are you?\"", "need": not Game.run.lore.has("factor_who")},
			{"text": "\"What happens to the one who carries it?\"", "need": not Game.run.lore.has("factor_bearer")},
			{"text": "\"Where would it be safe?\"", "need": not Game.flag("asked_safe")},
			"Draw on him.", "\"We're done talking.\""]
		var r := await s.choose("The Factor waits, hands folded. (%d left)" % (3 - asked), opts)
		match r:
			0:
				Game.add_lore("factor_what")
				await s.say("factor", "A gift. A very generous one. It gives you what you most want, and it doesn't stop giving until there's nothing left of you to give to.", "")
				asked += 1
			1:
				Game.add_lore("factor_who")
				await s.say("factor", "A custodian. Once, a bearer, like you. I wanted to keep things. Coins. Houses. People.", "")
				await s.say("factor", "So it let me keep it. I've kept it for a very long time. I'm good at keeping.", "smile")
				asked += 1
			2:
				Game.add_lore("factor_bearer")
				await s.say("factor", "They become what they wanted to be. Exactly that. Only that. A legend is a very lonely shape to be.", "sad")
				asked += 1
			3:
				Game.set_flag("asked_safe")
				await s.say("factor", "Safe? From you, or from everyone else?", "")
				await s.say("factor", "There is a door in the Pass of Teeth that the blade cannot see past. But a door only stays closed if someone stays to close it.", "")
				if not Game.run.clues.has("ledger"):
					Game.add_clue("ledger")
				asked += 1
			4:
				Game.add("reliance", 1)
				Game.add("suspicion", 1)
				Game.choose("Drew the blade on the Factor at the shrine.")
				var rk := s.a("player")
				rk.set_pose("strike")
				rk.afterimage_field(Pal.OMEN)
				s.sfx("slash_heavy", 1.0, -2.0)
				s.flash(Pal.OMEN, 0.3)
				s.w.remove_npc("factor")
				await s.wait(0.6)
				rk.set_pose("walk")
				s.sfx("caw", 1.0, -4.0)
				await s.narrate("The blade cuts through the place he was sitting. Nobody is sitting there. The crow takes off from the step where he'd been.")
				await s.say("factor", "(from somewhere) You see? It always reaches first.", "")
				done = true
			_:
				done = true
	if s.a("factor"):
		f.set_pose("walk")
		await s.say("factor", "One more thing, free. Ask Old Fen what he'd pay to keep you all alive. He's been doing the sum all week.", "")
		await s.walk("factor", [Vector2i(12, 12)], 26.0)
		s.w.remove_npc("factor")
	if Game.lore_count() >= 3:
		Game.set_pflag("lore_all")
	await s.say("fen", "...We move. Now. And nobody asks me anything until we're home.", "worried")


# ======================================================================
# S8 FEN'S BARGAIN
# ======================================================================

func scene_s8() -> Variant:
	scene = "S8"
	var c := await s.cine("rookery", 0.6)
	c.animate_bg("rookery", 4, 2.0)
	s.music("tension", 1.0)
	await s.narrate("They reach the Rookery at midnight. The gate is open. Bracken's axle is lying in the dirt, cut clean through.")
	s.sfx("thud", 1.0, -4.0)
	await s.narrate("Nailed to the door with a brass hook: a note in beautiful handwriting. RETURN WHAT IS KEPT AT GORGE BRIDGE, MIDDAY. NO ONE ELSE NEED BE.")
	await c.close(0.5)
	await s.explore(rookery_map(true), Vector2i(10, 9), 1)
	s.lock(true)
	var fen := s.a("fen")
	fen.set_pose("walk")
	fen.position = s.w.tile_center(Vector2i(9, 6))
	s.face_to("fen", "player")
	await s.say("fen", "Sit down. All of you. I've been doing a sum all week, and I've finally got the answer.", "")
	await s.say("fen", "Five of us. One sword. One man in cream who walks through walls and never, ever stops.", "")
	fen.gesture("point", 1.2)
	await s.say("fen", "Tomorrow at Gorge Bridge, we give it back. We trade the sword for our lives, and we go home, and we never speak of it.", "determined")
	if Game.flag("mara_joined") and not Game.flag("mara_left"):
		await s.say("mara", "He's right, Rook.", "worried")
	s.omen_pulse()
	await s.say("blade", "He's been planning this since the wagon. He'll do it while you sleep. Ask him. Ask him what he's already promised them.")
	var opts := ["\"...You're right. We trade it.\"", "\"It's mine, Fen.\""]
	if Game.v("suspicion") >= 5:
		opts.append({"text": "Draw on Fen.", "tag": "Suspicion"})
	var r := await s.choose("The old man waits, leaning on his stick.", opts)
	match r:
		0:
			Game.choose("Agreed to trade the blade at Gorge Bridge.")
			Game.set_flag("trade_agreed")
			Game.add("fen", 2)
			Game.add("loyalty", 1)
			Game.add("refusals", 1)
			fen.set_mood("smile")
			await s.say("fen", "Good lad. Good lad. You'll see. Bread, roof, people who'd notice. That's the legend worth having.", "smile")
			s.sfx("whisper", 0.6, -4.0)
			await s.say("blade", "Liar. You'll never let me go. I've seen it.")
		1:
			Game.choose("Refused to trade the blade.")
			Game.set_flag("refused_trade")
			Game.add("fen", -2)
			Game.add("suspicion", 1)
			fen.set_mood("sad")
			await s.say("rook", "It's mine. I took it. I carried it. It's the only thing anyone's ever written my name next to.", "angry")
			await s.say("fen", "Then God help the lot of us. We go to the bridge anyway. That note wasn't a question.", "sad")
		2:
			await _s8_fen_fight()
	await _s8_night()
	return "S9"


func _s8_fen_fight() -> void:
	Game.choose("Drew the blade on Old Fen.")
	Game.add("fen", -3)
	Game.add("suspicion", 1)
	var r := s.a("player")
	r.set_pose("ready")
	s.sfx("sword_draw", 1.0, -2.0)
	var fen := s.a("fen")
	fen.jump_back()
	await s.say("fen", "Rook. Put it down, son. That's not you. That's it.", "scared")
	await s.say("rook", "You were going to take it. I SAW you.", "omen")
	var party := ["rook"]
	if Game.flag("mara_joined") and not Game.flag("mara_left") and Game.v("mara") >= 3:
		await s.say("mara", "Rook, stop!", "shock")
	var res := await s.battle({
		"id": "s8_fen", "title": "Old Fen!", "bg": "rookery", "music": "boss",
		"party": party,
		"enemies": [BattleDefs.enemy("fen", {"pos": Vector2(84, 126)})],
		"objective": {"kind": "disarm", "text": "DISARM HIM"},
		"no_hostile": true,
		"victory_title": "THE OLD MAN KNEELS",
	})
	fen.set_pose("kneel")
	fen.set_mood("sad")
	if res.outcome == "defeat":
		await s.say("fen", "...There. You see? Old Fen's still got a trick or two. Now sit down before you hurt yourself.", "sad")
		Game.add("fen", 1)
		return
	await s.say("fen", "Go on, then. If that's who you are now.", "sad")
	var c := await s.choose("Fen kneels on the stones, waiting.", ["Finish it.", "Lower the blade."])
	if c == 0:
		Game.choose("Killed Old Fen.")
		Game.killed("fen")
		Game.add("suspicion", 2)
		Game.add("loyalty", -3)
		s.music("", 0.2)
		r.set_pose("windup")
		await s.wait(0.4)
		r.set_pose("strike")
		r.afterimage_field(Pal.OMEN)
		s.sfx("slash_heavy", 0.8, -2.0)
		s.flash(Pal.WHITE, 0.4)
		fen.set_pose("lie")
		fen.set_mood("closed")
		await s.wait(1.2)
		await s.narrate("It's very quiet in the Rookery after that. The crow doesn't make a sound.")
		for id in ["bracken", "wick", "mara"]:
			if s.a(id):
				s.a(id).set_mood("shock")
		await s.say("bracken", "...Rook.", "shock")
		await s.say("blade", "There. Now no one will take me while you sleep.")
	else:
		Game.choose("Spared Old Fen.")
		Game.set_pflag("spared_fen")
		r.set_pose("walk")
		s.sfx("sword_draw", 0.6, -8.0)
		await s.say("rook", "...I'm sorry. I don't know what I saw.", "cry")
		await s.say("fen", "I do. I've seen it before. On a grave in Varn.", "sad")


func _s8_night() -> void:
	await s.narrate("Nobody sleeps much. In the small hours, Wick sits beside Rook on the stairs.")
	if Game.flag("wick_gone"):
		return
	var w := s.a("wick")
	if w:
		w.info["wander"] = false
		await s.walk("player", [Vector2i(17, 4)], 50.0)
		s.face("player", 3)
		# Wick crosses the room to him instead of appearing beside him
		var from := s.w.tile_of(w.position)
		var path := [Vector2i(16, maxi(from.y, 4)), Vector2i(16, 4)]
		if from.y > 6:
			# from the bedrolls: round the fire and Bracken, up the east side
			path = [Vector2i(from.x, 9), Vector2i(15, 9), Vector2i(15, 4), Vector2i(16, 4)]
		w.set_pose("walk")
		await s.walk("wick", path, 40.0)
		w.face(2)
		s.face("player", 3)
		await s.say("wick", "Whatever happens at the bridge. You'll teach me the bow after? The real one?", "smile")
		await s.say("rook", "The real one. I promise.", "smile")
		if Game.run.get("mark", "") == "name":
			await s.say("wick", "I scratched WICK on my sling. Same as you did. So they'll remember us both.", "grin")
			await s.think("Four letters. Same as his.")


# --------------------------------------------------------------- routing --

func talk(n: Actor) -> void:
	match scene:
		"S4":
			await _s4_talk(n)
		"S5":
			await _s5_talk(n)
		_:
			match n.info.get("who", ""):
				"mara":
					await s.say("mara", "Stay close. Something about this place makes my teeth hurt.", "worried")
				"fen":
					await s.say("fen", "Don't touch anything. Especially the sword. Especially YOUR sword.", "")
				"bracken":
					await s.say("bracken", "I don't like statues with no faces. You never know what they're thinking.", "worried")
				"wick":
					await s.say("wick", "They all look like you, a bit. Without the face.", "")
				_:
					await s.think("...")


func examine(ev: Dictionary) -> void:
	match scene:
		"S4":
			match ev.get("id", ""):
				"stairs":
					if not Game.flag("carved_done"):
						await _s4_carve()
				"haul":
					await s.think("The haul, spread out on the table like a market stall of guilt.")
				_:
					await super.examine(ev)
		"S5":
			await _s5_examine(ev)
		"S6":
			await super.examine(ev)
		"S7":
			await _s7_examine(ev)
		_:
			await super.examine(ev)


func trigger(id: String) -> void:
	if scene == "S5":
		await _s5_trigger(id)


func autoplay() -> void:
	var w := s.w
	match scene:
		"S4":
			await _s4_carve()
		"S5":
			if explore_extras():
				if not Game.flag("poster_done"):
					await _s5_examine({"id": "poster"})
				await _s5_ollo()
				await _s5_ysa()
				await _s5_amsel()
				if not Game.has_item("map"):
					Game.add("coin", 40, true)
					await _dosha_map()
				if not Game.flag("alley_done"):
					await _s5_hunter()
			Game.set_flag("s5_leave")
		"S7":
			if explore_extras():
				Game.set_flag("auto_memory")
			await _s7_examine({"id": "altar"})
