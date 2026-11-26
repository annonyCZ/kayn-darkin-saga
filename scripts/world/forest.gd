class_name Forest
extends Node3D
## Scatters weathered pine/dead-tree/rock models from the supplied packs (MultiMesh + colliders) and wind-swayed grass over TerrainGen.

@export var tree_count: int = 420
@export var grass_count: int = 16000
@export var seed_value: int = 7

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_trees(rng)
	_grass(rng)

# ------------------------------------------------------------------ trees
func _pine_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cyl(st, 0.0, 3.0, 0.28, 0.18, 7, Color(0.28, 0.18, 0.1))
	var layers := [[2.0, 3.4, 2.1, Color(0.04, 0.11, 0.07)], [3.6, 3.0, 1.7, Color(0.05, 0.13, 0.08)],
		[5.0, 2.6, 1.25, Color(0.06, 0.15, 0.09)], [6.3, 2.2, 0.8, Color(0.08, 0.17, 0.1)]]
	for l: Array in layers:
		_cone(st, l[0], l[1], l[2], 9, l[3])
	st.generate_normals()
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)
	return mesh

func _cyl(st: SurfaceTool, y0: float, y1: float, r0: float, r1: float, sides: int, col: Color) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
		var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
		var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
		for p: Vector3 in [p00, p10, p01, p01, p10, p11]:
			st.set_color(col)
			st.add_vertex(p)

func _cone(st: SurfaceTool, y0: float, h: float, r: float, sides: int, col: Color) -> void:
	var tip := Vector3(0, y0 + h, 0)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var b0 := Vector3(cos(a0) * r, y0, sin(a0) * r)
		var b1 := Vector3(cos(a1) * r, y0, sin(a1) * r)
		var shade := 0.85 + 0.3 * float(i % 2)
		for p: Vector3 in [b0, tip, b1]:
			st.set_color(col * shade)
			st.add_vertex(p)
		# underside
		for p: Vector3 in [b0, b1, Vector3(0, y0, 0)]:
			st.set_color(col * 0.5)
			st.add_vertex(p)

## Spawn sites shared by every scatter: (x, z, ground height) outside the village and off steep ground.
func _site(rng: RandomNumberGenerator, rmin: float, rmax: float, max_slope: float) -> Array:
	for _i in 12:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(rmin, rmax)
		var x := cos(ang) * r
		var z := sin(ang) * r
		if Village.contains_xz(x, z):
			continue
		var h := TerrainGen.height_at(x, z)
		var slope := absf(TerrainGen.height_at(x + 1.5, z) - h) + absf(TerrainGen.height_at(x, z + 1.5) - h)
		if slope > max_slope:
			continue
		return [x, z, h, r]
	return []

## One MultiMesh of `count` instances of a weathered pack model, with optional round trunk/boulder colliders.
func _scatter(rng: RandomNumberGenerator, nm: String, mesh: Mesh, count: int, rmin: float, rmax: float, smin: float, smax: float,
		col_radius: float, col_height: float, tilt: float = 0.0, max_slope: float = 2.6) -> int:
	if mesh == null:
		return 0
	var body := StaticBody3D.new()
	body.name = nm + "Colliders"
	body.collision_layer = 1
	add_child(body)
	var xforms: Array[Transform3D] = []
	var tries := 0
	while xforms.size() < count and tries < count * 6:
		tries += 1
		var site := _site(rng, rmin, rmax, max_slope)
		if site.is_empty():
			continue
		var s := rng.randf_range(smin, smax)
		var b := Basis(Vector3.UP, rng.randf() * TAU)
		if tilt > 0.0:
			b = b * Basis(Vector3(1, 0, 0), rng.randf_range(-tilt, tilt)) * Basis(Vector3(0, 0, 1), rng.randf_range(-tilt, tilt))
		b = b.scaled(Vector3(s, s * rng.randf_range(0.9, 1.3), s))
		xforms.append(Transform3D(b, Vector3(site[0], float(site[2]) - 0.15, site[1])))
		if col_radius > 0.0 and float(site[3]) < 100.0:
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = col_radius * s
			cyl.height = col_height * s
			cs.shape = cyl
			cs.position = Vector3(site[0], float(site[2]) + col_height * s * 0.5, site[1])
			body.add_child(cs)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.visibility_range_end = 190.0
	add_child(mmi)
	return xforms.size()

