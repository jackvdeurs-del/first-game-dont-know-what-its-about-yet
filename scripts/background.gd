class_name Background
extends Node2D
## Night sky behind every room: gradient, moon, twinkling stars, two
## layers of mountains and slowly drifting fireflies.

const W := 1280.0
const H := 720.0

var _star_pos := PackedVector2Array()
var _star_size := PackedFloat32Array()
var _star_phase := PackedFloat32Array()
var _t := 0.0


func _ready() -> void:
	z_index = -100
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		_star_pos.append(Vector2(rng.randf() * W, rng.randf() * H * 0.6))
		_star_size.append(rng.randf_range(0.8, 2.0))
		_star_phase.append(rng.randf() * TAU)

	var motes := CPUParticles2D.new()
	motes.position = Vector2(W / 2.0, H / 2.0)
	motes.amount = 36
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(W / 2.0, H / 2.0)
	motes.direction = Vector2.UP
	motes.spread = 60.0
	motes.gravity = Vector2(0, -6)
	motes.initial_velocity_min = 5.0
	motes.initial_velocity_max = 18.0
	motes.scale_amount_min = 1.5
	motes.scale_amount_max = 3.0
	motes.color = Color(0.6, 1.4, 1.2, 0.8)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.5, Color.WHITE)
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	motes.color_ramp = fade
	add_child(motes)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var top := Color(0.04, 0.02, 0.1)
	var bottom := Color(0.17, 0.07, 0.23)
	draw_polygon(
		PackedVector2Array([Vector2(-200, -200), Vector2(W + 200, -200), Vector2(W + 200, H + 200), Vector2(-200, H + 200)]),
		PackedColorArray([top, top, bottom, bottom]))

	var moon := Vector2(1000, 150)
	draw_circle(moon, 110.0, Color(0.8, 0.6, 1.0, 0.04))
	draw_circle(moon, 70.0, Color(0.8, 0.6, 1.0, 0.07))
	draw_circle(moon, 44.0, Color(1.15, 1.0, 1.25))
	draw_circle(moon + Vector2(-12, -8), 9.0, Color(0.9, 0.8, 1.05))
	draw_circle(moon + Vector2(14, 12), 6.0, Color(0.9, 0.8, 1.05))

	for i in _star_pos.size():
		var a := 0.45 + 0.45 * sin(_t * 2.0 + _star_phase[i])
		draw_circle(_star_pos[i], _star_size[i], Color(1, 1, 1, a))

	_mountains(H * 0.6, 110.0, 0.004, 1.0, Color(0.13, 0.07, 0.24))
	_mountains(H * 0.74, 80.0, 0.007, 4.0, Color(0.08, 0.04, 0.16))


func _mountains(base_y: float, height: float, freq: float, seed_offset: float, color: Color) -> void:
	var points := PackedVector2Array([Vector2(-200, H + 200)])
	var x := -200.0
	while x <= W + 200.0:
		var n := 0.6 * sin(x * freq + seed_offset) + 0.4 * sin(x * freq * 2.7 + seed_offset * 3.0)
		points.append(Vector2(x, base_y - height * (0.5 + 0.5 * n)))
		x += 20.0
	points.append(Vector2(W + 200, H + 200))
	draw_colored_polygon(points, color)
