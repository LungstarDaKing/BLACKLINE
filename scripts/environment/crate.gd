extends StaticBody3D


func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.9, 0.9)
	$MeshInstance3D.mesh = mesh
	$MeshInstance3D.material_override = preload("res://assets/materials/metal_dark.tres")
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 0.9, 0.9)
	$CollisionShape3D.shape = shape
