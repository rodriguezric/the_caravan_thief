extends Node
## Loads every script so parse errors show up in one pass. Runs as the main
## scene's autotest (so autoloads exist): CT_TEST=check godot --headless --path .


static func scan(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(scan(dir.path_join(sub)))
	return out
