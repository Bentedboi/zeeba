extends Node2D
## One level of play: builds the map and everything in it, runs the camera,
## Dale's water, enemy contact, quests, checkpoints, deaths and exits.

const LevelScript := preload("res://scripts/level.gd")
const PrincessScript := preload("res://scripts/princess.gd")
const DaleScript := preload("res://scripts/dale.gd")
const MiteScript := preload("res://scripts/mite.gd")
const BoulderScript := preload("res://scripts/boulder.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const PropScript := preload("res://scripts/prop.gd")
const DialogueScript := preload("res://scripts/dialogue.gd")
const HudScript := preload("res://scripts/hud.gd")
const ShopScript := preload("res://scripts/shop.gd")
const BackgroundScript := preload("res://scripts/background.gd")

const WATER_SECONDS := 150.0   # a full (normal) tank lasts this long
const THIRST_TICK := 6.0       # seconds between HP losses on an empty tank

var level
var princess
var dale
var cam: Camera2D
var hud
var dialog
var shop
var bg
var fx
var fade: ColorRect

var props: Array = []
var mites: Array = []
var boulders: Array = []
var checkpoints: Array = []
var spikes: Array = []
var floaters: Array = []    # [pos, text, color, t]
var particles: Array = []   # [pos, vel, color, t]

var _look := 0.0
var _shake := 0.0
var _thirst := 0.0
var _cutscene := false
var _chatter := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	get_tree().paused = false
	_rng.randomize()
	var data: Dictionary = Levels.LIST[Game.level]

	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	bg = BackgroundScript.new()
	bg_layer.add_child(bg)
	bg.setup(data.theme)

	level = LevelScript.new()
	add_child(level)
	level.build(Game.level)
	spikes = level.spike_rects()

	for group in level.boulder_groups:
		var b = BoulderScript.new()
		b.level = level
		b.main = self
		b.setup(group)
		add_child(b)
		boulders.append(b)

	princess = PrincessScript.new()
	princess.main = self
	princess.z_index = 3

	var sign_i := 0
	var start := Vector2(48, 200)
	for s in level.spawns:
		var ch: String = s[0]
		var cell: Vector2i = s[1]
		var foot := Vector2(cell.x * 16 + 8, cell.y * 16 + 16)
		match ch:
			"P":
				start = foot
			"K":
				var p = _prop("checkpoint", foot)
				p.index = checkpoints.size()
				p.lit = Game.checkpoint >= p.index
				checkpoints.append(p)
			"s":
				var p = _prop("sign", foot)
				p.text = data.signs[sign_i] if sign_i < data.signs.size() else "..."
				sign_i += 1
			"$": _prop("shop", foot)
			"w": _prop("spring", foot)
			"E": _prop("exit", foot)
			"X": _prop("rocket", foot)
			"c": _prop("pod", foot)
			"m":
				var m = MiteScript.new()
				m.level = level
				m.position = foot
				m.z_index = 2
				add_child(m)
				mites.append(m)
			"r", "d":
				var pk = PickupScript.new()
				pk.main = self
				pk.kind = "speed" if ch == "r" else "strength"
				pk.position = foot
				pk.z_index = 1
				add_child(pk)
			_:
				var q: String = data["items"].get(ch, "")
				if q == "":
					continue
				var kind: String = Story.QUESTS[q].kind
				if kind == "item":
					if Game.quests_done.has(q) or q in Game.carrying:
						continue
					var pk = PickupScript.new()
					pk.main = self
					pk.kind = "quest"
					pk.quest = q
					pk.position = foot
					pk.z_index = 1
					add_child(pk)
				else:
					var p = _prop({"spot": "bench" if q == "bench" else "view", "npc": "gurble"}[kind], foot)
					p.quest = q

	dale = DaleScript.new()
	dale.princess = princess
	dale.main = self
	dale.z_index = 2
	add_child(dale)
	add_child(princess)
	if Game.checkpoint >= 0 and Game.checkpoint < checkpoints.size():
		start = checkpoints[Game.checkpoint].position + Vector2(10, 0)
	_place_party(start)

	fx = FxNode.new()
	fx.main = self
	fx.z_index = 5
	add_child(fx)

	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = level.w * 16
	cam.limit_bottom = level.h * 16 + LevelScript.UNDER * 16
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(cam)
	cam.position = princess.position + Vector2(0, -20)
	cam.reset_smoothing()

	hud = HudScript.new()
	hud.main = self
	add_child(hud)
	dialog = DialogueScript.new()
	add_child(dialog)
	shop = ShopScript.new()
	shop.main = self
	add_child(shop)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 30
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)
	create_tween().tween_property(fade, "color:a", 0.0, 0.6)

	Sfx.music(data.music)
	_intro.call_deferred()


