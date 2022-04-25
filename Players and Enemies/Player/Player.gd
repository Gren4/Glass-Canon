extends Players_and_Enemies

### Ноды ###
export(NodePath) var head_path
export(NodePath) var wall_run_path
export(NodePath) var camera_path
export(NodePath) var weapon_manager_path

export(NodePath) var ray_climb_path
export(NodePath) var ray_top_path
export(NodePath) var ray_top_point_path
export(NodePath) var ray_empty_path

export(NodePath) var ray_forward_path

export(NodePath) var animation_tree_path
export(NodePath) var hud_path

onready var head = get_node(head_path)
onready var wall_run_camera = get_node(wall_run_path)
onready var camera = get_node(camera_path)
onready var weapon_manager = get_node(weapon_manager_path)

onready var rayClimb = get_node(ray_climb_path)
onready var rayTop = get_node(ray_top_path)
onready var rayTopPoint = get_node(ray_top_point_path)
onready var rayEmpty = get_node(ray_empty_path)

onready var rayForward = get_node(ray_forward_path)

onready var animation_tree = get_node(animation_tree_path)
onready var hud = get_node(hud_path)

### Перечисления ###
# Состояния
enum {
	WALKING,
	IN_AIR,
	DASHING,
	DASHING_AIR
	WALLRUNNING, 
	CLIMBING
	}
# Положение относительно стены
enum { 
	LEFT, 
	RIGHT,
	CENTER = -1
	}
	
enum { 
	BASE, 
	ALT,
	ADS
	}
### Константы ###
# Передвижение
const WALKING_SPEED : float = 18.0
const ADS_WALKING_SPEED : float = 10.0
const WALL_SPEED : float = 5.0
const WALLRUNNING_SPEED : float = 25.0
const DASHING_SPEED : float = 200.0
const MAX_WALL_JUMP : int = 3
const WALL_JUMP_HORIZONTAL_POWER : float = 20.0
const WALL_JUMP_VERTICAL_POWER : float = 0.7
const WALL_JUMP_FACTOR : float = 0.2
# Ограничительные углы
const RAD_ANGLE_HEAD_ROTATION_CLAMP : float = 1.54
const RAD_ANGLE_AXIS_XY_LIMITATION : float = 1.58
const DEG_ANGLE_AXIS_Z_LIMITATION : int = 75
const DEG_ANGLE_AXIS_XY_LIMITATION : int = 15
const WALLRUN_ANGLE_DELTA_COEFF : int = 70
const NO_WALLRUN_ANGLE_DELTA_COEFF : int = 40
# Ускорения
const ACCEL_GROUND : float = 10.0
const ACCEL_DOP : float = 30.0
const ACCEL_AIR : float = 5.0
# Гравитация
const IN_AIR_GRAVITY : float = 40.0
const GROUND_GRAVITATION : float = -0.1
const NEAR_WALL_GRAVITY : float = IN_AIR_GRAVITY / 3
const WALL_RUNNING_GRAVITY : float = IN_AIR_GRAVITY / 30
# Прыжок
const JUMP_POWER : float = 20.0
# Таймеры
const ABLILTY_TO_JUMP_TIME : float = 0.5
const DASHING_TIME : float = 0.1
const DASHING_TIME_CD : float = 0.5
const HP_RECOVERY_CD : float = 4.0
# Отклонения для параметров игрока
const PLAYER_HEIGHT_DEVIATION : float = 0.1
const SLIDE_JUMP_MULTIPLIER : float = 1.15

