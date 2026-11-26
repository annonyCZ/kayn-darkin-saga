class_name VillageHall
extends Node3D
## Enterable timber hall with a real interior: walls with collision, a door opening on the local +Z
## side, gabled tile roof, red lacquer posts, furniture from the village pack, hanging red lanterns,
## a flickering brazier and warm interior light. Built entirely in code (no extra assets).

const W := 11.0   # width (X)
const D := 8.0    # depth (Z)
const H := 3.6    # wall height
const T := 0.32   # wall thickness
const DOOR_W := 2.4
const DOOR_H := 2.6

var wall_colliders: int = 0
var interior_light: OmniLight3D
var _wood: StandardMaterial3D
var _dark: StandardMaterial3D
var _lacquer: StandardMaterial3D
var _tile: StandardMaterial3D
var _flames: Array[OmniLight3D] = []
var _t: float = 0.0

func _ready() -> void:
	_make_materials()
	_floor()
	_walls()
	_posts_and_beams()
	_roof()
	_furniture()
	_lights()

func _make_materials() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var nt := NoiseTexture2D.new()
	nt.noise = noise
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color(0.36, 0.2, 0.11)
	_wood.albedo_texture = nt
	_wood.uv1_triplanar = true
	_wood.uv1_scale = Vector3(0.5, 0.5, 0.5)
	_wood.roughness = 0.75
	_dark = StandardMaterial3D.new()
	_dark.albedo_color = Color(0.14, 0.08, 0.05)
	_dark.albedo_texture = nt
	_dark.uv1_triplanar = true
	_dark.uv1_scale = Vector3(0.4, 0.4, 0.4)
	_dark.roughness = 0.8
	_lacquer = StandardMaterial3D.new()
	_lacquer.albedo_color = Color(0.4, 0.05, 0.05)
	_lacquer.roughness = 0.4
	_tile = StandardMaterial3D.new()
	_tile.albedo_color = Color(0.13, 0.14, 0.17)
	_tile.albedo_texture = nt
	_tile.uv1_triplanar = true
	_tile.uv1_scale = Vector3(1.2, 1.2, 1.2)
	_tile.roughness = 0.6
	_tile.cull_mode = BaseMaterial3D.CULL_DISABLED

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, solid: bool, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var n: Node3D
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		n = body
		wall_colliders += 1
	else:
		n = Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	n.add_child(mi)
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	return n

func _floor() -> void:
	_box(self, Vector3(W + 1.2, 0.3, D + 1.2), Vector3(0, 0.09, 0), _wood, true)

func _walls() -> void:
	var y := 0.24 + H * 0.5
	_box(self, Vector3(W, H, T), Vector3(0, y, -D * 0.5), _dark, true)                       # back
	_box(self, Vector3(T, H, D), Vector3(-W * 0.5, y, 0), _dark, true)                       # left
	_box(self, Vector3(T, H, D), Vector3(W * 0.5, y, 0), _dark, true)                        # right
	var seg := (W - DOOR_W) * 0.5
	for sx in [-1.0, 1.0]:                                                                    # front, door gap
		_box(self, Vector3(seg, H, T), Vector3(sx * (DOOR_W * 0.5 + seg * 0.5), y, D * 0.5), _dark, true)
	_box(self, Vector3(DOOR_W, H - DOOR_H, T), Vector3(0, 0.24 + DOOR_H + (H - DOOR_H) * 0.5, D * 0.5), _dark, false)  # lintel

func _posts_and_beams() -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(self, Vector3(0.42, H + 0.2, 0.42), Vector3(sx * (W * 0.5), 0.24 + H * 0.5, sz * (D * 0.5)), _lacquer, false)
	for sx in [-1.0, 1.0]:   # door posts
		_box(self, Vector3(0.36, DOOR_H, 0.36), Vector3(sx * (DOOR_W * 0.5), 0.24 + DOOR_H * 0.5, D * 0.5 + 0.05), _lacquer, false)
	_box(self, Vector3(DOOR_W + 0.9, 0.3, 0.4), Vector3(0, 0.24 + DOOR_H + 0.1, D * 0.5 + 0.08), _lacquer, false)
	for z in [-D * 0.5, 0.0, D * 0.5]:   # tie beams across the hall
		_box(self, Vector3(W + 0.2, 0.3, 0.3), Vector3(0, 0.24 + H - 0.15, z), _lacquer, false)
	for x in [-W * 0.25, W * 0.25]:
		_box(self, Vector3(0.3, 0.3, D), Vector3(x, 0.24 + H - 0.15, 0), _lacquer, false)

func _roof() -> void:
	var rise := 2.3
	var half := D * 0.5 + 0.9
	var len_ := sqrt(half * half + rise * rise)
	var ang := atan2(rise, half)
	for s in [-1.0, 1.0]:
		var slab := _box(self, Vector3(W + 1.8, 0.22, len_), Vector3(0, 0.24 + H + rise * 0.5, s * half * 0.5), _tile, false, Vector3(s * ang, 0, 0))
		slab.name = "Roof"
		# the front/back slabs tilt about X: positive angle lowers +Z side for s = +1
	# gable end fill
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in [-1.0, 1.0]:
		var x: float = sx * (W * 0.5 - 0.05)
		var pts := [Vector3(x, 0.24 + H, -D * 0.5 - 0.05), Vector3(x, 0.24 + H, D * 0.5 + 0.05), Vector3(x, 0.24 + H + rise, 0)]
		if sx < 0:
			pts.reverse()
		for p: Vector3 in pts:
			st.add_vertex(p)
	st.generate_normals()
	var gm := MeshInstance3D.new()
	gm.mesh = st.commit()
	gm.material_override = _dark
	add_child(gm)
	# ridge cap
	_box(self, Vector3(W + 2.0, 0.28, 0.4), Vector3(0, 0.24 + H + rise + 0.1, 0), _lacquer, false)

