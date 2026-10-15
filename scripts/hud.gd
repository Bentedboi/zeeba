extends CanvasLayer
## Party panels (Zeeba + Dale), coins, carried items, toasts, the level
## title card and the pause menu.

var main
var _view: Control
var _toast := ""
var _toast_t := 0.0
var _title := ""
var _title_t := 0.0
var _paused := false
var _sel := 0
const PAUSE_OPTS := ["RESUME", "RETRY FROM BEACON", "TITLE SCREEN"]


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_hud)
	add_child(_view)


func toast(text: String) -> void:
	_toast = text
	_toast_t = 3.0


func title_card(text: String) -> void:
	_title = text
	_title_t = 3.0


func _process(delta: float) -> void:
	_toast_t = maxf(0.0, _toast_t - delta)
	if not get_tree().paused or _paused:
		_title_t = maxf(0.0, _title_t - delta)
	if _paused:
		if Input.is_action_just_pressed("up"):
			_sel = (_sel + PAUSE_OPTS.size() - 1) % PAUSE_OPTS.size()
			Sfx.play("select")
		elif Input.is_action_just_pressed("down"):
			_sel = (_sel + 1) % PAUSE_OPTS.size()
			Sfx.play("select")
		elif Input.is_action_just_pressed("confirm"):
			Sfx.play("confirm")
			_close_pause()
			match _sel:
				1: main.retry()
				2: main.to_title()
		elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("cancel"):
			_close_pause()
	elif Input.is_action_just_pressed("pause") and not get_tree().paused and not main.busy():
		_paused = true
		_sel = 0
		get_tree().paused = true
		Sfx.play("select")
	_view.queue_redraw()


func _close_pause() -> void:
	_paused = false
	get_tree().paused = false
	Game.input_lock = 0.15


func _panel(r: Rect2, border: Color) -> void:
	_view.draw_rect(r, Color.BLACK)
	_view.draw_rect(r, border, false, 1.0)


func _bar(pos: Vector2, w: float, frac: float, col: Color) -> void:
	_view.draw_rect(Rect2(pos, Vector2(w, 4)), Color(0.15, 0.1, 0.2))
	_view.draw_rect(Rect2(pos, Vector2(roundf(w * clampf(frac, 0.0, 1.0)), 4)), col)
	_view.draw_rect(Rect2(pos, Vector2(w, 1)), Color(1, 1, 1, 0.15))


func _hearts(pos: Vector2, hp: int, max_hp: int, col: Color) -> void:
	for i in max_hp:
		PixelFont.draw(_view, pos + Vector2(i * 6, 0), "@", col if i < hp else Color(0.25, 0.2, 0.3))


