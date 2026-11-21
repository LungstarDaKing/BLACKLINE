extends Node
## Read-only audit of Jack's imported model. Prints AUDIT lines, then quits.

const MODEL: String = "res://assets/_incoming/Jack_Carter.fbx"


func _ready() -> void:
	var scene := load(MODEL) as PackedScene
	var root := scene.instantiate() as Node3D
	var total_tris := 0
	var total_verts := 0
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		if mesh == null:
			continue
		var aabb := mesh.get_aabb()
		print("AUDIT mesh=%s surfaces=%d blendshapes=%d skin=%s aabb_size=%s visible=%s" % [
			mi.name, mesh.get_surface_count(), mesh.get_blend_shape_count(), str(mi.skin != null),
			str(aabb.size), str(mi.visible)])
		for s in mesh.get_surface_count():
			var verts: int = mesh.surface_get_array_len(s)
			var idx: int = mesh.surface_get_array_index_len(s)
			var tris: int = (idx if idx > 0 else verts) / 3
			total_tris += tris
			total_verts += verts
			var mat := mi.get_active_material(s)
			print("AUDIT   surf=%d verts=%d tris=%d mat=%s" % [s, verts, tris, _describe(mat)])
	print("AUDIT TOTAL tris=%d verts=%d" % [total_tris, total_verts])
	for skel in root.find_children("*", "Skeleton3D", true, false):
		var sk := skel as Skeleton3D
		var names: PackedStringArray = []
		for b in sk.get_bone_count():
			names.append(sk.get_bone_name(b))
		print("AUDIT skeleton=%s bones=%d" % [sk.name, sk.get_bone_count()])
		print("AUDIT bones: " + ", ".join(names))
	for ap in root.find_children("*", "AnimationPlayer", true, false):
		print("AUDIT animations: " + ", ".join((ap as AnimationPlayer).get_animation_list()))
	print("AUDIT DONE")
	root.free()
	get_tree().quit()


func _describe(mat: Material) -> String:
	if mat == null:
		return "null"
	var text := "%s (%s)" % [mat.resource_name, mat.get_class()]
	var base := mat as BaseMaterial3D
	if base == null:
		return text
	text += " albedo=%s rough=%.2f metal=%.2f spec=%.2f transp=%d cull=%d shading=%d" % [
		str(base.albedo_color), base.roughness, base.metallic, base.metallic_specular,
		base.transparency, base.cull_mode, base.shading_mode]
	text += " normal_on=%s emission_on=%s" % [str(base.normal_enabled), str(base.emission_enabled)]
	for slot in [
		["albedo", BaseMaterial3D.TEXTURE_ALBEDO], ["metallic", BaseMaterial3D.TEXTURE_METALLIC],
		["rough", BaseMaterial3D.TEXTURE_ROUGHNESS], ["normal", BaseMaterial3D.TEXTURE_NORMAL],
		["emission", BaseMaterial3D.TEXTURE_EMISSION], ["ao", BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION]]:
		var tex := base.get_texture(slot[1])
		if tex != null:
			var info := "%s=%s %dx%d" % [slot[0], tex.resource_path.get_file(), tex.get_width(), tex.get_height()]
			var img := tex.get_image()
			if img != null:
				info += " fmt=%d" % img.get_format()
			text += " [" + info + "]"
	return text
