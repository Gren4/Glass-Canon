extends Enemies

export(NodePath) var hitboxl_path = null
export(NodePath) var hitboxr_path = null

export(NodePath) var ray_l_path = null
export(NodePath) var ray_r_path = null
export(NodePath) var ik_l_path = null
export(NodePath) var ik_r_path = null
export(NodePath) var point_l_path = null
export(NodePath) var point_r_path = null

onready var hitboxl = get_node(hitboxl_path)
onready var hitboxr = get_node(hitboxr_path)

onready var ray_l = get_node(ray_l_path)
onready var ray_r = get_node(ray_r_path)
onready var ik_l = get_node(ik_l_path)
onready var ik_r = get_node(ik_r_path)
onready var point_l = get_node(point_l_path)
onready var point_r = get_node(point_r_path)

var foot_l_up : bool = false
var foot_r_up : bool = false

func _ready() -> void:
	accel = 5.0
	SPEED_AIR = 18.0
	SPEED_DOP_ATTACK = 20.0
	SPEED_DOP_EVADE = 14.0
	SPEED_NORMAL = 19.0
	IDLE_TIMER = 3.0
	RESET_TIMER = 3.0
	ALLERTED_AND_KNOWS_LOC_TIMER = 20.0
	ALLERTED_AND_DOESNT_KNOW_LOC_TIMER = 3.0
	IDLE_TURN_TIMER = 3.0
	LOOK_AT_ALLERT_TIMER = 0.5
	ATTACK_CD_TIMER = 1.5
	NOT_IN_AIR_TIMER = 0.5
	animation_tree.set("parameters/IdleAlert/current",0)
	animation_tree.set("parameters/Zero/current",1)
	animation_tree.set("parameters/JumpTransition/current",0)
	animation_tree.set("parameters/JumpBlend/blend_amount",0)
	set_process(true)
	set_physics_process(true)
	call_deferred("init_timer_set")
	#$Body.scale.y = (0.9 + 0.2*randf())
	pass
	
func init_timer_set() -> void:
	StartTimer.wait_time = 0.1 + randf()*0.1
	StartTimer.start()
	
func ik_update() -> void:
	ray_l.force_raycast_update()
	ray_r.force_raycast_update()
	if not ray_l.is_colliding():
		#ik_l.interpolation = 0
		pass
	else:
		point_l.global_transform.origin = ray_l.get_collision_point()
		
	if not ray_r.is_colliding():
		#ik_r.interpolation = 0
		pass
	else:
		point_r.global_transform.origin = ray_r.get_collision_point()
	
func ik_setup() -> void:
	if ik_l.is_running() or ik_r.is_running():
		if dist_length > 15:
			ik_l.stop()
			ik_r.stop()
			return
		ik_update()
	else:
		if dist_length <= 15:
			ik_l.start()
			ik_r.start()
			ik_update()
	if ik_l.interpolation < 0.5 and foot_l_up == false:
		foot_l_up = true
	if ik_r. interpolation < 0.5 and foot_r_up == false:
		foot_r_up = true
	
#	if ik_l.interpolation == 1.0 and foot_l_up:
#		foot_l_up = false
#		audio.step()
#	if ik_r.interpolation == 1.0 and foot_r_up:
#		foot_r_up = false
#		audio.step()
	
func tact_init(delta : float) -> void:
	.tact_init(delta)
	ik_setup()

func _process(delta : float) -> void:
	if global_transform.origin.y < -50:
		death()
	
	
