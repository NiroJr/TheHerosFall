extends CharacterBody2D


var speed = 75.0
var player: Node2D


func _ready():
	player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta):
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return
	
	var direction = global_position.direction_to(
		player.global_position
	)
	velocity = direction * speed

	move_and_slide()
