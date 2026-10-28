class_name ElevationBody
extends CharacterBody2D
## allow charactors to move with elevation, step up, fall down
## to use extends ElevationBody，then in _ready() do setup_elevation()，
## in _physics_process() calcute velocity then use move_with_elevation(delta)。

const TILE := 16.0
const STEP_UP_SPEED := 160.0
const STEP_UP_PUSH := 8.0
const GRAVITY := 800.0
const FALL_LIMIT := -160.0

var feet := Vector2(0, 14) #feet to the characters middle point
var foot_size := Vector2(6, 3) 
var can_fall_into_void := false # true = can fall into void

enum { WALK, STEP_UP, FALL }
var state := WALK
var elevation := 0
var z_height := 0.0
var z_velocity := 0.0
var push_left := Vector2.ZERO
var floor_layers: Array[TileMapLayer] = []
var spawn_position := Vector2.ZERO
var spawn_elevation := 0
var lift_nodes: Array = []
var lift_base_y: Array = []


func setup_elevation(lift: Array = []) -> void:
	lift_nodes = lift
	lift_base_y.clear()
	for node in lift_nodes:
		lift_base_y.append(node.position.y)
	_find_floor_layers()
	if not floor_layers.is_empty():
		elevation = _start_elevation()
	spawn_position = global_position
	spawn_elevation = elevation



func _find_floor_layers() -> void:
	floor_layers.clear()
	var floors := get_tree().current_scene.get_node_or_null("Floors")
	if floors == null:
		return
	for child in floors.get_children():
		if child is TileMapLayer and child.tile_set != null \
				and child.tile_set.get_custom_data_layer_by_name("is_floor") != -1:
			floor_layers.append(child)


func move_with_elevation(delta: float) -> void:
	if floor_layers.is_empty():
		move_and_slide()
		return
	match state:
		WALK:
			var step := velocity * delta
			if not _can_move(Vector2(step.x, 0)):
				velocity.x = 0
			if not _can_move(Vector2(0, step.y)):
				velocity.y = 0
			move_and_slide()
			_check_level_change()
		STEP_UP:
			z_height = move_toward(z_height, 0.0, STEP_UP_SPEED * delta)
			if push_left != Vector2.ZERO:
				var move := push_left.limit_length(STEP_UP_SPEED * STEP_UP_PUSH / TILE * delta)
				if _ground_level(_feet_world() + move + move.sign() * foot_size) == elevation:
					move_and_collide(move)
					push_left -= move
				else:
					push_left = Vector2.ZERO
			if z_height == 0.0 and push_left == Vector2.ZERO:
				state = WALK
		FALL:
			z_velocity -= GRAVITY * delta
			z_height += z_velocity * delta
			if _ground_level(_feet_world()) >= 0:
				if z_height <= 0.0:
					_land()
			elif z_height < FALL_LIMIT:
				_fell_into_void()
	_update_visuals()


func _feet_world() -> Vector2:
	return global_position + feet + Vector2(0, elevation * TILE)


func _is_floor(h: int, point: Vector2) -> bool:
	var layer := floor_layers[h]
	var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(point)))
	return data != null and data.get_custom_data("is_floor")


# 世界坐标 world 这里的地面有几层高；-1 表示虚空
func _ground_level(world: Vector2) -> int:
	for h in range(floor_layers.size() - 1, -1, -1):
		if _is_floor(h, world - Vector2(0, h * TILE)):
			return h
	return -1


func _start_elevation() -> int:
	for h in range(floor_layers.size() - 1, -1, -1):
		if _is_floor(h, global_position + feet):
			return h
	return 0


func _can_move(step: Vector2) -> bool:
	if step == Vector2.ZERO:
		return true
	var probe := _feet_world() + step + step.sign() * foot_size
	var ground := _ground_level(probe)
	if ground < 0:
		return can_fall_into_void
	return ground <= elevation + 1


func _check_level_change() -> void:
	var ground := _ground_level(_feet_world())
	if ground == elevation:
		return
	if ground < 0:
		state = FALL
		z_velocity = 0.0
		return
	var shift := (ground - elevation) * TILE
	global_position.y -= shift
	z_height = -shift
	elevation = ground
	z_velocity = 0.0
	if shift > 0:
		state = STEP_UP
		push_left = velocity.normalized() * STEP_UP_PUSH
	else:
		state = FALL
	_level_changed(shift)


func _land() -> void:
	z_height = 0.0
	z_velocity = 0.0
	state = WALK


func _update_visuals() -> void:
	for i in lift_nodes.size():
		lift_nodes[i].position.y = lift_base_y[i] - z_height


func world_offset_to(other: ElevationBody) -> Vector2:
	return other._feet_world() - _feet_world()


func _level_changed(_shift: float) -> void:
	pass


func _fell_into_void() -> void:
	global_position = spawn_position
	elevation = spawn_elevation
	_land()
