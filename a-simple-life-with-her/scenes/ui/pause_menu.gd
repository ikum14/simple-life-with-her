extends Control

var details: Label
var feedback: Label
var save_button: Button
var load_button: Button
var active_tab := "overview"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.07, 0.06, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 100
	panel.offset_right = -100
	panel.offset_top = 85
	panel.offset_bottom = -60
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.text = "A SIMPLE LIFE WITH HER  /  PAUSED"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	column.add_child(tabs)
	add_button(tabs, "Overview", func(): active_tab = "overview"; refresh())
	add_button(tabs, "Inventory", func(): active_tab = "inventory"; refresh())
	add_button(tabs, "Quests", func(): active_tab = "quests"; refresh())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(details)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(feedback)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	add_button(buttons, "Resume", func(): GameManager.set_menu(false))
	save_button = add_button(buttons, "Save", func(): SaveManager.save_game())
	load_button = add_button(buttons, "Load", func(): await SaveManager.load_game())
	add_button(buttons, "Debug on/off", func(): GameManager.debug_visible = not GameManager.debug_visible)
	GameManager.modal_changed.connect(sync_visibility)
	GameManager.message_posted.connect(func(text, is_error): feedback.text = text; feedback.modulate = Color("ffb9a9") if is_error else Color("c5d8b2"))
	InventoryManager.changed.connect(refresh)
	QuestManager.changed.connect(refresh)
	sync_visibility()

func add_button(parent_node: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 56)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent_node.add_child(button)
	return button

func sync_visibility() -> void:
	visible = GameManager.menu_open
	save_button.disabled = GameManager.loading or DialogueManager.active
	load_button.disabled = GameManager.loading or DialogueManager.active
	refresh()

func refresh() -> void:
	if not is_instance_valid(details) or not GameManager.initialized:
		return
	match active_tab:
		"inventory":
			details.text = "INVENTORY\n\n" + InventoryManager.describe()
		"quests":
			details.text = "QUEST JOURNAL\n\n" + QuestManager.describe()
		_:
			details.text = "DAY %d · %s\n\nMove with the stick or WASD / arrow keys. Approach Mira and press Interact or E.\n\nBread is in the kitchen (upper right). Rest at the bed to start a new day.\n\nSave is manual. Finish your conversation before saving. F3 toggles debug information." % [TimeManager.day, TimeManager.get_current_period()]
