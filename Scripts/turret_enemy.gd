extends ElevationBody
@onready var projectile = load("res://Scenes/projectile.tscn")
@onready var main = get_tree().current_scene
@onready var health_bar = $HealthBar
var player : Area2D = null
var facing_angle = 0.0
var sprite_dir = 0
var sprite_index = 0
var slice = TAU/8
var line_of_sight := false
var can_shoot := true
const MAX_HEALTH := 100
var health := MAX_HEALTH

const Animations := [
	"right",
	"down_right",
	"down", 
	"down_right", #downLeft
	"right",  #left
	"up_right", #upLeft
	"up",	
	"up_right"
]

func _ready() -> void:
	$PlayerDetection.area_entered.connect(detected)
	$PlayerDetection.area_exited.connect(_outOfRange)
	$PlayerDetection/RayCast2D.add_exception(self)
	health_bar.value = MAX_HEALTH
	feet = Vector2(0, 5)
	setup_elevation()

func _physics_process(_delta: float) -> void:		
	if(player):
		check_sight_line()
		if(sprite_index == 3
		or sprite_index == 4
		or sprite_index == 5):
			$AnimatedSprite2D.flip_h = true;
		else:
			$AnimatedSprite2D.flip_h = false;
		
		$AnimatedSprite2D.play(Animations[sprite_index]);
	else:
		line_of_sight = false
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 0;
func detected(body: Area2D) -> void:
	if(body.is_in_group("PlayerHitBox")):
		player = body

func _outOfRange(body: Area2D) -> void:
	var to_player: Vector2 = world_offset_to(body.get_parent())
	if(body == player && to_player.length() > 6*13.04):
		player = null
		line_of_sight = false

func check_sight_line() -> void:
	if player.get_parent().elevation != elevation:
		line_of_sight = false
		return
	$PlayerDetection/RayCast2D.target_position = $PlayerDetection/RayCast2D.to_local(player.global_position)
	$PlayerDetection/RayCast2D.force_raycast_update()
	if($PlayerDetection/RayCast2D.is_colliding() && $PlayerDetection/RayCast2D.get_collider() == player):
		line_of_sight = true
		facing_angle = (player.global_position - global_position).angle()
		sprite_dir = fposmod(facing_angle, TAU)
		sprite_index = roundi(sprite_dir/slice)%8
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
	instance.shooter = self
	instance.speed = 200
	instance.elevation = elevation
	instance.set_collision_mask_value(3, false)
	main.add_child.call_deferred(instance)
	$Fire.start()
	return

func _on_fire_timeout() -> void:
	can_shoot = true

func take_damage(amount: int):
	health = clampi(health - amount, 0, MAX_HEALTH)
	health_bar.value = health
	if(health <= 0):
		queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	if get_tree().get_first_node_in_group("player").elevation != elevation:
		return
	if(player == null):
		return
	player.get_parent().enemies_hit.append(self)
	if area.is_in_group("Combo1"):
		take_damage(10)
	elif area.is_in_group("Combo2"):
		take_damage(20)
	elif area.is_in_group("Combo3"):
		take_damage(50)
