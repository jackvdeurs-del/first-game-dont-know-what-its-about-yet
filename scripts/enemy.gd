class_name Enemy
extends CharacterBody2D
## Every enemy uses this script; `kind` picks its behaviour and looks:
##   slime - patrols, and hops toward the player when she comes close
##   bat   - flies freely and swoops at the player
##   boss  - the Slime King: big leaps, shockwaves when he lands, and
##           magic orbs once he is below half health

signal died

const GRAVITY := 1500.0

var kind := "slime"
var max_hp := 3.0
var hp := 3.0
var half := Vector2(14, 11)
var speed := 70.0
var color := Color(0.35, 1.0, 0.55)
var contact_damage := 1

var _dir := -1
var _home := Vector2.ZERO
var _anim := 0.0
var _flash := 0.0
var _frozen := 0.0
var _stun := 0.0
var _hop_timer := 1.5
var _leap_timer := 2.0
var _airborne := false
var _dying := false


func setup(p_kind: String, foot: Vector2) -> void:
	kind = p_kind
	match kind:
		"slime":
			max_hp = 3.0
			half = Vector2(14, 11)
			speed = 70.0
			color = Color(0.35, 1.0, 0.55)
		"bat":
			max_hp = 2.0
			half = Vector2(11, 9)
			speed = 150.0
			color = Color(1.0, 0.35, 0.6)
		"boss":
			max_hp = 60.0
			half = Vector2(46, 36)
			speed = 260.0
			color = Color(0.8, 0.3, 1.0)
			contact_damage = 2
	hp = max_hp
	position = foot - Vector2(0, half.y)
	_home = position


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 if kind == "bat" else 1 | 32
	var shape := RectangleShape2D.new()
	shape.size = half * 2.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	add_to_group("enemies")
	if kind == "boss":
		add_to_group("boss")
	_dir = -1 if randf() < 0.5 else 1
	_anim = randf() * TAU
	_hop_timer = randf_range(1.0, 2.5)


func get_hit_rect() -> Rect2:
	return Rect2(global_position - half, half * 2.0)


func hurt(amount: float, knock_dir: Vector2) -> void:
	if _dying:
		return
	hp -= amount
	_flash = 0.1
	if kind != "boss":
		_stun = 0.22
		velocity = Vector2(knock_dir.x * 260.0, -160.0 if kind == "slime" else knock_dir.y * 200.0)
	FX.burst(get_parent(), global_position, FX.hdr(color, 1.6), 8, 200.0)
	Game.shake(3.0)
	if hp <= 0.0:
		_die()


func freeze(duration: float) -> void:
	if kind == "boss":
		duration *= 0.4
	_frozen = maxf(_frozen, duration)


func _die() -> void:
	_dying = true
	remove_from_group("enemies")
	remove_from_group("boss")
	var big := kind == "boss"
	FX.burst(get_parent(), global_position, FX.hdr(color, 2.0), 80 if big else 26, 520.0 if big else 320.0)
	Game.shake(20.0 if big else 6.0)
	Game.hit_stop(0.25 if big else 0.05)
	died.emit()
	queue_free()


func _physics_process(delta: float) -> void:
	if _dying:
		return
	_anim += delta
	_flash = maxf(_flash - delta, 0.0)
	_stun = maxf(_stun - delta, 0.0)
	_frozen = maxf(_frozen - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	match kind:
		"slime":
			_slime_ai(delta, player)
		"bat":
			_bat_ai(delta, player)
		"boss":
			_boss_ai(delta, player)
	if player and _frozen <= 0.0 and get_hit_rect().intersects(player.get_hit_rect()):
		player.take_damage(contact_damage, global_position)


func _slime_ai(delta: float, player: Player) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	if _frozen > 0.0:
		velocity.x = 0.0
	elif _stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	elif is_on_floor():
		var to_player := player.global_position - global_position if player else Vector2.INF
		var chasing := absf(to_player.x) < 320.0 and absf(to_player.y) < 90.0
		if chasing:
			_dir = 1 if to_player.x > 0.0 else -1
		if is_on_wall():
			_dir = 1 if get_wall_normal().x > 0.0 else -1
		var ledge := _ledge_ahead()
		if ledge and not chasing:
			_dir = -_dir
		velocity.x = 0.0 if ledge and chasing else _dir * speed * (1.7 if chasing else 1.0)
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			velocity.y = -430.0 if chasing else -260.0
			_hop_timer = randf_range(1.0, 2.2)
	move_and_slide()


func _ledge_ahead() -> bool:
	var from := global_position + Vector2(_dir * (half.x + 4.0), 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, half.y + 14.0), 1 | 32)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _bat_ai(delta: float, player: Player) -> void:
	if _frozen > 0.0:
		velocity = Vector2.ZERO
	elif _stun > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	else:
		var target := _home + Vector2(sin(_anim * 0.8) * 70.0, cos(_anim * 1.3) * 24.0)
		if player and player.global_position.distance_to(global_position) < 480.0:
			target = player.global_position + Vector2(0, -8)
		var desired := (target - global_position).normalized() * speed
		desired.y += sin(_anim * 6.0) * 60.0
		velocity = velocity.move_toward(desired, 420.0 * delta)
	move_and_slide()


