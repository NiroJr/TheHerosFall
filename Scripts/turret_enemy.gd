extends CharacterBody2D
@onready var projectile = load("res://Scenes/projectile.tscn")
@onready var main = get_tree().current_scene
var player : Area2D = null 
var line_of_sight := false
var can_shoot := true

func _ready() -> void:
	$PlayerDetection.area_entered.connect(detected)
	$PlayerDetection.area_exited.connect(_outOfRange)
	$PlayerDetection/RayCast2D.add_exception(self)

func _physics_process(delta: float) -> void:
	if(player):
		check_sight_line()
	else:
		line_of_sight = false

func detected(body: Area2D) -> void:
	if(body.is_in_group("PlayerHitBox")):
		player = body

func _outOfRange(body: Area2D) -> void:
	if(body == player):
		player = null
		line_of_sight = false

func check_sight_line() -> void:
	$PlayerDetection/RayCast2D.target_position = $PlayerDetection/RayCast2D.to_local(player.global_position)
	$PlayerDetection/RayCast2D.force_raycast_update()
	if($PlayerDetection/RayCast2D.is_colliding() && $PlayerDetection/RayCast2D.get_collider() == player):
		line_of_sight = true
		if(can_shoot):
			shoot()
	else:
		line_of_sight = false

func shoot() -> void:
	can_shoot = false
	var instance = projectile.instantiate()
	var angle = (player.global_position - global_position).angle()
	instance.dir = angle        
	instance.spawnPos = global_position
	instance.spawnRot = angle
	instance.enemy_projectile = true
	instance.speed = 200
	instance.modulate = Color(1.0,0.3,0.3)
	instance.set_collision_mask_value(3, false)
	main.add_child.call_deferred(instance)
	$Fire.start()
	return


func _on_fire_timeout() -> void:
	can_shoot = true