func _prop(kind: String, foot: Vector2):
	var p = PropScript.new()
	p.main = self
	p.kind = kind
	p.position = foot
	p.z_index = 1 if kind != "rocket" else 4
	add_child(p)
	props.append(p)
	return p


func _place_party(at: Vector2) -> void:
	princess.position = at
	princess.velocity = Vector2.ZERO
	princess.facing = 1
	princess.reset_trail()
	dale.position = at - Vector2(22, 0)
	dale._last = dale.position


func _intro() -> void:
	var data: Dictionary = Levels.LIST[Game.level]
	if Game.checkpoint < 0 and not Game.flags.has("intro%d" % Game.level):
		Game.flags["intro%d" % Game.level] = true
		var lines: Array = Story.INTRO if Game.level == 0 else Story.LEVEL_INTROS[Game.level]
		hud.title_card(data.name)
		if not lines.is_empty():
			await get_tree().create_timer(0.9).timeout
			await dialog.run(lines)
		Game.save_game()
	else:
		hud.title_card(data.name)


# --- per-frame -----------------------------------------------------------

func _physics_process(delta: float) -> void:
	# camera with look-ahead
	_look = lerpf(_look, princess.facing * 28.0, 2.5 * delta)
	var target: Vector2 = princess.position + Vector2(_look, -20)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - 20.0 * delta)
		target += Vector2(_rng.randf_range(-_shake, _shake), _rng.randf_range(-_shake, _shake))
	cam.position = target
	bg.scroll = cam.get_screen_center_position() - Vector2(160, 120)

	if _cutscene:
		return

	# Dale's water
	var rate := Game.water_max() / WATER_SECONDS
	if Game.water_max() > 100.0:
		rate = 100.0 / WATER_SECONDS
	if Game.upgrades.has("hat"):
		rate *= 0.5
	if Game.riding:
		rate *= 0.5
	Game.water = maxf(0.0, Game.water - rate * delta)
	if Game.water < Game.water_max() * 0.25 and Game.bottles > 0:
		Game.bottles -= 1
		Game.water = Game.water_max()
		Sfx.play("drink")
		toast("* (DALE drank a WATER BOTTLE. Ahhh!)")
	if Game.water <= 0.0:
		_thirst += delta
		if _thirst >= THIRST_TICK:
			_thirst = 0.0
			dale.hurt("DALE is parched! Find water!")
	else:
		_thirst = 0.0

	# hazards
	var pbox: Rect2 = princess.hitbox()
	for r in spikes:
		if pbox.intersects(r):
			princess.hurt(r.get_center().x)
			princess.velocity.y = -260.0
	if princess.position.y > level.h * 16 + 40:
		_fell()
		return

	# mites
	var dbox: Rect2 = dale.hitbox()
	for m in mites:
		if not is_instance_valid(m) or not m.alive():
			continue
		var mbox: Rect2 = m.hitbox()
		if pbox.intersects(mbox):
			var from_above: bool = princess.velocity.y > 20.0 and pbox.end.y < mbox.position.y + 7.0
			if from_above or (Game.riding and absf(princess.velocity.x) > 60.0):
				m.squash()
				debris(m.position + Vector2(0, -4), Color(Art.MITE_SWAP.o), 5)
				if from_above:
					princess.bounce()
			else:
				princess.hurt(m.position.x)
		elif dale.visible and dbox.intersects(mbox):
			dale.hurt("A DUST MITE nibbled DALE!")
	mites = mites.filter(func(m): return is_instance_valid(m))

	# effects
	for f in floaters:
		f[3] += delta
		f[0].y -= 18.0 * delta
	floaters = floaters.filter(func(f): return f[3] < 1.0)
	for p in particles:
		p[3] += delta
		p[1].y += 500.0 * delta
		p[0] += p[1] * delta
	particles = particles.filter(func(p): return p[3] < 0.8)
	fx.queue_redraw()


