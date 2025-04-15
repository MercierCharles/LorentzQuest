extends Node2D

@onready var time_label: Label = $TimeLabel
@onready var proton: CharacterBody2D = $Proton
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var fail_label: Label = $GameOverUI/FailLabel
@onready var lost_label: Label = $GameOverUI/LostLabel
@onready var theory_ui: CanvasLayer = $TheoryUI
@onready var play_button: Button = $TheoryUI/PlayButton  # Ensure this is the correct path to the button

var survival_time = 0.0  # Time in seconds
var is_running = false  # Game starts paused

func _ready():
	var music
	
	if GameState.selected_artist == "Bad Bunny" :
		music = load("res://assets/music/Bad Bunny/BAD BUNNY - CALLAÍTA (Video Oficial).mp3")
	elif GameState.selected_artist == "Morad" :
		music = load("res://assets/music/Morad/MORAD - NORMAL [VIDEO OFICIAL].mp3")
	elif GameState.selected_artist == "Myke Towers" :
		music = load("res://assets/music/Myke Towers/Myke Towers - Girl (Video Oficial).mp3")
		
	MusicPlayer.play_music(music)
	
	proton.hit_electron.connect(_on_proton_hit_electron)  # Connect proton's signal
	
		# Reset theory screen if coming from menu
	if GameState.entering_from_menu:
		GameState.has_seen_theory = false  
		GameState.entering_from_menu = false  # Reset this flag
	
	# Show theory only if it hasn't been seen
	if GameState.has_seen_theory:
		theory_ui.visible = false
		get_tree().paused = false  # Start game immediately
		is_running = true
	else:
		theory_ui.visible = true
		theory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true  # Pause until player presses Play

func _process(delta):
	if is_running:
		survival_time += delta  # Update timer
		time_label.text = "Time: %.2f s" % survival_time

func _on_proton_hit_electron():
	game_over()

func game_over():
	is_running = false  # Stop timer
	get_tree().paused = true  # Pause the game
	#GameManager.on_level_completed("CoulombForce", survival_time)
	if survival_time > GameState.best_time_CoulombForce :
		GameState.best_time_CoulombForce = survival_time
	game_over_ui.visible = true
	lost_label.text = "Time: %.2f s" % survival_time
	fail_label.text = "Record: %.2f s" % GameState.best_time_CoulombForce

func _on_play_button_pressed() -> void:
	GameState.has_seen_theory = true  # Mark theory as seen
	theory_ui.visible = false
	get_tree().paused = false  # Unpause the game
	is_running = true  # Start the game
