extends Node3D


func _ready() -> void:
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.07
	pole_mesh.bottom_radius = 0.1
	pole_mesh.height = 5.2
	$Pole.mesh = pole_mesh
	$Pole.position.y = 2.6
	$Pole.material_override = preload("res://assets/materials/metal_dark.tres")
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.45, 0.12, 0.45)
	$Lamp.mesh = lamp_mesh
	$Lamp.position.y = 5.25
	$Lamp.material_override = preload("res://assets/materials/emissive_warm.tres")
