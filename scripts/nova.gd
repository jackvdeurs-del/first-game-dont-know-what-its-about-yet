class_name Nova
extends Node2D
## Frost Nova: a burst of ice around the player that damages and
## freezes every enemy inside the radius.

const LIFE := 0.4
const FREEZE_TIME := 1.6

var radius := 120.0
var damage := 2.0
var _t := 0.0


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		var r := enemy.get_hit_rect()
		var closest := Vector2(
			clampf(global_position.x, r.position.x, r.end.x),
			clampf(global_position.y, r.position.y, r.end.y))
		if closest.distance_to(global_position) <= radius:
			enemy.hurt(damage, (enemy.global_position - global_position).normalized())
			enemy.freeze(FREEZE_TIME)
	FX.burst(get_parent(), global_position, FX.hdr(Game.style_color(Game.FROST), 2.0), 30, radius * 3.0)
	Game.shake(5.0)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var p := clampf(_t / LIFE, 0.0, 1.0)
	var col: Color = Game.style_color(Game.FROST)
	var r := radius * (1.0 - pow(1.0 - p, 3.0))
	var a := 1.0 - p
	draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.14 * a))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(col.r * 2.0, col.g * 2.0, col.b * 2.0, a), 4.0)
	for i in 10:
		var dir := Vector2.from_angle(TAU * i / 10.0 + 0.3)
		draw_line(dir * r * 0.55, dir * r * 0.95, Color(2.0, 2.4, 2.8, a), 2.5)
