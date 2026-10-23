extends CharacterBody2D

@export var speed = 500
var enemy_projectile := false
var dir : float
var spawnPos : Vector2
var spawnRot : float
var shooter : Node2D

@onready var sprite = $AnimatedSprite2D 

func _ready():
	global_position = spawnPos
	if(!enemy_projectile):
		global_rotation = spawnRot + PI
		sprite.play("default");
	else:
		global_rotation = spawnRot - PI/2
		sprite.play("turret");

func _physics_process(delta):
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
	if enemy_projectile:
		if area.is_in_group("PlayerHitBox"):
			collide.take_damage(1)
			queue_free()
		elif(area.is_in_group("Enemy") && collide != shooter):
			queue_free()
	elif(area.is_in_group("Enemy")):
			collide.take_damage(5)
			queue_free()
		
