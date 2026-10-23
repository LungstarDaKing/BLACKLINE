extends StaticBody3D
## Reusable box building. Unique mesh/shape per instance so sizes do not share.

@export var size := Vector3(8, 9, 10)
@export var albedo := Color(0.16, 0.15, 0.15, 1)


func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = 0.9
	$MeshInstance3D.mesh = mesh
	$MeshInstance3D.material_override = mat
	var shape := BoxShape3D.new()
	shape.size = size
	$CollisionShape3D.shape = shape
