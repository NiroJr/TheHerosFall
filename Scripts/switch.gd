class_name Switch
extends ElevationBody
signal power_changed

@export_enum("OFF", "ORANGE", "YELLOW", "PURPLE")
var starting_power = "OFF"

enum Kind { ORANGE, YELLOW, PURPLE }

const ON_TEXTURES := {
	Kind.ORANGE: preload("res://Assets/PuzzleSprites/switches/switchesAndWires4.png"),
	Kind.YELLOW: preload("res://Assets/PuzzleSprites/switches/switchesAndWires2.png"),
	Kind.PURPLE: preload("res://Assets/PuzzleSprites/switches/switchesAndWires1.png")
}
const OFF_TEXTURE := preload("res://Assets/PuzzleSprites/switches/switchesAndWires3.png")

@export_group("What changes it")
@export var accept_sword := true 
@export var accept_shot := true
@export var accept_enemy := true
@export_group("")
@export var hit_cooldown := 0.25

var is_on := false
var kind: Kind = Kind.ORANGE
var _cooldown := 0.0
var is_receiving := false

func _ready() -> void:
	var color: int = 0
	
	match starting_power:
		"ORANGE":
			color = 1
		"YELLOW":
			color = 2
		"PURPLE":
			color = 3
	if color > 0:
		set_color(color - 1)
	feet = Vector2(0, 11)
	setup_elevation()
	$HitBox.area_entered.connect(_on_hit)
	_refresh()


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func _on_hit(area: Area2D) -> void:
	if _cooldown > 0.0:
		return
	if _elevation_of(area) != elevation:
		return
	var attack := _attack_kind(area)
	if attack < 0:
		return
	_cooldown = hit_cooldown
	set_color(attack)
	_flash()


func _attack_kind(area: Area2D) -> int:
	if area.is_in_group("Combo1") or area.is_in_group("Combo2") or area.is_in_group("Combo3"):
		return Kind.ORANGE if accept_sword else -1
	var bullet := area.get_parent()
	if bullet.shooter != null and not bullet.shooter.is_in_group("player"):
		return Kind.PURPLE if accept_enemy else -1
	if "enemy_projectile" in bullet and not bullet.enemy_projectile:
		return Kind.YELLOW if accept_shot else -1
	return -1


func set_color(value: Kind, indirect := false) -> void:
	if is_on and kind == value:
		return
	if not is_on:
		is_on = true
		kind = value

	else:
		is_on = false
	is_receiving = indirect
	_refresh()
	power_changed.emit()
	is_receiving = false

func _refresh() -> void:
	$Sprite2D.texture = ON_TEXTURES[kind] if is_on else OFF_TEXTURE


func _flash() -> void:
	var tween := create_tween()
	$Sprite2D.scale = Vector2(1.2, 1.2)
	tween.tween_property($Sprite2D, "scale", Vector2.ONE, 0.12)


func _elevation_of(node: Node) -> int:
	while node != null and not ("elevation" in node):
		node = node.get_parent()
	return node.elevation if node != null else elevation
