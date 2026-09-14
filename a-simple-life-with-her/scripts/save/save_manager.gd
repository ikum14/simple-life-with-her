extends Node

const Validator = preload("res://scripts/world/content_loader.gd")
const SAVE_VERSION := 1
const MAX_BYTES := 1048576
var save_path := "user://save_v1.json"
var last_error := ""

func reject(message: String) -> bool:
	last_error = message
	return false

func capture() -> Dictionary:
	return {"save_version": SAVE_VERSION, "map_id": WorldManager.current_map, "player": WorldManager.capture_player(), "time": {"day": TimeManager.day, "period": TimeManager.period}, "inventory": InventoryManager.items.duplicate(true), "quests": QuestManager.quests.duplicate(true), "relationships": RelationshipManager.relationships.duplicate(true), "flags": GameManager.flags.duplicate(true)}

func valid_flags(value: Variant) -> bool:
	if not value is Dictionary or value.size() > 10000:
		return false
	for key in value:
		if not key is String or key.is_empty() or key.length() > 128 or not value[key] is bool:
			return false
	return true

func valid_vector(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for component in value:
		if not (component is float or component is int) or not is_finite(float(component)) or absf(float(component)) > 100000:
			return false
	return true

func validate(data: Variant) -> bool:
	last_error = ""
	if not data is Dictionary:
		return reject("Save root is not a dictionary")
	if not Validator.integer(data.get("save_version"), 1, SAVE_VERSION) or data.save_version != SAVE_VERSION:
		return reject("Unsupported save version; this build accepts version 1 only")
	for key in ["player", "time", "inventory", "quests", "relationships", "flags"]:
		if not data.get(key) is Dictionary:
			return reject("Missing or invalid save section: " + key)
	if not data.get("map_id") is String or not WorldManager.MAPS.has(data.map_id):
		return reject("Unknown saved map")
	if not valid_vector(data.player.get("position")) or not valid_vector(data.player.get("facing")):
		return reject("Invalid player coordinates")
	var facing := Vector2(data.player.facing[0], data.player.facing[1])
	if not facing in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		return reject("Invalid player facing")
	if not data.player.get("stats") is Dictionary:
		return reject("Missing player statistics")
	for key in ["health", "energy", "speed"]:
		if not Validator.integer(data.player.stats.get(key), 1 if key == "speed" else 0, int(GameManager.content.characters.ren.stats[key])):
			return reject("Invalid saved statistic: " + key)
	if not Validator.integer(data.time.get("day"), 1, 1000000) or not Validator.integer(data.time.get("period"), 0, 3):
		return reject("Invalid saved day or period")
	if not valid_flags(data.flags):
		return reject("Invalid saved flags")
	for id in data.inventory:
		if not GameManager.content.items.has(id) or not Validator.integer(data.inventory[id], 1, int(GameManager.content.items[id].stack_limit)):
			return reject("Invalid saved inventory item: " + str(id))
	if data.quests.size() != GameManager.content.quests.size():
		return reject("Saved quests do not match this content version")
	for id in GameManager.content.quests:
		var quest: Variant = data.quests.get(id)
		if not quest is Dictionary or not quest.get("status") in ["not_started", "active", "completed"] or not quest.get("objectives") is Dictionary or not quest.get("rewards_claimed") is bool:
			return reject("Invalid saved quest: " + id)
		var definition: Dictionary = GameManager.content.quests[id]
		if quest.objectives.size() != definition.objectives.size() or quest.rewards_claimed != (quest.status == "completed"):
			return reject("Inconsistent quest rewards or objectives: " + id)
		for objective in definition.objectives:
			var count: Variant = quest.objectives.get(objective.id)
			if not Validator.integer(count, 0, int(objective.quantity)):
				return reject("Invalid objective count: " + id)
			if (quest.status == "not_started" and count != 0) or (quest.status == "completed" and count != objective.quantity):
				return reject("Inconsistent quest progress: " + id)
			if quest.status == "active":
				var expected := int(objective.quantity) if objective.type == "talk" else 0
				if objective.type == "collect":
					expected = mini(int(data.inventory.get(objective.target, 0)), int(objective.quantity))
				if count != expected:
					return reject("Active objective does not match inventory or dialogue progress")
		for effect in definition.rewards:
			if effect.type == "flag" and quest.status == "completed" and data.flags.get(effect.key) != effect.value:
				return reject("Completed quest is missing its reward flag")
	var expected_relationships: Array = []
	for id in GameManager.content.characters:
		if GameManager.content.characters[id].has("relationship"):
			expected_relationships.append(id)
	if data.relationships.size() != expected_relationships.size():
		return reject("Saved relationship characters do not match content")
	for id in expected_relationships:
		var relation: Variant = data.relationships.get(id)
		if not relation is Dictionary:
			return reject("Missing relationship: " + id)
		for key in ["relationship_points", "relationship_level", "affection", "friendship"]:
			if not Validator.integer(relation.get(key), 0, 1000000):
				return reject("Invalid relationship value: " + key)
		if relation.relationship_level != RelationshipManager.level_for(id, int(relation.relationship_points)) or not valid_flags(relation.get("event_flags")):
			return reject("Invalid relationship level or event flags")
	return true

func read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		reject("Save file not found: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		reject("Cannot open save file: " + path)
		return {}
	if file.get_length() > MAX_BYTES:
		reject("Save file is too large")
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		reject("Save JSON is corrupt: " + parser.get_error_message())
		return {}
	if not validate(parser.data):
		return {}
	return parser.data

func save_game() -> bool:
	if GameManager.loading or DialogueManager.active or not is_instance_valid(WorldManager.player):
		GameManager.report("Finish the conversation before saving.", true)
		return false
	var data := capture()
	if not validate(data) or not WorldManager.position_is_safe(WorldManager.player.global_position):
		GameManager.report("Cannot save: " + (last_error if not last_error.is_empty() else "player position is obstructed"), true)
		return false
	var temp := save_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		GameManager.report("Cannot create temporary save: " + error_string(FileAccess.get_open_error()), true)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		GameManager.report("Save write failed: " + error_string(write_error), true)
		return false
	if read_save(temp).is_empty():
		GameManager.report("Temporary save failed validation: " + last_error, true)
		return false
	# A corrupt primary must never replace a healthy backup.
	if FileAccess.file_exists(save_path) and not read_save(save_path).is_empty():
		var backup_error := DirAccess.copy_absolute(save_path, save_path + ".bak")
		if backup_error != OK:
			GameManager.report("Cannot preserve save backup: " + error_string(backup_error), true)
			return false
	var result := DirAccess.rename_absolute(temp, save_path)
	if result != OK:
		GameManager.report("Cannot finalize save: " + error_string(result), true)
		return false
	GameManager.report("Game saved.")
	return true

func apply_state(data: Dictionary) -> void:
	GameManager.stats = data.player.stats.duplicate(true)
	GameManager.flags = data.flags.duplicate(true)
	InventoryManager.items = data.inventory.duplicate(true)
	QuestManager.quests = data.quests.duplicate(true)
	RelationshipManager.relationships = data.relationships.duplicate(true)
	TimeManager.day = int(data.time.day)
	TimeManager.period = int(data.time.period)
	WorldManager.player.global_position = Vector2(data.player.position[0], data.player.position[1])
	WorldManager.player.facing = Vector2(data.player.facing[0], data.player.facing[1])
	WorldManager.player.velocity = Vector2.ZERO
	GameManager.state_changed.emit()
	InventoryManager.changed.emit()
	QuestManager.changed.emit()
	TimeManager.changed.emit()
	for id in RelationshipManager.relationships:
		RelationshipManager.changed.emit(id)

func load_game() -> bool:
	if GameManager.loading or DialogueManager.active or not is_instance_valid(WorldManager.player):
		GameManager.report("Finish the conversation before loading.", true)
		return false
	var data := read_save(save_path)
	var recovered := false
	if data.is_empty():
		var primary_error := last_error
		if primary_error.begins_with("Unsupported save version"):
			GameManager.report(primary_error, true)
			return false
		data = read_save(save_path + ".bak")
		if data.is_empty():
			GameManager.report("Load failed: " + primary_error + "; backup: " + last_error, true)
			return false
		recovered = true
	var previous := capture()
	GameManager.loading = true
	GameManager.clear_input()
	GameManager.modal_changed.emit()
	var mounted := true
	if WorldManager.current_map != data.map_id:
		mounted = WorldManager.change_map(data.map_id)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var point := Vector2(data.player.position[0], data.player.position[1])
	if not mounted or not WorldManager.position_is_safe(point):
		if WorldManager.current_map != previous.map_id:
			WorldManager.change_map(previous.map_id)
		await get_tree().physics_frame
		await get_tree().physics_frame
		apply_state(previous)
		GameManager.loading = false
		GameManager.modal_changed.emit()
		GameManager.report("Load rejected: destination is obstructed or unavailable; current session preserved.", true)
		return false
	DialogueManager.close()
	apply_state(data)
	GameManager.loading = false
	GameManager.menu_open = false
	GameManager.modal_changed.emit()
	GameManager.report("Loaded backup save; primary was missing or corrupt." if recovered else "Game loaded.")
	return true
