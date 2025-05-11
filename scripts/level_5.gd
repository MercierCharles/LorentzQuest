extends Node2D

@onready var h_slider: HSlider = $CanvasLayer/Sliders/HSlider
@onready var proton: RigidBody2D = $ProtonLev4
@onready var theory_ui: CanvasLayer = $TheoryUI
@onready var play_button: Button = $TheoryUI/PlayButton
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var fail_label: Label = $GameOverUI/FailLabel
@onready var lost_label: Label = $GameOverUI/LostLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel

const GRID_SPACING = 400.0  
const FIELD_SCALE = 150.0  
const SYMBOL_SCENE = preload("res://scenes/magnetic_field_symbol_2d.tscn")  
const INITIAL_MAX_DISTANCE = 400.0  # Distance max initiale avant Game Over
const MIN_PATH_WIDTH = 100.0  # Largeur minimale du chemin
const WIDTH_DECREASE_RATE = 0.5  # Taux de réduction de la largeur par 1000 points
const STRAIGHT_LENGTH = 1000.0  # Longueur initiale de la ligne droite
const DEBUT_CHEMIN = -1500.0
const MIN_RADIUS = 600.0  # Rayon minimal des arcs de cercle
const MAX_RADIUS = 2000.0  # Rayon maximal des arcs de cercle
const MIN_ANGLE = PI / 4  # Angle minimal d'un arc de cercle
const MAX_ANGLE = PI / 2  # Angle maximal d'un arc de cercle
const INITIAL_SPEED = 1000.0
const SEGMENT_GENERATION_THRESHOLD = 5000.0  # Distance avant génération de nouveaux segments
const CLEANUP_DISTANCE = 10000.0  # Distance à laquelle les segments et symboles sont supprimés
const SYMBOL_GENERATION_RADIUS = 5000.0  # Rayon dans lequel générer des symboles autour du proton
const facteur_discontinuite = 1.5
const RED_WIDTH = 20
const GREEN_WIDTH = 2

var symbols = []  
var path_points = []  # Points du chemin visuel
var elapsed_time = 0.0
var score = 0
var is_running = true
var last_position = Vector2.ZERO  # Position du dernier point généré
var last_direction = Vector2.RIGHT  # Direction du dernier segment généré
var visible_path_points = []  # Points du chemin actuellement visibles

# Variables pour la génération dynamique
var path_start_index = 0  # Index du début du chemin visible
var generated_symbols = {}  # Dictionnaire pour traquer les symboles générés par secteur
var last_proton_grid_position = Vector2.ZERO  # Dernière position du proton pour la génération de symboles
var current_max_distance = INITIAL_MAX_DISTANCE  # Variable pour stocker la largeur actuelle du chemin

func _ready():
	var music
	
	if GameState.selected_artist == "Bad Bunny" :
		music = load("res://assets/music/Bad Bunny/Volando (Remix).mp3")
	elif GameState.selected_artist == "Morad" :
		music = load("res://assets/music/Morad/MORAD - PELELE (AUDIO OFICIAL).mp3")
	elif GameState.selected_artist == "Myke Towers" :
		music = load("res://assets/music/Myke Towers/Myke Towers - Mírenme Ahora (Video Oficial).mp3")
	elif GameState.selected_artist == "Ozuna":
		music = load("res://assets/music/Ozuna/Ozuna feat. Davido - Eva Longoria (Visualizer Oficial)  AFRO.mp3")
		
	MusicPlayer.play_music(music)
	
	RenderingServer.set_default_clear_color(Color.BLACK)
	h_slider.min_value = -10.0
	h_slider.max_value = 10.0
	h_slider.value = 0.0  

	h_slider.value_changed.connect(_on_slider_changed)
	
	# Initialisation du premier segment
	_generate_initial_path()
	
	if GameState.entering_from_menu:
		GameState.has_seen_theory_level4 = false  
		GameState.entering_from_menu = false  

	if GameState.has_seen_theory_level4:
		theory_ui.visible = false
		get_tree().paused = false  
		is_running = true
	else:
		theory_ui.visible = true
		theory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true  
	
	# Initialisation de la largeur du chemin
	current_max_distance = INITIAL_MAX_DISTANCE
	
	_initialize_proton()
	score_label.text = "Score: 0"
	
	# S'assurer que les segments de chemin sont correctement calculés avant de vérifier la distance
	visible_path_points = path_points.duplicate()
	
	# Générer les symboles initiaux après l'initialisation du proton
	last_proton_grid_position = _get_grid_position(proton.global_position)
	_ensure_symbols_around_proton()
	
	_update_symbols()
	
	queue_redraw()
	
	_on_play_button_pressed()  #pas d'écran de théorie

