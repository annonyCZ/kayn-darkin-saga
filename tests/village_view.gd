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
	var views := [[Vector3(0, 70, -66), Vector3(0, 0, -66.01), "top"], [Vector3(3, 3.2, -34), Vector3(0, 2.4, -60), "gate"], [Vector3(-8, 3.0, -60), Vector3(8, 2.0, -85), "side"], [Vector3(21.2, 1.8, -89.2), Vector3(26.5, 1.5, -93.2), "hall"], [Vector3(2, 3.0, -85), Vector3(22, 2.2, -92), "hallout"]]
	for v in views:
		cam.position = v[0]
		cam.look_at(v[1])
		await get_tree().create_timer(0.6).timeout
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [OS.get_environment("VIEW_OUT"), v[2]])
	get_tree().quit()
