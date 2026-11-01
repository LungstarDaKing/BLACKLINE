class_name PlayerController
extends CharacterBody3D
## Third-person player movement. Input is camera-relative; only the visual
## model turns, so the camera rig stays stable. Group: "player".

signal crouch_changed(crouched: bool)
signal died

@export_group("Movement")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var crouch_speed: float = 2.2
@export_range(0.1, 1.0) var aim_speed_scale: float = 0.65
@export var ground_acceleration: float = 16.0
@export var ground_friction: float = 20.0
@export var air_acceleration: float = 6.0
@export var turn_speed: float = 14.0

@export_group("Jumping")
@export var jump_velocity: float = 5.0
## Gravity multiplier while falling; makes jumps feel less floaty.
@export var fall_gravity_scale: float = 1.4
## Upward speed is multiplied by this when jump is released early.
@export_range(0.0, 1.0) var jump_cut_scale: float = 0.5
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Crouch")
@export var standing_height: float = 1.8
@export var crouched_height: float = 1.1
## true: press to toggle. false: hold to crouch.
@export var crouch_toggle: bool = true

@export_group("Stairs")
## Highest ledge the player walks up without jumping.
@export var max_step_height: float = 0.3

@export_group("Nodes")
@export var camera_rig: CameraRig
@export var visual: Node3D

## False while dead or in a cutscene: all player input is ignored.
var input_enabled: bool = true
var is_sprinting: bool = false
var is_crouching: bool = false
var is_aiming: bool = false
## Peak height above the take-off point of the most recent jump (telemetry for tests).
var last_jump_height: float = 0.0
## Optional components, found by name among our children.
var health: HealthComponent
var inventory: Inventory

var _jump_origin_y: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _want_crouch: bool = false
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _combat_left: float = 0.0

@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _body_mesh: MeshInstance3D = $Visual/Body
@onready var _nose_mesh: MeshInstance3D = $Visual/Nose


func _ready() -> void:
	add_to_group("player")
	# Keep the body glued to the floor when walking down steps.
	floor_snap_length = max_step_height + 0.1
	# Resources are shared between scene instances; resize our own copies.
	_collision.shape = _collision.shape.duplicate()
	_body_mesh.mesh = _body_mesh.mesh.duplicate()
	_apply_height(standing_height)
	inventory = get_node_or_null("Inventory") as Inventory
	health = get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.damaged.connect(_on_damaged)
		health.died.connect(_on_died)


## Called by combat code so the character keeps facing the camera briefly.
func notify_combat(duration: float = 1.5) -> void:
	_combat_left = maxf(_combat_left, duration)


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	var move_input := Vector2.ZERO
	if input_enabled:
		move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_combat_left = maxf(_combat_left - delta, 0.0)
	is_aiming = input_enabled and Input.is_action_pressed("aim")

	_update_crouch()
	_update_jump(delta, on_floor)

	var yaw := camera_rig.get_yaw() if camera_rig else 0.0
	var direction := Vector3(move_input.x, 0.0, move_input.y).rotated(Vector3.UP, yaw)

	is_sprinting = (
		input_enabled and Input.is_action_pressed("sprint")
		and direction != Vector3.ZERO and not is_crouching and not is_aiming
	)
	var speed := walk_speed
	if is_crouching:
		speed = crouch_speed
	elif is_sprinting:
		speed = sprint_speed
	elif is_aiming:
		speed = walk_speed * aim_speed_scale
	var target := direction * speed

	var accel := air_acceleration
	if on_floor:
		accel = ground_acceleration if direction != Vector3.ZERO else ground_friction
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	_update_facing(direction, yaw, delta)

	if camera_rig:
		camera_rig.set_aiming(is_aiming)
		camera_rig.set_sprinting(is_sprinting)

	if on_floor and velocity.y <= 0.0:
		_try_step_up(Vector3(velocity.x, 0.0, velocity.z) * delta)

	move_and_slide()


func _update_crouch() -> void:
	if input_enabled:
		if crouch_toggle:
			if Input.is_action_just_pressed("crouch"):
				_want_crouch = not _want_crouch
		else:
			_want_crouch = Input.is_action_pressed("crouch")
		# Pressing sprint while crouched means "get up and run".
		if Input.is_action_just_pressed("sprint"):
			_want_crouch = false
	if _want_crouch and not is_crouching:
		_set_crouched(true)
	elif not _want_crouch and is_crouching and _can_stand():
		_set_crouched(false)


func _update_jump(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(_coyote_left - delta, 0.0)
		var gravity_scale := fall_gravity_scale if velocity.y < 0.0 else 1.0
		velocity.y -= _gravity * gravity_scale * delta

	if input_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer_left = jump_buffer_time
	else:
		_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		if is_crouching:
			# Jumping from a crouch stands up first, if there is room.
			_want_crouch = false
			if _can_stand():
				_set_crouched(false)
		if not is_crouching:
			velocity.y = jump_velocity
			_jump_buffer_left = 0.0
			_coyote_left = 0.0
			_jump_origin_y = global_position.y
			last_jump_height = 0.0

	if not on_floor:
		last_jump_height = maxf(last_jump_height, global_position.y - _jump_origin_y)

	if input_enabled and Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= jump_cut_scale


func _update_facing(direction: Vector3, yaw: float, delta: float) -> void:
	if visual == null:
		return
	var weight := clampf(turn_speed * delta, 0.0, 1.0)
	if is_aiming or _combat_left > 0.0:
		visual.rotation.y = lerp_angle(visual.rotation.y, yaw, weight)
	elif direction != Vector3.ZERO:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), weight)


func _can_stand() -> bool:
	var extra := standing_height - crouched_height
	return not test_move(global_transform, Vector3.UP * extra)


func _set_crouched(value: bool) -> void:
	is_crouching = value
	_apply_height(crouched_height if value else standing_height)
	if camera_rig:
		camera_rig.set_crouched(value)
	crouch_changed.emit(value)


func _apply_height(height: float) -> void:
	(_collision.shape as CapsuleShape3D).height = height
	_collision.position.y = height * 0.5
	(_body_mesh.mesh as CapsuleMesh).height = height
	_body_mesh.position.y = height * 0.5
	_nose_mesh.position.y = height - 0.35


func _on_damaged(amount: float, _source: Node) -> void:
	if camera_rig:
		camera_rig.add_shake(clampf(amount * 0.12, 0.6, 3.0))


func _on_died(_source: Node) -> void:
	input_enabled = false
	is_aiming = false
	is_sprinting = false
	if camera_rig:
		camera_rig.input_enabled = false
		camera_rig.set_aiming(false)
		camera_rig.set_sprinting(false)
	if visual:
		create_tween().tween_property(visual, "rotation:x", deg_to_rad(-90.0), 0.5)
	died.emit()


## Lifts the body over a low ledge directly in front of it. Floor snapping then
## settles it back onto the ledge top after the horizontal move.
func _try_step_up(motion: Vector3) -> void:
	if motion.length_squared() < 0.000001:
		return
	if not test_move(global_transform, motion):
		return # Nothing in the way.
	var lift := Vector3.UP * max_step_height
	if test_move(global_transform, lift):
		return # Ceiling directly above.
	if test_move(global_transform.translated(lift), motion):
		return # Obstacle is taller than a step.
	global_position += lift