var last_sec = 1

func _process(delta):
	if is_running:
		elapsed_time += delta
		
		# Déplacement du slider avec les entrées
		var slider_step = 0.5
		
		if Input.is_joy_known(0):
			var axis_value = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
			axis_value = -axis_value
			var shaped = sign(axis_value) * pow(abs(axis_value),2.5)
			var slider_min = h_slider.min_value
			var slider_max = h_slider.max_value
			var new_value = lerp(slider_min, slider_max, (shaped + 1.0) / 2.0)
			h_slider.value = new_value
		
		# Mise à jour du score basé sur la distance parcourue
		var distance_traveled = proton.global_position.length()
		score = int(distance_traveled / 100)
		score_label.text = "Score: %d" % score
		
		# Mettre à jour la largeur du chemin en fonction du score
		_update_path_width()
		
		# Vérification de la distance du proton par rapport au chemin
		_check_distance_from_path()
		
		# Maintien de la vitesse constante
		if abs(elapsed_time-last_sec) < 0.1:
			last_sec = last_sec + 1
			var speed = proton.linear_velocity.length()
			if speed > 0:
				var corrected_velocity = proton.linear_velocity.normalized() * INITIAL_SPEED
				proton.linear_velocity = corrected_velocity
		
		# Génération dynamique du chemin
		_check_for_path_generation()
		
		# Vérifier si le proton a changé de secteur de grille
		var current_grid_pos = _get_grid_position(proton.global_position)
		if current_grid_pos != last_proton_grid_position:
			last_proton_grid_position = current_grid_pos
			_ensure_symbols_around_proton()
		
		# Nettoyage des segments et symboles qui sont loin derrière le joueur
		_cleanup_old_segments()

func _update_path_width():
	# Calculer la nouvelle largeur basée sur le score
	# Réduire la largeur au fur et à mesure que le score augmente
	var score_factor = score / 1000.0  # Convertir le score en facteur (tous les 1000 points)
	var width_reduction = score_factor * WIDTH_DECREASE_RATE * INITIAL_MAX_DISTANCE
	
	# S'assurer que la largeur ne descend pas en dessous du minimum
	current_max_distance = max(INITIAL_MAX_DISTANCE - width_reduction, MIN_PATH_WIDTH)
	
	# Redessiner le chemin avec la nouvelle largeur
	queue_redraw()

func _get_grid_position(world_pos: Vector2) -> Vector2:
	# Convertit une position monde en position de grille
	return Vector2(
		floor(world_pos.x / (GRID_SPACING * 2)), 
		floor(world_pos.y / (GRID_SPACING * 2))
	)

func _initialize_proton():
	proton.global_position = Vector2(0, 0)
	proton.linear_velocity = Vector2(INITIAL_SPEED, 0)  # Vitesse initiale (vers la droite)

func _generate_initial_path():
	path_points.clear()
	last_position = Vector2.ZERO
	last_direction = Vector2.RIGHT
	
	# Ajout du point de départ
	path_points.append(last_position)
	
	# Génération de la ligne droite initiale
	var end_line_pos = last_position + last_direction * STRAIGHT_LENGTH
	path_points.append(end_line_pos)
	last_position = end_line_pos
	
	last_direction = Vector2.LEFT
	
	# Génération des premiers segments de chemin
	_generate_path_segments(5)  # Générer 5 segments initiaux

# Déclaration au niveau de la classe
var cumulated_angle = 0.0  # Variable pour suivre l'angle cumulé du chemin

