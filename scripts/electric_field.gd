extends Node2D

@onready var intensity_slider = $"../Sliders/ControlSliders/HSliderNorm"  
@onready var direction_slider = $"../Sliders/ControlSliders/HSliderAngle"
@onready var camera: Camera2D = $"../Camera2D"

const FIELD_SCALE = 100.0  # Facteur de taille pour la flèche
const ARROW_SIZE = 15.0    # Taille de la pointe de la flèche
const GRID_SPACING = 200.0 # Espacement entre les flèches

func _ready():
	intensity_slider.value_changed.connect(_on_slider_changed)
	direction_slider.value_changed.connect(_on_slider_changed)

func _on_slider_changed(_value):
	queue_redraw()  # Redessiner les flèches

func _draw():
	var intensity = intensity_slider.value  # Entre 0 et 1
	var angle = direction_slider.value  # Entre 0 et 2π

	# Taille du viewport visible par la caméra
	var viewport_size = get_viewport_rect().size / camera.zoom
	var top_left = camera.position - viewport_size / 2
	var bottom_right = camera.position + viewport_size / 2

	# Parcours de la grille
	for x in range(int(top_left.x), int(bottom_right.x) + int(GRID_SPACING), int(GRID_SPACING)):
		for y in range(int(top_left.y), int(bottom_right.y) + int(GRID_SPACING), int(GRID_SPACING)):
			draw_arrow(Vector2(x, y), intensity, angle)

func draw_arrow(position, intensity, angle):
	var field_vector = Vector2(FIELD_SCALE * intensity, 0).rotated(angle)
	var end_pos = position + field_vector

	# Dessin de la flèche
	draw_line(position, end_pos, Color(1, 1, 1), 3)  # Ligne principale
	draw_arrowhead(end_pos, angle, Color(1, 1, 1))  # Pointe de la flèche

func draw_arrowhead(position, angle, color):
	var left = position + Vector2(-ARROW_SIZE, -ARROW_SIZE / 2).rotated(angle)
	var right = position + Vector2(-ARROW_SIZE, ARROW_SIZE / 2).rotated(angle)
	draw_triangle(position, left, right, color)

func draw_triangle(p1, p2, p3, color):
	draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([color]))
