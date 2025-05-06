extends Node2D

@onready var time_label: Label = $TimeLabel
@onready var proton: CharacterBody2D = $Proton
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var fail_label: Label = $GameOverUI/FailLabel
@onready var lost_label: Label = $GameOverUI/LostLabel
@onready var theory_ui: CanvasLayer = $TheoryUI
@onready var play_button: Button = $TheoryUI/PlayButton
@onready var electron_spawner: Node2D = $ElectronSpawner
@onready var electron_container: Node2D = $ElectronContainer
@onready var electron_count_label: Label = $ElectronCountLabel
@onready var collision_sound: AudioStreamPlayer = $CollisionSound

var survival_time = 0.0 # Time in seconds
var is_running = false # Game starts paused
var collision_in_progress = false # Éviter les collisions multiples

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	LeaderboardManager_node.top_scores_received.connect(_on_top_scores_received)
	
	# Connection du bouton de lecture déjà faite dans l'éditeur de scène, pas besoin de le faire ici
	# play_button.pressed.connect(_on_play_button_pressed)
	
	# Chargement de la musique selon l'artiste sélectionné
	var music
	if GameState.selected_artist == "Bad Bunny":
		music = load("res://assets/music/Bad Bunny/BAD BUNNY - CALLAÍTA (Video Oficial).mp3")
	elif GameState.selected_artist == "Morad":
		music = load("res://assets/music/Morad/MORAD - NORMAL [VIDEO OFICIAL].mp3")
	elif GameState.selected_artist == "Myke Towers":
		music = load("res://assets/music/Myke Towers/Myke Towers - Girl (Video Oficial).mp3")
	elif GameState.selected_artist == "Ozuna":
		music = load("res://assets/music/Ozuna/Ozuna - Se Preparó (Audio).mp3")
	
	# Assurer que la musique joue même si on revient au même niveau
	if music:
		MusicPlayer.play_music(music)
	
	# S'assurer qu'on n'a pas de connexions multiples du signal
	if proton.hit_electron.is_connected(_on_proton_hit_electron):
		proton.hit_electron.disconnect(_on_proton_hit_electron)
	proton.hit_electron.connect(_on_proton_hit_electron)
	
	# Reset theory screen if coming from menu
	if GameState.entering_from_menu:
		GameState.has_seen_theory = false
		GameState.entering_from_menu = false # Reset this flag
	
	# Show theory only if it hasn't been seen
	if GameState.has_seen_theory:
		start_game()
	else:
		theory_ui.visible = true
		theory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true # Pause until player presses Play

func _process(delta):
	if is_running:
		survival_time += delta # Update timer
		time_label.text = "Time: %.2f s" % survival_time
		
		# Mise à jour du compteur d'électrons
		var electron_count = electron_container.get_child_count()
		electron_count_label.text = "Electrons: " + str(electron_count)

func _on_proton_hit_electron(electron_node):
	# Si une collision a déjà été traitée, ignorer
	if collision_in_progress:
		return
		
	# Marquer collision comme en cours pour éviter doublons
	collision_in_progress = true
	
	# Arrêter le timer immédiatement
	is_running = false
	
	# Jouer le son de collision
	if collision_sound and not collision_sound.playing:
		collision_sound.play()
	
	# Appeler game_over directement
	game_over()

func _show_leaderboard(scores):
	print("Top scores:")
	for i in range(scores.size()):
		var entry = scores[i]
		print("%d. %s: %.2f" % [i + 1, entry.username, entry.score])

func _on_top_scores_received(received_mini_game_id, scores):
	# Vérifier si c'est pour ce mini-jeu
	if received_mini_game_id != 0:
		return
	
	# Afficher les scores
	_show_leaderboard(scores)

func start_game():
	# Réinitialiser les variables
	survival_time = 0.0
	is_running = true
	collision_in_progress = false
	
	# Nettoyer les électrons existants
	for child in electron_container.get_children():
		child.queue_free()
	
	# Démarrer le spawner d'électrons
	electron_spawner.start()
	
	# Afficher l'interface de jeu
	theory_ui.visible = false
	game_over_ui.visible = false
	get_tree().paused = false # Unpause the game
	
	# Réinitialiser les étiquettes
	time_label.text = "Time: 0.00 s"
	electron_count_label.text = "Electrons: 0"
	
	# S'assurer que tout est visible et fonctionnel
	proton.visible = true
	proton.set_collision_layer_value(1, true)
	proton.set_collision_mask_value(1, true)

func game_over():
	# Vérifier si l'interface de game over est déjà visible pour éviter doublons
	if game_over_ui.visible:
		return
		
	# Pause le jeu
	get_tree().paused = true
	
	# Arrêter le spawner d'électrons
	electron_spawner.stop()
	
	# Vérifier si le score est dans le top 5
	LeaderboardManager_node.check_score(0, survival_time)
	LeaderboardManager_node.get_top_scores(0)
	LeaderboardManager_node.submit_score(0, GameState.username, survival_time)
	
	if survival_time > GameState.best_time_CoulombForce:
		GameState.best_time_CoulombForce = survival_time
	
	# Afficher l'écran de game over
	game_over_ui.visible = true
	lost_label.text = "Time: %.2f s" % survival_time
	fail_label.text = "Record: %.2f s" % GameState.best_time_CoulombForce

func _on_play_button_pressed() -> void:
	GameState.has_seen_theory = true # Mark theory as seen
	start_game()

func restart_game():
	game_over_ui.visible = false
	start_game()
