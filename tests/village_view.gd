extends Node
## Renders the village from above and from the arena side (needs a display). Env: VIEW_OUT (prefix).
func _ready() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(2.0).timeout
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.fov = 60
	var views := [[Vector3(0, 30, -36), Vector3(0, 0, -36.01), "top"], [Vector3(2, 4.5, -14), Vector3(0, 2.0, -34), "gate"], [Vector3(-20, 5, -26), Vector3(-2, 2.5, -40), "side"], [Vector3(1, 2.2, -33), Vector3(0, 3.0, -45), "pavilion"]]
	for v in views:
		cam.position = v[0]
		cam.look_at(v[1])
		await get_tree().create_timer(0.6).timeout
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [OS.get_environment("VIEW_OUT"), v[2]])
	get_tree().quit()
