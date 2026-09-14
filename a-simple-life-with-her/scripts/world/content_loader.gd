extends RefCounted

var error: String = ""

func read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		fail("Missing data file: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		fail("Cannot read data: " + path)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		fail("Invalid JSON dictionary: " + path + " " + parser.get_error_message())
		return {}
	return parser.data

func fail(message: String) -> bool:
	if error.is_empty():
		error = message
	push_error(message)
	return false

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

func validate(data: Dictionary) -> bool:
	if not error.is_empty():
		return false
	for section in ["items", "quests", "dialogue", "characters"]:
		if not data.get(section) is Dictionary or data[section].is_empty():
			return fail("Missing content section: " + section)
	for id in data.items:
		var item: Variant = data.items[id]
		if not item is Dictionary or not item.get("name") is String or not integer(item.get("stack_limit"), 1, 9999):
			return fail("Invalid item definition: " + id)
	for id in data.characters:
		var character: Variant = data.characters[id]
		if not character is Dictionary or character.get("id") != id or not character.get("name") is String:
			return fail("Invalid character: " + id)
	var stats: Variant = data.characters.ren.get("stats")
	if not stats is Dictionary:
		return fail("Missing Ren statistics")
	for key in ["health", "energy", "speed"]:
		if not integer(stats.get(key), 1, 1000):
			return fail("Invalid Ren statistic: " + key)
	var mira: Dictionary = data.characters.mira
	if not mira.get("relationship") is Dictionary or not mira.get("level_thresholds") is Array or mira.level_thresholds.is_empty():
		return fail("Missing Mira relationship data")
	var previous := -1
	for threshold in mira.level_thresholds:
		if not integer(threshold, 0, 1000000) or threshold <= previous:
			return fail("Relationship thresholds must increase")
		previous = int(threshold)
	for id in data.quests:
		var quest: Variant = data.quests[id]
		if not quest is Dictionary or quest.get("id") != id or not quest.get("title") is String or not quest.get("description") is String or not quest.get("objectives") is Array or quest.objectives.is_empty() or not quest.get("required_items") is Dictionary or not quest.get("rewards") is Array:
			return fail("Invalid quest definition: " + id)
		var objective_ids: Array = []
		for objective in quest.objectives:
			if not objective is Dictionary or not objective.get("id") is String or objective.id in objective_ids or not objective.get("type") in ["talk", "collect", "return"] or not integer(objective.get("quantity"), 1, 9999) or not objective.get("text") is String:
				return fail("Invalid quest objective: " + id)
			objective_ids.append(objective.id)
			var targets: Dictionary = data.items if objective.type == "collect" else data.characters
			if not targets.has(objective.get("target", "")):
				return fail("Unknown objective target: " + id)
		for item_id in quest.required_items:
			if not data.items.has(item_id) or not integer(quest.required_items[item_id], 1, int(data.items[item_id].stack_limit)):
				return fail("Invalid required item: " + str(item_id))
		for effect in quest.rewards:
			if not validate_effect(effect, data, true):
				return false
	for id in data.dialogue:
		var entry: Variant = data.dialogue[id]
		if not entry is Dictionary or not entry.get("nodes") is Dictionary or not entry.nodes.has(entry.get("start", "")):
			return fail("Invalid dialogue graph: " + id)
		for node_id in entry.nodes:
			var node: Variant = entry.nodes[node_id]
			if not node is Dictionary or not node.get("speaker") is String or not node.get("text") is String:
				return fail("Invalid dialogue node: " + id + "/" + node_id)
			if node.has("next") and not entry.nodes.has(node.next):
				return fail("Missing dialogue next node: " + id)
			if not node.get("effects", []) is Array or not node.get("choices", []) is Array:
				return fail("Invalid dialogue effects/choices: " + id)
			for effect in node.get("effects", []):
				if not validate_effect(effect, data):
					return false
			for choice in node.get("choices", []):
				if not choice is Dictionary or not choice.get("text") is String or not entry.nodes.has(choice.get("next", "")) or not validate_condition(choice.get("condition", {}), data):
					return fail("Invalid dialogue choice: " + id)
	if not mira.get("dialogue_rules") is Array:
		return fail("Missing Mira dialogue rules")
	for rule in mira.dialogue_rules:
		if not rule is Dictionary or not data.dialogue.has(rule.get("dialogue_id", "")) or not validate_condition(rule.get("condition", {}), data):
			return fail("Invalid Mira dialogue rule")
	return true

func validate_condition(condition: Variant, data: Dictionary) -> bool:
	if not condition is Dictionary:
		return fail("Condition must be a dictionary")
	for key in condition:
		if not key in ["quest_status", "quest_id", "quest_ready", "flag"]:
			return fail("Unknown condition: " + key)
	if condition.has("quest_status") and (not condition.quest_status in ["not_started", "active", "completed"] or not data.quests.has(condition.get("quest_id", ""))):
		return fail("Invalid quest status condition")
	if condition.has("quest_ready") and not data.quests.has(condition.quest_ready):
		return fail("Unknown quest condition")
	if condition.has("flag") and not condition.flag is String:
		return fail("Invalid flag condition")
	return true

func validate_effect(effect: Variant, data: Dictionary, reward: bool = false) -> bool:
	if not effect is Dictionary:
		return fail("Effect must be a dictionary")
	match effect.get("type", ""):
		"start_quest", "complete_quest":
			if reward or not data.quests.has(effect.get("quest_id", "")):
				return fail("Invalid quest effect")
		"relationship":
			if effect.get("character_id") != "mira":
				return fail("Unknown relationship character")
			for key in ["points", "friendship", "affection"]:
				if not integer(effect.get(key, 0), 0, 10000):
					return fail("Invalid relationship reward")
		"flag":
			if not effect.get("key") is String or not effect.get("value") is bool:
				return fail("Invalid flag effect")
		"advance_time":
			if not integer(effect.get("steps"), 1, 100):
				return fail("Invalid time effect")
		"rest":
			pass
		_:
			return fail("Unknown effect: " + str(effect.get("type")))
	return true
