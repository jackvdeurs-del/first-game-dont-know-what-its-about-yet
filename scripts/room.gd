class_name Room
extends Node2D
## One room of the game, built from a text map in rooms.gd.
## Emits `cleared` when every enemy is defeated and `exit_reached`
## when the player walks into the open door.

signal cleared
signal exit_reached

const TILE := 32
const WIDTH := 40   # in tiles, including the outer walls
const HEIGHT := 22

const STONE := Color(0.11, 0.09, 0.2)
const MOSS := Color(0.3, 0.85, 0.72)
const CRYSTAL := Color(0.5, 1.6, 1.5)

var player: Player
var player_spawn := Vector2(3 * TILE, (HEIGHT - 1) * TILE)
var door: Door
var is_cleared := false
var _grid: Array[String] = []
var _exited := false


func build(layout: Dictionary) -> void:
	_make_grid(layout["map"])
	var solids := _make_body(1)
	var platforms := _make_body(32)
	platforms.set_meta("one_way", true)
	var spawns: Array = []
	for y in HEIGHT:
		var x := 0
		while x < WIDTH:
			var c := _cell(x, y)
			if c == "#" or c == "=":
				# Merge a whole run of blocks into one collision shape.
				var start := x
				while x < WIDTH and _cell(x, y) == c:
					x += 1
				if c == "#":
					_add_shape(solids, Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE), false)
				else:
					_add_shape(platforms, Rect2(start * TILE, y * TILE, (x - start) * TILE, 10), true)
				continue
			var foot := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			match c:
				"P":
					player_spawn = foot
				"D":
					door = Door.new()
					door.position = foot
					add_child(door)
				"s":
					spawns.append(["slime", foot])
				"b":
					spawns.append(["bat", foot])
				"B":
					spawns.append(["boss", foot])
			x += 1
	for spawn in spawns:
		var enemy := Enemy.new()
		enemy.setup(spawn[0], spawn[1])
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)
	queue_redraw()


func open_door() -> void:
	if door:
		door.open = true
		FX.burst(self, door.position + Vector2(0, -36), Color(0.6, 1.4, 2.2), 30, 260.0)


func _process(_delta: float) -> void:
	if door == null or not door.open or _exited:
		return
	if is_instance_valid(player) and not player.is_dead() and door.get_rect().intersects(player.get_hit_rect()):
		_exited = true
		exit_reached.emit()


func _on_enemy_died() -> void:
	_check_cleared.call_deferred()


func _check_cleared() -> void:
	if not is_cleared and get_tree().get_nodes_in_group("enemies").is_empty():
		is_cleared = true
		cleared.emit()


func _make_grid(map: Array) -> void:
	var inner_w := WIDTH - 2
	var lines := map.duplicate()
	while lines.size() < HEIGHT - 2:
		lines.push_front("")
	var wall := "#".repeat(WIDTH)
	_grid = [wall]
	for i in HEIGHT - 2:
		var line: String = lines[i]
		_grid.append("#" + line.substr(0, inner_w).rpad(inner_w, ".") + "#")
	_grid.append(wall)


func _cell(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT:
		return "#"
	return _grid[y][x]


func _make_body(layer: int) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	add_child(body)
	return body


func _add_shape(body: StaticBody2D, rect: Rect2, one_way: bool) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	collision.one_way_collision = one_way
	body.add_child(collision)


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	# Faint ruined pillars in the background for depth.
	for i in range(3, WIDTH, 9):
		draw_rect(Rect2(i * TILE, TILE, TILE * 1.5, (HEIGHT - 2) * TILE), Color(0.3, 0.2, 0.5, 0.08))
		draw_rect(Rect2(i * TILE - 8, TILE * 3, TILE * 1.5 + 16, 10), Color(0.3, 0.2, 0.5, 0.1))
	for y in HEIGHT + 1:
		for x in WIDTH:
			var c := _cell(x, mini(y, HEIGHT - 1))
			if c == "#":
				_draw_block(x, y)
			elif c == "=":
				_draw_platform(x, y)


func _draw_block(x: int, y: int) -> void:
	var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
	var shade := 0.8 + 0.3 * _noise(x, y)
	draw_rect(rect, Color(STONE.r * shade, STONE.g * shade, STONE.b * shade))
	# Brick seams
	draw_line(rect.position + Vector2(0, TILE - 1), rect.end - Vector2(0, 1), Color(0, 0, 0, 0.35), 2.0)
	var seam_x := rect.position.x + (TILE / 2.0 if y % 2 == 0 else 0.0)
	draw_line(Vector2(seam_x, rect.position.y), Vector2(seam_x, rect.end.y), Color(0, 0, 0, 0.25), 2.0)
	if y > 0 and y < HEIGHT and _cell(x, y - 1) != "#":
		# Exposed top: glowing moss and the odd crystal.
		draw_rect(Rect2(rect.position, Vector2(TILE, 4)), MOSS)
		draw_rect(Rect2(rect.position + Vector2(0, 4), Vector2(TILE, 2)), MOSS.darkened(0.5))
		if _noise(x, y) > 0.72:
			var base := rect.position + Vector2(TILE * _noise(y, x), 0)
			draw_colored_polygon(PackedVector2Array([
				base + Vector2(-4, 0), base + Vector2(0, -12), base + Vector2(4, 0),
			]), CRYSTAL)


func _draw_platform(x: int, y: int) -> void:
	var rect := Rect2(x * TILE, y * TILE, TILE, 10)
	draw_rect(rect, Color(0.26, 0.18, 0.4))
	draw_rect(Rect2(rect.position, Vector2(TILE, 2)), Color(0.9, 0.65, 1.4))
	draw_line(rect.position + Vector2(TILE - 1, 2), rect.position + Vector2(TILE - 1, 10), Color(0, 0, 0, 0.4), 2.0)
	if _cell(x - 1, y) != "=" or _cell(x + 1, y) != "=":
		# Hanging chain at the ends of each platform
		var cx := rect.position.x + TILE / 2.0
		draw_line(Vector2(cx, rect.position.y + 10), Vector2(cx, rect.position.y + 22), Color(0.4, 0.35, 0.5), 2.0)


func _noise(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
