extends CharacterBody2D
## Princess Zeeba. Run, variable-height jump, stomp, punch, and the rover.
## Origin is at her feet.

const RUN := 105.0
const RUN_BOOST := 185.0
const RUN_ROVER := 175.0
const ACCEL := 1000.0
const AIR_ACCEL := 760.0
const GRAV := 820.0
const JUMP_V := 310.0
const JUMP_ROVER := 255.0
const MAX_FALL := 430.0
const COYOTE := 0.1
const BUFFER := 0.12
const TRAIL_MAX := 240

var main
var facing := 1
var trail := PackedVector2Array()
var invuln := 0.0
var punch_t := 0.0
var hurt_t := 0.0
var anim_t := 0.0
var coyote := 0.0
var buffer := 0.0
var jumping := false
var frozen := false
var shape: CollisionShape2D
var _ghosts: Array = []


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(50)
	shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	add_child(shape)
	apply_shape()
	reset_trail()


func apply_shape() -> void:
	var r: RectangleShape2D = shape.shape
	if Game.riding:
		r.size = Vector2(26, 14)
		shape.position = Vector2(0, -7)
	else:
		r.size = Vector2(10, 20)
		shape.position = Vector2(0, -10)


func hitbox() -> Rect2:
	if Game.riding:
		return Rect2(position + Vector2(-13, -14), Vector2(26, 14))
	return Rect2(position + Vector2(-5, -20), Vector2(10, 20))


func reset_trail() -> void:
	trail = PackedVector2Array([position - Vector2(facing * 22, 0), position])


