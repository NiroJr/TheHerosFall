extends Control
@export_file("*.tscn") var first_level : String = "res://Scenes/main.tscn"
@onready var start_button := $Container/VBoxContainer/Play
@onready var quit_button := $Container/VBoxContainer/Quit
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Engine.time_scale = 1
	get_tree().paused = false
	start_button.grab_focus()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	PlayerData.health = 100
	get_tree().change_scene_to_file(first_level)

func _on_quit_pressed() -> void:
	get_tree().quit()
