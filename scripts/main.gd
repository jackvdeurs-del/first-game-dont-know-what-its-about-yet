extends Node2D
## Entry point. Builds the rooms in order and connects the player, HUD and
## talent picker. Also handles winning, dying and restarting.
##
## Testing tip: to start in a later room, set Project Settings >
## Editor > Run > Main Run Args to `-- --room=5` (any room number).

var room: Room
var player: Player
var hud: Hud
var picker: TalentPicker
var camera: Camera2D
var message: Label
var _shake := 0.0
var _game_over := false


func _ready() -> void:
	_add_glow()
	add_child(Background.new())

	camera = Camera2D.new()
	camera.position = Vector2(Room.WIDTH, Room.HEIGHT) * Room.TILE / 2.0
	add_child(camera)
	camera.make_current()

	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	ui.add_child(hud)
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 42)
	message.add_theme_constant_override("outline_size", 10)
	message.add_theme_color_override("font_outline_color", Color(0.05, 0.0, 0.1))
	message.hide()
	ui.add_child(message)

	var picker_layer := CanvasLayer.new()
	picker_layer.layer = 10
	picker_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(picker_layer)
	picker = TalentPicker.new()
	picker_layer.add_child(picker)
	picker.picked.connect(_on_talent_picked)

	Game.shake_requested.connect(_on_shake_requested)
	_start_room(_starting_room())


func _process(delta: float) -> void:
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	_shake = move_toward(_shake, 0.0, 40.0 * delta)
	if _game_over and Input.is_action_just_pressed("restart"):
		_game_over = false
		message.hide()
		Game.new_run()
		_start_room(0)


func _start_room(index: int) -> void:
	if room:
		remove_child(room)
		room.queue_free()
	Game.room_index = index
	var layout: Dictionary = Rooms.LIST[index]
	room = Room.new()
	add_child(room)
	room.build(layout)
	room.cleared.connect(_on_room_cleared)
	room.exit_reached.connect(_on_exit_reached)

	player = Player.new()
	player.position = room.player_spawn - Vector2(0, Player.HALF.y)
	room.add_child(player)
	room.player = player
	player.died.connect(_on_player_died)

	hud.room_title = "Room %d / %d  -  %s" % [index + 1, Rooms.LIST.size(), layout["name"]]
	hud.show_banner(layout["name"])


func _on_room_cleared() -> void:
	if _game_over:
		return
	var heal: int = Game.stats["heal_on_clear"]
	if heal > 0:
		Game.heal(heal)
	if Game.room_index == Rooms.LIST.size() - 1:
		_end("VICTORY!\nThe Slime King is defeated.\n\nPress R to play again")
		return

	var layout: Dictionary = Rooms.LIST[Game.room_index]
	var unlock: int = layout.get("unlocks", -1)
	if unlock >= 0 and not (unlock in Game.unlocked_styles):
		Game.unlock_style(unlock)
		hud.show_banner("New fighting style: %s!" % Game.STYLE_NAMES[unlock])

	await get_tree().create_timer(1.0).timeout
	if _game_over:
		return
	var options: Array[Dictionary] = Game.roll_talents(3)
	if options.is_empty():
		room.open_door()
		return
	get_tree().paused = true
	picker.open(options)


func _on_talent_picked(talent: Dictionary) -> void:
	Game.apply_talent(talent)
	get_tree().paused = false
	room.open_door()
	hud.show_banner("%s learned - the door is open!" % talent["name"])


func _on_exit_reached() -> void:
	_start_room.call_deferred(Game.room_index + 1)


func _on_player_died() -> void:
	_end("You were defeated...\n\nPress R to try again")


func _end(text: String) -> void:
	_game_over = true
	message.text = text
	message.show()


func _on_shake_requested(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _starting_room() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			var index := clampi(arg.get_slice("=", 1).to_int() - 1, 0, Rooms.LIST.size() - 1)
			for i in index:
				var unlock: int = Rooms.LIST[i].get("unlocks", -1)
				if unlock >= 0:
					Game.unlock_style(unlock)
			return index
	return 0


## Makes anything brighter than white (see FX.hdr) bloom with a soft glow.
func _add_glow() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
