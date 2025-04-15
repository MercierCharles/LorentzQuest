extends CharacterBody2D
signal hit_electron  # Signal émis lors de la collision avec un électron

const SPEED = 600.0
const CONTROLLER_DEADZONE = 0.2  # Seuil pour ignorer les petits mouvements du joystick

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
			hit_electron.emit()
