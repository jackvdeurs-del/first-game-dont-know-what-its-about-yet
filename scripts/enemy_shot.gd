class_name EnemyShot
extends Node2D
## The Slime King's attacks: a shockwave that runs along the floor
## (wave = true) or a glowing orb that flies in a straight line.

var velocity := Vector2.ZERO
var wave := false
var _life := 3.0
var _t := 0.0


func _physics_process(delta: float) -> void:
	_life -= delta
	_t += delta
	if _life <= 0.0:
		queue_free()
		return
	var next := global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		FX.burst(get_parent(), global_position, Color(1.6, 0.5, 1.8), 10, 150.0)
		queue_free()
		return
	global_position = next
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and _hit_rect().intersects(player.get_hit_rect()):
		player.take_damage(1, global_position)
		if not wave:
			queue_free()


func _hit_rect() -> Rect2:
	if wave:
		return Rect2(global_position + Vector2(-10, -30), Vector2(20, 30))
	return Rect2(global_position - Vector2(8, 8), Vector2(16, 16))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if wave:
		for i in 3:
			var x := (i - 1) * 7.0
			var height := 18.0 + 10.0 * absf(sin(_t * 20.0 + i * 2.0))
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 6, 0), Vector2(x, -height), Vector2(x + 6, 0),
			]), Color(1.8, 0.4, 2.0, 0.9))
		draw_line(Vector2(-12, 0), Vector2(12, 0), Color(2.2, 1.0, 2.4), 3.0)
	else:
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.3, 1.2, 0.35))
		draw_circle(Vector2.ZERO, 5.5, Color(2.0, 0.6, 2.2))
		draw_circle(Vector2.ZERO, 2.5, Color(2.6, 2.2, 2.6))
