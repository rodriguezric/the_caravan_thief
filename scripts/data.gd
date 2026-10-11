class_name Data
## The cast (as specs for the one renderer), the things you can carry, the
## story's scenes and its endings. Everything the story refers to by id.

const ROOK_SKIN := Color("d2b394")

const CAST := {
	"rook": {"id": "rook", "name": "Rook", "voice": "rook", "style": "cropped", "narrow": true, "adult": true, "rope": true,
		"skin": ROOK_SKIN, "hair": Color("33283a"), "eye": Color("d8a040"), "top": Color("c8b08c"), "jacket": Color("4a6688"),
		"patches": true, "coat_long": true, "bottom": Color("8c7258"), "shoes": Color("4a3428"), "belt": true, "weapon": "dagger"},
	"rook_sword": {"id": "rook", "variant": "sword", "name": "Rook", "voice": "rook", "style": "cropped", "narrow": true, "adult": true, "rope": true,
		"skin": ROOK_SKIN, "hair": Color("33283a"), "eye": Color("d8a040"), "top": Color("c8b08c"), "jacket": Color("4a6688"),
		"patches": true, "coat_long": true, "bottom": Color("8c7258"), "shoes": Color("4a3428"), "belt": true, "weapon": "sword", "sheath": true},
	"mara": {"id": "mara", "name": "Mara", "voice": "mara", "style": "braid", "adult": true, "broad": true, "quiver": true,
		"skin": Color("b88a68"), "hair": Color("9a4e32"), "eye": Color("6a8a4a"), "top": Color("b89a6a"), "cloak": Color("55704a"),
		"bottom": Color("6a4a32"), "shoes": Color("4a3428"), "belt": true, "weapon": "bow"},
	"fen": {"id": "fen", "name": "Old Fen", "voice": "fen", "style": "short", "adult": true, "beard": true, "brass_tooth": true, "armor": true,
		"skin": Color("a88066"), "hair": Color("a39a8e"), "beardc": Color("c4bcb0"), "eye": Color("6c6672"), "top": Color("6a4a32"),
		"bottom": Color("5a4a40"), "shoes": Color("3b2c3c"), "weapon": "cane"},
	"factor": {"id": "factor", "name": "The Factor", "voice": "factor", "style": "bald", "adult": true, "tall": true,
		"skin": Color("d4b08c"), "hair": Color("d4b08c"), "eye": Color("8fa0a8"), "robe": Color("efe6d2"), "sashc": Color("a8844e"),
		"shoes": Color("c9b894"), "top": Color("efe6d2")},
	"factor_ledger": {"id": "factor", "variant": "ledger", "name": "The Factor", "voice": "factor", "style": "bald", "adult": true, "tall": true,
		"skin": Color("d4b08c"), "hair": Color("d4b08c"), "eye": Color("8fa0a8"), "robe": Color("efe6d2"), "sashc": Color("a8844e"),
		"shoes": Color("c9b894"), "top": Color("efe6d2"), "weapon": "ledger"},
	"wick": {"id": "wick", "name": "Wick", "voice": "wick", "style": "messy", "freckles": true,
		"skin": Color("e8ccb0"), "hair": Color("c06a34"), "eye": Color("5a7a5a"), "top": Color("6a6a40"), "bottom": Color("8c7258"),
		"shoes": Color("4a3428"), "hat": "floppy", "hatc": Color("7a5638"), "weapon": "sling"},
	"wick_sword": {"id": "wick", "variant": "sword", "name": "Wick", "voice": "wick", "style": "messy", "freckles": true,
		"skin": Color("e8ccb0"), "hair": Color("c06a34"), "eye": Color("5a7a5a"), "top": Color("6a6a40"), "bottom": Color("8c7258"),
		"shoes": Color("4a3428"), "hat": "floppy", "hatc": Color("7a5638"), "weapon": "sword"},
	"bracken": {"id": "bracken", "name": "Bracken", "voice": "bracken", "style": "bald", "adult": true, "big": true, "beard": true,
		"skin": Color("7c5640"), "hair": Color("33283a"), "beardc": Color("3b2c3c"), "top": Color("7a4a34"), "bottom": Color("4a3428"),
		"shoes": Color("2b1f2a"), "belt": true, "weapon": "club"},
	"dosha": {"id": "dosha", "name": "Dosha", "voice": "dosha", "style": "long", "adult": true, "earring": true, "jewel": true, "dress": true,
		"skin": Color("9a7058"), "hair": Color("2b1f2a"), "eye": Color("b08a3e"), "top": Color("8e4652"), "bottom": Color("3c2a46"),
		"shoes": Color("3c2a46"), "hat": "scarf", "hatc": Color("5a4470")},
	"ollo": {"id": "ollo", "name": "Ollo", "voice": "ollo", "style": "short", "adult": true, "big": true, "mustache": true, "sash": true, "sashc": Color("a63a32"),
		"skin": Color("d2a884"), "hair": Color("4a3428"), "top": Color("b8703a"), "bottom": Color("6a4a32"), "shoes": Color("4a3428"),
		"hat": "turban", "hatc": Color("d8c8a0")},
	"guard": {"id": "guard", "name": "Caravan Guard", "voice": "man", "style": "short", "adult": true, "belt": true,
		"skin": Color("c09a78"), "hair": Color("4a3428"), "top": Color("b08a5e"), "bottom": Color("5a4a40"), "shoes": Color("3b2c3c"),
		"hat": "helm", "hatc": Color("7c8088"), "weapon": "spear"},
	"guard2": {"id": "guard2", "name": "Caravan Guard", "voice": "man", "style": "short", "adult": true, "belt": true, "mustache": true,
		"skin": Color("9a7058"), "hair": Color("2b1f2a"), "top": Color("a07a52"), "bottom": Color("4a3a32"), "shoes": Color("3b2c3c"),
		"hat": "helm", "hatc": Color("6c6672"), "weapon": "spear"},
	"hunter": {"id": "hunter", "name": "Cream Hunter", "voice": "hunter", "style": "short", "adult": true, "mask": true, "maskc": Color("e6dcc6"),
		"skin": Color("c8a888"), "hair": Color("4a3428"), "top": Color("d8c8a8"), "bottom": Color("8c7258"), "shoes": Color("4a3428"),
		"hat": "hood", "hatc": Color("e6dcc6"), "sash": true, "sashc": Color("b8a888"), "weapon": "hook"},
	"pilgrim": {"id": "pilgrim", "name": "Ysa", "voice": "woman", "style": "long", "adult": true, "dress": true,
		"skin": Color("c8a080"), "hair": Color("5a3a2a"), "top": Color("7a6a88"), "bottom": Color("3c2a46"), "shoes": Color("4a3428"),
		"hat": "scarf", "hatc": Color("a39a8e")},
	"pilgrim_kid": {"id": "pilgrim_kid", "name": "Tam", "voice": "kid", "style": "messy",
		"skin": Color("c8a080"), "hair": Color("5a3a2a"), "top": Color("8fa0a8"), "bottom": Color("6c6672"), "shoes": Color("4a3428")},
	"priest": {"id": "priest", "name": "Brother Amsel", "voice": "old", "style": "bald", "adult": true, "beard": true, "beardc": Color("d2c09a"),
		"skin": Color("b88a68"), "hair": Color("b88a68"), "robe": Color("6c6672"), "sashc": Color("a39a8e"), "shoes": Color("4a3428"), "top": Color("6c6672")},
	"bearer": {"id": "bearer", "name": "A Memory", "voice": "factor", "style": "ponytail", "adult": true, "ghost": true, "armor": true,
		"skin": Color("d2b394"), "hair": Color("4a3428"), "top": Color("6c6672"), "bottom": Color("4a3a32"), "shoes": Color("3b2c3c"), "weapon": "sword"},
	"townsman": {"id": "townsman", "name": "Townsman", "voice": "man", "style": "short", "adult": true,
		"skin": Color("c09a78"), "hair": Color("6a4a32"), "top": Color("687c5c"), "bottom": Color("5a4a40"), "shoes": Color("4a3428")},
	"townswoman": {"id": "townswoman", "name": "Townswoman", "voice": "woman", "style": "bun", "adult": true, "apron": true,
		"skin": Color("e0c4a6"), "hair": Color("9a4e32"), "top": Color("8e4652"), "bottom": Color("5a4470"), "shoes": Color("4a3428"), "skirt": true},
	"jackal": {"id": "jackal", "kind": "jackal", "name": "Jackal", "voice": "beast"},
	"crow": {"id": "crow", "kind": "crow", "name": "Crow", "voice": "crow"},
	"ox": {"id": "ox", "kind": "ox", "name": "Ox", "voice": "beast"},
}

