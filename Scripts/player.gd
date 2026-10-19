extends CharacterBody2D

@onready var main = get_tree().get_root().get_node("Main")
@onready var projectile = load("res://Scenes/projectile.tscn")
var facing_angle := 0.0
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var sprite_dir  := 0.0;
var slice  := TAU/8;
var sprite_index := 0;
var combo_step := 0;
var is_swinging := false;
var swing_spread := deg_to_rad(20)

func _ready() -> void:
	$SwordPivot.visible = false

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
	if Input.is_action_just_pressed("sword_swing"):
		if(is_swinging):
			return
		is_swinging = true
		$Combo.stop()
		$SwordPivot.visible = true
		var side := 1 if(cos(facing_angle) >=0) else -1
		match combo_step:
			0:
				$SwordPivot.rotation = facing_angle-side*swing_spread
				var swing_tween = create_tween()
				swing_tween.tween_property($SwordPivot, "rotation", facing_angle+side*swing_spread, 0.15)
				await swing_tween.finished
			1:
				$SwordPivot.rotation = facing_angle+side*swing_spread
				var swing_tween = create_tween()
				swing_tween.tween_property($SwordPivot, "rotation", facing_angle-side*swing_spread, 0.15)
				await swing_tween.finished
			2:
				$SwordPivot.rotation = facing_angle
				var swing_tween = create_tween()
				swing_tween.tween_property($SwordPivot, "rotation", facing_angle+TAU, 0.15)
				await swing_tween.finished
		combo_step= (combo_step+1)%3
		$Combo.start()
		await get_tree().create_timer(0.2).timeout
		$SwordPivot.visible = false
		is_swinging = false;
		
		
func _on_combo_timeout() -> void:
	combo_step = 0;
	is_swinging = false;
		
func shoot():
	var instance = projectile.instantiate()
	instance.scale.x = -1
	instance.scale.y = -1
	instance.dir = facing_angle
	instance.spawnPos = global_position
	instance.spawnRot = facing_angle
	main.add_child.call_deferred(instance)
	print("spawned at ", global_position, " parent: ", get_tree().current_scene.name)
