extends Sprite2D

var last_mouse_position: Vector2
var idle_time := 0.0
var idle_threshold := 2.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	top_level = true
	z_index = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	last_mouse_position = get_global_mouse_position()

func _process(delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	var mouse_moving = mouse_position != last_mouse_position
	var mouse_clicked = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if mouse_moving or mouse_clicked:
		idle_time = 0.0
		visible = true
	else:
		idle_time += delta

	if idle_time >= idle_threshold:
		visible = false

	global_position = lerp(global_position, mouse_position, 16.5 * delta)
	last_mouse_position = mouse_position
