extends StaticBody3D


func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 1.0, 0.28)
	$MeshInstance3D.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.28, 0.08)
	mat.roughness = 0.85
	$MeshInstance3D.material_override = mat
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2, 1.0, 0.28)
	$CollisionShape3D.shape = shape
