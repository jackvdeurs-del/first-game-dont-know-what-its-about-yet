class_name TalentPicker
extends Control
## Pause screen that offers a few talents after a room is cleared.
## Pick with the mouse, the number keys 1-3, or arrow keys + Enter.

signal picked(talent: Dictionary)

var _options: Array = []
var _accepting := false


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func open(options: Array) -> void:
	_options = options
	for child in get_children():
		child.queue_free()

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.06, 0.78)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)

	var title := Label.new()
	title.text = "Room cleared!  Choose a talent"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	column.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	column.add_child(row)
	var buttons: Array[Button] = []
	for i in options.size():
		var card := _make_card(options[i], i)
		card.pressed.connect(_choose.bind(i))
		card.disabled = true  # briefly, so a held key doesn't pick by accident
		row.add_child(card)
		buttons.append(card)

	show()
	_accepting = false
	await get_tree().create_timer(0.45).timeout
	for card in buttons:
		card.disabled = false
	_accepting = true
	if not buttons.is_empty():
		buttons[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _accepting:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var index := int(key.physical_keycode) - int(KEY_1)
		if index >= 0 and index < _options.size():
			_choose(index)
			get_viewport().set_input_as_handled()


func _choose(index: int) -> void:
	if not _accepting:
		return
	_accepting = false
	hide()
	picked.emit(_options[index])


func _make_card(talent: Dictionary, index: int) -> Button:
	var accent := Color(1.0, 0.85, 0.45)
	if talent.has("style"):
		accent = Game.style_color(talent["style"])

	var card := Button.new()
	card.custom_minimum_size = Vector2(260, 190)
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		var highlighted: bool = state in ["hover", "focus", "pressed"]
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.14, 0.1, 0.26, 0.97) if highlighted else Color(0.09, 0.07, 0.18, 0.96)
		box.border_color = accent if highlighted else accent.darkened(0.5)
		box.set_border_width_all(3 if highlighted else 2)
		box.set_corner_radius_all(12)
		card.add_theme_stylebox_override(state, box)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var key_label := _label("[%d]" % (index + 1), 14, Color(0.6, 0.55, 0.75))
	var title_label := _label(talent["name"], 24, accent)
	var desc_label := _label(talent["desc"], 17, Color(0.9, 0.88, 1.0))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(220, 0)
	for label in [key_label, title_label, desc_label]:
		column.add_child(label)
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
