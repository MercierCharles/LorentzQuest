extends CanvasLayer

@onready var restart_button = $RestartButton  # Assurez-vous que ce chemin est correct
@onready var menu_button = $MenuButton  # Assurez-vous que ce chemin est correct

var current_focus = null
var buttons = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false  # Cache GameOverUI au début
	
	# Connecter les boutons aux fonctions
	restart_button.pressed.connect(on_restart_button_pressed)
	menu_button.pressed.connect(on_menu_button_pressed)
	
	# Configuration des boutons pour la navigation
	buttons = [restart_button, menu_button]
	
	# S'assurer que tous les boutons peuvent recevoir le focus
	for button in buttons:
		button.focus_mode = Control.FOCUS_ALL
		button.focus_entered.connect(_on_button_focus_entered.bind(button))
		button.focus_exited.connect(_on_button_focus_exited.bind(button))
		


# Appelé lorsque le GameOverUI devient visible
func show_game_over_ui():
	visible = true
	get_tree().paused = true  # Mettre le jeu en pause
	
	# Donner le focus au bouton Restart par défaut
	current_focus = restart_button
	current_focus.grab_focus()

func _input(event):
	if not visible:
		return
		
	# Navigation horizontale avec la manette ou les touches
	if event.is_action_pressed("ui_right"):
		current_focus = menu_button
		current_focus.grab_focus()
	elif event.is_action_pressed("ui_left"):
		current_focus = restart_button
		current_focus.grab_focus()
	
	# Activation du bouton sélectionné
	if event.is_action_pressed("ui_accept"):
		if current_focus == restart_button:
			on_restart_button_pressed()
		elif current_focus == menu_button:
			on_menu_button_pressed()
			
	if Input.is_action_just_pressed("back"):
		on_menu_button_pressed()

func _on_button_focus_entered(button):
	# Effet visuel quand un bouton reçoit le focus
	button.modulate = Color(1.2, 1.2, 1.2)  # Légèrement plus lumineux

func _on_button_focus_exited(button):
	# Retour à la normale quand le bouton perd le focus
	button.modulate = Color(1.0, 1.0, 1.0)

func on_restart_button_pressed():
	get_tree().paused = false  # Unpause the game
	get_tree().reload_current_scene()

func on_menu_button_pressed() -> void:
	get_tree().paused = false  # Unpause the game
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
