extends SceneTree
## Headless smoke test: every script parses, every level loads and runs.
## godot --headless --path . -s res://tests/smoke.gd

func _init() -> void:
	_run.call_deferred()
	create_timer(90.0).timeout.connect(func(): print("TIMEOUT"); quit(1))


func _check() -> void:
	for f in DirAccess.get_files_at("res://scripts"):
		if f.ends_with(".gd"):
			var s = load("res://scripts/" + f)
			if s == null or not s.can_instantiate():
				print("FAIL script ", f)


func _run() -> void:
	_check()
	var game = root.get_node("Game")
	for lv in 3:
		game.new_game()
		game.level = lv
		game.flags["intro%d" % lv] = true
		change_scene_to_file("res://scenes/main.tscn")
		for i in 180:
			await physics_frame
		var main = current_scene
		print("level %d: %dx%d princess=%s dale=%s mites=%d boulders=%d props=%d floor=%s" % [lv, main.level.w, main.level.h, main.princess.position, main.dale.position, main.mites.size(), main.boulders.size(), main.props.size(), main.princess.is_on_floor()])
	print("SMOKE DONE")
	quit()