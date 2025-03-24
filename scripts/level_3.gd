extends Node2D

@onready var h_slider_angle: HSlider = $CanvasLayer/Sliders/ControlSliders/HSliderAngle
@onready var h_slider_norm: HSlider = $CanvasLayer/Sliders/ControlSliders/HSliderNorm
@onready var electron_lev_3: RigidBody2D = $ElectronLev3
@onready var finish_line: Area2D = $FinishLine
@onready var time_label: Label = $CanvasLayer/TimeLabel
@onready var win_scene_ui: CanvasLayer = $WinSceneUI
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var fail_label: Label = $GameOverUI/FailLabel
@onready var lost_label: Label = $GameOverUI/LostLabel
@onready var win_label: Label = $WinSceneUI/WinLabel
@onready var star_label: Label = $WinSceneUI/StarLabel
@onready var star_1: Sprite2D = $WinSceneUI/StarFull
@onready var star_2: Sprite2D = $WinSceneUI/StarFull2
@onready var star_3: Sprite2D = $WinSceneUI/StarFull3

const GRID_SPACING = 400.0  
const FIELD_SCALE = 150.0  
const ARROW_SCENE = preload("res://scenes/arrow_2d.tscn")  

var arrows = []  
var elapsed_time = 0.0  
var is_running = true  

func _ready():
	h_slider_norm.value_changed.connect(_on_slider_changed)
	h_slider_angle.value_changed.connect(_on_slider_changed)
	_generate_arrows()
	finish_line.level_completed.connect(_on_level_completed)

	# Masquer les étoiles au début
	star_1.visible = false
	star_2.visible = false
	star_3.visible = false

func _process(delta):
	if is_running:
		elapsed_time += delta
		time_label.text = "Time: %.2f s" % elapsed_time

func _generate_arrows():
	var level_size = Vector2(18000, 2500)  
	var start_x = -level_size.x / 2
	var start_y = -level_size.y / 2

	for x in range(int(start_x), int(level_size.x / 2), int(GRID_SPACING)):
		for y in range(int(start_y), int(level_size.y / 2), int(GRID_SPACING)):
			var arrow = ARROW_SCENE.instantiate()
			arrow.global_position = Vector2(x, y)  
			add_child(arrow)
			arrows.append(arrow)

	_update_arrows()

func _on_slider_changed(_value):
	queue_redraw()  

	var intensity = h_slider_norm.value * 20  
	var angle = h_slider_angle.value  
	var electric_field = Vector2(FIELD_SCALE * intensity, 0).rotated(angle)
	
	electron_lev_3.set_electric_field(electric_field)
	_update_arrows()  

func _update_arrows():
	var intensity = h_slider_norm.value
	var angle = h_slider_angle.value

	for arrow in arrows:
		arrow.update_arrow(intensity, angle, FIELD_SCALE)

func _on_level_completed():
	is_running = false  # Arrête le compteur
	await get_tree().create_timer(0.5).timeout  
	get_tree().paused = true 
	win_scene_ui.visible = true  

	# Affichage du temps final
	win_label.text = "Time: %.2f s" % elapsed_time

	# 🌟 Attribution des étoiles en fonction du temps
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
