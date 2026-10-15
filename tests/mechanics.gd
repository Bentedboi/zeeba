extends SceneTree
## Headless mechanics checks on level 1 (Rustfield):
##   jump apex, the 7-tile speed gap (needs red rocks), boulder punching.
## godot --headless --path . -s res://tests/mechanics.gd

var main
var game
var fails := 0


func _init() -> void:
	_run.call_deferred()
	create_timer(120.0).timeout.connect(func(): print("TIMEOUT"); quit(1))


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _release_all() -> void:
	for a in ["left", "right", "jump", "punch", "up", "talk"]:
		Input.action_release(a)


func _expect(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		fails += 1


func _place(cell_x: int) -> void:
	var p = main.princess
	p.position = Vector2(cell_x * 16 + 8, 14 * 16)
	p.velocity = Vector2.ZERO
	p.reset_trail()
	await _frames(5)


## Run right from cell, jumping when the floor ahead ends.
func _run_and_jump(from_x: int, edge_x: int, frames: int) -> void:
	await _place(from_x)
	Input.action_press("right")
	var jumped := false
	for i in frames:
		await physics_frame
		if not jumped and main.princess.position.x >= edge_x * 16 + 10:
			Input.action_press("jump")
			jumped = true
	_release_all()
	await _frames(30)


func _run() -> void:
	game = root.get_node("Game")
	game.new_game()
	game.flags["intro0"] = true
	game.flags["redrock"] = true
	game.flags["dirt"] = true
	change_scene_to_file("res://scenes/main.tscn")
	await _frames(20)
	main = current_scene
	var lv = main.level

	# 1. jump apex from flat ground
	await _place(10)
	var y0: float = main.princess.position.y
	Input.action_press("jump")
	var apex := y0
	for i in 50:
		await physics_frame
		apex = minf(apex, main.princess.position.y)
	_release_all()
	await _frames(30)
	print("  jump height = %.1f px (%.2f tiles)" % [y0 - apex, (y0 - apex) / 16.0])
	_expect(y0 - apex > 50.0 and y0 - apex < 64.0, "jump clears 3 tiles but not 4")

	# find the speed gap: first run of >= 6 empty ground cells on row 14
	var gap_start := -1
	var run := 0
	for x in lv.w:
		if lv.char_at(Vector2i(x, 14)) != "#":
			run += 1
			if run == 7:
				gap_start = x - 6
				break
		else:
			run = 0
	print("  speed gap starts at cell %d" % gap_start)

	# 2. without speed: fall in
	game.speed_charge = 0.0
	var hp_before: int = game.princess_hp
	await _run_and_jump(gap_start - 2, gap_start - 1, 70)
	await _frames(60)
	_expect(game.princess_hp < hp_before or main.princess.position.x < (gap_start + 7) * 16, "normal jump can't clear the speed gap")
	await _frames(60)
	game.princess_hp = 5

	# 3. with speed: clear it
	game.speed_charge = 8.0
	await _run_and_jump(gap_start - 6, gap_start - 1, 70)
	print("  landed at x=%.0f (gap ends at %d)" % [main.princess.position.x, (gap_start + 7) * 16])
	_expect(main.princess.position.x > (gap_start + 7) * 16 and main.princess.is_on_floor(), "boosted jump clears the speed gap")

	# 4. Dale follows across
	await _frames(40)
	_expect(main.dale.position.x > (gap_start + 7) * 16 - 30, "Dale followed across the gap (x=%.0f)" % main.dale.position.x)

	# 5. punch a boulder with strength
	var b = main.boulders[0]
	var br: Rect2 = b.rect()
	var bx := int(br.position.x / 16)
	game.strength = 1
	await _place(bx - 2)
	Input.action_press("right")
	await _frames(25)
	Input.action_press("punch")
	await _frames(5)
	_release_all()
	await _frames(10)
	_expect(not is_instance_valid(b) and game.strength == 0, "punch smashes boulder and uses strength")

	# 6. stomp a mite
	var m = main.mites[0]
	main.princess.position = m.position + Vector2(0, -40)
	main.princess.velocity = Vector2(0, 100)
	await _frames(30)
	_expect(not is_instance_valid(m) or not m.alive(), "stomping squashes a mite")

	# 7. Dale settles on the ground after Zeeba hops up a step and stops
	await _place(35)
	Input.action_press("right")
	var hopped := false
	for i in 90:
		await physics_frame
		if not hopped and main.princess.position.x >= 36 * 16:
			Input.action_press("jump")
			hopped = true
		if hopped and main.princess.is_on_floor() and main.princess.position.y < 13 * 16 + 4:
			break
	_release_all()
	await _frames(90)
	print("  princess=%s dale=%s" % [main.princess.position, main.dale.position])
	_expect(main.dale._grounded(main.dale.position), "Dale stands on ground after a hop")

	print("MECHANICS DONE, fails=%d" % fails)
	quit(fails)
