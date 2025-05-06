extends Control

func _ready():
	MusicPlayer.stop()

func _on_texture_button_1_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level1_mod.tscn")

func _on_texture_button_2_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level6.tscn")


func _on_texture_button_3_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level5.tscn")


func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/first_screen.tscn")


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rankings.tscn")
