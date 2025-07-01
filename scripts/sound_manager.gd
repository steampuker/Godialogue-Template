extends Button

@export var player: AudioStreamPlayer
@export var looping: bool = true
@export var play_on_start: bool = true

func _ready():
	assert(player != null)
	player.play()
	player.finished.connect(func(): if(looping): player.play())
	toggled.connect(func(pause: bool): player.stream_paused = pause)
	button_pressed = !play_on_start
