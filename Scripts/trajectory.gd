extends Line2D

const BOUNCE_PHYSICS_LAYER := 0
var floor_layers: Array = []
var elevation := 0
var ground_offset := 0.0

func update_trajectory(dir: Vector2, speed: float, delta: float, start_pos: Vector2, current_elevation: int, layers: Array) -> void:
	clear_points()
	elevation = current_elevation
	floor_layers = layers
	var pos := start_pos
	var vel := dir.normalized() * speed
	var max_points := 300
	var max_bounces := 10
	var bounce_count := 0

	for i in range(max_points):
		add_point(to_local(pos))
		var step := vel * delta
		var hit := _find_bounce(pos, step)
		if hit.is_empty():
			pos += step
		else:
			var hit_pos: Vector2 = hit[0]
			var normal: Vector2 = hit[1]
			vel = vel.bounce(normal)
			pos = hit_pos + normal * 0.5
			bounce_count += 1
			if bounce_count >= max_bounces:
				break

func _find_bounce(from: Vector2, step: Vector2) -> Array:
	if step == Vector2.ZERO:
		return []

	var to := from + step
	var best_d := INF
	var best_pos := Vector2.ZERO
	var best_normal := Vector2.ZERO

	for seg in _nearby_segments(from, to):
		var p = Geometry2D.segment_intersects_segment(from, to, seg[0], seg[1])
		if p != null:
			var d := from.distance_squared_to(p)
			if d < best_d:
				best_d = d
				best_pos = p
				var normal: Vector2 = (seg[1] - seg[0]).orthogonal().normalized()
				if normal.dot(step) > 0:
					normal = -normal
				best_normal = normal
	if best_d == INF:
		return []
	return [best_pos, best_normal]

func _nearby_segments(from: Vector2, at: Vector2) -> Array:
	var segs := []
	for line in get_tree().get_nodes_in_group("bounce_lines"):
		if line.elevation != -1 and line.elevation != elevation:
			continue
		var pts: PackedVector2Array = line.points
		var count := pts.size() if line.closed else pts.size() - 1
		for i in count:
			segs.append([line.to_global(pts[i]), line.to_global(pts[(i + 1) % pts.size()])])
	var polys := []

	for h in range(elevation + 1, floor_layers.size()):
		var layer: TileMapLayer = floor_layers[h]
		if layer.tile_set == null:
			continue
		if layer.tile_set.get_physics_layers_count() <= BOUNCE_PHYSICS_LAYER:
			continue
		var drop := Vector2(0, (h - elevation) * 16.0)
		var top := drop - Vector2(0, 16.0)
		var center := layer.local_to_map(layer.to_local(at - drop))

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var cell := center + Vector2i(dx, dy)
				var data := layer.get_cell_tile_data(cell)
				if data == null or not data.get_custom_data("is_floor"):
					continue
				var base := layer.map_to_local(cell)
				for k in data.get_collision_polygons_count(BOUNCE_PHYSICS_LAYER):
					var pts := PackedVector2Array()
					for p in data.get_collision_polygon_points(BOUNCE_PHYSICS_LAYER, k):
						var g := layer.to_global(base + p)
						pts.append(g + top)
						pts.append(g + drop)
					var poly := Geometry2D.convex_hull(pts)
					poly.remove_at(poly.size() - 1)
					polys.append(poly)

	for poly in polys:
		if Geometry2D.is_point_in_polygon(from, poly):
			return segs

	for poly in polys:
		for i in range(poly.size()):
			segs.append([poly[i], poly[(i + 1) % poly.size()]])
	return segs
