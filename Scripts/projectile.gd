extends CharacterBody2D

@export var speed = 500

var dir : float
var spawnPos : Vector2
var spawnRot : float

@onready var sprite = $AnimatedSprite2D 

func _ready():
	global_position = spawnPos
	global_rotation = spawnRot
	sprite.play("default");
	$Life.start()

func _physics_process(delta):
	velocity = Vector2.RIGHT.rotated(dir) * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		dir = velocity.bounce(collision.get_normal()).angle()
		global_rotation = dir

func _on_life_timeout() -> void:
	queue_free()
	$Life.stop()
