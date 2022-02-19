extends Players_and_Enemies

export(NodePath) var timer_look_at_path = null
onready var timer_look_at : Timer = get_node(timer_look_at_path)
export(NodePath) var player_path = null
onready var player = get_node(player_path)

var target
onready var space_state : PhysicsDirectSpaceState = get_world().direct_space_state

var isAlive : bool = true
enum {IDLE, ALLERTED_AND_KNOWS_LOC,ALLERTED_AND_DOESNT_KNOW_LOC, LOOK_AT, LOOK_AT_ALLERT}
var point_of_interest : Vector3 = Vector3.ZERO
onready var _state : int = IDLE

func _ready():
	speed = 10.0
	current_health = 250

func _process(delta):
	if global_transform.origin.y < -50:
		queue_free()
		return

func move_to_target(delta):
	direction = (target.global_transform.origin - global_transform.origin)
	
func finalize_velocity(delta):
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * speed, accel * delta) + dop_velocity
	dop_velocity = dop_velocity.linear_interpolate(Vector3.ZERO, accel * delta)
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	
	move_and_slide_with_snap(velocity, snap, Vector3.UP, not_on_moving_platform, 4, deg2rad(45))
	
func reset_self(delta):
	direction = Vector3.ZERO
	if rotation.x != 0:
		if rotation.x > 0:
			rotation.x -= 4 * delta
		else:
			rotation.x += 4 * delta
		rotation.x = max(0,rotation.x)
	if rotation.z != 0:
		if rotation.z > 0:
			rotation.z -= 4 * delta
		else:
			rotation.z += 4 * delta
		rotation.z = max(0,rotation.z)
	

func _physics_process(delta):
	analyze_player(delta)
	movement(delta)
	
func analyze_player(delta):
	if is_instance_valid(target):
		point_of_interest = target.global_transform.origin
		var result = space_state.intersect_ray($MeshInstance2.global_transform.origin,point_of_interest,[self],5)
		if result:
			if result.collider.is_in_group("Player"):
				_state = ALLERTED_AND_KNOWS_LOC
				Global.look_face(self,point_of_interest, 30, delta)
				set_color_red()
		else:
			_state = ALLERTED_AND_DOESNT_KNOW_LOC
			reset_self(delta)
			set_color_orange()			
	else:
		reset_self(delta)

func movement(delta):
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= gravity * delta	
	
	match _state:
		LOOK_AT_ALLERT:
			Global.turn_face(self, point_of_interest, 10 ,delta)
		ALLERTED_AND_KNOWS_LOC:
			if is_instance_valid(target):
				move_to_target(delta)
	finalize_velocity(delta)

	


func update_hp(damage):
	if _state != ALLERTED_AND_KNOWS_LOC and _state != LOOK_AT_ALLERT:
		_state = LOOK_AT_ALLERT
		timer_look_at.start()
		set_color_blue()
	current_health -= damage
	if (current_health <= 0):
		queue_free()


func _on_LookAt_timeout():
	_state = ALLERTED_AND_DOESNT_KNOW_LOC
	target = player
	set_color_orange()

func _on_Area_body_entered(body):
	#if (body.is_in_group("Player")):
	if body == player:
		timer_look_at.stop()
		_state = ALLERTED_AND_KNOWS_LOC
		target = body
		set_color_red()

func _on_Area_body_exited(body):
	#if (body.is_in_group("Player")):
	#	target = null
	#	set_color_green()
	pass
	
func set_color_red():
	$MeshInstance.get_surface_material(0).set_albedo(Color(1,0,0))

func set_color_green():
	$MeshInstance.get_surface_material(0).set_albedo(Color(0,1,0))
	
func set_color_orange():
	$MeshInstance.get_surface_material(0).set_albedo(Color(1,0.43,0))
	
func set_color_blue():
	$MeshInstance.get_surface_material(0).set_albedo(Color(0,0,1))
