extends Node
## Test-support tool (read only): prints meshes, materials, textures, skeleton and
## animation facts of Jack_Carter.fbx. Never modifies any asset.

const MODEL: String = "res://assets/_incoming/Jack_Carter.fbx"
const SLOTS: Array = [
	["albedo", BaseMaterial3D.TEXTURE_ALBEDO],
	["metallic", BaseMaterial3D.TEXTURE_METALLIC],
	["roughness", BaseMaterial3D.TEXTURE_ROUGHNESS],
	["emission", BaseMaterial3D.TEXTURE_EMISSION],
	["normal", BaseMaterial3D.TEXTURE_NORMAL],
	["ao", BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION],
]


func _ready() -> void:
	var scene := load(MODEL) as PackedScene
	if scene == null:
		print("AUDIT could not load model")
		get_tree().quit()
		return
	var root := scene.instantiate() as Node3D
	add_child(root)
	var total_tris := 0
	var total_verts := 0
	var seen_textures: Dictionary = {}
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		var aabb := mesh.get_aabb()
		print("AUDIT mesh '%s' surfaces=%d blend_shapes=%d skin=%s aabb_size=%s" % [
			mesh_instance.name, mesh.get_surface_count(), mesh.get_blend_shape_count(),
			str(mesh_instance.skin != null), str(aabb.size)])
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var tris := (indices.size() if indices.size() > 0 else verts.size()) / 3
			total_tris += tris
			total_verts += verts.size()
			var has_uv2 := arrays[Mesh.ARRAY_TEX_UV2] != null
			var has_tangent := arrays[Mesh.ARRAY_TANGENT] != null
			var has_color := arrays[Mesh.ARRAY_COLOR] != null
			var has_bones := arrays[Mesh.ARRAY_BONES] != null
			var material := mesh_instance.get_active_material(surface)
			var line := "AUDIT   surf %d: verts=%d tris=%d uv2=%s tangent=%s color=%s bones=%s" % [
				surface, verts.size(), tris, str(has_uv2), str(has_tangent), str(has_color), str(has_bones)]
			if material is BaseMaterial3D:
				var base := material as BaseMaterial3D
				line += " | mat='%s' albedo_col=%s rough=%.2f metal=%.2f spec=%.2f transp=%d alpha_cut=%d cull=%d shading=%d normal_on=%s rim=%s" % [
					base.resource_name, str(base.albedo_color), base.roughness, base.metallic,
					base.metallic_specular, base.transparency, base.alpha_scissor_threshold if base.transparency == 2 else 0,
					base.cull_mode, base.shading_mode, str(base.normal_enabled), str(base.rim_enabled)]
				print(line)
				for slot in SLOTS:
					var texture := base.get_texture(slot[1])
					if texture != null:
						var image := texture.get_image()
						var info := "%dx%d" % [texture.get_width(), texture.get_height()]
						if image != null:
							info += " fmt=%d mips=%s" % [image.get_format(), str(image.has_mipmaps())]
						print("AUDIT      %s: %s %s" % [slot[0], texture.resource_path if texture.resource_path != "" else "(embedded)", info])
						seen_textures[texture.resource_path + ":" + str(texture.get_width())] = texture
			else:
				print(line + " | material=%s" % str(material))
	print("AUDIT TOTAL meshes tris=%d verts=%d" % [total_tris, total_verts])
	var texture_bytes := 0
	for key in seen_textures:
		var texture := seen_textures[key] as Texture2D
		var image := texture.get_image()
		if image != null:
			texture_bytes += image.get_data().size()
	print("AUDIT unique textures=%d decoded_bytes=%d (%.1f MB, uncompressed in RAM, mipmaps excluded)" % [
		seen_textures.size(), texture_bytes, texture_bytes / 1048576.0])
	for skeleton_node in root.find_children("*", "Skeleton3D", true, false):
		var skeleton := skeleton_node as Skeleton3D
		var names: PackedStringArray = []
		for bone in skeleton.get_bone_count():
			names.append(skeleton.get_bone_name(bone))
		print("AUDIT skeleton '%s' bones=%d" % [skeleton.name, skeleton.get_bone_count()])
		var fingers: PackedStringArray = []
		for bone_name in names:
			if bone_name.contains("Thumb") or bone_name.contains("Index") or bone_name.contains("Middle") \
					or bone_name.contains("Ring") or bone_name.contains("Pinky") or bone_name.contains("Eye") \
					or bone_name.contains("Jaw") or bone_name.contains("Hair"):
				fingers.append(bone_name)
		print("AUDIT finger/face bones (%d): %s" % [fingers.size(), ", ".join(fingers)])
		print("AUDIT all bones: %s" % ", ".join(names))
	for player in root.find_children("*", "AnimationPlayer", true, false):
		print("AUDIT animation player: %d clips" % (player as AnimationPlayer).get_animation_list().size())
	print("AUDIT node tree:")
	_print_tree(root, 0)
	print("AUDIT DONE")
	get_tree().quit()


func _print_tree(node: Node, depth: int) -> void:
	if depth > 4:
		return
	print("AUDIT   %s%s (%s)" % ["  ".repeat(depth), node.name, node.get_class()])
	for child in node.get_children():
		if child is Skeleton3D and depth >= 2:
			print("AUDIT   %s%s (Skeleton3D, children hidden)" % ["  ".repeat(depth + 1), child.name])
			for grandchild in child.get_children():
				print("AUDIT   %s%s (%s)" % ["  ".repeat(depth + 2), grandchild.name, grandchild.get_class()])
			continue
		_print_tree(child, depth + 1)
