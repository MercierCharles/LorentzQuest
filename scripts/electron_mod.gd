extends RigidBody2D

# Signal callback pour la mise à jour de la taille de l'écran
func _on_viewport_size_changed():
	# Mettre à jour la taille de l'écran lorsque le viewport change
	if is_instance_valid(shadow_node):
		update_shadow()


const K = 40000000.0  # Coulomb constant
const PROTON_CHARGE = 2.0
const ELECTRON_CHARGE = -1.0
const MASS = 1.0
@onready var proton = get_node("../../Proton")

# Variables pour l'ombre au bord de l'écran
var screen_size
var shadow_node
var is_outside_screen = false
const MAX_SHADOW_DISTANCE = 500.0  # Distance maximale pour l'affichage de l'ombre

# Référence au CanvasLayer pour l'ombre
var shadow_canvas_layer

func _ready():
	gravity_scale = 0  # Disable gravity
	linear_damp = 0.5  # Add some damping to prevent excessive velocities
	add_to_group("electrons")  # Mark this object as an electron
	
	# S'assurer que le nœud est prêt avant de continuer
	await get_tree().process_frame
	
	# Créer le nœud d'ombre
	create_shadow_node()
	
	# Connecter un signal pour recalculer la taille de l'écran lorsque celle-ci change
	get_viewport().size_changed.connect(self._on_viewport_size_changed)

func create_shadow_node():
	# Supprimer le nœud d'ombre s'il existe déjà
	if shadow_node and is_instance_valid(shadow_node):
		shadow_node.queue_free()
	
	# Créer un nouveau nœud d'ombre
	shadow_node = Line2D.new()
	shadow_node.width = 6.0
	shadow_node.default_color = Color(1, 0.53, 0.71, 0.8)  # Rose (255, 134, 181)
	shadow_node.points = [Vector2(0, 0), Vector2(0, 0)]  # Points initiaux
	shadow_node.z_index = -10  # Placer l'ombre en dessous des électrons
	shadow_node.visible = false  # Par défaut invisible
	
	# Utiliser un CanvasLayer pour s'assurer que l'ombre est relative à l'écran, pas au monde
	shadow_canvas_layer = CanvasLayer.new()
	shadow_canvas_layer.layer = -1  # Utiliser une couche inférieure pour que les ombres soient derrière les électrons
	add_child(shadow_canvas_layer)
	shadow_canvas_layer.add_child(shadow_node)

func _physics_process(delta: float) -> void:
	# Appliquer les forces électrostatiques
	if proton and is_instance_valid(proton):
		apply_coulomb_force(proton)  # Attraction vers le proton
	
	var electrons = get_tree().get_nodes_in_group("electrons")
	for electron in electrons:
		if electron != self:  # Évite l'auto-répulsion
			apply_coulomb_force(electron, true)
	
	# Mettre à jour l'ombre
	if is_instance_valid(shadow_node):
		update_shadow()
	else:
		create_shadow_node()

func apply_coulomb_force(other, other_is_electron: bool = false) -> void:
	var direction = other.global_position - global_position
	var distance_squared = max(direction.length_squared(), 100.0)  # Prevent divide by zero and extreme forces
	
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

func update_shadow() -> void:
	# Obtenir la taille de l'écran en coordonnées globales
	var viewport = get_viewport()
	if not viewport:
		return
		
	# Calculer les bords de l'écran en coordonnées globales
	var camera = viewport.get_camera_2d()
	var canvas_transform = viewport.global_canvas_transform
	screen_size = viewport.get_visible_rect().size
	
	var min_x = -canvas_transform.origin.x
	var min_y = -canvas_transform.origin.y
	var max_x = min_x + screen_size.x
	var max_y = min_y + screen_size.y
	
	# Obtenir le rayon de l'électron
	var radius = 10.0  # Valeur par défaut
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape is CircleShape2D:
		radius = collision_shape.shape.radius
	
	# Ajouter une petite marge pour que l'ombre apparaisse avant que l'électron ne sorte complètement
	var margin = radius * 0.1
	min_x += margin
	min_y += margin
	max_x -= margin
	max_y -= margin
	
	# Déterminer si l'électron est hors écran
	is_outside_screen = (global_position.x < min_x or global_position.x > max_x or 
						 global_position.y < min_y or global_position.y > max_y)
	
	# Mettre à jour la visibilité du shadow_node
	shadow_node.visible = is_outside_screen
	
	# Si l'électron est hors écran, calculer la position de l'ombre
	if is_outside_screen:
		var edge_point = Vector2()
		var closest_distance = INF
		var check_points = []
		
		# Vérifier les quatre bords pour trouver le point le plus proche
		if global_position.x < min_x:
			# Point sur le bord gauche
			var y = clamp(global_position.y, min_y, max_y)
			check_points.append(Vector2(min_x, y))
		
		if global_position.x > max_x:
			# Point sur le bord droit
			var y = clamp(global_position.y, min_y, max_y)
			check_points.append(Vector2(max_x, y))
		
		if global_position.y < min_y:
			# Point sur le bord supérieur
			var x = clamp(global_position.x, min_x, max_x)
			check_points.append(Vector2(x, min_y))
		
		if global_position.y > max_y:
			# Point sur le bord inférieur
			var x = clamp(global_position.x, min_x, max_x)
			check_points.append(Vector2(x, max_y))
		
		# Trouver le point le plus proche parmi tous les points candidats
		for point in check_points:
			var dist = global_position.distance_to(point)
			if dist < closest_distance:
				closest_distance = dist
				edge_point = point
		
		# Si aucun point n'a été trouvé (cas rare), utiliser le coin le plus proche
		if edge_point == Vector2():
			var corners = [
				Vector2(min_x, min_y),
				Vector2(max_x, min_y),
				Vector2(min_x, max_y),
				Vector2(max_x, max_y)
			]
			
			for corner in corners:
				var dist = global_position.distance_to(corner)
				if dist < closest_distance:
					closest_distance = dist
					edge_point = corner
		
		# Calculer la distance entre l'électron et le bord
		var distance = global_position.distance_to(edge_point)
		
		# Inverser la logique: plus l'électron est proche du bord, plus l'ombre est grande
		# Limiter la distance pour l'effet à MAX_SHADOW_DISTANCE
		var distance_factor = clamp(distance, 0, MAX_SHADOW_DISTANCE) / MAX_SHADOW_DISTANCE
		
		# L'ombre est plus grande quand distance_factor est petit (électron proche du bord)
		var min_size = 5.0   # Taille minimale de l'ombre (quand l'électron est très loin)
		var max_size = 20.0  # Taille maximale de l'ombre (quand l'électron est juste hors écran)
		var shadow_size = min_size + (max_size - min_size) * (1.0 - distance_factor)
		
		# Obtenir la direction entre l'électron et le point du bord
		var direction = (global_position - edge_point).normalized()
		
		# Mettre à jour les points perpendiculairement à la direction
		var perpendicular = Vector2(-direction.y, direction.x)
		shadow_node.points[0] = edge_point + perpendicular * shadow_size
		shadow_node.points[1] = edge_point - perpendicular * shadow_size
		
		# Ajuster l'opacité selon la distance (plus opaque quand plus proche)
		var shadow_color = shadow_node.default_color
		shadow_color.a = 0.3 + 0.7 * (1.0 - distance_factor)  # Entre 0.3 et 1.0
		shadow_node.default_color = shadow_color
