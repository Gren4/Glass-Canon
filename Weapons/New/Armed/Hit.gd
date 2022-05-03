extends AudioStreamPlayer
onready var Hit = preload("res://SoundEffects/Weapons/Hit.wav")

func _ready() -> void:
	pass
	
func hit() -> void:
	var stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	stream.audio_stream = Hit
	self.set_stream(stream)
	self.play()
	pass