func state_machine(delta : float) -> void:
	match _state:
		IDLE:
			if not is_on_floor:
				if timer_not_on_ground >= NOT_IN_AIR_TIMER:
					set_state(AIR)
				else:
					timer_not_on_ground += delta
				return
			idle(delta)
		RESET:
			if reset_self(delta):
				set_state(IDLE)
		ALLERTED_AND_KNOWS_LOC:
			if not is_on_floor:
				if timer_not_on_ground >= NOT_IN_AIR_TIMER:
					set_state(AIR)
				else:
					timer_not_on_ground += delta
				return
			analyze_and_prepare_attack(delta)
		ATTACK_MELEE:
			attack()
			move_to_target(delta, 3.5, -dist, ATTACK_MELEE)
		EVADE:
			evading(delta)
		JUMP:
			face_threat(20,delta,link_to[0] + offset,link_to[0] + offset)
			if jump_time < 1.0:
				jump_time += delta / jump_time_coeff
				self.global_transform.origin = Global.quadratic_bezier(start_jump_pos,p1,link_to[0],jump_time)
				if jump_time >= 0.95:
					animation_tree.set("parameters/JumpTransition/current",2)
			else: 
				link_to.remove(0)
				link_from.remove(0)
				jump_time = 0.0
				audio.step()
				set_state(JUMP_END)
				
		AIR:
			if is_on_floor:
				animation_tree.set("parameters/JumpTransition/current",2)
				audio.step()
				set_state(JUMP_END)
				
		JUMP_END:
			if _timer >= 0.25:
				animation_tree.set("parameters/JumpBlend/blend_amount",0)
				_attack_timer = 0.0
				if allerted:
					set_state(ALLERTED_AND_KNOWS_LOC)
				else:
					set_state(IDLE)
			else:
				animation_tree.set("parameters/JumpBlend/blend_amount",1 - (1/0.25)*_timer)
				_timer += delta
		ALLERTED_AND_DOESNT_KNOW_LOC:
			look_for_player(delta)
		IDLE_TURN:
			pass
		LOOK_AT_ALLERT:
			look_at_allert(delta)
		DEATH:
			pass

func set_state(state : int) -> void:
	_timer = 0.0
	_dop_timer = 0.0
	_state = state
	match _state:
		IDLE:
			set_deferred("area_detection.monitoring", true)
			animation_tree.set("parameters/IdleAlert/current",0)
		RESET:
			set_deferred("area_detection.monitoring", true)
		LOOK_AT_ALLERT:
			animation_tree.set("parameters/IdleAlert/current",1)
		ALLERTED_AND_DOESNT_KNOW_LOC:
			animation_tree.set("parameters/IdleAlert/current",2)
			set_deferred("area_detection.monitoring", true)
		ALLERTED_AND_KNOWS_LOC:
			allerted = true
			animation_tree.set("parameters/IdleAlert/current",2)
			set_deferred("area_detection.monitoring", false)
		JUMP,AIR:
			animation_tree.set("parameters/JumpBlend/blend_amount",1)
			animation_tree.set("parameters/JumpTransition/current",0)
			direction = Vector3.ZERO
			velocityXY = Vector3.ZERO
		JUMP_END:
			direction = Vector3.ZERO
			velocityXY = Vector3.ZERO
		DEATH:
			death()
	
func attack() -> void:
	if hit_confirm:
		var targets
		match animation_tree.get("parameters/AttackTransition/current"):
			0:
				targets = hitboxl.get_overlapping_bodies()
			1:
				targets = hitboxr.get_overlapping_bodies()
		if player in targets:
			player.update_health(-attack_damage, self.global_transform.origin)
			audio.hit()
			hit_confirm = false

func on_animation_finish(anim_name:String) -> void:
	match anim_name:
		"AttackLeft", "AttackRight":
			_attack_timer = 0.0
			my_path.resize(0)
			link_from.resize(0)
			link_to.resize(0)
			set_state(ALLERTED_AND_KNOWS_LOC)
			velocityXY = velocityXY.normalized() * speed
			dop_speed = 0.0
			if attack_side + 1 >= 8:
				attack_side = 0
			else:
				attack_side += 1
			hit_confirm = false
	
func analyze_and_prepare_attack(delta : float) -> void:
	if _attack_timer < ATTACK_CD_TIMER:
		_attack_timer += delta
	if _attack_timer >= ATTACK_CD_TIMER:
			if dist_length <= 5.0:
				var result = space_state.intersect_ray(self.global_transform.origin,player.global_transform.origin,[self],11)
				if result:
					if result.collider.is_in_group("Player"):
						dop_speed = SPEED_DOP_ATTACK
						set_state(ATTACK_MELEE)
						animation_tree.set("parameters/Attack/active",true)
				_attack_timer = 0.0
	if not move_along_path(delta):
		evade_maneuver(delta, dist)

