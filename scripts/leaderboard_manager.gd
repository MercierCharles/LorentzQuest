# Modification du LeaderboardManager pour gérer des scores décimaux et vérifier le top
extends Node

class_name LeaderboardManager

# Configuration Firebase
const FIREBASE_URL = "https://lorentz-quest-default-rtdb.europe-west1.firebasedatabase.app"

# Les noms des mini-jeux
var mini_games = ["CoulombForce", "ElectricField", "MagneticField"]
var nbr_scores = 100

# HTTPRequest nodes pour les interactions avec Firebase
var http_get_request
var http_post_request

# Signal émis quand un score est assez élevé pour le top 
signal top_score_achieved(mini_game_id, score)

func _ready():
	# Initialisation des objets HTTPRequest
	http_get_request = HTTPRequest.new()
	http_post_request = HTTPRequest.new()
	add_child(http_get_request)
	add_child(http_post_request)
	http_get_request.request_completed.connect(_on_get_request_completed)
	http_post_request.request_completed.connect(_on_post_request_completed)

# Fonction principale: vérifie d'abord si le score est dans le top 
func check_score(mini_game_id, score):
	if mini_game_id < 0 or mini_game_id >= mini_games.size():
		printerr("ID de mini-jeu invalide")
		return
		
	var game_name = mini_games[mini_game_id]
	_check_if_high_score(game_name, score, mini_game_id)

# Vérifie si le score est assez élevé pour le top
func _check_if_high_score(game_name, score, mini_game_id):
	var url = FIREBASE_URL + "/leaderboards/" + game_name + ".json"
	var check_request = HTTPRequest.new()
	add_child(check_request)
	
	check_request.request_completed.connect(
		func(result, response_code, headers, body):
			var is_high_score = false
			
			if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
				var json = JSON.new()
				var error = json.parse(body.get_string_from_utf8())
				
				if error == OK:
					var leaderboard = json.get_data()
					
					# Si le leaderboard est vide ou a moins de nbr_scores entrées, c'est automatiquement un high score
					if leaderboard == null or (typeof(leaderboard) == TYPE_ARRAY and leaderboard.size() < nbr_scores):
						is_high_score = true
					else:
						# Convertir en array si c'est un dictionnaire
						var scores_array = []
						if typeof(leaderboard) == TYPE_DICTIONARY:
							for key in leaderboard:
								scores_array.append(leaderboard[key])
						else:
							scores_array = leaderboard
						
						# Trier les scores
						scores_array.sort_custom(_sort_by_score)
						
						# Vérifier si le score actuel est meilleur que le dernier du top
						if scores_array.size() < nbr_scores or score > scores_array[scores_array.size() - 1].score:
							is_high_score = true
			else:
				# Si erreur lors de la récupération, supposer que c'est un high score
				is_high_score = true
			
			if is_high_score:
				# Émettre le signal pour afficher l'écran de saisie
				top_score_achieved.emit(mini_game_id, score)
			
			check_request.queue_free()
	)
	
	check_request.request(url)

# Fonction appelée après que l'utilisateur a entré son nom
func submit_score(mini_game_id, username, score):
	if mini_game_id < 0 or mini_game_id >= mini_games.size():
		printerr("ID de mini-jeu invalide")
		return
		
	var game_name = mini_games[mini_game_id]
	# Récupération du leaderboard actuel
	_get_leaderboard(game_name, username, score)

# Récupère le leaderboard actuel
func _get_leaderboard(game_name, username, score):
	var url = FIREBASE_URL + "/leaderboards/" + game_name + ".json"
	var error = http_get_request.request(url)
	if error != OK:
		printerr("Erreur lors de la requête HTTP: ", error)
		return
	
	# Stockage temporaire des données pour le callback
	http_get_request.set_meta("game_name", game_name)
	http_get_request.set_meta("username", username)
	http_get_request.set_meta("score", score)

# Callback après avoir récupéré le leaderboard
func _on_get_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		printerr("Échec de la récupération du leaderboard: ", response_code)
		return
		
	var game_name = http_get_request.get_meta("game_name")
	var username = http_get_request.get_meta("username")
	var score = http_get_request.get_meta("score")
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	var leaderboard = []
	
	if error == OK and response_code == 200:
		leaderboard = json.get_data()
		if leaderboard == null:
			leaderboard = []
	
	# Vérifier si le score doit être ajouté au top
	_update_leaderboard(game_name, username, score, leaderboard)

# Met à jour le leaderboard si nécessaire
func _update_leaderboard(game_name, username, score, leaderboard):
	# Convertir le leaderboard en tableau si c'est un dictionnaire
	var scores_array = []
	if typeof(leaderboard) == TYPE_DICTIONARY:
		for key in leaderboard:
			scores_array.append(leaderboard[key])
	else:
		scores_array = leaderboard
	
	# Ajouter le nouveau score
	var entry = {
		"username": username,
		"score": score, # Le score est déjà en format décimal
		"timestamp": Time.get_unix_time_from_system()
	}
	
	scores_array.append(entry)
	
	# Trier par score (du plus haut au plus bas)
	scores_array.sort_custom(_sort_by_score)
	
	# Garder seulement le top nbr_scores
	if scores_array.size() > nbr_scores:
		scores_array.resize(nbr_scores)
	
	# Enregistrer le nouveau leaderboard
	_save_leaderboard(game_name, scores_array)

# Fonction de comparaison pour le tri
func _sort_by_score(a, b):
	return a.score > b.score

# Enregistre le leaderboard mis à jour
func _save_leaderboard(game_name, leaderboard):
	var url = FIREBASE_URL + "/leaderboards/" + game_name + ".json"
	var headers = ["Content-Type: application/json"]
	var json_string = JSON.stringify(leaderboard)
	
	var error = http_post_request.request(url, headers, HTTPClient.METHOD_PUT, json_string)
	if error != OK:
		printerr("Erreur lors de la sauvegarde du leaderboard: ", error)
		return
	
	http_post_request.set_meta("game_name", game_name)

# Callback après avoir sauvegardé le leaderboard
func _on_post_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		printerr("Échec de la sauvegarde du leaderboard: ", response_code)
		return
		
	var game_name = http_post_request.get_meta("game_name")
	print("Leaderboard mis à jour pour " + game_name)

# Dans LeaderboardManager
signal top_scores_received(mini_game_id, scores)

func get_top_scores(mini_game_id):
	if mini_game_id < 0 or mini_game_id >= mini_games.size():
		printerr("ID de mini-jeu invalide")
		return
		
	var game_name = mini_games[mini_game_id]
	var fetch_request = HTTPRequest.new()
	add_child(fetch_request)
	
	fetch_request.request_completed.connect(
		func(result, response_code, headers, body):
			var scores = []
			if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
				var json = JSON.new()
				var error = json.parse(body.get_string_from_utf8())
				if error == OK:
					var data = json.get_data()
					if data != null:
						if typeof(data) == TYPE_DICTIONARY:
							for key in data:
								scores.append(data[key])
						elif typeof(data) == TYPE_ARRAY:
							scores = data
						
						# Assurer que les scores sont triés
						scores.sort_custom(_sort_by_score)
			
			# Émettre le signal avec les résultats
			top_scores_received.emit(mini_game_id, scores)
			fetch_request.queue_free()
	)
	
	var url = FIREBASE_URL + "/leaderboards/" + game_name + ".json"
	fetch_request.request(url)
