class_name WeaponHolder
extends Node
## Child of the player. Owns the weapon list, ammo, reloading and firing.
## Shots are hitscan rays from the camera crosshair; damage goes to any
## HealthComponent on the thing that was hit. Group: "weapon_holder".

signal weapon_changed(data: WeaponData)
signal ammo_changed(in_magazine: int, reserve: int)
signal fired
signal dry_fired
signal reload_started
signal reload_finished
signal target_hit(target: Node, damage: float)

@export var weapons: Array[WeaponData] = []

var current_index: int = -1
var is_reloading: bool = false

var _player: PlayerController
var _magazines: Array[int] = []
var _reserves: Array[int] = []
var _cooldown: float = 0.0
var _reload_left: float = 0.0
var _model: MeshInstance3D
var _tracer_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("weapon_holder")
	_player = get_parent() as PlayerController
	for data in weapons:
		_magazines.append(data.magazine_size)
		_reserves.append(data.starting_reserve)
	_tracer_material = StandardMaterial3D.new()
	_tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tracer_material.albedo_color = Color(1.0, 0.9, 0.4)
	_build_model()
	if not weapons.is_empty():
		equip(0)


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()
	_update_model_pose()
	if _player == null or not _player.input_enabled:
		return

	if Input.is_action_just_pressed("reload"):
		start_reload()
	if Input.is_action_just_pressed("weapon_1"):
		equip(0)
	if Input.is_action_just_pressed("weapon_2"):
		equip(1)
	if Input.is_action_just_pressed("weapon_next"):
		equip((current_index + 1) % maxi(weapons.size(), 1))

	var data := get_current()
	if data == null:
		return
	var wants_fire := Input.is_action_pressed("fire") if data.automatic \
		else Input.is_action_just_pressed("fire")
	if wants_fire:
		_try_fire(data)


func get_current() -> WeaponData:
	if current_index < 0 or current_index >= weapons.size():
		return null
	return weapons[current_index]


func get_magazine() -> int:
	return _magazines[current_index] if current_index >= 0 else 0


func get_reserve() -> int:
	return _reserves[current_index] if current_index >= 0 else 0


func equip(index: int) -> void:
	if index < 0 or index >= weapons.size() or index == current_index:
		return
	is_reloading = false
	current_index = index
	_cooldown = 0.2
	_refresh_model()
	weapon_changed.emit(get_current())
	ammo_changed.emit(get_magazine(), get_reserve())


func start_reload() -> void:
	var data := get_current()
	if data == null or is_reloading:
		return
	if _magazines[current_index] >= data.magazine_size or _reserves[current_index] <= 0:
		return
	is_reloading = true
	_reload_left = data.reload_time
	reload_started.emit()


## Adds reserve rounds to the current weapon. Returns false if already full.
func add_ammo(amount: int) -> bool:
	var data := get_current()
	if data == null or _reserves[current_index] >= data.max_reserve:
		return false
	_reserves[current_index] = mini(_reserves[current_index] + amount, data.max_reserve)
	ammo_changed.emit(get_magazine(), get_reserve())
	return true


func get_hud_text() -> String:
	var data := get_current()
	if data == null:
		return ""
	if is_reloading:
		return "%s\nRELOADING..." % data.display_name.to_upper()
	return "%s\n%d / %d" % [data.display_name.to_upper(), get_magazine(), get_reserve()]


func _finish_reload() -> void:
	is_reloading = false
	var data := get_current()
	var needed := data.magazine_size - _magazines[current_index]
	var taken := mini(needed, _reserves[current_index])
	_magazines[current_index] += taken
	_reserves[current_index] -= taken
	reload_finished.emit()
	ammo_changed.emit(get_magazine(), get_reserve())


func _try_fire(data: WeaponData) -> void:
	if is_reloading or _cooldown > 0.0:
		return
	if _magazines[current_index] <= 0:
		_cooldown = 0.3
		dry_fired.emit()
		start_reload()
		return
	_magazines[current_index] -= 1
	_cooldown = data.fire_interval
	for i in data.pellets:
		_fire_ray(data)
	var rig := _player.camera_rig
	if rig:
		rig.add_recoil(data.recoil_degrees)
	_player.notify_combat()
	fired.emit()
	ammo_changed.emit(get_magazine(), get_reserve())


func _fire_ray(data: WeaponData) -> void:
	var rig := _player.camera_rig
	if rig == null:
		return
	var origin := rig.get_aim_origin()
	var direction := rig.get_aim_direction()
	if data.spread_degrees > 0.0:
		direction = _apply_spread(direction, data.spread_degrees)
	# Start the ray level with the player so nothing behind them is hit.
	var head := _player.global_position + Vector3.UP * 1.3
	var along := maxf((head - origin).dot(direction), 0.0)
	var from := origin + direction * along
	var to := from + direction * data.max_range

	var query := PhysicsRayQueryParameters3D.create(
		from, to, Game.LAYER_WORLD | Game.LAYER_ENEMY, [_player.get_rid()]
	)
	var result := _player.get_world_3d().direct_space_state.intersect_ray(query)
	var end := to
	if not result.is_empty():
		end = result["position"]
		var collider := result["collider"] as Node
		if HealthComponent.apply_damage(collider, data.damage, _player):
			target_hit.emit(collider, data.damage)
	_spawn_tracer(_muzzle_position(), end)


func _apply_spread(direction: Vector3, degrees: float) -> Vector3:
	var basis := Basis.looking_at(direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)
	var angle := deg_to_rad(degrees) * sqrt(randf())
	var around := randf() * TAU
	var offset := Vector3(cos(around) * sin(angle), sin(around) * sin(angle), -cos(angle))
	return (basis * offset).normalized()


func _muzzle_position() -> Vector3:
	if _model:
		return _model.global_position + (-_model.global_basis.z) * (_model.mesh as BoxMesh).size.z * 0.5
	return _player.global_position + Vector3.UP * 1.2


func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.1:
		return
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.025, 0.025, length)
	tracer.mesh = mesh
	tracer.material_override = _tracer_material
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(tracer)
	var dir := (to - from).normalized()
	var up := Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT
	tracer.global_transform = Transform3D(Basis.looking_at(dir, up), (from + to) * 0.5)
	get_tree().create_timer(0.05).timeout.connect(tracer.queue_free)


func _build_model() -> void:
	if _player == null or _player.visual == null:
		return
	_model = MeshInstance3D.new()
	_model.name = "WeaponModel"
	_model.mesh = BoxMesh.new()
	_model.material_override = StandardMaterial3D.new()
	_player.visual.add_child(_model)


func _refresh_model() -> void:
	var data := get_current()
	if _model == null or data == null:
		return
	(_model.mesh as BoxMesh).size = data.model_size
	(_model.material_override as StandardMaterial3D).albedo_color = data.model_color


func _update_model_pose() -> void:
	if _model == null or _player == null:
		return
	_model.position = Vector3(0.3, 0.65 if _player.is_crouching else 1.05, -0.4)
