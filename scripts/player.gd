class_name Player
extends CharacterBody2D
## The heroine: a young mage who runs, jumps, dashes and fights with the
## currently selected fighting style (see Game.current_style).
## Movement numbers are at the top so they're easy to tweak.

signal died

const HALF := Vector2(10, 22)   # half the size of her collision box
const RUN_SPEED := 270.0
const GROUND_ACCEL := 2400.0
const AIR_ACCEL := 1600.0
const FRICTION := 2800.0
const GRAVITY := 1900.0
const FALL_MULTIPLIER := 1.45   # falls faster than she rises, feels snappier
const MAX_FALL_SPEED := 950.0
const JUMP_VELOCITY := -660.0
const JUMP_CUT := 0.45          # releasing jump early makes a shorter hop
const COYOTE_TIME := 0.1        # can still jump just after running off a ledge
const JUMP_BUFFER_TIME := 0.12  # jump pressed just before landing still counts
const DASH_SPEED := 640.0
const DASH_TIME := 0.15
const HURT_TIME := 0.25
const INVULNERABLE_TIME := 1.0
const COOLDOWNS := [0.3, 0.24, 0.85]  # per style: Arcane Bolt, Blade Dance, Frost Nova

const SKIN := Color(1.0, 0.85, 0.75)
const HAIR := Color(0.95, 0.42, 0.55)
const DRESS := Color(0.22, 0.17, 0.4)
const HAT := Color(0.16, 0.11, 0.3)

var facing := 1
var _coyote := 0.0
var _jump_buffer := 0.0
var _air_jumps_left := 0
var _dashes_left := 0
var _dash_time := 0.0
var _hurt_time := 0.0
var _invulnerable := 0.0
var _attack_cooldown := 0.0
var _combo := 0
var _combo_time := 0.0
var _cast_flash := 0.0
var _anim := 0.0
var _was_on_floor := true
var _dead := false
var _trail: CPUParticles2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 32   # solid ground + one-way platforms
	floor_snap_length = 6.0
	var shape := RectangleShape2D.new()
	shape.size = HALF * 2.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	add_to_group("player")
	_trail = FX.make_trail()
	add_child(_trail)
	Game.changed.connect(_on_game_changed)


func get_hit_rect() -> Rect2:
	return Rect2(global_position - HALF, HALF * 2.0)


func is_dead() -> bool:
	return _dead


func take_damage(amount: int, from: Vector2) -> void:
	if _invulnerable > 0.0 or _dead:
		return
	_invulnerable = INVULNERABLE_TIME
	_hurt_time = HURT_TIME
	_dash_time = 0.0
	_trail.emitting = false
	var away := signf(global_position.x - from.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * 380.0, -380.0)
	Game.shake(8.0)
	Game.hit_stop(0.06)
	FX.burst(get_parent(), global_position, Color(1.8, 0.3, 0.5), 18, 260.0)
	if Game.damage(amount):
		_die()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_tick_timers(delta)
	_handle_style_input()

	var on_floor := is_on_floor()
	if on_floor:
		_coyote = COYOTE_TIME
		_air_jumps_left = Game.stats["air_jumps"]
		_dashes_left = Game.stats["dashes"]
		if not _was_on_floor:
			FX.dust(get_parent(), global_position + Vector2(0, HALF.y))
	_was_on_floor = on_floor

	var input_x := Input.get_axis("move_left", "move_right")
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity.y = 0.0
		if _dash_time <= 0.0:
			velocity.x *= 0.35
			_trail.emitting = false
	else:
		_move(delta, input_x, on_floor)
		_jump(on_floor)
		if Input.is_action_just_pressed("dash") and _dashes_left > 0 and _hurt_time <= 0.0:
			_start_dash(input_x)

	if Input.is_action_pressed("attack") and _attack_cooldown <= 0.0 and _hurt_time <= 0.0:
		_attack(on_floor)
	move_and_slide()


func _tick_timers(delta: float) -> void:
	_anim += delta
	_coyote -= delta
	_jump_buffer -= delta
	_hurt_time -= delta
	_invulnerable -= delta
	_attack_cooldown -= delta
	_cast_flash -= delta
	_combo_time -= delta
	if _combo_time <= 0.0:
		_combo = 0
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER_TIME


