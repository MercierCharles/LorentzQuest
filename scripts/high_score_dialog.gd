# UserNameInput.gd
extends CanvasLayer

signal username_submitted(username: String, score: float)

@onready var username_input: LineEdit = $UsernameInput
@onready var score_label: Label = $ScoreLabel
@onready var submit_button: Button = $SubmitButton

var current_score: float = 0.0
var level_name: String = ""

func _ready():
	submit_button.pressed.connect(_on_submit_button_pressed)
	username_input.text_submitted.connect(_on_text_submitted)
	if current_score > 0:
		score_label.text = "Score: " + str(current_score)

func setup(score: float, level: String):
	current_score = score
	level_name = level
	if is_instance_valid(score_label):
		score_label.text = "Score: " + str(score)

func _on_text_submitted(text: String):
	_on_submit_button_pressed()

func _on_submit_button_pressed() -> void:
	print("Saisie de nom d'utilisateur pour high score")
	if username_input.text.strip_edges() != "":
		emit_signal("username_submitted", username_input.text, current_score)
		queue_free()
	else:
		username_input.placeholder_text = "Enter a valid name!"
