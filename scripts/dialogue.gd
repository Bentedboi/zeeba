extends CanvasLayer
## Deltarune-style text box: black box, white frame, portrait on the left,
## typewriter text with per-speaker voice blips. Pauses the game while open.
## Lines are "speaker|text" (see Story). Await `finished` to wait for it.

signal finished

const CPS := 42.0

var _queue: Array = []
var _speaker := ""
var _text := ""
var _shown := 0.0
var _blip := 0
var _open := false
var _opened_frame := -1
var _view: Control


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_box)
	add_child(_view)


func is_open() -> bool:
	return _open


## Show lines (queued behind any text already showing).
func say(lines: Array) -> void:
	_queue.append_array(lines)
	if not _open:
		_open = true
		_opened_frame = Engine.get_process_frames()
		get_tree().paused = true
		_next()


## say() and wait until the whole queue has been read.
func run(lines: Array) -> void:
	say(lines)
	await finished


func _next() -> void:
	if _queue.is_empty():
		_open = false
		_view.queue_redraw()
		get_tree().paused = false
		Game.input_lock = 0.15
		finished.emit()
		return
	var line: String = _queue.pop_front()
	var parts := line.split("|", true, 1)
	_speaker = parts[0] if parts.size() > 1 else ""
	var body: String = parts[1] if parts.size() > 1 else parts[0]
	if _speaker != "" and not body.begins_with("*"):
		body = "* " + body
	var cols := 37 if _speaker != "" else 46
	_text = PixelFont.wrap(body, cols, "  ")
	_shown = 0.0
	_blip = 0
	_view.queue_redraw()


func _process(delta: float) -> void:
	if not _open:
		return
	var total := _text.length()
	if _shown < total:
		var before := int(_shown)
		_shown = minf(total, _shown + CPS * delta)
		var now := int(_shown)
		for i in range(before, now):
			var ch := _text[i]
			if ch in [",", ".", "!", "?"]:
				_shown = maxf(_shown - 0.5, i + 1)  # tiny pause on punctuation
			if ch != " " and ch != "\n":
				_blip += 1
				if _blip % 2 == 1:
					Sfx.play("blip", Story.SPEAKERS.get(_speaker, Story.SPEAKERS[""]).pitch * randf_range(0.97, 1.03), -14.0)
		_view.queue_redraw()
	if Engine.get_process_frames() == _opened_frame:
		return  # the key that opened the box shouldn't also skip it
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("talk"):
		if _shown < total:
			_shown = total
			_view.queue_redraw()
		else:
			_next()
	elif Input.is_action_just_pressed("cancel"):
		_shown = total
		_view.queue_redraw()


func _draw_box() -> void:
	if not _open:
		return
	var r := Rect2(8, 162, 304, 72)
	_view.draw_rect(r.grow(1), Color.BLACK)
	_view.draw_rect(r, Color.WHITE)
	_view.draw_rect(r.grow(-2), Color.BLACK)
	var x := 20.0
	var sp: Dictionary = Story.SPEAKERS.get(_speaker, Story.SPEAKERS[""])
	if sp.sprite != "":
		var tex := Art.tex(sp.sprite, sp.swap)
		var reg := Art.portrait_region(sp.sprite)
		var talking := int(_shown) < _text.length() and int(Time.get_ticks_msec() / 120) % 2 == 0
		var dy := -1.0 if talking else 0.0
		_view.draw_texture_rect_region(tex, Rect2(18, 176 + dy, reg.size.x * 3, reg.size.y * 3), reg)
		x = 72.0
	PixelFont.draw(_view, Vector2(x, 174), _text.substr(0, int(_shown)), Color.WHITE)
	if int(_shown) >= _text.length() and int(Time.get_ticks_msec() / 300) % 2 == 0:
		PixelFont.draw(_view, Vector2(298, 220), "`", Color.WHITE)
