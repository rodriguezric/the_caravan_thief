class_name StoryAct1
extends StoryPart
## Prologue and Act I: Invitation.
## P1 Rope Burns: Fen's crew at the ruined waystation; what Rook wants.
## S1 The Broken Wheel: help, watch, or rob a stranded caravan.
## S2 The Dry Well: the night heist through a guarded camp.
## S3 The Sealed Chest: draw the blade, call Fen, or leave it.

const NIGHT := Color(0.52, 0.5, 0.78)
const DUSK := Color(1.0, 0.82, 0.72)


# ======================================================================
# P1 ROPE BURNS
# ======================================================================

func waystation_map() -> Dictionary:
	return {
		"id": "waystation", "name": "The Old Waystation", "theme": "ruin", "music": "camp", "tint": Color(1.0, 0.9, 0.86),
		"rows": [
			"######################",
			"####W#####D######W####",
			"::::::::::::::::::::xr",
			":::::,,,,,::::::::::xr",
			"::::::,,,:::::::xx::rr",
			"::::::::::::::::xrrrrs",
			"xx::::::::::::::rrrsss",
			"rxx:::::::::::rrrssss=",
			"rrrxxx::::::rrrssss===",
			"srrrrrrxxrrrrsss====ss",
			"sssssrrrrrsssss===ssss",
			"ssssssssssss===sssssss",
		],
		"props": [
			{"kind": "campfire", "tile": Vector2i(9, 4), "anim": 3, "fps": 7.0, "light": Pal.CANDLE, "lr": 34, "pulse": 5.0, "light_off": Vector2(0, -8),
				"event": {"id": "fire", "text": "Last night's fire, coaxed back to life for breakfast. Fen insists on hot food. Fen insists on a lot of things."}},
			{"kind": "bedroll", "tile": Vector2i(4, 3), "v": 0, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(12, 3), "v": 1, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(13, 6), "v": 3, "decal": true},
			{"kind": "crate", "tile": Vector2i(2, 2), "v": 0},
			{"kind": "crate", "tile": Vector2i(3, 2), "v": 1},
			{"kind": "barrel", "tile": Vector2i(1, 3)},
			{"kind": "handcart", "tile": Vector2i(17, 3), "area": Rect2i(16, 3, 2, 1), "event": {"id": "cart", "text": "Bracken's handcart. He named it Duchess. Nobody is allowed to ask why."}},
			{"kind": "table", "tile": Vector2i(5, 6), "v": 2, "area": Rect2i(4, 6, 2, 1), "event": {"id": "map"}},
			{"kind": "pillar", "tile": Vector2i(19, 2), "v": 1, "wall": true},
			{"kind": "rubble", "tile": Vector2i(1, 7), "v": 0},
			{"kind": "rubble", "tile": Vector2i(13, 2), "v": 1},
			{"kind": "dead_tree", "tile": Vector2i(19, 10), "v": 1, "event": {"id": "crow"}},
			{"kind": "bush", "tile": Vector2i(2, 10), "v": 0},
			{"kind": "rock", "tile": Vector2i(16, 9), "v": 1},
		],
		"npcs": [
			{"who": "fen", "tile": Vector2i(8, 5), "dir": 2, "pose": "sit"},
			# already at Rook's feet: the audience of one for the opening rehearsal (wanders after)
			{"who": "wick", "tile": Vector2i(7, 6), "dir": 1, "range": 2.0},
			{"who": "bracken", "tile": Vector2i(15, 5), "dir": 3, "pose": "cross"},
		],
		"events": [
			{"tile": Vector2i(10, 1), "id": "arch", "text": "The waystation's old arch. Someone carved a list of names into it, a hundred years of travellers. Most of them are worn smooth."},
			{"tile": Vector2i(4, 1), "id": "slit", "text": "An arrow slit. Through it, the Saltway runs white to the horizon."},
			{"tile": Vector2i(17, 1), "id": "slit", "text": "An arrow slit. Through it, the Saltway runs white to the horizon."},
		],
		"exits": [{"id": "road", "rect": Rect2i(21, 7, 1, 2)}, {"id": "road", "rect": Rect2i(18, 11, 4, 1)}],
	}


func scene_p1() -> Variant:
	scene = "P1"
	s.music("title")
	var c := await s.cine("waystation")
	c.effect = "dust"
	c.effect_k = 0.4
	await c.bars(true)
	await s.narrate(["The Saltway runs four hundred miles, from the salt flats in the south to the border kingdoms in the north.",
		"Everything worth having travels along it. Silk. Saffron. Wages. Secrets.",
		"So do the people who take it."])
	await c.close(0.6)
	await s.explore(waystation_map(), Vector2i(6, 4), 0)
	s.lock(true)
	var wick := s.a("wick")
	s.face("player", 0)
	await s.wait(0.5)
	# Rook rehearses his legend for an audience of one
	s.sfx("whiff", 1.2, -10.0)
	await s.a("player").gesture("bow", 1.4)
	await s.say("rook", "Ladies. Gentlemen. Wick. Tremble, for you stand before... the ROOK of the SALTWAY!", "grin")
	s.a("player").gesture("victory", 1.0)
	wick.hop(5.0)
	wick.emote("music")
	await s.say("wick", "Again! Do the bit with the coat again!", "grin")
	await s.a("player").spin(1)
	s.a("player").gesture("hips", 1.2)
	await s.say("rook", "Stole the shadow off the moon. Picked a duke's pocket while he was still wearing it. They sing about him in Varn.", "smirk")
	s.face_to("bracken", "player")
	await s.say("bracken", "Rook of the what?", "")
	await s.say("rook", "...The Saltway. It's new. I'm workshopping it.", "worried")
	s.a("bracken").gesture("laugh", 1.4)
	s.sfx("crowd", 0.6, -14.0)
	await s.say("bracken", "HAH! Nobody sings about you in Varn. They hang people in Varn.", "laugh")
	s.mood("rook", "sad")
	await s.think("The rope burns on the backs of his hands start to itch. They always do, when someone says hanged.")
	# Fen gets up, slowly, with his stick
	var fen := s.a("fen")
	fen.set_pose("walk")
	await fen.hop(2.0)
	s.sfx("knock", 1.4, -16.0)
	await s.walk("fen", [Vector2i(8, 4), Vector2i(7, 4)], 26.0)
	s.face_to("fen", "player")
	s.face_to("player", "fen")
	await s.say("fen", "Names get you hanged, boy.", "")
	fen.gesture("point", 0.8)
	s.sfx("knock", 1.6, -14.0)
	await s.say("fen", "Bread gets you to winter. Bread, and a roof, and people who'd notice if you didn't come back.", "smile")
	await s.say("fen", "So. Rook of the Saltway. What do you actually want?", "")
	var r := await s.choose("What does Rook want?", ["\"A name that outlives me.\"", "\"Bread. Winter. Whatever you said.\"", "\"To never be poor again.\""])
	match r:
		0:
			Game.set_flag("desire", "name")
			Game.choose("Told Fen he wants a name that outlives him.")
			s.a("player").gesture("fist", 1.0)
			await s.say("rook", "A name. One that outlives me. When I'm dirt, I want someone on this road to still be telling lies about me.", "determined")
			s.shake_head("fen")
			await s.say("fen", "Every man who ever wanted that got it the same way. On a sign. Over a grave.", "sad")
		1:
			Game.set_flag("desire", "bread")
			Game.add("fen", 1)
			s.a("player").gesture("shrug", 1.0)
			await s.say("rook", "Bread. Winter. A roof. Whatever you said. I was listening, mostly.", "smirk")
			fen.gesture("laugh", 1.0)
			await s.say("fen", "Liar. But a polite one. I'll take it.", "grin")
		2:
			Game.set_flag("desire", "coin")
			s.a("player").gesture("cross", 1.2)
			await s.say("rook", "To never be poor again. To never have to ask for anything.", "")
			s.nod("fen")
			await s.say("fen", "Now that's honest. Wrong, but honest. Rich men ask for things all day.", "")
	await s.wait(0.3)
	await s.say("fen", "Work, then. Ollo's caravan broke a wheel two miles down the Saltway. Go and have a look.", "")
	fen.gesture("point", 1.0)
	await s.say("fen", "Look, Rook. Just look. Come back and tell me what you saw.", "")
	await s.say("", "Arrows or WASD to move, Z to talk and look at things, Shift to run, X for the menu. The road is to the east.", "", {"color": Pal.CANDLE.lerp(Pal.WHITE, 0.4)})
	wick.info["wander"] = true
	s.walk("fen", [Vector2i(8, 5)], 26.0)
	fen.set_pose("walk")
	s.lock(false)
	s.marker(Vector2i(20, 8))
	await s.until(func() -> bool: return Game.flag("p1_done"))
	return "S1"


