class_name Village
extends Node3D
## Small village set-dressing at the north edge of the arena plateau, built from the supplied
## Japanese village pack (glTF, metres) and the Chinese four-corner pavilion.
## Props get box/cylinder colliders from their mesh bounds; big ones also carve the navmesh
## (see ArenaNav, which reads the "carve_radius" meta).

const MODELS := "res://assets/environments/japan_village/models/"
## World-space centre of the village (flat plateau, r < 52). +Z points to the arena centre.
const CENTER := Vector3(0.0, 0.0, -36.0)
## Trees and grass are not scattered inside this radius (see Forest).
const CLEAR_RADIUS := 17.0

## [model, local x, local z, yaw degrees, scale, collider]  collider: "" none, "box", "cyl",
## "gate" (two pillars), "trunk" (thin cylinder).
const LAYOUT: Array = [
	["Road_Cross", 0.0, 0.0, 0, 1.0, ""],
	["Road_End_S", 0.0, 5.6, 0, 1.0, ""],
	["Road_End_S", 0.0, 8.6, 0, 1.0, ""],
	["Road_End_S", -5.6, 0.0, 90, 1.0, ""],
	["Road_End_S", 5.6, 0.0, -90, 1.0, ""],
	["ToriGate", 0.0, 11.5, 0, 1.0, "gate"],
	["StoneLantern", -3.3, 11.0, 0, 1.0, "cyl"],
	["StoneLantern", 3.3, 11.0, 0, 1.0, "cyl"],
	["House_4x5", -11.0, -3.0, 90, 1.0, "box"],
	["House_4x5", 11.0, -4.0, -90, 1.0, "box"],
	["House_4x5", -11.0, 7.5, 90, 1.0, "box"],
	["House_4x5", 11.5, 7.0, -90, 1.0, "box"],
	["MarketStall_Table_Tiered", -4.0, 4.0, 0, 1.0, "box"],
	["MarketStall_Table_SideTiered", 4.0, 4.0, 0, 1.0, "box"],
	["MarketStall_Table_wSpace", -4.0, -4.0, 180, 1.0, "box"],
	["MarketStall_Table_Flat", 4.2, -4.2, 180, 1.0, "box"],
	["Fence_Wood", -8.0, -14.0, 0, 1.0, "box"],
	["Fence_Wood", -4.0, -14.0, 0, 1.0, "box"],
	["Fence_Wood", 4.0, -14.0, 0, 1.0, "box"],
	["Fence_Wood", 8.0, -14.0, 0, 1.0, "box"],
	["Fence_Wood", 14.5, -9.0, 90, 1.0, "box"],
	["Fence_Wood", -14.5, -9.0, 90, 1.0, "box"],
	["Tree_RedPlum", -13.0, -12.5, 20, 1.0, "trunk"],
	["Tree_RedPlum", 13.0, -12.0, 140, 1.0, "trunk"],
	["Tree_RedPlum", 14.0, 13.0, 260, 1.0, "trunk"],
	["Barrel", -9.0, 3.0, 0, 1.0, "cyl"],
	["Barrel", -8.9, 4.2, 40, 1.0, "cyl"],
	["WoodenCrate_L", 9.0, 3.5, 20, 1.0, "box"],
	["WoodenCrate_S", 9.2, 2.2, 70, 1.0, "box"],
	["WoodenBox_Stack", -8.6, -8.0, 90, 1.0, "box"],
	["RiceBin", 8.5, -8.5, 0, 1.0, "cyl"],
	["CeremicPot", 8.8, -7.2, 0, 1.0, "cyl"],
	["LogStorage", 7.0, -12.3, 0, 1.0, "box"],
	["Log_Cluster", -6.5, -12.3, 30, 1.0, "box"],
	["Basket_L", -2.5, 3.5, 0, 1.0, ""],
	["Basket_S", 2.2, 3.5, 0, 1.0, ""],
	["Ladder", -12.6, -3.0, 90, 1.0, ""],
	["Table_Circular", 4.5, 12.0, 0, 1.0, "cyl"],
	["Chair", 4.5, 13.2, 180, 1.0, ""],
]
## Goods on the market stalls: [model, local x, local z, y offset]
const GOODS: Array = [
	["Tomato", -4.5, 4.0, 0.8], ["Tomato", -4.2, 3.8, 0.8], ["Corn", -3.6, 4.1, 0.8], ["Carrot_Orange", -3.2, 4.0, 0.8],
	["Potato", 3.6, 4.0, 0.7], ["Potato", 3.9, 4.1, 0.7], ["Sprout", 4.6, 3.9, 0.7],
	["Sweets_RiceDumpling_Spring", -4.3, -4.0, 0.5], ["Sweets_RiceDumpling_SoySauce", -3.9, -4.1, 0.5],
	["Mallet", 4.0, -4.2, 0.5], ["Sickle", 4.5, -4.3, 0.5],
]
## Carve radius around big props (navmesh), by model.
const CARVE: Dictionary = {"House_4x5": 4.4, "MarketStall_Table_Tiered": 2.2, "MarketStall_Table_SideTiered": 1.8,
	"MarketStall_Table_wSpace": 1.8, "MarketStall_Table_Flat": 1.2, "Tree_RedPlum": 1.0, "WoodenBox_Stack": 1.6,
	"LogStorage": 1.4, "Fence_Wood": 2.2}

