extends Node2D

@onready var time_label: Label = $TimeLabel
@onready var proton: CharacterBody2D = $Proton
@onready var win_scene_ui: CanvasLayer = $WinSceneUI
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var fail_label: Label = $GameOverUI/FailLabel
@onready var lost_label: Label = $GameOverUI/LostLabel
@onready var win_label: Label = $WinSceneUI/WinLabel
@onready var star_label: Label = $WinSceneUI/StarLabel
@onready var star_1: Sprite2D = $WinSceneUI/StarFull
@onready var star_2: Sprite2D = $WinSceneUI/StarFull2
@onready var star_3: Sprite2D = $WinSceneUI/StarFull3
@onready var theory_ui: CanvasLayer = $TheoryUI
@onready var play_button: Button = $TheoryUI/PlayButton  # Ensure this is the correct path to the button

var survival_time = 0.0  # Time in seconds
var is_running = false  # Game starts paused

func _ready():
	proton.hit_electron.connect(_on_proton_hit_electron)  # Connect proton's signal
	
	# Hide stars at the start
	star_1.visible = false
	star_2.visible = false
	star_3.visible = false
	
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
	if survival_time >= 5.0:
		level_completed()
	else:
		game_over()

func level_completed():
	is_running = false  # Stop timer
	get_tree().paused = true  # Pause the game
	win_label.text = "Time: %.2f s" % survival_time
	win_scene_ui.visible = true

	# 🌟 Star system based on survival time
	if survival_time >= 5.0:
		star_1.visible = true
		star_label.text = "Time for the second star : 20 s"
	if survival_time >= 20.0:
		star_2.visible = true
		star_label.text = "Time for the third star : 50 s"
	if survival_time >= 50.0:
		star_3.visible = true
		star_label.text = ""

func game_over():
	is_running = false  # Stop timer
	get_tree().paused = true  # Pause the game
	game_over_ui.visible = true
	lost_label.text = "Time: %.2f s" % survival_time
	fail_label.text = "Time to complete the level : 5 s"

func _on_play_button_pressed() -> void:
	GameState.has_seen_theory = true  # Mark theory as seen
	theory_ui.visible = false
	get_tree().paused = false  # Unpause the game
	is_running = true  # Start the game
