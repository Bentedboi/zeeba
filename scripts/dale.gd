extends Node2D
## Dale, the very helpless human. He walks exactly along Zeeba's trail a few
## steps behind her, like a Deltarune party member. Origin is at his feet.

const FOLLOW := 22.0

var princess
var main
var facing := 1
var moving := false
var anim_t := 0.0
var invuln := 0.0
var _last := Vector2.ZERO
var _dist := FOLLOW
var _still := 0.0
var _drop := 0.0
var _side := 0.0


func _grounded(p: Vector2) -> bool:
	for dx in [-3.0, 0.0, 3.0]:
		if main.level.is_floor_px(p + Vector2(dx, 1.0)):
			return true
	return false


func _physics_process(delta: float) -> void:
	invuln = maxf(0.0, invuln - delta)
	if Game.riding:
		position = princess.position
		visible = false
		return
	visible = true
	# When Zeeba stops, Dale shuffles along her path until he's on solid
	# ground, instead of freezing mid-way through one of her jumps.
	var want := FOLLOW
	if princess.is_on_floor() and princess.velocity.length() < 5.0:
		_still += delta
	else:
		_still = 0.0
	if _still > 0.12:
		while want > 12.0 and not _grounded(trail_point(princess.trail, want)):
			want -= 2.0
	_dist = move_toward(_dist, want, 70.0 * delta)
	var p: Vector2 = trail_point(princess.trail, _dist)
	# Still airborne on her path? Then he just drops down to the floor.
	var drop_to := 0.0
	if _still > 0.12 and not _grounded(p):
		for i in 64:
			if _grounded(p + Vector2(0, i)):
				drop_to = i
				break
	_drop = move_toward(_drop, drop_to, 220.0 * delta)
	p.y += _drop
	# Don't stand inside Zeeba (happens after she drops straight down).
	var side_to := 0.0
	if _still > 0.12 and absf(p.x - princess.position.x) < 10.0:
		var back := -float(princess.facing) * 14.0
		var spot := Vector2(princess.position.x + back, princess.position.y)
		if _grounded(spot) and not main.level.is_solid_px(spot + Vector2(0, -8)):
			side_to = spot.x - p.x
	_side = move_toward(_side, side_to, 40.0 * delta)
	p.x += _side
	moving = p.distance_to(_last) > 0.2
	if absf(p.x - _last.x) > 0.2:
		facing = 1 if p.x > _last.x else -1
	_last = p
	position = p
	if moving:
		anim_t += delta
	queue_redraw()


static func trail_point(trail: PackedVector2Array, dist: float) -> Vector2:
	var remaining := dist
	for i in range(trail.size() - 1, 0, -1):
		var seg := trail[i] - trail[i - 1]
		var length := seg.length()
		if length >= remaining:
			return trail[i] - seg / length * remaining
		remaining -= length
	return trail[0]


func hitbox() -> Rect2:
	return Rect2(position + Vector2(-5, -20), Vector2(10, 20))


func hurt(why: String) -> void:
	if invuln > 0.0 or Game.riding or not visible:
		return
	Game.dale_hp -= 1
	invuln = 1.6
	Sfx.play("hurt", 0.75)
	main.float_text(position + Vector2(0, -28), "OW!", Color(Art.PAL.v))
	if Game.dale_hp <= 0:
		main.party_down("DALE fainted! (" + why + ")")
	else:
		main.toast("* " + why)


func _draw() -> void:
	if invuln > 0.0 and int(invuln * 16.0) % 2 == 0:
		return
	var frame := "dale"
	if invuln > 0.9:
		frame = "dale_hurt"
	elif moving:
		frame = ["dale_walk1", "dale", "dale_walk2", "dale"][int(anim_t * 9.0) % 4]
	var shiver := 0.0
	if Game.level == 1 and not Game.quests_done.has("blanket"):
		shiver = 1.0 if int(Time.get_ticks_msec() / 70) % 2 == 0 else 0.0
	draw_set_transform(Vector2(shiver, 0), 0.0, Vector2(facing, 1))
	if Game.quests_done.has("blanket"):  # cape
		var cape := Color(Art.PAL.a)
		draw_rect(Rect2(-7, -13, 3, 11), Color(Art.PAL.k))
		draw_rect(Rect2(-6, -13, 2, 10), cape)
	draw_texture(Art.tex(frame), Vector2(-8, -24))
	draw_rect(Rect2(3, -22, 1, 2), Color(1, 1, 1, 0.8))  # helmet glint
	if Game.quests_done.has("glasses"):
		draw_rect(Rect2(-4, -19, 8, 1), Color(Art.PAL.k))
		draw_rect(Rect2(-4, -18, 3, 2), Color(Art.PAL.B))
		draw_rect(Rect2(1, -18, 3, 2), Color(Art.PAL.B))
	if Game.quests_done.has("flower"):
		draw_rect(Rect2(-6, -22, 2, 2), Color(Art.PAL.f))
		draw_rect(Rect2(-6, -20, 1, 2), Color(Art.PAL.G))
	if Game.upgrades.has("hat"):
		draw_rect(Rect2(-9, -25, 18, 2), Color(Art.PAL.k))
		draw_rect(Rect2(-8, -25, 16, 1), Color(Art.PAL.y))
		draw_rect(Rect2(-4, -28, 8, 3), Color(Art.PAL.y))
		draw_rect(Rect2(-4, -26, 8, 1), Color(Art.PAL.v))
	draw_set_transform(Vector2.ZERO)
	# Sweat drop when thirsty.
	if Game.water < Game.water_max() * 0.3:
		var t := fmod(Time.get_ticks_msec() / 600.0, 1.0)
		draw_rect(Rect2(7, -22 + t * 6.0, 2, 2), Color(Art.PAL.a))
