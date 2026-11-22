extends Node
## Renders the main scene and saves a screenshot (needs a display/GL, e.g. xvfb).
func _ready() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	add_child(main)
	for i in 40: await get_tree().process_frame
	var p := get_tree().get_first_node_in_group("player") as Player
	var rig := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	p.global_position = Vector3(float(OS.get_environment("SHOT_X") if OS.get_environment("SHOT_X") != "" else "0"), 0.1, float(OS.get_environment("SHOT_Z") if OS.get_environment("SHOT_Z") != "" else "10"))
	rig.yaw = float(OS.get_environment("SHOT_YAW") if OS.get_environment("SHOT_YAW") != "" else "0.3")
	if OS.get_environment("SHOT_ATTACK") != "":
		Input.action_press("light_attack")
	await get_tree().create_timer(0.5 if OS.get_environment("SHOT_ATTACK") == "" else 0.25).timeout
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_PATH"))
	get_tree().quit()
