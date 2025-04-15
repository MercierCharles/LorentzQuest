extends Control




func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_button_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")
