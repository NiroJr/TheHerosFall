extends CharacterBody2D


var speed = 75.0
var player: Node2D
var direction := Vector2.ZERO
const MAX_HEALTH := 100
var health := MAX_HEALTH
@onready var health_bar = $HealthBar

var attacks_received: Array[Area2D] = []

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("Enemy")
	$Sprite2D.play("default")
	health_bar.value = MAX_HEALTH


func _physics_process(_delta):
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return
	
	direction = global_position.direction_to(
		player.global_position
	)
	
	var distance = global_position.distance_to(
		player.global_position
	)
	
	if distance < 200:
		velocity = direction * speed
	else:
		velocity = direction * 0
	
	if(velocity == Vector2.ZERO):
		$Sprite2D.animation = "default"
	else:
		$Sprite2D.animation = "moving"

	move_and_slide()
	
func take_damage(amount: int):
	health = clampi(health - amount, 0, MAX_HEALTH)
	health_bar.value = health
	if(health <= 0):
		queue_free()
	#knockback on attacks
	var tween = create_tween()
	var target_position = position + direction*-20
	tween.tween_property(self, "position", target_position, 0.25)
	


func _on_hit_box_area_entered(area: Area2D) -> void:
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
		
