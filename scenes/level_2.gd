extends Node2D

var bg_music: AudioStreamPlayer

func _ready():
	_setup_audio()

func _setup_audio():
	bg_music = AudioStreamPlayer.new()
	bg_music.stream = load("res://assets/audio/backgroundSound.mp3")
	bg_music.volume_db = -10.0
	bg_music.process_mode = Node.PROCESS_MODE_ALWAYS # keep playing even if paused
	add_child(bg_music)
	bg_music.play()
