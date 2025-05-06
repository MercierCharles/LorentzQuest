extends Node2D

@onready var h_slider_angle: HSlider = $CanvasLayer/Sliders/ControlSliders/HSliderAngle
@onready var h_slider_norm: HSlider = $CanvasLayer/Sliders/ControlSliders/HSliderNorm
@onready var proton_lev_2: RigidBody2D = $ProtonLev2
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var fail_label: Label = $GameOverUI/FailLabel
@onready var lost_label: Label = $GameOverUI/LostLabel
@onready var theory_ui: CanvasLayer = $TheoryUI
@onready var play_button: Button = $TheoryUI/PlayButton
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var section_container: Node2D = $SectionContainer

const GRID_SPACING = 400.0
const FIELD_SCALE = 150.0
const ARROW_SCENE = preload("res://scenes/arrow_2d.tscn")

# Précharger les différentes sections de chemin
const SECTION_SCENES = [
	preload("res://scenes/sections/section_1adri.tscn"),
	preload("res://scenes/sections/section_2adri.tscn"),
	preload("res://scenes/sections/section_3adri.tscn"),
	preload("res://scenes/sections/section_rodo_1.tscn"),
	preload("res://scenes/sections/section_rodo_2.tscn"),
	# Ajoutez d'autres sections selon vos besoins
]

var arrows = []
var elapsed_time = 0.0
var is_running = true
var current_score = 0
var active_sections = []
var player_position = Vector2.ZERO
var section_length = 8625  # Longueur exacte de chaque section (8625 pixels)
var section_spawn_distance = 17250  # Distance à laquelle de nouvelles sections sont générées (2 sections d'avance)
var section_despawn_distance = -8625  # Distance à laquelle les sections sont supprimées (une section en arrière)

var left_boundary = null
var right_boundary = null
var base_boundary_speed = 100.0  # Vitesse initiale des lignes en pixels par seconde
var current_boundary_speed = 100.0  # Vitesse actuelle des lignes
var boundary_speed_increase = 5.0  # Augmentation de la vitesse par seconde
var boundary_width = 20.0    # Épaisseur des lignes
var boundary_spacing = 3300.0  # Distance entre les deux lignes
var boundary_start_x = -1650.0  # Position de départ pour la ligne de gauche

# Variables à ajouter au début de la classe
var transformation_lines = []  # Liste pour stocker les lignes de transformation
var transformation_line_width = 10.0  # Épaisseur de la ligne violette
var is_electron = false  # État actuel du joueur (proton par défaut)
const ELECTRON_SCENE = preload("res://scenes/electron_level3.tscn")  # Précharger la scène de l'électron

# Ajouter cette variable globale
var camera_node = null

# Ajoutez cette variable aux variables globales
var last_transform_position = Vector2.ZERO
var transform_cooldown = 0.5  # Temps minimum entre deux transformations
var transforming_areas = []  # Liste pour suivre les zones de transformation

func _create_transformation_line(position_x):
	var transform_line = Line2D.new()
	transform_line.default_color = Color(0.8, 0, 1, 0.8)  # Violet semi-transparent
	transform_line.width = transformation_line_width
	transform_line.add_point(Vector2(position_x, -2000))  # Point haut
	transform_line.add_point(Vector2(position_x, 2000))   # Point bas
	add_child(transform_line)
	transformation_lines.append(transform_line)
	
	# Ajoutons également une Area2D pour la détection de collision
	var area = Area2D.new()
	area.position = Vector2(position_x, 0)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.extents = Vector2(transformation_line_width/2, 2000)  # Largeur de la ligne, hauteur de 4000
	shape.shape = rect
	area.add_child(shape)
	
	# Connecter le signal de collision
	area.body_entered.connect(_on_transform_area_entered.bind(transform_line, area))
	
	add_child(area)
	transforming_areas.append(area)  # Ajouter à la liste de suivi
	
	return transform_line

