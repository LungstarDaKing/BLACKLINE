class_name Interactor
extends Area3D
## Sits on the player. Tracks Interactables in reach, focuses the nearest one
## and uses it when the "interact" action is pressed.

signal focus_changed(interactable: Interactable)

## Who is interacting; defaults to the parent node.
@export var actor: Node3D

var focused: Interactable = null

var _candidates: Array[Interactable] = []


func _ready() -> void:
	if actor == null:
		actor = get_parent() as Node3D
	collision_layer = 0
	collision_mask = Game.LAYER_INTERACTABLE
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or focused == null:
		return
	if actor and actor.get("input_enabled") == false:
		return
	focused.interact(actor)
	get_viewport().set_input_as_handled()


func _on_area_entered(area: Area3D) -> void:
	if area is Interactable and not _candidates.has(area):
		_candidates.append(area)


func _on_area_exited(area: Area3D) -> void:
	if area is Interactable:
		_candidates.erase(area)
		if area == focused:
			_set_focus(null)


func _update_focus() -> void:
	var best: Interactable = null
	var best_distance := INF
	for candidate in _candidates:
		if not is_instance_valid(candidate) or not candidate.can_interact(actor):
			continue
		var distance := candidate.global_position.distance_squared_to(actor.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	if best != focused:
		_set_focus(best)


func _set_focus(value: Interactable) -> void:
	if focused and is_instance_valid(focused):
		focused.set_focused(false)
	focused = value
	if focused:
		focused.set_focused(true)
	focus_changed.emit(focused)
