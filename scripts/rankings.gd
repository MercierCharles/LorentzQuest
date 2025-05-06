extends Control

@onready var scroll_container_5: ScrollContainer = $HBoxContainer1/ScrollContainer1
@onready var scroll_container_6: ScrollContainer = $HBoxContainer2/ScrollContainer2
@onready var scroll_container_7: ScrollContainer = $HBoxContainer3/ScrollContainer3
@onready var scores_container_5: VBoxContainer = $HBoxContainer1/ScrollContainer1/VBoxContainer
@onready var scores_container_6: VBoxContainer = $HBoxContainer2/ScrollContainer2/VBoxContainer
@onready var scores_container_7: VBoxContainer = $HBoxContainer3/ScrollContainer3/VBoxContainer

# Nombre maximum de caractères pour les noms d'utilisateur
const MAX_USERNAME_LENGTH = 15
var nbr_scores = 100

# Précharger la police
const TYPE_LIGHT_SANS_KV_84P = preload("res://assets/fonts/TypeLightSans-KV84p.otf")

func _ready():
	# Connexion au signal top_scores_received
	LeaderboardManager_node.top_scores_received.connect(_on_top_scores_received)
	
	# Demander les scores pour les trois mini-jeux
	LeaderboardManager_node.get_top_scores(0)
	LeaderboardManager_node.get_top_scores(1)
	LeaderboardManager_node.get_top_scores(2)

# Fonction pour tronquer les noms d'utilisateur trop longs
func truncate_username(username: String) -> String:
	if username.length() > MAX_USERNAME_LENGTH:
		return username.substr(0, MAX_USERNAME_LENGTH - 3) + "..."
	return username

func _on_top_scores_received(mini_game_id, scores):
	# Déterminer quel container mettre à jour
	var container
	match mini_game_id:
		0:
			container = scores_container_5
		1:
			container = scores_container_6
		2:
			container = scores_container_7
	
	# Effacer les anciens scores
	for child in container.get_children():
		child.queue_free()
	
	# Limiter le nombre de scores à afficher
	var count = min(scores.size(), nbr_scores)
	
	# Si aucun score disponible
	if count == 0:
		var label = Label.new()
		label.text = "No scores"
		
		# Appliquer la police personnalisée
		label.add_theme_font_override("font", TYPE_LIGHT_SANS_KV_84P)
		label.add_theme_font_size_override("font_size", 28)  # Taille de police à ajuster
		
		container.add_child(label)
		return
	
	# Ajouter chaque score comme un label individuel
	for i in range(count):
		if i < scores.size():
			var label = Label.new()
			
			# Tronquer le nom d'utilisateur s'il est trop long
			var shortened_name = truncate_username(scores[i].username)
			
			# Format différent selon l'ID du mini-jeu
			if mini_game_id == 0:
				label.text = "%d. %s: %.2f s" % [i + 1, shortened_name, scores[i].score]
			else:
				label.text = "%d. %s: %d" % [i + 1, shortened_name, int(scores[i].score)]
			
			# Appliquer la police personnalisée à chaque label
			label.add_theme_font_override("font", TYPE_LIGHT_SANS_KV_84P)
			
			# Taille de police
			if i < 3:
				label.add_theme_font_size_override("font_size", 28)  # Plus grande pour les 3 premiers
				
				# Couleurs spéciales pour les 3 premiers
				var colors = [Color.GOLD, Color.SILVER, Color(0.8, 0.5, 0.2)]  # Or, Argent, Bronze
				label.add_theme_color_override("font_color", colors[i])
			else:
				label.add_theme_font_size_override("font_size", 24)  # Taille normale
			
			container.add_child(label)

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
