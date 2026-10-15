extends Node2D
## Parallax backdrop: dithered sky bands, stars, moons (and Earth), and three
## layers of mesas (or cave pillars). Lives in a CanvasLayer behind the level.

var theme := "rust"
var scroll := Vector2.ZERO    # camera top-left in world pixels
var auto_scroll := 0.0        # px/s for menus
var _sky: ImageTexture
var _layers: Array = []       # [factor, color, heights PackedInt32Array, from_top]
var _t := 0.0


func setup(theme_name: String) -> void:
	theme = theme_name
	var th: Dictionary = Art.THEMES[theme]
	_sky = _make_sky(th)
	_layers.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(theme)
	if theme == "cave":
		_layers.append([0.15, Color(th.far), _heights(rng, 640, 60, 36, 0.05), true])
		_layers.append([0.15, Color(th.far), _heights(rng, 640, 70, 30, 0.04), false])
		_layers.append([0.35, Color(th.mid), _heights(rng, 640, 40, 28, 0.09), true])
		_layers.append([0.35, Color(th.mid), _heights(rng, 640, 55, 25, 0.07), false])
	else:
		_layers.append([0.12, Color(th.far), _heights(rng, 640, 84, 22, 0.02), false])
		_layers.append([0.3, Color(th.mid), _heights(rng, 640, 62, 26, 0.035), false])
		_layers.append([0.55, Color(th.near), _heights(rng, 640, 36, 18, 0.06), false])
	queue_redraw()


## Flat-topped mesas: a smooth profile quantised into plateaus.
func _heights(rng: RandomNumberGenerator, n: int, base: int, amp: int, freq: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(n)
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	for i in n:
		var x := float(i)
		var v := sin(x * freq + p1) * 0.6 + sin(x * freq * 2.7 + p2) * 0.4
		v = roundf(v * 3.0) / 3.0  # plateaus
		out[i] = base + int(v * amp)
	# smooth plateau edges into slopes 2px wide
	return out


func _make_sky(th: Dictionary) -> ImageTexture:
	var img := Image.create(320, 240, false, Image.FORMAT_RGBA8)
	var bands: Array = th.sky
	var bh := 240.0 / bands.size()
	for y in 240:
		var fb := y / bh
		var b := mini(int(fb), bands.size() - 1)
		var frac := fb - b
		for x in 320:
			var col := Color(bands[b])
			# Deltarune-ish ordered dither into the next band
			if b < bands.size() - 1 and frac > 0.7:
				var on := (x + y) % 2 == 0 if frac < 0.85 else (x % 2 == 0 or y % 2 == 0)
				if on:
					col = Color(bands[b + 1])
			img.set_pixel(x, y, col)
	if th.stars:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for i in 90:
			var p := Vector2i(rng.randi_range(0, 319), rng.randi_range(0, 150))
			var c := Color(1, 1, 1, rng.randf_range(0.3, 0.9))
			img.set_pixel(p.x, p.y, img.get_pixel(p.x, p.y).lerp(Color.WHITE, c.a))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	scroll.x += auto_scroll * delta
	queue_redraw()


func _draw() -> void:
	if _sky == null:
		return
	var th: Dictionary = Art.THEMES[theme]
	draw_texture(_sky, Vector2.ZERO)
	# twinkles
	if th.stars:
		for i in 6:
			var sx := float((i * 97 + 31) % 320)
			var sy := float((i * 53 + 17) % 120)
			if sin(_t * 2.0 + i) > 0.6:
				draw_rect(Rect2(sx - 1, sy, 3, 1), Color(1, 1, 1, 0.8))
				draw_rect(Rect2(sx, sy - 1, 1, 3), Color(1, 1, 1, 0.8))
	# celestial bodies
	match theme:
		"rust":
			var px := 250.0 - scroll.x * 0.02
			draw_circle(Vector2(px, 38), 11, Color("e8c8b0"))
			draw_circle(Vector2(px + 3, 36), 9, Color("f4dcc8"))
			draw_circle(Vector2(px - 3, 41), 2, Color("c8a890"))
			draw_circle(Vector2(px - 70, 24), 4, Color("d0b8a8"))
			if th.earth:
				var ex := 120.0 - scroll.x * 0.02
				draw_rect(Rect2(ex - 2, 28, 5, 5), Color(0.4, 0.7, 1.0, 0.25 + 0.1 * sin(_t * 2.0)))
				draw_rect(Rect2(ex - 1, 29, 3, 3), Color("3a8ae0"))
				draw_rect(Rect2(ex - 1, 29, 1, 1), Color("5ad070"))
		"dusk":
			var sx := 200.0 - scroll.x * 0.02
			draw_circle(Vector2(sx, 150), 22, Color(0.75, 0.9, 1.0, 0.18))
			draw_circle(Vector2(sx, 150), 13, Color(0.85, 0.95, 1.0, 0.35))
			draw_circle(Vector2(sx, 150), 7, Color("f0f8ff"))
	# parallax layers
	for layer in _layers:
		var f: float = layer[0]
		var col: Color = layer[1]
		var hs: PackedInt32Array = layer[2]
		var from_top: bool = layer[3]
		var off := int(scroll.x * f)
		var yoff := scroll.y * f * 0.3
		for x in range(0, 320, 2):
			var hh := hs[posmod(x + off, hs.size())]
			if from_top:
				draw_rect(Rect2(x, 0, 2, hh - 20 - yoff), col)
			else:
				var top := 240.0 - hh - yoff + 30.0
				draw_rect(Rect2(x, top, 2, 260 - top), col)
				draw_rect(Rect2(x, top, 2, 1), col.lightened(0.12))
