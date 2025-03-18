extends Node2D

@onready var proton_lev_2: RigidBody2D = $ProtonLev2

@onready var h_slider_angle: HSlider = $Sliders/ControlSliders/HSliderAngle
@onready var h_slider_norm: HSlider = $Sliders/ControlSliders/HSliderNorm

const FIELD_STRENGTH = 1000.0  # Intensité maximale du champ

func _process(_delta):
	# Récupérer les valeurs des sliders
	var norm = h_slider_norm.value  # Entre 0 et 1
	norm = norm*FIELD_STRENGTH
	var angle = h_slider_angle.value  # Entre 0 et 2π

	# Convertir en un vecteur
	var electric_field = Vector2(norm * cos(angle), norm * sin(angle))

	# Appliquer au proton
	proton_lev_2.set_electric_field(electric_field)
