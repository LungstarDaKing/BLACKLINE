class_name Enemy
extends CharacterBody3D
## Guard enemy. Sees the player inside a view cone with line of sight, hears
## nearby movement, then chases along the navmesh and attacks in melee range.
## Crouching makes the player harder to spot and hear.

signal state_changed(new_state: State)
signal died(enemy: Enemy)

enum State { IDLE, SUSPICIOUS, CHASE, ATTACK, SEARCH, DEAD }

@export_group("Senses")
@export var sight_range: float = 16.0
@export_range(10.0, 360.0) var fov_degrees: float = 110.0
## Distance at which a normally walking player is heard.
@export var hearing_range: float = 7.0
## Seconds of clear view needed to notice the player (shorter when close).
@export var reaction_time: float = 0.7
@export var awareness_decay: float = 0.4
@export var crouch_sight_scale: float = 0.5
@export var eye_height: float = 1.5

@export_group("Movement")
@export var walk_speed: float = 2.0
@export var chase_speed: float = 4.2
@export var turn_speed: float = 8.0
@export var acceleration: float = 14.0

@export_group("Combat")
@export var attack_range: float = 1.9
@export var attack_damage: float = 8.0
@export var attack_windup: float = 0.6
@export var attack_cooldown: float = 1.5
## Seconds without seeing the player before giving up the chase.
@export var lose_target_time: float = 4.0
@export var search_time: float = 4.0

var state: State = State.IDLE
var awareness: float = 0.0
var health: HealthComponent

var _player: PlayerController
var _home_position: Vector3
var _home_yaw: float
var _last_known_position: Vector3
var _lost_timer: float = 0.0
var _search_timer: float = 0.0
var _attack_cooldown_left: float = 0.0
var _windup_left: float = -1.0
var _repath_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _material: StandardMaterial3D

@onready var _visual: Node3D = $Visual
@onready var _body: MeshInstance3D = $Visual/Body
@onready var _label: Label3D = $StateLabel
@onready var _nav: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	add_to_group("enemy")
	_home_position = global_position
	_home_yaw = rotation.y
	_material = StandardMaterial3D.new()
	_body.material_override = _material
	health = get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.damaged.connect(_on_damaged)
		health.died.connect(_on_died)
	_apply_state_visuals()


