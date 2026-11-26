class_name Village
extends Node3D
## Village in the valley north of the arena plateau: a dirt street from the tori gate to a plaza with
## the Chinese pavilion, houses on both sides, market stalls, lantern posts, yards with fences,
## plum trees and an enterable hall (VillageHall). Built from the supplied Japanese village pack
## (glTF, metres) - see docs/ASSET_REGISTER.md. Props get colliders from their mesh bounds; big ones
## carve the navmesh (ArenaNav reads the "carve_radius" meta); lantern posts carry warm lights.
## Local +Z points south (towards the arena), the street runs along local Z.

const MODELS := "res://assets/environments/japan_village/models/"
## World-space centre of the village (flat basin, see TerrainGen.BASIN_*).
const CENTER := Vector3(0.0, 0.0, -66.0)
const GATE_Z := 27.0
const PLAZA_Z := -24.0
const PLAZA_RADIUS := 10.0
## Trees and grass are not scattered inside this radius (see Forest).
const CLEAR_RADIUS := 34.0

## Carve radius around big props (navmesh), by model.
const CARVE: Dictionary = {"House_4x5": 4.4, "MarketStall_Table_Tiered": 2.2, "MarketStall_Table_SideTiered": 1.8,
	"MarketStall_Table_wSpace": 1.8, "MarketStall_Table_Flat": 1.2, "Tree_RedPlum": 1.0, "WoodenBox_Stack": 1.6,
	"LogStorage": 1.4, "Fence_Wood": 2.2}
## Goods on the market stalls: [stall index in `_stalls`, model, dx, dz, y]
const GOODS: Array = [
	[0, "Tomato", -0.5, 0.0, 0.8], [0, "Tomato", -0.2, -0.2, 0.8], [0, "Corn", 0.5, 0.1, 0.8], [0, "Carrot_Orange", 0.9, -0.1, 0.8],
	[1, "Potato", -0.4, 0.0, 0.7], [1, "Potato", -0.1, 0.1, 0.7], [1, "Sprout", 0.6, -0.1, 0.7],
	[2, "Sweets_RiceDumpling_Spring", -0.3, 0.0, 0.5], [2, "Sweets_RiceDumpling_SoySauce", 0.1, 0.0, 0.5],
	[3, "Mallet", -0.2, 0.0, 0.5], [3, "Sickle", 0.3, 0.1, 0.5],
]

var prop_count: int = 0
var collider_count: int = 0
var light_count: int = 0
var house_count: int = 0
var pavilion: ChinesePavilion
var hall: VillageHall
var _stalls: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	name = "Village"
	position = CENTER
	_rng.seed = 4242
	_street()
	_houses()
	_yards()
	_market()
	_plaza()
	_trees_and_clutter()

# ------------------------------------------------------------------ layout
func _street() -> void:
	prop(self, "ToriGate", Vector3(0, 0, GATE_Z), 0.0, 1.15, "gate")
	for sx in [-1.0, 1.0]:
		prop(self, "StoneLantern", Vector3(sx * 3.6, 0, GATE_Z - 1.0), 0.0, 1.0, "cyl")
	# lantern posts along the street (every other one is a light)
	var z := 21.0
	var k := 0
	while z > PLAZA_Z + 10.0:
		for sx in [-1.0, 1.0]:
			var l := prop(self, "StoneLantern", Vector3(sx * 4.4, 0, z), 0.0, 1.0, "cyl")
			if (k + (0 if sx < 0 else 1)) % 2 == 0:
				_lantern_light(l)
		z -= 8.0
		k += 1

func _houses() -> void:
	# west row faces east (+X), east row faces west (-X)
	for row in [[-13.0, 90.0, [20.0, 8.0, -4.0, -16.0]], [13.0, -90.0, [18.0, 6.0, -6.0]]]:
		for z: float in row[2]:
			var sc := _rng.randf_range(0.95, 1.15)
			prop(self, "House_4x5", Vector3(row[0], 0, z), row[1] + _rng.randf_range(-3.0, 3.0), sc, "box")
			house_count += 1

