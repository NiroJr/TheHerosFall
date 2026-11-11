extends ElevationBody

@onready var main = get_tree().current_scene
@onready var projectile = load("res://Scenes/projectile.tscn")
@onready var timer: Timer = get_node("ShootCooldown")
@onready var canvasLayer: CanvasLayer = get_node("CanvasLayer")
@onready var crosshair: Sprite2D = canvasLayer.get_child(0)
@onready var trajectory: Line2D = get_node("Trajectory")
var charge_frames: Array[Texture2D] = [preload("res://Assets/MCSprites/aimReticle/aimChargeUpAnimation/aimReticle6.png"), preload("res://Assets/MCSprites/aimReticle/aimChargeUpAnimation/aimReticle7.png"), preload("res://Assets/MCSprites/aimReticle/aimChargeUpAnimation/aimReticle8.png"), preload("res://Assets/MCSprites/aimReticle/aimChargeUpAnimation/aimReticle9.png"), preload("res://Assets/MCSprites/aimReticle/aimChargeUpAnimation/aimReticle10.png")]
var is_fully_charged := false
var facing_angle := 0.0
const SPEED = 300.0
var sprite_dir  := 0.0;
var slice  := TAU/8;
var sprite_index := 0;
var direction = Vector2.ZERO
var combo_step := 0;
var is_swinging := false;
var buffered_swing := false;
var is_dashing := false;
var can_dash = true;
var is_parrying := false
var swing_anim := false
var attack_dash_dist := 20
var attack_dash_dur := 0.2
var dash_dir = Vector2(0,0)
var dashDistance = 150
var dashTime = 0.35
var aim_dir := Vector2.ZERO
var knockback := Vector2.ZERO
var knocked := false
var camera_shake := 0.0
var hitstop_dur = 0.08

var health := 100
@onready var health_bar : ProgressBar = $HUD/HealthBar

var enemies_hit: Array[Node] = []



func _ready() -> void:
	$SwordSwing.visible = false
	add_to_group("player")
	health_bar.value = health
	$SwordSwing/Combo1/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Combo2/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Combo3/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Parry/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Combo1.area_entered.connect(_swordHit)
	$SwordSwing/Combo2.area_entered.connect(_swordHit)
	$SwordSwing/Combo3.area_entered.connect(_swordHit)
	feet = Vector2(0, 14)
	setup_elevation([$PlayerSprite, $SwordSwing])
	_update_sort()
	timer.timeout.connect(_on_charge_timeout)
	$PlayerSprite.process_mode = Node.PROCESS_MODE_ALWAYS
	crosshair.texture = charge_frames[0]

func _on_charge_timeout() -> void:
	is_fully_charged = true
	crosshair.texture = charge_frames[charge_frames.size() - 1]
	trajectory.texture = load("res://Assets/MCSprites/aimReticle/aimReticle5.png")

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
const dash_Animations := [
	"dash_side",
	"dash_downRight",
	"dash_down", 
	"dash_downRight", #downLeft
	"dash_side",  #left
	"dash_upRight", #upLeft
	"dash_up",	
	"dash_upRight",
]

const dashEndLag_Animations := [
	"dashEndLag_side",
	"dashEndLag_downRight",
	"dashEndLag_down", 
	"dashEndLag_downRight", #downLeft
	"dashEndLag_side",  #left
	"dashEndLag_upRight", #upLeft
	"dashEndLag_Up",	
	"dashEndLag_upRight",
]

const combo1_Animations := [
	"combo1_side",
	"combo1_downRight",
	"combo1_down", 
	"combo1_downRight", #downLeft
	"combo1_side",  #left
	"combo1_upRight", #upLeft
	"combo1_up",	
	"combo1_upRight",
]

