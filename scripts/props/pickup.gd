class_name Pickup
extends Interactable
## Collectable placeholder object: a quest item, a medkit or an ammo box.
## Needs a child MeshInstance3D named "Mesh" and a CollisionShape3D for reach.

enum Kind { ITEM, HEALTH, AMMO }

@export var kind: Kind = Kind.ITEM
## ITEM: inventory id. Ignored for HEALTH and AMMO.
@export var item_id: StringName = &"keycard"
## ITEM: count. HEALTH: hit points restored. AMMO: reserve rounds added.
@export var amount: float = 1.0
@export var display_name: String = "Keycard"
@export var color: Color = Color(0.2, 0.9, 1.0)
@export var spin_speed: float = 1.5

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	super._ready()
	prompt_text = "Take " + display_name
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	_mesh.material_override = material
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	_mesh.rotate_y(spin_speed * delta)


func _on_interacted(actor: Node) -> void:
	match kind:
		Kind.ITEM:
			var inv := actor.get_node_or_null("Inventory") as Inventory
			if inv == null:
				return
			inv.add_item(item_id, int(amount))
		Kind.HEALTH:
			var health := actor.get("health") as HealthComponent
			if health == null or health.current_health >= health.max_health:
				Game.show_message("Health is already full")
				return
			health.heal(amount)
		Kind.AMMO:
			var holder := actor.get_node_or_null("WeaponHolder")
			if holder == null or not holder.add_ammo(int(amount)):
				Game.show_message("Cannot carry more ammo")
				return
	Game.show_message("Picked up: " + display_name)
	queue_free()
