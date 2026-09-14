extends Node2D

const ObjectScript = preload("res://scripts/world/home_object.gd")
const MIRA_SCENE = preload("res://scenes/characters/mira.tscn")
var walk_bounds := Rect2(54, 106, 1172, 452)
var furnishings := [
	{"rect": Rect2(85, 145, 180, 98), "color": Color("9caaa3"), "label": "BED"},
	{"rect": Rect2(440, 132, 135, 65), "color": Color("947b63"), "label": "DRESSER"},
	{"rect": Rect2(720, 142, 460, 66), "color": Color("947b63"), "label": "KITCHEN COUNTER"},
	{"rect": Rect2(115, 395, 165, 75), "color": Color("78968b"), "label": "SOFA"},
	{"rect": Rect2(440, 409, 165, 66), "color": Color("947b63"), "label": "TABLE"}
]
var walls := [Rect2(40, 90, 1200, 16), Rect2(40, 90, 14, 482), Rect2(1226, 90, 14, 482), Rect2(40, 558, 1200, 14), Rect2(632, 106, 16, 236), Rect2(54, 326, 230, 16), Rect2(384, 326, 550, 16), Rect2(1034, 326, 192, 16)]

func _ready() -> void:
	for rect in walls:
		add_solid(rect)
	for furnishing in furnishings:
		add_solid(furnishing.rect)
	add_label("BEDROOM", Vector2(82, 280), Color("5f665d"))
	add_label("KITCHEN", Vector2(1080, 280), Color("5f665d"))
	add_label("LIVING ROOM", Vector2(84, 516), Color("5f665d"))
	add_label("ENTRANCE", Vector2(1070, 516), Color("5f665d"))
	add_object("bed", "Rest until morning", Vector2(180, 264), "bed")
	add_object("table", "Look at the table", Vector2(520, 496), "table")
	add_object("kitchen", "Inspect the kitchen", Vector2(795, 232), "kitchen")
	add_object("door", "Check the front door", Vector2(1120, 546), "door")
	add_object("bread", "Collect bread", Vector2(997, 235), "", "bread", "pickup_bread")
	add_object("apple", "Collect apple", Vector2(1140, 235), "", "apple", "pickup_apple")
	var mira := MIRA_SCENE.instantiate()
	mira.position = Vector2(790, 435)
	add_child(mira)
	add_label("MIRA", Vector2(766, 372), Color("344a46"))

func add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func add_label(text: String, point: Vector2, color: Color, parent_node: Node = self) -> void:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	parent_node.add_child(label)

func add_object(id: String, prompt_text: String, point: Vector2, dialogue: String, item: String = "", flag: String = "") -> void:
	var object = ObjectScript.new()
	object.name = id.capitalize()
	object.interaction_id = id
	object.prompt = prompt_text
	object.position = point
	object.dialogue_id = dialogue
	object.item_id = item
	object.pickup_flag = flag
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	object.add_child(collision)
	if not item.is_empty():
		var icon := Polygon2D.new()
		icon.polygon = PackedVector2Array([Vector2(-14, -12), Vector2(14, -12), Vector2(14, 6), Vector2(-14, 6)])
		icon.color = Color("eed0a0") if item == "bread" else Color("ab6860")
		object.add_child(icon)
		add_label(item.capitalize(), Vector2(-24, 10), Color("344a46"), object)
	else:
		add_label("•", Vector2(-4, -12), Color("344a46"), object)
	add_child(object)

func _draw() -> void:
	draw_rect(Rect2(40, 90, 1200, 482), Color("dbd4bd"))
	draw_rect(Rect2(648, 106, 578, 220), Color("c4cbb9"))
	for x in range(60, 1230, 48):
		draw_line(Vector2(x, 342), Vector2(x, 558), Color(0.4, 0.35, 0.25, 0.12))
	for wall in walls:
		draw_rect(wall, Color("52665d"))
	for furnishing in furnishings:
		draw_rect(furnishing.rect, furnishing.color)
		draw_rect(furnishing.rect, Color("736f5e"), false, 2)
		draw_string(ThemeDB.fallback_font, furnishing.rect.position + Vector2(12, 30), furnishing.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("263d36"))
	draw_rect(Rect2(88, 151, 174, 27), Color("ede8d8"))
	draw_rect(Rect2(1074, 550, 104, 8), Color("947b63"))