# Nouvelle fonction pour gérer les entrées dans la zone de transformation
func _on_transform_area_entered(body, line, area):
	if body == proton_lev_2:
		var current_time = elapsed_time
		var current_position = proton_lev_2.global_position
		
		# Vérifier si nous ne sommes pas en cooldown et si nous avons bougé assez loin
		if current_time > (proton_lev_2.get_meta("last_transform_time", 0) + transform_cooldown) and \
		   current_position.distance_to(last_transform_position) > 50:
			
			_transform_player()
			proton_lev_2.set_meta("last_transform_time", current_time)
			last_transform_position = current_position
			
			# Supprimer la ligne de transformation
			if line in transformation_lines:
				var index = transformation_lines.find(line)
				if index != -1:
					transformation_lines.remove_at(index)
				line.queue_free()
			
			# Supprimer également l'Area2D
			if area in transforming_areas:
				var index = transforming_areas.find(area)
				if index != -1:
					transforming_areas.remove_at(index)
				area.queue_free()

func _create_boundaries():
	# Créer uniquement la ligne de gauche
	left_boundary = Line2D.new()
	left_boundary.default_color = Color(1, 0, 0, 0.8)  # Rouge semi-transparent
	left_boundary.width = boundary_width
	left_boundary.add_point(Vector2(boundary_start_x, -2000))  # Point haut
	left_boundary.add_point(Vector2(boundary_start_x, 2000))   # Point bas
	add_child(left_boundary)
	
	# On ne crée plus la ligne de droite
	right_boundary = null

func _ready():
	var music
	
	if GameState.selected_artist == "Bad Bunny" :
		music = load("res://assets/music/Bad Bunny/BAD BUNNY x JHAY CORTEZ - CÓMO SE SIENTE REMIX  LAS QUE NO IBAN A SALIR (Audio Oficial).mp3")
	elif GameState.selected_artist == "Morad" :
		music = load("res://assets/music/Morad/BENY JR FT MORAD - SIGUE (K y B Capítulo 1) [VIDEO OFICIAL].mp3")
	elif GameState.selected_artist == "Myke Towers" :
		music = load("res://assets/music/Myke Towers/La Forma En Que Me Miras - Super Yei x Myke Towers x Sammy x Lenny Tavarez x Rafa Pabon x Jone Quest.mp3")
	elif GameState.selected_artist == "Ozuna":
		music = load("res://assets/music/Ozuna/Ozuna - Baila Baila Baila (Remix) Feat. Daddy Yankee, J Balvin, Farruko, Anuel AA (Audio Oficial).mp3")
		
	MusicPlayer.play_music(music)
	
	RenderingServer.set_default_clear_color(Color.BLACK)
	h_slider_norm.value_changed.connect(_on_slider_changed)
	h_slider_angle.value_changed.connect(_on_slider_changed)
	_generate_arrows()
	_create_boundaries()  # Créer les lignes verticales
	
		# Sauvegarder la référence à la caméra dès le début
	for child in proton_lev_2.get_children():
		if child is Camera2D:
			camera_node = child
			break
	
	# Ajouter un ScoreLabel s'il n'existe pas déjà
	if not score_label:
		score_label = Label.new()
		score_label.text = "Score: 0"
		score_label.position = Vector2(20, 60)  # Position sous le time_label
		$CanvasLayer.add_child(score_label)
	else:
		score_label.text = "Score: 0"
		score_label.visible = true
	
	# Créer un conteneur de sections s'il n'existe pas
	if not section_container:
		section_container = Node2D.new()
		section_container.name = "SectionContainer"
		add_child(section_container)
	
	if GameState.entering_from_menu:
		GameState.has_seen_theory_level2 = false
		GameState.entering_from_menu = false
	
	# Show theory only if it hasn't been seen
	if GameState.has_seen_theory_level2:
		theory_ui.visible = false
		get_tree().paused = false
		is_running = true
		_start_infinite_level()
	else:
		theory_ui.visible = true
		theory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true

# Ajouter cette constante pour la section de départ
const START_SECTION = preload("res://scenes/sections/section_prompt.tscn")

