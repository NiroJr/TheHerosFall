extends ElevationBody
@onready var main = get_tree().current_scene
var player :Area2D
var line_of_sight := false
var can_shoot := true
var alerted := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Rocket/CollisionShape2D.set_deferred("disabled", true)
	$Rocket.visible = false
	$PlayerDetection.area_entered.connect(_detected)
	$PlayerDetection.area_exited.connect(_out_of_range)
	$target.visible = false
	$PlayerDetection/RayCast2D.add_exception(self)
	$Hatch_Launcher.play("default")


func _process(_delta: float) -> void:
	if(alerted):
		return
	if(player):
		check_sight_line()
	else:
		line_of_sight = false

func check_sight_line() -> void:
	$PlayerDetection/RayCast2D.target_position = $PlayerDetection/RayCast2D.to_local(player.global_position)
	$PlayerDetection/RayCast2D.force_raycast_update()
	if($PlayerDetection/RayCast2D.is_colliding() && $PlayerDetection/RayCast2D.get_collider() == player):
		line_of_sight = true
		if(can_shoot):
			shoot()
	else:
		line_of_sight = false

func shoot() -> void:
	can_shoot = false
	$Hatch_Launcher.play("Firing")
	while ($Hatch_Launcher.is_playing() && $Hatch_Launcher.frame < 5):
		await $Hatch_Launcher.frame_changed
		if(!line_of_sight): 
			$Fire.start()
			$Hatch_Launcher.play("default")
			return
	var rocket_instance = $Rocket.duplicate()
	rocket_instance.target_node = $target
	var player_pos = player.global_position
	$target.global_position = player.global_position
	$target.visible = true
	rocket_instance.visible = true
	rocket_instance.get_node("CollisionShape2D").disabled = false
	rocket_instance.global_position = $Hatch_Launcher.global_position
	rocket_instance.z_index = self.z_index +1
	main.add_child(rocket_instance)
	rocket_instance.spawn(player_pos)
	$Fire.start()
	await $Hatch_Launcher.animation_finished
	$Hatch_Launcher.stop()
	$Hatch_Launcher.play("default")

func _on_fire_timeout() -> void:
	can_shoot = true

func _detected(area: Area2D) -> void:
	if(area.is_in_group("PlayerHitBox")):
		player = area
		$Alert.visible = true
		$Alert.play("default")
		alerted = true
		await $Alert.animation_finished
		await get_tree().create_timer(1.0).timeout
		alerted = false
		$Alert.visible = false

func _out_of_range(area: Area2D) -> void:
	var to_player: Vector2 = world_offset_to(area.get_parent())
	if(area == player && to_player.length() > 6*8):
		player = null
		line_of_sight = false
		$Hatch_Launcher.play("default")