### Переменные ###
#Параметры игрока
onready var player_height : float = $CollisionShape.get_shape().height
# Состояние игрока
var State : int = WALKING
# Здоровье
var hp_recovery_timer : float = 0.0
var current_health : float = 100.0
var imunity : bool = false
# Оружие
var weapon_regime : int = BASE
# Управление мышью
const ADS_SENSIVITY : float = 0.1
const NORMAL_SENSIVITY : float = 0.3
var mouseSensivity : float = NORMAL_SENSIVITY
var mouse_input : Vector2
# Состояния коллизий
var isceil_tek : bool = true
var isfloor_tek : bool = true
var iswall_tek : bool = true
# Передвижение
var speed : float = WALKING_SPEED
var accel : float = ACCEL_GROUND
var coun_wall_jump : int = MAX_WALL_JUMP
var vel_info : Vector3 = Vector3.ZERO
var cur_speed : float = 0.0
# Внешние взаимодейтсвия
var interactable_items_count : int = 0
# Таймеры
var timer_not_on_ground : float = 0
var timer_dashing : float = 0
# Параметры для карабканья
var climbPoint : Vector3 = Vector3.ZERO
var rotateTo : Vector3 = Vector3.ZERO
# Параметры для бега по стене
var wall_id : int
var wallrun_dir_old : Vector3 = Vector3.ZERO
var sideW : int = -1
var sideD : int = -1
var wallrun_current_angle : float
var wall_normal : KinematicCollision = null

### Функции ###
func _ready() -> void:
	set_state(WALKING)
	update_health()
	set_disable_scale(true)
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_health(value = 0, origin : Vector3 = Vector3.ZERO) -> void:
	if value < 0 and not imunity:
		animation_tree.set("parameters/Hit/active",true)
		hp_recovery_timer = HP_RECOVERY_CD
		if origin != Vector3.ZERO:
			var point : Vector2 = Vector2(self.global_transform.origin.z,self.global_transform.origin.x).direction_to(Vector2(origin.z,origin.x))
			var base : Vector2 = Vector2(-self.global_transform.basis.z.z,-self.global_transform.basis.z.x)
			var degree : float = rad2deg(point.angle_to(base))
			hud.show_indicator(degree)
	current_health += value
	current_health = clamp(current_health,0,100)
	if current_health <= 0:
		current_health = 100
		global_transform.origin = Vector3(0,20,0)
	hud.update_health(int(current_health))

func _input(event) -> void:
	if event is InputEventMouseMotion:
		if weapon_regime == ADS:
			mouseSensivity = ADS_SENSIVITY
		else:
			mouseSensivity = NORMAL_SENSIVITY
		head.rotate_x(deg2rad(-event.relative.y * mouseSensivity))
		head.rotation.x = clamp(head.rotation.x, -RAD_ANGLE_HEAD_ROTATION_CLAMP, RAD_ANGLE_HEAD_ROTATION_CLAMP)
		mouse_input.y = event.relative.y
		if State != CLIMBING:
			self.rotate_y(deg2rad(-event.relative.x * mouseSensivity))
			mouse_input.x = event.relative.x
		
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_WHEEL_UP:
					weapon_manager.next_weapon()
				BUTTON_WHEEL_DOWN:
					weapon_manager.previous_weapon()

func get_point_for_npc(dist:float,side:int,type:String = "Melee") -> Vector3:
	var result : Vector3 = Vector3.ZERO
	var origin = self.global_transform.origin
	match side:
		0:
			result = Vector3(origin.x,origin.y,origin.z-dist)
			rayForward.set_cast_to(to_local(result))
			rayForward.force_raycast_update()
			if rayForward.is_colliding():
				result = rayForward.get_collision_point()
				if type == "Range":
					result.z = result.z*0.7
		1:
			result = Vector3(origin.x+dist,origin.y,origin.z)
			rayForward.set_cast_to(to_local(result))
			rayForward.force_raycast_update()
			if rayForward.is_colliding():
				result = rayForward.get_collision_point()
				if type == "Range":
					result.x = result.x*0.7
		2:
			result = Vector3(origin.x,origin.y,origin.z+dist)
			rayForward.set_cast_to(to_local(result))
			rayForward.force_raycast_update()
			if rayForward.is_colliding():
				result = rayForward.get_collision_point()
				if type == "Range":
					result.z = result.z*0.7
		3:
			result = Vector3(origin.x-dist,origin.y,origin.z)
			rayForward.set_cast_to(to_local(result))
			rayForward.force_raycast_update()
			if rayForward.is_colliding():
				result = rayForward.get_collision_point()
				if type == "Range":
					result.x = result.x*0.7
	
	return result