## Things that can be carried. weight limits what can be grabbed at once;
## evidence is how badly it gives Rook away; owner is who it can go back to.
const ITEMS := {
	"purse": {"name": "Ollo's Purse", "desc": "Fat with silver. Embroidered OLLO, in case anyone wondered.", "value": 30, "weight": 1, "evidence": 1, "owner": "ollo"},
	"seal_ring": {"name": "Silver Seal-Ring", "desc": "A merchant's seal. Without it Ollo can't sign for goods at the border.", "value": 45, "weight": 0, "evidence": 3, "owner": "ollo", "key": true},
	"saffron": {"name": "Saffron Box", "desc": "A lacquered box of saffron threads. Worth more than the wagon carrying it.", "value": 40, "weight": 2, "evidence": 1, "owner": "ollo"},
	"silk": {"name": "Bolt of Dyed Silk", "desc": "Violet silk from the far coast. Heavy, beautiful, very noticeable.", "value": 50, "weight": 3, "evidence": 2, "owner": "ollo"},
	"icon": {"name": "Pilgrim's Icon", "desc": "A painted wooden saint, worn smooth by a family's hands. Worth almost nothing to anyone else.", "value": 8, "weight": 1, "evidence": 1, "owner": "pilgrim", "key": true},
	"ledger": {"name": "The Factor's Ledger", "desc": "Columns of names, each with a date and a single word: KEPT. The oldest pages are not in any language you know.", "value": 0, "weight": 1, "evidence": 3, "owner": "factor", "lore": true},
	"map": {"name": "Map Scrap", "desc": "Half a map of the Pass of Teeth. Someone has drawn a door where there is only rock.", "value": 0, "weight": 0, "evidence": 0, "lore": true},
	"poster": {"name": "Wanted Poster", "desc": "THE CARAVAN THIEF. 50 CROWNS. The drawing makes his nose much bigger than it is.", "value": 0, "weight": 0, "evidence": 1},
	"letter": {"name": "Mara's Letter", "desc": "To her sister in Velt. It is mostly about how badly she sleeps on the road.", "value": 0, "weight": 0, "evidence": 0, "owner": "mara"},
	"payroll": {"name": "Caravan Payroll", "desc": "Three months of wages for every guard on the Saltway. A legend's worth of coin.", "value": 300, "weight": 3, "evidence": 3, "owner": "ollo"},
}

