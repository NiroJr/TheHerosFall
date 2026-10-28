extends TileMapLayer
@export_range(0.0,1.0) var fade_alpha := 0.3
@export var sprite_rect := Rect2(-16, -32, 32, 60)
var player: Node2D
var level := 0
var cell_groups: Dictionary = {}
var faded_groups: Dictionary = {}
var refresh_groups: Dictionary = {}


func _ready() -> void:
	var parent := get_parent()
	if parent == null or parent.name != "Floors" or get_index() == 0:
		set_process(false)
		return
	level = get_index()
	player = get_tree().get_first_node_in_group("player")
	build_groups()

func build_groups() -> void:
	cell_groups.clear()
	faded_groups.clear()
	var group_id := 0
	for start in get_used_cells():
		if cell_groups.has(start):
			continue
		var pending: Array[Vector2i] = [start]
		cell_groups[start] = group_id
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			for neighbor in get_surrounding_cells(cell):
				if get_cell_source_id(neighbor) != -1 and not cell_groups.has(neighbor):
					cell_groups[neighbor] = group_id
					pending.append(neighbor)
		group_id += 1

func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	var new_faded: Dictionary = {}
	if level > player.get("elevation"):
		var area := Rect2(player.global_position + sprite_rect.position, sprite_rect.size)
		var c0 := local_to_map(to_local(area.position))
		var c1 := local_to_map(to_local(area.end))
		for y in range(c0.y, c1.y + 1):
			for x in range(c0.x, c1.x + 1):
				var cell := Vector2i(x, y)
				if cell_groups.has(cell) and _drawn_over_player(cell):
					new_faded[cell_groups[cell]] = true
	if new_faded != faded_groups:
		refresh_groups = faded_groups.duplicate()
		refresh_groups.merge(new_faded)
		faded_groups = new_faded
		notify_runtime_tile_data_update()

func _drawn_over_player(cell: Vector2i) -> bool:
	var data := get_cell_tile_data(cell)
	var sort_y := to_global(map_to_local(cell)).y + y_sort_origin + data.y_sort_origin
	return sort_y > player.global_position.y

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return cell_groups.has(coords) and refresh_groups.has(cell_groups[coords])


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if faded_groups.has(cell_groups[coords]):
		tile_data.modulate.a *= fade_alpha
