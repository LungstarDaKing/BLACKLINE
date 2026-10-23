extends CharacterBody3D
## Kabelo "Ghost" Dlamini — on-foot controller, health, interact, death.

@export var max_health := 100.0

var health := 100.0
var driving := false
var dead := false
var _footstep_t := 0.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var interact_area: Area3D = $InteractArea


func _ready() -> void:
	add_to_group("player")
	health = max_health
	Game.register_player(self)
	Game.health_changed.emit(health, max_health)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if driving or dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump") and not Game.input_locked:
		velocity.y = Game.jump_velocity

	var input_dir := Vector2.ZERO
	if not Game.input_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var yaw_basis: Basis = camera_pivot.get_flat_basis() if camera_pivot.has_method("get_flat_basis") else global_transform.basis
	var direction := (yaw_basis.x * input_dir.x + yaw_basis.z * input_dir.y)
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
		var speed: float = Game.sprint_speed if Input.is_action_pressed("sprint") and not Game.input_locked else Game.move_speed
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var look_at_pos := global_position + Vector3(direction.x, 0.0, direction.z)
		$MeshRoot.look_at(look_at_pos, Vector3.UP)
		_footstep_t -= delta
		if _footstep_t <= 0.0 and is_on_floor():
			AudioHooks.play_footstep()
			_footstep_t = 0.42 if speed > 6.0 else 0.55
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_update_prompt()
	if global_position.y < -12.0:
		take_damage(max_health, self)

	if not Game.input_locked and Input.is_action_just_pressed("interact"):
		_interact()


func take_damage(amount: float, _from: Node = null) -> void:
	if dead or driving:
		return
	health = maxf(health - amount, 0.0)
	Game.health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


func heal_full() -> void:
	health = max_health
	Game.health_changed.emit(health, max_health)


func set_driving(active: bool) -> void:
	driving = active
	visible = not active
	collision_shape.disabled = active
	camera.current = not active
	velocity = Vector3.ZERO
	if active:
		Game.set_prompt("")


func _interact() -> void:
	var target := _nearest_interactable()
	if target != null:
		target.interact(self)


func _nearest_interactable() -> Node:
	var best: Node = null
	var best_d := 999.0
	for body in interact_area.get_overlapping_bodies():
		if body.has_method("interact"):
			var d: float = global_position.distance_to(body.global_position)
			if d < best_d:
				best_d = d
				best = body
	for area in interact_area.get_overlapping_areas():
		if area.has_method("interact"):
			var d: float = global_position.distance_to(area.global_position)
			if d < best_d:
				best_d = d
				best = area
		elif area.get_parent() != null and area.get_parent().has_method("interact"):
			var host: Node = area.get_parent()
			var d2: float = global_position.distance_to(host.global_position)
			if d2 < best_d:
				best_d = d2
				best = host
	return best


func _update_prompt() -> void:
	if driving or Game.input_locked:
		return
	var target := _nearest_interactable()
	if target != null and target.has_method("get_prompt"):
		Game.set_prompt(target.get_prompt())
	else:
		Game.set_prompt("")


func _die() -> void:
	dead = true
	velocity = Vector3.ZERO
	Game.mission_failed.emit("Ghost is down.")
