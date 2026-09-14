extends Control

var label: Label
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.position = Vector2(58, 110)
	panel.custom_minimum_size = Vector2(540, 260)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 18)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	hide()

func _process(delta: float) -> void:
	visible = GameManager.debug_visible
	if not visible or not is_instance_valid(WorldManager.player):
		return
	elapsed += delta
	if elapsed < 0.25:
		return
	elapsed = 0
	label.text = "DEBUG / F3\nMap: %s   Ren: %s\nDay: %d   Period: %s\nMira: %s\nInventory: %s\nQuests: %s\nFlags: %s" % [WorldManager.current_map, WorldManager.player.position, TimeManager.day, TimeManager.get_current_period(), JSON.stringify(RelationshipManager.relationships), JSON.stringify(InventoryManager.items), JSON.stringify(QuestManager.quests), JSON.stringify(GameManager.flags)]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 540
