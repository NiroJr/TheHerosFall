extends Area2D
var flight_time := 1.2
var flight_arc = 120
var start : Vector2
var target : Vector2
var lift: Vector2
var time := 0.0
var is_active := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_player_hit)
	$AnimatedSprite2D.play("Launch")
	
func spawn(target_position : Vector2) -> void:
	start = global_position
	target = target_position
	var mid_point := start.lerp(target, 0.5)
	lift = mid_point + Vector2(0, -flight_arc)
	is_active = true
	
func _process(delta: float) -> void:
	if(!is_active):
		return
	time += delta
	var t := clampf(time / flight_time, 0.0, 1.0)
	var p0 := start.lerp(lift, t)
	var p1 := lift.lerp(target, t)
	var new_position := p0.lerp(p1, t)
	var dir := new_position - global_position
	if dir.length_squared() > 0.01:
		rotation = dir.angle() - deg_to_rad(90)
	global_position = new_position
	if t >= 1.0:
		_explode()
		
func _explode()-> void:
	$AnimatedSprite2D.play("Land")
	await $AnimatedSprite2D.animation_finished
	queue_free()

func _player_hit(area : Area2D) -> void:
	if(area.is_in_group("PlayerHitBox")):
		area.get_parent().take_damage(20)
		_explode()
	
