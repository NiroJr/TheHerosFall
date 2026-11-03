extends ElevationBody

@onready var projectile = load("res://Scenes/projectile.tscn")
@onready var main = get_tree().current_scene
@onready var health_bar = $HealthBar

const MAX_HEALTH := 100
const TURRET_ANIMATIONS := [
	"right",
	"down_right",
	"down",
	"down_right",
	"right",
	"up_right",
	"up",
	"up_right"
]

var speed = 75.0
var player: Node2D
var direction := Vector2.ZERO
var knockback := Vector2.ZERO
var health := MAX_HEALTH

var player_box: Area2D = null
var turret_sprite_index := 0
var line_of_sight := false
var can_shoot := true
var slice := TAU / 8


func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("Enemy")
	#$TurretSprite.play("default")
	health_bar.value = MAX_HEALTH
	feet = Vector2(0, 10)
	setup_elevation([$HealthBar, $TurretSprite])
	$PlayerDetection.area_entered.connect(detected)
	$PlayerDetection.area_exited.connect(_out_of_range)
	$PlayerDetection/RayCast2D.add_exception(self)


func _physics_process(delta):
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var to_player: Vector2 = world_offset_to(player)
	direction = to_player.normalized()
	var distance = to_player.length()
	var reachable: bool = player.elevation - elevation <= 1

	if distance < 200 and reachable:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	if velocity == Vector2.ZERO:
		$Sprite2D.animation = "default"
		$Sprite2D.play("default")
	else:
		$Sprite2D.animation = "moving"
		$Sprite2D.play("moving")

	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 640 * delta)

	move_with_elevation(delta)
	update_turret()


func update_turret() -> void:
	if player_box:
		check_sight_line()
		$TurretSprite.flip_h = turret_sprite_index in [3, 4, 5]
		$TurretSprite.play(TURRET_ANIMATIONS[turret_sprite_index])
	else:
		line_of_sight = false
		$TurretSprite.stop()
		$TurretSprite.frame = 0

func detected(body: Area2D) -> void:
	if body.is_in_group("PlayerHitBox"):
		player_box = body
		$Alert.visible = true
		$Alert.play("default")
		await $Alert.animation_finished
		$Alert.visible = false


func _out_of_range(body: Area2D) -> void:
	var to_box: Vector2 = world_offset_to(body.get_parent())
	if body == player_box and to_box.length() > 6 * 13.04:
		player_box = null
		line_of_sight = false


func check_sight_line() -> void:
	if player_box.get_parent().elevation != elevation:
		line_of_sight = false
		return
	var ray = $PlayerDetection/RayCast2D
	ray.target_position = ray.to_local(player_box.global_position)
	ray.force_raycast_update()
	if ray.is_colliding() and ray.get_collider() == player_box:
		line_of_sight = true
		var facing_angle = (player_box.global_position - global_position).angle()
		var sprite_dir = fposmod(facing_angle, TAU)
		turret_sprite_index = roundi(sprite_dir / slice) % 8
		if can_shoot:
			shoot()
	else:
		line_of_sight = false


func shoot() -> void:
	can_shoot = false
	var instance = projectile.instantiate()
	var angle = (player_box.global_position - global_position).angle()
	instance.dir = angle
	instance.spawnPos = global_position
	instance.spawnRot = angle
	instance.enemy_projectile = true
	instance.shooter = self
	instance.speed = 200
	instance.elevation = elevation
	instance.ground_offset = feet.y
	instance.set_collision_mask_value(3, false)
	main.add_child.call_deferred(instance)
	$Fire.start()


func _on_fire_timeout() -> void:
	can_shoot = true


func take_damage(amount: int):
	health = clampi(health - amount, 0, MAX_HEALTH)
	health_bar.value = health
	if health <= 0:
		queue_free()
	knockback = -direction * 240


func _on_hit_box_area_entered(area: Area2D) -> void:
	if player.elevation != elevation:
		return

	if area.is_in_group("PlayerHitBox"):
		player.take_damage(10)

	player.enemies_hit.append(self)

	if area.is_in_group("Combo1"):
		take_damage(10)
	elif area.is_in_group("Combo2"):
		take_damage(20)
	elif area.is_in_group("Combo3"):
		take_damage(50)
	elif area.is_in_group("Parry"):
		take_damage(0)
