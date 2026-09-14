extends Node

signal changed(character_id: String)
var relationships: Dictionary = {}

func reset_state() -> void:
	relationships = {}
	for id in GameManager.content.characters:
		var character: Dictionary = GameManager.content.characters[id]
		if character.has("relationship"):
			relationships[id] = character.relationship.duplicate(true)
			changed.emit(id)

func level_for(character_id: String, points: int) -> int:
	var level := 0
	var thresholds: Array = GameManager.content.characters[character_id].level_thresholds
	for index in thresholds.size():
		if points >= int(thresholds[index]):
			level = index
	return level

func add_points(character_id: String, points: int, friendship: int = 0, affection: int = 0) -> bool:
	if not relationships.has(character_id) or mini(points, mini(friendship, affection)) < 0:
		GameManager.report("Invalid relationship update: " + character_id, true)
		return false
	var relationship: Dictionary = relationships[character_id]
	relationship.relationship_points = mini(1000000, int(relationship.relationship_points) + points)
	relationship.friendship = mini(1000000, int(relationship.friendship) + friendship)
	relationship.affection = mini(1000000, int(relationship.affection) + affection)
	relationship.relationship_level = level_for(character_id, int(relationship.relationship_points))
	changed.emit(character_id)
	return true
