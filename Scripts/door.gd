extends CharacterBody2D

@export_enum("orange", "purple", "yellow")
var door_color: String = "yellow"

@export var wires : Wires

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

var is_closed: bool =  false

func _ready() -> void:
	sprite.play(door_color)
	sprite.stop()
	sprite.frame = 0
	
	if wires != null:
		wires.power_changed.connect(update_power)

func update_power():
	if wires == null:
		return
	
	var power = wires.kind + 1 if wires.is_on else 0
	var color: int
	
	match door_color:
		"orange":
			color = 1
		"yellow":
			color = 2
		"purple":
			color = 3
	
	if power == color:
		close()
	else:
		open()
	

func close():
	if is_closed:
		return
	
	is_closed = true
	collision.set_deferred("disabled", false)
	sprite.play(door_color)

func open():
	if not is_closed:
		return
	
	is_closed = false
	collision.set_deferred("disabled", true)
	sprite.play_backwards(door_color)
