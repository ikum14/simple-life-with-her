extends Node

signal line_changed(speaker: String, text: String, choices: Array)
signal closed
var active := false
var dialogue_id := ""
var node_id := ""
var available_choices: Array = []
var effect_nodes: Dictionary = {}

func start_dialogue(id: String) -> bool:
	if active or GameManager.menu_open or GameManager.loading:
		return false
	if not GameManager.content.dialogue.has(id):
		GameManager.report("Missing dialogue ID: " + id, true)
		return false
	dialogue_id = id
	node_id = GameManager.content.dialogue[id].start
	effect_nodes = {}
	active = true
	GameManager.clear_input()
	GameManager.modal_changed.emit()
	show_node()
	return true

func current_node() -> Dictionary:
	return GameManager.content.dialogue[dialogue_id].nodes[node_id] if active else {}

func show_node() -> void:
	var node := current_node()
	available_choices = []
	for choice in node.get("choices", []):
		if GameManager.condition_met(choice.get("condition", {})):
			available_choices.append(choice)
	line_changed.emit(node.speaker, node.text, available_choices)

func advance(choice_index: int = -1) -> bool:
	if not active or GameManager.menu_open or GameManager.loading:
		return false
	var node := current_node()
	if not available_choices.is_empty() and (choice_index < 0 or choice_index >= available_choices.size()):
		return false
	if not effect_nodes.has(node_id):
		for effect in node.get("effects", []):
			if not GameManager.apply_effect(effect):
				return false
		effect_nodes[node_id] = true
	var next_id: String = available_choices[choice_index].next if not available_choices.is_empty() else str(node.get("next", ""))
	if next_id.is_empty():
		close()
	else:
		node_id = next_id
		show_node()
	return true

func close() -> void:
	active = false
	dialogue_id = ""
	node_id = ""
	available_choices = []
	effect_nodes = {}
	GameManager.clear_input()
	closed.emit()
	GameManager.modal_changed.emit()
