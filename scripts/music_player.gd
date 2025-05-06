extends AudioStreamPlayer

var current_stream: AudioStream = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_music(music_stream: AudioStream):
	music_stream.loop = true
	if music_stream == null:
		return
	
	# Si la musique est différente, on la change
	if music_stream != current_stream:
		current_stream = music_stream
		stream = music_stream
		play()
	# Si la même musique est demandée mais n'est pas en cours de lecture, la redémarrer
	elif !playing:
		play()


# Nouvelle méthode pour obtenir la piste audio actuelle
func get_current_track() -> AudioStream:
	return current_stream