# Modifier la fonction _start_infinite_level
func _start_infinite_level():
	# Créer d'abord la section de départ, à gauche de la première section
	var start_section = START_SECTION.instantiate()
	start_section.global_position = Vector2(-section_length, 0)  # Position négative pour être à gauche
	section_container.add_child(start_section)
	active_sections.append(start_section)
	
	# Connecter le signal de checkpoint si la section en a un
	if start_section.has_signal("checkpoint_reached"):
		start_section.checkpoint_reached.connect(_on_checkpoint_reached)
	
	# Puis générer les premières sections aléatoires commençant à la position 0
	# On vide active_sections pour que la première section aléatoire soit à la position 0
	active_sections.clear()
	
	# Générer les sections aléatoires à partir de la position 0
	for i in range(3):  # On génère 3 sections aléatoires comme avant
		_spawn_next_section()
	
	# Rajouter la section de départ à active_sections pour qu'elle soit bien gérée
	active_sections.insert(0, start_section)


func _check_boundary_collision():
	# Vérifier si le proton est à gauche de la ligne gauche
	var proton_x = proton_lev_2.global_position.x
	var left_x = left_boundary.points[0].x
	
	# Si le proton est à gauche de la ligne gauche
	if proton_x < left_x:
		game_over()

func _process(delta):
	if is_running:
		elapsed_time += delta
		
		# Mise à jour de la position du joueur
		player_position = proton_lev_2.global_position
		
		# Mettre à jour le score en fonction de la position X du joueur
		current_score = int(player_position.x)/100
		score_label.text = "Score: %d" % current_score
		
		# Augmenter la vitesse des limites avec le temps
		current_boundary_speed = base_boundary_speed + (boundary_speed_increase * elapsed_time)
		
		# Gestion intelligente de la limite gauche
		var left_points = left_boundary.points
		var current_left_x = left_points[0].x
		
		# Déplacer normalement la ligne à sa vitesse actuelle
		var displacement = current_boundary_speed * delta
		left_points[0].x += displacement
		left_points[1].x += displacement
		
		# Si la ligne est trop loin derrière le joueur (hors de l'écran), la repositionner
		var max_distance = 2200  # Distance maximale avant de repositionner la ligne
		if player_position.x - current_left_x > max_distance:
			left_points[0].x = player_position.x - max_distance
			left_points[1].x = player_position.x - max_distance
		
		left_boundary.points = left_points
		
		# Vérifier les collisions avec les lignes de transformation
		_check_transformation_collision()
		
		# Vérifier les collisions avec les limites
		_check_boundary_collision()
		
		# Mettre à jour la grille de flèches autour du joueur
		_update_arrow_grid()
		
		# Vérifier si nous devons générer une nouvelle section
		_check_section_generation()
		
		# Vérifier si le joueur est tombé ou sorti des limites
		if _is_player_out_of_bounds():
			game_over()

var last_section_index = -1

# Variables à ajouter au début de la classe
var grid_min_x = -1000
var grid_max_x = 1000
var grid_min_y = -1000
var grid_max_y = 1000
var visible_arrows = {}  # Dictionnaire pour stocker les flèches visibles par leur position en grille

# Remplacer la fonction _generate_arrows() existante
func _generate_arrows():
	# Ne rien faire ici initialement, les flèches seront générées dynamiquement
	pass

