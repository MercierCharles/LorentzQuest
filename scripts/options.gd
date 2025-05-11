extends Control

@onready var artist_selector: OptionButton = $artist_selector
@onready var line_edit: LineEdit = $LineEdit
@onready var button: Button = $ColorRect/Button

var artists = ["Bad Bunny", "Morad", "Myke Towers", "Ozuna"]
var current_focus: Control  # Pour suivre le contrôle actuellement sélectionné
var elements = []  # Tableau pour stocker tous les éléments de l'interface
var current_element_index = 0  # Index de l'élément actuellement sélectionné

func _ready():
	# Configuration des éléments interactifs
	line_edit.text_submitted.connect(on_username_entered)
	line_edit.text = GameState.username
	
	# Remplir le menu déroulant
	for artist in artists:
		artist_selector.add_item(artist)
	
	# Trouver l'index de l'artiste déjà sélectionné
	var index = artists.find(GameState.selected_artist)
	if index != -1:
		artist_selector.select(index)
	
	# Connecter le signal
	artist_selector.item_selected.connect(on_artist_selected)
	
	# Configuration du bouton
	button.pressed.connect(on_button_pressed)
	
	# Configuration de la navigation avec la manette
	elements = [line_edit, artist_selector, button]
	
	# S'assurer que tous les éléments peuvent recevoir le focus
	for element in elements:
		element.focus_mode = Control.FOCUS_ALL
	
	# Donner le focus au premier élément au démarrage
	current_element_index = 0
	current_focus = elements[current_element_index]
	current_focus.grab_focus()
	
	# Connecter les signaux de focus pour les effets visuels
	for element in elements:
		element.focus_entered.connect(_on_element_focus_entered.bind(element))
		element.focus_exited.connect(_on_element_focus_exited.bind(element))

func _process(delta):
	# Navigation avec les touches directionnelles ou le D-pad de la manette
	if Input.is_action_just_pressed("ui_accept"):
		# Si on est sur le LineEdit
		if line_edit.has_focus():
			line_edit.focus_mode = Control.FOCUS_ALL
		elif artist_selector.has_focus():
			if not artist_selector.get_popup().visible:
				artist_selector.get_popup().position = artist_selector.global_position + Vector2(0, artist_selector.size.y)
				artist_selector.get_popup().show()
		
	if Input.is_action_just_pressed("back"):
		on_button_pressed()

func navigate_to_next_element():
	# Passer à l'élément suivant dans la liste
	current_element_index = (current_element_index + 1) % elements.size()
	current_focus = elements[current_element_index]
	current_focus.grab_focus()

func navigate_to_previous_element():
	# Passer à l'élément précédent dans la liste
	current_element_index = (current_element_index - 1 + elements.size()) % elements.size()
	current_focus = elements[current_element_index]
	current_focus.grab_focus()

func _on_element_focus_entered(element):
	# Effet visuel quand un élément reçoit le focus
	element.modulate = Color(1.2, 1.2, 1.2)  # Légèrement plus lumineux

func _on_element_focus_exited(element):
	# Retour à la normale quand l'élément perd le focus
	element.modulate = Color(1.0, 1.0, 1.0)

func on_artist_selected(index):
	GameState.selected_artist = artists[index]

func on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/first_screen.tscn")

func on_username_entered(text: String):
	var name = text.strip_edges()
	if name != "":
		GameState.username = name
		print("Nom d'utilisateur enregistré : ", GameState.username)
		line_edit.release_focus()
		# Passer automatiquement à l'élément suivant
		navigate_to_next_element()
	else:
		line_edit.placeholder_text = "Invalid username"
		


func _input(event):
	# Gérer l'activation de l'élément sélectionné avec le bouton A/Croix
	if event.is_action_pressed("ui_accept"):
		if current_focus == button:
			on_button_pressed()
		elif current_focus == artist_selector:
			# Simuler un clic sur l'OptionButton pour ouvrir le menu déroulant
			if not artist_selector.get_popup().visible:
				artist_selector.get_popup().position = artist_selector.global_position + Vector2(0, artist_selector.size.y)
				artist_selector.get_popup().show()
				
				# Configuration de la navigation dans le popup
				_setup_popup_navigation()

func _setup_popup_navigation():
	var popup = artist_selector.get_popup()
	
	# PopupMenu doesn't have focus_mode property, so we don't set it
	# We'll use input handling to navigate the popup instead
	
	# Connecter les signaux nécessaires pour le popup
	if not popup.is_connected("id_pressed", _on_popup_item_selected):
		popup.id_pressed.connect(_on_popup_item_selected)
	
	# Connecter un signal pour détecter quand le popup se ferme
	if not popup.is_connected("popup_hide", _on_popup_closed):
		popup.popup_hide.connect(_on_popup_closed)

func _on_popup_item_selected(id):
	# L'option a été sélectionnée, mettre à jour en conséquence
	artist_selector.select(id)
	on_artist_selected(id)

func _on_popup_closed():
	# Quand le popup se ferme, redonner le focus à l'OptionButton
	artist_selector.grab_focus()
