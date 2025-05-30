extends Camera2D

@onready var target: RigidBody2D = $"../ProtonLev4"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target:
		position.x = lerp(position.x, target.position.x, 5 * delta)  # Lissage du suivi en X
		position.y = lerp(position.y, target.position.y, 5 * delta)  # Lissage du suivi en Y
