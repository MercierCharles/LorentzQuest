extends RigidBody2D

const CHARGE = -1.0  

var electric_field = Vector2.ZERO

func _ready():
	gravity_scale = 0  # Disable gravity

func _physics_process(_delta):
	var force = CHARGE * electric_field
	apply_central_force(force)

func set_electric_field(field: Vector2):
	electric_field = field
