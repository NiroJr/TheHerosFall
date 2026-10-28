extends CharacterBody2D

@onready var main = get_tree().current_scene
@onready var projectile = load("res://Scenes/projectile.tscn")
@onready var timer: Timer = get_node("ShootCooldown")
@onready var crosshair: Sprite2D = get_node("Cursor")
var is_fully_charged := false
var facing_angle := 0.0
const SPEED = 300.0
var sprite_dir  := 0.0;
var slice  := TAU/8;
var sprite_index := 0;
var combo_step := 0;
var is_swinging := false;
var buffered_swing := false;
var is_dashing := false;
var can_dash = true;
var attack_dash_dist := 20
var attack_dash_dur := 0.2
var dash_dir = Vector2(0,0)

var health := 100
@onready var health_bar : ProgressBar = $HUD/HealthBar

var enemies_hit: Array[Node] = []
const TILE := 16.0
const STEP_UP_SPEED := 160.0
const GRAVITY := 800.0
const FEET := Vector2(0, 28) #feet relative to player
const FOOT_SIZE := Vector2(6, 3) #feet radius
const FALL_LIMIT := -160.0 #void detection
const CAN_FALL_INTO_VOID := false
const STEP_UP_PUSH := 8.0

enum { WALK, STEP_UP, FALL }  
var state := WALK
var elevation := 0
var z_height := 0.0
var z_velocity := 0.0
var push_left := Vector2.ZERO
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
	$SwordSwing/Parry/CollisionShape2D.set_deferred("disabled", true)
	floors = get_tree().current_scene.get_node_or_null("Floors")
	if floors:
		elevation = _start_elevation()
		_update_sort()
	spawn_position = global_position
	spawn_elevation = elevation
	timer.timeout.connect(_on_charge_timeout)

func _on_charge_timeout() -> void:
	is_fully_charged = true
	crosshair.texture = load("res://Assets/MCSprites/aimReticle/aimReticle1.png")

const Animations := [
	"right_walk",
	"downRight_walk",
	"down_walk", 
	"downRight_walk", #downLeft
	"right_walk",  #left
	"upRight_walk", #upLeft
	"up_walk",	
	"upRight_walk",
	"right_idle",
	"downRight_idle",
	"down_idle", 
	"downRight_idle", #downLeft
	"right_idle",  #left
	"upRight_idle", #upLeft
	"up_idle",	
	"upRight_idle"
]
func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var hDirection = 0
	var vDirection = 0
	if(!is_swinging):
		hDirection = Input.get_axis("Left", "Right")
		vDirection = Input.get_axis("Up", "Down")
	
	if Input.is_action_just_pressed("Dash") && (!is_swinging):
		if(!is_dashing && can_dash):
			_dash(160, 0.15);
			await get_tree().create_timer(0.4).timeout
			self.process_mode = Node.PROCESS_MODE_PAUSABLE
			can_dash = true;
			
	if(is_dashing):
		velocity = dash_dir*(attack_dash_dist/attack_dash_dur)
	else:
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
		$PlayerSprite.play(Animations[sprite_index+8])
		$PlayerSprite.frame = 0;
	move_with_elevation(_delta)
	
	var holding := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if holding:
		if timer.is_stopped() and not is_fully_charged:
			timer.start()
	else:
		if is_fully_charged:
			shoot()
			crosshair.texture = load("res://Assets/MCSprites/aimReticle/aimReticle2.png")
		timer.stop()
		is_fully_charged = false
	
	if Input.is_action_just_pressed("sword_swing"):
		if(is_swinging):
			buffered_swing = true;
		else:
			is_dashing = false
			sword_swing()
	
	if Input.is_action_just_pressed("Parry"):
		_parry()

			
func _dash(dist: int, speed: float)-> void:
	can_dash = false
	is_dashing = true
	dash_dir = Vector2.RIGHT.rotated(facing_angle)
	attack_dash_dist = dist
	attack_dash_dur = speed
	$HitBox/CollisionShape2D.process_mode = PROCESS_MODE_DISABLED
	await get_tree().create_timer(speed).timeout
	is_dashing = false
	$HitBox/CollisionShape2D.process_mode = Node.PROCESS_MODE_INHERIT
	if(!is_swinging):
		self.process_mode = Node.PROCESS_MODE_DISABLED
	