func _p1_talk(n: Actor) -> void:
	match n.info.get("who", ""):
		"fen":
			var k := Game.bump_talk("fen_p1")
			if k == 1:
				await s.say("fen", "Two miles. Ollo's wagons, cream canvas, the fat one with the striped awning. You'll see them.", "")
				await s.say("fen", "And Rook. There's a second wagon travelling with them that isn't Ollo's. Clean as a bone. Stay away from that one.", "worried")
			else:
				n.set_pose("walk")
				await s.say("fen", "Still here? The road won't rob itself.", "smirk")
				n.set_pose("sit")
		"wick":
			var k := Game.bump_talk("wick_p1")
			if k == 1:
				n.hop(4.0)
				await s.say("wick", "Can I come? I can be lookout. I'm a great lookout. I look at everything.", "grin")
				await s.say("rook", "Fen said look, not rob. Lookout's me today.", "smirk")
				n.emote("sweat")
				await s.say("wick", "Teach me the bow, then. The real one. Not the one you do when you've been caught.", "smile")
			else:
				await s.say("wick", "Rook of the Saltway. Wick of the... Wick. Still workshopping.", "smile")
		"bracken":
			var k := Game.bump_talk("bracken_p1")
			if k == 1:
				await s.say("bracken", "My knee says rain. Knee's never been right, but it says it every morning anyway.", "")
				await s.say("bracken", "Here. Fen's bread. Don't tell him I gave you the good end.", "smile")
				Game.add_supply("bread", 1)
				s.sfx("coin", 0.8, -8.0)
				await s.say("", "Got: Road Bread.", "", {"color": Pal.GLOW})
			else:
				await s.say("bracken", "One day I'm buying a farm. Goats. A wife, maybe. In that order.", "")


func _p1_examine(ev: Dictionary) -> void:
	match ev.get("id", ""):
		"map":
			await s.think("Fen's map of the Saltway, weighted down with stones. The caravan's route is marked in charcoal. So is a little drawing of a noose, labelled VARN. Fen's idea of a joke.")
		"crow":
			s.sfx("caw", 1.0, -8.0)
			await s.think("A crow on the dead tree, watching him. It's been following the crew since Varn. Bracken says it's lucky. Fen says it's hungry.")
			await s.think("It has one strange eye. It catches the light the wrong colour.")
		_:
			await super.examine(ev)


func _p1_exit(_e: Dictionary) -> void:
	if Game.flag("p1_done"):
		return
	s.unmarker()
	Game.set_flag("p1_done")


# ======================================================================
# S1 THE BROKEN WHEEL
# ======================================================================

func saltway_map() -> Dictionary:
	return {
		"id": "saltway", "name": "The Saltway", "theme": "road", "music": "road",
		"rows": [
			"##################################",
			"##################################",
			"rrrrsssgsssssssssssssgsssssssrrrrr",
			"rrrsssssssssssssssssssssssssssrrrr",
			"rrsssgsssssssssssgssssssssssssssrr",
			"ssssssssssssssssssssssssssssssssss",
			"ssgsssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssss",
			"==================================",
			"==================================",
			"sssssssssgsssssssssssssssssgssssss",
			"ssgssssssssssssssssssssssssssssssg",
			"ssssssssssssssssssssssssssssssssss",
			"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
		],
		"props": [
			{"kind": "boulder", "tile": Vector2i(4, 4), "v": 0},
			{"kind": "boulder", "tile": Vector2i(8, 3), "v": 1},
			{"kind": "rock", "tile": Vector2i(2, 6), "v": 1},
			{"kind": "wagon_broken", "tile": Vector2i(14, 7), "area": Rect2i(12, 6, 5, 2), "id": "wagon", "event": {"id": "wagon"}},
			{"kind": "wheel", "tile": Vector2i(11, 8), "v": 0, "id": "wheel", "decal": true},
			{"kind": "crate", "tile": Vector2i(17, 6), "v": 1},
			{"kind": "sacks", "tile": Vector2i(18, 6), "v": 1},
			{"kind": "boulder", "tile": Vector2i(24, 6), "v": 0, "area": Rect2i(23, 6, 3, 1)},
			{"kind": "wagon", "tile": Vector2i(29, 7), "v": 2, "area": Rect2i(27, 6, 5, 2), "id": "factor_wagon"},
			{"kind": "bush", "tile": Vector2i(9, 11), "v": 2},
			{"kind": "bush", "tile": Vector2i(22, 11), "v": 0},
			{"kind": "dead_tree", "tile": Vector2i(32, 4), "v": 0},
			{"kind": "sign", "tile": Vector2i(6, 7), "event": {"id": "sign", "text": "A milestone: VARN 41. KESH CROSSING 12. Someone has scratched a little crown into it. Rook did that, last spring."}},
		],
		"npcs": [
			{"who": "ollo", "tile": Vector2i(13, 9), "dir": 1},
			{"who": "guard", "id": "g1", "tile": Vector2i(16, 9), "dir": 1},
			{"who": "guard2", "id": "g2", "tile": Vector2i(11, 7), "dir": 2},
			{"who": "pilgrim", "id": "ysa", "tile": Vector2i(19, 9), "dir": 1, "pose": "sit"},
			{"who": "pilgrim_kid", "id": "tam", "tile": Vector2i(20, 10), "dir": 3, "wander": true, "range": 1.5},
			{"who": "ox", "id": "ox", "tile": Vector2i(20, 7), "dir": 2},
			{"who": "mara", "tile": Vector2i(24, 5), "dir": 0, "offset": Vector2(0, -10)},
			{"who": "factor", "tile": Vector2i(27, 9), "dir": 3},
			{"who": "hunter", "id": "h1", "tile": Vector2i(31, 9), "dir": 3},
		],
		"triggers": [],
		"exits": [],
	}


func scene_s1() -> Variant:
	scene = "S1"
	await s.explore(saltway_map(), Vector2i(2, 3), 2)
	s.lock(true)
	var r := s.a("player")
	r.set_pose("crouch")
	await s.wait(0.4)
	await s.think("Ollo's caravan. One wagon down on its axle, oxen sulking, guards standing around arguing about whose job it is.")
	await s.pan(Vector2i(14, 8), 1.2)
	s.a("ollo").gesture("fist", 1.0)
	s.a("ollo").emote("anger")
	await s.say("ollo", "Lift it! LIFT it! You're paid to lift things! I have seen you lift a whole roast chicken!", "angry")
	s.a("g1").gesture("shrug", 1.0)
	await s.say("guard", "We're paid to guard things, master Ollo.", "")
	await s.pan(Vector2i(20, 9), 0.8)
	await s.think("A pilgrim woman and her boy, riding with the caravan for safety. The boy is trying to feed the ox a pebble.")
	await s.pan(Vector2i(24, 6), 0.8)
	var mara := s.a("mara")
	mara.set_pose("aim")
	await s.think("On the rock: the caravan's scout. Bow strung, braid tied back, watching the ridge.")
	mara.face(3)
	await s.wait(0.3)
	mara.emote("?")
	r.set_pose("cower")
	r.emote("sweat")
	await s.wait(0.8)
	mara.face(0)
	mara.set_pose("walk")
	r.set_pose("crouch")
	await s.think("Watching *this* ridge. Very good scout. Very bad news.")
	await s.pan(Vector2i(28, 9), 1.0)
	s.music("omen", 1.5)
	await s.think("And there: the second wagon. The one Fen said to stay away from.")
	await s.narrate("Its canvas is spotless. Beside it stands a tall man in cream robes, so clean the road dust seems to have decided against him. He carries no weapon. He has not moved.")
	var f := s.a("factor")
	await s.wait(0.6)
	f.face(1)
	await s.wait(0.6)
	f.face(3)
	s.sfx("heartbeat", 1.0, -6.0)
	await s.think("He's looking at the ridge. At me. He can't be looking at me.")
	s.sfx("caw", 1.0, -6.0)
	await s.wait(0.4)
	await s.pan_back(0.8)
	s.music("road", 1.0)
	var choice := await s.choose("How does Rook play this?", ["Walk down and help with the wheel.", "Stay on the ridge and watch.", "Slip in while they're busy and take something."])
	match choice:
		0:
			Game.set_flag("s1", "help")
			Game.choose("Helped Ollo's caravan with the broken wheel.")
			await _s1_help()
		1:
			Game.set_flag("s1", "observe")
			Game.choose("Watched the caravan from the ridge.")
			await _s1_observe()
		2:
			Game.set_flag("s1", "rob")
			Game.choose("Robbed the stranded caravan in broad daylight.")
			await _s1_rob()
	await _s1_report()
	return "S2"