const combo2_Animations := [
	"combo2_side",
	"combo2_downRight",
	"combo2_down", 
	"combo2_downRight", #downLeft
	"combo2_side",  #left
	"combo2_upRight", #upLeft
	"combo2_up",	
	"combo2_upRight",
]
func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if(is_swinging):
		pass
	if(camera_shake > 0.0):
		camera_shake = move_toward(camera_shake, 0.0, 25*_delta)
		$Camera2D.offset = Vector2(randf_range(-camera_shake, camera_shake), randf_range(-camera_shake, camera_shake))
	else:
		$Camera2D.offset = Vector2.ZERO
	if(knocked):
		velocity= knockback
		knockback = knockback.move_toward(Vector2.ZERO, 640*_delta)
		move_with_elevation(_delta)
		return
	direction = Vector2.ZERO
	if(!is_swinging):
		direction = Input.get_vector("Left","Right","Up","Down")
	
	if Input.is_action_just_pressed("Dash") && (!is_swinging):
		if(!is_dashing && can_dash):
			_dash(dashDistance, dashTime);
			
	var holding := Input.is_action_pressed("Shoot")
	if(is_dashing):
		velocity = dash_dir.normalized()*(attack_dash_dist/attack_dash_dur)
	elif(holding):
		velocity = direction*(SPEED*0.33)
	#	if hDirection:
	#		velocity.x = hDirection * SPEED*0.33
	#	else:
	#		velocity.x = move_toward(velocity.x, 0, SPEED*0.33)
	#	if vDirection:
	#		velocity.y = vDirection * SPEED*0.33
	#	else:
	#		velocity.y = move_toward(velocity.y, 0, SPEED*0.33)
	elif(is_parrying):
		velocity = Vector2.ZERO
	else:
		velocity = direction*SPEED
	#	if hDirection:
	#		velocity.x = hDirection * SPEED
	#	else:
	#		velocity.x = move_toward(velocity.x, 0, SPEED)
	#	if vDirection:
	#		velocity.y = vDirection * SPEED
	#	else:
	#		velocity.y = move_toward(velocity.y, 0, SPEED)

	#	velocity = velocity.normalized() * SPEED
	
		
		
	#Rotates the player body and facing direction for projectile during movement
	if(velocity != Vector2.ZERO && !swing_anim):
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
		if(!is_dashing):
			$PlayerSprite.play(Animations[sprite_index]);
	elif(!is_dashing && !swing_anim): 
		$PlayerSprite.stop()
		$PlayerSprite.play(Animations[sprite_index+8])
		$PlayerSprite.frame = 0;
	
	skip_floor_check = is_dashing
	move_with_elevation(_delta)
	
	aim_dir = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
	if(aim_dir.length()> 0):
		aim_dir = aim_dir.normalized()
	else:
		aim_dir = (get_global_mouse_position() - global_position).normalized()
	if holding:
		if timer.is_stopped() and not is_fully_charged:
			timer.start()
		if not is_fully_charged:
			var progress := 1.0 - (timer.time_left / timer.wait_time)
			crosshair.texture = charge_frames[min(int(progress * charge_frames.size()), charge_frames.size() - 1)]
		
		trajectory.update_trajectory(aim_dir, 500.0, get_physics_process_delta_time())
	else:
		if is_fully_charged:
			shoot()
			trajectory.texture = load("res://Assets/MCSprites/aimReticle/aimReticle4.png")
		crosshair.texture = charge_frames[0]
		timer.stop()
		is_fully_charged = false
		trajectory.clear_points()
	
	if Input.is_action_just_pressed("sword_swing"):
		if(is_swinging):
			buffered_swing = true;
		else:
			is_dashing = false
			sword_swing()
	
	if Input.is_action_just_pressed("Parry"):
		_parry()

			