func _generate_path_segments(count: int):
	# La variable cumulated_angle est maintenant accessible directement
	
	for i in range(count):
		var arc_radius = randf_range(MIN_RADIUS, MAX_RADIUS)
		var arc_angle = randf_range(MIN_ANGLE, MAX_ANGLE)
		var arc_clockwise = randi() % 2 == 0
		
		# Calculer l'effet de cet arc sur l'angle cumulé
		var angle_delta = arc_angle * (-1 if arc_clockwise else 1)
		var new_cumulated_angle = cumulated_angle + angle_delta
		
		# Vérifier si l'arc respecte la contrainte d'orientation
		if new_cumulated_angle > PI/2 or new_cumulated_angle < -PI/2:
			# Si l'arc fait dévier trop le chemin, inverser le sens ou réduire l'angle
			arc_clockwise = !arc_clockwise
			angle_delta = arc_angle * (-1 if arc_clockwise else 1)
			new_cumulated_angle = cumulated_angle + angle_delta
			
			# Si même avec l'inversion, on dépasse les limites, réduire l'angle
			if new_cumulated_angle > PI/2 or new_cumulated_angle < -PI/2:
				# Calculer un angle qui respecte les limites
				var max_allowed_delta = (PI/2 - cumulated_angle) if arc_clockwise else (-PI/2 - cumulated_angle)
				arc_angle = abs(max_allowed_delta) * 0.9  # 90% de l'angle maximum pour éviter les limites exactes
				angle_delta = arc_angle * (-1 if arc_clockwise else 1)
				new_cumulated_angle = cumulated_angle + angle_delta
		
		# Mise à jour de l'angle cumulé
		cumulated_angle = new_cumulated_angle
		
		# Calcul du centre garantissant la continuité
		var arc_normal = last_direction.orthogonal() * (-1 if arc_clockwise else 1)
		var arc_center = last_position + arc_normal * arc_radius
		
		# Génération de l'arc
		var arc_points = _generate_arc(last_position, arc_center, arc_radius, arc_angle, arc_clockwise)
		
		# Vérification et correction de l'orientation
		if arc_points.size() > 1:
			var arc_tangent_vector = (arc_points[-1] - arc_points[-2]).normalized()
			# Assurer que la direction reste cohérente
			if last_direction.dot(arc_tangent_vector) < 0:
				arc_tangent_vector = -arc_tangent_vector
			
			last_direction = arc_tangent_vector
			last_position = arc_points[-1]
			
			# Ajout des points de l'arc au chemin
			for j in range(1, arc_points.size()):  # Commencer à 1 pour éviter la duplication du point de départ
				path_points.append(arc_points[j])
	
	queue_redraw()

func _generate_arc(start_pos: Vector2, center: Vector2, radius: float, angle: float, clockwise: bool) -> Array:
	var arc_points = []
	var start_angle = (start_pos - center).angle()
	var num_segments = 20  

	for i in range(num_segments + 1):
		var t = float(i) / num_segments
		var theta = start_angle + t * angle * (-1 if clockwise else 1)
		var point = center + Vector2(cos(theta), sin(theta)) * radius
		arc_points.append(point)

	return arc_points

func _check_for_path_generation():
	# Vérifier si le proton est suffisamment proche de la fin du chemin actuel
	var distance_to_end = proton.global_position.distance_to(last_position)
	
	if distance_to_end < SEGMENT_GENERATION_THRESHOLD:
		# Générer de nouveaux segments de chemin
		_generate_path_segments(3)  # Générer 3 nouveaux segments
		
		# Note: La génération des symboles est maintenant gérée par _ensure_symbols_around_proton()

func _ensure_symbols_around_proton():
	var center = proton.global_position
	var radius = SYMBOL_GENERATION_RADIUS
	
	# Calculer les limites de la grille à générer
	var grid_min_x = int(floor((center.x - radius) / GRID_SPACING))
	var grid_max_x = int(ceil((center.x + radius) / GRID_SPACING))
	var grid_min_y = int(floor((center.y - radius) / GRID_SPACING))
	var grid_max_y = int(ceil((center.y + radius) / GRID_SPACING))
	
	# Générer les symboles
	for grid_x in range(grid_min_x, grid_max_x + 1):
		for grid_y in range(grid_min_y, grid_max_y + 1):
			var grid_pos = Vector2(grid_x * GRID_SPACING, grid_y * GRID_SPACING)
			
			# Vérifier si la position est dans le rayon spécifié
			if center.distance_to(grid_pos) <= radius:
				# Clé unique pour cette position de grille
				var grid_key = "%d_%d" % [grid_x, grid_y]
				
				# Ne générer un symbole que si cette position n'existe pas déjà
				if not grid_key in generated_symbols:
					var symbol = SYMBOL_SCENE.instantiate()
					symbol.global_position = grid_pos
					symbol.set_direction("out" if randi() % 2 == 0 else "in")
					add_child(symbol)
					symbols.append(symbol)
					generated_symbols[grid_key] = symbol