func _handle_style_input() -> void:
	if Input.is_action_just_pressed("next_style"):
		Game.cycle_style(1)
	elif Input.is_action_just_pressed("prev_style"):
		Game.cycle_style(-1)
	for i in 3:
		if Input.is_action_just_pressed("style_%d" % (i + 1)):
			Game.select_style(i)


func _move(delta: float, input_x: float, on_floor: bool) -> void:
	var top_speed: float = RUN_SPEED * Game.stats["move_speed"]
	if _hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
		if input_x == 0.0 and on_floor:
			accel = FRICTION
		velocity.x = move_toward(velocity.x, input_x * top_speed, accel * delta)
		if input_x != 0.0:
			facing = 1 if input_x > 0.0 else -1
	var gravity := GRAVITY * (FALL_MULTIPLIER if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)


func _jump(on_floor: bool) -> void:
	if _jump_buffer > 0.0:
		if Input.is_action_pressed("move_down") and on_floor and _on_platform():
			# Drop down through a one-way platform.
			_jump_buffer = 0.0
			set_collision_mask_value(6, false)
			get_tree().create_timer(0.25).timeout.connect(set_collision_mask_value.bind(6, true))
		elif _coyote > 0.0:
			_do_jump()
		elif _air_jumps_left > 0:
			_air_jumps_left -= 1
			_do_jump()
			FX.burst(get_parent(), global_position + Vector2(0, HALF.y), FX.hdr(Game.style_color(), 1.5), 12, 160.0)
	if Input.is_action_just_released("jump") and velocity.y < 0.0 and _hurt_time <= 0.0:
		velocity.y *= JUMP_CUT


func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_buffer = 0.0
	_coyote = 0.0
	FX.dust(get_parent(), global_position + Vector2(0, HALF.y))


func _on_platform() -> bool:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider and collider.get_meta("one_way", false):
			return true
	return false


func _start_dash(input_x: float) -> void:
	_dashes_left -= 1
	if input_x != 0.0:
		facing = 1 if input_x > 0.0 else -1
	_dash_time = DASH_TIME
	velocity = Vector2(DASH_SPEED * facing, 0.0)
	_invulnerable = maxf(_invulnerable, DASH_TIME + 0.05)
	_trail.emitting = true


func _attack(on_floor: bool) -> void:
	var power: float = Game.stats["damage"]
	var cooldown: float = COOLDOWNS[Game.current_style]
	_cast_flash = 0.12
	if Game.current_style == Game.ARCANE:
		var shots: int = Game.stats["multishot"]
		for i in shots:
			var bolt := Bolt.new()
			bolt.position = global_position + Vector2(16.0 * facing, -6.0)
			bolt.velocity = Vector2(780.0 * facing, 0.0).rotated((i - (shots - 1) / 2.0) * 0.14)
			bolt.damage = power
			bolt.pierce = Game.stats["pierce"]
			get_parent().add_child(bolt)
	elif Game.current_style == Game.BLADE:
		_combo = _combo % 3 + 1
		_combo_time = 0.6
		var slash := Slash.new()
		slash.facing = facing
		slash.finisher = _combo == 3
		slash.size_mult = Game.stats["slash_size"]
		slash.damage = (3.0 if slash.finisher else 2.0) * power
		slash.position = Vector2(6.0 * facing, -4.0)
		add_child(slash)
		velocity.x += 150.0 * facing
		if not on_floor:
			velocity.y = minf(velocity.y, 40.0)  # slashing in the air hovers a little
		if slash.finisher:
			cooldown *= 1.8
	elif Game.current_style == Game.FROST:
		var nova := Nova.new()
		nova.position = global_position
		nova.radius = 120.0 * Game.stats["nova_radius"]
		nova.damage = 2.0 * power
		get_parent().add_child(nova)
	_attack_cooldown = cooldown / Game.stats["attack_speed"]


func _die() -> void:
	_dead = true
	remove_from_group("player")
	_trail.emitting = false
	FX.burst(get_parent(), global_position, Color(2.0, 0.6, 1.2), 40, 380.0)
	Game.shake(14.0)
	hide()
	died.emit()


func _on_game_changed() -> void:
	_trail.color = FX.hdr(Game.style_color(), 1.5)


# --- Drawing ---------------------------------------------------------------
# She is drawn with shapes for now. To use sprite art later, replace this
# with an AnimatedSprite2D child and play animations based on velocity.

