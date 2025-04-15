extends Control

@onready var artist_selector: OptionButton = $artist_selector

var artists = ["Bad Bunny", "Morad", "Myke Towers"]

func _ready():
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