func _furniture() -> void:
	var f := 0.24
	Village.prop(self, "Table_Circular", Vector3(0, f, -0.8), 0.0, 1.5, "cyl")
	for i in 5:
		var a := TAU * i / 5.0 + 0.3
		Village.prop(self, "Chair", Vector3(cos(a) * 1.55, f, -0.8 + sin(a) * 1.55), rad_to_deg(-a) - 90.0, 1.0, "")
	for sx in [-1.0, 1.0]:
		Village.prop(self, "Barrel", Vector3(sx * 4.6, f, -3.3), 0.0, 1.0, "cyl")
		Village.prop(self, "Barrel", Vector3(sx * 4.6, f, -2.2), 40.0, 1.0, "cyl")
		Village.prop(self, "WoodenCrate_L", Vector3(sx * 4.3, f, 1.8), sx * 90.0, 1.0, "box")
		Village.prop(self, "CeremicPot", Vector3(sx * 3.3, f, -3.5), 0.0, 1.2, "cyl")
	Village.prop(self, "WoodenBox_Stack", Vector3(-3.6, f, 3.0), 0.0, 1.0, "box")
	Village.prop(self, "Basket_L", Vector3(3.4, f, 3.1), 20.0, 1.0, "")
	Village.prop(self, "MarketStall_Table_Flat", Vector3(0, f, -3.4), 0.0, 1.4, "box")
	Village.prop(self, "StoneLantern", Vector3(-1.6, f, -3.4), 0.0, 0.9, "cyl")
	Village.prop(self, "StoneLantern", Vector3(1.6, f, -3.4), 0.0, 0.9, "cyl")
	# red banners on the back wall
	for sx in [-1.0, 1.0]:
		var b := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.1, 2.4)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.5, 0.04, 0.05)
		bm.emission_enabled = true
		bm.emission = Color(0.6, 0.05, 0.05)
		bm.emission_energy_multiplier = 0.25
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		q.material = bm
		b.mesh = q
		b.position = Vector3(sx * 2.8, 2.1, -D * 0.5 + T * 0.5 + 0.03)
		add_child(b)
	_brazier(Vector3(0, 0.24, 2.6))

func _brazier(pos: Vector3) -> void:
	var bowl := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.3
	cyl.height = 0.5
	cyl.material = _dark
	bowl.mesh = cyl
	bowl.position = pos + Vector3(0, 0.55, 0)
	add_child(bowl)
	for sx in [-1.0, 1.0]:
		_box(self, Vector3(0.1, 0.55, 0.1), pos + Vector3(sx * 0.3, 0.27, 0.0), _dark, false)
	var fire := CPUParticles3D.new()
	fire.position = pos + Vector3(0, 0.85, 0)
	fire.amount = 28
	fire.lifetime = 0.9
	fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = 0.22
	fire.direction = Vector3.UP
	fire.spread = 12.0
	fire.gravity = Vector3(0, 1.4, 0)
	fire.initial_velocity_min = 0.3
	fire.initial_velocity_max = 0.8
	fire.scale_amount_min = 0.03
	fire.scale_amount_max = 0.07
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.vertex_color_use_as_albedo = true
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.albedo_texture = _soft_dot()
	qm.material = fm
	fire.mesh = qm
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 0.7, 0.25, 0.55), Color(1.0, 0.3, 0.06, 0.4), Color(0.3, 0.04, 0.02, 0.0)])
	fire.color_ramp = g
	add_child(fire)
	var l := OmniLight3D.new()
	l.position = pos + Vector3(0, 1.1, 0)
	l.light_color = Color(1.0, 0.5, 0.2)
	l.light_energy = 1.8
	l.omni_range = 8.0
	l.shadow_enabled = true
	add_child(l)
	_flames.append(l)

func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 64
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

func _lights() -> void:
	for p in [Vector3(-3.0, 0.24 + H - 0.9, -1.5), Vector3(3.0, 0.24 + H - 0.9, -1.5), Vector3(-3.0, 0.24 + H - 0.9, 2.0), Vector3(3.0, 0.24 + H - 0.9, 2.0)]:
		var lan := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.24
		sm.height = 0.62
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.1, 0.08)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.25, 0.1)
		mat.emission_energy_multiplier = 0.6
		sm.material = mat
		lan.mesh = sm
		lan.position = p
		add_child(lan)
		_box(self, Vector3(0.03, 0.9, 0.03), p + Vector3(0, 0.75, 0), _dark, false)
		var l := OmniLight3D.new()
		l.position = p
		l.light_color = Color(1.0, 0.35, 0.18)
		l.light_energy = 1.4
		l.omni_range = 6.5
		add_child(l)
		_flames.append(l)
	interior_light = OmniLight3D.new()
	interior_light.position = Vector3(0, 2.6, 0)
	interior_light.light_color = Color(1.0, 0.78, 0.55)
	interior_light.light_energy = 1.6
	interior_light.omni_range = 11.0
	add_child(interior_light)

func _process(delta: float) -> void:
	_t += delta
	for i in _flames.size():
		var f := 0.88 + 0.12 * sin(_t * (7.0 + i * 1.3) + i) + 0.05 * sin(_t * 17.0 + i * 2.0)
		_flames[i].light_energy = (1.8 if _flames[i].shadow_enabled else 1.4) * f
