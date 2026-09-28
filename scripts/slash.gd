class_name Slash
extends Node2D
## One swing of the Blade Dance style. Hits everything in front of the
## player once, then fades out. Every third swing is a bigger finisher.

const LIFE := 0.16

var facing := 1
var damage := 2.0
var finisher := false
var size_mult := 1.0
var _t := 0.0
var _reach := 50.0


func _ready() -> void:
	_reach = (68.0 if finisher else 50.0) * size_mult
	var height := _reach * 1.1
	var left := global_position.x - 12.0 if facing > 0 else global_position.x - _reach
	var area := Rect2(left, global_position.y - height / 2.0, _reach + 12.0, height)
	var hit_any := false
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy.get_hit_rect().intersects(area):
			enemy.hurt(damage, Vector2(facing, -0.4 if finisher else 0.0))
			hit_any = true
	if hit_any:
		Game.shake(6.0 if finisher else 3.0)
		Game.hit_stop(0.07 if finisher else 0.035)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var p := clampf(_t / LIFE, 0.0, 1.0)
	var col: Color = Game.style_color(Game.BLADE)
	var alpha := 1.0 - p
	var r := _reach * 0.75
	var sweep := PI * 0.9
	var a0 := -sweep / 2.0
	var a1 := a0 + sweep * minf(p * 1.6 + 0.2, 1.0)
	if facing < 0:
		a0 = PI - a0
		a1 = PI - a1
	var width := (10.0 if finisher else 6.0) * (1.0 - p * 0.5)
	draw_arc(Vector2.ZERO, r * 0.8, a0, a1, 24, Color(col.r, col.g, col.b, alpha * 0.4), 14.0)
	draw_arc(Vector2.ZERO, r, a0, a1, 24, Color(col.r * 2.2, col.g * 2.2, col.b * 2.2, alpha), width)
	draw_arc(Vector2.ZERO, r * 1.06, a0, a1, 24, Color(2.5, 2.3, 2.0, alpha), 2.0)
