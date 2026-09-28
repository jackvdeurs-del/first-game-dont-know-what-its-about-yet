extends Node
## Plays through the whole game automatically to catch crashes and broken
## room flow. Run it from the project folder with:
##   godot --headless --path . res://tests/smoke_test.tscn
## Exits with code 0 when everything works, 1 when something failed.

const TIME_LIMIT := 60.0

var _failures := 0


func _ready() -> void:
	get_tree().create_timer(TIME_LIMIT, true, false, true).timeout.connect(_on_time_limit)
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await tree.process_frame

	_check(await _wait_for(func() -> bool: return main.player.is_on_floor(), 3.0), "player lands on the floor")

	for i in Rooms.LIST.size():
		var room: Room = main.room
		var player: Player = main.player
		_check(Game.room_index == i, "entered room %d" % (i + 1))
		_check(room.door == null or not room.door.open, "room %d door starts closed" % (i + 1))

		# Try every unlocked fighting style once.
		for style in Game.unlocked_styles:
			Game.select_style(style)
			player._attack(true)
			await _frames(5)

		for enemy in tree.get_nodes_in_group("enemies"):
			(enemy as Enemy).hurt(999.0, Vector2.RIGHT)

		if i == Rooms.LIST.size() - 1:
			_check(await _wait_for(func() -> bool: return main._game_over, 3.0), "beating the boss wins the game")
			break

		var picker: TalentPicker = main.picker
		_check(await _wait_for(func() -> bool: return picker._accepting, 5.0), "talent picker opens after room %d" % (i + 1))
		var talents_before := Game.talent_ids.size()
		picker._choose(0)
		await tree.process_frame
		_check(Game.talent_ids.size() == talents_before + 1, "talent applied")
		_check(not tree.paused, "game unpaused after choosing")
		_check(room.door.open, "door opens after choosing")

		var unlock: int = Rooms.LIST[i].get("unlocks", -1)
		if unlock >= 0:
			_check(unlock in Game.unlocked_styles, "room %d unlocks %s" % [i + 1, Game.STYLE_NAMES[unlock]])

		var old_room_id := room.get_instance_id()
		player.global_position = room.door.global_position + Vector2(0, -30)
		_check(await _wait_for(func() -> bool: return main.room.get_instance_id() != old_room_id, 3.0), "door leads to the next room")

	# R starts a new run, and losing every heart ends it.
	Input.action_press("restart")
	await _frames(2)
	Input.action_release("restart")
	_check(Game.room_index == 0 and not main._game_over, "restart after victory")
	await _frames(2)
	Game.damage(Game.health - 1)
	main.player.take_damage(1, Vector2.ZERO)
	_check(await _wait_for(func() -> bool: return main._game_over, 2.0), "losing all hearts ends the run")

	_finish()


func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		_failures += 1


func _finish() -> void:
	print("\nSmoke test %s (%d failure%s)" % ["PASSED" if _failures == 0 else "FAILED", _failures, "" if _failures == 1 else "s"])
	get_tree().quit(0 if _failures == 0 else 1)


func _on_time_limit() -> void:
	_check(false, "finished within %d seconds" % TIME_LIMIT)
	_finish()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _wait_for(condition: Callable, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await get_tree().process_frame
	return false
