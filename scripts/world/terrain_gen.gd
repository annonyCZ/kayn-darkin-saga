class_name TerrainGen
extends StaticBody3D
## Procedural terrain: flat central plateau (gameplay arena) blending into noisy hills
## and high rim cliffs. Generates mesh + trimesh collision at load, deterministic seed.

const SIZE := 220.0
const STEP := 2.0
const FLAT_R := 52.0
const BLEND_R := 88.0
## Village valley: a flat basin north of the arena plateau, walled in by steep hills.
const BASIN_C := Vector2(0.0, -68.0)
const BASIN_FLAT := 34.0
const BASIN_BLEND := 54.0

static var _noise: FastNoiseLite

static func _n() -> FastNoiseLite:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise.frequency = 0.011
		_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		_noise.fractal_octaves = 4
		_noise.seed = 1337
	return _noise

static func height_at(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var t := smoothstep(FLAT_R, BLEND_R, r)
	if t <= 0.0:
		return 0.0
	var n := (_n().get_noise_2d(x, z) + 1.0) * 0.5
	var rim := smoothstep(BLEND_R, SIZE * 0.5, r)
	var basin := smoothstep(BASIN_FLAT, BASIN_BLEND, Vector2(x, z).distance_to(BASIN_C))
	return (t * (4.0 + n * 20.0) + rim * rim * 24.0) * basin

func _ready() -> void:
	collision_layer = 1
	var cells := int(SIZE / STEP)
	var n := cells + 1
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	verts.resize(n * n)
	norms.resize(n * n)
	uvs.resize(n * n)
	var half := SIZE * 0.5
	for j in n:
		for i in n:
			var x := -half + i * STEP
			var z := -half + j * STEP
			var idx := j * n + i
			verts[idx] = Vector3(x, height_at(x, z), z)
			var hl := height_at(x - STEP, z)
			var hr := height_at(x + STEP, z)
			var hd := height_at(x, z - STEP)
			var hu := height_at(x, z + STEP)
			norms[idx] = Vector3(hl - hr, 2.0 * STEP, hd - hu).normalized()
			uvs[idx] = Vector2(float(i) / cells, float(j) / cells)
	var indices := PackedInt32Array()
	for j in cells:
		for i in cells:
			var a := j * n + i
			var b := a + 1
			var c := a + n
			var d := c + 1
			indices.append_array([a, b, c, b, d, c])     # clockwise winding seen from above (Godot front face)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/terrain.gdshader")
	mat.set_shader_parameter("grass_tex", load("res://assets/environments/terrain3d_demo/textures/ground037_alb_ht.png"))
	mat.set_shader_parameter("rock_tex", load("res://assets/environments/terrain3d_demo/textures/rock023_alb_ht.png"))
	mat.set_shader_parameter("dirt_tex", load("res://assets/environments/terrain3d_demo/textures/ground037_alb_ht.png"))
	# Village street (dirt) runs along the village's local Z axis from the gate to the plaza.
	mat.set_shader_parameter("street_a", Vector2(Village.CENTER.x, Village.CENTER.z + Village.GATE_Z))
	mat.set_shader_parameter("street_b", Vector2(Village.CENTER.x, Village.CENTER.z + Village.PLAZA_Z))
	mat.set_shader_parameter("plaza_r", Village.PLAZA_RADIUS)
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = mesh
	add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = mesh.create_trimesh_shape()
	add_child(cs)
