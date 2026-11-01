class_name MissionManager
extends Node
## Generic mission state: a list of objectives, an optional countdown, and
## completed / failed outcomes. Level scripts add objectives and report
## progress; the HUD finds this node through the "mission" group.

signal mission_started
signal objective_completed(id: StringName)
signal mission_completed
signal mission_failed(reason: String)

enum State { IDLE, ACTIVE, COMPLETED, FAILED }

## Seconds allowed for the mission. 0 disables the timer.
@export var time_limit: float = 360.0
@export var fail_when_player_dies: bool = true
## Delay so the player's death is visible before the fail screen appears.
@export var fail_delay_on_death: float = 1.4

var state: State = State.IDLE
var time_left: float = 0.0

var _objectives: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("mission")
	_bind_player.call_deferred()


func _process(delta: float) -> void:
	if state != State.ACTIVE or time_limit <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		fail("Time ran out.")


func add_objective(id: StringName, text: String) -> void:
	_objectives.append({"id": id, "text": text, "done": false})


func start() -> void:
	if state != State.IDLE:
		return
	state = State.ACTIVE
	time_left = time_limit
	mission_started.emit()


func complete_objective(id: StringName) -> void:
	if state != State.ACTIVE:
		return
	for objective in _objectives:
		if objective["id"] == id and not objective["done"]:
			objective["done"] = true
			objective_completed.emit(id)
			Game.show_message("Objective complete: " + objective["text"])
			break
	if _all_done():
		complete()


func is_objective_done(id: StringName) -> bool:
	for objective in _objectives:
		if objective["id"] == id:
			return objective["done"]
	return false


func complete() -> void:
	if state != State.ACTIVE:
		return
	state = State.COMPLETED
	mission_completed.emit()


func fail(reason: String) -> void:
	if state != State.ACTIVE:
		return
	state = State.FAILED
	mission_failed.emit(reason)


func get_objectives_text() -> String:
	var lines: PackedStringArray = []
	for objective in _objectives:
		lines.append(("[x] " if objective["done"] else "[ ] ") + objective["text"])
	return "\n".join(lines)


func get_timer_text() -> String:
	if time_limit <= 0.0:
		return ""
	var total := int(ceil(time_left))
	return "%d:%02d" % [total / 60, total % 60]


func _all_done() -> bool:
	for objective in _objectives:
		if not objective["done"]:
			return false
	return not _objectives.is_empty()


func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player and fail_when_player_dies:
		player.died.connect(_on_player_died)


func _on_player_died() -> void:
	await get_tree().create_timer(fail_delay_on_death).timeout
	fail("You were killed.")
