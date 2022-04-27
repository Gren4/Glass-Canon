extends Node
onready var Step : AudioStreamPlayer = $Step

func _ready():
	var Step_stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	Step_stream.audio_stream = preload("res://SoundEffects/Movement/Step.wav")
	Step_stream.random_pitch = 1.2
	Step.volume_db = -5
	Step.set_stream(Step_stream)
	pass

func step():
	Step.play()
