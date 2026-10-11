class_name StoryPart
extends Node
## Base for the three act scripts. Each scene is a method scene_<id>() that
## plays the scene and returns the next scene's id (or, at the very end, the
## ending record). Field events come in through talk / examine / trigger /
## exit / spotted; simple flavour text can live in the map data.

var s: Story
## Which scene this part is currently playing (for event routing).
var scene := ""


func talk(_n: Actor) -> void:
	await s.say("", "...")


func examine(ev: Dictionary) -> void:
	if ev.has("text"):
		await s.say(ev.get("who", "~"), ev.text)


func trigger(_id: String) -> void:
	pass


func exit(_e: Dictionary) -> void:
	pass


func spotted(_who: Actor) -> void:
	pass


func autoplay() -> void:
	## Automated runs: take the canonical next step from wherever we are.
	pass


func explore_extras() -> bool:
	## Automated runs with CT_EXPLORE=1 also poke at the optional things.
	return OS.get_environment("CT_EXPLORE") != ""


func push_back(tiles: int = 1) -> void:
	## Turn the player around from an exit they can't take yet.
	var p := s.w.player
	var back: Vector2 = -Actor.DIRS[p.dir] * 16.0 * tiles
	await s.walk("player", [p.position + back], 70.0)
