extends Node3D
## Builds the small New Carthage industrial district from primitive instances.

const BUILDING := preload("res://scenes/environment/building.tscn")
const CRATE := preload("res://scenes/environment/crate.tscn")
const BARRIER := preload("res://scenes/environment/barrier.tscn")
const LIGHT := preload("res://scenes/environment/streetlight.tscn")
const ASPHALT := preload("res://assets/materials/asphalt.tres")
const CONCRETE := preload("res://assets/materials/concrete.tres")

var player_spawn := Vector3(-16, 0.35, 52)
var car_spawn := Transform3D(Basis.IDENTITY, Vector3(6, 0.4, 30))
var police_spawn := Transform3D(Basis.IDENTITY, Vector3(2, 0.4, 72))
var enemy_spawns: Array[Vector3] = [Vector3(5, 0.3, 34), Vector3(-10, 0.3, 48), Vector3(4, 0.3, 12)]
var safehouse_pos := Vector3(8, 0, -64)


func _ready() -> void:
	_ground()
	_road()
	_buildings()
	_warehouse()
	_safehouse()
	_props()
	_lights()
	_signs()


func _ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(90, 0.2, 170)
	mesh_i.mesh = box
	mesh_i.material_override = CONCRETE
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(90, 0.2, 170)
	col.shape = shape
	body.add_child(mesh_i)
	body.add_child(col)
	add_child(body)


func _road() -> void:
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 0.06, 160)
	mesh_i.mesh = box
	mesh_i.material_override = ASPHALT
	mesh_i.position = Vector3(0, 0.14, 0)
	add_child(mesh_i)
	for side in [-7.6, 7.6]:
		var walk := MeshInstance3D.new()
		var wmesh := BoxMesh.new()
		wmesh.size = Vector3(3.2, 0.08, 160)
		walk.mesh = wmesh
		walk.material_override = CONCRETE
		walk.position = Vector3(side, 0.15, 0)
		add_child(walk)


func _place_building(pos: Vector3, size: Vector3, color: Color) -> void:
	var b: Node3D = BUILDING.instantiate()
	b.position = Vector3(pos.x, size.y * 0.5, pos.z)
	b.size = size
	b.albedo = color
	add_child(b)


func _buildings() -> void:
	var dark := Color(0.14, 0.13, 0.13)
	var rust := Color(0.22, 0.12, 0.1)
	var grey := Color(0.2, 0.21, 0.22)
	var east := [42.0, 24.0, 6.0, -12.0, -30.0, -48.0]
	var west := [22.0, 4.0, -14.0, -32.0, -50.0]
	for z in east:
		_place_building(Vector3(18, 0, z), Vector3(10, 9 + int(absf(z)) % 5, 12), dark if int(z) % 20 == 0 else grey)
	for z in west:
		_place_building(Vector3(-18, 0, z), Vector3(10, 8 + int(absf(z)) % 4, 12), rust if z < 0 else dark)


func _warehouse() -> void:
	_place_building(Vector3(-24, 0, 54), Vector3(20, 8, 24), Color(0.17, 0.16, 0.14))
	_place_building(Vector3(-24, 0, 38), Vector3(8, 5, 6), Color(0.12, 0.12, 0.12))


func _safehouse() -> void:
	_place_building(safehouse_pos, Vector3(12, 6, 10), Color(0.12, 0.18, 0.16))
	var area := Area3D.new()
	area.name = "SafehouseZone"
	area.collision_layer = 16
	area.collision_mask = 2 | 8
	area.monitoring = true
	area.monitorable = true
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(14, 4, 12)
	col.shape = shape
	area.position = Vector3(safehouse_pos.x, 2, safehouse_pos.z)
	area.add_child(col)
	add_child(area)


func _props() -> void:
	for i in 6:
		var c: Node3D = CRATE.instantiate()
		c.position = Vector3(-12.0 + i * 1.1, 0.5, 44)
		add_child(c)
	for i in 3:
		var bar: Node3D = BARRIER.instantiate()
		bar.position = Vector3(-6.0 + i * 2.4, 0.5, 40)
		add_child(bar)


func _lights() -> void:
	for z in range(-70, 80, 22):
		for x in [-8.5, 8.5]:
			var lamp: Node3D = LIGHT.instantiate()
			lamp.position = Vector3(x, 0, z)
			add_child(lamp)


func _signs() -> void:
	_label("WAREHOUSE 7", Vector3(-14, 4.2, 42), Color(0.85, 0.7, 0.25))
	_label("SAFEHOUSE", Vector3(8, 4.5, -58), Color(0.4, 0.85, 0.55))
	_label("NEW CARTHAGE — SECTOR 4", Vector3(0, 3.2, 8), Color(0.8, 0.8, 0.82))


func _label(text: String, pos: Vector3, color: Color) -> void:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 48
	lab.pixel_size = 0.02
	lab.modulate = color
	lab.position = pos
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lab)
