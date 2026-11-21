extends Node
## Phase 3D read-only audit of Jack_Carter.fbx. Prints geometry, material and texture data.

func _ready() -> void:
	var ps: PackedScene = load("res://assets/_incoming/Jack_Carter.fbx")
	var root: Node = ps.instantiate()
	add_child(root)
	var total_tris := 0
	var total_verts := 0
	var tex_seen := {}
	var meshes: Array = []
	_collect(root, meshes)
	print("AUDIT mesh_instances=", meshes.size())
	for mi in meshes:
		var m: Mesh = mi.mesh
		if m == null:
			continue
		var aabb: AABB = mi.get_aabb()
		print("AUDIT MESH ", mi.name, " surfaces=", m.get_surface_count(), " aabb_size=", aabb.size, " skin=", mi.skin != null, " blendshapes=", (m as ArrayMesh).get_blend_shape_count() if m is ArrayMesh else -1)
		for s in m.get_surface_count():
			var arrays: Array = m.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var idx = arrays[Mesh.ARRAY_INDEX]
			var tris: int = (idx.size() / 3) if idx != null and idx.size() > 0 else verts.size() / 3
			total_tris += tris
			total_verts += verts.size()
			var mat: Material = mi.get_active_material(s)
			var line := "AUDIT   surf %d tris=%d verts=%d has_uv=%s has_tangent=%s has_weights=%s" % [s, tris, verts.size(), arrays[Mesh.ARRAY_TEX_UV] != null, arrays[Mesh.ARRAY_TANGENT] != null, arrays[Mesh.ARRAY_BONES] != null]
			print(line)
			if mat is BaseMaterial3D:
				var b: BaseMaterial3D = mat
				print("AUDIT     mat=", b.resource_name, " albedo=", b.albedo_color, " rough=", b.roughness, " metal=", b.metallic, " spec=", b.metallic_specular, " transp=", b.transparency, " cull=", b.cull_mode, " normal_en=", b.normal_enabled, " rim=", b.rim_enabled, " sss=", b.subsurf_scatter_enabled, " emission=", b.emission_enabled, " ao=", b.ao_enabled, " orm=", b.orm_texture if false else "n/a")
				for slot in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "ao_texture", "emission_texture", "orm_texture"]:
					var t = b.get(slot)
					if t is Texture2D:
						print("AUDIT       ", slot, " ", t.get_width(), "x", t.get_height(), " ", t.resource_path, " ", t.get_class())
						tex_seen[t.get_rid()] = [t.get_width(), t.get_height()]
			else:
				print("AUDIT     mat=", mat)
	print("AUDIT TOTAL tris=", total_tris, " verts=", total_verts, " unique_textures=", tex_seen.size())
	var mem := 0
	for k in tex_seen:
		mem += int(tex_seen[k][0]) * int(tex_seen[k][1]) * 4
	print("AUDIT uncompressed_texture_bytes=", mem, " (MB ", mem / 1048576.0, ")")
	var sk: Skeleton3D = _find_skel(root)
	if sk:
		print("AUDIT skeleton bones=", sk.get_bone_count())
		var names := []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i))
		print("AUDIT bones: ", ", ".join(names))
	var ap := _find_ap(root)
	if ap:
		print("AUDIT clips: ", ", ".join(ap.get_animation_list()))
	get_tree().quit()

func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)

func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find_skel(c)
		if r:
			return r
	return null

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_ap(c)
		if r:
			return r
	return null
