extends Node

const BASE_URL = "https://lorentz-quest-default-rtdb.europe-west1.firebasedatabase.app/"

# Fonction pour trier les scores (du plus haut au plus bas)
func _sort_scores(a, b):
	return int(b["score"]) - int(a["score"])

func get_scores(level: String) -> Array:
	var http := HTTPRequest.new()
	add_child(http)
	await get_tree().create_timer(0.01).timeout

	var url = BASE_URL + "leaderboard/%s.json" % level
	var error = http.request(url)

	if error != OK:
		print("Erreur lors de la requête GET : ", error)
		return []

	var result = await http.request_completed
	var status = result[0]
	var response_code = result[1]
	var body = result[3]

	if status != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Erreur de connexion : ", status, " code : ", response_code)
		http.queue_free()
		return []

	var scores = []
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json is Dictionary:
		for id in json:
			scores.append(json[id])

		scores.sort_custom(Callable(self, "_sort_scores"))
	else:
		print("Erreur de parsing JSON : ", body.get_string_from_utf8())

	http.queue_free()
	return scores



# Envoie un score à Firebase et met à jour le top 5
func send_score_to_firebase(username: String, level: String, score: int) -> bool:
	if username.strip_edges() == "" or level.strip_edges() == "" or score < 0:
		print("Erreur: données invalides")
		return false

	var http := HTTPRequest.new()
	add_child(http)
	await http.ready

	var get_url = BASE_URL + "leaderboard/%s.json" % level
	var success := false

	# GET existants
	var error := http.request(get_url, [], HTTPClient.METHOD_GET)
	if error != OK:
		print("Erreur lors de la requête GET: ", error)
		http.queue_free()
		return false

	var response = await http.request_completed
	var result = response[0]
	var response_code = response[1]
	var body = response[3]

	var scores := []
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json_result = JSON.parse_string(body.get_string_from_utf8())
		if json_result is Dictionary:
			for id in json_result:
				scores.append(json_result[id])

	# Ajouter le nouveau score
	var new_entry = {
		"username": username,
		"score": score,
		"timestamp": Time.get_unix_time_from_system()
	}
	scores.append(new_entry)
	scores.sort_custom(Callable(self, "_sort_scores"))
	if scores.size() > 5:
		scores = scores.slice(0, 5)

	# Construire le JSON pour PUT
	var new_data := {}
	for i in range(scores.size()):
		new_data["entry_%d" % i] = scores[i]

	var put_url = BASE_URL + "leaderboard/%s.json" % level
	var json_data = JSON.stringify(new_data)

	# Nouvelle requête PUT
	error = http.request(put_url, [], HTTPClient.METHOD_PUT, json_data)
	if error != OK:
		print("Erreur lors de la requête PUT: ", error)
	else:
		response = await http.request_completed
		result = response[0]
		response_code = response[1]
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			print("Score envoyé avec succès !")
			success = true
		else:
			print("Erreur lors de l'envoi du score: ", result, " code: ", response_code)

	http.queue_free()
	return success
