extends AudioStreamPlayer
onready var FireStart = preload("res://SoundEffects/Weapons/RiffleShotgun/FireStart.wav")
onready var FireEnd = preload("res://SoundEffects/Weapons/RiffleShotgun/FireEnd.wav")
onready var Fire = preload("res://SoundEffects/Weapons/RiffleShotgun/Fire.wav")

var type : int = 0

func _ready():
	set_physics_process(false)
	pass
	
func fire_start():
	var stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	stream.audio_stream = Fire
	stream.random_pitch = 1.05
	self.set_stream(stream)
	self.play()
	type = 1

func fire_end():
	set_physics_process(true)

func _physics_process(delta):
#	if not self.playing:
#		match type:
#			1:
#				var stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
#				stream.audio_stream = FireEnd
#				stream.random_pitch = 1.05
#				self.set_stream(stream)
#				self.play()
#				type = 0
#				set_physics_process(false)
	pass
