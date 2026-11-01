class_name Interactable
extends Area3D
## Anything the player can use with the interact key. Give it a CollisionShape3D
## to define where it can be reached, then connect to `interacted`.

signal interacted(actor: Node)
signal focus_changed(focused: bool)

@export var prompt_text: String = "Interact"
@export var enabled: bool = true
## Disable after the first successful use.
@export var one_shot: bool = false


func _ready() -> void:
	collision_layer = Game.LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true


func can_interact(_actor: Node) -> bool:
	return enabled


## Text shown on the HUD. Override to vary it by actor (e.g. a locked door).
func get_prompt(_actor: Node = null) -> String:
	return prompt_text


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	interacted.emit(actor)
	if one_shot:
		enabled = false


func set_focused(value: bool) -> void:
	focus_changed.emit(value)