## Battle items (consumable). heal: HP; tp: technique points.
const SUPPLIES := {
	"bread": {"name": "Road Bread", "desc": "Hard as a brick. Restores 18 HP.", "heal": 18, "target": "ally"},
	"salve": {"name": "Herb Salve", "desc": "Mara's recipe. Restores 40 HP.", "heal": 40, "target": "ally"},
	"tonic": {"name": "Bitter Tonic", "desc": "Tastes of tree bark. Restores 12 TP.", "tp": 12, "target": "ally"},
	"smoke": {"name": "Smoke Pellet", "desc": "A cloud to vanish into. The whole party is much harder to hit for a turn.", "smoke": true, "target": "party"},
	"sand": {"name": "Pouch of Grit", "desc": "Thrown in the eyes. The target loses its next action.", "stun": 1, "target": "enemy"},
}

## The story's spine. Each scene is played by a method on the Story director.
const SCENES := [
	{"id": "P1", "act": "Prologue", "title": "Rope Burns", "place": "The Waystation", "time": "Dawn"},
	{"id": "S1", "act": "Act I: Invitation", "title": "The Broken Wheel", "place": "The Saltway", "time": "Afternoon"},
	{"id": "S2", "act": "Act I: Invitation", "title": "The Dry Well", "place": "Caravan Camp", "time": "Night"},
	{"id": "S3", "act": "Act I: Invitation", "title": "The Sealed Chest", "place": "The Factor's Wagon", "time": "Night"},
	{"id": "S4", "act": "Act II: Reliance", "title": "The Rookery", "place": "The Ruined Watchtower", "time": "Night"},
	{"id": "S5", "act": "Act II: Reliance", "title": "Kesh Crossing", "place": "The Border Market", "time": "Morning"},
	{"id": "S6", "act": "Act II: Reliance", "title": "Campfire Accusation", "place": "The Hill Road", "time": "Night"},
	{"id": "S7", "act": "Act II: Reliance", "title": "The Shrine of the Unnamed", "place": "The High Path", "time": "Dusk"},
	{"id": "S8", "act": "Act II: Reliance", "title": "Fen's Bargain", "place": "The Rookery", "time": "Night"},
	{"id": "S9", "act": "Act III: Dominion", "title": "The Bridge Ambush", "place": "Gorge Bridge", "time": "Morning"},
	{"id": "S10", "act": "Act III: Dominion", "title": "Teeth of the Pass", "place": "The Pass of Teeth", "time": "Night"},
	{"id": "S11", "act": "Act III: Dominion", "title": "No Thief Can Reach", "place": "The Tomb Door", "time": "Dawn"},
]

