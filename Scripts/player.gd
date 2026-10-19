extends CharacterBody2D

@onready var main = get_tree().get_root().get_node("Main")
@onready var projectile = load("res://Scenes/projectile.tscn")
var facing_angle := 0.0
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var sprite_dir  := 0.0;
var slice  := TAU/8;
var sprite_index := 0;

func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var hDirection := Input.get_axis("ui_left", "ui_right")
	var vDirection := Input.get_axis("ui_up", "ui_down")
	
	if hDirection:
		velocity.x = hDirection * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if vDirection:
		velocity.y = vDirection * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	#Rotates the player body and facing direction for projectile during movement
	if(velocity != Vector2.ZERO):
		facing_angle = velocity.angle()
		sprite_dir = fposmod(facing_angle, TAU)
		
		sprite_index = roundi(sprite_dir/slice)%8
		
		if(sprite_index == 3
		or sprite_index == 4
		or sprite_index == 5):
			$PlayerSprite.flip_h = true;
		else:
			$PlayerSprite.flip_h = false;
			
		$PlayerSprite.frame = sprite_index
		

	move_and_slide()
	
	if Input.is_action_just_pressed("ui_accept"):
		print("shoot called")
		shoot()
	
func shoot():
	var instance = projectile.instantiate()
	instance.scale.x = -1
	instance.scale.y = -1
	instance.dir = facing_angle
	instance.spawnPos = global_position
	instance.spawnRot = facing_angle
	main.add_child.call_deferred(instance)
	print("spawned at ", global_position, " parent: ", get_tree().current_scene.name)
