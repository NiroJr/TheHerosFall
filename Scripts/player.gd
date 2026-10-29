extends ElevationBody

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



func _ready() -> void:
	$SwordSwing.visible = false
	add_to_group("player")
	health_bar.value = health
	$SwordSwing/Combo1/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Combo2/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Combo3/CollisionShape2D.set_deferred("disabled", true)
	$SwordSwing/Parry/CollisionShape2D.set_deferred("disabled", true)
	feet = Vector2(0, 14)
	setup_elevation([$PlayerSprite, $SwordSwing])
	_update_sort()
	timer.timeout.connect(_on_charge_timeout)
	can_fall_into_void = true

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
		
	skip_floor_check = is_dashing
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
	$HitBox.process_mode = PROCESS_MODE_DISABLED if !is_swinging else PROCESS_MODE_PAUSABLE
	await get_tree().create_timer(speed).timeout
	$HitBox.process_mode = Node.PROCESS_MODE_PAUSABLE
	is_dashing = false
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
	instance.elevation = elevation
	instance.shooter = self
	instance.ground_offset = feet.y
	instance.dir = angle             
	instance.spawnPos = global_position
	instance.spawnRot = angle        
	main.add_child.call_deferred(instance)
	
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
