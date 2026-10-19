extends CharacterBody2D

@export var speed = 500

var dir : float
var spawnPos : Vector2
var spawnRot : float


func _ready():
	global_position = spawnPos
	global_rotation = spawnRot

func _physics_process(_delta):
	velocity = (Vector2.RIGHT * speed).rotated(dir)
	move_and_slide()
