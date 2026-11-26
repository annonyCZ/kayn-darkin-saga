class_name EnvProps
extends RefCounted
## Loads meshes from the supplied nature / town packs and weathers them (desaturated, darkened) so the
## cheerful cartoon palettes sit in the grim dusk grade. Results are cached per model.

const NATURE := "res://assets/environments/stylized_nature/models/"
const TOWN := "res://assets/environments/chinese_town/models/"

static var _cache: Dictionary = {}

## Mesh of the first MeshInstance3D in a .glb, with every surface weathered.
## `keep` = how much of the original colour survives (0 = grey), `tint` multiplies the result.
static func mesh(path: String, keep: float = 0.4, tint: Color = Color(0.7, 0.68, 0.66)) -> Mesh:
	var key := "%s|%.2f|%s" % [path, keep, tint]
	if _cache.has(key):
		return _cache[key]
	var ps := load(path) as PackedScene
	if ps == null:
		push_warning("EnvProps: missing " + path)
		return null
	var root := ps.instantiate()
	var found := root.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		root.free()
		return null
	var m := ((found[0] as MeshInstance3D).mesh).duplicate() as Mesh
	root.free()
	for i in m.get_surface_count():
		var src := m.surface_get_material(i) as BaseMaterial3D
		if src == null:
			continue
		var d := src.duplicate() as BaseMaterial3D
		var base := src.albedo_color
		var lum := base.r * 0.3 + base.g * 0.59 + base.b * 0.11
		d.albedo_color = Color(lum, lum, lum, base.a).lerp(base, keep) * tint
		if d.albedo_texture != null:
			d.albedo_texture = Village._weathered(d.albedo_texture, keep)
		d.roughness = maxf(src.roughness, 0.85)
		d.metallic = 0.0
		m.surface_set_material(i, d)
	_cache[key] = m
	return m
