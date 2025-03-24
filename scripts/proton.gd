extends CharacterBody2D

signal hit_electron  # Signal émis lors de la collision avec un électron

const SPEED = 600.0

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("electrons"):
			hit_electron.emit()  # Émettre le signal au lieu d'appeler game_over()
