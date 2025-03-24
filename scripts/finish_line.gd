extends Area2D
@onready var timer: Timer = $Timer

signal level_completed  # Signal to notify when the level is completed

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "ProtonLev2" or body.name == "ElectronLev3":  # Ensure it's the proton or electron
		level_completed.emit()
		print("Won")

  