func _s1_help() -> void:
	var r := s.a("player")
	r.set_pose("walk")
	await s.walk("player", [Vector2i(4, 5), Vector2i(9, 7), Vector2i(12, 9)], 56.0)
	s.face("player", 2)
	s.face_to("ollo", "player")
	s.a("ollo").jump_back()
	s.a("ollo").emote("!")
	await s.say("ollo", "Bandit! Guards! A bandit with a... with a very nice coat.", "shock")
	await r.gesture("bow", 1.0)
	await s.say("rook", "Rook. Wheelwright, juggler, honest traveller. Mostly honest. Looks like you've got a wheel problem.", "smile")
	await s.say("ollo", "I have a wheel problem, a guard problem, and an everything-costs-money problem.", "worried")
	await s.say("rook", "The first one's free.", "grin")
	# Mara comes down from her rock to see who the stranger is
	var mara := s.a("mara")
	mara.position.y += 10
	await s.walk("mara", [Vector2i(24, 7), Vector2i(17, 8), Vector2i(15, 8)], 60.0)
	s.face_to("mara", "player")
	await s.say("mara", "You came off that ridge. I watched you sit up there for a quarter of an hour.", "angry")
	await s.say("rook", "Admiring the view. Grab the other side?", "smirk")
	# the lift: both of them under the axle, straining
	await s.walk("player", [Vector2i(12, 8)], 40.0)
	s.face("player", 1)
	await s.walk("mara", [Vector2i(16, 8)], 40.0)
	s.face("mara", 1)
	r.set_pose("carry")
	mara.set_pose("carry")
	s.sfx("creak", 0.8, -4.0)
	r.tremble(1.2)
	mara.tremble(1.2)
	r.emote("sweat")
	await s.say("rook", "Hhhnnngh. On three. One. Two-", "hurt")
	var wg: Sprite2D = s.w.prop_sprite("wagon")
	var tw := s.w.create_tween()
	tw.tween_property(wg, "position:y", wg.position.y - 3, 0.3).set_trans(Tween.TRANS_BACK)
	s.shake(1.0, 0.3)
	await s.wait(0.3)
	s.a("g1").gesture("carry", 1.0)
	s.sfx("thud", 0.8, -4.0)
	var wheel: Sprite2D = s.w.prop_sprite("wheel")
	if wheel:
		wheel.visible = false
	await s.narrate("The wheel goes back on with a THUNK that everyone feels in their teeth.")
	r.set_pose("walk")
	mara.set_pose("walk")
	r.land()
	mara.land()
	s.face_to("mara", "player")
	s.face_to("player", "mara")
	await s.say("mara", "You've got rope burns. Both hands.", "")
	await s.say("rook", "Sailor.", "smile")
	await s.say("mara", "On the Saltway.", "")
	await s.say("rook", "...Very dry sailor.", "smirk")
	mara.gesture("cross", 1.2)
	await s.say("mara", "Mara. Scout. If you're casing us, wheelwright, you're doing it very strangely.", "smile")
	Game.set_flag("met_mara")
	Game.add("mara", 2)
	Game.add("loyalty", 1)
	# then: the howl
	s.sfx("howl", 1.0, -2.0)
	s.a("tam").emote("!")
	s.a("ox").emote("!")
	mara.set_pose("aim")
	await s.say("mara", "Jackals. Off the flats. Three of them, maybe more.", "angry")
	await s.say("mara", "You've got a knife. Use it.", "determined")
	var res := await s.battle(_jackal_battle())
	if res.outcome == "defeat":
		Game.set_flag("injured")
		await s.narrate("The jackals drag Rook through the dust before Mara's arrows finally scatter them. He limps back to his feet, embarrassed in several places.")
	for id in ["g1", "g2"]:
		s.a(id).set_mood("smile")
	await s.say("ollo", "You helped. Without being paid. I don't understand it, but I respect it from a distance.", "smile")
	Game.add("coin", 10)
	await s.say("ollo", "We camp at the Dry Well tonight. You're welcome to the fire. Don't touch the cream wagon. The Factor doesn't like hands.", "")
	await s.say("ysa", "Thank you, traveller. Tam, say thank you.", "smile")
	s.a("tam").hop(4.0)
	await s.say("pilgrim_kid", "Thank you, sailor!", "grin")
	await _s1_help_factor()


func _s1_help_factor() -> void:
	## Walking back past the cream wagon, the Factor stops him. Rook doesn't
	## have the blade yet; the Factor talks to him as if he already might.
	var r := s.a("player")
	var f := s.a("factor")
	await s.walk("player", [Vector2i(20, 9), Vector2i(24, 9)], 50.0)
	s.face_to("factor", "player")
	await s.say("factor", "You have careful hands.", "")
	r.set_mood("shock")
	s.face_to("player", "factor")
	await s.wait(0.3)
	r.set_mood("")
	r.gesture("cross", 1.2)
	await s.say("rook", "Wheelwright's hands.", "smirk")
	await s.walk("factor", [Vector2i(26, 9)], 22.0)
	s.face_to("factor", "player")
	await s.say("factor", "A wheelwright's hands are calloused across the palm. Yours are burned at the wrists. Rope, I think. Pulled tight, a long time ago.", "")
	r.emote("sweat")
	await s.think("Two people in one afternoon. He's going to start wearing gloves. He's going to start wearing a sack.")
	await s.narrate("The Factor draws a folded cloth from his sleeve, cream like his robes, and holds it out. It smells of nothing at all.")
	f.gesture("reach", 1.6)
	await s.say("factor", "For the hands. The salt gets into old burns.", "smile")
	var c := await s.choose("The cloth hangs between them. The Factor waits as if he has never once been in a hurry.", [
		"Take it. Say thank you.", "Keep your hands to yourself.", "Ask him what's in the cream wagon."])
	match c:
		0:
			Game.set_flag("factor_cloth")
			r.gesture("reach", 0.8)
			s.sfx("paper", 1.4, -12.0)
			await s.say("rook", "...Thanks.", "")
			await s.say("factor", "Manners. They're rarer on this road than water.", "smile")
			await s.think("It's the softest thing he has ever held. He wants to give it back. He wants to keep it. Both at once. That's never a good sign.")
		1:
			r.shake_head()
			await s.say("rook", "I'm fine. Salt's good for you. Keeps things.", "grin")
			f.nod(1)
			await s.say("factor", "It does. Fish. Meat. Grudges.", "smile")
			await s.narrate("He folds the cloth away, corner to corner, exactly as it was.")
			await s.say("factor", "Keeping things is my trade too, as it happens.", "")
		_:
			await s.say("rook", "So. The cream wagon. What's a man like you guarding out here with no guards?", "sly")
			s.sfx("heartbeat", 0.8, -10.0)
			f.face(2)
			await s.wait(0.6)
			s.face_to("factor", "player")
			await s.say("factor", "Something that was lost once, and is kept now.", "")
			await s.say("factor", "Kept things are not lost, you understand. Not even when they wander off. They only take the long way home.", "smile")
			await s.think("That wasn't an answer. That was a door with a painted handle.")
	# he looks past Rook, up at the ridge he came down from
	f.face(1)
	await s.wait(0.5)
	s.face_to("factor", "player")
	await s.say("factor", "You came down off that ridge. Most people who watch from ridges stay up there. Or come down after dark.", "")
	r.gesture("shrug", 1.0)
	await s.say("rook", "I'm a morning person.", "grin")
	await s.say("factor", "Then I hope I see you in the morning.", "smile")
	s.sfx("heartbeat", 1.0, -8.0)
	await s.wait(0.4)
	f.gesture("bow", 1.4)
	await s.say("factor", "Good afternoon.", "smile")
	await s.walk("player", [Vector2i(21, 9)], 46.0)
	s.face_to("player", "factor")
	r.emote("...")
	await s.think("He hasn't moved. He wasn't looking at my hands. He was looking at my face the whole time.")


func _jackal_battle() -> Dictionary:
	return {
		"id": "s1_jackals", "title": "Jackals off the flats!", "bg": "road", "music": "battle",
		"party": ["rook", "mara"],
		"enemies": [BattleDefs.enemy("jackal"), BattleDefs.enemy("jackal", {"spd": 11}), BattleDefs.enemy("jackal", {"hp": 20})],
		"objective": {"kind": "defeat", "text": "DRIVE THEM OFF"},
		"victory_note": "The jackals scatter back onto the salt flats.",
		"thresholds": [{"unit": "rook", "below": 0.5, "fn": func(b: Battle) -> Dictionary:
			await b.say("mara", "Get behind me, wheelwright! You fight like a man who's mostly run.", "angry")
			await b.say("rook", "I'm VERY good at running!", "hurt")
			var m := b.unit("mara")
			if m and m.alive:
				var rk := b.unit("rook")
				rk.status["covered"] = 2
				rk.set_meta("cover_by", "mara")
				b.apply_status(rk, "covered", 2)
			return {}}],
	}


