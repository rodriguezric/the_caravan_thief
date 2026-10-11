class_name BattleDefs
## Battle data: who can fight beside Rook (stats grow with the act and the
## thematic variables, not with EXP), their techniques, the blade's arts, and
## the enemies of the Saltway.
##
## Skill fields: name, desc, cost (TP), kind (dmg / heal / buff / debuff /
## steal / special), target (enemy / all / ally / self / party), power,
## anim (which choreography plays), sword (a sword art: costs no TP but raises
## Suspicion by `suspicion`), tier (minimum sword mastery), status effects.

const SKILLS := {
	# --- Rook --------------------------------------------------------------
	"quickcut": {"name": "Quickcut", "desc": "Three fast cuts. Each one weaker, all of them rude.", "cost": 4, "kind": "dmg", "target": "enemy", "power": 0.55, "hits": 3, "anim": "flurry"},
	"feint": {"name": "Feint", "desc": "Fake left, stab right. The target's guard drops for two turns.", "cost": 3, "kind": "dmg", "target": "enemy", "power": 0.8, "anim": "feint", "status": "exposed"},
	"grit": {"name": "Dirty Trick", "desc": "A fistful of road grit in the eyes. The target loses its next action.", "cost": 5, "kind": "debuff", "target": "enemy", "power": 0.3, "anim": "throw", "status": "dazed"},
	"tumble": {"name": "Tumble", "desc": "Roll out of reach. Rook dodges everything aimed at him until his next turn.", "cost": 3, "kind": "buff", "target": "self", "anim": "tumble", "status": "evasive"},
	# --- the blade's arts (Rook, once he carries it) ---------------------------
	"omen_edge": {"name": "Omen Edge", "desc": "See the opening before it opens. A certain critical strike.", "cost": 0, "kind": "dmg", "target": "enemy", "power": 1.5, "anim": "omen_edge", "sword": true, "suspicion": 1, "tier": 1, "crit": true},
	"parry_sight": {"name": "Parry Sight", "desc": "Watch the next blow coming and turn it back on whoever throws it.", "cost": 0, "kind": "buff", "target": "self", "anim": "parry", "sword": true, "suspicion": 1, "tier": 1, "status": "counter"},
	"thousand": {"name": "Thousand Hands", "desc": "Time stops for everyone but the bearer. Strikes every enemy.", "cost": 0, "kind": "dmg", "target": "all", "power": 1.3, "anim": "thousand", "sword": true, "suspicion": 2, "tier": 2},
	"mine": {"name": "Mine", "desc": "Take what they have. Drains life from the target into Rook.", "cost": 0, "kind": "dmg", "target": "enemy", "power": 1.4, "anim": "mine", "sword": true, "suspicion": 2, "tier": 3, "drain": 0.6},
	# --- Mara --------------------------------------------------------------
	"pin": {"name": "Pinning Shot", "desc": "An arrow through the shadow. The target's next turn comes much later.", "cost": 4, "kind": "dmg", "target": "enemy", "power": 0.9, "anim": "pin", "status": "pinned"},
	"volley": {"name": "Volley", "desc": "Five arrows into the sky, and down on every enemy.", "cost": 7, "kind": "dmg", "target": "all", "power": 0.7, "anim": "volley"},
	"dressing": {"name": "Field Dressing", "desc": "A scout's bandage, tight and fast. Restores HP to one ally.", "cost": 4, "kind": "heal", "target": "ally", "power": 34, "anim": "heal"},
	"cover": {"name": "Cover", "desc": "Mara stands in front of an ally and takes their next hit.", "cost": 3, "kind": "buff", "target": "ally", "anim": "cover", "status": "covered"},
	# --- Fen -----------------------------------------------------------------
	"caltrops": {"name": "Caltrops", "desc": "Iron spikes across the ground. Every enemy is hurt when it moves to act.", "cost": 4, "kind": "debuff", "target": "all", "anim": "caltrops", "status": "caltrops"},
	"old_tale": {"name": "Old Tale", "desc": "A long, distracting story. The target's attacks weaken for three turns.", "cost": 4, "kind": "debuff", "target": "enemy", "anim": "tale", "status": "weak"},
	"rally": {"name": "Rally", "desc": "\"Hold the line, you lot!\" Raises the whole crew's attack.", "cost": 6, "kind": "buff", "target": "party", "anim": "rally", "status": "rallied"},
	# --- Wick & Bracken ------------------------------------------------------
	"pebbles": {"name": "Pebble Storm", "desc": "Wick empties his pockets at everyone.", "cost": 4, "kind": "dmg", "target": "all", "power": 0.5, "anim": "pebbles"},
	"haymaker": {"name": "Haymaker", "desc": "Bracken winds up for a very long time. Worth it.", "cost": 5, "kind": "dmg", "target": "enemy", "power": 2.0, "anim": "haymaker"},
}

