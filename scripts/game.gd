extends Node
## Global run state, available everywhere as `Game` (Project Settings > Autoload).
## Holds everything that has to survive between rooms: health, unlocked
## fighting styles and the talents chosen so far.

signal changed
signal shake_requested(amount: float)

const ARCANE := 0
const BLADE := 1
const FROST := 2
const STYLE_NAMES := ["Arcane Bolt", "Blade Dance", "Frost Nova"]
const STYLE_COLORS := [Color(0.8, 0.45, 1.0), Color(1.0, 0.55, 0.25), Color(0.4, 0.85, 1.0)]
const BASE_MAX_HEALTH := 5

var room_index := 0
var max_health := BASE_MAX_HEALTH
var health := BASE_MAX_HEALTH
var unlocked_styles: Array[int] = []
var current_style := ARCANE
var talent_ids: Array[String] = []
var talent_names: Array[String] = []
var stats: Dictionary = {}


func _ready() -> void:
	_setup_input()
	new_run()


func new_run() -> void:
	room_index = 0
	max_health = BASE_MAX_HEALTH
	health = max_health
	unlocked_styles = [ARCANE]
	current_style = ARCANE
	talent_ids.clear()
	talent_names.clear()
	stats = {
		"damage": 1.0,        # multiplier for every attack
		"attack_speed": 1.0,  # attack cooldowns are divided by this
		"move_speed": 1.0,
		"air_jumps": 0,
		"dashes": 1,          # dashes available before touching the ground again
		"pierce": 0,          # extra enemies an arcane bolt passes through
		"multishot": 1,       # arcane bolts per cast
		"slash_size": 1.0,
		"nova_radius": 1.0,
		"heal_on_clear": 0,
	}
	changed.emit()


func style_color(style: int = -1) -> Color:
	if style < 0:
		style = current_style
	return STYLE_COLORS[style]


func cycle_style(direction: int) -> void:
	var i := unlocked_styles.find(current_style)
	current_style = unlocked_styles[wrapi(i + direction, 0, unlocked_styles.size())]
	changed.emit()


func select_style(style: int) -> void:
	if style in unlocked_styles and style != current_style:
		current_style = style
		changed.emit()


func unlock_style(style: int) -> void:
	if style in unlocked_styles:
		return
	unlocked_styles.append(style)
	unlocked_styles.sort()
	current_style = style
	changed.emit()


## Returns true when this hit was fatal.
func damage(amount: int) -> bool:
	health = maxi(health - amount, 0)
	changed.emit()
	return health == 0


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	changed.emit()


## Picks `count` random talents the player is allowed to take right now.
func roll_talents(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for t: Dictionary in Talents.ALL:
		if t.get("once", false) and t["id"] in talent_ids:
			continue
		if t.has("style") and not (t["style"] in unlocked_styles):
			continue
		pool.append(t)
	pool.shuffle()
	return pool.slice(0, count)


func apply_talent(t: Dictionary) -> void:
	match t["id"]:
		"power":
			stats["damage"] += 0.25
		"haste":
			stats["attack_speed"] += 0.2
		"vitality":
			max_health += 1
			health = max_health
		"swift":
			stats["move_speed"] += 0.12
		"double_jump":
			stats["air_jumps"] += 1
		"extra_dash":
			stats["dashes"] += 1
		"pierce":
			stats["pierce"] += 1
		"multishot":
			stats["multishot"] += 1
		"big_slash":
			stats["slash_size"] += 0.3
		"nova_size":
			stats["nova_radius"] += 0.3
		"regen":
			stats["heal_on_clear"] += 1
	talent_ids.append(t["id"])
	talent_names.append(t["name"])
	changed.emit()


func shake(amount: float) -> void:
	shake_requested.emit(amount)


## Freezes the action for a split second so big hits feel heavy.
func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"attack": [KEY_J, KEY_Z],
		"dash": [KEY_K, KEY_X, KEY_SHIFT],
		"prev_style": [KEY_Q],
		"next_style": [KEY_E],
		"style_1": [KEY_1],
		"style_2": [KEY_2],
		"style_3": [KEY_3],
		"restart": [KEY_R],
	}
	var pad_buttons := {
		"jump": JOY_BUTTON_A,
		"attack": JOY_BUTTON_X,
		"dash": JOY_BUTTON_B,
		"prev_style": JOY_BUTTON_LEFT_SHOULDER,
		"next_style": JOY_BUTTON_RIGHT_SHOULDER,
		"restart": JOY_BUTTON_START,
	}
	for action: String in keys:
		if InputMap.has_action(action):
			continue  # already defined in Project Settings > Input Map
		InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
		if pad_buttons.has(action):
			var button := InputEventJoypadButton.new()
			button.button_index = pad_buttons[action]
			InputMap.action_add_event(action, button)
	_add_stick("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_stick("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_stick("move_down", JOY_AXIS_LEFT_Y, 1.0)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", click)


func _add_stick(action: String, axis: JoyAxis, value: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	InputMap.action_add_event(action, motion)
