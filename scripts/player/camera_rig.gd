class_name CameraRig
extends Node3D
## Third-person over-the-shoulder camera.
##
## The rig is top-level: it follows its parent (the player) with its own
## smoothing, so step-ups and crouching do not snap the view. Yaw rotates this
## node, pitch rotates the SpringArm3D, and the arm is offset to the shoulder.

@export_group("Look")
@export var mouse_sensitivity: float = 0.0025
@export var aim_sensitivity_scale: float = 0.65
@export var stick_sensitivity: float = 2.8
@export_range(-89.0, 0.0) var min_pitch_deg: float = -60.0
@export_range(0.0, 89.0) var max_pitch_deg: float = 35.0
@export_range(-89.0, 89.0) var start_pitch_deg: float = -12.0

@export_group("Follow")
@export var standing_height: float = 1.6
@export var crouched_height: float = 1.1
## Higher = snappier vertical follow. Horizontal follow is always exact.
@export var vertical_smoothing: float = 14.0
@export var height_smoothing: float = 10.0

@export_group("Shoulder and zoom")
@export var shoulder_offset: float = 0.55
@export var arm_length: float = 3.5
@export var aim_arm_length: float = 2.1
@export var base_fov: float = 75.0
@export var aim_fov: float = 62.0
@export var sprint_fov: float = 82.0
@export var zoom_smoothing: float = 10.0

@export_group("Feel")
@export var recoil_recovery_deg: float = 14.0

@onready var _arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

## Set false to freeze look input (e.g. when the player is dead).
var input_enabled: bool = true

var _target: Node3D
var _yaw: float = 0.0
var _pitch: float = 0.0
var _recoil: float = 0.0
var _shake: float = 0.0
var _height: float = 1.6
var _aiming: bool = false
var _sprinting: bool = false
var _crouched: bool = false


func _ready() -> void:
	top_level = true
	_target = get_parent() as Node3D
	_height = standing_height
	_pitch = deg_to_rad(start_pitch_deg)
	# Do not let the arm collide with the body it belongs to.
	var body := _target as CollisionObject3D
	if body:
		_arm.add_excluded_object(body.get_rid())
	_arm.spring_length = arm_length
	_arm.position.x = shoulder_offset
	camera.fov = base_fov
	snap_to_target()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_rotation()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var look_scale := aim_sensitivity_scale if _aiming else 1.0
		_yaw -= event.relative.x * mouse_sensitivity * look_scale
		_pitch -= event.relative.y * mouse_sensitivity * look_scale
		_apply_rotation()


func _process(delta: float) -> void:
	if _target == null:
		return
	if input_enabled:
		var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if look != Vector2.ZERO:
			var look_scale := aim_sensitivity_scale if _aiming else 1.0
			_yaw -= look.x * stick_sensitivity * look_scale * delta
			_pitch -= look.y * stick_sensitivity * look_scale * delta

	_recoil = move_toward(_recoil, 0.0, deg_to_rad(recoil_recovery_deg) * delta)
	_follow(delta)
	_update_zoom(delta)
	_update_shake(delta)
	_apply_rotation()


## Horizontal rotation of the camera, used by the player for camera-relative movement.
func get_yaw() -> float:
	return _yaw


func get_aim_origin() -> Vector3:
	return camera.global_position


func get_aim_direction() -> Vector3:
	return -camera.global_basis.z


func set_aiming(value: bool) -> void:
	_aiming = value


func set_sprinting(value: bool) -> void:
	_sprinting = value


func set_crouched(value: bool) -> void:
	_crouched = value


## Kicks the view upwards; it recovers on its own.
func add_recoil(pitch_degrees: float) -> void:
	_recoil += deg_to_rad(pitch_degrees)


## Short camera shake, strength in degrees (try 0.5 to 2.0).
func add_shake(strength_degrees: float) -> void:
	_shake = maxf(_shake, strength_degrees)


## Jumps straight to the target without smoothing (spawn, teleport).
func snap_to_target() -> void:
	if _target:
		_height = crouched_height if _crouched else standing_height
		global_position = _target.global_position + Vector3(0.0, _height, 0.0)


func _follow(delta: float) -> void:
	var goal_height := crouched_height if _crouched else standing_height
	_height = lerpf(_height, goal_height, 1.0 - exp(-height_smoothing * delta))
	var goal := _target.global_position + Vector3(0.0, _height, 0.0)
	var pos := global_position
	pos.x = goal.x
	pos.z = goal.z
	pos.y = lerpf(pos.y, goal.y, 1.0 - exp(-vertical_smoothing * delta))
	global_position = pos


func _update_zoom(delta: float) -> void:
	var weight := 1.0 - exp(-zoom_smoothing * delta)
	var goal_fov := base_fov
	if _aiming:
		goal_fov = aim_fov
	elif _sprinting:
		goal_fov = sprint_fov
	camera.fov = lerpf(camera.fov, goal_fov, weight)
	_arm.spring_length = lerpf(_arm.spring_length, aim_arm_length if _aiming else arm_length, weight)


func _update_shake(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, 4.0 * delta)
	if _shake > 0.0:
		var amount := deg_to_rad(_shake)
		camera.rotation = Vector3(randf_range(-1.0, 1.0) * amount, randf_range(-1.0, 1.0) * amount, 0.0)
	else:
		camera.rotation = Vector3.ZERO


func _apply_rotation() -> void:
	_pitch = clampf(_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	_yaw = wrapf(_yaw, -PI, PI)
	rotation.y = _yaw
	_arm.rotation.x = clampf(_pitch + _recoil, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
