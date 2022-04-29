extends RigidBody

var attack_damage : int = 20
var timer : float = 8
export(float) var speed_coef = 3.0
var parent : Object = null
onready var audio = $Audio/ProjectileSound
var sound = preload("res://SoundEffects/Enemies/Projectile2.wav")
var splash = preload("res://SoundEffects/Enemies/Splash.wav")
var hit_confirm : bool = false

func _ready():
	var stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	stream.audio_stream = sound
	stream.audio_stream.set_loop_mode(AudioStreamSample.LOOP_PING_PONG)
	stream.random_pitch = 1.2
	audio.set_stream(stream)
	audio.play()
	#set_as_toplevel(true)

func splash():
	var stream : AudioStreamRandomPitch = AudioStreamRandomPitch.new()
	stream.audio_stream = splash
	stream.random_pitch = 1.2
	audio.set_stream(stream)
	audio.play()
	hit_confirm = true
	self.set_linear_velocity(Vector3.ZERO)
	self.visible = false
	
func _physics_process(delta):
	
	if not hit_confirm:
		if timer <= 0:
			queue_free()
		else:
			timer -= delta
	else:
		if not audio.is_playing():
			queue_free()

func _on_Area_body_entered(body):
	if body != parent:
		if body.is_in_group("Player"):
			body.update_health(-attack_damage, self.global_transform.origin)
			splash()
		elif body.is_in_group("Enemy"): 
			body.update_hp(attack_damage)
			splash()
		else:
			splash()
