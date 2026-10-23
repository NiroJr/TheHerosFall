extends CharacterBody2D

@export var c1_a :float
@export var c2_a :float
#@export var c3_a :float
@onready var main = get_tree().current_scene
@onready var projectile = load("res://Scenes/projectile.tscn")
var facing_angle := 0.0
const SPEED = 300.0
var sprite_dir  := 0.0;
var slice  := TAU/8;
var sprite_index := 0;
var combo_step := 0;
var is_swinging := false;
var buffered_swing := false;

var health := 100
@onready var health_bar : ProgressBar = $HUD/HealthBar

var enemies_hit: Array[Node] = []
const TILE := 16.0
const JUMP_SPEED := 180.0
const GRAVITY := 800.0
const FEET := Vector2(0, 28) #feet relative to player
const FOOT_SIZE := Vector2(6, 3) #feet radius
const FALL_LIMIT := -160.0 #void detection

var elevation := 0
var z_height := 0.0
var z_velocity := 0.0
var in_air := false
var floors: Node = null
var spawn_position := Vector2.ZERO
var spawn_elevation := 0
@onready var sprite_base_y: float = $PlayerSprite.position.y
@onready var swing_base_y: float = $SwordSwing.position.y

func _ready() -> void:
	$SwordSwing.visible = false
	add_to_group("player")
	health_bar.value = health
	$SwordSwing/Combo1/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Combo2/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Combo3/CollisionShape2D.set_deferred("disabled", true)
	floors = get_tree().current_scene.get_node_or_null("Floors")
	if floors:
		elevation = _start_elevation()
		_update_sort()
	spawn_position = global_position
	spawn_elevation = elevation

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
		
	velocity = velocity.normalized() * SPEED
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
		
	move_with_elevation(_delta)
	
	if Input.is_action_just_pressed("Shoot"):
		shoot()
	if Input.is_action_just_pressed("sword_swing"):
		if(is_swinging):
			buffered_swing = true;
		else:
			sword_swing()
func sword_swing() ->void:
	
	is_swinging = true
	while true:
		buffered_swing = false	
		$Combo.stop()
		$SwordSwing.visible = true
		$Combo.start()
		var side := 1 if(cos(facing_angle) >=0) else -1
		match combo_step:
			0:
				$SwordSwing/Combo1.rotation = facing_angle+PI
				$SwordSwing/Combo1/SwordAnimation.rotation += deg_to_rad(c1_a)
				$SwordSwing/Combo1/SwordAnimation.flip_h = (side == 1)
				$SwordSwing/Combo1.visible = true
				$SwordSwing/Combo2.visible = false
				$SwordSwing/Combo3.visible = false
				$SwordSwing/Combo1/CollisionShape2D.set_deferred("disabled", false)
				$SwordSwing/Combo1/SwordAnimation.play("Combo1")
				await $SwordSwing/Combo1/SwordAnimation.animation_finished
				$SwordSwing/Combo1/CollisionShape2D.set_deferred("disabled", true)
				$SwordSwing/Combo1/SwordAnimation.rotation = deg_to_rad(c1_a)
			1:
				$SwordSwing/Combo2.rotation = facing_angle+PI
				if(side == 1):
					$SwordSwing/Combo2/SwordAnimation.flip_v = false
					$SwordSwing/Combo2/SwordAnimation.offset.y = -15
					$SwordSwing/Combo2/SwordAnimation.rotation -= deg_to_rad(c2_a)
				elif (side ==-1):
					$SwordSwing/Combo2/SwordAnimation.rotation += deg_to_rad(c2_a-45)
				$SwordSwing/Combo1.visible = false
				$SwordSwing/Combo2.visible = true
				$SwordSwing/Combo3.visible = false
				$SwordSwing/Combo2/CollisionShape2D.set_deferred("disabled", false)
				$SwordSwing/Combo2/SwordAnimation.play("Combo2")
				await $SwordSwing/Combo2/SwordAnimation.animation_finished
				$SwordSwing/Combo2/CollisionShape2D.set_deferred("disabled", true)
				$SwordSwing/Combo2/SwordAnimation.flip_v = true
				$SwordSwing/Combo2/SwordAnimation.offset.y = 15
				$SwordSwing/Combo2/SwordAnimation.rotation = deg_to_rad(240)
			2:
				$SwordSwing/Combo3.rotation = facing_angle+PI
				$SwordSwing/Combo1.visible = false
				$SwordSwing/Combo2.visible = false
				$SwordSwing/Combo3.visible = true
				$SwordSwing/Combo3/CollisionShape2D.set_deferred("disabled", false)
				$SwordSwing/Combo3/SwordAnimation.play("Combo3")
				await $SwordSwing/Combo3/SwordAnimation.animation_finished
				$SwordSwing/Combo3/CollisionShape2D.set_deferred("disabled", true)
		combo_step = (combo_step+1)%3
		$SwordSwing.visible = false
		if(buffered_swing):
			continue
		else:
			break
	is_swinging = false;
	enemies_hit.clear()
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot()
		
