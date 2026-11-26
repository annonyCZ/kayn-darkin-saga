class_name Forest
extends Node3D
## Scatters low-poly pines (MultiMesh + trunk colliders) and wind-swayed grass over TerrainGen.

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

func _trees(rng: RandomNumberGenerator) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _pine_mesh()
	var body := StaticBody3D.new()
	body.name = "TreeColliders"
	body.collision_layer = 1
	add_child(body)
	var xforms: Array[Transform3D] = []
	var tries := 0
	while xforms.size() < tree_count and tries < tree_count * 12:
		tries += 1
		var ang := rng.randf() * TAU
		var r := rng.randf_range(36.0, 104.0)
		var x := cos(ang) * r
		var z := sin(ang) * r
		if Village.contains_xz(x, z):
			continue
		var h := TerrainGen.height_at(x, z)
		# skip steep ground
		var slope := absf(TerrainGen.height_at(x + 1.5, z) - h) + absf(TerrainGen.height_at(x, z + 1.5) - h)
		if slope > 2.6:
			continue
		var s := rng.randf_range(0.8, 1.7)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.25), s))
		xforms.append(Transform3D(b, Vector3(x, h - 0.2, z)))
		if r < 100.0:
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.3 * s
			cyl.height = 4.0
			cs.shape = cyl
			cs.position = Vector3(x, h + 2.0, z)
			body.add_child(cs)
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Pines"
	mmi.multimesh = mm
	mmi.visibility_range_end = 170.0
	add_child(mmi)

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
