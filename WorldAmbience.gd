extends AudioStreamPlayer
onready var OpenSpace = preload("res://SoundEffects/Ambience/OpenSpace.ogg")

func _ready():
	var stream : AudioStreamOGGVorbis = OpenSpace
	self.set_stream(stream)
	self.volume_db = -10.0
	self.play()
	pass
