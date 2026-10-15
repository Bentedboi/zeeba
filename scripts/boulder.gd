extends StaticBody2D
## A connected cluster of cracked boulders. One punch with STRENGTH (or a
## rover ram) smashes the whole cluster.

var level
var main
var cells: Array[Vector2i] = []


func setup(group: Array[Vector2i]) -> void:
	cells = group
	collision_layer = 1
	for c in cells:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(16, 16)
		cs.shape = r
		cs.position = Vector2(c) * 16.0 + Vector2(8, 8)
		add_child(cs)


func rect() -> Rect2:
	var r := Rect2(Vector2(cells[0]) * 16.0, Vector2(16, 16))
	for c in cells:
		r = r.merge(Rect2(Vector2(c) * 16.0, Vector2(16, 16)))
	return r


func smash() -> void:
	for c in cells:
		level.boulder_cells.erase(c)
		main.debris(Vector2(c) * 16.0 + Vector2(8, 8), Color(Art.BOULDER_SWAP.j), 7)
	Sfx.play("smash")
	main.shake(4.0)
	queue_free()


func _draw() -> void:
	var tex := Art.tex("boulder", Art.BOULDER_SWAP)
	for c in cells:
		draw_texture(tex, Vector2(c) * 16.0)