func busy() -> bool:
	return _cutscene or dialog.is_open() or shop.is_open()


# --- actions called by the princess ----------------------------------------

func punch(p: Node2D) -> void:
	var reach := Rect2(p.position + Vector2(-2 if p.facing > 0 else -14, -20), Vector2(16, 18))
	for m in mites:
		if is_instance_valid(m) and m.alive() and reach.intersects(m.hitbox()):
			m.squash()
			debris(m.position + Vector2(0, -4), Color(Art.MITE_SWAP.o), 5)
	for b in boulders:
		if not is_instance_valid(b):
			continue
		if reach.intersects(b.rect().grow(1)):
			if Game.strength > 0:
				Game.strength -= 1
				b.smash()
			else:
				Sfx.play("cancel")
				toast("* (It's cracked, but you're not strong enough. Eat some DIRT!)")
			break
	boulders = boulders.filter(func(b): return is_instance_valid(b))


func interact() -> void:
	if busy():
		return
	var best = null
	for p in props:
		if p.near and p.interactable():
			best = p
	if best == null:
		return
	match best.kind:
		"sign":
			say(["|" + best.text])
		"shop":
			shop.open()
		"gurble":
			if Game.quests_done.has("joke"):
				say(Story.GURBLE_DONE)
			elif "joke" in Game.carrying:
				say(Story.GURBLE_WAIT)
			else:
				Game.carrying.append("joke")
				Sfx.play("pickup")
				say(Story.GURBLE_JOKE)
		"bench", "view":
			if Game.quests_done.has(best.quest):
				say(["|* (A nice spot. You and DALE already enjoyed it.)"])
			else:
				_spot_quest(best.quest)


func _spot_quest(q: String) -> void:
	_cutscene = true
	await dialog.run(Story.QUESTS[q].give)
	_complete(q)
	_cutscene = false


func talk_to_dale() -> void:
	if busy() or Game.riding and Game.carrying.is_empty():
		if Game.riding and not busy():
			say(["dale|Wheee! I love the rover! It's like a little house with wheels!"])
		return
	if not Game.carrying.is_empty():
		_give_items()
		return
	var lines: Array = Story.DALE_THIRSTY if Game.water < Game.water_max() * 0.3 else Story.DALE_CHATTER
	say([lines[_chatter % lines.size()]])
	_chatter += 1


func _give_items() -> void:
	_cutscene = true
	while not Game.carrying.is_empty():
		var q: String = Game.carrying[0]
		await dialog.run(Story.QUESTS[q].give)
		Game.carrying.erase(q)
		_complete(q)
	_cutscene = false


func _complete(q: String) -> void:
	var reward: int = Story.QUESTS[q].reward
	Game.quests_done[q] = true
	Game.add_coins(reward)
	Sfx.play("coin")
	float_text(dale.position + Vector2(0, -30), "+$%d" % reward, Color(Art.PAL.y))
	toast("* NICE THING DONE: %s  (+$%d)" % [Story.QUESTS[q].name, reward])
	Game.save_game()


func activate_checkpoint(cp: Node2D) -> void:
	for c in checkpoints:
		if c.index <= cp.index:
			c.lit = true
	Game.checkpoint = cp.index
	Game.princess_hp = Game.princess_max
	Sfx.play("checkpoint")
	toast("* (The beacon hums. You feel DETERMINED to get Dale home.)")
	Game.save_game()


