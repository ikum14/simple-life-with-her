extends Node

signal map_changed(map_id: String)
const MAPS := {"home": "res://scenes/maps/home.tscn"}
var current_map := "home"
var map_root: Node2D
var container: Node2D
var player: CharacterBody2D

func setup(world_container: Node2D, ren: CharacterBody2D) -> bool:
	container = world_container
	player = ren
	return change_map("home")

func change_map(map_id: String, spawn_name: String = "entrance") -> bool:
	if not MAPS.has(map_id) or not is_instance_valid(container):
		GameManager.report("Unknown map or missing world container: " + map_id, true)
		return false
	var packed := load(MAPS[map_id]) as PackedScene
	if packed == null:
		GameManager.report("Could not load map scene: " + map_id, true)
		return false
	var candidate := packed.instantiate() as Node2D
	if candidate == null:
		GameManager.report("Map root must be Node2D: " + map_id, true)
		return false
	if is_instance_valid(map_root):
		container.remove_child(map_root)
		map_root.free()
	map_root = candidate
	current_map = map_id
	container.add_child(map_root)
	if not map_root.has_node("Spawns/" + spawn_name):
		GameManager.report("Missing map spawn: " + spawn_name, true)
		return false
	player.global_position = map_root.get_node("Spawns/" + spawn_name).global_position
	player.velocity = Vector2.ZERO
	map_changed.emit(map_id)
	return true

func position_is_safe(point: Vector2) -> bool:
	if not is_instance_valid(player) or not is_instance_valid(map_root):
		return false
	if not map_root.walk_bounds.has_point(point):
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player.get_node("CollisionShape2D").shape
	query.transform = Transform2D(0, point)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func capture_player() -> Dictionary:
	return {"position": [player.global_position.x, player.global_position.y], "facing": [player.facing.x, player.facing.y], "stats": GameManager.stats.duplicate(true)}
