extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false  # Cache GameOverUI au début


func _on_restart_button_pressed():
	get_tree().paused = false  # Unpause the game
	get_tree().reload_current_scene()
