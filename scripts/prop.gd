extends Node2D
## Everything else placed in a level: signs, checkpoint beacons, Blorb's shop,
## Gurble, water springs, the exit, the rocket, the bench, the viewpoint and
## Dale's crashed pod. Origin is at the ground under the prop.

const INTERACT := ["sign", "shop", "gurble", "bench", "view"]

var main
var kind := ""
var text := ""        # sign text
var quest := ""       # bench / view / gurble quest id
var index := 0        # checkpoint number
var lit := false
var near := false
var t := 0.0
var cooldown := 0.0
var launch := -1.0    # rocket launch timer


func _physics_process(delta: float) -> void:
	t += delta
	cooldown = maxf(0.0, cooldown - delta)
	var p: Node2D = main.princess
	var d: Vector2 = p.position - position
	near = absf(d.x) < 16.0 and d.y > -20.0 and d.y < 8.0
	match kind:
		"checkpoint":
			if near and not lit:
				main.activate_checkpoint(self)
		"spring":
			if near and cooldown <= 0.0 and Game.water < Game.water_max() - 1.0:
				Game.water = Game.water_max()
				cooldown = 3.0
				Sfx.play("drink")
				main.toast("* (DALE refilled his water. *glug glug glug*)")
		"exit":
			if near:
				main.reach_exit()
		"rocket":
			if near and launch < 0.0:
				main.reach_rocket(self)
			if launch >= 0.0:
				launch += delta
	queue_redraw()


func interactable() -> bool:
	return kind in INTERACT


func _draw() -> void:
	var k := Color(Art.PAL.k)
	match kind:
		"sign":
			draw_rect(Rect2(-1, -8, 3, 8), Color(Art.PAL.D))
			draw_rect(Rect2(-9, -20, 18, 13), k)
			draw_rect(Rect2(-8, -19, 16, 11), Color(Art.PAL.d))
			draw_rect(Rect2(-8, -19, 16, 1), Color(Art.PAL.u))
			for i in 3:
				draw_rect(Rect2(-6, -17 + i * 3, 12 - i * 3, 1), Color(Art.PAL.D))
		"checkpoint":
			var tex := Art.tex("beacon", {} if lit else Art.BEACON_OFF)
			draw_texture(tex, Vector2(-4, -16))
			if lit:
				var r := 6.0 + fmod(t * 10.0, 10.0)
				draw_arc(Vector2(0, -13), r, 0, TAU, 16, Color(0.35, 0.9, 0.75, 1.0 - r / 16.0), 1.0)
		"shop":
			# stall: poles, striped awning, counter, Blorb behind it
			draw_rect(Rect2(-17, -34, 2, 34), k)
			draw_rect(Rect2(15, -34, 2, 34), k)
			draw_texture(Art.tex("shopkeep"), Vector2(-8, -30 + roundf(sin(t * 2.0))))
			for i in 9:
				var col := Color(Art.PAL.v) if i % 2 == 0 else Color(Art.PAL.w)
				draw_rect(Rect2(-18 + i * 4, -38, 4, 6), col)
			draw_rect(Rect2(-18, -39, 36, 1), k)
			draw_rect(Rect2(-18, -32, 36, 1), k)
			draw_rect(Rect2(-14, -12, 28, 12), k)
			draw_rect(Rect2(-13, -11, 26, 10), Color(Art.PAL.d))
			draw_rect(Rect2(-13, -11, 26, 2), Color(Art.PAL.u))
			PixelFont.draw(self, Vector2(-3, -9), "$", Color(Art.PAL.y))
		"gurble":
			var hop := absf(sin(t * 3.0)) * 3.0
			draw_texture(Art.tex("shopkeep", Art.GURBLE_SWAP), Vector2(-8, -24 - roundf(hop)))
		"spring":
			draw_rect(Rect2(-9, -5, 18, 5), k)
			draw_rect(Rect2(-8, -4, 16, 3), Color(Art.PAL.a))
			draw_rect(Rect2(-8, -2, 16, 1), Color(Art.PAL.A))
			for i in 3:
				var ph := fmod(t * 1.3 + i * 0.37, 1.0)
				draw_rect(Rect2(-5 + i * 4, -6 - ph * 12.0, 2, 2), Color(0.6, 0.9, 1.0, 1.0 - ph))
		"exit":
			# a glowing archway into the next area
			draw_rect(Rect2(-14, -36, 28, 36), k)
			draw_rect(Rect2(-12, -34, 24, 34), Color(Art.PAL.K))
			draw_rect(Rect2(-9, -30, 18, 30), Color("0a0612"))
			var a := 0.5 + 0.3 * sin(t * 4.0)
			draw_rect(Rect2(-9, -30, 18, 30), Color(1.0, 0.85, 0.4, a * 0.25))
			PixelFont.draw(self, Vector2(-3, -20 + roundf(sin(t * 5.0))), "`", Color(1, 0.9, 0.5, a + 0.2))
		"rocket":
			_draw_rocket()
		"bench":
			draw_rect(Rect2(-11, -9, 22, 3), k)
			draw_rect(Rect2(-10, -8, 20, 1), Color(Art.PAL.u))
			draw_rect(Rect2(-11, -15, 22, 3), k)
			draw_rect(Rect2(-10, -14, 20, 1), Color(Art.PAL.u))
			draw_rect(Rect2(-9, -6, 2, 6), k)
			draw_rect(Rect2(7, -6, 2, 6), k)
			draw_rect(Rect2(-9, -14, 2, 6), k)
			draw_rect(Rect2(7, -14, 2, 6), k)
		"view":
			# little telescope on a tripod
			draw_line(Vector2(0, -8), Vector2(-5, 0), k, 1.0)
			draw_line(Vector2(0, -8), Vector2(5, 0), k, 1.0)
			draw_line(Vector2(0, -8), Vector2(0, 0), k, 1.0)
			draw_set_transform(Vector2(0, -10), -0.5, Vector2.ONE)
			draw_rect(Rect2(-7, -2, 14, 4), k)
			draw_rect(Rect2(-6, -1, 12, 2), Color(Art.PAL.y))
			draw_rect(Rect2(5, -2, 2, 4), Color(Art.PAL.a))
			draw_set_transform(Vector2.ZERO)
		"pod":
			draw_set_transform(Vector2(0, -7), 0.35, Vector2.ONE)
			draw_rect(Rect2(-14, -8, 28, 15), k)
			draw_rect(Rect2(-13, -7, 26, 13), Color(Art.PAL.z))
			draw_rect(Rect2(-13, 2, 26, 4), Color(Art.PAL.Z))
			draw_rect(Rect2(-5, -5, 8, 6), Color(Art.PAL.k))
			draw_rect(Rect2(-4, -4, 6, 4), Color(0.4, 0.75, 0.9, 1))
			draw_rect(Rect2(-13, -7, 26, 1), Color.WHITE)
			draw_rect(Rect2(8, -7, 3, 13), Color(Art.PAL.o))
			draw_set_transform(Vector2.ZERO)
			for i in 4:
				var ph := fmod(t * 0.5 + i * 0.25, 1.0)
				var r := 2.0 + ph * 5.0
				draw_circle(Vector2(6 + ph * 10.0, -14 - ph * 30.0), r, Color(0.55, 0.5, 0.6, 0.55 * (1.0 - ph)))
	if near and interactable() and not main.busy():
		var by := -44.0 if kind == "shop" else -34.0
		PixelFont.draw(self, Vector2(-2, by + roundf(sin(t * 6.0))), "^", Color.WHITE, 1, k)


