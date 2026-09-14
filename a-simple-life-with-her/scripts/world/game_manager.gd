extends Node

signal state_changed
signal message_posted(text: String, is_error: bool)
signal modal_changed

const ContentLoader = preload("res://scripts/world/content_loader.gd")
var content: Dictionary = {}
var flags: Dictionary = {}
var stats: Dictionary = {}
var initialized := false
var menu_open := false
var loading := false
var touch_vector := Vector2.ZERO
var debug_visible := false

func initialize() -> bool:
	if initialized:
		return true
	configure_input()
	var loader = ContentLoader.new()
	content = {
		"characters": {"ren": loader.read_dictionary("res://data/characters/ren.json"), "mira": loader.read_dictionary("res://data/characters/mira.json")},
		"items": loader.read_dictionary("res://data/items/items.json"),
		"quests": {},
		"dialogue": loader.read_dictionary("res://data/dialogue/mira.json")
	}
	var quest: Dictionary = loader.read_dictionary("res://data/quests/breakfast.json")
	content.quests[quest.get("id", "")] = quest
	content.dialogue.merge(loader.read_dictionary("res://data/dialogue/home.json"))
	if not loader.validate(content):
		report(loader.error, true)
		return false
	initialized = true
	reset_session()
	return true

func reset_session() -> void:
	DialogueManager.close()
	flags = {}
	stats = content.characters.ren.stats.duplicate(true)
	InventoryManager.reset_state()
	QuestManager.reset_state()
	RelationshipManager.reset_state()
	TimeManager.reset_state()
	menu_open = false
	loading = false
	touch_vector = Vector2.ZERO
	state_changed.emit()
	modal_changed.emit()

func configure_input() -> void:
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "interact": [KEY_E], "menu": [KEY_ESCAPE], "debug": [KEY_F3]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

func is_blocked() -> bool:
	return not initialized or menu_open or loading or DialogueManager.active

func clear_input() -> void:
	touch_vector = Vector2.ZERO
	for action in ["move_left", "move_right", "move_up", "move_down", "interact"]:
		Input.action_release(action)

func set_menu(value: bool) -> void:
	if DialogueManager.active or loading:
		return
	menu_open = value
	clear_input()
	modal_changed.emit()

func report(text: String, is_error: bool = false) -> void:
	if is_error:
		push_error(text)
	message_posted.emit(text, is_error)

func set_flag(key: String, value: bool) -> void:
	flags[key] = value
	state_changed.emit()

func condition_met(condition: Dictionary) -> bool:
	if condition.has("quest_status") and QuestManager.status(condition.quest_id) != condition.quest_status:
		return false
	if condition.has("quest_ready") and not QuestManager.can_complete(condition.quest_ready):
		return false
	if condition.has("flag") and not flags.get(condition.flag, false):
		return false
	return true

func apply_effect(effect: Dictionary) -> bool:
	match effect.type:
		"start_quest":
			return QuestManager.start_quest(effect.quest_id)
		"complete_quest":
			return QuestManager.complete_quest(effect.quest_id)
		"relationship":
			return RelationshipManager.add_points(effect.character_id, int(effect.get("points", 0)), int(effect.get("friendship", 0)), int(effect.get("affection", 0)))
		"flag":
			set_flag(effect.key, effect.value)
		"advance_time":
			TimeManager.advance_time(int(effect.steps))
		"rest":
			TimeManager.next_morning()
			stats.energy = content.characters.ren.stats.energy
			state_changed.emit()
		_:
			report("Unknown effect: " + str(effect.type), true)
			return false
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		clear_input()
		if initialized:
			menu_open = true
			modal_changed.emit()
