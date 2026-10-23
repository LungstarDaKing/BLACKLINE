extends Node3D
## Hitscan handgun. Works for Ghost (player input) and for enemies (AI fire()).

@export var is_player_weapon := true
@export var mag_size := 12
@export var reserve_ammo := 36
@export var damage := 34.0
@export var fire_cooldown := 0.22
@export var reload_time := 1.35
@export var range_m := 75.0
@export var muzzle_flash_time := 0.05

var mag := 0
var reserve := 0
var _cooldown := 0.0
var _reloading := false
var _reload_left := 0.0

@onready var _flash: MeshInstance3D = get_node_or_null("MuzzleFlash")


func _ready() -> void:
	mag = mag_size
	reserve = reserve_ammo
	if _flash:
		_flash.visible = false
	_emit_ammo()


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()
	if is_player_weapon and not Game.input_locked:
		if Input.is_action_just_pressed("fire"):
			try_fire()
		if Input.is_action_just_pressed("reload"):
			try_reload()


func try_fire() -> void:
	if _reloading or _cooldown > 0.0:
		return
	if mag <= 0:
		if is_player_weapon:
			Game.notify_feedback("EMPTY — press R to reload")
		try_reload()
		return
	mag -= 1
	_cooldown = fire_cooldown
	_show_flash()
	AudioHooks.play_gunfire()
	_hitscan()
	_emit_ammo()


func try_reload() -> void:
	if _reloading or mag >= mag_size or reserve <= 0:
		if is_player_weapon and reserve <= 0 and mag <= 0:
			Game.notify_feedback("NO RESERVE AMMO")
		return
	_reloading = true
	_reload_left = reload_time
	if is_player_weapon:
		Game.notify_feedback("RELOADING")
	AudioHooks.play_reload()


func fire_at(from: Vector3, to: Vector3, exclude: Array[RID] = []) -> void:
	if _reloading or _cooldown > 0.0 or mag <= 0:
		try_reload()
		return
	mag -= 1
	_cooldown = fire_cooldown
	_show_flash()
	AudioHooks.play_gunfire()
	_cast(from, to, exclude)
	_emit_ammo()


func _finish_reload() -> void:
	var need := mag_size - mag
	var taken: int = mini(need, reserve)
	mag += taken
	reserve -= taken
	_reloading = false
	_emit_ammo()
	if is_player_weapon:
		Game.notify_feedback("")


func _hitscan() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_position
	var to := from + (-cam.global_transform.basis.z) * range_m
	var exclude: Array[RID] = []
	var body := get_parent()
	if body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	_cast(from, to, exclude)


func _cast(from: Vector3, to: Vector3, exclude: Array[RID]) -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	query.collision_mask = 1 | 2 | 4 | 8
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(damage * Game.difficulty if not is_player_weapon else damage, get_parent())


func _show_flash() -> void:
	if _flash == null:
		return
	_flash.visible = true
	get_tree().create_timer(muzzle_flash_time).timeout.connect(func() -> void:
		if is_instance_valid(_flash):
			_flash.visible = false
	)


func _emit_ammo() -> void:
	if is_player_weapon:
		Game.ammo_changed.emit(mag, reserve)
