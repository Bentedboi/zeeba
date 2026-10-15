extends Node2D
## Dust mite: patrols back and forth, turns at walls and ledges.
## It nibbles Dale (and bumps Zeeba). Stomp it or punch it. Origin at its feet.

const SPEED := 24.0

var level
var dir := -1
var t := 0.0
var dead := 0.0   # > 0 while the squash animation plays


func _physics_process(delta: float) -> void:
	t += delta
	if dead > 0.0:
		dead -= delta
		if dead <= 0.0:
			queue_free()
		queue_redraw()
		return
	var nx := position.x + dir * SPEED * delta
	var front := nx + dir * 7.0
	if level.is_solid_px(Vector2(front, position.y - 6.0)) or not level.is_floor_px(Vector2(front, position.y + 2.0)):
		dir = -dir
	else:
		position.x = nx
	queue_redraw()


func alive() -> bool:
	return dead <= 0.0


func hitbox() -> Rect2:
	return Rect2(position + Vector2(-6, -9), Vector2(12, 9))


func squash() -> void:
	dead = 0.45
	Sfx.play("stomp")


func _draw() -> void:
	var tex := Art.tex("mite" if int(t * 6.0) % 2 == 0 else "mite2", Art.MITE_SWAP)
	if dead > 0.0:
		draw_texture_rect(tex, Rect2(-8, -4, 16, 4), false, Color(1, 1, 1, dead / 0.45))
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-dir, 1))
	draw_texture(tex, Vector2(-8, -12))
	draw_set_transform(Vector2.ZERO)