func _draw_rocket() -> void:
	var k := Color(Art.PAL.k)
	var rise := 0.0
	if launch > 1.0:
		rise = pow(launch - 1.0, 2.0) * 60.0
	var shake_x := 0.0
	if launch > 0.0 and launch < 1.2:
		shake_x = 1.0 if int(launch * 30.0) % 2 == 0 else -1.0
	var o := Vector2(shake_x, -rise)
	# launch pad (stays on the ground)
	draw_rect(Rect2(-22, -4, 44, 4), k)
	draw_rect(Rect2(-21, -3, 42, 2), Color(Art.PAL.Z))
	draw_rect(Rect2(-20, -40, 3, 36), Color(Art.PAL.Z))
	draw_rect(Rect2(-20, -40, 8, 2), Color(Art.PAL.Z))
	if launch > 0.0:
		var fl := 8.0 + (int(launch * 20.0) % 3) * 3.0 + minf(launch * 12.0, 24.0)
		draw_rect(Rect2(o.x - 6, o.y - 4, 12, fl), Color(Art.PAL.y))
		draw_rect(Rect2(o.x - 3, o.y - 4, 6, fl * 0.7), Color.WHITE)
		draw_rect(Rect2(o.x - 8, o.y - 4, 2, fl * 0.5), Color(Art.PAL.o))
		draw_rect(Rect2(o.x + 6, o.y - 4, 2, fl * 0.5), Color(Art.PAL.o))
	# fins
	draw_rect(Rect2(o.x - 14, o.y - 18, 6, 14), k)
	draw_rect(Rect2(o.x - 13, o.y - 17, 5, 12), Color(Art.PAL.v))
	draw_rect(Rect2(o.x + 8, o.y - 18, 6, 14), k)
	draw_rect(Rect2(o.x + 8, o.y - 17, 5, 12), Color(Art.PAL.v))
	# body
	draw_rect(Rect2(o.x - 9, o.y - 52, 18, 48), k)
	draw_rect(Rect2(o.x - 8, o.y - 51, 16, 46), Color.WHITE)
	draw_rect(Rect2(o.x + 3, o.y - 51, 5, 46), Color(Art.PAL.W))
	draw_rect(Rect2(o.x - 8, o.y - 12, 16, 3), Color(Art.PAL.v))
	# nose
	for i in 10:
		var half := int(i * 0.8) + 1
		draw_rect(Rect2(o.x - half - 1, o.y - 62 + i, half * 2 + 2, 1), k)
		draw_rect(Rect2(o.x - half, o.y - 62 + i, half * 2, 1), Color(Art.PAL.v))
	# window (Dale waves from it once he's aboard)
	draw_circle(Vector2(o.x, o.y - 36), 5, k)
	draw_circle(Vector2(o.x, o.y - 36), 4, Color(0.45, 0.8, 0.95))
	if launch >= 0.0:
		draw_texture_rect_region(Art.tex("dale"), Rect2(o.x - 4, o.y - 40, 8, 6), Rect2(4, 3, 8, 6))
	draw_rect(Rect2(o.x - 2, o.y - 39, 2, 2), Color(1, 1, 1, 0.8))
	# smoke
	if launch > 0.0:
		for i in 8:
			var ph := fmod(launch * 0.8 + i * 0.125, 1.0)
			var side := -1.0 if i % 2 == 0 else 1.0
			draw_circle(Vector2(side * (6 + ph * 30.0), -4 - ph * 8.0), 3 + ph * 8.0, Color(0.85, 0.8, 0.85, 0.6 * (1.0 - ph)))
