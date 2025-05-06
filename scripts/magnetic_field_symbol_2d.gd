extends Node2D

@export var direction: String = "out"  # "out" (⊙) or "in" (⊗)
var field_scale = 1.0  # Default size scale

const BASE_RADIUS = 10
const CROSS_LENGTH = 13.5
const DOT_RADIUS = 3
const CIRCLE_THICKNESS = 3  # Thickness for the outer circle

func _draw():
	var radius = BASE_RADIUS * field_scale
	var cross_size = CROSS_LENGTH * field_scale
	var dot_size = DOT_RADIUS * field_scale
	
	# ✅ Draw outlined circle (instead of a filled one)
	draw_arc(Vector2.ZERO, radius, 0, 2 * PI, 32, Color.DIM_GRAY, CIRCLE_THICKNESS)

	if direction == "out":
		# ✅ Draw a small filled dot in the center (⊙)
		draw_circle(Vector2.ZERO, dot_size, Color.DIM_GRAY)

	elif direction == "in":
		# ✅ Draw a cross (⊗) for field into the screen
		draw_line(Vector2(-cross_size / 2, -cross_size / 2), 
				  Vector2(cross_size / 2, cross_size / 2), Color.DIM_GRAY, 2)
		draw_line(Vector2(cross_size / 2, -cross_size / 2), 
				  Vector2(-cross_size / 2, cross_size / 2), Color.DIM_GRAY, 2)

func set_field_scale(scaling):
	field_scale = scaling
	queue_redraw()

func set_direction(new_direction):
	if new_direction in ["out", "in"]:
		direction = new_direction
		queue_redraw()