var prop_count: int = 0
var collider_count: int = 0
var pavilion: ChinesePavilion

func _ready() -> void:
	name = "Village"
	position = CENTER
	for e: Array in LAYOUT:
		_place(e[0], e[1], e[2], e[3], e[4], e[5])
	for g: Array in GOODS:
		_place(g[0], g[1], g[2], 0, 1.0, "", g[3])
	pavilion = ChinesePavilion.new()
	pavilion.name = "Pavilion"
	pavilion.position = Vector3(0.0, _ground(0.0, -9.0), -9.0)
	add_child(pavilion)
	pavilion.set_meta("carve_radius", 3.8)

func _ground(lx: float, lz: float) -> float:
	return TerrainGen.height_at(CENTER.x + lx, CENTER.z + lz)

func _place(model: String, lx: float, lz: float, yaw: float, sc: float, collider: String, y_off: float = 0.0) -> void:
	var ps := load(MODELS + model + ".gltf") as PackedScene
	if ps == null:
		push_warning("Village: missing model " + model)
		return
	var inst := ps.instantiate() as Node3D
	var holder: Node3D
	var box := _bounds(inst)
	if collider != "":
		var body := StaticBody3D.new()
		body.collision_layer = 1
		holder = body
	else:
		holder = Node3D.new()
	holder.name = model
	holder.position = Vector3(lx, _ground(lx, lz) + y_off, lz)
	holder.rotation.y = deg_to_rad(yaw)
	holder.scale = Vector3.ONE * sc
	holder.add_child(inst)
	add_child(holder)
	prop_count += 1
	var c := box.get_center()
	match collider:
		"box":
			_shape(holder, BoxShape3D.new(), Vector3(box.size.x * 0.96, box.size.y, box.size.z * 0.96), Vector3(c.x, c.y, c.z))
		"cyl":
			var cyl := CylinderShape3D.new()
			cyl.radius = maxf(box.size.x, box.size.z) * 0.45
			cyl.height = box.size.y
			_shape(holder, cyl, Vector3.ONE, Vector3(c.x, c.y, c.z))
		"trunk":
			var t := CylinderShape3D.new()
			t.radius = 0.35
			t.height = 3.0
			_shape(holder, t, Vector3.ONE, Vector3(c.x, 1.5, c.z))
		"gate":
			for sx in [-1.0, 1.0]:
				_shape(holder, BoxShape3D.new(), Vector3(0.6, box.size.y, 0.9), Vector3(c.x + sx * (box.size.x * 0.5 - 0.55), c.y, c.z))
	if CARVE.has(model):
		holder.set_meta("carve_radius", CARVE[model])

func _shape(holder: Node3D, shape: Shape3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	if shape is BoxShape3D:
		(shape as BoxShape3D).size = size
	cs.shape = shape
	cs.position = pos
	holder.add_child(cs)
	collider_count += 1

func _bounds(n: Node) -> AABB:
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
