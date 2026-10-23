extends CharacterBody3D
## Idle / patrol / chase / fire with cooldown. No NavigationAgent — walks toward the target.

enum State { IDLE, PATROL, CHASE, ATTACK, DEAD }

@export var detect_range := 16.0
@export var attack_range := 9.0
@export var lose_range := 24.0
@export var move_speed := 3.3
@export var fire_interval := 1.2
@export var max_health := 70.0
@export var patrol_extent := 5.0

var state: State = State.PATROL
var health := 70.0
var _patrol_a := Vector3.ZERO
var _patrol_b := Vector3.ZERO
var _patrol_to_b := true
var _fire_cd := 0.0
var _los_blocked := false

@onready var weapon: Node = $Weapon
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_root: Node3D = $MeshRoot


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	_patrol_a = global_position + Vector3(-patrol_extent, 0.0, 0.0)
	_patrol_b = global_position + Vector3(patrol_extent, 0.0, 0.0)
	if weapon and weapon.has_method("_ready"):
		weapon.is_player_weapon = false
		weapon.damage = Game.enemy_damage
		weapon.fire_cooldown = fire_interval
		weapon.mag_size = 12
		weapon.reserve_ammo = 99
		weapon.mag = 12
		weapon.reserve = 99


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	_fire_cd = maxf(_fire_cd - delta, 0.0)
	var target := _current_target()
	var dist := 999.0
	if target != null:
		dist = Vector3(global_position.x, 0.0, global_position.z).distance_to(Vector3(target.x, 0.0, target.z))
		_los_blocked = not _has_line_of_sight(target)

	match state:
		State.IDLE, State.PATROL:
			_patrol(delta)
			if target != null and dist <= detect_range and not _los_blocked:
				state = State.CHASE
		State.CHASE:
			if target == null or dist > lose_range:
				state = State.PATROL
			elif dist <= attack_range and not _los_blocked:
				state = State.ATTACK
			else:
				_move_toward(target, delta)
		State.ATTACK:
			if target == null or dist > attack_range * 1.25 or _los_blocked:
				state = State.CHASE
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				_face(target)
				if _fire_cd <= 0.0:
					_shoot(target)
					_fire_cd = fire_interval

	move_and_slide()


func take_damage(amount: float, _from: Node = null) -> void:
	if state == State.DEAD:
		return
	health -= amount
	if state == State.IDLE or state == State.PATROL:
		state = State.CHASE
	if health <= 0.0:
		_die()


func _current_target() -> Vector3:
	if Game.player == null or not is_instance_valid(Game.player):
		return Vector3.ZERO
	return Game.player.global_position


func _patrol(delta: float) -> void:
	var dest := _patrol_b if _patrol_to_b else _patrol_a
	if Vector3(global_position.x, 0, global_position.z).distance_to(Vector3(dest.x, 0, dest.z)) < 0.6:
		_patrol_to_b = not _patrol_to_b
		dest = _patrol_b if _patrol_to_b else _patrol_a
	_move_toward(dest, delta)


func _move_toward(dest: Vector3, _delta: float) -> void:
	var offset := dest - global_position
	offset.y = 0.0
	if offset.length() < 0.15:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir := offset.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_face(dest)


func _face(dest: Vector3) -> void:
	var look := dest
	look.y = global_position.y
	if look.distance_to(global_position) > 0.1:
		mesh_root.look_at(look, Vector3.UP)


func _has_line_of_sight(dest: Vector3) -> bool:
	var from := global_position + Vector3(0, 1.2, 0)
	var to := dest + Vector3(0, 1.2, 0)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	return hit.is_empty()


func _shoot(dest: Vector3) -> void:
	if weapon == null:
		return
	var from := global_position + Vector3(0, 1.35, 0)
	var to := dest + Vector3(0, 1.2, 0)
	var exclude: Array[RID] = [get_rid()]
	weapon.fire_at(from, to, exclude)


func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	collision_shape.disabled = true
	if mesh_root:
		mesh_root.rotation.x = deg_to_rad(85.0)
	set_physics_process(false)
