extends Node2D

@export var radius := 8.0;
@export var color := Color(0, 0, 0, 0.35)
@export_enum("Player", "Rocket")
var base := "Player"

func _draw() -> void:
	if(base == "Player"):
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, radius, color)
	if(base == "Rocket"):
		radius = 20
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, radius, color)
