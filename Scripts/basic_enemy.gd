extends ElevationBody



var speed = 75.0
var player: Node2D
var direction := Vector2.ZERO
var knockback := Vector2.ZERO
const MAX_HEALTH := 100
var health := MAX_HEALTH
@onready var health_bar = $HealthBar

var attacks_received: Array[Area2D] = []

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("Enemy")
	$Sprite2D.play("default")
	health_bar.value = MAX_HEALTH
	feet = Vector2(0, 10)
	setup_elevation([$Sprite2D, $HealthBar])




func _physics_process(delta):
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return
 
	var to_player: Vector2 = world_offset_to(player)
	direction = to_player.normalized()
	var distance = to_player.length()
 
	var reachable: bool = player.elevation - elevation <= 1
 
	if distance < 200 and reachable:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
 
	if(velocity == Vector2.ZERO):
		$Sprite2D.animation = "default"
	else:
		$Sprite2D.animation = "moving"
 
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 640 * delta)
 
	move_with_elevation(delta)
	
func take_damage(amount: int):
	health = clampi(health - amount, 0, MAX_HEALTH)
	health_bar.value = health
	if(health <= 0):
		queue_free()
	#knockback on attacks
	knockback = -direction * 240
	


func _on_hit_box_area_entered(area: Area2D) -> void:
	if player.elevation != elevation:
		return
 
	if area.is_in_group("PlayerHitBox"):
		player.take_damage(10)
	
	 # Record this enemy as hit
	player.enemies_hit.append(self)
	
	if area.is_in_group("Combo1"):
		take_damage(10)
	elif area.is_in_group("Combo2"):
		take_damage(20)
	elif area.is_in_group("Combo3"):
		take_damage(50)
	elif area.is_in_group("Parry"):
		take_damage(0)
