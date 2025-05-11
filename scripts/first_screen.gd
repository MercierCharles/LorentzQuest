extends Control
@onready var line_edit: LineEdit = $ColorRect2/LineEdit
@onready var color_rect_2: ColorRect = $ColorRect2
@onready var button_play: Button = $ButtonPlay
@onready var button_options: Button = $ButtonOptions
@onready var label: Label = $Label
@onready var proton: Sprite2D = $Proton
var username_submitted = false

# Variables pour l'effet de pulse
var pulse_time: float = 0.0
var pulse_speed: float = 3
var pulse_amplitude: float = 0.05
var base_scale: Vector2 = Vector2(1.0, 1.0)
var base_scale_proton: Vector2 = Vector2(0.1, 0.1)

func _ready():
	# Configuration des éléments d'interface
	line_edit.focus_mode = Control.FOCUS_ALL
	button_play.focus_mode = Control.FOCUS_ALL
	button_options.focus_mode = Control.FOCUS_ALL
	
	# Définir les voisins de focus pour la navigation
	button_play.focus_neighbor_bottom = button_options.get_path()
	button_options.focus_neighbor_top = button_play.get_path()
	
	# Au début, les boutons ne sont pas visibles
	button_play.visible = false
	button_options.visible = false
	
	# Connecter les signaux pour LineEdit
	line_edit.text_submitted.connect(on_username_entered)
	line_edit.grab_focus()
	
	# Vérifier si le nom d'utilisateur est déjà défini
	if GameState.username != "":
		color_rect_2.visible = false
		button_play.visible = true
		button_options.visible = true
		button_play.grab_focus()
		username_submitted = true
		
	# Sauvegarde de l'échelle initiale des éléments
	if label:
		base_scale = label.scale
		# Définir le pivot au centre du label pour que la pulsation soit centrée
		label.pivot_offset = label.size / 2
	
	if proton:
		# Définir le pivot au centre du sprite pour que la pulsation soit centrée
		proton.pivot_offset = proton.texture.get_size() / 2
	
func _process(delta):
	# Gestion des entrées de manette
	if Input.is_action_just_pressed("ui_accept"):
		# Si on est sur le LineEdit
		if line_edit.has_focus() and not username_submitted:
			# Simuler la soumission du texte comme si "Enter" était pressé
			on_username_entered(line_edit.text)
		
		# Si on est sur le bouton Play
		elif button_play.has_focus() and button_play.visible:
			_on_button_play_pressed()
		
		# Si on est sur le bouton Options
		elif button_options.has_focus() and button_options.visible:
			_on_button_options_pressed()
	
	# Effet de pulse scaling sur le titre
	pulse_time += delta * pulse_speed
	var pulse_factor = 1.0 + pulse_amplitude * sin(pulse_time)
	
	# Appliquer l'effet de pulse au Label et au Proton
	if label:
		label.scale = base_scale * pulse_factor
	
	if proton:
		proton.scale = base_scale_proton * pulse_factor

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_button_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func on_username_entered(text: String):
	var name = text.strip_edges()
	if name != "":
		GameState.username = name
		print("Nom d'utilisateur enregistré : ", GameState.username)
		line_edit.release_focus()
		color_rect_2.visible = false
		
		# Marquer que le nom a été soumis pour éviter la double activation
		username_submitted = true
		
		# Afficher les boutons maintenant
		button_play.visible = true
		button_options.visible = true
		
		# Important: Attendre un bref moment avant de donner le focus au bouton Play
		# pour éviter que le même appui sur Enter/X active aussi le bouton Play
		await get_tree().create_timer(0.2).timeout
		button_play.grab_focus()
	else:
		line_edit.placeholder_text = "Invalid username"
		line_edit.text = ""  # Effacer le texte invalide
