extends Node3D
## MISSION 01: THIRTEEN MINUTES — full playable loop.

enum Phase { BRIEFING, STEAL, PURSUIT, SAFEHOUSE, ENDING, FAILED, COMPLETE }

var phase: Phase = Phase.BRIEFING
var _lines: Array[Dictionary] = []
var _line_i := 0
var _pursuit_time := 0.0
var dialogue_open := false
const TIME_LIMIT := 13.0 * 60.0

@onready var player: Node3D = $Player
@onready var getaway: Node3D = $GetawaySedan
@onready var police: Node3D = $PoliceSedan
@onready var ui: Node = $GameUI
@onready var district: Node3D = $District


func _ready() -> void:
	Game.wanted = false
	Game.input_locked = true
	Game.mission_failed.connect(_on_failed)
	if getaway.has_signal("vehicle_stolen"):
		getaway.vehicle_stolen.connect(_on_stolen)
	if getaway.has_signal("vehicle_destroyed"):
		getaway.vehicle_destroyed.connect(_on_car_destroyed)
	if getaway.has_method("add_to_group"):
		getaway.add_to_group("player_car")
	_place_actors()
	var zone := district.get_node_or_null("SafehouseZone")
	if zone:
		zone.body_entered.connect(_on_safehouse_body)
	_start_briefing()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_open:
		return
	var click := event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or click:
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if dialogue_open:
		return
	if phase == Phase.PURSUIT:
		_pursuit_time += delta
		var dest: Vector3 = district.safehouse_pos
		var here: Vector3 = getaway.global_position if getaway.get("occupied") else player.global_position
		var dist := Vector2(here.x, here.z).distance_to(Vector2(dest.x, dest.z))
		var progress := clampf(1.0 - dist / 120.0, 0.0, 1.0)
		ui.set_escape_progress(progress, _pursuit_time, TIME_LIMIT)
		if _pursuit_time >= TIME_LIMIT:
			_on_failed("Thirteen minutes are gone. The net closed.")


func _place_actors() -> void:
	player.global_position = district.player_spawn
	getaway.global_transform = district.car_spawn
	getaway.rotate_y(PI)
	police.global_transform = district.police_spawn
	police.rotate_y(PI)
	var i := 1
	for spawn in district.enemy_spawns:
		var n := get_node_or_null("Enemy%d" % i)
		if n:
			n.global_position = spawn
		i += 1


func _start_briefing() -> void:
	phase = Phase.BRIEFING
	Game.set_objective("Listen to the briefing.")
	_lines = [
		{"speaker": "HANDLER", "text": "Ghost. New Carthage, Sector 4. Warehouse Seven. Thirteen minutes."},
		{"speaker": "HANDLER", "text": "Black sedan in the yard. Engine warm. You take it, you leave, you get paid."},
		{"speaker": "GHOST", "text": "In and out. Who is the client?"},
		{"speaker": "HANDLER", "text": "You don't need a name. Don't look in the cabin. Just drive."},
	]
	_line_i = 0
	_show_line()


func _show_line() -> void:
	if _line_i >= _lines.size():
		_finish_dialogue()
		return
	dialogue_open = true
	var line: Dictionary = _lines[_line_i]
	ui.show_dialogue(line["speaker"], line["text"])


func _advance_dialogue() -> void:
	_line_i += 1
	_show_line()


func _finish_dialogue() -> void:
	dialogue_open = false
	ui.hide_dialogue()
	if phase == Phase.ENDING:
		_complete()
		return
	if phase == Phase.BRIEFING:
		phase = Phase.STEAL
		Game.set_objective("Steal the black sedan in the warehouse yard.")
	await get_tree().process_frame
	Game.input_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_stolen() -> void:
	if phase != Phase.STEAL:
		return
	Game.input_locked = true
	phase = Phase.PURSUIT
	_lines = [
		{"speaker": "GHOST", "text": "Encrypted drive in the console. This is not a car job."},
		{"speaker": "POLICE RADIO", "text": "All units, Sector 4. Armed theft. Lethal force authorised."},
	]
	_line_i = 0
	_show_line()
	Game.set_wanted(true)
	Game.set_objective("Reach the safehouse before the net closes.")


func _on_safehouse_body(body: Node3D) -> void:
	if phase != Phase.PURSUIT:
		return
	if body.is_in_group("player") or body.is_in_group("player_car") or body == player or body == getaway:
		_enter_safehouse()


func _enter_safehouse() -> void:
	phase = Phase.ENDING
	Game.set_wanted(false)
	if police.has_method("deactivate"):
		police.deactivate()
	Game.input_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if getaway.get("occupied"):
		getaway.exit_vehicle()
	Game.set_objective("You made it.")
	_lines = [
		{"speaker": "GHOST", "text": "I'm in. Sipho is dead and they pinned it on me. What did I steal?"},
		{"speaker": "UNKNOWN", "text": "You stole exactly what we needed you to steal."},
		{"speaker": "GHOST", "text": "We? You hired me tonight."},
		{"speaker": "UNKNOWN", "text": "And someone hired the men who killed Sipho. Look closer at the contract."},
	]
	_line_i = 0
	_show_line()


func _complete() -> void:
	phase = Phase.COMPLETE
	Game.mission_01_complete = true
	Game.save_progress()
	ui.show_result(
		true,
		"MISSION COMPLETE",
		"The handler who sent you into Warehouse Seven countersigned Sipho Dlamini's kill order.\n\nName on both files: C. Radebe.\n\nThe job was never the car. The job was you."
	)


func _on_car_destroyed() -> void:
	if phase == Phase.PURSUIT:
		_on_failed("The sedan is wrecked. The evidence is gone.")


func _on_failed(reason: String) -> void:
	if phase == Phase.FAILED or phase == Phase.COMPLETE:
		return
	phase = Phase.FAILED
	Game.input_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.set_wanted(false)
	ui.show_result(false, "MISSION FAILED", reason)
