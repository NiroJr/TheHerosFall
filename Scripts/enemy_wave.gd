extends CharacterBody2D

@export var waves: Array[Wave] = []

var current_wave: int = 0
var enemies_defeated: int = 0

func _ready() -> void:
	for wave in waves:
		for path in wave.enemies:
			var enemy = get_node(path)
			enemy.hide()
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	start_wave()

func start_wave():
	enemies_defeated = 0
	if current_wave >= waves.size():
		#turn off wires
		return
	for path in waves[current_wave].enemies:
		var enemy = get_node(path)
		enemy.show()
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.died.connect(_refresh)
		
func _refresh():
	enemies_defeated += 1
	if enemies_defeated >= waves[current_wave].enemies.size():
		current_wave += 1
		start_wave()