func _s1_observe() -> void:
	var r := s.a("player")
	await s.think("Watch. Just look, like Fen said. Get close enough to hear without being close enough to be seen.")
	await s.say("", "Sneak to the three places marked. Stay out of the guards' sight.", "", {"color": Pal.CANDLE.lerp(Pal.WHITE, 0.4)})
	s.w.def["sneak"] = true
	r.set_pose("sneak")
	s.lock(false)
	Game.set_flag("listen_n", 0)
	_place_listen()
	await s.until(func() -> bool: return int(Game.fval("listen_n", 0)) >= 3)
	s.w.def["sneak"] = false
	s.lock(true)
	Game.set_flag("observed_rotation")
	Game.add("finesse", 1)
	await s.think("The second bell. The hunter's watch changes at the second bell, and for a count of a hundred nobody's watching the cream wagon.")
	# on the way back, a guard notices a shape on the ridge
	await s.walk("player", [Vector2i(9, 5), Vector2i(6, 5)], 40.0)
	var g := s.a("g2")
	await s.walk("g2", [Vector2i(9, 7)], 50.0)
	s.face_to("g2", "player")
	g.emote("!")
	s.sfx("alert", 1.0, -4.0)
	await s.say("guard2", "Oi! You! On the ridge!", "angry")
	r.jump_back()
	await s.think("...Well. Looking only works if nobody looks back.")
	var res := await s.battle(_ridge_battle())
	if res.outcome == "defeat":
		Game.set_flag("injured")
		await s.narrate("The guards give Rook a kicking and a warning and leave him in the dust. He takes the warning. He keeps the information.")
	else:
		await s.narrate("Rook vanishes over the ridge before anyone can describe him. Mostly.")


func _place_listen() -> void:
	s.w.events[Vector2i(10, 6)] = {"id": "listen_guards"}
	s.w.events[Vector2i(18, 5)] = {"id": "listen_ollo"}
	s.w.events[Vector2i(26, 5)] = {"id": "listen_factor"}
	s.marker(Vector2i(10, 6))
	s.w.guards.clear()
	s.w._make_guard(s.a("g1"), {"vision": 52})
	s.w.guards[0].pts = [s.w.tile_center(Vector2i(16, 9)), s.w.tile_center(Vector2i(16, 7)), s.w.tile_center(Vector2i(19, 7))]
	s.w._make_guard(s.a("g2"), {"vision": 52})
	s.w.guards[1].pts = [s.w.tile_center(Vector2i(11, 7)), s.w.tile_center(Vector2i(8, 7))]
	s.w.stealth = true
	s.w._build_alert_bar()


func _listen(id: String) -> void:
	if Game.flag("heard_" + id):
		await s.think("Nothing more to hear here.")
		return
	Game.set_flag("heard_" + id)
	Game.set_flag("listen_n", int(Game.fval("listen_n", 0)) + 1)
	s.a("player").set_pose("crouch")
	match id:
		"guards":
			await s.say("guard", "Second bell, I go off. Second bell, the cream ones come on. A hundred count where nobody's at that wagon.", "")
			await s.say("guard2", "Don't let the Factor hear you call them the cream ones.", "worried")
			s.marker(Vector2i(18, 5))
		"ollo":
			await s.say("ollo", "Twelve wagons of my goods, and I'm paid to drag one sealed box for him. One box! No one's allowed to say what's in it!", "angry")
			await s.say("ollo", "I'll tell you what's in it. Trouble. Wrapped in very expensive cloth.", "worried")
			s.marker(Vector2i(26, 5))
		"factor":
			s.music("omen", 1.0)
			s.face_to("factor", "h1")
			await s.say("factor", "If anyone should open the cargo, you will not chase the box.", "")
			await s.say("hunter", "Sir?", "")
			await s.say("factor", "Boxes are patient. You will chase whoever opened it. Gently, if you can. Kindly, if you can't.", "smile")
			Game.add_lore("factor_hunts")
			s.unmarker()
			s.music("road", 1.0)
	s.a("player").set_pose("sneak")


func _ridge_battle() -> Dictionary:
	return {
		"id": "s1_ridge", "title": "Spotted on the ridge!", "bg": "road", "music": "battle",
		"party": ["rook"],
		"enemies": [BattleDefs.enemy("guard2"), BattleDefs.enemy("guard", {"hp": 30})],
		"objective": {"kind": "escape", "turns": 3, "text": "GET AWAY:", "win_title": "OVER THE RIDGE", "note": "No one gets a good look at his face."},
		"can_flee": true,
	}


func _s1_rob() -> void:
	var r := s.a("player")
	await s.think("Everyone's looking at the wheel. Nobody's looking at Ollo's belt.")
	r.set_pose("sneak")
	await s.walk("player", [Vector2i(4, 6), Vector2i(9, 8), Vector2i(12, 10)], 40.0)
	r.set_pose("sneak")
	s.face("player", 2)
	await s.wait(0.3)
	var res := await s.minigame("pickpocket", {"mark": "ollo", "item": "Ollo's purse", "skill": Game.v("finesse") / 10.0 + 0.3, "bg": "saltway"})
	Game.add("finesse", 1)
	if res.get("success", false):
		Game.give_item("purse")
		Game.give_item("seal_ring")
		Game.add_supply("smoke", 1)
		Game.add_supply("sand", 1)
		Game.add("suspicion", 1)
		await s.narrate("The purse comes away clean. So does the silver seal-ring knotted to its cord. And, from the wagon's open kit-box, a couple of smoke pellets and a pouch of grit.")
		await s.think("Nobody saw. Nobody saw. Nobody-")
		s.face_to("mara", "player")
		s.a("mara").emote("!")
		await s.say("mara", "HEY! Blue coat!", "angry")
	else:
		s.a("ollo").face(0)
		s.a("ollo").emote("!!")
		await s.say("ollo", "THIEF! There's a hand in my- that's a HAND!", "shock")
	r.set_pose("walk")
	r.jump_back()
	Game.set_flag("met_mara")
	Game.add("mara", -1)
	s.a("mara").set_pose("aim")
	var b := await s.battle(_rob_battle())
	if b.outcome == "defeat":
		Game.set_flag("injured")
		await s.narrate("Mara's arrow pins Rook's coat-tail to the road. He leaves the coat-tail. He keeps the coat.")
	else:
		await s.narrate("Rook is over the ridge and gone before the dust settles. Behind him, the scout doesn't shout. She just watches, memorising.")


func _rob_battle() -> Dictionary:
	return {
		"id": "s1_rob", "title": "Caught red-handed!", "bg": "road", "music": "battle",
		"party": ["rook"],
		"enemies": [BattleDefs.enemy("mara", {"nonlethal": true}), BattleDefs.enemy("guard", {"hp": 30})],
		"objective": {"kind": "escape", "turns": 3, "text": "GET AWAY:", "win_title": "CLEAN GETAWAY", "note": "The scout got a good look at him. That might matter later."},
		"can_flee": true,
	}


func _s1_report() -> void:
	# dusk back at the waystation
	var c := await s.cine("waystation")
	s.music("camp")
	var fen := c.person("fen", Vector2(110, 160), 2, "", "sit")
	var rook := c.person("rook", Vector2(200, 160), 3)
	c.person("wick", Vector2(150, 148), 0, "", "sit")
	c.person("bracken", Vector2(240, 150), 3, "", "cross")
	await s.wait(0.3)
	match str(Game.fval("s1", "")):
		"help":
			await s.say("rook", "I helped them fix the wheel.", "smile")
			fen.gesture("facepalm", 1.4)
			await s.say("fen", "You HELPED them.", "shock")
			await s.say("rook", "They invited me to their fire. Tonight. At the Dry Well.", "grin")
			fen.set_mood("smile")
			await s.say("fen", "...Ha! An invitation. That's better than a look. That's a door left open.", "laugh")
			Game.add("fen", 1)
		"observe":
			await s.say("rook", "The cream wagon's watch changes at the second bell. For a hundred count, nobody's on it.", "smirk")
			fen.emote("idea")
			await s.say("fen", "Now that's thieving. That's the real thing. Eyes before hands.", "grin")
			Game.add("fen", 1)
		"rob":
			rook.gesture("shrug", 1.0)
			await s.say("rook", "I may have also taken a purse. And a ring. Slightly.", "smirk")
			fen.emote("anger")
			await s.say("fen", "In daylight. With a scout on a rock. Now they're awake, Rook. Now they count their fingers.", "angry")
			Game.add("fen", -1)
	await s.say("fen", "Fine. It's done. Tonight, the Dry Well. Ollo's camp, and whatever's in that cream wagon.", "")
	await s.say("fen", "Wick makes noise at the north end. Bracken waits with Duchess. I watch the road. You go in.", "")
	c.get_actor("wick").hop(5.0)
	await s.say("wick", "I'm noise! I'm the noise!", "grin")
	await s.say("bracken", "Duchess is ready. Duchess was born ready.", "smile")
	await c.close(0.6)


# ======================================================================
# S2 THE DRY WELL
# ======================================================================