func _physics_process(delta: float) -> void:
	anim_t += delta
	invuln = maxf(0.0, invuln - delta)
	punch_t = maxf(0.0, punch_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	Game.speed_charge = maxf(0.0, Game.speed_charge - delta)
	var locked := frozen or Game.input_lock > 0.0

	var dir := 0.0
	if not locked and hurt_t <= 0.0:
		dir = Input.get_axis("left", "right")
	var top := RUN
	if Game.riding:
		top = RUN_ROVER
	elif Game.speed_charge > 0.0:
		top = RUN_BOOST
	if hurt_t <= 0.0:
		var acc := ACCEL if is_on_floor() else AIR_ACCEL
		if dir == 0.0 and is_on_floor():
			acc *= 1.4
		velocity.x = move_toward(velocity.x, dir * top, acc * delta)
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1

	velocity.y = minf(velocity.y + GRAV * delta, MAX_FALL)
	if is_on_floor():
		coyote = COYOTE
		jumping = false
	else:
		coyote -= delta
	if not locked and Input.is_action_just_pressed("jump"):
		buffer = BUFFER
	else:
		buffer -= delta
	if buffer > 0.0 and coyote > 0.0:
		velocity.y = -(JUMP_ROVER if Game.riding else JUMP_V)
		buffer = 0.0
		coyote = 0.0
		jumping = true
		Sfx.play("jump", 0.8 if Game.riding else 1.0)
	if jumping and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y *= 0.45
		jumping = false

	var pre_vx := velocity.x
	move_and_slide()
	if Game.riding and absf(pre_vx) > 110.0:
		for i in get_slide_collision_count():
			var b := get_slide_collision(i).get_collider()
			if b != null and b.has_method("smash"):
				b.smash()
				velocity.x = pre_vx * 0.5
				break

	if trail[-1].distance_to(position) >= 2.0:
		trail.append(position)
		if trail.size() > TRAIL_MAX:
			trail.remove_at(0)

	if Game.speed_charge > 0.0 and not Game.riding and absf(velocity.x) > RUN and int(anim_t * 60) % 4 == 0:
		_ghosts.append([position, facing, 0.25, _frame()])
	for g in _ghosts:
		g[2] -= delta
	_ghosts = _ghosts.filter(func(g): return g[2] > 0.0)

	if not locked:
		if Input.is_action_just_pressed("punch") and not Game.riding and punch_t <= 0.0:
			punch_t = 0.22
			Sfx.play("punch")
			main.punch(self)
		if Input.is_action_just_pressed("up"):
			main.interact()
		if Input.is_action_just_pressed("talk"):
			main.talk_to_dale()
		if Input.is_action_just_pressed("rover"):
			toggle_rover()
	queue_redraw()


func toggle_rover() -> void:
	if not Game.upgrades.has("rover"):
		main.toast("* (You don't have a rover. Blorb sells one!)")
		return
	if not is_on_floor():
		return
	var was := Game.riding
	Game.riding = not was
	apply_shape()
	if test_move(global_transform, Vector2(0, -1)):
		Game.riding = was  # no room to change
		apply_shape()
		return
	Sfx.play("rover")
	reset_trail()


func hurt(from_x: float) -> void:
	if invuln > 0.0 or frozen:
		return
	Game.princess_hp -= 1
	invuln = 1.3
	hurt_t = 0.3
	jumping = false
	var away := 1.0 if position.x >= from_x else -1.0
	velocity = Vector2(away * 140.0, -210.0)
	Sfx.play("hurt")
	main.shake(3.0)
	if Game.princess_hp <= 0:
		main.party_down("ZEEBA is too worn out to go on...")


func bounce() -> void:
	velocity.y = -JUMP_V * (0.95 if Input.is_action_pressed("jump") else 0.7)
	jumping = Input.is_action_pressed("jump")


func _frame() -> String:
	if punch_t > 0.0:
		return "princess_jump" if not is_on_floor() else "princess_run1"
	if not is_on_floor():
		return "princess_jump"
	if absf(velocity.x) > 8.0:
		var speed_mul := 1.6 if absf(velocity.x) > RUN + 5.0 else 1.0
		return ["princess_run1", "princess", "princess_run2", "princess"][int(anim_t * 10.0 * speed_mul) % 4]
	return "princess"


func _draw() -> void:
	for g in _ghosts:
		var gp: Vector2 = g[0] - position
		draw_set_transform(gp, 0.0, Vector2(g[1], 1))
		draw_texture(Art.tex(g[3]), Vector2(-8, -24), Color(1.0, 0.35, 0.25, g[2] * 2.0))
	draw_set_transform(Vector2.ZERO)
	if invuln > 0.0 and int(invuln * 16.0) % 2 == 0:
		return
	if Game.riding:
		draw_rover(self, facing, anim_t, absf(velocity.x), true)
		return
	var bob := 0.0
	if is_on_floor() and absf(velocity.x) < 8.0:
		bob = 1.0 if int(anim_t * 2.0) % 2 == 0 else 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	draw_texture(Art.tex(_frame()), Vector2(-8, -24 - bob))
	if punch_t > 0.0:
		var k := 1.0 - punch_t / 0.22
		var fx := 7.0 + k * 7.0
		draw_rect(Rect2(fx, -14, 4, 4), Color(Art.PAL.g))
		draw_rect(Rect2(fx + 4, -14, 1, 4), Color(Art.PAL.k))
		if Game.strength > 0:
			draw_rect(Rect2(fx + 6, -17, 2, 2), Color(Art.PAL.u))
			draw_rect(Rect2(fx + 7, -11, 2, 2), Color(Art.PAL.u))
	draw_set_transform(Vector2.ZERO)
	if Game.strength > 0 and int(anim_t * 6.0) % 3 == 0:
		var sx := -6.0 + fmod(anim_t * 37.0, 12.0)
		draw_rect(Rect2(sx, -22.0 - fmod(anim_t * 20.0, 6.0), 1, 1), Color(Art.PAL.u))


## Shared by gameplay and the title screen.
static func draw_rover(ci: CanvasItem, dir: int, t: float, speed: float, with_riders: bool) -> void:
	var k := Color(Art.PAL.k)
	var metal := Color(Art.PAL.z)
	var metal_d := Color(Art.PAL.Z)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
	var bump := 1.0 if speed > 20.0 and int(t * 12.0) % 2 == 0 else 0.0
	# riders
	if with_riders:
		var bt := Art.tex("princess")
		ci.draw_texture_rect_region(bt, Rect2(-1, -24 - bump, 16, 12), Rect2(0, 0, 16, 12))
		var dt := Art.tex("dale")
		ci.draw_texture_rect_region(dt, Rect2(-15, -23 - bump, 16, 12), Rect2(0, 0, 16, 12))
	# dome
	ci.draw_rect(Rect2(-14, -16 - bump, 26, 6), Color(0.75, 0.95, 1.0, 0.18))
	ci.draw_rect(Rect2(-14, -17 - bump, 26, 1), Color(0.85, 0.98, 1.0, 0.7))
	# body
	ci.draw_rect(Rect2(-16, -11 - bump, 32, 7), k)
	ci.draw_rect(Rect2(-15, -10 - bump, 30, 5), metal)
	ci.draw_rect(Rect2(-15, -7 - bump, 30, 2), metal_d)
	ci.draw_rect(Rect2(-12, -9 - bump, 6, 1), Color(Art.PAL.g))
	ci.draw_rect(Rect2(13, -10 - bump, 2, 2), Color(Art.PAL.y))
	# antenna + flag
	ci.draw_rect(Rect2(-15, -24 - bump, 1, 13), k)
	ci.draw_rect(Rect2(-14, -24 - bump, 5, 3), Color(Art.PAL.g))
	# wheels
	for wx in [-11, 0, 11]:
		ci.draw_rect(Rect2(wx - 4, -6, 8, 6), k)
		ci.draw_rect(Rect2(wx - 3, -5, 6, 4), Color(Art.PAL.B))
		var spoke := int(t * speed * 0.3) % 2
		ci.draw_rect(Rect2(wx - 1 + spoke, -4 + spoke, 2, 2), metal)
	ci.draw_set_transform(Vector2.ZERO)
