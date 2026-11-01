class_name Door
extends Interactable
## Sliding door. The root is the reach area; the moving panel is a child
## AnimatableBody3D named "Slab". Locked doors need `required_item`.

signal opened

@export var locked: bool = true
@export var required_item: StringName = &"keycard"
@export var slide: Vector3 = Vector3(0.0, 3.1, 0.0)
@export var open_time: float = 0.8
@export var locked_prompt: String = "Locked - keycard required"
@export var open_prompt: String = "Open Door"

var is_open: bool = false

@onready var _slab: AnimatableBody3D = $Slab


func _ready() -> void:
	super._ready()
	interacted.connect(_on_interacted)


func get_prompt(actor: Node = null) -> String:
	if locked and not _actor_has_key(actor):
		return locked_prompt
	return open_prompt


func open() -> void:
	if is_open:
		return
	is_open = true
	enabled = false
	var tween := create_tween()
	tween.tween_property(_slab, "position", _slab.position + slide, open_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	opened.emit()


func _on_interacted(actor: Node) -> void:
	if locked:
		if not _actor_has_key(actor):
			Game.show_message("Locked. A keycard is required.")
			return
		locked = false
		Game.show_message("Door unlocked")
	open()


func _actor_has_key(actor: Node) -> bool:
	if actor == null:
		return false
	var inv := actor.get_node_or_null("Inventory") as Inventory
	return inv != null and inv.has_item(required_item)
