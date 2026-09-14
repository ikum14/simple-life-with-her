extends Control

var finger := -1
var stick_offset := Vector2.ZERO
var safe_left := 0.0
var safe_right := 0.0
var safe_bottom := 0.0
const RADIUS := 58.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.modal_changed.connect(clear)
	get_viewport().size_changed.connect(update_safe_area)
	update_safe_area()

func update_safe_area() -> void:
	if OS.get_name() == "Android":
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var scale_factor := size / Vector2(screen)
		safe_left = safe.position.x * scale_factor.x
		safe_right = (screen.x - safe.end.x) * scale_factor.x
		safe_bottom = (screen.y - safe.end.y) * scale_factor.y
	queue_redraw()

func stick_center() -> Vector2:
	return Vector2(112 + safe_left, size.y - 76 - safe_bottom)

func action_center() -> Vector2:
	return Vector2(size.x - 118 - safe_right, size.y - 78 - safe_bottom)

func menu_rect() -> Rect2:
	return Rect2(size.x - 150 - safe_right, 18, 120, 46)

func clear() -> void:
	finger = -1
	stick_offset = Vector2.ZERO
	GameManager.clear_input()
	queue_redraw()

func handle_press(index: int, point: Vector2, pressed: bool, canceled: bool = false) -> bool:
	if not pressed or canceled:
		if index == finger:
			clear()
			return true
		return false
	if GameManager.is_blocked():
		return false
	if menu_rect().has_point(point):
		GameManager.set_menu(true)
		return true
	if point.distance_to(action_center()) <= RADIUS + 12:
		WorldManager.player.try_interact()
		return true
	if finger == -1 and point.distance_to(stick_center()) <= RADIUS + 24:
		finger = index
		update_stick(point)
		return true
	return false

func handle_drag(index: int, point: Vector2) -> bool:
	if finger != index or GameManager.is_blocked():
		return false
	update_stick(point)
	return true

func update_stick(point: Vector2) -> void:
	stick_offset = (point - stick_center()).limit_length(RADIUS)
	GameManager.touch_vector = stick_offset / RADIUS if stick_offset.length() > 8 else Vector2.ZERO
	queue_redraw()

func _input(event: InputEvent) -> void:
	var handled := false
	if event is InputEventScreenTouch:
		handled = handle_press(event.index, event.position, event.pressed, event.canceled)
	elif event is InputEventScreenDrag:
		handled = handle_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		handled = handle_press(1000, event.position, event.pressed)
	elif event is InputEventMouseMotion and finger == 1000:
		handled = handle_drag(1000, event.position)
	if handled:
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if GameManager.is_blocked():
		return
	var center := stick_center()
	draw_circle(center, RADIUS + 10, Color("263d36"))
	draw_arc(center, RADIUS + 10, 0, TAU, 48, Color("78968b"), 2)
	draw_line(center - Vector2(40, 0), center + Vector2(40, 0), Color("52665d"), 2)
	draw_line(center - Vector2(0, 40), center + Vector2(0, 40), Color("52665d"), 2)
	draw_circle(center + stick_offset, 27, Color("a7beb0"))
	draw_circle(action_center(), RADIUS, Color("78968b"))
	draw_string(ThemeDB.fallback_font, action_center() + Vector2(-40, 6), "INTERACT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("10251f"))
	draw_style_box(menu_style(), menu_rect())
	draw_string(ThemeDB.fallback_font, menu_rect().position + Vector2(28, 29), "MENU", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ede8d8"))
	draw_string(ThemeDB.fallback_font, Vector2(224 + safe_left, size.y - 48 - safe_bottom), "MOVE  ·  WASD / arrows     INTERACT  ·  E", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("a7beb0"))

func menu_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("344a46")
	style.set_corner_radius_all(8)
	return style
