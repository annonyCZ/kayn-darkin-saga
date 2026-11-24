extends Node
## End-to-end check of the real scene flow (needs a display, e.g. xvfb):
## menu -> New game -> game scene -> pause "Main menu" -> menu again. Uses a throw-away save prefix.
## Run: godot --path . res://tests/menu_flow_check.tscn
func _ready() -> void:
	var gs := get_node("/root/GameState")
	gs.save_prefix = "user://flowcheck_"
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as MainMenu
	menu.fade_time = 0.2
	add_child(menu)
	# The checker must outlive this scene, so it lives under the root window.
	var checker := Node.new()
	checker.name = "FlowChecker"
	checker.set_script(load("res://tests/menu_flow_checker.gd"))
	get_tree().root.add_child.call_deferred(checker)
	await get_tree().create_timer(1.0).timeout
	menu.activate("new")
