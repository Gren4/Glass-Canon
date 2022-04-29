extends Spatial
onready var Step : AudioStreamPlayer3D = $Step
onready var Hit : AudioStreamPlayer3D = $Hit
onready var Whoosh : AudioStreamPlayer3D = $Whoosh
onready var Shoot : AudioStreamPlayer3D = $Shoot

func _ready():
	var Step_stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	Step_stream.audio_stream = preload("res://SoundEffects/Movement/Step.wav")
	Step_stream.random_pitch = 1.2
	Step.set_stream(Step_stream)
	var Hit_stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	Hit_stream.audio_stream = preload("res://SoundEffects/Enemies/Splash.wav")
	Hit_stream.random_pitch = 1.2
	Hit.set_stream(Hit_stream)
	var Whoosh_stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	Whoosh_stream.audio_stream = preload("res://SoundEffects/Enemies/Whoosh.wav")
	Whoosh_stream.random_pitch = 1.2
	Whoosh.set_stream(Whoosh_stream)
	var Shoot_stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	Shoot_stream.audio_stream = preload("res://SoundEffects/Enemies/Shoot.wav")
	Shoot_stream.random_pitch = 1.2
	Shoot.set_stream(Shoot_stream)
	pass

func step():
	Step.play()
	
func hit():
	Hit.play()
	
func whoosh():
	Whoosh.play()
	
func shoot():
	Shoot.play()