#func get_point_for_npc_local(dist,side) -> Vector3:
#	var result : Vector3 = Vector3.ZERO
#	match side:
#		0:
#			rayForward.set_cast_to(Vector3(0,0,-dist))
#			rayForward.force_raycast_update()
#			if rayForward.is_colliding():
#				result = rayForward.get_collision_point()
#			else:
#				result = to_global(rayForward.cast_to)
#		1:
#			rayForward.set_cast_to(Vector3(dist,0,0))
#			rayForward.force_raycast_update()
#			if rayForward.is_colliding():
#				result = rayForward.get_collision_point()
#			else:
#				result = to_global(rayForward.cast_to)
#		2:
#			rayForward.set_cast_to(Vector3(0,0,dist))
#			rayForward.force_raycast_update()
#			if rayForward.is_colliding():
#				result = rayForward.get_collision_point()
#			else:
#				result = to_global(rayForward.cast_to)
#		3:
#			rayForward.set_cast_to(Vector3(-dist,0,0))
#			rayForward.force_raycast_update()
#			if rayForward.is_colliding():
#				result = rayForward.get_collision_point()
#			else:
#				result = to_global(rayForward.cast_to)
#
#	return result
	
func _process(delta) -> void:
	weapon_manager.current_weapon.sway(mouse_input,delta)
	mouse_input = Vector2.ZERO
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
	if global_transform.origin.y < -50:
		global_transform.origin = Vector3(0,20,0)
		
func _physics_process(delta) -> void:
	primary_setup(delta)
	state_machine(delta)
	camera_transform(delta)
	process_weapons(delta)
	finalize_velocity(delta)
	animations_handler()
	
	
func state_machine(delta) -> void:
	match State:
		WALKING:
			movement_inputs()
			if jump(1):
				if start_dashing(delta,DASHING):
					if check_edge_climb():
						if check_wall_run():
							pass
		IN_AIR:
			movement_inputs()
			if check_edge_climb():
				if start_dashing(delta,DASHING_AIR):
					if wall_jump_air():
						if check_wall_run():
							pass
		CLIMBING:
			edge_climb(delta)
			pass
		WALLRUNNING:
			if check_edge_climb():
				if wall_jump_wallrun():
					if wall_run():
						pass
		DASHING:
			if check_edge_climb():
				if check_wall_run():
					if jump(SLIDE_JUMP_MULTIPLIER):
						if dashing(delta):
							pass
		DASHING_AIR:
			if check_edge_climb():
				if check_wall_run():
						if dashing(delta):
							pass
	
func set_state(state) -> void:
	State = state
	match state:
		WALKING:
			imunity = false
			timer_not_on_ground = 0.0
			if weapon_regime == ADS:
				speed = ADS_WALKING_SPEED
			else:
				speed = WALKING_SPEED
			accel = ACCEL_GROUND
			snap = Vector3.DOWN
			coun_wall_jump = MAX_WALL_JUMP
		IN_AIR:
			imunity = false
			if weapon_regime == ADS:
				speed = ADS_WALKING_SPEED
			else:
				speed = WALKING_SPEED
			accel = ACCEL_AIR
		CLIMBING:
			imunity = false
			speed = WALKING_SPEED
			accel = ACCEL_GROUND
			dop_velocity = Vector3.ZERO
			velocity = Vector3(0,JUMP_POWER,0)
			velocityXY = Vector3.ZERO
			snap = Vector3.ZERO
		WALLRUNNING:
			imunity = false
			speed = WALLRUNNING_SPEED
			accel = ACCEL_GROUND
			dop_velocity = Vector3.ZERO
			coun_wall_jump = MAX_WALL_JUMP
		DASHING, DASHING_AIR:
			imunity = true
			speed = DASHING_SPEED	
			dop_velocity = Vector3.ZERO
			timer_dashing = 0.0

