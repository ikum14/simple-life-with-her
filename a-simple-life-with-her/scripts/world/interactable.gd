class_name Interactable
extends Area2D

signal interacted(actor: Node2D)
@export var interaction_id := ""
@export var prompt := "Interact"
@export var enabled := true

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 2
	collision_mask = 0
	monitorable = true

func interact(actor: Node2D) -> bool:
	if not enabled or GameManager.is_blocked():
		return false
	interacted.emit(actor)
	return true