func _parry()-> void:
	var parry : Node2D = $SwordSwing/Parry
	$SwordSwing.visible = true
	$SwordSwing/Combo1.visible = false
	$SwordSwing/Combo2.visible = false
	$SwordSwing/Combo3.visible = false
	parry.visible = true
	var shape = parry.get_node("CollisionShape2D")
	var anim = parry.get_node(("parry_anim"))
	anim.play("parry")
	while (anim.is_playing() && anim.frame < 4):
		await anim.frame_changed
	if(anim.is_playing()):
		shape.set_deferred("disabled", false)
	await anim.animation_finished
	$SwordSwing.visible = false
	parry.visible = false
	shape.set_deferred("disabled", true)

func _on_parry_area_entered(area: Area2D) -> void:
	$SwordSwing/Parry/parry_anim.play("parried")

func sword_swing() -> void:
	is_swinging = true
	while true:
		buffered_swing = false
		$Combo.stop()
		$SwordSwing.visible = true
		$Combo.start()

		# Steps 0 and 1 both use Combo1 (step 1 is mirrored), step 2 uses Combo3
		var use_combo1 := (combo_step == 0 or combo_step == 1)
		var combo_node: Node2D = $SwordSwing/Combo1 if use_combo1 else $SwordSwing/Combo3
		var anim_name := "Combo1" if use_combo1 else "Combo3"

		$SwordSwing/Combo1.visible = use_combo1
		$SwordSwing/Combo3.visible = not use_combo1
		$SwordSwing/Parry.visible = false

		combo_node.rotation = facing_angle - PI/2
		# Mirror on the second hit, reset on the others
		combo_node.scale.x = -1 if combo_step == 1 else 1

		var shape: CollisionShape2D = combo_node.get_node("CollisionShape2D")
		var anim: AnimatedSprite2D = combo_node.get_node("SwordAnimation")

		shape.set_deferred("disabled", false)
		anim.play(anim_name)
		if(use_combo1):
			_dash(16, 0.12)
		else:
			_dash(32, 0.12)
		can_dash = true
		velocity = Vector2.ZERO;
		await anim.animation_finished
		shape.set_deferred("disabled", true)

		combo_step = (combo_step + 1) % 3
		$SwordSwing.visible = false
		if buffered_swing:
			continue
		else:
			break
	is_swinging = false
	enemies_hit.clear()

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
	#if(is_dashing):
	#	return
	health = clampi(health - amount, 0, 100)
	health_bar.value = health
	
func move_with_elevation(delta: float) -> void:
	if floors == null:
		move_and_slide()
		return
	match state:
		WALK:
			var step := velocity * delta
			if not _can_move(Vector2(step.x, 0)):
				velocity.x = 0
			if not _can_move(Vector2(0, step.y)):
				velocity.y = 0
			move_and_slide()
			_check_level_change()
		STEP_UP:
			z_height = move_toward(z_height, 0.0, STEP_UP_SPEED * delta)
			if push_left != Vector2.ZERO:
				var move := push_left.limit_length(STEP_UP_SPEED * STEP_UP_PUSH / TILE * delta)
				if _ground_level(_feet_world() + move + move.sign() * FOOT_SIZE) == elevation:
					move_and_collide(move)
					push_left -= move
				else:
					push_left = Vector2.ZERO
			if z_height == 0.0 and push_left == Vector2.ZERO:
				state = WALK
		FALL:
			z_velocity -= GRAVITY * delta
			z_height += z_velocity * delta
			if _ground_level(_feet_world()) >= 0:
				if z_height <= 0.0:
					_land()
			elif z_height < FALL_LIMIT:
				_respawn()
	_update_visuals()

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
	if ground < 0:
		return CAN_FALL_INTO_VOID
	return ground <= elevation + 1


func _check_level_change() -> void:
	var ground := _ground_level(_feet_world())
	if ground == elevation:
		return
	if ground < 0:
		state = FALL
		z_velocity = 0.0
		return
	var shift := (ground - elevation) * TILE
	global_position.y -= shift
	$Camera2D.position.y += shift
	z_height = -shift
	elevation = ground
	_update_sort()
	z_velocity = 0.0
	if shift > 0:
		state = STEP_UP
		push_left = velocity.normalized() * STEP_UP_PUSH
	else:
		state = FALL
	
func _land() -> void:
	z_height = 0.0
	z_velocity = 0.0
	state = WALK


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
		if h <= elevation:
			layer.y_sort_origin = (h - elevation - 1) * 100000
		else:
			layer.y_sort_origin = int(TILE * (h - elevation) - TILE / 2 - FEET.y)
# Replace with function body.
