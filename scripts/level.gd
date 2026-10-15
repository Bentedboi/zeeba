extends Node2D
## Tile map for one level: draws the terrain, builds merged collision
## rectangles, and answers tile queries. Object characters are handed back
## to main.gd as spawn requests.

const T := 16
const UNDER := 5   # rows of bedrock drawn below the map so the camera can sit lower

var rows: Array = []
var w := 0
var h := 0
var theme := "rust"
var spawns: Array = []          # [char, Vector2i]
var boulder_cells := {}         # Vector2i -> true (still standing)
var boulder_groups: Array = []  # Array of Array[Vector2i]
var _deco: Array = []           # [kind, Vector2, variant]


func build(index: int) -> void:
	var data: Dictionary = Levels.LIST[index]
	theme = data.theme
	rows = Levels.build_map(index)
	h = rows.size()
	w = rows[0].length()
	for y in h:
		for x in w:
			var ch: String = rows[y][x]
			if ch in [".", "#", "=", "^"]:
				continue
			if ch == "B":
				boulder_cells[Vector2i(x, y)] = true
			else:
				spawns.append([ch, Vector2i(x, y)])
	_group_boulders()
	_build_collision()
	_build_deco()
	queue_redraw()


func char_at(c: Vector2i) -> String:
	if c.x < 0 or c.x >= w or c.y < 0 or c.y >= h:
		return "."
	return rows[c.y][c.x]


func is_ground(c: Vector2i) -> bool:
	if c.x < 0 or c.x >= w:
		return true
	return char_at(c) == "#" or boulder_cells.has(c)


func is_solid_px(p: Vector2) -> bool:
	return is_ground(Vector2i(floori(p.x / T), floori(p.y / T)))


## Something a walker can stand on (ground, boulder or platform).
func is_floor_px(p: Vector2) -> bool:
	var c := Vector2i(floori(p.x / T), floori(p.y / T))
	return is_ground(c) or char_at(c) == "="


func spike_rects() -> Array:
	var out := []
	for y in h:
		for x in w:
			if rows[y][x] == "^":
				out.append(Rect2(x * T + 2, y * T + 9, T - 4, 7))
	return out


# --- build ---------------------------------------------------------------

func _group_boulders() -> void:
	var seen := {}
	for c in boulder_cells:
		if seen.has(c):
			continue
		var group: Array[Vector2i] = []
		var stack: Array[Vector2i] = [c]
		seen[c] = true
		while not stack.is_empty():
			var cur: Vector2i = stack.pop_back()
			group.append(cur)
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n: Vector2i = cur + d
				if boulder_cells.has(n) and not seen.has(n):
					seen[n] = true
					stack.append(n)
		boulder_groups.append(group)


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	# Horizontal runs per row, merged downward when the run below matches.
	var open := {}  # "x0,x1" -> Rect2i being extended
	var rects: Array[Rect2i] = []
	for y in h:
		var runs := {}
		var x := 0
		while x < w:
			if rows[y][x] == "#":
				var x0 := x
				while x < w and rows[y][x] == "#":
					x += 1
				runs["%d,%d" % [x0, x]] = Rect2i(x0, y, x - x0, 1)
			else:
				x += 1
		var next_open := {}
		for key in runs:
			if open.has(key):
				var r: Rect2i = open[key]
				r.size.y += 1
				next_open[key] = r
			else:
				next_open[key] = runs[key]
		for key in open:
			if not next_open.has(key) or next_open[key].position.y != open[key].position.y:
				rects.append(open[key])
		open = next_open
	for key in open:
		rects.append(open[key])
	for r in rects:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(r.size) * T
		cs.shape = shape
		cs.position = Vector2(r.position) * T + shape.size / 2.0
		body.add_child(cs)
	# One-way platforms.
	for y in h:
		var x := 0
		while x < w:
			if rows[y][x] == "=":
				var x0 := x
				while x < w and rows[y][x] == "=":
					x += 1
				var cs := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - x0) * T, 6)
				cs.shape = shape
				cs.one_way_collision = true
				cs.position = Vector2(x0 * T + shape.size.x / 2.0, y * T + 3)
				body.add_child(cs)
			else:
				x += 1
	# Side walls so nobody walks off the ends of the map.
	for side in [-8.0, w * T + 8.0]:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16, h * T * 3)
		cs.shape = shape
		cs.position = Vector2(side, 0)
		body.add_child(cs)


