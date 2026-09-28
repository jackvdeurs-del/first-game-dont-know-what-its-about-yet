class_name Hud
extends Control
## Heads-up display: hearts, fighting styles, chosen talents, the boss
## health bar, the room title and big announcement banners.

var room_title := ""
var _banner := ""
var _banner_time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE


func show_banner(text: String) -> void:
	_banner = text
	_banner_time = 3.0


func _process(delta: float) -> void:
	_banner_time = maxf(_banner_time - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in Game.max_health:
		var col := Color(1.7, 0.3, 0.45) if i < Game.health else Color(0.25, 0.2, 0.3, 0.8)
		_heart(Vector2(34 + i * 30, 32), 11.0, col)

	for s in 3:
		var r := Rect2(24 + s * 150, 56, 140, 30)
		var unlocked := s in Game.unlocked_styles
		var col: Color = Game.style_color(s) if unlocked else Color(0.5, 0.5, 0.55)
		draw_rect(r, Color(0.05, 0.02, 0.1, 0.65))
		if s == Game.current_style:
			draw_rect(r, FX.hdr(col, 1.6), false, 2.0)
		var label: String = Game.STYLE_NAMES[s] if unlocked else "???"
		_text(font, r.position + Vector2(10, 21), "%d  %s" % [s + 1, label], 15, col)

	if not Game.talent_names.is_empty():
		var talents := ", ".join(PackedStringArray(Game.talent_names))
		_text(font, Vector2(24, 112), "Talents: " + talents, 14, Color(1.0, 0.9, 0.65, 0.9))

	_text(font, Vector2(0, 38), room_title, 18, Color(0.85, 0.8, 1.0), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 24.0)

	var boss := get_tree().get_first_node_in_group("boss") as Enemy
	if boss:
		var w := 320.0
		var bar := Rect2((size.x - w) / 2.0, 62.0, w, 14.0)
		draw_rect(bar.grow(3.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(bar.position, Vector2(w * maxf(boss.hp, 0.0) / boss.max_hp, bar.size.y)), Color(1.6, 0.4, 1.8))
		_text(font, Vector2(0, bar.position.y - 10.0), "THE SLIME KING", 18, Color(1.0, 0.8, 1.0), HORIZONTAL_ALIGNMENT_CENTER, size.x)

	if _banner_time > 0.0:
		var color := Color(1.0, 0.92, 0.7, minf(_banner_time, 1.0))
		_text(font, Vector2(0, size.y * 0.28), _banner, 34, color, HORIZONTAL_ALIGNMENT_CENTER, size.x)

	if Game.room_index == 0:
		var controls := "A/D move  |  Space jump  |  J or click attack  |  K dash  |  Q/E or 1-3 switch style  |  S+Space drop down"
		_text(font, Vector2(0, size.y - 20.0), controls, 15, Color(0.85, 0.85, 1.0, 0.8), HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _text(font: Font, pos: Vector2, text: String, font_size: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string_outline(font, pos, text, align, width, font_size, 6, Color(0.03, 0.0, 0.08, 0.9))
	draw_string(font, pos, text, align, width, font_size, color)


func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 1.03, -r * 0.05), c + Vector2(r * 1.03, -r * 0.05), c + Vector2(0, r * 1.1),
	]), col)
