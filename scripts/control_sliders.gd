extends Control

@onready var h_slider_angle: HSlider = $HSliderAngle
@onready var h_slider_norm: HSlider = $HSliderNorm


const INTENSITY_STEP = 0.05  # Pas d'ajustement de l'intensité
const DIRECTION_STEP = 0.2   # Pas d'ajustement de la direction (en radians)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_RIGHT:
			h_slider_angle.value += DIRECTION_STEP
		elif event.keycode == KEY_LEFT:
			h_slider_angle.value -= DIRECTION_STEP
		elif event.keycode == KEY_UP:
			h_slider_norm.value += INTENSITY_STEP
		elif event.keycode == KEY_DOWN:
			h_slider_norm.value -= INTENSITY_STEP

		# On s'assure que les valeurs restent dans les bornes
		h_slider_norm.value = clamp(h_slider_norm.value, 0.0, 1.0)
		h_slider_angle.value = wrapf(h_slider_angle.value, 0.0, TAU)  # TAU = 2π