# Nouvelle fonction pour mettre à jour les flèches dynamiquement
func _update_arrow_grid():
	var player_grid_x = int(player_position.x / GRID_SPACING)
	var view_distance_x = 12  # Nombre de cellules visibles horizontalement
	var view_distance_y = 6   # Nombre de cellules visibles verticalement
	
	# Définir les limites de la grille visible actuelle
	var new_grid_min_x = player_grid_x - view_distance_x
	var new_grid_max_x = player_grid_x + view_distance_x
	var new_grid_min_y = -view_distance_y
	var new_grid_max_y = view_distance_y
	
	# Créer des flèches pour les nouvelles cellules visibles
	for x in range(new_grid_min_x, new_grid_max_x + 1):
		for y in range(new_grid_min_y, new_grid_max_y + 1):
			var grid_pos = Vector2(x, y)
			if not visible_arrows.has(grid_pos):
				var arrow = ARROW_SCENE.instantiate()
				arrow.global_position = Vector2(x * GRID_SPACING, y * GRID_SPACING)
				add_child(arrow)
				visible_arrows[grid_pos] = arrow
	
	# Mettre à jour toutes les flèches visibles
	var intensity = h_slider_norm.value
	var angle = h_slider_angle.value
	
	for grid_pos in visible_arrows.keys():
		var arrow = visible_arrows[grid_pos]
		# Vérifier si la flèche est encore dans la zone visible
		if grid_pos.x < new_grid_min_x or grid_pos.x > new_grid_max_x or \
		   grid_pos.y < new_grid_min_y or grid_pos.y > new_grid_max_y:
			# Supprimer les flèches hors de la zone visible
			arrow.queue_free()
			visible_arrows.erase(grid_pos)
		else:
			# Mettre à jour la flèche
			arrow.update_arrow(intensity, angle, FIELD_SCALE)
	
	# Mettre à jour les limites de la grille
	grid_min_x = new_grid_min_x
	grid_max_x = new_grid_max_x
	grid_min_y = new_grid_min_y
	grid_max_y = new_grid_max_y

func _on_slider_changed(_value):
	queue_redraw()

	var intensity = h_slider_norm.value * 20
	var angle = h_slider_angle.value
	var electric_field = Vector2(FIELD_SCALE * intensity, 0).rotated(angle)
	
	proton_lev_2.set_electric_field(electric_field)

func _update_arrows():
	var intensity = h_slider_norm.value
	var angle = h_slider_angle.value

	for arrow in arrows:
		arrow.update_arrow(intensity, angle, FIELD_SCALE)

func _spawn_next_section():
	# Sélection aléatoire d'une section différente de la précédente
	var available_indices = range(SECTION_SCENES.size())
	if last_section_index != -1:
		available_indices.erase(last_section_index)
	
	var new_section_index = available_indices[randi() % available_indices.size()]
	last_section_index = new_section_index
	
	var section_scene = SECTION_SCENES[new_section_index]
	var section = section_scene.instantiate()
	
	# Position de la nouvelle section
	var x_pos = 0
	if active_sections.size() > 0:
		# Placer après la dernière section
		var last_section = active_sections[active_sections.size() - 1]
		x_pos = last_section.global_position.x + section_length
	
	section.global_position = Vector2(x_pos, 0)
	section_container.add_child(section)
	active_sections.append(section)
	
	# Connecter le signal de checkpoint si la section en a un
	if section.has_signal("checkpoint_reached"):
		section.checkpoint_reached.connect(_on_checkpoint_reached)
	
	# Ajouter une chance (25%) de créer une ligne de transformation à la jonction
	# MAIS PAS pour les premières sections du niveau
	if randf() < 1 and active_sections.size() > 1:  # Éviter les premières sections
		_create_transformation_line(x_pos)


func _check_transformation_collision():
	# Cette fonction sert maintenant de méthode de secours
	# si le signal body_entered ne se déclenche pas correctement
	
	for i in range(transformation_lines.size() - 1, -1, -1):
		var line = transformation_lines[i]
		var line_x = line.points[0].x
		var proton_x = proton_lev_2.global_position.x
		
		# Vérifier avec une zone plus large
		var detection_width = 40
		
		# Utiliser à la fois la position actuelle et la position précédente estimée
		var previous_x = proton_x - proton_lev_2.linear_velocity.x * get_physics_process_delta_time()
		
		# Si le joueur a traversé la ligne OU s'il est très proche
		if (previous_x < line_x and proton_x > line_x) or \
		   (previous_x > line_x and proton_x < line_x) or \
		   abs(proton_x - line_x) < detection_width:
			
			var current_time = elapsed_time
			var current_position = proton_lev_2.global_position
			
			# Vérifier le cooldown et la distance
			if current_time > (proton_lev_2.get_meta("last_transform_time", 0) + transform_cooldown) and \
			   current_position.distance_to(last_transform_position) > 50:
				
				_transform_player()
				proton_lev_2.set_meta("last_transform_time", current_time)
				last_transform_position = current_position
				
				# Supprimer la ligne après transformation
				line.queue_free()
				transformation_lines.remove_at(i)
				
				# Supprimer également l'Area2D correspondante si elle existe
				for j in range(transforming_areas.size() - 1, -1, -1):
					var area = transforming_areas[j]
					if abs(area.position.x - line_x) < 5:  # Si l'area est proche de la ligne
						area.queue_free()
						transforming_areas.remove_at(j)
						break