func camp_map() -> Dictionary:
	var observed := Game.flag("observed_rotation")
	var npcs := [
		{"who": "guard", "id": "g1", "tile": Vector2i(8, 4), "dir": 2, "patrol": [Vector2i(8, 4), Vector2i(14, 4)], "vision": 56},
		{"who": "guard2", "id": "g3", "tile": Vector2i(15, 12), "dir": 2, "patrol": [Vector2i(15, 12), Vector2i(21, 12), Vector2i(21, 14)], "vision": 52},
		{"who": "guard", "id": "sleeper", "tile": Vector2i(17, 9), "dir": 0, "pose": "lie", "mood": "sleep"},
		{"who": "hunter", "id": "h1", "tile": Vector2i(30, 10), "dir": 3},
		{"who": "ox", "id": "ox", "tile": Vector2i(4, 14), "dir": 2},
	]
	if not observed:
		npcs.append({"who": "guard2", "id": "g2", "tile": Vector2i(24, 5), "dir": 0, "patrol": [Vector2i(24, 5), Vector2i(24, 12)], "vision": 60, "speed": 30.0})
	return {
		"id": "camp", "name": "The Dry Well", "theme": "road", "music": "heist", "tint": NIGHT, "stealth": true, "sneak": true,
		"rows": [
			"####################################",
			"####################################",
			"rrrsssssssssssssssssssssssssssssrrrr",
			"rrssssssssssssssssssssssssssssssssrr",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"====================================",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"ssssssssssssssssssssssssssssssssssss",
			"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
		],
		"props": [
			{"kind": "wagon", "tile": Vector2i(6, 7), "v": 0, "area": Rect2i(4, 6, 5, 2)},
			{"kind": "wagon", "tile": Vector2i(18, 4), "v": 1, "area": Rect2i(16, 3, 5, 2), "id": "stores", "event": {"id": "stores"}},
			{"kind": "wagon", "tile": Vector2i(12, 14), "v": 0, "area": Rect2i(10, 13, 5, 2), "flip": true},
			{"kind": "wagon", "tile": Vector2i(31, 8), "v": 2, "area": Rect2i(29, 7, 5, 2), "id": "factor_wagon", "event": {"id": "factor_wagon"}},
			{"kind": "tent", "tile": Vector2i(11, 7), "v": 1},
			{"kind": "tent", "tile": Vector2i(27, 13), "v": 0},
			{"kind": "tent", "tile": Vector2i(22, 7), "v": 2},
			{"kind": "campfire", "tile": Vector2i(18, 10), "anim": 3, "fps": 7.0, "light": Pal.CANDLE, "lr": 40, "pulse": 5.0, "light_off": Vector2(0, -6)},
			{"kind": "bedroll", "tile": Vector2i(16, 10), "v": 1, "decal": true},
			{"kind": "bedroll", "tile": Vector2i(20, 11), "v": 2, "decal": true},
			{"kind": "lamp_post", "tile": Vector2i(14, 6), "light": Pal.CANDLE, "lr": 26, "pulse": 3.0, "light_off": Vector2(2, -26)},
			{"kind": "lamp_post", "tile": Vector2i(27, 8), "light": Pal.CANDLE, "lr": 26, "pulse": 3.0, "light_off": Vector2(2, -26)},
			{"kind": "well", "tile": Vector2i(24, 14), "area": Rect2i(23, 14, 2, 1), "event": {"id": "well", "text": "The Dry Well. It isn't dry. Nobody on the Saltway trusts a well with an honest name."}},
			{"kind": "crate", "tile": Vector2i(9, 10), "v": 0},
			{"kind": "crate", "tile": Vector2i(10, 10), "v": 1},
			{"kind": "barrel", "tile": Vector2i(25, 9)},
			{"kind": "sacks", "tile": Vector2i(21, 3), "v": 1},
			{"kind": "hay", "tile": Vector2i(3, 13)},
			{"kind": "trough", "tile": Vector2i(6, 13)},
		],
		"npcs": npcs,
		"triggers": [{"id": "approach", "rect": Rect2i(26, 9, 2, 3)}],
		"exits": [{"id": "west", "rect": Rect2i(0, 8, 1, 3)}],
	}


func scene_s2() -> Variant:
	scene = "S2"
	var c := await s.cine("night_camp")
	c.animate_bg("night_camp", 4, 2.0)
	c.effect = "stars"
	c.effect_k = 0.2
	s.music("heist")
	await s.narrate(["The Dry Well. Ollo's wagons in a ring, a fire burning low, guards with lanterns walking slow circles.",
		"Somewhere out in the dark, Fen is watching the road, Bracken is holding Duchess, and Wick is waiting to be noise."])
	if Game.fval("s1", "") == "help":
		await s.narrate("Rook could walk in through the front, as a guest. He doesn't. Guests get remembered.")
	await c.close(0.6)
	await s.explore(camp_map(), Vector2i(1, 9), 2)
	await s.say("", "Sneak to the cream wagon at the east of the camp. Lantern light is how the guards see. The eye at the top right fills when someone's looking.", "", {"color": Pal.CANDLE.lerp(Pal.WHITE, 0.4)})
	if Game.flag("observed_rotation"):
		await s.think("Second bell. The hunter's watch is changing. One fewer lantern between me and that wagon.")
	s.marker(Vector2i(28, 10))
	await s.until(func() -> bool: return Game.flag("in_wagon"))
	if not s.w.spotted_once and not Game.flag("s2_caught"):
		Game.set_pflag("ghost")
	return "S3"


func _s2_examine(ev: Dictionary) -> void:
	match ev.get("id", ""):
		"stores":
			if Game.flag("looted"):
				await s.think("He's taken what he can carry. Any more and he'll clink when he walks.")
				return
			await s.think("Ollo's stores wagon. The tailboard's only tied. Inside: crates, bundles, a family's travelling chest.")
			var r := await s.choose("Take something?", ["Quickly. Grab what you can.", "Not why we're here."])
			if r != 0:
				return
			Game.set_flag("looted")
			var items := ["saffron", "silk", "icon"]
			if not Game.has_item("purse"):
				items.insert(0, "purse")
			var res := await s.minigame("loot", {"items": items, "capacity": 4, "time": 9.0, "keep_music": true})
			for id in res.get("taken", []):
				Game.give_item(id)
			if res.get("taken", []).size() > 0:
				Game.add("suspicion", 1, true)
				Game.choose("Looted Ollo's stores at the Dry Well: %s." % ", ".join(res.taken.map(func(x): return Data.item(x).name)))
			if res.get("taken", []).has("icon"):
				await s.think("A painted wooden saint, rubbed smooth by hands. Probably worth nothing. He takes it anyway. His hands do, anyway.")
		"factor_wagon":
			if not Game.flag("approached"):
				await s.think("The hunter is right there. Wait for Wick.")
				return
			await _s2_lock()
		_:
			await super.examine(ev)


func _s2_trigger(id: String) -> void:
	if id != "approach" or Game.flag("approached"):
		return
	s.unmarker()
	Game.set_flag("approached")
	var r := s.a("player")
	r.set_pose("crouch")
	await s.think("The cream wagon. One hunter at the steps. Come on, Wick. Come on...")
	await s.wait(0.6)
	# Wick's distraction: something enormous falls over at the north end
	s.sfx("crash", 1.0, -2.0)
	s.shake(2.0, 0.5)
	await s.wait(0.3)
	s.sfx("crowd", 1.4, -8.0)
	var h := s.a("h1")
	h.emote("!")
	h.jump_back()
	await s.say("wick", "(from very far away) OH NO. THE GOATS. SOMEONE HAS FREED ALL THE GOATS.", "shock")
	await s.wait(0.2)
	h.face(1)
	await s.walk("h1", [Vector2i(30, 5), Vector2i(26, 3)], 70.0)
	s.hide("h1")
	r.set_pose("sneak")
	await s.think("There are no goats. There have never been goats. Bless that boy.")
	s.marker(Vector2i(30, 9))


func _s2_lock() -> void:
	var r := s.a("player")
	r.set_pose("pick")
	r.face(1)
	s.unmarker()
	var res := await s.minigame("lockpick", {"pins": 4 if Game.v("finesse") < 3 else 3, "keep_music": true, "title": "THE CREAM WAGON"})
	if not res.get("success", false):
		Game.set_flag("noise")
		await s.narrate("The pick snaps with a sound like a bone. Rook freezes. Then he does it the ugly way: a knife through the canvas.")
		s.sfx("slash", 0.8, -4.0)
	else:
		await s.narrate("Click. The door to the cream wagon swings in on oiled hinges, without a sound. Of course it does.")
	Game.set_flag("in_wagon")


