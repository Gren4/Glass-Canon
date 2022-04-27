extends AudioStreamPlayer
onready var Fire = preload("res://SoundEffects/Weapons/RiffleShotgun/Fire.wav")

func _ready():
	pass
	
func fire_start():
	var stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	stream.audio_stream = Fire
	stream.random_pitch = 1.05
	self.set_stream(stream)
	self.play()
	pass
