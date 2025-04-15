extends Control

@onready var h_slider_angle: HSlider = get_node("HSliderAngle")
@onready var h_slider_norm: HSlider = get_node("HSliderNorm")
@onready var joystick_background = get_node("Joystick/JoystickBackground")
@onready var joystick_knob = get_node("Joystick/JoystickBackground/JoystickKnob")
var is_dragging = false
var click_start_position = Vector2()
var current_mouse_position = Vector2()
var max_radius = 180
const INTENSITY_STEP = 0.05  # Intensity adjustment step
const DIRECTION_STEP = 0.2   # Angle adjustment step (radians)
const CONTROLLER_DEADZONE = 0.2  # Seuil pour ignorer les petits mouvements du joystick

func _ready():
	# S'assurer que les périphériques d'entrée sont bien configurés dans le projet
	Input.set_use_accumulated_input(false)

func _input(event):

	
	# Gestion des événements de la souris
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			click_start_position = event.position
			current_mouse_position = event.position
			update_sliders()
			gui_input(event)
		else:
			is_dragging = false
			current_mouse_position = event.position
			update_sliders()
			gui_input(event)
	elif event is InputEventMouseMotion and is_dragging:
		current_mouse_position = event.position
		update_sliders()
		gui_input(event)
	
	# Gestion de la manette PS4
	if event is InputEventJoypadMotion:
		# Joystick gauche de la manette PS4
		if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y:
			process_controller_input()

func process_controller_input():
	# Lecture des valeurs du joystick gauche
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)  # 0 est le premier contrôleur
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	
	# Appliquer un deadzone pour éviter les mouvements indésirables
	if abs(joy_x) < CONTROLLER_DEADZONE:
		joy_x = 0
	if abs(joy_y) < CONTROLLER_DEADZONE:
		joy_y = 0
	
	# Convertir les coordonnées du joystick en angle et norme
	var joy_vector = Vector2(joy_x, joy_y)
	var norm = clamp(joy_vector.length(), 0.0, 1.0)
	
	# Si le joystick est suffisamment déplacé
	if norm > CONTROLLER_DEADZONE:
		# Calculer l'angle (notez que pour un joystick, Y est inversé)
		var direction = Vector2(joy_x, joy_y).angle()
		
		# Mettre à jour les valeurs des sliders
		h_slider_norm.value = norm
		h_slider_angle.value = fmod(direction + TAU, TAU)
		
		# Afficher le joystick virtuel si nécessaire
		if !joystick_background.visible:
			show_joystick_at(Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2))
	else:
		# Réinitialiser si le joystick est au repos
		if !is_dragging:
			h_slider_norm.value = 0.0
			hide_joystick()

func update_sliders():
	var vector = current_mouse_position - click_start_position
	var norm = clamp(vector.length() / max_radius, 0.0, 1.0)
	var direction = vector.angle()
	h_slider_norm.value = norm
	h_slider_angle.value = fmod(direction + TAU, TAU)

func gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			show_joystick_at(click_start_position)
		else:
			is_dragging = false
			hide_joystick()

func show_joystick_at(start_position):
	joystick_background.size = Vector2.ONE * max_radius * 2
	joystick_background.position = start_position - joystick_background.size / 2
	joystick_knob.position = joystick_background.size / 2 - joystick_knob.size / 2
	joystick_background.show()

func hide_joystick():
	joystick_background.hide()
	
func update_knob_position():
	var direction = h_slider_angle.value
	var norm = h_slider_norm.value
	var offset = Vector2.RIGHT.rotated(direction) * (norm * max_radius)
	joystick_knob.position = joystick_background.size / 2 - joystick_knob.size / 2 + offset
	
func _process(_delta):
	update_knob_position()
	
	# Ajouter une vérification continue des entrées manette dans _process
	# Utile si vous voulez une réponse plus fluide
	process_controller_input()
