extends Area2D
@export_file("*.tscn") var next_level: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if next_level.is_empty():
		push_warning("LevelExit: no next_level set")
		return
	get_tree().change_scene_to_file.call_deferred(next_level)
