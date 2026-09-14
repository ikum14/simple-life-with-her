extends Interactable

@export var dialogue_id := ""
@export var item_id := ""
@export var quantity := 1
@export var pickup_flag := ""

func _ready() -> void:
	super._ready()
	interacted.connect(_on_interacted)
	GameManager.state_changed.connect(reconcile)
	reconcile()

func reconcile() -> void:
	enabled = pickup_flag.is_empty() or not GameManager.flags.get(pickup_flag, false)
	visible = enabled

func _on_interacted(_actor: Node2D) -> void:
	if not item_id.is_empty():
		if not InventoryManager.can_add(item_id, quantity):
			GameManager.report("Your bag cannot hold this item.", true)
			return
		if InventoryManager.add_item(item_id, quantity):
			GameManager.set_flag(pickup_flag, true)
			GameManager.report("Collected %s × %d" % [GameManager.content.items[item_id].name, quantity])
	elif not dialogue_id.is_empty():
		DialogueManager.start_dialogue(dialogue_id)
	else:
		GameManager.report("Object has no interaction configured: " + interaction_id, true)
