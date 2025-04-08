extends Camera2D
@onready var targetProton: RigidBody2D = $"../ProtonLev2"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if targetProton:
		position.x = lerp(position.x, targetProton.position.x, 5 * delta)  # Lissage du suivi en X