func _trees(rng: RandomNumberGenerator) -> void:
	var pine := EnvProps.mesh(EnvProps.NATURE + "tree_pine_02.glb", 0.3, Color(0.55, 0.58, 0.55))
	var alpine := EnvProps.mesh(EnvProps.NATURE + "tree_alpine_pine_03.glb", 0.3, Color(0.5, 0.54, 0.54))
	var dead := EnvProps.mesh(EnvProps.NATURE + "tree_mangrove_01.glb", 0.1, Color(0.38, 0.36, 0.34))
	var birch := EnvProps.mesh(EnvProps.NATURE + "tree_birch_01.glb", 0.0, Color(0.42, 0.4, 0.38))
	var rock := EnvProps.mesh(EnvProps.NATURE + "rock_02.glb", 0.15, Color(0.62, 0.62, 0.64))
	var sand := EnvProps.mesh(EnvProps.NATURE + "rock_sandstone_01.glb", 0.1, Color(0.5, 0.48, 0.47))
	var basalt := EnvProps.mesh(EnvProps.NATURE + "basalt_columns_02.glb", 0.0, Color(0.9, 0.9, 0.95))
	var glow := EnvProps.mesh(EnvProps.NATURE + "mushroom_glow_01.glb", 0.9, Color(0.5, 0.55, 0.6))
	# forest bulk: two pine silhouettes (very different heights), dead twisted trees and bare birches between them
	_scatter(rng, "Pines", pine, int(tree_count * 0.55), 36.0, 104.0, 1.5, 2.6, 0.22, 4.0)
	_scatter(rng, "AlpinePines", alpine, int(tree_count * 0.4), 36.0, 104.0, 1.4, 2.8, 0.2, 4.0)
	_scatter(rng, "DeadTrees", dead, 34, 38.0, 100.0, 1.2, 2.2, 0.35, 3.0, 0.08)
	_scatter(rng, "Birches", birch, 40, 38.0, 100.0, 1.0, 1.7, 0.12, 3.0, 0.1)
	# rock formations: boulders, layered sandstone, black basalt columns (monumental accents), mossy small stones
	_scatter(rng, "Boulders", rock, 60, 30.0, 100.0, 1.6, 4.5, 0.42, 1.6, 0.2, 4.0)
	_scatter(rng, "Sandstone", sand, 30, 32.0, 100.0, 1.8, 4.0, 0.42, 1.4, 0.2, 4.0)
	_scatter(rng, "Basalt", basalt, 22, 40.0, 100.0, 1.6, 3.4, 0.9, 2.9, 0.06, 4.0)
	_scatter(rng, "Stones", rock, 70, 12.0, 60.0, 0.35, 0.8, 0.0, 0.0, 0.3, 1.2)
	_scatter(rng, "GlowMushrooms", glow, 40, 12.0, 90.0, 1.3, 2.4, 0.0, 0.0, 0.0, 1.5)

# ------------------------------------------------------------------ grass
func _grass_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var w := 0.28
	var hgt := 0.46
	for k in 3:
		var a := PI * k / 3.0
		var dx := cos(a) * w
		var dz := sin(a) * w
		var base := verts.size()
		verts.append_array([Vector3(-dx, 0, -dz), Vector3(dx, 0, dz), Vector3(dx, hgt, dz), Vector3(-dx, hgt, -dz)])
		uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		idx.append_array([base, base + 2, base + 1, base, base + 3, base + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/grass.gdshader")
	m.surface_set_material(0, mat)
	return m

func _grass(rng: RandomNumberGenerator) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _grass_mesh()
	var xforms: Array[Transform3D] = []
	var tries := 0
	while xforms.size() < grass_count and tries < grass_count * 3:
		tries += 1
		var ang := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 50.0
		var x := cos(ang) * r
		var z := sin(ang) * r
		if Vector2(x - 7.0, z - 8.0).length() < 3.2 or Village.contains_xz(x, z):
			continue    # keep the altar and the village clear
		var h := TerrainGen.height_at(x, z)
		var slope := absf(TerrainGen.height_at(x + 1.0, z) - h) + absf(TerrainGen.height_at(x, z + 1.0) - h)
		if slope > 1.2:
			continue
		var s := rng.randf_range(0.8, 1.4)
		xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(x, h, z)))
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Grass"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 48.0
	mmi.visibility_range_end_margin = 8.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mmi)
