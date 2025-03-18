extends Camera2D

@onready var target: RigidBody2D = $"../ProtonLev2"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target:
		position.x = lerp(position.x, target.position.x, 5 * delta)  # Lissage du suivi en X
