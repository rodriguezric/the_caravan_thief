extends Node
## Game state autoload.
## - profile: what carries across playthroughs (endings seen, legacy records,
##   the last route, records, lines already read). Its own file.
## - achievements: unlocked ids + running stats (Protektor's pattern). Own file.
## - settings: audio, accessibility, battle speed. Own file; resetting it never
##   touches progress.
## - run: the playthrough in progress: the thematic variables, relationships,
##   flags, what Rook carries, and the decisions made. Saved at the start of
##   every scene (Continue picks up there).

const PROFILE_PATH := "user://caravan_profile.json"
const SAVE_PATH := "user://caravan_save.json"
const ACH_PATH := "user://caravan_achievements.json"
const SETTINGS_PATH := "user://caravan_settings.json"
const DEFAULT_SETTINGS := {"master": 0.8, "music": 0.7, "sfx": 0.8, "voice": 0.7, "reduced_motion": false, "text_speed": 1,
	"battle_speed": 0, "shake": true}

## Thematic variables and relationships, with their ranges.
const VARS := {"finesse": [0, 10], "suspicion": [0, 10], "loyalty": [0, 10], "mara": [-5, 6], "fen": [-5, 6],
	"reliance": [0, 20], "refusals": [0, 5], "coin": [0, 9999], "fk_uses": [0, 999]}
const VAR_NAMES := {"finesse": "FINESSE", "suspicion": "SUSPICION", "loyalty": "LOYALTY", "mara": "MARA'S TRUST", "fen": "FEN'S TRUST",
	"reliance": "SWORD RELIANCE", "refusals": "REFUSAL", "coin": "COIN"}

var main: Node
## The window shell (game picture + touch controls).
var shell: Node
var touch_active := false
var touch_layout := ""
var touch_running := false
var touch_tilt := ""
var profile := {}
var achieved := {}
var achv_stats := {}
var settings := {}
## True for automated test runs: nothing is written unless CT_DIR points somewhere.
var testing := false

# --- the current run -----------------------------------------------------
var run := {}
var play_started := 0.0


func _ready() -> void:
	testing = OS.get_environment("CT_TEST") != ""
	load_settings()
	load_profile()
	load_achievements()
	apply_settings()


func _path(p: String) -> String:
	## Test runs keep their files in a scratch directory (CT_DIR).
	var d := OS.get_environment("CT_DIR")
	return p if d == "" else d.path_join(p.get_file())


func _can_write() -> bool:
	return not testing or OS.get_environment("CT_DIR") != ""


# ----------------------------------------------------------------- profile --

func _default_profile() -> Dictionary:
	return {"endings": {}, "flags": {}, "legacy": [], "last_route": {}, "read": {}, "runs": 0, "finished": 0,
		"records": {"battles": 0, "won": 0, "lost": 0, "fled": 0, "damage": 0, "taken": 0, "sword_skills": 0, "foreknowledge": 0,
			"assists": 0, "locks": 0, "picks": 0, "play_time": 0.0, "steals": 0, "spared": 0},
		"best": {}}


func load_profile() -> void:
	profile = _default_profile()
	var d = _read_json(_path(PROFILE_PATH))
	if d is Dictionary:
		# tolerate missing fields after updates: merge over the defaults
		for k in d:
			if profile.has(k) and typeof(profile[k]) == typeof(d[k]):
				if profile[k] is Dictionary:
					(profile[k] as Dictionary).merge(d[k], true)
				else:
					profile[k] = d[k]


func save_profile() -> void:
	if _can_write():
		_write_json(_path(PROFILE_PATH), profile)


func pflag(name: String) -> bool:
	return profile.flags.get(name, false)


func set_pflag(name: String, value: bool = true) -> void:
	## Permanent discoveries that outlive a playthrough.
	if profile.flags.get(name, false) == value:
		return
	profile.flags[name] = value
	save_profile()
	Achievements.check()


func has_ending(key: String) -> bool:
	return profile.endings.has(key)