func primary_setup(delta) -> void:
	cur_speed = vel_info.length()
	isfloor_tek = is_on_floor()
	iswall_tek = is_on_wall()
	isceil_tek = is_on_ceiling()
			
	match State:
		WALKING:
			if isfloor_tek:
				velocity.y = GROUND_GRAVITATION
				timer_not_on_ground = 0.0
				if weapon_regime == ADS:
					speed = ADS_WALKING_SPEED
				else:
					speed = WALKING_SPEED
			else:
				if iswall_tek:
					velocity.y -= NEAR_WALL_GRAVITY * delta
					speed = WALL_SPEED
				else:
					velocity.y -= IN_AIR_GRAVITY * delta
					speed = WALKING_SPEED
				if timer_not_on_ground >= ABLILTY_TO_JUMP_TIME:
					set_state(IN_AIR)
				else:
					timer_not_on_ground += delta
		IN_AIR:
			if isceil_tek:
				velocity.y -= WALL_RUNNING_GRAVITY
			if isfloor_tek:
				velocity.y = GROUND_GRAVITATION
				set_state(WALKING)
				animation_tree.set("parameters/Land/active", true)
			else:
				if iswall_tek:
					if velocity.y <= 0.0:
						velocity.y -= NEAR_WALL_GRAVITY * delta
					else:
						velocity.y -= IN_AIR_GRAVITY * delta
				else:
					velocity.y -= IN_AIR_GRAVITY * delta
		WALLRUNNING:
			velocity.y -= WALL_RUNNING_GRAVITY * delta
			
	
	if hp_recovery_timer > 0.0:
		hp_recovery_timer -= delta
	else:
		if current_health < 100.0:
			current_health += 5 * delta
			current_health = clamp(current_health,0,100)
			update_health()

func start_dashing(delta,state_) -> bool:
	if timer_dashing <= 0.0:
		if Input.is_action_just_pressed("shift"):
			if direction == Vector3.ZERO:
				direction -= self.global_transform.basis.z
			velocity.y = 0
			set_state(state_)
			return false
	else:
		timer_dashing -= delta
	return true
	
func dashing(delta) -> bool:
	if timer_dashing >= DASHING_TIME:
		velocityXY = direction * WALKING_SPEED
		timer_dashing = DASHING_TIME_CD
		set_state(IN_AIR)
		return false
	else:
		timer_dashing += delta
	return true
	
func check_wall_run() -> bool:
	if not isfloor_tek and iswall_tek and Input.is_action_pressed("shift") and Input.is_action_pressed("move_forward") and (velocity.y < (JUMP_POWER / 2)):
		for n in get_slide_count() :
			wall_normal = get_slide_collision(n)
			var isWall : bool = wall_normal.collider.is_in_group("Wall")
			if (isWall):
				# Нормаль к плоскости стены
				var normal : Vector3 = wall_normal.normal
				if normal.angle_to(Vector3.UP) > RAD_ANGLE_AXIS_XY_LIMITATION:
					break
				# Рассчитываем направление вдоль стены
				var wallrun_dir : Vector3 = Vector3.UP.cross(normal)
				# Считываем вектор3 направления камеры
				var player_view_dir : Vector3 = -head.global_transform.basis.z
				# Рассчитываем угол между вектором3 направлением движения и вектором3 направлением камеры
				var dot : float = wallrun_dir.dot(player_view_dir)
				# В зависимости от угла мы должны поменять сторону направления движения вдоль стены
				if dot < 0:
					wallrun_dir = -wallrun_dir
				# Проверяем под каким углом смотрим на стену. 
				# При небольшом угле бежать по стене не будем.
				# Двумерный вектор2 направления камеры игрока
				var view_dir_2d : Vector2 = Vector2(player_view_dir.x, player_view_dir.z)
				# Двумерный вектор2 стены
				var wallrun_axis_2d : Vector2 = Vector2(wallrun_dir.x, wallrun_dir.z)
				# Угол между вектором2 стены и вектором2 предыдущей стены
				var angle : float = wallrun_axis_2d.angle_to(view_dir_2d)
				angle = rad2deg(angle)
				if dot < 0:
					angle = -angle
				if angle < -DEG_ANGLE_AXIS_Z_LIMITATION:
					break
				# Добавляем к направлению движения небольшую силу в сторону стены, 
				# чтобы не отрываться от неё
				wallrun_dir += -normal * 0.05
				velocity.y = 0
				# Сохраняем номер последней стены, по которой бежали
				wall_id = wall_normal.collider_id;
				# Расчитываем сторону, противоположную от стены
				sideW = get_side(wall_normal.position)
				# Переопределяем глобальный вектор направления.
				# Ввод пользователя клавишами влево\вправо\назад будет проигнорирован.
				direction = wallrun_dir
				wallrun_dir_old = wallrun_dir
				set_state(WALLRUNNING)
				return false
	return true