## Rook's arts in the order the SWORD menu lists them.
const SWORD_ARTS := ["omen_edge", "parry_sight", "thousand", "mine"]


static func act() -> int:
	## 0 = prologue & Act I, 1 = Act II, 2 = Act III.
	var i := Data.scene_index(str(Game.run.get("scene", "P1")))
	return 0 if i <= 3 else (1 if i <= 8 else 2)


static func member(id: String) -> Dictionary:
	var a := act()
	var fin := Game.v("finesse")
	match id:
		"rook":
			var skills := ["quickcut", "feint"]
			if a >= 1 or fin >= 3:
				skills.append("tumble")
			if a >= 1:
				skills.append("grit")
			return {"id": "rook", "name": "Rook", "spec": "rook_sword" if Game.flag("has_sword") else "rook", "hp": 58 + a * 22 + fin * 2,
				"tp": 12 + a * 4, "atk": 10 + a * 3 + fin / 2, "def": 3 + a, "spd": 12 + fin, "skills": skills, "style": "melee",
				"evade": 0.04 + fin * 0.02, "crit": 0.08 + fin * 0.015}
		"mara":
			var t := Game.v("mara")
			var skills := ["pin", "dressing"]
			if a >= 1:
				skills.append("volley")
			if t >= 2:
				skills.append("cover")
			return {"id": "mara", "name": "Mara", "spec": "mara", "hp": 66 + a * 22, "tp": 14 + a * 3, "atk": 10 + a * 3, "def": 3 + a,
				"spd": 10, "skills": skills, "style": "bow", "evade": 0.05, "crit": 0.1}
		"mara_rival":
			return {"id": "mara", "name": "Mara", "spec": "mara", "hp": 70, "tp": 10, "atk": 9, "def": 3, "spd": 11, "skills": [], "style": "bow"}
		"fen":
			return {"id": "fen", "name": "Old Fen", "spec": "fen", "hp": 52 + a * 16, "tp": 14 + a * 3, "atk": 7 + a * 2, "def": 4 + a,
				"spd": 7, "skills": ["caltrops", "old_tale", "rally"], "style": "melee", "evade": 0.03, "crit": 0.06}
		"wick":
			return {"id": "wick", "name": "Wick", "spec": "wick", "hp": 38 + a * 12, "tp": 10, "atk": 6 + a * 2, "def": 1 + a,
				"spd": 14, "skills": ["pebbles"], "style": "sling", "evade": 0.1, "crit": 0.05}
		"wick_sword":
			return {"id": "wick", "name": "Wick", "spec": "wick_sword", "hp": 44, "tp": 0, "atk": 13, "def": 2,
				"spd": 15, "skills": [], "style": "melee", "evade": 0.1, "crit": 0.25}
		"bracken":
			return {"id": "bracken", "name": "Bracken", "spec": "bracken", "hp": 92 + a * 26, "tp": 10, "atk": 12 + a * 3, "def": 5 + a,
				"spd": 6, "skills": ["haymaker"], "style": "melee", "evade": 0.0, "crit": 0.05}
	return {"id": id, "name": id.capitalize(), "spec": id, "hp": 40, "tp": 0, "atk": 6, "def": 1, "spd": 8, "skills": [], "style": "melee"}