func endings_found() -> int:
	return profile.endings.size()


func record(name: String, n: int = 1) -> void:
	var r: Dictionary = profile.records
	r[name] = int(r.get(name, 0)) + n


func best(game: String) -> int:
	return int(profile.best.get(game, 0))


func record_minigame(game: String, score: int) -> void:
	if score > best(game):
		profile.best[game] = score
	save_profile()


func record_battle(summary: Dictionary) -> void:
	record("battles")
	match summary.get("outcome", ""):
		"victory", "objective":
			record("won")
		"defeat":
			record("lost")
		"fled", "escaped":
			record("fled")
	record("damage", int(summary.get("dealt", 0)))
	record("taken", int(summary.get("taken", 0)))
	save_profile()
	Achievements.check()


func mark_read(key: String) -> void:
	profile.read[key] = 1


func is_read(key: String) -> bool:
	return profile.read.has(key)


func _add_play_time() -> void:
	if play_started > 0.0:
		var now := Time.get_ticks_msec() / 1000.0
		profile.records.play_time = float(profile.records.play_time) + (now - play_started)
		play_started = now


func clear_progress() -> void:
	profile = _default_profile()
	achieved = {}
	achv_stats = {}
	save_profile()
	save_achievements()
	clear_save()


func clear_all() -> void:
	clear_progress()
	settings = DEFAULT_SETTINGS.duplicate()
	save_settings()
	apply_settings()


# --------------------------------------------------------------------- run --

func new_run() -> void:
	run = {"scene": "P1", "vars": {"finesse": 1, "suspicion": 0, "loyalty": 2, "mara": 0, "fen": 2, "reliance": 0, "refusals": 0, "coin": 12, "fk_uses": 0},
		"flags": {}, "items": [], "returned": [], "sold": [], "lore": [], "clues": [], "mark": "",
		"supplies": {"bread": 3, "smoke": 1}, "choices": [], "battles": {}, "kills": [], "time": 0.0}
	profile.runs = int(profile.runs) + 1
	play_started = Time.get_ticks_msec() / 1000.0
	save_profile()


func has_save() -> bool:
	return FileAccess.file_exists(_path(SAVE_PATH))


func save_run() -> void:
	## Called at the start of every scene.
	_add_play_time()
	save_profile()
	if _can_write() and not run.is_empty():
		_write_json(_path(SAVE_PATH), run)


func load_run() -> bool:
	var d = _read_json(_path(SAVE_PATH))
	if not d is Dictionary:
		return false
	new_run()
	profile.runs = maxi(0, int(profile.runs) - 1)
	for k in d:
		run[k] = d[k]
	# JSON gives floats back; keep the variables whole numbers
	for k in run.vars:
		run.vars[k] = int(run.vars[k])
	for k in run.supplies:
		run.supplies[k] = int(run.supplies[k])
	play_started = Time.get_ticks_msec() / 1000.0
	return true


func clear_save() -> void:
	var p := _path(SAVE_PATH)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(p)


func save_summary() -> String:
	## One line for the Continue option: where you are and when.
	var d = _read_json(_path(SAVE_PATH))
	if not d is Dictionary:
		return ""
	var s := Data.scene(str(d.get("scene", "P1")))
	return "%s: %s" % [s.act.split(":")[0], s.title]


func v(name: String) -> int:
	return int(run.get("vars", {}).get(name, 0))


func add(name: String, n: int, quiet: bool = false) -> void:
	## Change a thematic variable or relationship. Shows a small rising note
	## so choices visibly land, unless quiet.
	if n == 0:
		return
	var r: Array = VARS.get(name, [-999, 999])
	var before := v(name)
	var after := clampi(before + n, r[0], r[1])
	run.vars[name] = after
	if not quiet and after != before and main and main.has_method("stat_note"):
		main.stat_note(name, after - before)
	if name == "suspicion" and after >= 10:
		set_pflag("paranoid")
	Achievements.check()


