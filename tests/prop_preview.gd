extends Node
## Renders a scene from a few angles for visual inspection (needs a display). Env: PREVIEW_SCENE, PREVIEW_OUT (prefix), PREVIEW_DIST, PREVIEW_H
func _ready() -> void:
	var vp := get_viewport()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.5, 0.58)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, -30, 0); add_child(sun)
	var path := OS.get_environment("PREVIEW_SCENE")
	var inst: Node = ClassDB.instantiate("Node3D") if false else null
	if path.ends_with(".gd"):
		inst = (load(path) as GDScript).new()
	else:
		inst = (load(path) as PackedScene).instantiate()
	add_child(inst)
	var cam := Camera3D.new(); add_child(cam)
	var d := float(OS.get_environment("PREVIEW_DIST")) if OS.get_environment("PREVIEW_DIST") != "" else 15.0
	var h := float(OS.get_environment("PREVIEW_H")) if OS.get_environment("PREVIEW_H") != "" else 3.0
	var k := 0
	for yaw in [0.0, 50.0, 140.0]:
		var a := deg_to_rad(yaw)
		cam.position = Vector3(sin(a) * d, h + d * 0.25, cos(a) * d)
		cam.look_at(Vector3(0, h, 0))
		await get_tree().create_timer(0.5).timeout
		vp.get_texture().get_image().save_png("%s_%d.png" % [OS.get_environment("PREVIEW_OUT"), k])
		k += 1
	get_tree().quit()
