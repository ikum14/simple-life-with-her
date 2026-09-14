extends Control

var speaker_label: Label
var text_label: Label
var actions: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.2)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 50
	panel.offset_right = -50
	panel.offset_top = -252
	panel.offset_bottom = -24
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	speaker_label = Label.new()
	speaker_label.add_theme_color_override("font_color", Color("c5d8b2"))
	speaker_label.add_theme_font_size_override("font_size", 24)
	column.add_child(speaker_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text_label)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	column.add_child(actions)
	DialogueManager.line_changed.connect(show_line)
	DialogueManager.closed.connect(hide)
	hide()

func show_line(speaker: String, text: String, choices: Array) -> void:
	speaker_label.text = speaker.to_upper()
	text_label.text = text
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	if choices.is_empty():
		add_action("Next  /  E" if DialogueManager.current_node().has("next") else "Close  /  E", -1)
	else:
		for index in choices.size():
			add_action(choices[index].text, index)
	show()
	actions.get_child(0).grab_focus()

func add_action(text: String, index: int) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): DialogueManager.advance(index))
	actions.add_child(button)
