extends Node2D
## Title screen: scrolling Mars, Zeeba and Dale walking, menu.

const BackgroundScript := preload("res://scripts/background.gd")

var bg
var _opts: Array = []
var _sel := 0
var _t := 0.0
var _going := false
var _fade := 1.0


func _ready() -> void:
	get_tree().paused = false
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	bg = BackgroundScript.new()
	layer.add_child(bg)
	bg.setup("rust")
	bg.auto_scroll = 22.0
	if Game.has_save():
		_opts.append("CONTINUE")
	_opts.append_array(["NEW GAME", "QUIT"])
	Sfx.music("title")


func _process(delta: float) -> void:
	_t += delta
	_fade = maxf(0.0, _fade - delta * 1.5) if not _going else minf(1.0, _fade + delta * 2.0)
	queue_redraw()
	if _going:
		return
	if Input.is_action_just_pressed("up"):
		_sel = (_sel + _opts.size() - 1) % _opts.size()
		Sfx.play("select")
	elif Input.is_action_just_pressed("down"):
		_sel = (_sel + 1) % _opts.size()
		Sfx.play("select")
	elif Input.is_action_just_pressed("confirm"):
		Sfx.play("confirm")
		match _opts[_sel]:
			"CONTINUE":
				Game.load_game()
				if Game.flags.has("won"):
					Game.new_game()
				_go()
			"NEW GAME":
				Game.new_game()
				_go()
			"QUIT":
				get_tree().quit()


func _go() -> void:
	_going = true
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _draw() -> void:
	# ground strip
	var gx := -fmod(_t * 40.0, 16.0)
	for i in 22:
		draw_texture(Art.tile("rust", "top", i % 4), Vector2(gx + i * 16, 200))
		draw_texture(Art.tile("rust", "fill", (i + 1) % 4), Vector2(gx + i * 16, 216))
		draw_texture(Art.tile("rust", "fill", (i + 2) % 4), Vector2(gx + i * 16, 232))
	draw_rect(Rect2(0, 199, 320, 1), Color(Art.PAL.k))
	# party walking
	var fr: String = ["princess_run1", "princess", "princess_run2", "princess"][int(_t * 8.0) % 4]
	draw_texture(Art.tex(fr), Vector2(176, 176 - (1 if int(_t * 8.0) % 2 == 0 else 0)))
	var df: String = ["dale_walk1", "dale", "dale_walk2", "dale"][int(_t * 8.0) % 4]
	draw_texture(Art.tex(df), Vector2(146, 176))
	draw_rect(Rect2(157, 178, 1, 2), Color(1, 1, 1, 0.8))
	# title
	var wob := roundf(sin(_t * 2.0) * 2.0)
	PixelFont.draw_centered(self, 160, 30 + wob, "PRINCESS ZEEBA", Color(Art.PAL.g), 3, Color(Art.PAL.k))
	PixelFont.draw_centered(self, 160, 64, "and the Very Helpless Human", Color(Art.PAL.f), 1, Color(Art.PAL.k))
	# menu
	for i in _opts.size():
		var y := 96 + i * 16
		var col := Color(Art.PAL.y) if i == _sel else Color.WHITE
		PixelFont.draw_centered(self, 160, y, _opts[i], col, 1, Color.BLACK)
		if i == _sel:
			var w := PixelFont.width(_opts[i])
			draw_rect(Rect2(160 - w / 2.0 - 11, y + 2, 5, 5), Color(Art.PAL.v))
	PixelFont.draw_centered(self, 160, 152, "Z: SELECT   ARROWS: MOVE", Color(1, 1, 1, 0.55), 1, Color.BLACK)
	if _fade > 0.0:
		draw_rect(Rect2(0, 0, 320, 240), Color(0, 0, 0, _fade))
