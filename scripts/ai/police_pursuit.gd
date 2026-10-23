extends ArcadeCar
## One police sedan. Follows Ghost / the getaway car. Separate from player driving input.

@export var follow_distance := 11.0
@export var stuck_seconds := 3.0
@export var unstuck_nudge := 8.0

var pursuit_active := false
var _stuck_timer := 0.0
var _blink := 0.0

@onready var light_red: MeshInstance3D = get_node_or_null("LightRed")
@onready var light_blue: MeshInstance3D = get_node_or_null("LightBlue")


func _ready() -> void:
	is_player_car = false
	max_speed = Game.vehicle_max_speed * 0.92
	super._ready()
	add_to_group("police")
	Game.wanted_changed.connect(_on_wanted)


func activate() -> void:
	pursuit_active = true


func deactivate() -> void:
	pursuit_active = false
	current_speed = 0.0


func _on_wanted(active: bool) -> void:
	pursuit_active = active


func _process(delta: float) -> void:
	if not pursuit_active:
		if light_red:
			light_red.visible = false
		if light_blue:
			light_blue.visible = false
		return
	_blink += delta
	var phase := fmod(_blink, 0.5) < 0.25
	if light_red:
		light_red.visible = phase
	if light_blue:
		light_blue.visible = not phase


func _ai_drive_command(delta: float) -> Vector2:
	if not pursuit_active:
		return Vector2.ZERO
	var target_pos := _target_position()
	var offset := target_pos - global_position
	offset.y = 0.0
	var dist := offset.length()
	if dist < 0.4:
		return Vector2.ZERO

	var desired := offset.normalized()
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	var angle := forward.signed_angle_to(desired, Vector3.UP)
	var steer := clampf(angle / 0.6, -1.0, 1.0)
	var throttle := 1.0
	if dist < follow_distance:
		throttle = 0.15
	elif dist < follow_distance * 1.6:
		throttle = 0.55

	if dist > 8.0 and absf(current_speed) < 0.55:
		_stuck_timer += delta
		if _stuck_timer >= stuck_seconds:
			_unstuck(desired)
	else:
		_stuck_timer = 0.0
	return Vector2(throttle, steer)


func _target_position() -> Vector3:
	var cars := get_tree().get_nodes_in_group("player_car")
	for car in cars:
		if car != self and is_instance_valid(car) and car.get("occupied"):
			return car.global_position
	if Game.player != null and is_instance_valid(Game.player):
		return Game.player.global_position
	return global_position


func _unstuck(dir: Vector3) -> void:
	_stuck_timer = 0.0
	global_position += dir * unstuck_nudge
	global_position.y = 0.4
	current_speed = max_speed * 0.4
