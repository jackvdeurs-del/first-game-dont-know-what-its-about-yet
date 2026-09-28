class_name Bolt
extends Node2D
## A magic bolt fired by the Arcane Bolt style.

var velocity := Vector2.ZERO
var damage := 1.0
var pierce := 0
var _life := 1.2
var _hit: Array[Enemy] = []


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	var next := global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_pop(hit["position"])
		return
	global_position = next
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy in _hit or not enemy.get_hit_rect().grow(6.0).has_point(global_position):
			continue
		enemy.hurt(damage, Vector2(signf(velocity.x), 0.0))
		_hit.append(enemy)
		if pierce <= 0:
			_pop(global_position)
			return
		pierce -= 1


func _pop(at: Vector2) -> void:
	FX.burst(get_parent(), at, FX.hdr(Game.style_color(Game.ARCANE), 2.0), 10, 160.0)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var dir := velocity.normalized()
	var col: Color = Game.style_color(Game.ARCANE)
	draw_line(-dir * 24.0, Vector2.ZERO, Color(col.r, col.g, col.b, 0.35), 5.0)
	draw_line(-dir * 12.0, Vector2.ZERO, FX.hdr(col, 1.6), 3.0)
	draw_circle(Vector2.ZERO, 5.0, FX.hdr(col, 2.2))
	draw_circle(Vector2.ZERO, 2.5, Color(2.5, 2.2, 2.8))