func _process(_delta: float) -> void:
	var blinking := _invulnerable > 0.0 and _dash_time <= 0.0 and fmod(_anim, 0.12) < 0.06
	modulate.a = 0.35 if blinking else 1.0
	queue_redraw()


## Point in "facing space": positive x is always in front of her.
func _fp(x: float, y: float) -> Vector2:
	return Vector2(x * facing, y)


func _draw() -> void:
	var style_col: Color = Game.style_color()
	var glow := FX.hdr(style_col, 1.8 + maxf(_cast_flash, 0.0) * 10.0)
	var on_floor := is_on_floor()
	var run := clampf(absf(velocity.x) / RUN_SPEED, 0.0, 1.0)
	var step := sin(_anim * 15.0) * run if on_floor else 0.0
	var wave := sin(_anim * 7.0)

	# Cape, streaming out behind her when she runs
	draw_colored_polygon(PackedVector2Array([
		_fp(3, -9), _fp(-4, -9),
		_fp(-10.0 - run * 9.0, 12.0 - run * 7.0 + wave * 2.0),
		_fp(-1.0 - run * 4.0, 16.0 - run * 3.0),
	]), style_col.darkened(0.55))

	# Legs
	var leg := Color(0.12, 0.08, 0.2)
	if on_floor:
		draw_line(_fp(-3, 10), _fp(-3.0 - step * 5.0, 21), leg, 4.0)
		draw_line(_fp(3, 10), _fp(3.0 + step * 5.0, 21), leg, 4.0)
	else:
		draw_line(_fp(-3, 10), _fp(-6, 18), leg, 4.0)
		draw_line(_fp(3, 10), _fp(5, 17), leg, 4.0)

	# Dress with a glowing hem in the style's color
	draw_colored_polygon(PackedVector2Array([_fp(-6, -9), _fp(6, -9), _fp(10, 12), _fp(-10, 12)]), DRESS)
	draw_line(_fp(-10, 12), _fp(10, 12), style_col, 2.0)
	draw_line(_fp(-6, 0), _fp(7, 0), style_col.darkened(0.3), 2.0)

	# Arm holding a wand (or a sword of light in Blade Dance)
	var hand := _fp(12, -2) if _cast_flash > 0.0 else _fp(9, 3)
	draw_line(_fp(3, -6), hand, DRESS.lightened(0.15), 3.5)
	draw_circle(hand, 2.2, SKIN)
	if Game.current_style == Game.BLADE:
		draw_line(hand, hand + _fp(18, -10), glow, 3.0)
		draw_line(hand + _fp(-2, -3), hand + _fp(2, 3), Color(0.85, 0.7, 0.4), 3.0)
	else:
		var tip := hand + _fp(5, -11)
		draw_line(hand, tip, Color(0.45, 0.3, 0.2), 2.0)
		draw_circle(tip, 3.0 + maxf(_cast_flash, 0.0) * 20.0, glow)

	# Head: hair, ponytail, face, bangs
	draw_circle(_fp(-1.5, -16), 8.5, HAIR)
	draw_colored_polygon(PackedVector2Array([
		_fp(-6, -20), _fp(-9, -13),
		_fp(-15.0 - run * 5.0, -6.0 + wave * 2.0), _fp(-13.0 - run * 4.0, -15),
	]), HAIR)
	draw_circle(_fp(1.5, -14.5), 6.5, SKIN)
	draw_colored_polygon(PackedVector2Array([
		_fp(-5, -21), _fp(8, -20), _fp(8.5, -15.5), _fp(4, -18), _fp(0, -16), _fp(-3, -18),
	]), HAIR)
	draw_circle(_fp(4.5, -14), 1.4, Color(0.1, 0.05, 0.2))
	draw_circle(_fp(4.9, -14.5), 0.5, Color.WHITE)
	draw_circle(_fp(3.5, -11.3), 1.3, Color(1.0, 0.5, 0.55, 0.5))

	# Witch hat, its tip bending back as she runs
	var hat_tip := _fp(-6.0 - run * 4.0, -38.0 + wave)
	draw_colored_polygon(PackedVector2Array([_fp(-8, -21), _fp(9, -21), _fp(2, -30), hat_tip]), HAT)
	draw_line(_fp(-12, -21), _fp(13, -21), HAT, 3.0)
	draw_line(_fp(-7, -23), _fp(8, -23), style_col, 2.0)
	draw_circle(hat_tip, 1.8, glow)