func _on_combo_timeout() -> void:
	if(!is_swinging):
		combo_step = 0;
		
func shoot():
	var instance = projectile.instantiate()
	var angle = (get_global_mouse_position() - global_position).angle()
	instance.dir = angle             
	instance.spawnPos = global_position
	instance.spawnRot = angle        
	main.add_child.call_deferred(instance)
	
func take_damage(amount: int):
	health = clampi(health - amount, 0, 100)
	health_bar.value = health
	
func move_with_elevation(delta: float) -> void:
	_update_jump(delta)
	if floors == null:
		move_and_slide()
		_update_visuals()
		return
	var step := velocity * delta
	if not _can_move(Vector2(step.x, 0)):
		velocity.x = 0
	if not _can_move(Vector2(0, step.y)):
		velocity.y = 0
	move_and_slide()
	_update_floor()
	_update_visuals()
func _update_jump(delta: float) -> void:
	if not in_air and Input.is_action_just_pressed("Jump"):
		in_air = true
		z_velocity = JUMP_SPEED
	if in_air:
		z_velocity -= GRAVITY * delta
		z_height += z_velocity * delta
		if floors == null and z_height <= 0:
			_land()

func _feet_world() -> Vector2:
	return global_position + FEET + Vector2(0, elevation * TILE)

func _is_floor(h: int, point: Vector2) -> bool:
	var layer := floors.get_child(h) as TileMapLayer
	var cell := layer.local_to_map(layer.to_local(point))
	var data := layer.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("is_floor")

func _ground_level(world: Vector2) -> int:
	for h in range(floors.get_child_count() - 1, -1, -1):
		if _is_floor(h, world - Vector2(0, h * TILE)):
			return h
	return -1
	
func _start_elevation() -> int:
	for h in range(floors.get_child_count() - 1, -1, -1):
		if _is_floor(h, global_position + FEET):
			return h
	return 0
	
func _can_move(step: Vector2) -> bool:
	if step == Vector2.ZERO:
		return true
	var probe := _feet_world() + step + step.sign() * FOOT_SIZE
	var ground := _ground_level(probe)
	if not in_air:
		return ground == elevation
	return ground * TILE <= elevation * TILE + z_height
	
func _update_floor() -> void:
	var ground := _ground_level(_feet_world())
	if not in_air and ground != elevation:
		in_air = true
	if not in_air:
		return
	if ground >= 0 and ground != elevation:
		var total := elevation * TILE + z_height
		var shift := (ground - elevation) * TILE
		global_position.y -= shift
		$Camera2D.position.y += shift
		elevation = ground
		z_height = total - elevation * TILE
		_update_sort()
	if ground >= 0 and z_height <= 0:
		_land()
	elif ground < 0 and z_height < FALL_LIMIT:
		_respawn()

func _land() -> void:
	z_height = 0.0
	z_velocity = 0.0
	in_air = false


func _respawn() -> void:
	global_position = spawn_position
	elevation = spawn_elevation
	$Camera2D.position.y = 0
	_land()
	_update_sort()

func _update_visuals() -> void:
	$PlayerSprite.position.y = sprite_base_y - z_height
	$SwordSwing.position.y = swing_base_y - z_height
	$Camera2D.position.y = move_toward($Camera2D.position.y, 0, 120 * get_physics_process_delta_time())
	$Shadow.scale = Vector2.ONE * clampf(1.0 - z_height / 64.0, 0.5, 1.0)
	$Shadow.visible = floors == null or _ground_level(_feet_world()) >= 0
	
func _update_sort() -> void:
	if floors == null:
		return
	for h in range(1, floors.get_child_count()):
		var layer := floors.get_child(h) as TileMapLayer
		layer.y_sort_origin = int(TILE * (h - elevation) - TILE / 2 - FEET.y)
