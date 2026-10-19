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

func _physics_process(_delta):
	velocity = (Vector2.RIGHT * speed).rotated(dir)
	move_and_slide()
