extends RigidBody2D

const K = 40000000.0  # Coulomb constant
const PROTON_CHARGE = 2.0
const ELECTRON_CHARGE = -1.0
const MASS = 1.0

@onready var proton = get_node("../../Proton")

func _ready():
	gravity_scale = 0  # Disable gravity
	add_to_group("electrons")  # Mark this object as an electron

func _physics_process(_delta: float) -> void:
	if proton:
		apply_coulomb_force(proton)  # Attraction vers le proton

	var electrons = get_tree().get_nodes_in_group("electrons")  # Mise à jour dynamique des électrons
	for electron in electrons:
		if electron != self:  # Évite l'auto-répulsion
			apply_coulomb_force(electron, true)

func apply_coulomb_force(other, other_is_electron: bool = false) -> void:
	var direction = other.position - position
	var distance_squared = max(direction.length_squared(), 1.0)  # Prevent divide by zero
	var force_magnitude

	if other_is_electron:
		force_magnitude = K * abs(ELECTRON_CHARGE * ELECTRON_CHARGE) / distance_squared
	else:
		force_magnitude = K * abs(PROTON_CHARGE * ELECTRON_CHARGE) / distance_squared
	
	var force_direction = direction.normalized()
	
	if other_is_electron:
		force_direction = -force_direction  # Reverse force direction for repulsion
	
	var acceleration = (force_direction * force_magnitude) / MASS
	apply_central_force(acceleration * MASS)  # Apply force
