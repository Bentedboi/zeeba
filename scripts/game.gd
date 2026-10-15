extends Node
## Global run state (autoload "Game"): coins, quests, shop upgrades,
## party stats, input bindings and the save file.

signal coins_changed

const SAVE_PATH := "user://save.cfg"

var level := 0
var checkpoint := -1          # index into the level's checkpoints, -1 = level start
var coins := 0
var quests_done := {}         # quest id -> true
var carrying: Array = []      # quest ids Zeeba is holding for Dale
var upgrades := {}            # "rover", "hat", "tank" -> true
var flags := {}               # one-off story flags
var bottles := 0

var princess_max := 5
var princess_hp := 5
var dale_max := 3
var dale_hp := 3
var water := 100.0
var speed_charge := 0.0       # seconds of red-rock speed left
var strength := 0             # dirt charges (one per boulder smash)
var riding := false
var input_lock := 0.0         # swallow input briefly after menus close

const SPEED_MAX := 8.0
const STRENGTH_MAX := 3
const BOTTLE_MAX := 3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()


func _process(delta: float) -> void:
	if input_lock > 0.0:
		input_lock -= delta


func water_max() -> float:
	return 150.0 if upgrades.has("tank") else 100.0


func add_coins(n: int) -> void:
	coins += n
	coins_changed.emit()


func new_game() -> void:
	level = 0
	checkpoint = -1
	coins = 0
	quests_done = {}
	carrying = []
	upgrades = {}
	flags = {}
	bottles = 0
	riding = false
	water = water_max()
	refill()
	save_game()


## Heal the party after a respawn; Dale gets at least a good gulp of water.
func refill() -> void:
	princess_hp = princess_max
	dale_hp = dale_max
	water = maxf(water, water_max() * 0.6)
	speed_charge = 0.0
	strength = 0


func save_game() -> void:
	var c := ConfigFile.new()
	c.set_value("run", "level", level)
	c.set_value("run", "checkpoint", checkpoint)
	c.set_value("run", "coins", coins)
	c.set_value("run", "quests", quests_done.keys())
	c.set_value("run", "carrying", carrying)
	c.set_value("run", "upgrades", upgrades.keys())
	c.set_value("run", "flags", flags.keys())
	c.set_value("run", "bottles", bottles)
	c.set_value("run", "riding", riding)
	c.save(SAVE_PATH)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) != OK:
		return false
	level = c.get_value("run", "level", 0)
	checkpoint = c.get_value("run", "checkpoint", -1)
	coins = c.get_value("run", "coins", 0)
	quests_done = _to_set(c.get_value("run", "quests", []))
	carrying = c.get_value("run", "carrying", [])
	upgrades = _to_set(c.get_value("run", "upgrades", []))
	flags = _to_set(c.get_value("run", "flags", []))
	bottles = c.get_value("run", "bottles", 0)
	riding = c.get_value("run", "riding", false) and upgrades.has("rover")
	princess_hp = princess_max
	dale_hp = dale_max
	water = water_max()
	speed_charge = 0.0
	strength = 0
	return true


func _to_set(arr: Array) -> Dictionary:
	var d := {}
	for k in arr:
		d[k] = true
	return d


# --- input ---------------------------------------------------------------

func _setup_input() -> void:
	_bind("left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_bind("right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_bind("up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_bind("down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_bind("jump", [KEY_Z, KEY_SPACE, KEY_K], [JOY_BUTTON_A])
	_bind("punch", [KEY_X, KEY_J], [JOY_BUTTON_X])
	_bind("talk", [KEY_C, KEY_L], [JOY_BUTTON_Y])
	_bind("rover", [KEY_R], [JOY_BUTTON_LEFT_SHOULDER])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_bind("confirm", [KEY_Z, KEY_ENTER, KEY_SPACE, KEY_K], [JOY_BUTTON_A])
	_bind("cancel", [KEY_X, KEY_SHIFT, KEY_J], [JOY_BUTTON_B])


func _bind(action: String, keys: Array, buttons: Array = [], axis := -1, axis_dir := 0.0) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.4)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action, j)
	if axis >= 0:
		var m := InputEventJoypadMotion.new()
		m.axis = axis
		m.axis_value = axis_dir
		InputMap.action_add_event(action, m)
