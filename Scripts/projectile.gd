extends CharacterBody2D

@export var speed = 500
var enemy_projectile := false
var dir : float
var spawnPos : Vector2
var spawnRot : float
var shooter : Node2D
var elevation := 0
var ground_offset := 0.0
var floor_layers: Array = []
@onready var sprite = $AnimatedSprite2D 

func _ready():
	global_position = spawnPos
	if(!enemy_projectile):
		global_rotation = spawnRot + PI
		sprite.play("default");
	else:
		global_rotation = spawnRot - PI/2
		sprite.play("turret");
	if shooter != null and "floor_layers" in shooter:
		floor_layers = shooter.floor_layers
 
func _physics_process(delta):
	velocity = Vector2.RIGHT.rotated(dir) * speed
	_bounce_off_higher_ground(velocity * delta)
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
			collide.take_damage(1)
			queue_free()
		elif(area.is_in_group("Parry")):
			dir = dir + PI
			global_rotation = global_rotation+ PI
			self.enemy_projectile = false
		elif(area.is_in_group("Enemy") && collide != shooter):
			queue_free()
	elif(area.is_in_group("Enemy")):
			collide.take_damage(5)
			queue_free()
			
func _elevation_of(node: Node) -> int:
	while node != null and not ("elevation" in node):
		node = node.get_parent()
	return node.elevation if node != null else elevation

func _bounce_off_higher_ground(step: Vector2) -> void:
	if floor_layers.is_empty() or _is_wall(Vector2.ZERO):
		return
	var v := Vector2.RIGHT.rotated(dir)
	if step.x != 0 and _is_wall(Vector2(step.x, 0)):
		v.x = -v.x
	if step.y != 0 and _is_wall(Vector2(0, step.y)):
		v.y = -v.y
	if v != Vector2.RIGHT.rotated(dir):
		dir = v.angle()
		global_rotation = dir - PI/2 if enemy_projectile else dir + PI
		
func _is_wall(step: Vector2) -> bool:
	var world := global_position + step + Vector2(0, ground_offset + elevation * 16.0)
	for h in range(floor_layers.size() - 1, elevation, -1):
		var layer: TileMapLayer = floor_layers[h]
		var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(world - Vector2(0, h * 16.0))))
		if data != null and data.get_custom_data("is_floor"):
			return true
	return false
