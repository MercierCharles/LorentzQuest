extends Control

func _on_level_1_button_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level1.tscn")

func _on_level_2_button_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level2.tscn")

func _on_level_3_button_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level3.tscn")

func _on_level_4_button_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level4.tscn")

func _on_level_5_button_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level5.tscn")