func _cleanup_old_segments():
	# Suppression des segments et symboles qui sont loin derrière le joueur
	var proton_pos = proton.global_position
	
	# Nettoyer les points du chemin, mais toujours laisser au moins 10 points visibles
	while path_points.size() > 12 and path_start_index < path_points.size() - 10:
		if proton_pos.distance_to(path_points[path_start_index]) > CLEANUP_DISTANCE:
			path_start_index += 1
		else:
			break
	
	# Créer une liste des points visibles pour le dessin
	visible_path_points = path_points.slice(path_start_index)
	
	# Nettoyer les symboles
	var symbols_to_remove = []
	for symbol in symbols:
		if symbol.global_position.distance_to(proton_pos) > CLEANUP_DISTANCE:
			symbols_to_remove.append(symbol)
	
	for symbol in symbols_to_remove:
		var grid_x = int(symbol.global_position.x / GRID_SPACING)
		var grid_y = int(symbol.global_position.y / GRID_SPACING)
		var grid_key = "%d_%d" % [grid_x, grid_y]
		generated_symbols.erase(grid_key)
		symbols.erase(symbol)
		symbol.queue_free()

func _draw():
	if visible_path_points.size() > 1:
		# Dessiner le chemin principal en vert
		#draw_polyline(visible_path_points, Color.GREEN, GREEN_WIDTH)
		#draw_polyline([Vector2(DEBUT_CHEMIN+current_max_distance*facteur_discontinuite,0),Vector2.ZERO], Color.GREEN, GREEN_WIDTH)
		
		# Listes pour les bords gauche et droit
		var outer_points_left = []
		var outer_points_right = []
		
		# Premier segment droit - création des lignes parallèles simples
		# Segment supérieur (au lieu de outer_points_right)
		draw_line(
			Vector2(DEBUT_CHEMIN, -current_max_distance*facteur_discontinuite),
			Vector2(STRAIGHT_LENGTH, -current_max_distance*facteur_discontinuite),
			Color.RED, RED_WIDTH, true
		)
		
		# Segment inférieur (au lieu de outer_points_left)
		draw_line(
			Vector2(DEBUT_CHEMIN, current_max_distance*facteur_discontinuite),
			Vector2(STRAIGHT_LENGTH, current_max_distance*facteur_discontinuite),
			Color.RED, RED_WIDTH, true
		)
		
		# Segment vertical à gauche
		draw_line(
			Vector2(DEBUT_CHEMIN, -current_max_distance*facteur_discontinuite),
			Vector2(DEBUT_CHEMIN, current_max_distance*facteur_discontinuite),
			Color.RED, RED_WIDTH, true
		)
		
		# Ajouter les points aux listes pour le reste du dessin
		outer_points_right.append(Vector2(DEBUT_CHEMIN, -current_max_distance*facteur_discontinuite))
		outer_points_right.append(Vector2(STRAIGHT_LENGTH, -current_max_distance*facteur_discontinuite))
		outer_points_left.append(Vector2(DEBUT_CHEMIN, current_max_distance*facteur_discontinuite))
		outer_points_left.append(Vector2(STRAIGHT_LENGTH, current_max_distance*facteur_discontinuite))
		
		# Pour le reste des points du chemin, utiliser la méthode existante
		for i in range(1, visible_path_points.size()):
			var normal = Vector2.ZERO
			
			if i == visible_path_points.size() - 1:
				# Dernier point
				var direction = (visible_path_points[i] - visible_path_points[i-1]).normalized()
				normal = Vector2(-direction.y, direction.x)
			else:
				# Points intermédiaires
				var prev_dir = (visible_path_points[i] - visible_path_points[i-1]).normalized()
				var next_dir = (visible_path_points[i+1] - visible_path_points[i]).normalized()
				
				# Normales des deux segments
				var prev_normal = Vector2(-prev_dir.y, prev_dir.x)
				var next_normal = Vector2(-next_dir.y, next_dir.x)
				
				# Moyenne des normales
				normal = ((prev_normal + next_normal) / 2).normalized()
				
				# Correction dans les virages serrés
				var angle = abs(prev_dir.angle_to(next_dir))
				if angle > 0.01:
					var correction = 1.0 / max(sin(angle / 2), 0.5)
					normal *= min(correction, 1.5)
			
			# Ajouter les points aux listes
			outer_points_left.append(visible_path_points[i] + normal * current_max_distance)
			outer_points_right.append(visible_path_points[i] - normal * current_max_distance)
		
		# Inverser l'ordre des points de droite
		outer_points_right.reverse()
		
		# Dessiner les lignes rouges extérieures si nous avons assez de points
		if outer_points_left.size() > 2:
			draw_polyline(outer_points_left, Color.RED, RED_WIDTH)
		
		if outer_points_right.size() > 2:
			draw_polyline(outer_points_right, Color.RED, RED_WIDTH)


