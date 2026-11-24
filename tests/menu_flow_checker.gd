extends Node
## Helper of menu_flow_check.gd (lives under the root window and survives scene changes).
func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	var cs := get_tree().current_scene
	var ok1 := cs != null and cs.name == "Main" and get_tree().get_first_node_in_group("player") != null
	print("FLOW menu -> game: ", "OK" if ok1 else "FAIL (scene=%s)" % [cs.name if cs else "null"])
	var gs := get_node("/root/GameState")
	print("FLOW new game saved in slot ", gs.slot, ": ", "OK" if FileAccess.file_exists(gs.slot_path(1)) else "FAIL")
	var pm := cs.get_node("PauseMenu") as PauseMenu
	pm._to_main_menu()
	await get_tree().create_timer(2.5).timeout
	cs = get_tree().current_scene
	print("FLOW pause -> menu: ", "OK" if cs is MainMenu and not get_tree().paused else "FAIL")
	for i in range(1, 4):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.slot_path(i)))
	get_tree().quit(0 if ok1 and cs is MainMenu else 1)
