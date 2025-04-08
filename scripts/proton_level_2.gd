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
	charge = -1

func _set_as_proton():
	$Sprite.texture = preload("res://assets/sprites/proton.png")
	charge = +1  
