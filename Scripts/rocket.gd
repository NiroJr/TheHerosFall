extends Area2D
var lift_time := 1
var fall_time := 0.1
var flight_arc = 240
var start : Vector2
var target : Vector2
var lift: Vector2
var time := 0.0
var is_active := false
@export var target_node := Node2D
var has_exploded := false

func _ready() -> void:
	#area_entered.connect(_player_hit)
	$AnimatedSprite2D.play("Launch")
	$Shadow.top_level = true
	
func spawn(target_position : Vector2) -> void:
	start = global_position
	target = target_position+Vector2(1,0)
	var mid_point := start.lerp(target, 0.5)
	lift = mid_point + Vector2(0, -flight_arc)
	is_active = true
	
func _process(delta: float) -> void:
	if(!is_active):
		return
	time += delta
	var t = 0.0
	if(time < lift_time):
		t = 0.5*(time / lift_time)
	else:
		var fall := time -lift_time
		t = 0.5 + 0.5*( fall/ fall_time)
	t = clampf(t, 0.0, 1.0)
	var p0 := start.lerp(lift, t)
	var p1 := lift.lerp(target, t)
	var new_position := p0.lerp(p1, t)
	var dir := new_position - global_position
	if dir.length_squared() > 0.01:
		rotation = dir.angle() - deg_to_rad(90)
	global_position = new_position
	var shadow_pos = start.lerp(target, t)
	var height := (shadow_pos - new_position).length()
	var shadow_factor := clampf(1.0 - (height / (flight_arc * 1.5)), 0.4, 1.0)
	$Shadow.scale = Vector2.ONE * shadow_factor
	$Shadow.global_position = shadow_pos
	if t >= 1.0:
		_explode()
		
func _explode()-> void:
	if has_exploded: 
		return
	self.add_to_group("Enemy")
	has_exploded = true
	is_active = false
	$Shadow.visible = false
	$AnimatedSprite2D.play("Land")
	await get_tree().physics_frame
	for area in self.get_overlapping_areas():
		if area != null && area.is_in_group("PlayerHitBox"):
			area.get_parent().take_damage(50)
			area.get_parent()._shake(20)
	self.set_deferred("monitoring", false)
	await $AnimatedSprite2D.animation_finished
	if is_instance_valid(target_node):
		target_node.visible = false
	queue_free()
	


	