func _s2_spotted(who: Actor) -> void:
	if Game.flag("s2_caught"):
		await _s2_dragged_out(who)
		return
	Game.set_flag("s2_caught")
	var r := s.a("player")
	if who:
		who.emote("!")
		who.face_toward(r.position)
	s.sfx("alert", 1.0, -2.0)
	r.jump_back()
	await s.say("guard", "Thief! In the camp! Lanterns, LANTERNS!", "angry")
	var res := await s.battle({
		"id": "s2_caught", "title": "Caught in the lanterns!", "bg": "camp", "music": "battle",
		"party": ["rook"],
		"enemies": [BattleDefs.enemy("guard"), BattleDefs.enemy("guard2", {"hp": 30})],
		"objective": {"kind": "escape", "turns": 2, "text": "SLIP AWAY:", "win_title": "BACK INTO THE DARK", "note": "He loses them among the tents."},
		"can_flee": true,
	})
	if res.outcome == "defeat":
		Game.set_flag("injured")
		await s.narrate("Rook takes a spear-butt to the ribs and rolls under a wagon. In the dark, one more shadow is easy to lose.")
	# the guard who saw him goes back to his round, and Rook ends up hidden
	# behind the west wagon (the screen is still dark after the fight, so
	# nobody sees anyone move). The camp is awake now: an extra lantern walks
	# the middle of the camp, the patrols are quicker and the alert lingers.
	if who and is_instance_valid(who):
		s.w.reset_guard(who)
	r.position = s.w.tile_center(S2_HIDE)
	r.face(1)
	r.set_pose("crouch")
	if s.w.actor("g4") == null:
		s.spawn("guard", Vector2i(13, 8), 2, {"id": "g4", "patrol": [Vector2i(13, 8), Vector2i(13, 12)], "vision": 50, "pause": 0.8})
	s.w.raise_alertness()
	s.w.alert = 0.0
	s.w.stealth_grace = 4.0
	s.sfx("crowd", 1.2, -10.0)
	await s.think(["Behind the west wagon, in the dark, with his heart going like a drum.",
		"The whole camp's awake now. Another lantern on the rounds, and they're walking faster. Get caught again and there won't be a fight. There'll be a rope."])
	r.set_pose("sneak")


## Where Rook hides after the first catch: in the wagon's shadow, out of the
## north patrol's light.
const S2_HIDE := Vector2i(6, 8)


func _s2_dragged_out(who: Actor) -> void:
	## Second catch: no second fight. The guards drag him to the fire, Wick
	## turns the camp upside down, and Rook gets into the cream wagon the ugly
	## way, bruised and loud.
	var w := s.w
	w.stealth = false
	w.alert = 0.0
	if w.alert_bar:
		w.alert_bar.visible = false
	var r := s.a("player")
	if who == null or not is_instance_valid(who):
		who = w.actor("g1")
	s.sfx("alert", 1.0, -2.0)
	who.emote("!")
	who.face_toward(r.position)
	r.jump_back()
	await s.say("guard", "HIM again! Don't let him run this time!", "angry")
	# the guard closes in and grabs him
	var grab := create_tween()
	grab.tween_property(who, "position", r.position + (who.position - r.position).limit_length(12.0), 0.35)
	await grab.finished
	s.sfx("hit", 0.8, -6.0)
	s.shake(2.0, 0.3)
	r.set_pose("hurt")
	Game.set_flag("injured")
	await s.narrate("A hand in his collar, a knee in his back. The lantern swings so close he can feel it on his face.")
	# dragged to the fire
	var fire := w.tile_center(Vector2i(17, 11))
	var drag := create_tween().set_parallel(true)
	drag.tween_property(r, "position", fire, 1.4).set_trans(Tween.TRANS_SINE)
	drag.tween_property(who, "position", fire + Vector2(-12, 0), 1.4).set_trans(Tween.TRANS_SINE)
	who.moving = true
	s.pan(fire, 1.0)
	await drag.finished
	who.moving = false
	r.set_pose("kneel")
	await s.say("guard", "Wake the Factor. He'll want to see what a cream thief looks like before we hang one.", "angry")
	await s.wait(0.4)
	# Wick: the loudest possible distraction
	s.sfx("crash", 1.0, -2.0)
	s.shake(3.0, 0.6)
	s.flash(Pal.CANDLE, 0.25)
	var wick := s.spawn("wick", Vector2i(2, 12), 1, {"id": "wick"})
	var ox := w.actor("ox")
	await s.say("wick", "(from the dark) STAMPEDE! Everybody MOVE! The oxen have seen a GHOST!", "shock")
	s.sfx("crowd", 1.4, -6.0)
	if ox:
		ox.visible = true
		var run_ox := create_tween()
		run_ox.tween_property(ox, "position", w.tile_center(Vector2i(26, 12)), 1.6)
		ox.moving = true
	var run_w := create_tween()
	run_w.tween_property(wick, "position", w.tile_center(Vector2i(12, 11)), 0.9)
	wick.moving = true
	for g in w.guards:
		var ga: Actor = g.actor
		if is_instance_valid(ga) and ga.visible:
			ga.emote("!")
			ga.face_toward(wick.position)
	await s.wait(0.9)
	wick.moving = false
	# Rook twists free in the confusion
	who.face_toward(wick.position)
	r.set_pose("dodge")
	r.jump_back()
	await s.say("wick", "Go, GO! I've got them!", "grin")
	var run_g := create_tween()
	run_g.tween_property(who, "position", wick.position + Vector2(-20, 0), 0.8)
	who.moving = true
	var run_w2 := create_tween()
	run_w2.tween_property(wick, "position", w.tile_center(Vector2i(2, 14)), 1.0)
	wick.moving = true
	r.set_pose("run")
	var dash := create_tween()
	dash.tween_property(r, "position", w.tile_center(Vector2i(29, 10)), 1.2).set_trans(Tween.TRANS_SINE)
	s.pan(w.tile_center(Vector2i(29, 10)), 1.0)
	await dash.finished
	s.hide("wick")
	who.moving = false
	if ox:
		ox.moving = false
	s.hide("h1")
	r.face(1)
	r.set_pose("pick")
	s.sfx("slash", 0.8, -4.0)
	await s.narrate(["Nobody's watching the cream wagon. Nobody's watching anything but an ox with a lantern on its horns.",
		"Rook doesn't bother with the lock. A knife through the canvas, a roll, and he's inside, bruised and breathing hard and very, very loud about it."])
	Game.set_flag("noise")
	Game.set_flag("approached")
	Game.choose("Caught twice at the Dry Well; Wick stampeded the oxen to get Rook into the cream wagon.")
	s.unmarker()
	Game.set_flag("in_wagon")


# ======================================================================
# S3 THE SEALED CHEST
# ======================================================================

func wagon_map() -> Dictionary:
	return {
		"id": "factor_wagon_in", "name": "The Factor's Wagon", "theme": "wagon", "music": "omen", "tint": Color(0.95, 0.85, 0.8),
		"rows": [
			"############",
			"############",
			"#pppppppppp#",
			"#pppppppppp#",
			"#pp,,,,,,pp#",
			"#pppppppppp#",
			"############",
		],
		"props": [
			{"kind": "desk", "tile": Vector2i(2, 2), "v": 0, "area": Rect2i(1, 2, 2, 1), "event": {"id": "desk"}},
			{"kind": "sealed_chest", "tile": Vector2i(6, 3), "v": 0, "area": Rect2i(5, 3, 3, 1), "id": "chest", "event": {"id": "chest"}},
			{"kind": "lantern", "tile": Vector2i(9, 2), "v": 0, "lift": 14, "area": Rect2i(), "light": Pal.CANDLE, "lr": 40, "pulse": 2.0},
			{"kind": "cushion", "tile": Vector2i(10, 4), "v": 0, "decal": true},
			{"kind": "pot", "tile": Vector2i(10, 2), "v": 1},
		],
		"npcs": [],
		"exits": [{"id": "out", "rect": Rect2i(4, 6, 4, 1)}],
	}


func scene_s3() -> Variant:
	scene = "S3"
	await s.explore(wagon_map(), Vector2i(5, 5), 1)
	s.lock(true)
	var r := s.a("player")
	await r.look_around()
	await s.think("No silk. No saffron. A desk, a cushion, a lantern that's still lit, and one long box wrapped in cream cloth and chain.")
	await s.think("The lantern's still lit. He was here a minute ago.")
	s.lock(false)
	s.marker(Vector2i(6, 4))
	await s.until(func() -> bool: return Game.flag("chest_open"))
	var choice := await s.choose("The blade lies in its cloth. Something about it is waiting.", [
		"Draw the sword.",
		"Get Fen. He'll know what this is.",
		"Leave it. Take the book and go."])
	match choice:
		0:
			Game.choose("Drew the sword from the sealed chest.")
			await _s3_draw()
		1:
			Game.choose("Called Fen to look at the sword instead of touching it.")
			await _s3_fen()
		2:
			Game.choose("Left the sword in its chest.")
			await _s3_leave()
	await _s3_escape()
	return "S4"


