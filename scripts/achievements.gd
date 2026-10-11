class_name Achievements
## Every achievement and the checks that award them (Protektor's pattern, as in
## Pumpkin Man): definitions are data, progress is derived from the profile,
## the run and a few running stats, and check() is cheap enough to call after
## anything happens.

const CATS := ["endings", "choices", "battle", "craft"]
const CAT_NAMES := {"endings": "ENDINGS", "choices": "CHOICES", "battle": "BATTLE", "craft": "THIEVERY"}

## [id, category, icon, name, description]. Most are checked against flags
## (profile flags set by the story) of the same id.
const LIST := [
	["all_endings", "endings", "crown", "Every Way It Ends", "See all six endings."],
	["legacy_3", "endings", "book", "Sword Stories", "Leave three legacy records for the blade."],
	["drew_sword", "choices", "sword", "The Blade Answers", "Draw the sword from the sealed chest."],
	["left_sword", "choices", "chest", "Not Mine", "Leave the sword where you found it."],
	["dominion", "choices", "eye", "Dominion", "Rely on the blade until it relies on you."],
	["signed", "choices", "carve", "A Name That Outlives You", "Carve your name into the blade."],
	["confessed", "choices", "heart", "Say It Out Loud", "Tell Mara what the blade shows you."],
	["searched", "choices", "bag", "Light Fingers, Heavy Heart", "Go through Mara's things while she sleeps."],
	["honest", "choices", "hand", "Give It Back", "Return three stolen things to their owners."],
	["poster", "choices", "poster", "Fifty Crowns", "Keep your own wanted poster."],
	["lore_all", "choices", "book", "The Custodian's Secret", "Learn everything the Factor will tell you."],
	["memory", "choices", "ghost", "Someone Else's Memory", "Lay the blade on the shrine and remember."],
	["clues", "choices", "door", "A Door Where There Is Only Rock", "Find all three clues to the vault."],
	["protector", "choices", "shield", "Nobody Left Behind", "Get the whole crew across the bridge."],
	["payroll", "choices", "coin", "A Legend's Wages", "Seize the caravan payroll at the bridge."],
	["pursuer", "choices", "boot", "After Him", "Chase the Factor across the bridge."],
	["mara_trust", "choices", "bow", "She Watches Your Back", "Earn Mara's complete trust."],
	["fen_trust", "choices", "tooth", "Like a Son", "Earn Old Fen's complete trust."],
	["paranoid", "choices", "eye", "Everyone Is a Thief", "Let Suspicion consume you completely."],
	["clean", "choices", "hand", "Clean Hands", "Reach an ending without killing anyone."],
	["talked_down", "battle", "bow", "Lower the Bow", "Talk Mara down at the gate instead of fighting her."],
	["fk_10", "battle", "eye", "Seen It Coming", "Use Foreknowledge 10 times.", "foreknowledge", 10],
	["thousand", "battle", "sword", "Thousand Hands", "Unleash the blade's Thousand Hands."],
	["assists_5", "battle", "heart", "Thick as Thieves", "Have allies leap to your aid 5 times.", "assists", 5],
	["untouchable", "battle", "shield", "Untouchable", "Win a battle without taking a scratch."],
	["steal_5", "battle", "coin", "Pockets", "Steal from 5 enemies mid-fight.", "steals", 5],
	["fail_forward", "battle", "skull", "Get Back Up", "Lose a fight and carry on anyway."],
	["turned", "battle", "eye", "The Blade Chose", "Strike a friend the blade showed you as a thief."],
	["escaped", "battle", "boot", "Out the Back", "Win a fight by getting away."],
	["ghost", "craft", "mask", "Ghost of the Dry Well", "Reach the Factor's wagon without being seen."],
	["lock_perfect", "craft", "lock", "Locksmith", "Pick a lock without a single slip."],
	["pick_perfect", "craft", "hand", "Featherlight", "Lift a purse without a twitch."],
	["loot_full", "craft", "bag", "Greedy Hands", "Fill your bag to the last ounce."],
]


static func defs() -> Array:
	if Engine.has_meta("ct_achievement_defs"):
		return Engine.get_meta("ct_achievement_defs")
	var d := []
	for i in Data.ENDINGS.size():
		var e: Array = Data.ENDINGS[i]
		d.append({"id": "end_" + e[0], "cat": "endings", "icon": "ending", "slot": i, "name": e[1], "desc": e[2]})
	for a in LIST:
		var a2 := {"id": a[0], "cat": a[1], "icon": a[2], "name": a[3], "desc": a[4]}
		if a.size() > 5:
			a2.stat = a[5]
			a2.target = a[6]
		d.append(a2)
	d[Data.ENDINGS.size()].stat = "endings"
	d[Data.ENDINGS.size()].target = Data.ENDINGS.size()
	d[Data.ENDINGS.size() + 1].stat = "legacy"
	d[Data.ENDINGS.size() + 1].target = 3
	Engine.set_meta("ct_achievement_defs", d)
	return d


static func find(id: String) -> Dictionary:
	for a in defs():
		if a.id == id:
			return a
	return {}


static func stat(name: String) -> int:
	match name:
		"endings":
			return Game.profile.endings.size()
		"legacy":
			return Game.profile.legacy.size()
		"foreknowledge", "assists", "steals":
			return int(Game.profile.records.get(name, 0))
	return int(Game.achv_stats.get(name, 0))


static func progress(a: Dictionary) -> Array:
	if a.has("stat"):
		return [mini(stat(a.stat), int(a.target)), int(a.target)]
	return []


static func check() -> void:
	for a in defs():
		if Game.has_achievement(a.id):
			continue
		if _met(a):
			Game.unlock_achievement(a.id)


static func _met(a: Dictionary) -> bool:
	var id: String = a.id
	if a.has("stat") and a.has("target"):
		return stat(a.stat) >= int(a.target)
	if id.begins_with("end_"):
		return Game.has_ending(id.substr(4))
	if not Game.run.is_empty():
		match id:
			"dominion":
				if Game.tier() >= 3:
					return true
			"honest":
				if Game.run.get("returned", []).size() >= 3:
					return true
			"mara_trust":
				if Game.v("mara") >= 6:
					return true
			"fen_trust":
				if Game.v("fen") >= 6:
					return true
			"lore_all":
				if Game.lore_count() >= 3:
					return true
			"clues":
				if Game.run.get("clues", []).size() >= 3:
					return true
	return Game.pflag(id)
