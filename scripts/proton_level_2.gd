extends RigidBody2D

var charge = 1.0  

var electric_field = Vector2.ZERO

func _ready():
	gravity_scale = 0  # Disable gravity

func _physics_process(_delta):
	var force = charge * electric_field
	apply_central_force(force)

func set_electric_field(field: Vector2):
	electric_field = field

func _set_as_electron():
	$Sprite.texture = preload("res://assets/sprites/electron.png")
	adapt_sprite_to_collision()
	charge = -1

func _set_as_proton():
	$Sprite.texture = preload("res://assets/sprites/proton.png")
	adapt_sprite_to_collision()
	charge = +1

func adapt_sprite_to_collision():
	# Assurez-vous d'avoir un nœud CollisionShape2D comme enfant
	if $CollisionShape2D and $Sprite.texture:
		var collision_shape = $CollisionShape2D.shape
		var sprite_size = $Sprite.texture.get_size()
		
		if collision_shape is CircleShape2D:
			# Pour une forme circulaire
			var diameter = collision_shape.radius * 2
			var scale_factor = diameter / max(sprite_size.x, sprite_size.y)
			$Sprite.scale = Vector2(scale_factor, scale_factor)
		elif collision_shape is RectangleShape2D:
			# Pour une forme rectangulaire
			var scale_x = collision_shape.extents.x * 2 / sprite_size.x
			var scale_y = collision_shape.extents.y * 2 / sprite_size.y
			$Sprite.scale = Vector2(scale_x, scale_y) 
