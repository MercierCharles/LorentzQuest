extends Control

@onready var joystick_background = $JoystickBackground
@onready var joystick_knob = $JoystickBackground/JoystickKnob

var is_dragging = false
var joystick_start_pos = Vector2.ZERO
var max_radius = 50  # Rayon max du joystick (ajuste selon ton besoin)

func _ready():
	hide_joystick()
	if Input.get_connected_joypads().size() > 0:
		joystick_background.visible = false
		joystick_knob.visible = false  # Hide the node
	else:
		joystick_background.visible = true
		joystick_knob.visible = true 



func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			joystick_start_pos = event.position
			show_joystick_at(joystick_start_pos)
		else:
			is_dragging = false
			hide_joystick()

	elif event is InputEventMouseMotion and is_dragging:
		update_joystick(event.position)

func show_joystick_at(position):
	joystick_background.position = position - joystick_background.size / 2
	joystick_knob.position = joystick_background.size / 2 - joystick_knob.size / 2
	joystick_background.show()

func hide_joystick():
	joystick_background.hide()

func update_joystick(current_pos):
	var offset = current_pos - joystick_start_pos
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	
	joystick_knob.position = (joystick_background.size / 2 - joystick_knob.size / 2) + offset

	# Tu peux ici récupérer la direction normalisée et la longueur si besoin :
	var direction = offset.normalized() if offset.length() > 0 else Vector2.ZERO
	var intensity = offset.length() / max_radius
