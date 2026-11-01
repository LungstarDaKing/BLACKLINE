class_name HealthComponent
extends Node
## Reusable health. Add as a child of anything that can be damaged, then call
## HealthComponent.apply_damage(some_collider, amount, source) to hurt it.

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal died(source: Node)

@export var max_health: float = 100.0
@export var invulnerable: bool = false

var current_health: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health


func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or invulnerable or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit(source)


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0 or current_health >= max_health:
		return
	var before := current_health
	current_health = minf(current_health + amount, max_health)
	healed.emit(current_health - before)
	health_changed.emit(current_health, max_health)


func get_fraction() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0


## Finds the HealthComponent among target's direct children and damages it.
## Returns true if something was hit.
static func apply_damage(target: Node, amount: float, source: Node = null) -> bool:
	if target == null:
		return false
	for child in target.get_children():
		if child is HealthComponent:
			(child as HealthComponent).take_damage(amount, source)
			return true
	return false
