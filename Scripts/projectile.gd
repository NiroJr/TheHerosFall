extends CharacterBody2D

@export var speed = 500
var enemy_projectile := false
var dir : float
var spawnPos : Vector2
var spawnRot : float

@onready var sprite = $AnimatedSprite2D 

func _ready():
	global_position = spawnPos
	global_rotation = spawnRot + PI
	sprite.play("default");

func _physics_process(delta):
	velocity = Vector2.RIGHT.rotated(dir) * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		dir = velocity.bounce(collision.get_normal()).angle()
		global_rotation = dir + PI
	
		
	

func _on_life_timeout() -> void:
	queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if enemy_projectile:
		if area.is_in_group("PlayerHitBox"):
			area.get_parent().take_damage(1)
			queue_free()
		elif(area.get_parent().is_in_group("Enemy")):
			queue_free()