func wall_run() -> bool:
	if isfloor_tek:
		set_state(WALKING)
		return false
	else:
		if Input.is_action_pressed("shift") and Input.is_action_pressed("move_forward") and (velocity.y < (JUMP_POWER / 2)) and iswall_tek:
			for n in get_slide_count() :
				wall_normal = get_slide_collision(n)
				# Расчитываем сторону, противоположную от стены
				sideW = get_side(wall_normal.position)
				if wall_id != wall_normal.collider_id:
					var isWall : bool = wall_normal.collider.is_in_group("Wall")
					if (isWall):
						# Нормаль к плоскости стены
						var normal : Vector3 = wall_normal.normal
						if normal.angle_to(Vector3.UP) > RAD_ANGLE_AXIS_XY_LIMITATION:
							break
						# Рассчитываем направление вдоль стены
						var wallrun_dir : Vector3 = Vector3.UP.cross(normal)
						# Считываем вектор3 направления камеры
						var player_view_dir : Vector3 = -head.global_transform.basis.z
						# Рассчитываем угол между вектором3 направлением движения и вектором3 направлением камеры
						var dot : float = wallrun_dir.dot(player_view_dir)
						# В зависимости от угла мы должны поменять сторону направления движения вдоль стены
						if dot < 0:
							wallrun_dir = -wallrun_dir
						var wallrun_axis_2d : Vector2 = Vector2(wallrun_dir.x, wallrun_dir.z)
						# Двумерный вектор2 предыдущей стены
						var wallrun_old_axis_2d : Vector2 = Vector2(wallrun_dir_old.x, wallrun_dir_old.z)
						# Угол между вектором2 стены и вектором2 предыдущей стены
						var angle : float = wallrun_axis_2d.angle_to(wallrun_old_axis_2d)
						angle = rad2deg(angle)
						if dot < 0:
							angle = -angle
						if angle < -DEG_ANGLE_AXIS_Z_LIMITATION:
							break
						# Добавляем к направлению движения небольшую силу в сторону стены, 
						# чтобы не отрываться от неё
						wallrun_dir += -normal * 0.05
						velocity.y = 0
						# Сохраняем номер последней стены, по которой бежали
						wall_id = wall_normal.collider_id;
						# Переопределяем глобальный вектор направления.
						# Ввод пользователя клавишами влево\вправо\назад будет проигнорирован.
						direction = wallrun_dir
						wallrun_dir_old = wallrun_dir
						return true
		else:
			set_state(IN_AIR)
			return false
	return true
		
func camera_transform(delta) -> void:
	match State:
		WALLRUNNING:
			if sideW == LEFT:
				wallrun_current_angle += delta * WALLRUN_ANGLE_DELTA_COEFF
				wallrun_current_angle = clamp(wallrun_current_angle, -DEG_ANGLE_AXIS_XY_LIMITATION, DEG_ANGLE_AXIS_XY_LIMITATION)
			elif sideW == RIGHT:
				wallrun_current_angle -= delta * WALLRUN_ANGLE_DELTA_COEFF
				wallrun_current_angle = clamp(wallrun_current_angle, -DEG_ANGLE_AXIS_XY_LIMITATION, DEG_ANGLE_AXIS_XY_LIMITATION)
			wall_run_camera.rotation_degrees.z =  wallrun_current_angle
