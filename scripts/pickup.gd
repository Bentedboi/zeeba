extends Node2D
## Red rocks (SPEED), dirt (STRENGTH) and quest items lying around the level.
## Rocks and dirt grow back, so nobody can get stuck. Origin at the ground.

const REGROW := 10.0

var main
var kind := "speed"   # speed, strength, quest
var quest := ""
var t := 0.0
var regrow := 0.0


func _ready() -> void:
	t = randf() * 3.0


func _physics_process(delta: float) -> void:
	t += delta
	if regrow > 0.0:
		regrow -= delta
		visible = regrow <= 0.0
		return
	if main.princess.hitbox().intersects(Rect2(position + Vector2(-7, -14), Vector2(14, 14))):
		_collect()
	queue_redraw()


func _collect() -> void:
	match kind:
		"speed":
			Game.speed_charge = minf(Game.SPEED_MAX, Game.speed_charge + 4.0)
			Sfx.play("crunch", 1.3)
			main.float_text(position + Vector2(0, -18), "SPEED!", Color(Art.PAL.n))
			main.debris(position + Vector2(0, -4), Color(Art.PAL.r), 4)
			regrow = REGROW
			visible = false
			if not Game.flags.has("redrock"):
				Game.flags["redrock"] = true
				main.say(Story.FIRST_REDROCK)
		"strength":
			if Game.strength >= Game.STRENGTH_MAX:
				return
			Game.strength += 1
			Sfx.play("crunch", 0.8)
			main.float_text(position + Vector2(0, -18), "STRENGTH!", Color(Art.PAL.u))
			main.debris(position + Vector2(0, -4), Color(Art.PAL.d), 4)
			regrow = REGROW
			visible = false
			if not Game.flags.has("dirt"):
				Game.flags["dirt"] = true
				main.say(Story.FIRST_DIRT)
		"quest":
			Game.carrying.append(quest)
			Sfx.play("pickup")
			var q: Dictionary = Story.QUESTS[quest]
			main.say(q.found + ["|* (Press C to give the " + q.name + " to DALE.)"])
			queue_free()


func _draw() -> void:
	var bob := roundf(sin(t * 3.0) * 1.5)
	match kind:
		"speed":
			draw_texture(Art.tex("redrock"), Vector2(-6, -9))
			if int(t * 4.0) % 5 == 0:
				draw_rect(Rect2(2, -8, 1, 1), Color.WHITE)
		"strength":
			draw_texture(Art.tex("dirt"), Vector2(-7, -8))
			if int(t * 4.0) % 5 == 2:
				draw_rect(Rect2(-2, -7, 1, 1), Color.WHITE)
		"quest":
			var tex := Art.tex(Story.QUESTS[quest].sprite)
			var s := tex.get_size()
			# soft glow so it reads as "pick me up"
			var glow := 0.25 + 0.15 * sin(t * 4.0)
			draw_circle(Vector2(0, -s.y / 2.0 - 3 + bob), s.x * 0.7, Color(1, 0.95, 0.6, glow * 0.4))
			draw_texture(tex, Vector2(-floorf(s.x / 2.0), -s.y - 3 + bob))
