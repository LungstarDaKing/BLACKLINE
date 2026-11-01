@tool
class_name Block
extends StaticBody3D
## Placeholder box: collision and mesh are both built from `size`.
## Runs in the editor so level layouts (and navigation bakes) see the real size.

@export var size: Vector3 = Vector3(1.0, 1.0, 1.0):
	set(value):
		size = value
		if is_inside_tree():
			call_deferred("_rebuild")
@export var color: Color = Color(0.35, 0.38, 0.45):
	set(value):
		color = value
		if is_inside_tree():
			call_deferred("_rebuild")

@onready var _shape: CollisionShape3D = $Shape
@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not _shape or not _mesh:
		return
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	_mesh.mesh = mesh
