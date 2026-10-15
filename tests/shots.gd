extends SceneTree
## Screenshot tour (needs a window): title, each level, dialogue, shop, ending.
## godot --path . -s res://tests/shots.gd   -> user://shots/*.png

var game


func _init() -> void:
	_run.call_deferred()
	create_timer(120.0).timeout.connect(func(): print("TIMEOUT"); quit(1))


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute("user://shots")
	img.save_png("user://shots/%s.png" % name)
	print("shot ", name, " ", img.get_size())


func _level(lv: int, cell_x: int, with_intro := false) -> Node:
	game.new_game()
	game.level = lv
	if not with_intro:
		game.flags["intro%d" % lv] = true
	game.flags["redrock"] = true
	game.flags["dirt"] = true
	change_scene_to_file("res://scenes/main.tscn")
	await _frames(3)
	var main = current_scene
	if cell_x >= 0:
		main.princess.position = Vector2(cell_x * 16 + 8, 13 * 16)
		main.princess.reset_trail()
		main.dale.position = main.princess.position - Vector2(22, 0)
		main.cam.position = main.princess.position
		main.cam.reset_smoothing()
	return main


func _run() -> void:
	game = root.get_node("Game")
	change_scene_to_file("res://scenes/title.tscn")
	await _frames(90)
	await _shot("01_title")

	var main = await _level(0, -1, true)
	await _frames(150)
	await _shot("02_intro_dialogue")

	main = await _level(0, 40)
	await _frames(40)
	main.princess.velocity.x = 100
	game.speed_charge = 5.0
	game.strength = 2
	await _frames(20)
	await _shot("03_rustfield")

	main = await _level(0, 128)
	await _frames(40)
	await _shot("04_tunnel")

	main = await _level(0, 175)
	game.carrying = ["sock"]
	await _frames(40)
	await _shot("05_flowerbox_view")

	main = await _level(0, 183)
	game.coins = 30
	await _frames(30)
	main.shop.open()
	await _frames(30)
	await _shot("06_shop")
	main.shop._close()
	await _frames(40)

	main = await _level(1, 30)
	await _frames(40)
	await _shot("07_caverns")

	main = await _level(1, 80)
	game.upgrades["rover"] = true
	game.upgrades["hat"] = true
	game.riding = true
	main.princess.apply_shape()
	await _frames(40)
	await _shot("08_caverns_rover")
	game.riding = false

	main = await _level(2, 60)
	game.quests_done = {"glasses": true, "flower": true, "blanket": true}
	await _frames(40)
	await _shot("09_spaceport")

	main = await _level(2, 158)
	await _frames(40)
	await _shot("10_rocket")

	change_scene_to_file("res://scenes/ending.tscn")
	await _frames(660)
	await _shot("11_ending")
	quit()