## Enemy moves: name, power, kind (hit / multi / buff / debuff / heal / seal /
## drain / call / summon), target (one / all / bearer / self), fx, text.
static func enemy(kind: String, over: Dictionary = {}) -> Dictionary:
	var a := act()
	var d: Dictionary
	match kind:
		"jackal":
			d = {"name": "Jackal", "spec": "jackal", "hp": 24, "atk": 6, "def": 0, "spd": 13, "style": "melee",
				"moves": [{"name": "Bite", "power": 1.0, "fx": "bite"}, {"name": "Lunge", "power": 1.3, "fx": "bite", "weight": 0.5},
					{"name": "Howl", "kind": "buff", "status": "rallied", "target": "self", "fx": "howl", "weight": 0.4}],
				"ko": "flee", "steal": ""}
		"guard":
			d = {"name": "Caravan Guard", "spec": "guard", "hp": 34 + a * 18, "atk": 7 + a * 3, "def": 2 + a, "spd": 8, "style": "spear",
				"moves": [{"name": "Spear Thrust", "power": 1.1, "fx": "stab"}, {"name": "Shield Bash", "power": 0.8, "fx": "blunt", "status": "dazed", "chance": 0.25},
					{"name": "Brace", "kind": "buff", "status": "guarding", "target": "self", "weight": 0.4}],
				"ko": "down", "steal": "bread"}
		"guard2":
			d = enemy("guard")
			d.spec = "guard2"
		"hunter":
			d = {"name": "Cream Hunter", "spec": "hunter", "hp": 40 + a * 20, "atk": 8 + a * 3, "def": 2 + a, "spd": 11, "style": "melee",
				"moves": [{"name": "Hook Slash", "power": 1.0, "fx": "slash"}, {"name": "Hook and Pull", "power": 0.7, "fx": "slash", "status": "exposed"},
					{"name": "Mark the Bearer", "kind": "debuff", "target": "bearer", "status": "marked", "weight": 0.5, "text": "points a hook at the blade's bearer."}],
				"ko": "down", "steal": "salve", "focus": "bearer"}
		"hunter_captain":
			d = enemy("hunter")
			d.name = "Hunter Captain"
			d.hp = 90 + a * 30
			d.atk = 13 + a * 3
			d.scale = 2.2
			d.moves.append({"name": "Twin Hooks", "kind": "multi", "hits": 2, "power": 0.75, "fx": "slash", "weight": 0.8})
			d.steal = "tonic"
		"mara":
			d = {"name": "Mara", "spec": "mara", "hp": 72, "atk": 9, "def": 3, "spd": 12, "style": "bow", "nonlethal": true,
				"moves": [{"name": "Warning Shot", "power": 0.6, "fx": "arrow"}, {"name": "Pinning Shot", "power": 0.9, "fx": "arrow", "status": "pinned", "weight": 0.6},
					{"name": "Aim", "kind": "buff", "status": "aiming", "target": "self", "weight": 0.4, "text": "draws and holds. Her aim doesn't waver."}],
				"ko": "kneel", "steal": "letter"}
		"fen":
			d = {"name": "Old Fen", "spec": "fen", "hp": 80 + a * 20, "atk": 10 + a * 2, "def": 4, "spd": 7, "style": "melee", "nonlethal": true,
				"moves": [{"name": "Cane Rap", "power": 1.0, "fx": "blunt"}, {"name": "Old Tale", "kind": "debuff", "status": "weak", "weight": 0.5, "text": "starts telling a story. It's about you."},
					{"name": "Knife from the Boot", "power": 1.5, "fx": "stab", "weight": 0.5}],
				"ko": "kneel", "steal": ""}
		"factor":
			d = {"name": "The Factor", "spec": "factor_ledger", "hp": 240, "atk": 12, "def": 5, "spd": 9, "style": "magic", "boss": true, "scale": 2.2,
				"moves": [{"name": "Appraise", "kind": "debuff", "target": "bearer", "status": "marked", "fx": "seal", "text": "looks at the bearer the way one looks at a column of numbers."},
					{"name": "Debit", "power": 1.1, "fx": "seal", "kind": "drain", "text": "writes a figure in the ledger. Someone's strength leaves them."},
					{"name": "Seal", "kind": "seal", "target": "bearer", "fx": "seal", "text": "stamps a brass seal on the air. The blade will not answer for a while."},
					{"name": "Claim", "power": 1.6, "fx": "seal", "target": "bearer", "kind": "claim", "weight": 0.7, "text": "reaches for the bearer. The more the blade is used, the harder he pulls."}],
				"ko": "kneel", "steal": "ledger", "focus": "bearer"}
	d = d.duplicate(true)
	d.merge(over, true)
	d.kind = kind
	return d
