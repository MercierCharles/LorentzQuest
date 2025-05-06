extends Node2D

# Référence à la scène d'électron à instancier
@export var electron_scene: PackedScene
# Nœud contenant tous les électrons
@onready var electron_container = $"../ElectronContainer"
# Référence au proton pour calculer la distance initiale
@onready var proton = $"../Proton"
# Timer pour spawner un électron toutes les 30 secondes
@onready var spawn_timer: Timer = $SpawnTimer

# Distance minimale entre le proton et un nouvel électron
const MIN_DISTANCE_TO_PROTON = 300.0
# Marge pour les limites de l'écran (zone de confinement)
const SCREEN_MARGIN = 50.0

# Limites de l'écran
var screen_width = 0
var screen_height = 0
# Actif ou non
var is_active = false

func _ready():
	# Initialiser le timer
	spawn_timer.wait_time = 2.0  # 30 secondes entre chaque électron
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	
	# Obtenir les dimensions de l'écran
	var viewport_rect = get_viewport_rect()
	screen_width = viewport_rect.size.x
	screen_height = viewport_rect.size.y

func start():
	is_active = true
	# Spawner le premier électron immédiatement
	spawn_electron()
	# Démarrer le timer pour les électrons suivants
	spawn_timer.start()

func stop():
	is_active = false
	spawn_timer.stop()

func _on_spawn_timer_timeout():
	if is_active:
		spawn_electron()

func spawn_electron():
	# Créer une nouvelle instance d'électron
	var electron = electron_scene.instantiate()
	
	# Choisir une position de départ en dehors de l'écran
	var spawn_position = get_random_offscreen_position()
	
	# Placer l'électron à cette position
	electron.position = spawn_position
	
	# Calculer la direction vers le centre de l'écran pour la vitesse initiale
	var center = Vector2(screen_width / 2, screen_height / 2)
	var direction = (center - spawn_position).normalized()
	
	# Donner une vitesse initiale vers le centre de l'écran
	var initial_speed = 100.0
	electron.linear_velocity = direction * initial_speed
	
	# Ajouter l'électron au conteneur
	electron_container.add_child(electron)

func get_random_offscreen_position() -> Vector2:
	# Choisir un côté de l'écran (0=haut, 1=droite, 2=bas, 3=gauche)
	var side = randi() % 4
	
	var pos = Vector2()
	
	match side:
		0: # Haut
			pos.x = randf_range(0, screen_width)
			pos.y = -50.0 # Au-dessus de l'écran
		1: # Droite
			pos.x = screen_width + 50.0 # À droite de l'écran
			pos.y = randf_range(0, screen_height)
		2: # Bas
			pos.x = randf_range(0, screen_width)
			pos.y = screen_height + 50.0 # Sous l'écran
		3: # Gauche
			pos.x = -50.0 # À gauche de l'écran
			pos.y = randf_range(0, screen_height)
	
	# S'assurer que la position n'est pas trop proche du proton
	while (pos - proton.position).length() < MIN_DISTANCE_TO_PROTON:
		# Réessayer avec un autre côté
		side = (side + 1) % 4
		match side:
			0: # Haut
				pos.x = randf_range(0, screen_width)
				pos.y = -50.0
			1: # Droite
				pos.x = screen_width + 50.0
				pos.y = randf_range(0, screen_height)
			2: # Bas
				pos.x = randf_range(0, screen_width)
				pos.y = screen_height + 50.0
			3: # Gauche
				pos.x = -50.0
				pos.y = randf_range(0, screen_height)
	
	return pos