func move_along_path(delta : float) -> bool:
	if my_path.size() > 0:
		var dir_to_path = (my_path[0] - self.global_transform.origin)
		if link_from.size() > 0 and link_to.size() > 0:
			var dtp_l = (my_path[0] - link_from[0])
			if dtp_l.length() < 1.5 and dir_to_path.length() < 1.4:
				direction = Vector3.ZERO
				velocityXY = Vector3.ZERO
				start_jump_pos = self.global_transform.origin
				p1 = (link_to[0] + start_jump_pos) / 2  + Vector3(0,1*max(start_jump_pos.y,link_to[0].y),0)
				var jdist = (link_to[0] - start_jump_pos)
				jump_time_coeff = jdist.length() / speed
				jump_time_coeff = clamp(jump_time_coeff,0.5,0.8)
				offset = jdist.normalized()
				offset.y = 0
				while (link_to[0] in my_path):
					my_path.remove(0)
				audio.step()
				set_state(JUMP)
				return true
		if dir_to_path.length() < 1.4:
			my_path.remove(0)
		else:
			if is_on_wall():
				velocity.y = 1.0
				snap = Vector3.ZERO
			if dist_length < 3.5:
				left_ray.force_raycast_update()
				if not left_ray.is_colliding():
					move_to_target(delta, 3.5, Vector3.UP.cross(dir_to_path).normalized(), ALLERTED_AND_KNOWS_LOC,my_path[0])
			else:
				if dist_length > 8.0:
					move_to_target(delta, 3.5, dir_to_path, ALLERTED_AND_KNOWS_LOC,my_path[0])
				else:
					move_to_target(delta, 3.5, dir_to_path, ALLERTED_AND_KNOWS_LOC)
	else:
		front_ray.force_raycast_update()
		if front_ray.is_colliding():
			if dist2D_length > 4.5 and dist_length > 4.5:
				move_to_target(delta, 3.5, -dist, ALLERTED_AND_KNOWS_LOC)
			elif dist2D_length < 3.0:
				move_to_target(delta, 3.5, self.global_transform.basis.z, ALLERTED_AND_KNOWS_LOC)
			else:
				move_to_target(delta, 3.5, Vector3.ZERO, ALLERTED_AND_KNOWS_LOC)
		else:
			move_to_target(delta, 3.5, Vector3.ZERO, ALLERTED_AND_KNOWS_LOC)
	return false
		
func evade_setup(coef : int, dist_V : Vector3) -> void:
	direction = coef * side * Vector3.UP.cross(dist_V).normalized()
	side = coef * side
	dop_speed = SPEED_DOP_EVADE
	set_state(EVADE)
	
func evading(delta : float) -> void:
	match side:
		-1:
			left_down_ray.force_raycast_update()
			if not left_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				velocityXY = Vector3.ZERO
				side = 1
				set_state(ALLERTED_AND_KNOWS_LOC)
		1:
			right_down_ray.force_raycast_update()
			if not right_down_ray.is_colliding():
				direction = -dist
				dop_speed = 0.0
				velocityXY = Vector3.ZERO
				side = -1
				set_state(ALLERTED_AND_KNOWS_LOC)
				
	if _dop_timer >= 0.25:
		direction = -dist
		dop_speed = 0.0
		side = -side
		set_state(ALLERTED_AND_KNOWS_LOC)
	else:
		_dop_timer += delta
	move_to_target(delta, 3.5, -dist, EVADE)

func get_nav_path(path : Dictionary) -> void:
	if _state != JUMP and _state != JUMP_END:
		my_path = path["complete_path"]
		link_from.resize(0)
		link_to.resize(0)
		if not path["nav_link_to_first"].empty():
			if path["nav_link_path_inbetween"].empty():
				var to = path["nav_link_from_last"][0]
				var from = path["nav_link_to_first"][path["nav_link_to_first"].size()-1]
				if to in my_path and from in my_path:
					link_from.append(from)
					link_to.append(to)
			else:
				var from = path["nav_link_to_first"][path["nav_link_to_first"].size()-1]
				if from in my_path:
					link_from.append(from)
				for pp in path["nav_link_path_inbetween"].size():
					for p in path["nav_link_path_inbetween"][pp].size():
						if path["nav_link_path_inbetween"][pp][p][0] in my_path:
							link_to.append(path["nav_link_path_inbetween"][pp][p][0])
						if path["nav_link_path_inbetween"][pp][p][path["nav_link_path_inbetween"][pp][p].size()-1] in my_path:
							link_from.append(path["nav_link_path_inbetween"][pp][p][path["nav_link_path_inbetween"][pp][p].size()-1])
				var to = path["nav_link_from_last"][0]
				if to in my_path:
					link_to.append(to)

func play_audio(var name : String) -> void:
	match name:
		"Step":
			if is_moving:
				audio.step()
		"Whoosh":
			audio.whoosh()
			hit_confirm = true

func _on_Area_body_entered(body) -> void:
	if _state == IDLE:
		set_state(LOOK_AT_ALLERT)
		set_deferred("area_detection.monitoring", false)

func _on_Start_timeout() -> void:
	animation_tree.active = true
