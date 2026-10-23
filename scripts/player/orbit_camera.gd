extends Node3D
## Third-person orbit camera. Yaw on this node, pitch on the SpringArm3D child.

@export var min_pitch_deg := -35.0
@export var max_pitch_deg := 50.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if Game.input_locked:
		return
	if event is InputEventMouseMotion:
		var sensitivity: float = Game.mouse_sensitivity * 0.012
		rotate_y(-event.relative.x * sensitivity)
		arm.rotate_x(-event.relative.y * sensitivity)
		arm.rotation.x = clampf(arm.rotation.x, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))


func get_flat_basis() -> Basis:
	var yaw := global_transform.basis
	var forward := -yaw.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := yaw.x
	right.y = 0.0
	right = right.normalized()
	return Basis(right, Vector3.UP, -forward)
