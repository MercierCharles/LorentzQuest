extends CharacterBody2D

const SPEED = 600.0

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if direction.length() > 0:
		direction = direction.normalized()  # Normalise le vecteur directionnel
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO  # Arrêt progressif

	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("electrons"):
			game_over()
			
@onready var game_over_ui: CanvasLayer = $"../GameOverUI"

func game_over():
	print("Game Over!")  # Debugging
	get_tree().paused = true  # Pause game on loss
	game_over_ui.visible = true  # Show the Game Over UI
