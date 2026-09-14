extends Node

signal changed
var items: Dictionary = {}

func reset_state() -> void:
	items = {}
	changed.emit()

func get_quantity(item_id: String) -> int:
	return int(items.get(item_id, 0))

func valid_item(item_id: String) -> bool:
	if not GameManager.content.items.has(item_id):
		GameManager.report("Invalid item ID: " + item_id, true)
		return false
	return true

func can_add(item_id: String, quantity: int) -> bool:
	return valid_item(item_id) and quantity > 0 and get_quantity(item_id) + quantity <= int(GameManager.content.items[item_id].stack_limit)

func add_item(item_id: String, quantity: int = 1) -> bool:
	if not can_add(item_id, quantity):
		GameManager.report("Cannot add item: " + item_id + " (invalid quantity or full stack)", true)
		return false
	items[item_id] = get_quantity(item_id) + quantity
	changed.emit()
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not valid_item(item_id) or quantity <= 0 or get_quantity(item_id) < quantity:
		GameManager.report("Cannot remove item: " + item_id + " (invalid quantity or insufficient items)", true)
		return false
	items[item_id] = get_quantity(item_id) - quantity
	if items[item_id] == 0:
		items.erase(item_id)
	changed.emit()
	return true

func describe() -> String:
	if items.is_empty():
		return "Your bag is empty."
	var lines := PackedStringArray()
	for id in items:
		lines.append("%s × %d" % [GameManager.content.items[id].name, items[id]])
	return "\n".join(lines)
