extends Control

@onready var scroll_container_5: ScrollContainer = $HBoxContainer1/ScrollContainer1
@onready var scroll_container_6: ScrollContainer = $HBoxContainer2/ScrollContainer2
@onready var scroll_container_7: ScrollContainer = $HBoxContainer3/ScrollContainer3
@onready var scores_container_5: VBoxContainer = $HBoxContainer1/ScrollContainer1/VBoxContainer
@onready var scores_container_6: VBoxContainer = $HBoxContainer2/ScrollContainer2/VBoxContainer
@onready var scores_container_7: VBoxContainer = $HBoxContainer3/ScrollContainer3/VBoxContainer
@onready var back_button: Button = $ButtonBack
@onready var label_1: Label = $Label1
@onready var label_2: Label = $Label2
@onready var label_3: Label = $Label3

# Variables pour la navigation à la manette
var current_container: ScrollContainer
var scroll_speed: float = 600.0
var selected_column: int = 0  # 0=gauche, 1=milieu, 2=droite
var is_on_button: bool = false
var scroll_containers = []
var button_activation_cooldown: float = 0.3  # Temps en secondes pour éviter les activations accidentelles
var current_cooldown: float = 0.0

# Variables pour l'animation des labels
var labels = []
var label_animation_speed: float = 5.0  # Vitesse de l'animation
var label_normal_scale: Vector2 = Vector2(1.0, 1.0)
var label_highlighted_scale: Vector2 = Vector2(1.3, 1.3)  # 30% plus grand

# Nombre maximum de caractères pour les noms d'utilisateur
const MAX_USERNAME_LENGTH = 15
var nbr_scores = 100

# Précharger la police
const TYPE_LIGHT_SANS_KV_84P = preload("res://assets/fonts/TypeLightSans-KV84p.otf")

func _ready():
	# Configuration de la navigation à la manette
	scroll_containers = [scroll_container_5, scroll_container_6, scroll_container_7]
	current_container = scroll_containers[0]
	
	# Configuration des labels pour l'animation
	labels = [label_1, label_2, label_3]
	for label in labels:
		label.scale = label_normal_scale
		# Configurer le pivot au centre pour une animation centrée
		label.pivot_offset = label.size / 2
	
	# Mettre le focus sur le ScrollContainer actif
	current_container.grab_focus()
	
	# Configurer le bouton de retour
	back_button.focus_mode = Control.FOCUS_ALL
	
	# Connexion au signal top_scores_received
	LeaderboardManager_node.top_scores_received.connect(_on_top_scores_received)
	
	# Demander les scores pour les trois mini-jeux
	LeaderboardManager_node.get_top_scores(0)
	LeaderboardManager_node.get_top_scores(1)
	LeaderboardManager_node.get_top_scores(2)
	
	# Effet visuel pour montrer quel conteneur est sélectionné
	_highlight_current_container()

func _process(delta: float) -> void:
	# Gestion du cooldown pour éviter les activations accidentelles
	if current_cooldown > 0:
		current_cooldown -= delta
		
	# Animation continue des labels
	_update_label_animations(delta)
	
	# Navigation entre les colonnes avec la manette
	if Input.is_action_just_pressed("ui_right") and not is_on_button:
		if selected_column < 2:
			selected_column += 1
			current_container = scroll_containers[selected_column]
			_highlight_current_container()
	
	elif Input.is_action_just_pressed("ui_left") and not is_on_button:
		if selected_column > 0:
			selected_column -= 1
			current_container = scroll_containers[selected_column]
			_highlight_current_container()
	
	# Gestion du défilement vertical et navigation vers le bouton retour
	if not is_on_button:
		# Navigation spéciale vers le bouton avec ui_focus_next (touche Tab ou équivalent manette)
		if Input.is_action_just_pressed("ui_focus_next") and current_cooldown <= 0:
			is_on_button = true
			back_button.grab_focus()
			_unhighlight_all_containers()
			current_cooldown = button_activation_cooldown
			return
		
		# Vérifier si la scrollbar verticale existe et est visible
		var v_scrollbar = current_container.get_v_scroll_bar()
		if v_scrollbar and v_scrollbar.visible:
			var at_bottom = current_container.scroll_vertical >= v_scrollbar.max_value - current_container.size.y
			var at_top = current_container.scroll_vertical <= 0
			
			# Défilement vers le bas
			if Input.is_action_pressed("ui_down"):
				# Si on est déjà au bas de la liste et qu'on appuie sur down
				if at_bottom and current_cooldown <= 0:
					is_on_button = true
					back_button.grab_focus()
					_unhighlight_all_containers()
					current_cooldown = button_activation_cooldown
				else:
					# Défilement normal
					current_container.scroll_vertical += scroll_speed * delta
			
			# Défilement vers le haut
			elif Input.is_action_pressed("ui_up"):
				current_container.scroll_vertical -= scroll_speed * delta
	
	# Retour aux conteneurs de score depuis le bouton
	elif is_on_button and (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_focus_prev")):
		is_on_button = false
		back_button.release_focus()
		current_container = scroll_containers[selected_column]
		_highlight_current_container()
		current_cooldown = button_activation_cooldown
		
	
	# Validation (bouton A/Croix)
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_button:
			_on_button_pressed()
		
	if Input.is_action_just_pressed("back"):
		_on_button_pressed()
			
	

func _highlight_current_container() -> void:
	# Réinitialiser tous les conteneurs
	_unhighlight_all_containers()
	
	# Mettre en évidence le conteneur actif
	var frame = current_container.get_parent()
	if frame is Control:  # Ajouter un parent de type Panel ou Control pour cet effet
		frame.modulate = Color(1.2, 1.2, 1.2)  # Plus lumineux
		
	# Mettre à jour la cible d'animation pour les labels
	for i in range(labels.size()):
		if i == selected_column:
			labels[i].add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Teinte dorée
		else:
			labels[i].remove_theme_color_override("font_color")

func _unhighlight_all_containers() -> void:
	for container in scroll_containers:
		var frame = container.get_parent()
		if frame is Control:
			frame.modulate = Color(1.0, 1.0, 1.0)  # Normal
	
func _update_label_animations(delta: float) -> void:
	# Mettre à jour l'échelle de chaque label en fonction de s'il est sélectionné
	for i in range(labels.size()):
		var target_scale = label_normal_scale
		if i == selected_column and not is_on_button:
			target_scale = label_highlighted_scale
		
		# Animation douce vers la taille cible
		labels[i].scale = labels[i].scale.lerp(target_scale, delta * label_animation_speed)

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
