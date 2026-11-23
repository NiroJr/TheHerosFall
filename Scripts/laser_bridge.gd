class_name LaserBridge extends TileMapLayer

signal power_changed

@export var level := 0
@export var source: Node
@export var need_kind := 0 # -1 = any;0 orange / 1 yellow / 2 purple

var is_on := false
var kind := -1
var _lookup := {}
var _cells := {}
var _color := 0


func _ready() -> void:
	add_to_group("laser_bridges")
	_build_lookup()
	for cell in get_used_cells():
		var data := get_cell_tile_data(cell)
		if data == null:
			continue
		_cells[cell] = data.get_custom_data("bridge_shape")
		if _color == 0:
			_color = data.get_custom_data("bridge_color")
	if _color == 0:
		_color = 1
	if need_kind != -1:
		_color = need_kind + 1
	if source:
		source.power_changed.connect(_refresh)
	_refresh()


func _build_lookup() -> void:
	_lookup.clear()
	if tile_set == null or tile_set.get_custom_data_layer_by_name("bridge_shape") == -1:
		return
	for i in tile_set.get_source_count():
		var sid := tile_set.get_source_id(i)
		var src := tile_set.get_source(sid) as TileSetAtlasSource
		if src == null:
			continue
		for t in src.get_tiles_count():
			var coords := src.get_tile_id(t)
			var data := src.get_tile_data(coords, 0)
			var shape: String = data.get_custom_data("bridge_shape")
			if shape != "":
				var key := _key(shape, data.get_custom_data("bridge_color"), data.get_custom_data("bridge_lit"))
				_lookup[key] = [sid, coords]


func _key(shape: String, color: int, lit: bool) -> String:
	return "%s:%d:%s" % [shape, color, lit]


func _refresh() -> void:
	is_on = source != null and source.is_on and (need_kind == -1 or source.kind == need_kind)
	kind = source.kind if source else -1
	if need_kind != -1:
		_color = need_kind + 1
	elif source != null and source.is_on:
		_color = source.kind + 1 #switch kind 0/1/2, color 1/2/3
	_redraw()
	power_changed.emit()


func _redraw() -> void:
	for cell in _cells:
		var key := _key(_cells[cell], _color, is_on)
		if _lookup.has(key):
			var tile = _lookup[key]
			set_cell(cell, tile[0], tile[1])
		else:
			erase_cell(cell)


func has_floor(point: Vector2) -> bool:
	return is_on and _cells.has(local_to_map(to_local(point)))