func _draw_hud() -> void:
	var green := Color(Art.PAL.g)
	var orange := Color(Art.PAL.o)
	# Zeeba
	_panel(Rect2(3, 3, 108, 28), green)
	PixelFont.draw(_view, Vector2(7, 6), "ZEEBA", green)
	_hearts(Vector2(43, 6), Game.princess_hp, Game.princess_max, Color(Art.PAL.v))
	PixelFont.draw(_view, Vector2(7, 18), "SPD", Color(Art.PAL.n))
	_bar(Vector2(26, 20), 30, Game.speed_charge / Game.SPEED_MAX, Color(Art.PAL.r))
	PixelFont.draw(_view, Vector2(61, 18), "STR", Color(Art.PAL.u))
	for i in Game.STRENGTH_MAX:
		var c := Color(Art.PAL.u) if i < Game.strength else Color(0.25, 0.2, 0.3)
		_view.draw_rect(Rect2(81 + i * 9, 19, 7, 6), c)
	# Dale
	_panel(Rect2(209, 3, 108, 28), orange)
	PixelFont.draw(_view, Vector2(213, 6), "DALE", orange)
	var dale_col := Color(Art.PAL.v)
	if Game.dale_hp <= 1 and int(Time.get_ticks_msec() / 250) % 2 == 0:
		dale_col = Color.WHITE
	_hearts(Vector2(243, 6), Game.dale_hp, Game.dale_max, dale_col)
	PixelFont.draw(_view, Vector2(213, 18), "H2O", Color(Art.PAL.a))
	var wf := Game.water / Game.water_max()
	var wcol := Color(Art.PAL.a)
	if wf < 0.3 and int(Time.get_ticks_msec() / 250) % 2 == 0:
		wcol = Color(Art.PAL.v)
	_bar(Vector2(232, 20), 52 if not Game.upgrades.has("tank") else 60, wf, wcol)
	for i in Game.bottles:
		_view.draw_rect(Rect2(296 + i * 6, 18, 4, 7), Color(Art.PAL.k))
		_view.draw_rect(Rect2(297 + i * 6, 19, 2, 5), Color(Art.PAL.a))
	# Coins + carried items
	var coins := "$%d" % Game.coins
	_panel(Rect2(140, 3, 40, 13), Color(Art.PAL.y))
	PixelFont.draw_centered(_view, 160, 6, coins, Color(Art.PAL.y))
	var ix := 160 - Game.carrying.size() * 7
	for q in Game.carrying:
		var tex := Art.tex(Story.QUESTS[q].sprite)
		_view.draw_texture_rect(tex, Rect2(ix, 19, 12, 12 * tex.get_size().y / tex.get_size().x), false)
		ix += 14
	if not Game.carrying.is_empty() and int(Time.get_ticks_msec() / 400) % 2 == 0:
		PixelFont.draw_centered(_view, 160, 33, "C: GIVE", Color.WHITE, 1, Color.BLACK)
	if Game.upgrades.has("rover"):
		PixelFont.draw(_view, Vector2(4, 228), "R: ROVER", Color(1, 1, 1, 0.6), 1, Color.BLACK)
	# Title card
	if _title_t > 0.0:
		var a := minf(1.0, _title_t) * minf(1.0, (3.0 - _title_t) * 3.0)
		_view.draw_rect(Rect2(0, 44, 320, 30), Color(0, 0, 0, 0.7 * a))
		PixelFont.draw_centered(_view, 160, 49, _title, Color(1, 1, 1, a), 2)
	# Toast
	if _toast_t > 0.0 and not main.busy():
		var lines := PixelFont.wrap(_toast, 48)
		var hgt := lines.count("\n") * PixelFont.LINE + 14
		var w := PixelFont.width(lines) + 12
		var r := Rect2(160 - w / 2.0, 40, w, hgt)
		_view.draw_rect(r, Color.BLACK)
		_view.draw_rect(r, Color.WHITE, false, 1.0)
		PixelFont.draw(_view, r.position + Vector2(6, 4), lines, Color.WHITE)
	# Pause
	if _paused:
		_view.draw_rect(Rect2(0, 0, 320, 240), Color(0, 0, 0, 0.6))
		var r := Rect2(90, 70, 140, 82)
		_view.draw_rect(r, Color.BLACK)
		_view.draw_rect(r, Color.WHITE, false, 2.0)
		PixelFont.draw_centered(_view, 160, 78, "PAUSED", Color(Art.PAL.y))
		for i in PAUSE_OPTS.size():
			var col := Color(Art.PAL.y) if i == _sel else Color.WHITE
			PixelFont.draw(_view, Vector2(110, 98 + i * 14), PAUSE_OPTS[i], col)
			if i == _sel:
				_view.draw_rect(Rect2(101, 100 + i * 14, 5, 5), Color(Art.PAL.v))
		var done := 0
		for q in Story.QUESTS:
			if Game.quests_done.has(q):
				done += 1
		PixelFont.draw_centered(_view, 160, 140, "NICE THINGS: %d/%d" % [done, Story.QUESTS.size()], Color(Art.PAL.f))
