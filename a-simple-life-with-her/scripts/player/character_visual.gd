extends Node2D

@export var shirt_color := Color("648b83")
@export var hair_color := Color("3c3536")
var facing := Vector2.DOWN
var walking := false
var animation_name := "idle_down"
var phase := 0.0

func set_motion(direction: Vector2, moving: bool) -> void:
	facing = direction
	walking = moving
	var suffix := "down"
	if absf(direction.x) > absf(direction.y):
		suffix = "right" if direction.x > 0 else "left"
	elif direction.y < 0:
		suffix = "up"
	animation_name = ("walk_" if moving else "idle_") + suffix
	queue_redraw()

func _process(delta: float) -> void:
	if walking:
		phase += delta * 12.0
		queue_redraw()

func _draw() -> void:
	draw_ellipse_shadow()
	var step := sin(phase) * 3.0 if walking else 0.0
	draw_rect(Rect2(-10, -7 + step, 8, 13), Color("34434a"))
	draw_rect(Rect2(2, -7 - step, 8, 13), Color("34434a"))
	draw_rect(Rect2(-14, -31, 28, 26), shirt_color)
	draw_circle(Vector2(0, -40), 13, Color("e8c7a2"))
	draw_rect(Rect2(-13, -53, 26, 10), hair_color)
	if facing.y >= 0:
		draw_circle(Vector2(-5 + facing.x * 3, -39), 1.5, Color("32383b"))
		draw_circle(Vector2(5 + facing.x * 3, -39), 1.5, Color("32383b"))
	else:
		draw_circle(Vector2(0, -42), 12, hair_color)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 20, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO)
