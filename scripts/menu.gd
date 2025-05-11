extends Control

@onready var texture_button_1: TextureButton = $TextureButton1
@onready var texture_button_2: TextureButton = $TextureButton2
@onready var texture_button_3: TextureButton = $TextureButton3
@onready var button_back: Button = $ButtonBack
@onready var button_ranking: Button = $ButtonRanking

# Matériel pour mise en évidence du focus
var initial_scale = Vector2(1.0, 1.0)
var focus_scale = Vector2(1.1, 1.1)
var focus_tween: Tween
var is_ready = false

func _ready():
	MusicPlayer.stop()
	
	# Configuration des éléments d'interface
	texture_button_1.focus_mode = Control.FOCUS_ALL
	texture_button_2.focus_mode = Control.FOCUS_ALL
	texture_button_3.focus_mode = Control.FOCUS_ALL
	button_back.focus_mode = Control.FOCUS_ALL
	button_ranking.focus_mode = Control.FOCUS_ALL
	
	# Configurer les pivot_offset pour centrer les transformations
	texture_button_1.pivot_offset = Vector2(texture_button_1.size.x / 2, texture_button_1.size.y / 2)
	texture_button_2.pivot_offset = Vector2(texture_button_2.size.x / 2, texture_button_2.size.y / 2)
	texture_button_3.pivot_offset = Vector2(texture_button_3.size.x / 2, texture_button_3.size.y / 2)
	
	# Réinitialiser les échelles
	texture_button_1.scale = initial_scale
	texture_button_2.scale = initial_scale
	texture_button_3.scale = initial_scale
	
	# Connecter les signaux de focus pour les TextureButtons
	texture_button_1.focus_entered.connect(_on_texture_button_focus_entered.bind(texture_button_1))
	texture_button_1.focus_exited.connect(_on_texture_button_focus_exited.bind(texture_button_1))
	texture_button_2.focus_entered.connect(_on_texture_button_focus_entered.bind(texture_button_2))
	texture_button_2.focus_exited.connect(_on_texture_button_focus_exited.bind(texture_button_2))
	texture_button_3.focus_entered.connect(_on_texture_button_focus_entered.bind(texture_button_3))
	texture_button_3.focus_exited.connect(_on_texture_button_focus_exited.bind(texture_button_3))
	
	is_ready = true
	
	# Définir les voisins de focus pour la navigation
	texture_button_1.focus_neighbor_right = texture_button_2.get_path()
	texture_button_2.focus_neighbor_right = texture_button_3.get_path()
	texture_button_2.focus_neighbor_left = texture_button_1.get_path()
	texture_button_3.focus_neighbor_left = texture_button_2.get_path()
	
	texture_button_1.focus_neighbor_bottom = button_back.get_path()
	texture_button_2.focus_neighbor_bottom = button_back.get_path()
	texture_button_3.focus_neighbor_bottom = button_ranking.get_path()
	button_back.focus_neighbor_top = texture_button_2.get_path()
	button_ranking.focus_neighbor_top = texture_button_2.get_path()
	
	button_back.focus_neighbor_right = button_ranking.get_path()
	button_ranking.focus_neighbor_left = button_back.get_path()

func _process(delta):
	# Gestion des entrées de manette
	if Input.is_action_just_pressed("ui_accept"):
		# Si on est sur le LineEdit
		if texture_button_1.has_focus():
			_on_texture_button_1_pressed()
			
		elif texture_button_2.has_focus():
			_on_texture_button_2_pressed()
		
		elif texture_button_3.has_focus():
			_on_texture_button_3_pressed()
			
		elif button_back.has_focus():
			_on_button_back_pressed()
			
		elif button_ranking.has_focus():
			_on_button_ranking_pressed()
	
	if Input.is_action_just_pressed("back"):
		_on_button_back_pressed()
	
	# Si aucun contrôle n'a le focus au démarrage, donner le focus au premier bouton
	if is_ready and not (texture_button_1.has_focus() or texture_button_2.has_focus() or 
		texture_button_3.has_focus() or button_back.has_focus() or button_ranking.has_focus()):
		texture_button_1.grab_focus()

func _on_texture_button_1_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level1_mod.tscn")

func _on_texture_button_2_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level6.tscn")

func _on_texture_button_3_pressed() -> void:
	GameState.entering_from_menu = true
	get_tree().change_scene_to_file("res://scenes/level5.tscn")

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/first_screen.tscn")

func _on_button_ranking_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rankings.tscn")

# Fonctions pour la mise en évidence visuelle du focus sur les TextureButtons
func _on_texture_button_focus_entered(button: TextureButton) -> void:
	# Annuler le tween précédent s'il existe
	#if focus_tween:
		#focus_tween.kill()
	
	# Créer un nouveau tween pour l'animation d'agrandissement
	focus_tween = create_tween()
	focus_tween.tween_property(button, "scale", focus_scale, 0.2).set_ease(Tween.EASE_OUT)
	
	# Ajouter un effet de modulation pour rendre le bouton plus lumineux
	focus_tween.parallel().tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)

func _on_texture_button_focus_exited(button: TextureButton) -> void:
	# Annuler le tween précédent s'il existe
	if focus_tween:
		focus_tween.kill()
	
	# Créer un nouveau tween pour l'animation de rétrécissement
	focus_tween = create_tween()
	focus_tween.tween_property(button, "scale", initial_scale, 0.2).set_ease(Tween.EASE_IN)
	
	# Restaurer la modulation normale
	focus_tween.parallel().tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