func _dash(dist: int, speed: float)-> void:
	var swinging := is_swinging
	can_dash = false
	is_dashing = true
	dash_dir = Vector2.RIGHT.rotated(facing_angle)
	attack_dash_dist = dist
	attack_dash_dur = speed
	$HitBox.process_mode = Node.PROCESS_MODE_PAUSABLE if swinging else Node.PROCESS_MODE_DISABLED

	if !swinging:
		$SwordSwing.visible = false
		$SwordSwing.process_mode = Node.PROCESS_MODE_DISABLED
		$PlayerSprite.speed_scale = (12.0/13.0) / attack_dash_dur
		$PlayerSprite.play(dash_Animations[sprite_index])

	await get_tree().create_timer(speed).timeout

	$HitBox.process_mode = Node.PROCESS_MODE_PAUSABLE
	$SwordSwing.process_mode = Node.PROCESS_MODE_INHERIT
	is_dashing = false

	if !swinging:
		$PlayerSprite.speed_scale = 1
		$PlayerSprite.play(dashEndLag_Animations[sprite_index])
		self.process_mode = Node.PROCESS_MODE_DISABLED
		await $PlayerSprite.animation_finished
		self.process_mode = Node.PROCESS_MODE_INHERIT

	can_dash = true
	
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

func _on_parry_area_entered(_area: Area2D) -> void:
	is_parrying = true
	$SwordSwing/Parry/parry_anim.play("parried")
	await $SwordSwing/Parry/parry_anim.animation_finished
	is_parrying = false

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
		swing_anim = true
		match combo_step:
			0:
				$PlayerSprite.play(combo1_Animations[sprite_index])
			1:
				if(sprite_index == 2):
					$PlayerSprite.flip_h =true
				$PlayerSprite.play(combo2_Animations[sprite_index])
			#2:
			#	$PlayerSprite.play(combo1_Animations[sprite_index])
		anim.play(anim_name)
		while(anim.frame < 3):
			await anim.frame_changed
		if(use_combo1):
			_dash(16, 0.12)
		else:
			_dash(25, 0.12)
		can_dash = true
		velocity = Vector2.ZERO;
		await anim.animation_finished
		swing_anim = false
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
		
func _swordHit(area: Area2D)->void:
	if area.is_in_group("Enemy"):
		Engine.time_scale = 0.1
		await get_tree().create_timer(hitstop_dur, true, false, true).timeout
		Engine.time_scale = 1

func shoot():
	var instance = projectile.instantiate()
	var angle = aim_dir.angle()
	instance.elevation = elevation
	instance.shooter = self
	instance.ground_offset = feet.y
	instance.dir = angle             
	instance.spawnPos = global_position
	instance.spawnRot = angle        
	main.add_child.call_deferred(instance)
	
func _shake(strength: float) ->void:
	camera_shake = strength

func take_damage(amount: int):
	#if(is_dashing):
	#	return
	health = clampi(health - amount, 0, 100)
	health_bar.value = health
	
 
func _level_changed(shift: float) -> void:
	$Camera2D.position.y += shift
	_update_sort()
 
 
func _fell_into_void() -> void:
	super()
	$Camera2D.position.y = 0
	_update_sort()
 
 
func _update_visuals() -> void:
	super()
	$Camera2D.position.y = move_toward($Camera2D.position.y, 0, 120 * get_physics_process_delta_time())
	$Shadow.scale = Vector2.ONE * clampf(1.0 - z_height / 64.0, 0.5, 1.0)
	$Shadow.visible = floor_layers.is_empty() or _ground_level(_feet_world()) >= 0
 
 
func _update_sort() -> void:
	for h in range(1, floor_layers.size()):
		var layer := floor_layers[h]
		if h <= elevation:
			layer.y_sort_origin = (h - elevation - 1) * 100000
		else:
			layer.y_sort_origin = int(TILE * (h - elevation) - TILE / 2 - feet.y)
		layer.notify_runtime_tile_data_update()


func _on_hit_box_area_entered(area: Area2D) -> void:
	if(area.is_in_group("Enemy")):
		var hit_dir := (global_position - area.global_position).normalized()
		knockback = hit_dir*240
		knocked = true
		await get_tree().create_timer(0.3).timeout
		knocked = false
