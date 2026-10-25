extends TileMapLayer

var player : Node2D
@export_range(0.0,1.0) 
var fade_alpha := 0.3
@export_range(0, 8) 
var detection_depth := 0

var cell_groups: Dictionary = {}
var groups: Array = []
var faded_groups: Dictionary = {}


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	build_groups()


# Find all connected walls and pillars.
func build_groups() -> void:
	cell_groups.clear()
	groups.clear()
	faded_groups.clear()

	var occupied: Dictionary = {}

	for cell in get_used_cells():
		occupied[cell] = true

	for start in occupied:
		if cell_groups.has(start):
			continue

		var group_id := groups.size()
		var group: Array[Vector2i] = []
		var pending: Array[Vector2i] = [start]

		cell_groups[start] = group_id

		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			group.append(cell)

			for neighbor in get_surrounding_cells(cell):
				if occupied.has(neighbor) and not cell_groups.has(neighbor):
					cell_groups[neighbor] = group_id
					pending.append(neighbor)

		groups.append(group)


func _process(_delta: float) -> void:
	
	var player_cell: Vector2i = local_to_map(
		to_local(player.global_position)
	)
	
	var new_faded: Dictionary = {}
	
	for y in range(-detection_depth, 2):
		for x in range(-1, 2):
			var cell: Vector2i = player_cell + Vector2i(x, y)
			
			if cell_groups.has(cell):
				var group_id: int = cell_groups[cell]
				new_faded[group_id] = true
				
	if new_faded != faded_groups:
		faded_groups = new_faded
		notify_runtime_tile_data_update()
	
		


func _use_tile_data_runtime_update(
	coords: Vector2i
) -> bool:
	return cell_groups.has(coords)


func _tile_data_runtime_update(
	coords: Vector2i,
	tile_data: TileData
) -> void:
	var group_id: int = cell_groups[coords]

	if faded_groups.has(group_id):
		tile_data.modulate.a *= fade_alpha