func get_state_name() -> String:
	return State.keys()[state]


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	_repath_timer = maxf(_repath_timer - delta, 0.0)

	# The player joins its group in its own _ready(), which can run after ours.
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as PlayerController

	if _player == null or _player_is_dead():
		if state in [State.CHASE, State.ATTACK, State.SUSPICIOUS]:
			_set_state(State.IDLE)
		awareness = 0.0
	else:
		var tracking := state == State.CHASE or state == State.ATTACK
		_update_awareness(delta, _can_see_player(tracking), _can_hear_player())

	match state:
		State.IDLE:
			_process_idle(delta)
		State.SUSPICIOUS:
			_process_suspicious(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.SEARCH:
			_process_search(delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()


# --- senses -----------------------------------------------------------------

func _player_is_dead() -> bool:
	return _player.health != null and _player.health.is_dead


func _can_see_player(ignore_view_cone: bool) -> bool:
	var eye := global_position + Vector3.UP * eye_height
	var target := _player.global_position + Vector3.UP * (0.6 if _player.is_crouching else 1.1)
	var to := target - eye
	var max_distance := sight_range * (crouch_sight_scale if _player.is_crouching else 1.0)
	if to.length() > max_distance:
		return false
	if not ignore_view_cone:
		var flat := Vector3(to.x, 0.0, to.z)
		var forward := Vector3(-global_basis.z.x, 0.0, -global_basis.z.z)
		if flat.length() > 0.01 and forward.angle_to(flat) > deg_to_rad(fov_degrees * 0.5):
			return false
	var query := PhysicsRayQueryParameters3D.create(eye, target, Game.LAYER_WORLD)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _can_hear_player() -> bool:
	var speed := Vector3(_player.velocity.x, 0.0, _player.velocity.z).length()
	if speed < 0.5:
		return false
	var loudness := 1.0
	if _player.is_sprinting:
		loudness = 2.0
	elif _player.is_crouching:
		loudness = 0.4
	return global_position.distance_to(_player.global_position) <= hearing_range * loudness


func _update_awareness(delta: float, sees: bool, hears: bool) -> void:
	if sees:
		var closeness := 1.0 + clampf(1.0 - global_position.distance_to(_player.global_position) / sight_range, 0.0, 1.0)
		awareness += delta / reaction_time * closeness
		_last_known_position = _player.global_position
		_lost_timer = 0.0
	elif hears:
		awareness += delta / (reaction_time * 2.0)
		_last_known_position = _player.global_position
	else:
		awareness -= awareness_decay * delta
		_lost_timer += delta
	awareness = clampf(awareness, 0.0, 1.0)


# --- states -----------------------------------------------------------------

func _process_idle(delta: float) -> void:
	if awareness > 0.05:
		_set_state(State.SUSPICIOUS)
		return
	if global_position.distance_to(_home_position) > 0.6:
		_move_towards(_home_position, walk_speed, delta)
	else:
		_stop(delta)
		rotation.y = lerp_angle(rotation.y, _home_yaw, clampf(turn_speed * 0.5 * delta, 0.0, 1.0))


func _process_suspicious(delta: float) -> void:
	_stop(delta)
	_face_point(_last_known_position, delta)
	if awareness >= 1.0:
		_set_state(State.CHASE)
	elif awareness <= 0.0:
		_set_state(State.IDLE)


func _process_chase(delta: float) -> void:
	var player_position := _player.global_position
	var distance := global_position.distance_to(player_position)
	if distance <= attack_range:
		_set_state(State.ATTACK)
		return
	if _lost_timer >= lose_target_time:
		_set_state(State.SEARCH)
		return
	_move_towards(_last_known_position, chase_speed, delta)


func _process_attack(delta: float) -> void:
	_stop(delta)
	_face_point(_player.global_position, delta)
	var distance := global_position.distance_to(_player.global_position)
	if _windup_left >= 0.0:
		_windup_left -= delta
		if _windup_left < 0.0:
			if distance <= attack_range * 1.3:
				HealthComponent.apply_damage(_player, attack_damage, self)
			_attack_cooldown_left = attack_cooldown
		return
	if distance > attack_range * 1.4:
		_set_state(State.CHASE)
	elif _attack_cooldown_left <= 0.0:
		_windup_left = attack_windup
		_play_lunge()


func _process_search(delta: float) -> void:
	if awareness >= 1.0:
		_set_state(State.CHASE)
		return
	if global_position.distance_to(_last_known_position) > 1.2 and _search_timer < search_time:
		_move_towards(_last_known_position, walk_speed * 1.4, delta)
		return
	_stop(delta)
	_search_timer += delta
	if _search_timer >= search_time:
		awareness = 0.0
		_set_state(State.IDLE)


func _set_state(new_state: State) -> void:
	if state == new_state or state == State.DEAD:
		return
	state = new_state
	_windup_left = -1.0
	if new_state == State.CHASE:
		awareness = 1.0
		_lost_timer = 0.0
	elif new_state == State.SEARCH:
		_search_timer = 0.0
	_apply_state_visuals()
	state_changed.emit(new_state)


# --- movement ---------------------------------------------------------------

func _navigation_ready() -> bool:
	var map := _nav.get_navigation_map()
	return NavigationServer3D.map_get_iteration_id(map) > 0 \
		and not NavigationServer3D.map_get_regions(map).is_empty()


func _move_towards(point: Vector3, speed: float, delta: float) -> void:
	var direction := Vector3.ZERO
	if _navigation_ready():
		if _repath_timer <= 0.0:
			_nav.target_position = point
			_repath_timer = 0.2
		direction = _nav.get_next_path_position() - global_position
	direction.y = 0.0
	# No usable path (or no navmesh): head straight for the point.
	if direction.length() < 0.05 and global_position.distance_to(point) > 1.0:
		direction = point - global_position
		direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(direction * speed, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if direction != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), clampf(turn_speed * delta, 0.0, 1.0))


func _stop(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face_point(point: Vector3, delta: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(turn_speed * delta, 0.0, 1.0))


# --- reactions --------------------------------------------------------------

func _on_damaged(_amount: float, source: Node) -> void:
	if state == State.DEAD:
		return
	_flash()
	if source is PlayerController:
		_last_known_position = (source as Node3D).global_position
		awareness = 1.0
		_lost_timer = 0.0
		if state != State.ATTACK:
			_set_state(State.CHASE)


func _on_died(_source: Node) -> void:
	state = State.DEAD
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_apply_state_visuals()
	create_tween().tween_property(_visual, "rotation:x", deg_to_rad(-90.0), 0.4)
	state_changed.emit(State.DEAD)
	died.emit(self)
	get_tree().create_timer(6.0).timeout.connect(queue_free)


func _flash() -> void:
	_material.emission_enabled = true
	_material.emission = Color(1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(_material, "emission", Color(0.0, 0.0, 0.0), 0.15)


func _play_lunge() -> void:
	var tween := create_tween()
	tween.tween_property(_visual, "position:z", -0.35, attack_windup * 0.8)
	tween.tween_property(_visual, "position:z", 0.0, 0.2)


func _apply_state_visuals() -> void:
	match state:
		State.IDLE:
			_material.albedo_color = Color(0.45, 0.12, 0.12)
			_label.text = ""
		State.SUSPICIOUS:
			_material.albedo_color = Color(0.85, 0.55, 0.1)
			_label.text = "?"
		State.CHASE:
			_material.albedo_color = Color(0.95, 0.1, 0.1)
			_label.text = "!"
		State.ATTACK:
			_material.albedo_color = Color(1.0, 0.0, 0.0)
			_label.text = "!!"
		State.SEARCH:
			_material.albedo_color = Color(0.8, 0.45, 0.2)
			_label.text = "?"
		State.DEAD:
			_material.albedo_color = Color(0.2, 0.2, 0.2)
			_label.text = ""
