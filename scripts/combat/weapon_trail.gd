class_name WeaponTrail
extends MeshInstance3D
## Ribbon trail behind a weapon swing. Samples two points (base/tip, given in the
## tracked node's local space) while `emitting` and draws a fading additive strip.

@export var tracked_path: NodePath
@export var base_local: Vector3 = Vector3(0, 0, -0.5)
@export var tip_local: Vector3 = Vector3(-1.1, 0, -1.95)
@export var life: float = 0.18
@export var trail_color: Color = Color(0.75, 0.5, 1.0)

var emitting: bool = false
var _tracked: Node3D
var _samples: Array = []   # [time, base, tip]
var _im: ImmediateMesh

func _ready() -> void:
	top_level = true
	_tracked = get_node_or_null(tracked_path) as Node3D
	_im = ImmediateMesh.new()
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = m
	global_transform = Transform3D.IDENTITY

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if emitting and _tracked != null:
		var xf := _tracked.global_transform
		_samples.append([now, xf * base_local, xf * tip_local])
	while not _samples.is_empty() and now - float(_samples[0][0]) > life:
		_samples.pop_front()
	_im.clear_surfaces()
	if _samples.size() < 2:
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for s: Array in _samples:
		var a := 1.0 - (now - float(s[0])) / life
		_im.surface_set_color(Color(trail_color.r, trail_color.g, trail_color.b, a * 0.1))
		_im.surface_add_vertex(s[1])
		_im.surface_set_color(Color(trail_color.r, trail_color.g, trail_color.b, a * 0.9))
		_im.surface_add_vertex(s[2])
	_im.surface_end()
