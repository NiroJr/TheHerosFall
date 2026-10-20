extends CharacterBody2D

@export var c1_a :float
#@export var c2_a :float
#@export var c3_a :float
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
	$SwordSwing.visible = false

const Animations := [
	"right",
	"downRight",
	"down", 
	"downRight", #downLeft
	"right",  #left
	"upRight", #upLeft
	"up",	
	"upRight"
]

func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var hDirection := Input.get_axis("Left", "Right")
	var vDirection := Input.get_axis("Up", "Down")
	
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
		
		
		#flips sprites when left input is recieved and the direction is given
		if(sprite_index == 3
		or sprite_index == 4
		or sprite_index == 5):
			$PlayerSprite.flip_h = true;
		else:
			$PlayerSprite.flip_h = false;
		
		$PlayerSprite.play(Animations[sprite_index]);
	else: 
		$PlayerSprite.stop()
		$PlayerSprite.frame = 0;
		
	move_and_slide()
	
	if Input.is_action_just_pressed("Shoot"):
		shoot()
	if Input.is_action_just_pressed("sword_swing"):
		if(is_swinging):
			return
		is_swinging = true
		$Combo.stop()
		$SwordSwing.visible = true
		var side := 1 if(cos(facing_angle) >=0) else -1
		match combo_step:
			0:
				$SwordSwing/Combo1.rotation = facing_angle+PI
				$SwordSwing/Combo1/SwordAnimation.rotation += deg_to_rad(c1_a)
				$SwordSwing/Combo1/SwordAnimation.flip_h = (side == 1)
				$SwordSwing/Combo1.visible = true
				$SwordSwing/Combo2.visible = false
				$SwordSwing/Combo3.visible = false
				$SwordSwing/Combo1/SwordAnimation.play("Combo1")
				await $SwordSwing/Combo1/SwordAnimation.animation_finished
				$SwordSwing/Combo1/SwordAnimation.rotation = deg_to_rad(c1_a)
			1:
				$SwordSwing/Combo2.rotation = facing_angle+PI
				if(side == 1):
					$SwordSwing/Combo2/SwordAnimation.flip_v = false
					$SwordSwing/Combo2/SwordAnimation.offset.y = -15 
				$SwordSwing/Combo1.visible = false
				$SwordSwing/Combo2.visible = true
				$SwordSwing/Combo3.visible = false
				$SwordSwing/Combo2/SwordAnimation.play("Combo2")
				await $SwordSwing/Combo2/SwordAnimation.animation_finished
				$SwordSwing/Combo2/SwordAnimation.flip_v = true
				$SwordSwing/Combo2/SwordAnimation.offset.y = 15
			2:
				$SwordSwing/Combo3.rotation = facing_angle+PI
				$SwordSwing/Combo1.visible = false
				$SwordSwing/Combo2.visible = false
				$SwordSwing/Combo3.visible = true
				$SwordSwing/Combo3/SwordAnimation.play("Combo3")
				await $SwordSwing/Combo3/SwordAnimation.animation_finished
		combo_step= (combo_step+1)%3
		$Combo.start()
		$SwordSwing.visible = false
		is_swinging = false;
		
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot()
		
func _on_combo_timeout() -> void:
	combo_step = 0;
		
func shoot():
	var instance = projectile.instantiate()
	var angle = (get_global_mouse_position() - global_position).angle()
	instance.dir = angle             
	instance.spawnPos = global_position
	instance.spawnRot = angle        
	main.add_child.call_deferred(instance)
