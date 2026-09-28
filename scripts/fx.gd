class_name FX
## Small helpers for particles and glowing colors.
## Colors brighter than 1.0 glow, thanks to HDR 2D and the glow effect
## set up in main.gd.


static func hdr(c: Color, strength: float) -> Color:
	return Color(c.r * strength, c.g * strength, c.b * strength, c.a)


## A one-shot burst of sparks, e.g. for hits and deaths.
static func burst(parent: Node, at: Vector2, color: Color, amount: int = 16, speed: float = 220.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.55
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.3
	p.initial_velocity_max = speed
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = color
	p.color_ramp = _fade()
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)


## Little puffs at her feet when jumping and landing.
static func dust(parent: Node, at: Vector2) -> void:
	burst(parent, at, Color(0.75, 0.65, 0.95, 0.6), 6, 90.0)


## Afterimage sparkles used while dashing.
static func make_trail() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.amount = 40
	p.lifetime = 0.3
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(8, 18)
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 10.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = hdr(Game.style_color(), 1.5)
	p.color_ramp = _fade()
	return p


static func _fade() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	return g