func _yards() -> void:
	# back fences behind the houses
	for sx in [-1.0, 1.0]:
		var z := 24.0
		while z > -22.0:
			prop(self, "Fence_Wood", Vector3(sx * 21.0, 0, z), 90.0, 1.0, "box")
			z -= 4.0
	# side fences between the yards and the street
	for sx in [-1.0, 1.0]:
		for fz in [25.0, -22.0]:
			prop(self, "Fence_Wood", Vector3(sx * 17.0, 0, fz), 0.0, 1.0, "box")
	# yard clutter
	var yards := [
		["Barrel", -16.5, 14.0], ["Barrel", -16.5, 15.2], ["WoodenCrate_L", -17.0, 1.5], ["WoodenCrate_S", -17.2, 3.0],
		["WoodenBox_Stack", -17.0, -9.5], ["RiceBin", 16.5, 12.0], ["CeremicPot", 16.6, 10.6], ["LogStorage", 17.5, -2.0],
		["Log_Cluster", -17.0, -20.0], ["Basket_L", 16.5, -11.0], ["Basket_S", -16.6, 10.0], ["CeremicPot", -16.5, -3.0],
		["Barrel", 16.8, 22.0], ["WoodenCrate_L", 16.5, 1.0],
	]
	for y: Array in yards:
		prop(self, y[0], Vector3(y[1], 0, y[2]), _rng.randf_range(0, 360), 1.0, "box" if String(y[0]).begins_with("Wooden") or y[0] == "LogStorage" or y[0] == "Log_Cluster" else "cyl")

func _market() -> void:
	var defs := [["MarketStall_Table_Tiered", -5.4, 12.0, 90.0], ["MarketStall_Table_SideTiered", 5.4, 10.0, -90.0],
		["MarketStall_Table_wSpace", -5.4, 2.0, 90.0], ["MarketStall_Table_Flat", 5.4, 0.0, -90.0]]
	for d: Array in defs:
		_stalls.append(prop(self, d[0], Vector3(d[1], 0, d[2]), d[3], 1.0, "box"))
	for g: Array in GOODS:
		var st := _stalls[g[0]]
		var pos := st.position + st.transform.basis * Vector3(g[2], 0, g[3])
		prop(self, g[1], Vector3(pos.x, g[4], pos.z), 0.0, 1.0, "")
	prop(self, "Basket_L", Vector3(-6.8, 0, 6.5), 0.0, 1.0, "")
	prop(self, "Basket_S", Vector3(6.8, 0, 5.0), 40.0, 1.0, "")
	prop(self, "Table_Circular", Vector3(4.6, 0, 20.5), 0.0, 1.0, "cyl")
	prop(self, "Chair", Vector3(4.6, 0, 21.6), 180.0, 1.0, "")

func _plaza() -> void:
	pavilion = ChinesePavilion.new()
	pavilion.name = "Pavilion"
	pavilion.position = Vector3(0, _ground(0, PLAZA_Z), PLAZA_Z)
	pavilion.model_scale = 0.2
	add_child(pavilion)
	pavilion.set_meta("carve_radius", 4.2)
	for a in 4:
		var ang := PI * 0.25 + a * PI * 0.5
		var l := prop(self, "StoneLantern", Vector3(cos(ang) * 8.5, 0, PLAZA_Z + sin(ang) * 8.5), 0.0, 1.0, "cyl")
		_lantern_light(l)
	# the hall (enterable) closes the plaza on the east side; door faces the plaza (west)
	hall = VillageHall.new()
	hall.name = "Hall"
	hall.position = Vector3(23.0, _ground(23.0, PLAZA_Z - 2.0), PLAZA_Z - 2.0)
	hall.rotation.y = deg_to_rad(-90.0)
	add_child(hall)
	hall.set_meta("carve_radius", 7.0)

func _trees_and_clutter() -> void:
	for t in [[-9.0, -14.0], [8.0, -13.0], [-17.5, 28.0], [-25.0, -12.0], [14.0, 27.0], [-20.0, -26.0], [26.0, 8.0]]:
		prop(self, "Tree_RedPlum", Vector3(t[0], 0, t[1]), _rng.randf_range(0, 360), _rng.randf_range(0.9, 1.3), "trunk")

# ------------------------------------------------------------------ helpers
func _ground(lx: float, lz: float) -> float:
	return TerrainGen.height_at(CENTER.x + lx, CENTER.z + lz)

func _lantern_light(lantern: Node3D) -> void:
	var l := OmniLight3D.new()
	l.name = "Glow"
	l.position = Vector3(0, 1.4, 0)
	l.light_color = Color(1.0, 0.62, 0.3)
	l.light_energy = 2.2
	l.omni_range = 8.0
	l.omni_attenuation = 1.4
	lantern.add_child(l)
	light_count += 1

