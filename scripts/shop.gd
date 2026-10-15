extends CanvasLayer
## Blorb's Mart, Deltarune-shop style: Blorb up top, chatter box bottom-left,
## stock list bottom-right.

signal closed

var main
var _view: Control
var _open := false
var _sel := 0
var _line := ""
var _shown := 0.0
var _t := 0.0
var _opened_frame := -1
var _prev_music := ""


func _ready() -> void:
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_shop)
	add_child(_view)


func is_open() -> bool:
	return _open


func open() -> void:
	_open = true
	_sel = 0
	_set_line(Story.SHOP_HELLO)
	_opened_frame = Engine.get_process_frames()
	get_tree().paused = true
	_prev_music = Sfx._want_song
	Sfx.music("shop")


func _set_line(text: String) -> void:
	_line = PixelFont.wrap("* " + text, 26, "  ")
	_shown = 0.0


func _owned(id: String) -> bool:
	match id:
		"bottle": return Game.bottles >= Game.BOTTLE_MAX
		"bandage": return Game.dale_hp >= Game.dale_max and Game.princess_hp >= Game.princess_max
		_: return Game.upgrades.has(id)


func _process(delta: float) -> void:
	if not _open:
		return
	_t += delta
	if _shown < _line.length():
		var before := int(_shown)
		_shown = minf(_line.length(), _shown + 45.0 * delta)
		if int(_shown) != before and int(_shown) % 2 == 0:
			Sfx.play("blip", 0.65, -16.0)
	_view.queue_redraw()
	if Engine.get_process_frames() == _opened_frame:
		return
	var n := Story.SHOP_ITEMS.size() + 1
	if Input.is_action_just_pressed("up"):
		_sel = (_sel + n - 1) % n
		Sfx.play("select")
		_describe()
	elif Input.is_action_just_pressed("down"):
		_sel = (_sel + 1) % n
		Sfx.play("select")
		_describe()
	elif Input.is_action_just_pressed("confirm"):
		if _sel == n - 1:
			_close()
		else:
			_buy(Story.SHOP_ITEMS[_sel])
	elif Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause"):
		_close()


func _describe() -> void:
	if _sel < Story.SHOP_ITEMS.size():
		_set_line(Story.SHOP_ITEMS[_sel][3])
	else:
		_set_line("Leaving so soon? Blorb is sad. Blorb is always a little sad.")


func _buy(item: Array) -> void:
	var id: String = item[0]
	var price: int = item[2]
	if _owned(id):
		Sfx.play("cancel")
		match id:
			"bottle": _set_line("Your human can't carry any more bottles! Look at his little arms!")
			"bandage": _set_line("Everybody's already healthy! Blorb is happy for you.")
			_: _set_line("You already have that one, friend!")
		return
	if Game.coins < price:
		Sfx.play("cancel")
		_set_line("You're short on coins! Do nice things for your human. Coins happen.")
		return
	Game.add_coins(-price)
	Sfx.play("coin")
	match id:
		"bottle":
			Game.bottles += 1
			_set_line("One fresh bottle! Dale drinks it by himself when he's thirsty.")
		"tank":
			Game.upgrades["tank"] = true
			Game.water = Game.water_max()
			_set_line("Big tank! Filled it up for free. Blorb is generous.")
		"hat":
			Game.upgrades["hat"] = true
			_set_line("Ooh, what a stylish human! Very shady. Very fashion.")
		"bandage":
			Game.dale_hp = mini(Game.dale_max, Game.dale_hp + 1)
			Game.princess_hp = Game.princess_max
			_set_line("All patched up! Try not to get nibbled.")
		"rover":
			Game.upgrades["rover"] = true
			_set_line("VROOM! Press R to hop in. It can ram through boulders, too!")
	Game.save_game()


func _close() -> void:
	_open = false
	Sfx.play("confirm")
	get_tree().paused = false
	Game.input_lock = 0.2
	Sfx.music(_prev_music)
	_view.queue_redraw()
	main.say(Story.SHOP_BYE)
	closed.emit()


func _draw_shop() -> void:
	if not _open:
		return
	var v := _view
	# backdrop: Blorb's stall interior
	v.draw_rect(Rect2(0, 0, 320, 240), Color("120a1c"))
	for i in 12:
		var col := Color("2a1638") if i % 2 == 0 else Color("1e1030")
		v.draw_rect(Rect2(i * 28, 0, 28, 128), col)
	for i in 21:
		var col := Color(Art.PAL.v) if i % 2 == 0 else Color(Art.PAL.w)
		v.draw_rect(Rect2(i * 16, 0, 16, 12), col)
	v.draw_rect(Rect2(0, 12, 320, 2), Color(Art.PAL.k))
	# shelves with wares
	for s in 2:
		var y := 40 + s * 36
		v.draw_rect(Rect2(14, y, 80, 3), Color(Art.PAL.d))
		v.draw_rect(Rect2(226, y, 80, 3), Color(Art.PAL.d))
		for j in 4:
			v.draw_rect(Rect2(20 + j * 18, y - 10, 6, 10), Color(Art.PAL.a))
			v.draw_rect(Rect2(232 + j * 18, y - 8, 8, 8), Color(Art.PAL.r) if (j + s) % 2 == 0 else Color(Art.PAL.y))
	# Blorb, big
	var bob := roundf(sin(_t * 2.0) * 2.0)
	v.draw_texture_rect(Art.tex("shopkeep"), Rect2(136, 20 + bob, 48, 72), false)
	v.draw_rect(Rect2(96, 92, 128, 36), Color(Art.PAL.k))
	v.draw_rect(Rect2(98, 94, 124, 34), Color(Art.PAL.d))
	v.draw_rect(Rect2(98, 94, 124, 3), Color(Art.PAL.u))
	PixelFont.draw_centered(v, 160, 106, "BLORB'S MART", Color(Art.PAL.y), 1, Color(Art.PAL.k))
	# chatter box
	var lb := Rect2(4, 132, 170, 104)
	v.draw_rect(lb, Color.BLACK)
	v.draw_rect(lb, Color.WHITE, false, 2.0)
	PixelFont.draw(v, Vector2(12, 140), _line.substr(0, int(_shown)), Color.WHITE)
	# stock box
	var rb := Rect2(178, 132, 138, 104)
	v.draw_rect(rb, Color.BLACK)
	v.draw_rect(rb, Color.WHITE, false, 2.0)
	for i in Story.SHOP_ITEMS.size() + 1:
		var y := 140 + i * 13
		var label := "EXIT"
		var price := ""
		var dim := false
		if i < Story.SHOP_ITEMS.size():
			var it: Array = Story.SHOP_ITEMS[i]
			label = it[1]
			price = "$%d" % it[2]
			dim = _owned(it[0])
			if dim and it[0] in ["tank", "hat", "rover"]:
				price = "SOLD"
		var col := Color(Art.PAL.y) if i == _sel else Color.WHITE
		if dim:
			col = col.darkened(0.55)
		PixelFont.draw(v, Vector2(194, y), label, col)
		PixelFont.draw(v, Vector2(310 - PixelFont.width(price), y), price, col)
		if i == _sel:
			v.draw_rect(Rect2(185, y + 2, 5, 5), Color(Art.PAL.v))
	PixelFont.draw(v, Vector2(194, 222), "$%d" % Game.coins, Color(Art.PAL.y))
	PixelFont.draw(v, Vector2(234, 222), "WATER x%d" % Game.bottles, Color(Art.PAL.a))
