class_name ChinesePavilion
extends StaticBody3D
## Chinese four-corner pavilion (user-supplied FBX, see docs/ASSET_REGISTER.md).
## The FBX units are ~cm, so it is scaled down; materials are assigned by part name at load
## (the FBX has no usable texture links), and four pillar colliders let the player walk inside.

const MODEL := "res://assets/environments/chinese_pavilion/pavilion.fbx"
## The supplied "*_UV.png" files are UV-layout templates (wireframes), not albedo textures, so the
## parts get flat PBR materials by role instead: [colour, roughness, metallic].
const LACQUER := [Color(0.42, 0.05, 0.05), 0.42, 0.0]
const WOOD := [Color(0.20, 0.09, 0.05), 0.65, 0.0]
const RAFTER := [Color(0.30, 0.10, 0.06), 0.7, 0.0]
const TILE := [Color(0.13, 0.14, 0.17), 0.6, 0.0]
const RIDGE := [Color(0.2, 0.2, 0.23), 0.55, 0.0]
const GOLD := [Color(0.78, 0.55, 0.16), 0.35, 0.7]
const PLAQUE := [Color(0.04, 0.03, 0.03), 0.4, 0.0]
const PARTS := {
	"檐柱": LACQUER, "额枋": LACQUER, "抹角梁": LACQUER, "檐檩垫板": LACQUER, "金檩金枋": LACQUER,
	"老角梁": LACQUER, "仔角梁由戗": LACQUER, "挂落": WOOD, "扶手": LACQUER, "坐凳": WOOD,
	"对联": PLAQUE, "牌匾": PLAQUE, "衬头木": WOOD, "檐椽": RAFTER, "飞椽": RAFTER, "脑椽": RAFTER,
	"瓦面": TILE, "垂脊": RIDGE, "角云": GOLD, "套兽": GOLD, "雷公柱宝顶": GOLD,
}
const ALIAS := {"雷公柱": "雷公柱宝顶"}

@export var model_scale: float = 0.17
## Part names without a colour entry in PARTS (they fall back to wood); empty when all are matched.
var unmatched_parts: Array[String] = []

func _ready() -> void:
	collision_layer = 1
	var ps := load(MODEL) as PackedScene
	if ps == null:
		push_error("ChinesePavilion: model missing")
		return
	var model := ps.instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * model_scale
	add_child(model)
	var cache := {}
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			var key := String(src.resource_name).rstrip("0123456789") if src else ""
			key = ALIAS.get(key, key)
			if not cache.has(key):
				var spec: Array = PARTS.get(key, WOOD)
				if not PARTS.has(key):
					unmatched_parts.append(key)
				var m := StandardMaterial3D.new()
				m.albedo_color = spec[0]
				m.roughness = spec[1]
				m.metallic = spec[2]
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				cache[key] = m
			mi.set_surface_override_material(i, cache[key])
	# FBX units: pillars at +-11 from the centre, radius ~1.43, height ~20.4.
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 1.45 * model_scale
			cyl.height = 20.4 * model_scale
			cs.shape = cyl
			cs.position = Vector3(11.0 * sx, 10.2, 11.0 * sz) * model_scale
			add_child(cs)