func _transform_player():
	var current_position = proton_lev_2.global_position
	var current_linear_velocity = proton_lev_2.linear_velocity
	
	# Sauvegarder le champ électrique actuel
	var intensity = h_slider_norm.value * 20
	var angle = h_slider_angle.value
	var electric_field = Vector2(FIELD_SCALE * intensity, 0).rotated(angle)

	# Supprimer tous les scripts de caméra liés
	for child in proton_lev_2.get_children():
		if child is Camera2D:
			child.queue_free()

	# Transformer le node en "proton" ou "électron" selon son état actuel
	if is_electron:
		# CONFIGURATION POUR PROTON
		proton_lev_2._set_as_proton()  # You must define this in your script
		proton_lev_2.set_electric_field(electric_field)
		is_electron = false
	else:
		# CONFIGURATION POUR ELECTRON
		proton_lev_2._set_as_electron()  # You must define this in your script
		proton_lev_2.set_electric_field(-electric_field)
		is_electron = true
	
	# Remise en place des propriétés de mouvement
	proton_lev_2.global_position = current_position
	proton_lev_2.linear_velocity = current_linear_velocity
	
	# Ajouter notre caméra externe au node
	if camera_node and camera_node.get_parent() != proton_lev_2:
		if camera_node.get_parent():
			camera_node.get_parent().remove_child(camera_node)
		proton_lev_2.add_child(camera_node)
	
	# Mettre à jour la caméra pour suivre le bon node
	if camera_node:
		camera_node.set("target", proton_lev_2)


func _check_section_generation():
	# Supprimer les sections trop éloignées mais avec un seuil plus généreux
	# Modification de la condition pour que la section ne disparaisse pas trop tôt
	while active_sections.size() > 0 and active_sections[0].global_position.x < player_position.x + section_despawn_distance - 8625:  # Retarde la suppression d'une section complète
		var section_to_remove = active_sections.pop_front()
		section_to_remove.queue_free()
	
	# Vérifier la distance entre le joueur et la dernière section
	if active_sections.size() > 0:
		var last_section_end_x = active_sections.back().global_position.x + section_length
		if last_section_end_x - player_position.x < section_spawn_distance:
			_spawn_next_section()
	else:
		# Si aucune section n'est présente, en générer une
		_spawn_next_section()

func _on_checkpoint_reached():
	current_score += 10
	score_label.text = "Score: %d" % current_score

func _is_player_out_of_bounds():
	# Vérifier si le joueur est tombé trop bas ou est trop loin derrière
	var y_limit = 1500  # Limite verticale (tombé)
	var x_behind_limit = -section_length  # Limite horizontale (trop en arrière - une section complète)
	
	if active_sections.size() == 0:
		return player_position.y > y_limit
		
	return (player_position.y > y_limit or 
			player_position.x < active_sections[0].global_position.x + x_behind_limit)

func game_over():
	is_running = false
	get_tree().paused = true
	LeaderboardManager_node.submit_score(1,GameState.username,current_score)
	if current_score > GameState.best_score_ElectricField :
		GameState.best_score_ElectricField = current_score
	game_over_ui.visible = true  
	lost_label.text = "Score: %d" % current_score
	fail_label.text = "Record: %d" % GameState.best_score_ElectricField

func _on_play_button_pressed() -> void:
	GameState.has_seen_theory_level2 = true
	theory_ui.visible = false
	get_tree().paused = false
	is_running = true
	_start_infinite_level()
