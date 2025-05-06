# GameManager.gd - À placer dans un autoload
extends Node

# Référence à votre scène d'écran de saisie de nom d'utilisateur
var username_input_scene = preload("res://scenes/high_score_dialog.tscn")
var current_mini_game_id = -1
var current_high_score = 0.0
var username_input_instance = null

func _ready():
	# Connecter le signal du LeaderboardManager
	LeaderboardManager_node.top_score_achieved.connect(_on_top_score_achieved)

# Appelé quand un score est assez élevé pour entrer dans le top
func _on_top_score_achieved(mini_game_id, score):
	current_mini_game_id = mini_game_id
	current_high_score = score
	
	# Créer l'écran de saisie du nom d'utilisateur
	username_input_instance = username_input_scene.instantiate()
	get_tree().current_scene.add_child(username_input_instance)
	
	# Configurer l'écran avec le score et le niveau
	username_input_instance.setup(score, LeaderboardManager_node.mini_games[mini_game_id])
	
	# Connecter le signal pour recevoir le nom d'utilisateur
	username_input_instance.username_submitted.connect(_on_username_submitted)

# Appelé quand l'utilisateur soumet son nom
func _on_username_submitted(username, score):
	# Assurez-vous que le score est le même que celui stocké
	assert(score == current_high_score)
	
	# Soumettre le score au leaderboard
	LeaderboardManager_node.submit_score(current_mini_game_id, username, current_high_score)
	
	# Réinitialiser les variables
	current_mini_game_id = -1
	current_high_score = 0.0
	username_input_instance = null
