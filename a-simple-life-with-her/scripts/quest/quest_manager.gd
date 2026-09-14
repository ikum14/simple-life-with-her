extends Node

signal changed
var quests: Dictionary = {}

func _ready() -> void:
	InventoryManager.changed.connect(reconcile_inventory)

func reset_state() -> void:
	quests = {}
	for id in GameManager.content.quests:
		var objectives: Dictionary = {}
		for objective in GameManager.content.quests[id].objectives:
			objectives[objective.id] = 0
		quests[id] = {"status": "not_started", "objectives": objectives, "rewards_claimed": false}
	changed.emit()

func valid_quest(id: String) -> bool:
	if not quests.has(id):
		GameManager.report("Missing quest ID: " + id, true)
		return false
	return true

func status(id: String) -> String:
	return str(quests[id].status) if valid_quest(id) else "invalid"

func start_quest(id: String) -> bool:
	if not valid_quest(id):
		return false
	if quests[id].status != "not_started":
		return true
	quests[id].status = "active"
	for objective in GameManager.content.quests[id].objectives:
		if objective.type == "talk":
			quests[id].objectives[objective.id] = int(objective.quantity)
	reconcile_inventory()
	changed.emit()
	GameManager.report("Quest started: " + GameManager.content.quests[id].title)
	return true

func reconcile_inventory() -> void:
	for id in quests:
		if quests[id].status != "active":
			continue
		for objective in GameManager.content.quests[id].objectives:
			if objective.type == "collect":
				quests[id].objectives[objective.id] = mini(InventoryManager.get_quantity(objective.target), int(objective.quantity))
	changed.emit()

func can_complete(id: String) -> bool:
	if not quests.has(id) or quests[id].status != "active":
		return false
	var definition: Dictionary = GameManager.content.quests[id]
	for item_id in definition.required_items:
		if InventoryManager.get_quantity(item_id) < int(definition.required_items[item_id]):
			return false
	for objective in definition.objectives:
		if objective.type != "return" and int(quests[id].objectives[objective.id]) < int(objective.quantity):
			return false
	return true

func complete_quest(id: String) -> bool:
	if not valid_quest(id):
		return false
	if quests[id].status == "completed":
		return true
	if not can_complete(id):
		GameManager.report("Quest requirements not met: " + id, true)
		return false
	var definition: Dictionary = GameManager.content.quests[id]
	# Mark complete before inventory signals fire, so hand-in cannot erase objectives.
	quests[id].status = "completed"
	quests[id].rewards_claimed = true
	for objective in definition.objectives:
		quests[id].objectives[objective.id] = int(objective.quantity)
	for item_id in definition.required_items:
		InventoryManager.remove_item(item_id, int(definition.required_items[item_id]))
	for effect in definition.rewards:
		GameManager.apply_effect(effect)
	changed.emit()
	GameManager.report("Breakfast prepared. Mira +10 relationship points.")
	return true

func describe() -> String:
	var lines := PackedStringArray()
	for id in quests:
		var definition: Dictionary = GameManager.content.quests[id]
		lines.append(definition.title + " — " + str(quests[id].status).replace("_", " "))
		lines.append(definition.description)
		for objective in definition.objectives:
			lines.append("  %s  %d/%d" % [objective.text, quests[id].objectives[objective.id], objective.quantity])
	return "\n".join(lines)