func _s3_examine(ev: Dictionary) -> void:
	match ev.get("id", ""):
		"desk":
			if Game.has_item("ledger"):
				await s.think("An empty desk. Very neat. Even the dust is arranged.")
				return
			s.sfx("paper", 1.0, -6.0)
			await s.think("A ledger, bound in cream leather. Columns of names. Beside each name, a date, and one word: KEPT.")
			await s.think("The oldest pages aren't in any language he knows. The newest entry is today's date. The name hasn't been filled in yet.")
			Game.give_item("ledger")
			Game.add_lore("factor_ledger")
			Game.add_clue("ledger")
			await s.think("And tucked in the back: a page of the Pass of Teeth, with a door drawn where the map shows only rock.")
		"chest":
			if Game.flag("chest_open"):
				return
			s.unmarker()
			var r := s.a("player")
			r.face(1)
			r.set_pose("pick")
			await s.think("Twelve wax seals. Each one stamped with a brass hand, fingers closed.")
			for k in 6:
				s.sfx("carve", 1.0 + k * 0.08, -8.0)
				r.shake(0.15)
				await s.wait(0.22)
			s.sfx("chest", 1.0, -4.0)
			var ch: Sprite2D = s.w.prop_sprite("chest")
			ch.texture = Art.prop("sealed_chest", 1)
			s.w.add_light(ch.position + Vector2(0, -8), 30, Pal.OMEN, 3.0)
			r.set_pose("walk")
			r.jump_back()
			s.music("omen", 0.5)
			# the blade presented: no hands, just the thing itself in violet light
			var c := await s.cine("omen_void", 0.5)
			c.effect = "omen"
			c.effect_k = 0.5
			var sw := c.sprite(Art.prop("sword_prop", 0), Vector2(160, 84), 2.0)
			sw.modulate.a = 0.0
			c.create_tween().tween_property(sw, "modulate:a", 1.0, 1.0)
			s.sfx("whisper", 0.8, -4.0)
			await s.narrate("A sword. Old, dark steel with a vein of violet light running down it. The guard is two brass hands, fingers curled, gripping the blade. In the pommel, a stone like a closed eye.")
			s.sfx("omen", 1.0, -4.0)
			await s.say("blade", "...There you are.")
			await s.think("Swords don't talk. Swords definitely don't talk.")
			await c.close(0.5)
			Game.set_flag("chest_open")
		_:
			await super.examine(ev)


func _s3_draw() -> void:
	Game.set_flag("has_sword")
	Game.set_pflag("drew_sword")
	Game.add("reliance", 1)
	Game.add("finesse", 1)
	var r := s.a("player")
	r.set_spec(s.rook_spec())
	r.face(0)
	r.set_pose("hold_up")
	s.sfx("sword_draw", 1.0, -2.0)
	s.flash(Pal.OMEN, 0.5)
	s.shake(2.0, 0.4)
	r.emote("!")
	await s.wait(0.5)
	# the first vision: what's about to happen
	var c := await s.cine("vision", 0.2)
	c.animate_bg("vision", 4, 6.0)
	s.sfx("vision", 1.0, -4.0)
	var rk := c.person("rook", Vector2(200, 150), 3, "shock", "hold_up")
	rk.set_spec(s.rook_spec())
	var hn := c.person("hunter", Vector2(60, 150), 2, "", "windup")
	await s.wait(0.4)
	await c.walk(hn, Vector2(160, 150), 140.0)
	hn.set_pose("strike")
	rk.set_pose("dodge")
	s.sfx("whiff", 1.0, -4.0)
	await s.wait(0.4)
	await s.narrate("For a heartbeat, he sees it: the door behind him opening, a cream-hooded hunter, the hook swinging for the back of his neck. He sees exactly where it will be.")
	await c.close(0.2)
	s.flash(Pal.WHITE, 0.2)
	# and then it happens, exactly as shown
	var h := s.spawn("hunter", Vector2i(5, 5), 1)
	h.set_pose("windup")
	s.sfx("door", 1.0, -4.0)
	await s.wait(0.15)
	h.set_pose("strike")
	r.set_pose("dodge")
	r.afterimage_field()
	s.sfx("whiff", 1.1, -2.0)
	await r.jump_back(12.0)
	r.face(0)
	r.set_pose("ready")
	await s.say("rook", "...I saw that. I SAW that before it happened.", "shock")
	await s.say("blade", "You will see a great deal more.")
	await s.say("hunter", "Bearer. Put it down. The Factor would like a word.", "")
	await s.say("", "In battle, SWORD opens the blade's arts. Foreknowledge shows what every enemy will do this round, without using your turn. The arts are strong and free. Each one raises Suspicion.", "", {"color": Pal.OMEN.lerp(Pal.WHITE, 0.5)})
	var res := await s.battle(_hunter_battle(["rook"]))
	s.w.remove_npc("hunter")
	if res.outcome == "defeat":
		Game.set_flag("injured")
		await s.narrate("They bring him down, but they won't touch the sword, and that hesitation is all he needs. He rolls out under the wagon.")


func _hunter_battle(party: Array, extra := {}) -> Dictionary:
	var d := {
		"id": "s3_hunters", "title": "The bearer wakes", "bg": "wagon", "music": "battle",
		"party": party,
		"enemies": [BattleDefs.enemy("hunter", {"hp": 32, "atk": 8}), BattleDefs.enemy("hunter", {"hp": 28, "atk": 7, "spd": 9})],
		"objective": {"kind": "defeat", "text": "BREAK OUT"},
		"victory_note": "The hunters go down without a sound. Somewhere outside, someone is walking toward the wagon. Unhurried.",
		"no_hostile": true,
	}
	d.merge(extra, true)
	return d


func _s3_fen() -> void:
	Game.add("fen", 1)
	Game.add("loyalty", 1)
	var r := s.a("player")
	await s.think("No. Not alone. Fen's seen everything once.")
	r.face(0)
	s.sfx("caw", 1.3, -4.0)
	await s.narrate("Rook gives the crow-call. A minute later, the old man climbs in through the cut canvas, cursing his knee in three languages.")
	var fen := s.spawn("fen", Vector2i(5, 5), 1)
	await s.walk("fen", [Vector2i(6, 4)], 30.0)
	fen.face(1)
	await s.wait(0.6)
	fen.set_mood("shock")
	fen.jump_back()
	await s.say("fen", "Close the box, Rook.", "shock")
	await s.say("rook", "What is it?", "")
	fen.gesture("point", 1.2)
	await s.say("fen", "That guard. The hands. I've seen hands like that once, cut into a grave in Varn. A man who robbed every caravan from here to the sea and died with nobody at his funeral.", "worried")
	await s.say("fen", "They said he kept a sword nobody else was allowed to touch.", "sad")
	Game.add_lore("fen_grave")
	s.sfx("door", 1.0, -4.0)
	var h := s.spawn("hunter", Vector2i(8, 5), 3)
	h.emote("!")
	await s.say("hunter", "Thieves. Step away from the cargo.", "")
	Game.set_flag("fen_fights")
	var res := await s.battle(_hunter_battle(["rook", "fen"], {"on_turn": func(b: Battle, turn: int) -> Dictionary:
		if turn == 2 and not Game.flag("has_sword"):
			await b.hide_ui()
			await b.say("fen", "Rook! Use it! It's the only edge we've got!", "angry")
			b.pose("fen", "throw", 0.5)
			Sfx.play("whiff", 1.0, -4.0)
			var rk := b.unit("rook")
			await b.projectile(b.unit("fen").center(), rk.center() + Vector2(0, -20), "omen", 0.35, 30.0)
			Game.set_flag("has_sword")
			Game.add("reliance", 1)
			rk.spec = Game.main.story.rook_spec()
			rk._key = ""
			rk.set_pose("victory", 0.8)
			Sfx.play("sword_draw", 1.0, -2.0)
			b.fk_charges = 3
			Game.main.flash(Pal.OMEN, 0.4, 0.6)
			b.fx.burst(rk.center(), 24, [Pal.OMEN, Pal.WHITE], Vector2(30, 90), Vector2(0.3, 0.6), {"shape": 1})
			await b.say("blade", "Hello again.")
			await b.say("", "SWORD is open: Foreknowledge and the blade's arts. Each art raises Suspicion.", "", {"color": Pal.OMEN.lerp(Pal.WHITE, 0.5)})
			await b.show_ui()
		return {}}))
	s.w.remove_npc("hunter")
	if res.outcome == "defeat":
		Game.set_flag("injured")
	s.a("player").set_spec(s.rook_spec())
	await s.say("fen", "...God help us. You're holding it like you've held it before.", "worried")


