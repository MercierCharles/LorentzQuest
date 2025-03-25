extends Node2D

@onready var h_slider: HSlider = $CanvasLayer/Sliders/HSlider
@onready var proton: RigidBody2D = $ProtonLev4
@onready var finish_line: Area2D = $FinishLine
@onready var theory_ui: CanvasLayer = $TheoryUI
@onready var play_button: Button = $TheoryUI/PlayButton
@onready var win_scene_ui: CanvasLayer = $WinSceneUI
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var fail_label: Label = $GameOverUI/FailLabel
@onready var lost_label: Label = $GameOverUI/LostLabel
@onready var win_label: Label = $WinSceneUI/WinLabel
@onready var star_label: Label = $WinSceneUI/StarLabel
@onready var star_1: Sprite2D = $WinSceneUI/StarFull
@onready var star_2: Sprite2D = $WinSceneUI/StarFull2
@onready var star_3: Sprite2D = $WinSceneUI/StarFull3
@onready var time_label: Label = $CanvasLayer/TimeLabel

const GRID_SPACING = 400.0  
const FIELD_SCALE = 150.0  
const SYMBOL_SCENE = preload("res://scenes/magnetic_field_symbol_2d.tscn")  

var symbols = []  
var elapsed_time = 0.0  
var is_running = true  

func _ready():
	h_slider.min_value = -10.0  # Negative values → field "in"
	h_slider.max_value = 10.0   # Positive values → field "out"
	h_slider.value = 0.0       # Start at center (zero field)

	h_slider.value_changed.connect(_on_slider_changed)
	_generate_symbols()
	finish_line.level_completed.connect(_on_level_completed)

	if GameState.entering_from_menu:
		GameState.has_seen_theory_level4 = false  
		GameState.entering_from_menu = false  

	if GameState.has_seen_theory_level4:
		theory_ui.visible = false
		get_tree().paused = false  
		is_running = true
	else:
		theory_ui.visible = true
		theory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true  

func _process(delta):
	if is_running:
		elapsed_time += delta
		time_label.text = "Time: %.2f s" % elapsed_time

	# ✅ Adjust slider using left/right arrows
	var slider_step = 0.5  # Adjust sensitivity
	if Input.is_action_pressed("ui_right"):
		h_slider.value = min(h_slider.max_value, h_slider.value + slider_step)
	elif Input.is_action_pressed("ui_left"):
		h_slider.value = max(h_slider.min_value, h_slider.value - slider_step)


func _generate_symbols():
	var level_size = Vector2(18000, 2500)  
	var start_x = -level_size.x / 2
	var start_y = -level_size.y / 2

	for x in range(int(start_x), int(level_size.x / 2), int(GRID_SPACING)):
		for y in range(int(start_y), int(level_size.y / 2), int(GRID_SPACING)):
			var symbol = SYMBOL_SCENE.instantiate()
			symbol.global_position = Vector2(x, y)  
			symbol.set_direction("out" if randi() % 2 == 0 else "in")  # Random "out" or "in"
			add_child(symbol)
			symbols.append(symbol)

	_update_symbols()

func _on_slider_changed(_value):
	queue_redraw()  

	var intensity = h_slider.value * 2.0  # Keep it as a float

	# ✅ Fix: Pass a float instead of a Vector3
	proton.set_magnetic_field(intensity)

	_update_symbols()

func _update_symbols():
	var intensity = h_slider.value  
	var scale_factor = abs(intensity)  # , absolute value to avoid negative scaling

	# Determine the field direction based on slider value
	var direction = "out" if intensity > 0 else "in" if intensity < 0 else "none"

	for symbol in symbols:
		symbol.set_field_scale(scale_factor)
		if direction != "none":
			symbol.set_direction(direction)  # Update the direction dynamically

func _on_level_completed():
	is_running = false  # Stop the timer
	await get_tree().create_timer(0.5).timeout 
	get_tree().paused = true  
	win_scene_ui.visible = true  

	# Display final time
	win_label.text = "Time: %.2f s" % elapsed_time

	# 🌟 Assign stars based on time
	if elapsed_time > 60.0:
		game_over()
	elif elapsed_time >= 45.0:
		star_1.visible = true
		star_label.text = "Time for the second star : 45 s"
	elif elapsed_time >= 30.0:
		star_1.visible = true
		star_2.visible = true
		star_label.text = "Time for the third star : 30 s"
	else:
		star_1.visible = true
		star_2.visible = true
		star_3.visible = true
		star_label.text = ""

func game_over():
	is_running = false  
	get_tree().paused = true  
	game_over_ui.visible = true  
	lost_label.text = "Time: %.2f s" % elapsed_time
	fail_label.text = "Time to complete the level : 60 s"

func _on_play_button_pressed() -> void:
	GameState.has_seen_theory_level4 = true  # Mark theory as seen
	theory_ui.visible = false
	get_tree().paused = false  # Unpause the game
	is_running = true  # Start the game
