extends Control

var status_label: Label
var prompt_label: Label
var toast: Label
var toast_timer: Timer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label = make_label(Vector2(40, 18), 22)
	prompt_label = make_label(Vector2(250, 581), 20)
	prompt_label.text = "Walk closer to Mira to talk"
	toast = make_label(Vector2(250, 615), 19)
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 6
	add_child(toast_timer)
	toast_timer.timeout.connect(func(): toast.text = "")
	TimeManager.changed.connect(refresh)
	GameManager.state_changed.connect(refresh)
	RelationshipManager.changed.connect(func(_id): refresh())
	GameManager.message_posted.connect(show_message)
	GameManager.modal_changed.connect(func(): prompt_label.visible = not GameManager.is_blocked())
	refresh()

func make_label(point: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = point
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ede8d8"))
	add_child(label)
	return label

func bind_player(player: Node) -> void:
	player.target_changed.connect(func(text): prompt_label.text = text)

func refresh() -> void:
	if not GameManager.initialized:
		return
	var relationship: Dictionary = RelationshipManager.relationships.mira
	status_label.text = "DAY %d  /  %s     ·     HOME\nREN  HP %d   ENERGY %d     ·     MIRA  Lv.%d  /  %d points" % [TimeManager.day, TimeManager.get_current_period().to_upper(), GameManager.stats.health, GameManager.stats.energy, relationship.relationship_level, relationship.relationship_points]

func show_message(text: String, is_error: bool) -> void:
	toast.text = text
	toast.add_theme_color_override("font_color", Color("ffb9a9") if is_error else Color("c5d8b2"))
	toast_timer.start()
