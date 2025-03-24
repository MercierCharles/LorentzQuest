extends CanvasLayer

func _ready() -> void:
	visible = false  # Cache WinSceneUI au début

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/level_selector.tscn")

func _on_next_level_button_pressed() -> void:
	get_tree().paused = false

	# Récupérer le chemin de la scène actuelle
	var current_scene_path = get_tree().current_scene.scene_file_path  # Ex: "res://scenes/level2.tscn"

	# Expression régulière pour capturer le numéro du niveau
	var regex = RegEx.new()
	regex.compile("res://scenes/level(\\d+)\\.tscn")  # Capture un nombre après "level"
	
	var result = regex.search(current_scene_path)
	
	if result:
		var current_level = int(result.get_string(1))  # Extrait "2" de "level2"
		var next_level = current_level + 1
		var next_scene_path = "res://scenes/level" + str(next_level) + ".tscn"

		# Vérifier si le fichier existe avant de changer de scène
		if ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
		else:
			print("Niveau suivant introuvable:", next_scene_path)  # Debug
	else:
		print("Impossible de détecter le niveau actuel:", current_scene_path)
