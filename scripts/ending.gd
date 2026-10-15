extends Node2D
## The end: the rocket flies home past a big blue Earth, then the tally.

var _t := 0.0
var _done := 0
var _stars: Array = []


func _ready() -> void:
	get_tree().paused = false
	Sfx.music("ending")
	for q in Story.QUESTS:
		if Game.quests_done.has(q):
			_done += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 120:
		_stars.append([Vector2(rng.randf() * 320, rng.randf() * 240), rng.randf_range(0.2, 1.0)])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > 9.0 and Input.is_action_just_pressed("confirm"):
		Sfx.play("confirm")
		get_tree().change_scene_to_file("res://scenes/title.tscn")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 240), Color("06040e"))
	for s in _stars:
		var p: Vector2 = s[0]
		var x := fposmod(p.x - _t * 30.0 * s[1], 320.0)
		draw_rect(Rect2(x, p.y, 1, 1), Color(1, 1, 1, s[1]))
	# Earth grows as the rocket arrives
	var er := 18.0 + minf(_t, 8.0) * 8.0
	var ec := Vector2(250, 120)
	draw_circle(ec, er + 4, Color(0.4, 0.7, 1.0, 0.2))
	draw_circle(ec, er, Color("2a6ad0"))
	draw_circle(ec + Vector2(-er * 0.3, -er * 0.2), er * 0.35, Color("4ac060"))
	draw_circle(ec + Vector2(er * 0.25, er * 0.3), er * 0.25, Color("4ac060"))
	draw_circle(ec + Vector2(er * 0.1, -er * 0.6), er * 0.2, Color(1, 1, 1, 0.8))
	# tiny rocket
	var rx := 40.0 + minf(_t, 8.0) * 18.0
	var ry := 140.0 + sin(_t * 3.0) * 3.0
	draw_rect(Rect2(rx - 14, ry - 2, 6 + (int(_t * 20.0) % 3) * 2, 4), Color(Art.PAL.y))
	draw_rect(Rect2(rx - 8, ry - 4, 14, 8), Color.WHITE)
	draw_rect(Rect2(rx + 6, ry - 3, 4, 6), Color(Art.PAL.v))
	draw_rect(Rect2(rx - 8, ry - 6, 4, 2), Color(Art.PAL.v))
	draw_rect(Rect2(rx - 8, ry + 4, 4, 2), Color(Art.PAL.v))
	draw_rect(Rect2(rx - 1, ry - 2, 3, 3), Color(0.45, 0.8, 0.95))
	# words
	var a := clampf((_t - 2.0) / 1.5, 0.0, 1.0)
	PixelFont.draw_centered(self, 120, 24, "DALE MADE IT HOME.", Color(1, 1, 1, a), 2)
	var b := clampf((_t - 4.5) / 1.5, 0.0, 1.0)
	PixelFont.draw_centered(self, 120, 56, "NICE THINGS DONE: %d / %d" % [_done, Story.QUESTS.size()], Color(1, 0.6, 0.9, b))
	PixelFont.draw_centered(self, 120, 70, "COINS LEFT: $%d" % Game.coins, Color(1, 0.85, 0.3, b))
	var c := clampf((_t - 6.5) / 1.5, 0.0, 1.0)
	var msg := "He tells everyone on Earth about\nthe kindest princess in the solar system."
	if _done < Story.QUESTS.size():
		msg = "He never forgets the martian princess\nwho got him home."
	PixelFont.draw_centered(self, 160, 190, msg, Color(1, 1, 1, c))
	if _t > 9.0 and int(_t * 2.0) % 2 == 0:
		PixelFont.draw_centered(self, 160, 222, "THE END   (Z)", Color(Art.PAL.y))
	# Zeeba waving from the corner
	if _t > 3.0:
		draw_texture(Art.tex("princess_jump"), Vector2(12, 196 - absf(sin(_t * 4.0)) * 3.0))