func _build_deco() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(theme + str(w))
	for y in h:
		for x in w:
			if rows[y][x] != "#":
				continue
			var above := char_at(Vector2i(x, y - 1))
			var below := char_at(Vector2i(x, y + 1))
			if above == "." and rng.randf() < 0.22:
				var kind := "pebble" if rng.randf() < 0.65 else "crystal"
				_deco.append([kind, Vector2(x * T + rng.randi_range(2, 12), y * T), rng.randi_range(0, 2)])
			if theme == "cave" and below == "." and y > 0 and rng.randf() < 0.35:
				_deco.append(["stalactite", Vector2(x * T + rng.randi_range(3, 11), (y + 1) * T), rng.randi_range(4, 12)])


# --- drawing -------------------------------------------------------------

func _draw() -> void:
	var th: Dictionary = Art.THEMES[theme]
	var dark := Color(th.dark).darkened(0.35)
	var outline := Color(Art.PAL.k)
	for y in h:
		for x in w:
			var ch: String = rows[y][x]
			var p := Vector2(x * T, y * T)
			match ch:
				"#":
					var top := char_at(Vector2i(x, y - 1)) != "#" and y > 0
					var v := absi(hash(Vector2i(x, y))) % 4
					draw_texture(Art.tile(theme, "top" if top else "fill", v), p)
					if top:
						draw_rect(Rect2(p.x, p.y - 1, T, 1), outline)
					if x > 0 and rows[y][x - 1] != "#":
						draw_rect(Rect2(p.x, p.y, 1, T), dark)
					if x < w - 1 and rows[y][x + 1] != "#":
						draw_rect(Rect2(p.x + T - 1, p.y, 1, T), dark)
					if y < h - 1 and rows[y + 1][x] != "#":
						draw_rect(Rect2(p.x, p.y + T - 1, T, 1), dark)
				"=":
					draw_texture(Art.tile(theme, "plat"), p)
				"^":
					draw_texture(Art.tile(theme, "spike"), p + Vector2(0, 6))
	# bedrock under the map, and dark chasms under pits
	var void_col := Color(th.dark).darkened(0.7)
	for x in w:
		var px := x * T
		if rows[h - 1][x] == "#":
			for i in UNDER:
				var v := absi(hash(Vector2i(x, h + i))) % 4
				draw_texture(Art.tile(theme, "fill", v), Vector2(px, (h + i) * T), Color.WHITE.darkened(0.1 + i * 0.13))
		else:
			for i in 8:
				var a := clampf(i / 5.0, 0.0, 1.0)
				draw_rect(Rect2(px, (h - 2) * T + i * 12, T, 12), Color(void_col, a))
			draw_rect(Rect2(px, (h + 4) * T, T, UNDER * T), void_col)
	var c1 := Color(th.crystal)
	var c2 := Color(th.crystal2)
	for d in _deco:
		var p: Vector2 = d[1]
		match d[0]:
			"pebble":
				draw_rect(Rect2(p.x, p.y - 2, 3 + d[2], 2), Color(th.spec))
				draw_rect(Rect2(p.x, p.y - 3, 2 + d[2], 1), Color(th.top2))
			"crystal":
				var hgt: int = 4 + d[2] * 2
				for i in hgt:
					var half := int((hgt - i) / 3.0)
					draw_rect(Rect2(p.x - half, p.y - 1 - i, half + 1, 1), c1)
					draw_rect(Rect2(p.x + 1, p.y - 1 - i, half, 1), c2)
			"stalactite":
				var length: int = d[2]
				for i in length:
					var half := int((length - i) / 4.0)
					draw_rect(Rect2(p.x - half, p.y + i, half * 2 + 1, 1), Color(th.body) if i < length - 2 else Color(th.top2))
