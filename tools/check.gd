extends SceneTree
## Loads every script so parse errors show up in one pass:
## godot --headless --path . -s tools/check.gd


func _init() -> void:
	var n := 0
	for p in _scan("res://scripts") + _scan("res://tools"):
		var s = load(p)
		n += 1
		if s == null:
			print("FAILED ", p)
	print("checked ", n, " scripts")
	quit()


func _scan(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(_scan(dir.path_join(sub)))
	return out