func _s3_leave() -> void:
	Game.add("refusals", 1)
	Game.set_pflag("left_sword")
	var r := s.a("player")
	await s.think("No. Fen said stay away from this wagon, and the box is talking. You don't argue with a box that talks. You leave.")
	r.face(0)
	if not Game.has_item("ledger"):
		Game.give_item("ledger")
		Game.add_lore("factor_ledger")
		Game.add_clue("ledger")
		await s.think("He takes the ledger from the desk on his way past. A thief has to leave with something.")
	await s.walk("player", [Vector2i(5, 5)], 50.0)
	var wick := s.spawn("wick", Vector2i(6, 5), 1)
	wick.hop(4.0)
	await s.say("wick", "Is it gold? Is it the goats? I'll just grab one thing!", "grin")
	await s.say("rook", "Wick, NO-", "shock")
	await s.walk("wick", [Vector2i(6, 4)], 70.0)
	await s.narrate("And then Wick is past him, both hands in the box.")
	# the blade takes to him at once
	wick.face(1)
	s.sfx("omen", 1.0, -4.0)
	s.flash(Pal.OMEN, 0.3)
	wick.set_spec(Data.spec("wick_sword"))
	wick.set_mood("omen")
	wick.hop(4.0)
	Game.set_flag("wick_sword")
	await s.wait(0.4)
	# and a hunter in the doorway
	s.sfx("door", 1.0, -4.0)
	var h := s.spawn("hunter", Vector2i(6, 6), 1, {"id": "hunter"})
	h.hop(6.0)
	r.emote("!")
	await s.say("hunter", "THIEVES! At the cargo!", "angry")
	await s.say("rook", "Out. OUT!", "shock")
	# they bowl past him and out into the night
	s.walk("wick", [Vector2i(5, 4), Vector2i(5, 5)], 110.0)
	await s.wait(0.15)
	h.hop(8.0)
	h.face(3)
	await s.walk("player", [Vector2i(4, 5)], 110.0)
	r.face(0)
	wick.face(0)
	for a in [r, wick]:
		a.create_tween().tween_property(a, "modulate:a", 0.0, 0.2)
	await s.wait(0.25)
	s.w.remove_npc("wick")
	s.w.remove_npc("hunter")
	r.visible = false
	# outside: the camp waking up, and Bracken coming at a run
	var c := await s.cine("night_camp", 0.4)
	c.animate_bg("night_camp", 4, 2.0)
	var rk := c.person("rook", Vector2(-20, 156), 2, "shock", "run")
	rk.set_spec(s.rook_spec())
	var wkc := c.person("wick_sword", Vector2(-50, 156), 2, "omen", "run")
	c.walk(rk, Vector2(170, 156), 140.0)
	await c.walk(wkc, Vector2(130, 156), 140.0)
	var foes := []
	for k in 3:
		var f := c.person("guard" if k == 1 else "hunter", Vector2(350 + k * 24, 156), 3, "angry", "run")
		c.walk(f, Vector2(236 + k * 26, 156), 120.0)
		foes.append(f)
	s.sfx("alert", 1.0, -4.0)
	await s.wait(0.6)
	var br := c.person("bracken", Vector2(-30, 156), 2, "angry", "run")
	await c.walk(br, Vector2(196, 156), 170.0)
	br.hop(6.0)
	await s.say("bracken", "Nobody lays a hook on the boy. Nobody.", "angry")
	await s.say("rook", "Wick, stay behind us!", "determined")
	var res := await s.battle({
		"id": "s3_wick", "title": "The hunters come running!", "bg": "camp", "music": "battle",
		"party": ["rook", "bracken"],
		"enemies": [BattleDefs.enemy("hunter"), BattleDefs.enemy("guard"), BattleDefs.enemy("hunter", {"hp": 40})],
		"objective": {"kind": "escape", "turns": 4, "text": "HOLD ON:", "win_title": "OUT OF THE CAMP", "note": "Wick runs with them, the blade in both hands, and he will not let go of it."},
		"can_flee": true, "no_hostile": true,
		"on_turn": func(b: Battle, turn: int) -> Dictionary:
			if turn == 2:
				await b.hide_ui()
				var wk := await b.add_unit("party", BattleDefs.member("wick_sword").merged({"ai": true}), Vector2(300, 112), 60.0)
				wk.set_mood("omen")
				Sfx.play("omen", 1.0, -2.0)
				Game.main.flash(Pal.OMEN, 0.4, 0.6)
				await b.say("wick", "I can see it. I can see where they're going to be. Rook, I can SEE it!", "omen")
				var e := b._first(b.enemies)
				if e:
					await b.omen_edge(wk, e, 3.0)
				await b.say("rook", "Wick... put it down.", "worried")
				await b.show_ui()
			return {},
	})
	if res.outcome == "defeat":
		Game.set_flag("injured")
	if is_instance_valid(r):
		r.visible = true
		r.modulate.a = 1.0


func _s3_escape() -> void:
	# out of the wagon, and the Factor waiting in the lantern light
	var c := await s.cine("night_camp", 0.4)
	c.animate_bg("night_camp", 4, 2.0)
	var factor := c.person("factor", Vector2(80, 158), 2)
	var rk := c.person("rook", Vector2(150, 158), 3, "shock")
	rk.set_spec(s.rook_spec())
	if Game.flag("wick_sword"):
		c.person("wick_sword", Vector2(190, 158), 3, "omen")
	await s.wait(0.4)
	await s.say("factor", "Ah. There you are.", "smile")
	await s.narrate("He doesn't shout. He doesn't reach for anything. He looks at Rook the way a man looks at a word he's been trying to remember.")
	await s.say("factor", "Please don't run. It only makes the road longer.", "")
	rk.set_mood("determined")
	rk.face(2)
	s.sfx("whiff", 1.0, -6.0)
	await c.walk(rk, Vector2(360, 158), 160.0)
	await s.say("factor", "...Well. They always run.", "")
	await c.close(0.5)
	# the run across the dunes
	var c2 := await s.cine("saltway", 0.4)
	c2.effect = "sand"
	c2.effect_k = 0.5
	s.music("battle", 0.6)
	var crew := []
	var ids := ["fen", "bracken", "rook"]
	if Game.flag("wick_sword"):
		ids.append("wick_sword")
	else:
		ids.append("wick")
	for i in ids.size():
		var a := c2.person(ids[i], Vector2(-30 - i * 30, 150 + (i % 2) * 8), 2, "", "run")
		if ids[i] == "rook":
			a.set_spec(s.rook_spec())
		crew.append(a)
	for a in crew:
		c2.walk(a, Vector2(380, a.position.y), 110.0)
	await s.wait(2.4)
	await s.narrate("They run until the camp's lanterns are pinpricks, and then until they're nothing. Nobody follows. That's the worst part. Nobody follows at all.")
	await c2.close(0.6)


# --------------------------------------------------------------- routing --

func talk(n: Actor) -> void:
	match scene:
		"P1":
			await _p1_talk(n)
		_:
			match n.info.get("who", ""):
				"ox":
					await s.say("ox", "Mrrrrh.", "")
				_:
					await s.think("Better not draw attention.")


func examine(ev: Dictionary) -> void:
	match scene:
		"P1":
			await _p1_examine(ev)
		"S1":
			if str(ev.get("id", "")).begins_with("listen_"):
				await _listen(str(ev.id).substr(7))
			else:
				await super.examine(ev)
		"S2":
			await _s2_examine(ev)
		"S3":
			await _s3_examine(ev)
		_:
			await super.examine(ev)


func trigger(id: String) -> void:
	if scene == "S2":
		await _s2_trigger(id)


func exit(e: Dictionary) -> void:
	match scene:
		"P1":
			await _p1_exit(e)
		"S2":
			await s.think("Not without what we came for.")
			await push_back()
		"S3":
			if not Game.flag("chest_open"):
				await s.think("Not yet. Not with that box sitting there.")
				await push_back()


func spotted(who: Actor) -> void:
	match scene:
		"S1":
			s.w.alert = 0.0
			await s.think("Down! He ducks behind the rocks before the guard looks twice.")
			s.w.player.position = s.w.tile_center(Vector2i(6, 5))
		"S2":
			await _s2_spotted(who)


func autoplay() -> void:
	var w := s.w
	match scene:
		"P1":
			if explore_extras():
				await _p1_talk(w.by_id.fen)
				await _p1_talk(w.by_id.bracken)
			await _p1_exit({})
		"S1":
			for id in ["guards", "ollo", "factor"]:
				if not Game.flag("heard_" + id):
					w.player.position = w.tile_center([Vector2i(10, 7), Vector2i(18, 6), Vector2i(26, 6)][["guards", "ollo", "factor"].find(id)])
					await _listen(id)
					return
		"S2":
			if Game.flag("ct_caught"):
				# test runs (CT_STATE=ct_caught): step into a lantern and
				# wait to be seen, so the caught paths get played
				var g: Actor = w.actor("g1")
				w.player.position = g.position + Actor.DIRS[g.dir] * 24.0
				w.player.visible = true
				w.release("autoplay")
				var t := 0.0
				while is_instance_valid(w) and not w.busy and t < 4.0:
					await get_tree().process_frame
					t += get_process_delta_time()
					if is_instance_valid(g):
						w.player.position = g.position + Actor.DIRS[g.dir] * 24.0
				if is_instance_valid(w):
					w.hold("autoplay")
				return
			w.stealth = false
			if explore_extras() and not Game.flag("looted"):
				await _s2_examine({"id": "stores"})
			if not Game.flag("approached"):
				w.player.position = w.tile_center(Vector2i(26, 10))
				await _s2_trigger("approach")
			else:
				await _s2_lock()
		"S3":
			if explore_extras() and not Game.has_item("ledger"):
				await _s3_examine({"id": "desk"})
			await _s3_examine({"id": "chest"})
