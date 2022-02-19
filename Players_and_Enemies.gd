extends KinematicBody
class_name Players_and_Enemies

const ACCEL : float = 10.0
const ACCEL_AIR  : float= 5.0
enum { LEFT, RIGHT, CENTER = -1}
const SPEED_N : float = 20.0
const SPEED_W : float = 25.0
const SPEED_S : float = 100.0

var current_health : int = 100

var speed : float = SPEED_N
var accel : float = ACCEL
var gravity : float = 40.0

var dop_velocity : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.ZERO
var velocityXY : Vector3 = Vector3.ZERO
var direction : Vector3 = Vector3.ZERO
var snap : Vector3 = Vector3.DOWN

var not_on_moving_platform : bool = true