## Instances a pack model under `parent` with an optional collider; returns the holder node.
## Pass `parent` = the village to place at ground height; holders inside other nodes (the hall)
## use the given local y as is.
static func prop(parent: Node3D, model: String, local: Vector3, yaw: float, sc: float, collider: String) -> Node3D:
	var ps := load(MODELS + model + ".gltf") as PackedScene
	if ps == null:
		push_warning("Village: missing model " + model)
		return null
	var inst := ps.instantiate() as Node3D
	_mute_colours(inst, model)
	var box := _bounds(inst)
	var holder: Node3D = StaticBody3D.new() if collider != "" else Node3D.new()
	if holder is StaticBody3D:
		(holder as StaticBody3D).collision_layer = 1
	holder.name = model
	var y := local.y
	if parent is Village:
		y += TerrainGen.height_at(CENTER.x + local.x, CENTER.z + local.z)
	holder.position = Vector3(local.x, y, local.z)
	holder.rotation.y = deg_to_rad(yaw)
	holder.scale = Vector3.ONE * sc
	holder.add_child(inst)
	parent.add_child(holder)
	var v := parent as Village
	if v:
		v.prop_count += 1
	var c := box.get_center()
	match collider:
		"box":
			_shape(holder, v, BoxShape3D.new(), Vector3(box.size.x * 0.96, box.size.y, box.size.z * 0.96), c)
		"cyl":
			var cyl := CylinderShape3D.new()
			cyl.radius = maxf(box.size.x, box.size.z) * 0.45
			cyl.height = box.size.y
			_shape(holder, v, cyl, Vector3.ONE, c)
		"trunk":
			var t := CylinderShape3D.new()
			t.radius = 0.35
			t.height = 3.0
			_shape(holder, v, t, Vector3.ONE, Vector3(c.x, 1.5, c.z))
		"gate":
			for sx in [-1.0, 1.0]:
				_shape(holder, v, BoxShape3D.new(), Vector3(0.6, box.size.y, 0.9), Vector3(c.x + sx * (box.size.x * 0.5 - 0.55), c.y, c.z))
	if CARVE.has(model):
		holder.set_meta("carve_radius", float(CARVE[model]) * sc)
	return holder

## The pack uses a saturated flat-colour atlas; multiply it down so it sits in the dark, moody grade
## (plum blossoms are muted harder - they were neon pink under the red dusk light).
static var _mute_cache: Dictionary = {}

static func _mute_colours(inst: Node, model: String) -> void:
	# toy-like saturated flats -> weathered: strip most of the saturation, then darken (plum trees look dead/ashen)
	var tint := Color(0.5, 0.42, 0.38) if model == "Tree_RedPlum" else Color(0.8, 0.76, 0.72)
	var keep := 0.15 if model == "Tree_RedPlum" else 0.5
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if src == null:
				continue
			var key := "%s|%s|%d" % [model, src.resource_path, i]
			if not _mute_cache.has(key):
				var d := src.duplicate() as BaseMaterial3D
				var base := src.albedo_color
				var lum := base.r * 0.3 + base.g * 0.59 + base.b * 0.11
				var grey := Color(lum, lum, lum, base.a)
				d.albedo_color = grey.lerp(base, keep) * tint
				if d.albedo_texture != null:
					d.albedo_texture = _weathered(d.albedo_texture, keep)
				d.roughness = maxf(src.roughness, 0.8)
				_mute_cache[key] = d
			mi.set_surface_override_material(i, _mute_cache[key])

static var _tex_cache: Dictionary = {}

## The pack paints colour in an atlas texture, so albedo_color alone cannot desaturate it:
## build a washed-out, slightly warm-grey copy of the atlas once.
static func _weathered(tex: Texture2D, keep: float) -> Texture2D:
	var key := "%d|%.2f" % [tex.get_instance_id(), keep]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var lum := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			var g := Color(lum * 1.02, lum, lum * 0.95, c.a)
			img.set_pixel(x, y, g.lerp(c, keep))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex_cache[key] = t
	return t

static func _shape(holder: Node3D, v: Village, shape: Shape3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	if shape is BoxShape3D:
		(shape as BoxShape3D).size = size
	cs.shape = shape
	cs.position = pos
	holder.add_child(cs)
	if v:
		v.collider_count += 1

static func _bounds(n: Node) -> AABB:
	var r := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var t := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != n.get_parent():
			if p is Node3D:
				t = (p as Node3D).transform * t
			p = p.get_parent()
		var b := t * mi.get_aabb()
		r = b if first else r.merge(b)
		first = false
	return r

## True if a world-space XZ point lies inside the village clearing (used by Forest).
static func contains_xz(x: float, z: float) -> bool:
	return Vector2(x - CENTER.x, z - CENTER.z).length() < CLEAR_RADIUS
