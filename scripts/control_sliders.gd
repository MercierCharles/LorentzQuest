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

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT:
				h_slider_angle.value += DIRECTION_STEP
				if h_slider_angle.value >= h_slider_angle.max_value:
					h_slider_angle.value = h_slider_angle.min_value
			KEY_LEFT:
				h_slider_angle.value -= DIRECTION_STEP
				if h_slider_angle.value <= h_slider_angle.min_value:
					h_slider_angle.value = h_slider_angle.max_value
			KEY_UP:
				h_slider_norm.value = clamp(h_slider_norm.value + INTENSITY_STEP, 0.0, 1.0)
			KEY_DOWN:
				h_slider_norm.value = clamp(h_slider_norm.value - INTENSITY_STEP, 0.0, 1.0)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				click_start_position = event.position
				current_mouse_position = event.position
				_update_sliders()
				_gui_input(event)
			else:
				is_dragging = false
				current_mouse_position = event.position
				_update_sliders()
				_gui_input(event)
	elif event is InputEventMouseMotion and is_dragging:
			current_mouse_position = event.position
			_update_sliders()
			_gui_input(event)
			

func _update_sliders():
	var vector = current_mouse_position - click_start_position
	var norm = clamp(vector.length() / max_radius, 0.0, 1.0)
	var direction = vector.angle()

	h_slider_norm.value = norm
	h_slider_angle.value = fmod(direction + TAU, TAU)


func _gui_input(event):
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
	
func _update_knob_position():
	var direction = h_slider_angle.value
	var norm = h_slider_norm.value
	var offset = Vector2.RIGHT.rotated(direction) * (norm * max_radius)
	joystick_knob.position = joystick_background.size / 2 - joystick_knob.size / 2 + offset

	
func _process(delta):
	_update_knob_position()