func _boss_ai(delta: float, player: Player) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 1100.0)
	if is_on_floor():
		if _airborne:
			_airborne = false
			_land()
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
		if _frozen <= 0.0:
			_leap_timer -= delta
		if _leap_timer <= 0.0 and player:
			var dx := player.global_position.x - global_position.x
			_dir = 1 if dx > 0.0 else -1
			velocity = Vector2(clampf(dx * 1.1, -speed, speed), -760.0)
			_leap_timer = 1.1 if hp < max_hp * 0.5 else 1.7
			_airborne = true
	move_and_slide()


func _land() -> void:
	Game.shake(12.0)
	var foot := global_position + Vector2(0, half.y)
	FX.burst(get_parent(), foot, Color(1.2, 0.5, 1.6), 24, 260.0)
	if foot.y >= (Room.HEIGHT - 1) * Room.TILE - 1:
		# Shockwaves only travel along the main floor.
		for i in 2:
			var side := i * 2 - 1
			var wave := EnemyShot.new()
			wave.wave = true
			wave.position = foot + Vector2(side * (half.x + 6.0), -2.0)
			wave.velocity = Vector2(side * 330.0, 0.0)
			get_parent().add_child(wave)
	var player := get_tree().get_first_node_in_group("player") as Player
	if hp < max_hp * 0.5 and player:
		var aim := (player.global_position - global_position).angle()
		for i in 3:
			var orb := EnemyShot.new()
			orb.position = global_position + Vector2(0, -half.y * 0.5)
			orb.velocity = Vector2.from_angle(aim + (i - 1) * 0.3) * 240.0
			get_parent().add_child(orb)


# --- Drawing ---------------------------------------------------------------

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if kind == "bat":
		_draw_bat()
	else:
		_draw_slime()
	if _frozen > 0.0:
		draw_circle(Vector2.ZERO, half.length() + 3.0, Color(0.55, 0.85, 1.0, 0.3))
		draw_arc(Vector2.ZERO, half.length() + 3.0, 0.0, TAU, 32, Color(1.2, 1.8, 2.2, 0.8), 2.0)


func _draw_slime() -> void:
	var squash := clampf(velocity.y / 900.0, -0.35, 0.35)
	var wobble := sin(_anim * 6.0) * 0.05
	var w := half.x * (1.0 + squash * 0.5 + wobble)
	var h := half.y * 2.0 * (1.0 - squash * 0.6 - wobble)
	var base_y := half.y
	var body := Color(2, 2, 2) if _flash > 0.0 else color.darkened(0.35)
	var dome := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		dome.append(Vector2(cos(a) * w, base_y + sin(a) * h))
	draw_colored_polygon(dome, body)
	draw_polyline(dome, FX.hdr(color, 1.4), 2.0)
	draw_circle(Vector2(0, base_y - h * 0.3), w * 0.3, Color(color.r, color.g, color.b, 0.35))
	draw_circle(Vector2(-w * 0.45, base_y - h * 0.7), w * 0.14, Color(1, 1, 1, 0.55))
	var eye_y := base_y - h * 0.5
	for i in 2:
		var eye := Vector2(w * (-0.3 if i == 0 else 0.3) + _dir * 2.0, eye_y)
		draw_circle(eye, w * 0.16, Color.WHITE)
		draw_circle(eye + Vector2(_dir * w * 0.06, 0.5), w * 0.08, Color(0.05, 0.02, 0.1))
	if kind == "boss":
		# Angry brows and a golden crown
		for i in 2:
			var side := -1.0 if i == 0 else 1.0
			draw_line(Vector2(side * w * 0.45, eye_y - h * 0.16), Vector2(side * w * 0.12, eye_y - h * 0.08), Color(0.1, 0.02, 0.15), 4.0)
		var top := base_y - h
		var cw := w * 0.45
		draw_colored_polygon(PackedVector2Array([
			Vector2(-cw, top + 6), Vector2(-cw, top - 14), Vector2(-cw * 0.5, top - 4),
			Vector2(0, top - 22), Vector2(cw * 0.5, top - 4), Vector2(cw, top - 14), Vector2(cw, top + 6),
		]), Color(1.5, 1.15, 0.3))
		draw_circle(Vector2(0, top - 4), 4.0, Color(2.0, 0.3, 0.5))


func _draw_bat() -> void:
	var flap := sin(_anim * 18.0)
	var body := Color(2, 2, 2) if _flash > 0.0 else color.darkened(0.55)
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		# Two triangles per wing, so the shape stays valid at every flap angle.
		var shoulder := Vector2(s * 4, -3)
		var tip := Vector2(s * 24, -12.0 - flap * 10.0)
		var edge := Vector2(s * 15, 3.0 + flap * 3.0)
		var root := Vector2(s * 6, 5)
		var wing_color := body.darkened(0.2)
		draw_colored_polygon(PackedVector2Array([shoulder, tip, edge]), wing_color)
		draw_colored_polygon(PackedVector2Array([shoulder, edge, root]), wing_color)
		draw_polyline(PackedVector2Array([shoulder, tip, edge, root]), FX.hdr(color, 0.9), 1.5)
		draw_colored_polygon(PackedVector2Array([
			Vector2(s * 3, -6), Vector2(s * 7, -14), Vector2(s * 8, -5),
		]), body)
	draw_circle(Vector2.ZERO, 9.0, body)
	draw_circle(Vector2(-3, -1), 1.8, Color(2.4, 0.5, 0.6))
	draw_circle(Vector2(3, -1), 1.8, Color(2.4, 0.5, 0.6))
