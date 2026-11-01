class_name Inventory
extends Node
## Minimal item store for keys and quest items. Items are plain string ids.

signal item_added(id: StringName, count: int)
signal item_removed(id: StringName, count: int)

var _items: Dictionary = {}


func add_item(id: StringName, count: int = 1) -> void:
	if count <= 0:
		return
	_items[id] = get_count(id) + count
	item_added.emit(id, count)


func remove_item(id: StringName, count: int = 1) -> bool:
	if get_count(id) < count:
		return false
	_items[id] = get_count(id) - count
	if _items[id] <= 0:
		_items.erase(id)
	item_removed.emit(id, count)
	return true


func has_item(id: StringName) -> bool:
	return get_count(id) > 0


func get_count(id: StringName) -> int:
	return _items.get(id, 0)
