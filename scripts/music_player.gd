extends AudioStreamPlayer

var current_stream: AudioStream = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_music(music_stream: AudioStream):
	if music_stream == null:
		return
	# Si la musique est différente, on la change
	if music_stream != current_stream:
		current_stream = music_stream
		stream = music_stream
		play()
