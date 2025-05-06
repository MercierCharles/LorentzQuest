extends Control

@onready var artist_selector: OptionButton = $artist_selector
@onready var line_edit: LineEdit = $LineEdit

var artists = ["Bad Bunny", "Morad", "Myke Towers", "Ozuna"]

func _ready():
	line_edit.text_submitted.connect(on_username_entered)
	line_edit.text = GameState.username
	# Remplir le menu déroulant
	for artist in artists:
		artist_selector.add_item(artist)

	# Trouver l'index de l'artiste déjà sélectionné
	var index = artists.find(GameState.selected_artist)
	if index != -1:
		artist_selector.select(index)

	# Connecter le signal
	artist_selector.connect("item_selected", _on_artist_selected)

func _on_artist_selected(index):
	GameState.selected_artist = artists[index]


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/first_screen.tscn")


func on_username_entered(text: String):
	var name = text.strip_edges()
	if name != "":
		GameState.username = name
		print("Nom d'utilisateur enregistré : ", GameState.username)
		line_edit.release_focus()
	else:
		line_edit.placeholder_text = "Invalid username"
