extends Node

@onready var leaderboard_manager = $LeaderboardManager
var current_level_name: String = ""

func on_level_completed(level_name: String, score: int) -> void:
	current_level_name = level_name

	# Vérifier que leaderboard_manager est bien initialisé
	if leaderboard_manager != null:
		var is_high = await is_high_score(level_name, score)
		if is_high:
			show_high_score_dialog(level_name, score)
		else:
			proceed_to_next_screen()
	else:
		print("Erreur : leaderboard_manager n'est pas initialisé.")

	var is_high = await is_high_score(level_name, score)
	if is_high:
		show_high_score_dialog(level_name, score)
	else:
		proceed_to_next_screen()


func is_high_score(level_name: String, score: int) -> bool:
	var scores = await leaderboard_manager.get_scores(level_name)
	if scores.size() < 5:
		return true
	var lowest_score = scores[scores.size() - 1].score
	return score > lowest_score


func show_high_score_dialog(level_name: String, score: int) -> void:
	var high_score_dialog = preload("res://scenes/high_score_dialog.tscn").instantiate()
	high_score_dialog.setup(score, level_name)
	high_score_dialog.username_submitted.connect(_on_username_submitted)
	get_tree().current_scene.add_child(high_score_dialog)


func _on_username_submitted(username: String, score: int) -> void:
	await leaderboard_manager.send_score_to_firebase(username, current_level_name, score)
	proceed_to_next_screen()


func proceed_to_next_screen():
	# À toi de définir le comportement
	print("Passage à l’écran suivant.")