#		DASHING, DASHING_AIR:
#			if (sideD == 0):
#				wallrun_current_angle += delta * NO_WALLRUN_ANGLE_DELTA_COEFF
#				wallrun_current_angle = clamp(wallrun_current_angle, -DEG_ANGLE_AXIS_XY_LIMITATION, DEG_ANGLE_AXIS_XY_LIMITATION)
#			elif (sideD == 1):
#				wallrun_current_angle -= delta * NO_WALLRUN_ANGLE_DELTA_COEFF
#				wallrun_current_angle = clamp(wallrun_current_angle, -DEG_ANGLE_AXIS_XY_LIMITATION, DEG_ANGLE_AXIS_XY_LIMITATION)
		_:
			if wallrun_current_angle != 0:
				if wallrun_current_angle > 0:
					wallrun_current_angle -= delta * NO_WALLRUN_ANGLE_DELTA_COEFF
					wallrun_current_angle = max(0, wallrun_current_angle)
				elif wallrun_current_angle < 0:
					wallrun_current_angle += delta * NO_WALLRUN_ANGLE_DELTA_COEFF
					wallrun_current_angle = min(wallrun_current_angle, 0)
				wall_run_camera.rotation_degrees.z =  wallrun_current_angle

func get_side(point) -> int:
	point = to_local(point)
	if point.x > 0:
		return LEFT
	elif point.x < 0:
		return RIGHT
	else:
		return CENTER

func movement_inputs() -> void:
	direction = Vector3.ZERO
	sideD = -1
	if Input.is_action_pressed("move_forward"):
		direction -= self.global_transform.basis.z
	elif Input.is_action_pressed("move_backwards"):
		direction += self.global_transform.basis.z
				
	if Input.is_action_pressed("move_right"):
		sideD = 1
		direction += self.global_transform.basis.x
	elif Input.is_action_pressed("move_left"):
		sideD = 0
		direction -= self.global_transform.basis.x

func jump(factor) -> bool:
	if Input.is_action_just_pressed("jump"):
		velocity.y = factor * JUMP_POWER
		velocityXY = direction * WALKING_SPEED
		snap = Vector3.ZERO
		animation_tree.set("parameters/Jump/active", true)
		set_state(IN_AIR)
		return false
	return true
	
func wall_jump_air() -> bool:
	if iswall_tek and coun_wall_jump > 0:
		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			velocityXY = Vector3.ZERO
			velocity.y = JUMP_POWER * WALL_JUMP_VERTICAL_POWER
			for n in get_slide_count() :
				var wall_normal = get_slide_collision(n)
				var isWall : bool = wall_normal.collider.is_in_group("Wall")
				if (isWall):
					wall_normal = get_slide_collision(0)
					var normal : Vector3 = wall_normal.normal
					dop_velocity = normal * WALL_JUMP_HORIZONTAL_POWER * WALL_JUMP_FACTOR
					coun_wall_jump -= 1
					return false
	return true

func wall_jump_wallrun() -> bool:
	if iswall_tek and coun_wall_jump > 0:
		if Input.is_action_just_pressed("jump"):
			snap = Vector3.ZERO
			velocityXY = Vector3.ZERO
			velocity.y = JUMP_POWER * WALL_JUMP_VERTICAL_POWER
			var normal : Vector3 = wall_normal.normal
			dop_velocity = normal * WALL_JUMP_HORIZONTAL_POWER * WALL_JUMP_FACTOR
			return false
	return true

