extends CharacterBody2D

signal target_changed(prompt: String)
var facing := Vector2.DOWN
var target: Interactable
var scan_elapsed := 0.0
var inventory: Node:
	get: return InventoryManager
var relationship: Node:
	get: return RelationshipManager
@onready var visual: Node2D = $Visual
@onready var detector: Area2D = $InteractionDetector

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if not GameManager.is_blocked():
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down") + GameManager.touch_vector
		direction = direction.limit_length()
	if direction.length_squared() > 0.01:
		facing = Vector2(signf(direction.x), 0) if absf(direction.x) > absf(direction.y) else Vector2(0, signf(direction.y))
	velocity = direction * float(GameManager.stats.get("speed", 190))
	move_and_slide()
	visual.set_motion(facing, velocity.length_squared() > 1)
	scan_elapsed += delta
	if scan_elapsed >= 0.08:
		scan_elapsed = 0
		refresh_target()

func reachable(candidate: Interactable) -> bool:
	if not candidate.enabled or global_position.distance_to(candidate.global_position) > 100:
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position, candidate.global_position, 1, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or hit.collider.is_ancestor_of(candidate)

func refresh_target() -> void:
	var best: Interactable = null
	var best_score := INF
	if not GameManager.is_blocked():
		for area in detector.get_overlapping_areas():
			if area is Interactable and reachable(area):
				var offset: Vector2 = area.global_position - global_position
				var score: float = offset.length() - facing.dot(offset.normalized()) * 15
				if score < best_score:
					best = area
					best_score = score
	if target != best or not is_instance_valid(target):
		target = best
		target_changed.emit(target.prompt if is_instance_valid(target) else "Walk closer to a person or object")

func try_interact() -> bool:
	if GameManager.is_blocked():
		return false
	refresh_target()
	if is_instance_valid(target) and reachable(target):
		return target.interact(self)
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		try_interact()
		get_viewport().set_input_as_handled()
