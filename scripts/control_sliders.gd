extends Control

@onready var h_slider_angle: HSlider = $HSliderAngle
@onready var h_slider_norm: HSlider = $HSliderNorm

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