func reach_exit() -> void:
	if _cutscene:
		return
	_cutscene = true
	princess.frozen = true
	var data: Dictionary = Levels.LIST[Game.level]
	var done := 0
	var total := 0
	for q in data["items"].values():
		total += 1
		if Game.quests_done.has(q):
			done += 1
	await dialog.run(["|* (%s cleared!)" % data.name, "|* Nice things done here: %d / %d" % [done, total]])
	await _fade_out()
	Game.level += 1
	Game.checkpoint = -1
	Game.speed_charge = 0.0
	Game.strength = 0
	Game.save_game()
	get_tree().reload_current_scene()


func reach_rocket(rocket: Node2D) -> void:
	if _cutscene:
		return
	_cutscene = true
	princess.frozen = true
	Game.riding = false
	princess.apply_shape()
	await dialog.run(Story.ENDING)
	dale.visible = false
	dale.set_physics_process(false)
	rocket.launch = 0.0
	Sfx.music("")
	Sfx.play("launch")
	var t := 0.0
	while t < 4.5:
		t += get_physics_process_delta_time()
		shake(1.5 if t < 2.0 else 0.5)
		await get_tree().physics_frame
	await _fade_out()
	Game.flags["won"] = true
	Game.save_game()
	get_tree().change_scene_to_file("res://scenes/ending.tscn")


# --- failure -----------------------------------------------------------------

func _fell() -> void:
	Game.princess_hp -= 1
	Sfx.play("hurt")
	if Game.princess_hp <= 0:
		party_down("ZEEBA fell too many times...")
		return
	toast("* Careful! DALE almost followed you down there!")
	_respawn(false)


func party_down(why: String) -> void:
	if _cutscene:
		return
	_cutscene = true
	princess.frozen = true
	Sfx.play("faint")
	await get_tree().create_timer(0.6).timeout
	await dialog.run(["|* " + why, "|* But Zeeba won't give up on Dale. Back to the last beacon!"])
	_respawn(true)


func retry() -> void:
	_respawn(true)


func _respawn(heal: bool) -> void:
	_cutscene = true
	princess.frozen = true
	await _fade_out()
	if heal:
		Game.refill()
	var at: Vector2 = Vector2(48, 200)
	for s in level.spawns:
		if s[0] == "P":
			at = Vector2(s[1].x * 16 + 8, s[1].y * 16 + 16)
	if Game.checkpoint >= 0 and Game.checkpoint < checkpoints.size():
		at = checkpoints[Game.checkpoint].position + Vector2(10, 0)
	_place_party(at)
	princess.invuln = 1.0
	cam.position = princess.position + Vector2(0, -20)
	cam.reset_smoothing()
	create_tween().tween_property(fade, "color:a", 0.0, 0.4)
	princess.frozen = false
	_cutscene = false


func to_title() -> void:
	Game.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.45)
	await tw.finished


# --- little helpers ------------------------------------------------------------

func say(lines: Array) -> void:
	dialog.say(lines)


func toast(text: String) -> void:
	hud.toast(text)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func float_text(pos: Vector2, text: String, color: Color) -> void:
	floaters.append([pos, text, color, 0.0])


func debris(pos: Vector2, color: Color, n: int) -> void:
	for i in n:
		particles.append([pos, Vector2(_rng.randf_range(-90, 90), _rng.randf_range(-220, -80)), color, _rng.randf_range(0.0, 0.3)])


class FxNode extends Node2D:
	var main

	func _draw() -> void:
		for p in main.particles:
			var s: float = 3.0 if p[3] < 0.4 else 2.0
			draw_rect(Rect2(p[0], Vector2(s, s)), p[2])
		for f in main.floaters:
			var a: float = 1.0 - maxf(0.0, f[3] - 0.6) / 0.4
			var c: Color = f[2]
			c.a = a
			PixelFont.draw_centered(self, f[0].x, f[0].y, f[1], c, 1, Color(0, 0, 0, a))
