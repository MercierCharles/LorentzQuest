extends Node2D

@onready var line: Line2D = $Line2D
@onready var arrowhead: Polygon2D = $Arrowhead  # Add a Polygon2D in the scene

func update_arrow(intensity, angle, field_scale):
	var field_vector = Vector2(field_scale * intensity, 0).rotated(angle)
	
	# Update main arrow line
	line.points = [Vector2.ZERO, field_vector]
	
	# Update arrowhead position
	arrowhead.position = field_vector
	arrowhead.rotation = angle
	arrowhead.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(-30, -15), Vector2(-30, 15)  # Triangle shape
	])
	arrowhead.color = Color(1, 1, 1)