## Endings, in gallery order: [key, name, how (hint), sword's fate].
const ENDINGS := [
	["legendary", "The Legendary Thief", "Trust the blade more than anyone. Keep it, and beat everyone who tries to take it.", "Kept by Rook, his only companion."],
	["honor", "Honor Among Thieves", "Trust your crew, tell them the truth, protect them at the bridge, and give the blade to the one who would carry it.", "Carried away by Mara."],
	["vault", "The Unreachable Vault", "Learn what the Factor knows, follow every clue to the door in the Pass, and hide the blade where no thief can reach.", "Sealed in a tomb Rook built."],
	["empty", "Empty Hands", "Give back what you took, refuse the blade twice, and leave without killing anyone you love.", "Left behind in its chest, on the road."],
	["fence", "The Fence's Price", "Sell it. Everything has a price.", "Sold across the border."],
	["claimed", "The Bearer Claimed", "Keep it, without the strength or the friends to keep it.", "Still in the caravan, with a new custodian."],
]

const MARKS := {"name": "ROOK, scratched into the guard", "crow": "a crow, scratched into the guard", "": "unmarked"}


static func spec(id: String) -> Dictionary:
	return CAST.get(id, {"id": id, "name": id.capitalize()})


static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {"name": id.capitalize(), "desc": "", "value": 0, "weight": 0, "evidence": 0})


static func scene(id: String) -> Dictionary:
	for s in SCENES:
		if s.id == id:
			return s
	return SCENES[0]


static func scene_index(id: String) -> int:
	for i in SCENES.size():
		if SCENES[i].id == id:
			return i
	return 0


static func ending(key: String) -> Array:
	for e in ENDINGS:
		if e[0] == key:
			return e
	return ["", "", "", ""]
