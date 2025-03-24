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

var survival_time = 0.0  # Temps en secondes
var is_running = true  # Indique si le niveau est en cours

func _ready():
	proton.hit_electron.connect(_on_proton_hit_electron)  # Connecte le signal du proton
	# Cacher les étoiles au début
	star_1.visible = false
	star_2.visible = false
	star_3.visible = false

func _process(delta):
	if is_running:
		survival_time += delta  # Ajoute le temps écoulé depuis la dernière frame
		time_label.text = "Time: %.2f s" % survival_time

func _on_proton_hit_electron():
	if survival_time >= 5.0:
		level_completed()
	else:
		game_over()

func level_completed():
	is_running = false  # Arrêter la mise à jour du temps
	win_label.text = "Time: %.2f s" % survival_time
	get_tree().paused = true
	win_scene_ui.visible = true

	# 🌟 Affichage des étoiles selon le temps de survie
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
	is_running = false  # Arrêter la mise à jour du temps
	get_tree().paused = true
	game_over_ui.visible = true
	lost_label.text = "Time: %.2f s" % survival_time
	fail_label.text = "Time to complete the level : 5 s"