func flag(name: String) -> bool:
	return bool(run.get("flags", {}).get(name, false))


func set_flag(name: String, value = true) -> void:
	run.flags[name] = value


func fval(name: String, default = "") -> Variant:
	return run.get("flags", {}).get(name, default)


func bump_talk(key: String) -> int:
	## Counts conversations with someone this scene (for varied repeat lines).
	var k := int(run.flags.get("talk_" + key, 0)) + 1
	run.flags["talk_" + key] = k
	return k


func tier() -> int:
	## Sword mastery: 0 none, 1 Invitation, 2 Reliance, 3 Dominion.
	if not flag("has_sword"):
		return 0
	var r := v("reliance") + v("suspicion") / 2
	if r >= 8:
		return 3
	if r >= 4:
		return 2
	return 1


func tier_name() -> String:
	return ["Unclaimed", "Invitation", "Reliance", "Dominion"][tier()]


func hostile_allies() -> bool:
	## At high Suspicion the blade shows Rook his friends as thieves.
	return v("suspicion") >= 6


func has_item(id: String) -> bool:
	return run.get("items", []).has(id)


func give_item(id: String) -> void:
	if not has_item(id):
		run.items.append(id)
		if main and main.has_method("item_note"):
			main.item_note(id, true)


func take_item(id: String) -> void:
	run.items.erase(id)


func return_item(id: String) -> void:
	## Give a stolen thing back to its owner.
	if has_item(id):
		run.items.erase(id)
		if not run.returned.has(id):
			run.returned.append(id)
		Achievements.check()


func sell_item(id: String) -> int:
	if not has_item(id):
		return 0
	run.items.erase(id)
	run.sold.append(id)
	var val := int(Data.item(id).get("value", 0))
	add("coin", val, true)
	return val


func weight() -> int:
	var w := 0
	for id in run.get("items", []):
		w += int(Data.item(id).get("weight", 0))
	return w


func evidence() -> int:
	var e := 0
	for id in run.get("items", []):
		e += int(Data.item(id).get("evidence", 0))
	return e


func supply(id: String) -> int:
	return int(run.get("supplies", {}).get(id, 0))


func add_supply(id: String, n: int = 1) -> void:
	run.supplies[id] = maxi(0, supply(id) + n)


func add_lore(id: String) -> void:
	if not run.lore.has(id):
		run.lore.append(id)
		if main and main.has_method("lore_note"):
			main.lore_note(id)
		Achievements.check()


func add_clue(id: String) -> void:
	if not run.clues.has(id):
		run.clues.append(id)
		if main and main.has_method("lore_note"):
			main.lore_note("clue")
		Achievements.check()


func lore_count() -> int:
	return run.get("lore", []).filter(func(x): return str(x).begins_with("factor")).size()


func choose(text: String) -> void:
	## Remember a decision for the route summary.
	run.choices.append({"scene": run.get("scene", ""), "text": text})


func killed(who: String) -> void:
	if not run.kills.has(who):
		run.kills.append(who)


func record_ending(key: String, extra: Dictionary) -> bool:
	## Returns true if this ending is new. Writes the legacy record and the
	## route summary, and clears the save.
	var fresh: bool = not profile.endings.has(key)
	if fresh:
		profile.endings[key] = int(Time.get_unix_time_from_system())
	profile.finished = int(profile.finished) + 1
	var e := Data.ending(key)
	var legacy := {"ending": key, "name": e[1], "sword": extra.get("sword", e[3]), "bearer": extra.get("bearer", ""),
		"bond": extra.get("bond", ""), "mark": Data.MARKS.get(run.get("mark", ""), "unmarked"), "lore": run.get("lore", []).size(),
		"time": int(Time.get_unix_time_from_system())}
	profile.legacy.append(legacy)
	profile.last_route = {"ending": key, "choices": run.get("choices", []), "vars": run.get("vars", {}).duplicate(),
		"returned": run.get("returned", []), "lore": run.get("lore", []), "clues": run.get("clues", []), "kills": run.get("kills", []),
		"eligible": extra.get("eligible", [])}
	_add_play_time()
	save_profile()
	clear_save()
	Achievements.check()
	return fresh