func _check_distance_from_path():
	var proton_pos = proton.global_position
	var min_distance = INF
	
	#PARTIE 1: Vérification pour la section initiale rectangulaire
	if proton_pos.x <= STRAIGHT_LENGTH:
		#Vérifier si le proton est à l'intérieur des limites du rectangle initial
		var outside_initial_section = false
		
		#Hors des limites verticales
		if abs(proton_pos.y) > current_max_distance*facteur_discontinuite:
			outside_initial_section = true
		
		#À gauche de la ligne rouge verticale
		if proton_pos.x < DEBUT_CHEMIN:
			outside_initial_section = true
		
		if outside_initial_section:
			game_over()  #Game over immédiat si on traverse une ligne rouge initiale
			return
	
	#PARTIE 2: Vérification pour le reste du chemin (segments curvilignes)
	if visible_path_points.size() >= 2:
		#Pour chaque segment visible
		for i in range(visible_path_points.size() - 1):
			var segment_start = visible_path_points[i]
			var segment_end = visible_path_points[i + 1]
			var closest_point = _closest_point_on_segment(proton_pos, segment_start, segment_end)
			var distance = proton_pos.distance_to(closest_point)
			
			if distance < min_distance:
				min_distance = distance
		
		#Si on est trop loin de n'importe quel segment de chemin
		if min_distance > current_max_distance*facteur_discontinuite and proton_pos.x > 0:
			game_over()

func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ap = p - a
	var ab_length_squared = ab.length_squared()
	
	if ab_length_squared == 0:
		return a  
	
	var t = ap.dot(ab) / ab_length_squared
	t = clamp(t, 0.0, 1.0)
	
	return a + ab * t

func _on_slider_changed(_value):
	queue_redraw()  
	var intensity = - h_slider.value * 2.0  
	proton.set_magnetic_field(intensity)  
	_update_symbols()

func _update_symbols():
	var intensity = -h_slider.value  
	var scale_factor = abs(intensity)
	var direction = "out" if intensity > 0 else "in" if intensity < 0 else "none"
	
	for symbol in symbols:
		if direction == "none":
			# Cacher le symbole quand l'intensité est nulle
			symbol.visible = false
		else:
			symbol.visible = true
			symbol.set_field_scale(scale_factor)
			symbol.set_direction(direction)

func game_over():
	is_running = false  
	get_tree().paused = true  
	LeaderboardManager_node.submit_score(2,GameState.username,score)
	if score > GameState.best_score_MagneticField :
		GameState.best_score_MagneticField = score
	game_over_ui.show_game_over_ui() 
	lost_label.text = "Score: %d" % score
	fail_label.text = "Record: %d" % GameState.best_score_MagneticField

func _on_play_button_pressed() -> void:
	GameState.has_seen_theory_level4 = true
	theory_ui.visible = false
	get_tree().paused = false
	is_running = true

func _on_restart_button_pressed() -> void:
	# Réinitialiser le jeu pour une nouvelle partie
	get_tree().reload_current_scene()
