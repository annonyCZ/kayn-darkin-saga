extends Node
## Renders Kayn's model from front, side and back on a neutral stage (needs a display). Env: VIEW_OUT (prefix).
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.2, 0.23)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.58)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 150, 0)
	rim.light_energy = 0.8
	add_child(rim)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(10, 10)
	floor_mi.mesh = pm
	add_child(floor_mi)
	var p := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate()
	add_child(p)
	p.set_physics_process(false)
	p.set_process(false)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.fov = 35
	await get_tree().create_timer(0.8).timeout
	var views := [[Vector3(0, 1.1, -4.6), "front"], [Vector3(4.6, 1.1, 0), "side"], [Vector3(-2.5, 1.2, 3.8), "back"], [Vector3(0.0, 1.8, -1.5), "face"]]
	for v in views:
		cam.position = v[0]
		cam.look_at(Vector3(0, 1.75 if v[1] == "face" else 1.0, 0))
		await get_tree().create_timer(0.4).timeout
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [OS.get_environment("VIEW_OUT"), v[1]])
	get_tree().quit()
