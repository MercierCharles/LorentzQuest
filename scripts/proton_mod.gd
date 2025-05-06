extends CharacterBody2D
signal hit_electron(electron)  # Signal modifié pour inclure l'électron touché

const SPEED = 600.0
const CONTROLLER_DEADZONE = 0.2  # Seuil pour ignorer les petits mouvements du joystick

# Variables pour les limites de l'écran
var screen_size
var proton_radius = 0

func _ready():
	# S'assurer que les actions d'entrée incluent les boutons directionnels de la manette
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
	
	# Ajouter les boutons directionnels de la manette aux actions
	var left_dpad = InputEventJoypadButton.new()
	left_dpad.button_index = JOY_BUTTON_DPAD_LEFT
	InputMap.action_add_event("move_left", left_dpad)
	
	var right_dpad = InputEventJoypadButton.new()
	right_dpad.button_index = JOY_BUTTON_DPAD_RIGHT
	InputMap.action_add_event("move_right", right_dpad)
	
	var up_dpad = InputEventJoypadButton.new()
	up_dpad.button_index = JOY_BUTTON_DPAD_UP
	InputMap.action_add_event("move_up", up_dpad)
	
	var down_dpad = InputEventJoypadButton.new()
	down_dpad.button_index = JOY_BUTTON_DPAD_DOWN
	InputMap.action_add_event("move_down", down_dpad)
	
	# Obtenir la taille de l'écran
	screen_size = get_viewport_rect().size
	
	# Obtenir le rayon du proton à partir de sa shape de collision
	var collision_shape = get_node("CollisionShape2D")
	if collision_shape and collision_shape.shape is CircleShape2D:
		proton_radius = collision_shape.shape.radius
	elif collision_shape and collision_shape.shape is RectangleShape2D:
		proton_radius = min(collision_shape.shape.extents.x, collision_shape.shape.extents.y)
	else:
		# Valeur par défaut si aucune forme n'est trouvée
		proton_radius = 16.0

func _physics_process(delta: float) -> void:
	# 1. Obtenir les valeurs du joystick analogique
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var joystick_direction = Vector2(joy_x, joy_y)
	
	# 2. Obtenir les entrées digitales (clavier + D-Pad)
	var digital_direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	# 3. Décider quelle entrée utiliser
	var direction = Vector2.ZERO
	
	if joystick_direction.length() > CONTROLLER_DEADZONE:
		# Utiliser l'entrée du joystick analogique si active
		direction = joystick_direction
	elif digital_direction.length() > 0:
		# Sinon utiliser D-Pad ou clavier si disponible
		direction = digital_direction
	
	# 4. Appliquer le mouvement
	if direction.length() > 0:
		# Normaliser seulement si nécessaire (pour conserver l'intensité du joystick)
		if direction.length() > 1.0:
			direction = direction.normalized()
		
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("electrons"):
			# Émettre le signal avec l'électron touché
			hit_electron.emit(collider)
	
	# Limiter la position du proton aux limites de l'écran
	enforce_screen_boundaries()

func enforce_screen_boundaries() -> void:
	# Calculer les limites en tenant compte du rayon du proton
	var min_x = proton_radius
	var min_y = proton_radius
	var max_x = screen_size.x - proton_radius
	var max_y = screen_size.y - proton_radius
	
	# Limiter la position à l'intérieur de l'écran
	position.x = clamp(position.x, min_x, max_x)
	position.y = clamp(position.y, min_y, max_y)
