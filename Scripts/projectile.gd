extends CharacterBody2D

@export var speed = 500
var enemyProjectileSpeed = 300
var enemy_projectile := false
var dir : float
var spawnPos : Vector2
var spawnRot : float
var shooter : Node2D
var elevation := 0
var ground_offset := 0.0
var floor_layers: Array = []
@onready var sprite = $AnimatedSprite2D 
const BOUNCE_PHYSICS_LAYER := 0

#damage values 
var playerProjectileDamage = 20
var enemyProjectileDamage = 10 


@export var debug_bounce := false
var _debug_segs := []



func _draw() -> void:
	if debug_bounce:
		draw_set_transform(Vector2.ZERO, -global_rotation)
		draw_circle(Vector2(0, ground_offset), 2, Color.RED) 
		draw_set_transform_matrix(global_transform.affine_inverse())   # 下面直接用世界坐标画
		for seg in _debug_segs:
			draw_line(seg[0], seg[1], Color.CYAN, 1.0)
		draw_circle(global_position + Vector2(0, ground_offset), 1.5, Color.RED)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		
func _ready():
	global_position = spawnPos
	if(!enemy_projectile):
		global_rotation = spawnRot + PI
		sprite.play("default");
	else:
		global_rotation = spawnRot - PI/2
		sprite.play("turret");
		speed = enemyProjectileSpeed
	if shooter != null and "floor_layers" in shooter:
		floor_layers = shooter.floor_layers
 
func _physics_process(delta):
	queue_redraw()
	velocity = Vector2.RIGHT.rotated(dir) * speed
	_bounce_off_lines(velocity * delta)
	velocity = Vector2.RIGHT.rotated(dir) * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		dir = velocity.bounce(collision.get_normal()).angle()
		if enemy_projectile:
			global_rotation = dir - PI/2
		else:
			global_rotation = dir + PI
	
		
	

func _on_life_timeout() -> void:
	queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	var collide = area.get_parent()
	if _elevation_of(area) != elevation:
		return
	if enemy_projectile:
		if area.is_in_group("PlayerHitBox"):
			collide.take_damage(enemyProjectileDamage)
			queue_free()
		elif(area.is_in_group("Parry")):
			dir = dir + PI
			global_rotation = global_rotation+ PI
			self.enemy_projectile = false
		elif(area.is_in_group("Enemy") && collide != shooter):
			queue_free()
	elif(area.is_in_group("Enemy")):
			collide.take_damage(playerProjectileDamage)
			queue_free()
			
func _elevation_of(node: Node) -> int:
	while node != null and not ("elevation" in node):
		node = node.get_parent()
	return node.elevation if node != null else elevation
	
	
func _bounce_off_lines(step: Vector2) -> bool:
	if step == Vector2.ZERO:
		return false
	var from := global_position + Vector2(0, ground_offset)
	var to := from + step
	if debug_bounce:
		_debug_segs = _nearby_segments(from, to)
		queue_redraw()
	var best_d := INF
	var best_n := Vector2.ZERO
	for seg in _nearby_segments(from, to):
		var p = Geometry2D.segment_intersects_segment(from, to, seg[0], seg[1])
		if p != null:
			var d := from.distance_squared_to(p)
			if d < best_d:
				best_d = d
				best_n = (seg[1] - seg[0]).orthogonal().normalized()
	if best_d == INF:
		return false
	dir = Vector2.RIGHT.rotated(dir).bounce(best_n).angle()
	global_rotation = dir - PI/2 if enemy_projectile else dir + PI
	return true

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
		if layer.tile_set == null or layer.tile_set.get_physics_layers_count() <= BOUNCE_PHYSICS_LAYER:
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
					poly.remove_at(poly.size() - 1)   # convex_hull 返回的最后一个点和第一个点重复
					polys.append(poly)
	for poly in polys:
		if Geometry2D.is_point_in_polygon(from, poly):
			return segs
	for poly in polys:
		for i in poly.size():
			segs.append([poly[i], poly[(i + 1) % poly.size()]])
	return segs
