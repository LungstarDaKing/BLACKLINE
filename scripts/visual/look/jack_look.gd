class_name JackLook
extends Node
## Material presentation upgrade for Jack Carter (isolated test only).
##
## Never edits the FBX or its textures: it builds per-surface override
## materials from copies of the imported ones, so apply() / restore() can be
## toggled at any time for before/after comparisons.
## Every imported material has roughness 1.0 and no metal, so everything looks
## like matte clay; this assigns believable values per material name.

const SKIN_SHADER: String = "res://scripts/visual/look/jack_skin.gdshader"

## material name -> overrides. Keys: rough, metal, spec, rim, rim_tint,
## clearcoat, clearcoat_rough, skin (use the skin shader).
const RULES: Dictionary = {
	"Skin": {"skin": true},
	"Skin details": {"rough": 0.78, "spec": 0.2},
	"Eyes": {"rough": 0.12, "spec": 0.9, "clearcoat": 1.0, "clearcoat_rough": 0.04},
	"Eyebrows": {"rough": 0.8, "spec": 0.15},
	"Eyelashes": {"rough": 0.8, "spec": 0.15},
	"Teeth": {"rough": 0.32, "spec": 0.5},
	"Tongue": {"rough": 0.35, "spec": 0.4},
	"Outfit": {"rough": 0.92, "spec": 0.2, "rim": 0.22, "rim_tint": 0.7, "albedo_mul": 0.84},
	"Watch strap": {"rough": 0.55, "spec": 0.4},
	"Watch": {"rough": 0.28, "metal": 0.9},
	"Earpiece": {"rough": 0.45, "spec": 0.5},
	"Earpiece tube": {"rough": 0.5, "spec": 0.4},
	"Gold watch": {"rough": 0.22, "metal": 1.0},
	"Watch face": {"rough": 0.25, "spec": 0.7},
	"Sneaker leather": {"rough": 0.5, "spec": 0.55},
	"Sneaker midsole": {"rough": 0.75, "spec": 0.35},
	"Sneaker outsole": {"rough": 0.9, "spec": 0.25},
	"Sneaker laces": {"rough": 0.92, "spec": 0.2},
	"Silver": {"rough": 0.28, "metal": 0.9},
}

@export_group("Skin")
@export var skin_roughness_lit: float = 0.52
@export var skin_roughness_dark: float = 0.82
@export var skin_specular: float = 0.38
@export var skin_rim: float = 0.25
@export var skin_saturation: float = 1.0
@export var skin_tint: Color = Color(1.0, 1.0, 1.0)

var upgraded: bool = false

var _meshes: Array[MeshInstance3D] = []
## MeshInstance3D -> Array of the imported (original) surface materials.
var _originals: Dictionary = {}
var _cache: Dictionary = {}
var _skin_shader: Shader


func setup(model: Node3D) -> void:
	_meshes.clear()
	_originals.clear()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null:
			continue
		_meshes.append(instance)
		var list: Array = []
		for surface in instance.mesh.get_surface_count():
			list.append(instance.mesh.surface_get_material(surface))
		_originals[instance] = list
	_skin_shader = load(SKIN_SHADER) as Shader


func apply() -> void:
	for instance in _meshes:
		var list: Array = _originals[instance]
		for surface in list.size():
			var original := list[surface] as StandardMaterial3D
			if original == null:
				continue
			var key := "%d_%s" % [instance.get_instance_id(), surface]
			if not _cache.has(key):
				_cache[key] = _build(original)
			instance.set_surface_override_material(surface, _cache[key])
	upgraded = true


func restore() -> void:
	for instance in _meshes:
		for surface in instance.mesh.get_surface_count():
			instance.set_surface_override_material(surface, null)
	upgraded = false


## Rebuilds the skin material after a parameter was changed in the inspector.
func refresh_skin() -> void:
	for key in _cache.keys().duplicate():
		var material := _cache[key] as ShaderMaterial
		if material != null:
			_set_skin_params(material)


func _build(original: StandardMaterial3D) -> Material:
	var rule: Dictionary = RULES.get(original.resource_name, {})
	if bool(rule.get("skin", false)) and _skin_shader != null:
		var material := ShaderMaterial.new()
		material.shader = _skin_shader
		material.resource_name = original.resource_name + " (upgraded)"
		material.set_shader_parameter("albedo_tex", original.albedo_texture)
		_set_skin_params(material)
		return material
	var copy := original.duplicate() as StandardMaterial3D
	copy.resource_name = original.resource_name + " (upgraded)"
	copy.emission_enabled = false
	if rule.has("albedo_mul"):
		# Pure white cloth clips to flat white in sunlight; real white fabric is ~85 %.
		var factor: float = float(rule["albedo_mul"])
		copy.albedo_color = Color(copy.albedo_color.r * factor, copy.albedo_color.g * factor,
				copy.albedo_color.b * factor, copy.albedo_color.a)
	copy.roughness = float(rule.get("rough", copy.roughness))
	copy.metallic = float(rule.get("metal", copy.metallic))
	copy.metallic_specular = float(rule.get("spec", copy.metallic_specular))
	if rule.has("rim"):
		copy.rim_enabled = true
		copy.rim = float(rule["rim"])
		copy.rim_tint = float(rule.get("rim_tint", 0.5))
	if rule.has("clearcoat"):
		copy.clearcoat_enabled = true
		copy.clearcoat = float(rule["clearcoat"])
		copy.clearcoat_roughness = float(rule.get("clearcoat_rough", 0.1))
	return copy


func _set_skin_params(material: ShaderMaterial) -> void:
	material.set_shader_parameter("roughness_lit", skin_roughness_lit)
	material.set_shader_parameter("roughness_dark", skin_roughness_dark)
	material.set_shader_parameter("specular_amount", skin_specular)
	material.set_shader_parameter("rim_amount", skin_rim)
	material.set_shader_parameter("saturation", skin_saturation)
	material.set_shader_parameter("tint", skin_tint)
