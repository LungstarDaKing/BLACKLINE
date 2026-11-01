class_name ZoneTrigger
extends Area3D
## Area that reports when the player walks into it.

signal player_entered(player: Node)

@export var enabled: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.LAYER_PLAYER
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if enabled and body.is_in_group("player"):
		player_entered.emit(body)