# ------------------------------------------------------------ achievements --

func has_achievement(id: String) -> bool:
	return achieved.has(id)


func unlock_achievement(id: String) -> void:
	if achieved.has(id):
		return
	achieved[id] = int(Time.get_unix_time_from_system())
	save_achievements()
	if main and main.has_method("toast_achievement"):
		main.toast_achievement(Achievements.find(id))


func bump_stat(name: String, n: int = 1) -> void:
	achv_stats[name] = int(achv_stats.get(name, 0)) + n
	save_achievements()
	Achievements.check()


func save_achievements() -> void:
	if _can_write():
		_write_json(_path(ACH_PATH), {"achieved": achieved, "stats": achv_stats})


func load_achievements() -> void:
	var d = _read_json(_path(ACH_PATH))
	if d is Dictionary:
		achieved = d.get("achieved", {})
		achv_stats = d.get("stats", {})


# ---------------------------------------------------------------- settings --

func load_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate()
	var d = _read_json(_path(SETTINGS_PATH))
	if d is Dictionary:
		for k in settings:
			if d.has(k) and typeof(d[k]) in [TYPE_FLOAT, TYPE_INT, TYPE_BOOL]:
				settings[k] = d[k]
	for k in ["master", "music", "sfx", "voice"]:
		settings[k] = clampf(float(settings[k]), 0.0, 1.0)
	settings.text_speed = clampi(int(settings.text_speed), 0, 2)
	settings.battle_speed = clampi(int(settings.battle_speed), 0, 1)


func save_settings() -> void:
	if _can_write():
		_write_json(_path(SETTINGS_PATH), settings)


func apply_settings() -> void:
	var mi := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(mi, linear_to_db(pow(maxf(0.001, float(settings.master)), 1.6)))
	AudioServer.set_bus_mute(mi, float(settings.master) <= 0.001)
	Sfx.set_bus_volume("Music", settings.music)
	Sfx.set_bus_volume("SFX", settings.sfx)
	Sfx.set_bus_volume("Voice", settings.voice)


func buzz(ms: int) -> void:
	## A short vibration, only when playing by touch.
	if touch_active:
		Input.vibrate_handheld(ms)


func autoplay() -> bool:
	## Automated test runs drive the game themselves (see tools/autotest.gd).
	return OS.get_environment("CT_AUTOPLAY") != ""


func next_choice() -> int:
	## Scripted story choices for automated runs: CT_CHOICES="1,0,2" (default 0).
	if not Engine.has_meta("ct_choices"):
		var q := []
		for c in OS.get_environment("CT_CHOICES").split(",", false):
			q.append(int(c))
		Engine.set_meta("ct_choices", q)
	var q: Array = Engine.get_meta("ct_choices")
	return q.pop_front() if not q.is_empty() else 0


func reduced_motion() -> bool:
	return settings.get("reduced_motion", false)


func shake_on() -> bool:
	return settings.get("shake", true) and not reduced_motion()


func text_cps() -> float:
	if autoplay():
		return 600.0
	return [32.0, 48.0, 90.0][int(settings.get("text_speed", 1))]


func battle_speed() -> float:
	if autoplay():
		return float(OS.get_environment("CT_SPEED")) if OS.get_environment("CT_SPEED") != "" else 3.0
	return [1.0, 1.6][int(settings.get("battle_speed", 0))]


# -------------------------------------------------------------------- disk --

func _read_json(p: String):
	if not FileAccess.file_exists(p):
		return null
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


func _write_json(p: String, data) -> void:
	## Write to a temp file, then swap it in, so a crash never leaves half a save.
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	var tmp := p + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("could not write " + p)
		return
	f.store_string(JSON.stringify(data))
	f.close()
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(p)
	DirAccess.rename_absolute(tmp, p)
