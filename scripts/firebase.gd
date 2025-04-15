extends Node

# Envoie un score à Firebase et met à jour le top 5 pour n'importe quel niveau
func send_score_to_firebase(username: String, level: String, score: int) -> bool:
	# Validation des entrées
	if username.strip_edges() == "" or level.strip_edges() == "" or score < 0:
		print("Erreur: données invalides")
		return false
	
	var http := HTTPRequest.new()
	add_child(http)
	await get_tree().process_frame
	
	# L'URL complète de ta base Firebase
	var base_url = "https://lorentz-quest-default-rtdb.europe-west1.firebasedatabase.app/"
	var get_url = base_url + "leaderboard/%s.json" % level
	
	# Variable pour suivre le succès de l'opération
	var success = false
	
	# Requête GET pour récupérer les scores existants
	var error = http.request(get_url, [], HTTPClient.METHOD_GET)
	if error != OK:
		print("Erreur lors de la requête GET: ", error)
		http.queue_free()
		return false
	
	var response = await http.request_completed
	var result = response[0]
	var response_code = response[1]
	var headers = response[2]
	var body = response[3]
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Erreur de connexion: ", result, " code: ", response_code)
	else:
		var json_result = JSON.parse_string(body.get_string_from_utf8())
		var scores = []
		
		if json_result is Dictionary:
			# Récupérer les scores existants dans Firebase
			for id in json_result:
				scores.append(json_result[id])
		
		# Ajouter le nouveau score seulement si il mérite sa place
		var new_entry = {
			"username": username,
			"score": score, 
			"timestamp": Time.get_unix_time_from_system()
		}
		
		# Ajouter ce score seulement si c'est un des meilleurs (on garde les 5 meilleurs)
		if scores.size() < 5 or score > scores.min().get("score", 0):
			scores.append(new_entry)
		
		# Trier les scores du plus grand au plus petit
		scores.sort_custom(Callable(self, "_sort_scores"))
		
		# Garder seulement les 5 meilleurs scores
		if scores.size() > 5:
			scores = scores.slice(0, 5)
			
		# Préparer les données à envoyer vers Firebase
		var new_data := {}
		for i in range(scores.size()):
			new_data["entry_%d" % i] = scores[i]
			
		# Requête PUT pour mettre à jour les scores dans Firebase
		var put_url = base_url + "leaderboard/%s.json" % level
		var json_data = JSON.stringify(new_data)
		
		error = http.request(put_url, [], HTTPClient.METHOD_PUT, json_data)
		if error != OK:
			print("Erreur lors de la requête PUT: ", error)
		else:
			response = await http.request_completed
			result = response[0]
			response_code = response[1]
			
			if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
				print("Score envoyé avec succès!")
				success = true
			else:
				print("Erreur lors de l'envoi du score: ", result, " code: ", response_code)
	
	# Libérer la ressource
	http.queue_free()
	return success

# Fonction de tri des scores (du plus grand au plus petit)
func _sort_scores(a, b):
	return int(b["score"]) - int(a["score"])
