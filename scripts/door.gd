class_name Door
extends Node2D
## The exit at the end of a room. Sealed until the room is cleared,
## then turns into a swirling portal.

const SIZE := Vector2(40, 72)

var open := false
var _t := 0.0


## Area the player has to touch to leave the room (in room coordinates).
func get_rect() -> Rect2:
	return Rect2(position + Vector2(-SIZE.x / 2.0, -SIZE.y), SIZE)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := SIZE.x
	var h := SIZE.y
	var arch := Vector2(0, -h + w / 2.0)
	var stone := Color(0.24, 0.19, 0.36)
	draw_circle(arch, w / 2.0 + 8.0, stone)
	draw_rect(Rect2(-w / 2.0 - 8.0, arch.y, w + 16.0, h - w / 2.0), stone)

	var inside := Color(0.12, 0.35, 0.55) if open else Color(0.04, 0.02, 0.08)
	draw_circle(arch, w / 2.0, inside)
	draw_rect(Rect2(-w / 2.0, arch.y, w, h - w / 2.0), inside)

	var center := Vector2(0, -h / 2.0)
	if open:
		for i in 4:
			var r := (w / 2.0 - 3.0) * (1.0 - i * 0.2)
			var a := _t * (3.0 + i) + i * 1.7
			draw_arc(center, r, a, a + 4.0, 20, Color(0.5, 1.3, 2.2, 0.85), 2.5)
		draw_circle(center, 5.0 + sin(_t * 6.0), Color(1.8, 2.2, 2.6))
	else:
		for i in 3:
			var bx := -w / 2.0 + w * (i + 1) / 4.0
			draw_line(Vector2(bx, arch.y - 10.0), Vector2(bx, 0), Color(0.3, 0.25, 0.4), 3.0)
		draw_circle(center, 7.0, Color(1.3, 0.25, 0.35, 0.55 + 0.3 * sin(_t * 3.0)))

	# Keystone gem
	var gem := arch + Vector2(0, -w / 2.0 - 4.0)
	var gem_color := Color(0.6, 1.6, 2.2) if open else Color(1.2, 0.3, 0.4)
	draw_colored_polygon(PackedVector2Array([
		gem + Vector2(0, -6), gem + Vector2(5, 0), gem + Vector2(0, 6), gem + Vector2(-5, 0),
	]), gem_color)
