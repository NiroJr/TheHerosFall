class_name Wires
extends TileMapLayer

signal power_changed

@export var source: Node 

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
	if source != null and source.has_signal("power_changed"):
		source.power_changed.connect(_refresh)
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
	if source != null:
		is_on = source.is_on
		kind = source.kind
	var color := kind + 1 if is_on else 0
	for cell in _cells:
		var key := "%s:%d" % [_cells[cell], color]
		if _lookup.has(key):
			set_cell(cell, _lookup[key][0], _lookup[key][1])
	power_changed.emit()
