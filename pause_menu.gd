extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game():
	show()
	get_tree().paused = true

func resume_game():
	get_tree().paused = false
	hide()




func _on_button_pressed() -> void:
	resume_game()
