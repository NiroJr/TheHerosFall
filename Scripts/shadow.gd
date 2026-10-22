extends Node2D

@export var radius := 16.0;
@export var color := Color(0, 0, 0, 0.35)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, radius, color)
