extends CharacterBody3D
## Arcade sedan. Custom CharacterBody3D controller (not VehicleBody3D) for stable
## low-spec testing: throttle, steer, brake, reverse, speed cap, no suspension sim.

class_name ArcadeCar

@export var is_player_car := true
@export var max_speed := 22.0
@export var reverse_speed := 7.5
@export var acceleration := 16.0
@export var brake_force := 26.0
@export var steer_speed := 1.55
@export var friction := 7.5
@export var max_health := 120.0
@export var interact_distance := 3.6

var occupied := false
var current_speed := 0.0
var health := 120.0
var occupant: Node3D = null
var stolen := false

signal vehicle_stolen
signal vehicle_destroyed

@onready var chase_camera: Camera3D = $ChaseCamera
@onready var exit_marker: Marker3D = $ExitMarker
@onready var body_mesh: MeshInstance3D = $Body


func _ready() -> void:
	add_to_group("vehicle")
	if is_player_car:
		add_to_group("player_car")
	health = max_health
	max_speed = Game.vehicle_max_speed
	acceleration = Game.vehicle_acceleration
	if chase_camera:
		chase_camera.current = false


func get_prompt() -> String:
	if occupied:
		return "Press E to exit the vehicle"
	return "Press E to enter the sedan"


func interact(actor: Node3D) -> void:
	if occupied:
		exit_vehicle()
	else:
		enter_vehicle(actor)


func enter_vehicle(actor: Node3D) -> void:
	if occupied or actor == null:
		return
	if global_position.distance_to(actor.global_position) > interact_distance + 0.8:
		return
	occupied = true
	occupant = actor
	if actor.has_method("set_driving"):
		actor.set_driving(true)
	if chase_camera:
		chase_camera.current = true
	if not stolen and is_player_car:
		stolen = true
		vehicle_stolen.emit()
	Game.set_prompt("Press E to exit")


func exit_vehicle() -> void:
	if not occupied or occupant == null:
		return
	var exit_pos := exit_marker.global_position if exit_marker else global_position + global_transform.basis.x * 2.2
	exit_pos.y = maxf(exit_pos.y, 0.2)
	occupant.global_position = exit_pos
	if occupant.has_method("set_driving"):
		occupant.set_driving(false)
	occupied = false
	if chase_camera:
		chase_camera.current = false
	occupant = null
	Game.set_prompt("")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = 0.0

	var throttle := 0.0
	var steer := 0.0
	if occupied and is_player_car and not Game.input_locked:
		throttle = Input.get_axis("move_back", "move_forward")
		steer = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("interact"):
			exit_vehicle()
			_move_on_ground(delta)
			return
	else:
		var cmd := _ai_drive_command(delta)
		throttle = cmd.x
		steer = cmd.y

	_apply_drive(throttle, steer, delta)
	_move_on_ground(delta)
	_spin_wheels(delta)
	if occupied and occupant != null and is_instance_valid(occupant):
		occupant.global_position = global_position + Vector3(0, 1.0, 0)


func _ai_drive_command(_delta: float) -> Vector2:
	return Vector2.ZERO


func _apply_drive(throttle: float, steer: float, delta: float) -> void:
	if throttle > 0.05:
		current_speed = move_toward(current_speed, max_speed, acceleration * delta * throttle)
	elif throttle < -0.05:
		if current_speed > 0.4:
			current_speed = move_toward(current_speed, 0.0, brake_force * delta)
		else:
			current_speed = move_toward(current_speed, -reverse_speed, brake_force * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, friction * delta)

	if absf(current_speed) > 0.35:
		rotate_y(-steer * steer_speed * delta * signf(current_speed))


func _move_on_ground(_delta: float) -> void:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	velocity.x = forward.x * current_speed
	velocity.z = forward.z * current_speed
	move_and_slide()
	if occupied:
		AudioHooks.play_engine()


func _spin_wheels(delta: float) -> void:
	var spin := current_speed * delta * 1.4
	for child in get_children():
		if child is MeshInstance3D and String(child.name).begins_with("Wheel"):
			(child as MeshInstance3D).rotate_x(spin)


func take_damage(amount: float, _from: Node = null) -> void:
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		current_speed = 0.0
		vehicle_destroyed.emit()
		if occupied:
			exit_vehicle()
			if Game.player and Game.player.has_method("take_damage"):
				Game.player.take_damage(80.0, self)
