extends Node2D

@onready var timer: Timer = $Timer
@onready var time_label: Label = $TimeLabel

var survival_time = 0.0  # Store time as float

func _ready():
	timer.timeout.connect(_on_timer_timeout)  # Connect Timer Signal

func _on_timer_timeout():
	survival_time += 0.01  # Increase by 0.01s
	time_label.text = "Time: " + str("%.2f" % survival_time) + "s"  # Format to 2 decimal places
