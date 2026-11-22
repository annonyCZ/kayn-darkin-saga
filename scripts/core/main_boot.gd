extends Node
## Wires the camera rig to the player when the main scene starts.

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var rig := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	if player and rig:
		rig.set_follow_target(player)
