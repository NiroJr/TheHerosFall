class_name Wires
extends TileMapLayer

signal power_changed

@export var sources: Array[Node]

var is_on := false
var kind: int = 0 

var _lookup: Dictionary = {}
var _cells: Dictionary = {}

func _ready() -> void:
	_build_lookup()
	for cell in get_used_cells():
		var data := get_cell_tile_data(cell)
		if data != null and data.get_custom_data("wire_shape") != "":
			_cells[cell] = data.get_custom_data("wire_shape")
	for source in sources:
		if source != null and source.has_signal("power_changed"):
			source.power_changed.connect(_on_switch_activation.bind(source))
	_refresh()

func _on_switch_activation(active: Node) -> void:
	if not active.is_on or active.is_receiving:
		_refresh()
		return
	
	var color: int = active.kind
	for source in sources:
		if source == null or source == active:
			continue
		source.set_color(color, true)
	
	_refresh()

func _build_lookup() -> void:
	for i in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(i)
		var atlas := tile_set.get_source(source_id) as TileSetAtlasSource
		if atlas == null:
			continue
		for t in atlas.get_tiles_count():
			var coords := atlas.get_tile_id(t)
			var data := atlas.get_tile_data(coords, 0)
			var shape: String = data.get_custom_data("wire_shape")
			if shape != "":
				_lookup["%s:%d" % [shape, data.get_custom_data("wire_color")]] = [source_id, coords]


func _refresh() -> void:
	is_on = false
	kind = 0
	
	for source in sources:
		if source != null and source.is_on:
			is_on = true
			kind = source.kind
			break
			
	var color := kind + 1 if is_on else 0
	for cell in _cells:
		var key := "%s:%d" % [_cells[cell], color]
		if _lookup.has(key):
			set_cell(cell, _lookup[key][0], _lookup[key][1])
	power_changed.emit()