func check_edge_climb() -> bool:
	if iswall_tek and not isfloor_tek and Input.is_action_pressed("move_forward"):
		rayClimb.force_raycast_update()
		for n in get_slide_count() :
			if rayClimb.is_colliding():
				if (rayClimb.get_collider() == get_slide_collision(n).collider):
					var ClimbPoint : Vector3 = to_local(rayClimb.get_collision_point())
					var normal : Vector3 = -get_slide_collision(n).normal
					var normal_2d : Vector2 = Vector2(normal.x, normal.z)
					# Считываем вектор3 направления камеры
					var player_view_dir : Vector3 = -head.global_transform.basis.z
					# Двумерный вектор2 направления камеры игрока
					var view_dir_2d : Vector2 = Vector2(player_view_dir.x, player_view_dir.z)
					# Угол между вектором2 стены и вектором2 направлением камеры игрока
					var angleClimb : float = rad2deg(normal_2d.angle_to(view_dir_2d))
					rayEmpty.translation.y = ClimbPoint.y + PLAYER_HEIGHT_DEVIATION
					rayEmpty.rotation_degrees.y = angleClimb
					rayTopPoint.translation.y = ClimbPoint.y
					rayEmpty.force_raycast_update()
					if not rayEmpty.is_colliding():
						rayTop.force_raycast_update()
						if rayTop.is_colliding():
							var TopPoint : Vector3 = to_local(rayTop.get_collision_point())
							if TopPoint.y - ClimbPoint.y < player_height + PLAYER_HEIGHT_DEVIATION:
								return true
						rayTopPoint.force_raycast_update()
						if rayTopPoint.is_colliding():
							var ClimbTopPoint : Vector3 = to_local(rayTopPoint.get_collision_point())
							if ClimbTopPoint.y - ClimbPoint.y < player_height + PLAYER_HEIGHT_DEVIATION:
								return true
						rotateTo = Vector3(0,self.rotation_degrees.y + angleClimb,0)
						climbPoint = (rayClimb.get_collision_point())
						direction = normal * 0.5
						if climbPoint.y - self.global_transform.origin.y > 1.0:
							weapon_manager.climb()
						set_state(CLIMBING)
						return false
					break
	return true

func edge_climb(delta) -> bool:
	self.rotation_degrees = self.rotation_degrees.linear_interpolate(rotateTo, delta * 10)
	if transform.origin.y > climbPoint.y + player_height or isfloor_tek or isceil_tek:
		direction = Vector3.ZERO
		velocity = Vector3.ZERO
		set_state(WALKING)
		return false
	return true

func process_weapons(delta) -> void:
	pass
	if interactable_items_count > 0:
		weapon_manager.process_weapon_pickup()
#
#	if Input.is_action_just_pressed("empty"):
#		weapon_manager.change_weapon("Empty")
#	if Input.is_action_just_pressed("primary"):
#		weapon_manager.change_weapon("Primary")
#	if Input.is_action_just_pressed("secondary"):
#		weapon_manager.change_weapon("Secondary")

	if Input.is_action_pressed("ads") and not weapon_manager.current_weapon.is_reloading:
		weapon_regime = weapon_manager.current_weapon.weapon_regime(true, delta)
	else:
		weapon_regime = weapon_manager.current_weapon.weapon_regime(false, delta)
#
	if not weapon_manager.is_switching_active():
		if Input.is_action_pressed("fire"):
			weapon_manager.fire()
#
#	if Input.is_action_just_pressed("reload"):
#		weapon_manager.reload()
#
#
#
#	if Input.is_action_just_pressed("drop"):
#		weapon_manager.drop_weapon()
		

func finalize_velocity(delta) -> void:
		
	direction = direction.normalized()
	velocityXY = velocityXY.linear_interpolate(direction * speed, accel * delta) + dop_velocity
	dop_velocity = dop_velocity.linear_interpolate(Vector3.ZERO, ACCEL_DOP * delta)
	velocity.x = velocityXY.x
	velocity.z = velocityXY.z
	vel_info = move_and_slide_with_snap(velocity, snap, Vector3.UP, not_on_moving_platform, 4, deg2rad(45))
	
func animations_handler() -> void:
	if State == WALKING:
		if isfloor_tek:
			animation_tree.set("parameters/HeadBop/blend_position", vel_info.length_squared() / pow(WALKING_SPEED,2))
		else:
			animation_tree.set("parameters/HeadBop/blend_position", 0)
	else:
		animation_tree.set("parameters/HeadBop/blend_position", 0)


