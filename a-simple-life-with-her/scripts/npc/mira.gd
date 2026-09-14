extends CharacterBody2D

signal schedule_requested(day: int, period: String)
signal relationship_event_requested(event_id: String)
@export var character_id := "mira"

func _ready() -> void:
	$Interaction.interacted.connect(_on_interacted)
	TimeManager.changed.connect(_on_time_changed)
	$Visual.set_motion(Vector2.DOWN, false)

func _on_interacted(actor: Node2D) -> void:
	var offset := actor.global_position - global_position
	$Visual.set_motion(offset.normalized(), false)
	var definition: Dictionary = GameManager.content.characters[character_id]
	for rule in definition.dialogue_rules:
		if GameManager.condition_met(rule.condition):
			DialogueManager.start_dialogue(rule.dialogue_id)
			return
	GameManager.report("No matching dialogue for character: " + character_id, true)

func _on_time_changed() -> void:
	schedule_requested.emit(TimeManager.day, TimeManager.get_current_period())

func request_relationship_event(event_id: String) -> void:
	for event in GameManager.content.characters[character_id].events:
		if event.get("id") == event_id:
			relationship_event_requested.emit(event_id)
			return
	GameManager.report("Missing relationship event: " + event_id, true)
