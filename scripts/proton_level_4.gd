extends RigidBody2D

const CHARGE = 0.1  

var magnetic_field = 0.0  # Scalar value for B
var velocity := Vector2.ZERO  # Used to store current velocity

func _ready():
	gravity_scale = 0  # Disable gravity
	linear_velocity = Vector2(300, 0)

func _physics_process(_delta):
	velocity = linear_velocity  # Get current velocity
	
	# Lorentz Force: F = q * v × B
	var force = CHARGE * magnetic_field * Vector2(-velocity.y, velocity.x)  # Perpendicular to velocity
	
	apply_central_force(force)
	
	rotation = 2*linear_velocity.angle()


func set_magnetic_field(B: float):
	magnetic_field = B
