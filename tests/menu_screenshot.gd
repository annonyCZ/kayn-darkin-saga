extends Node
## Renders the main menu (optionally with a panel open) and saves a PNG. Needs a display/GL (xvfb).
## Env: SHOT_PATH, SHOT_PANEL = "" | load | settings | gallery | credits | quit | controls | audio, SHOT_FOCUS=id
func _ready() -> void:
	var gs := get_node("/root/GameState")
	gs.save_prefix = "user://shot_"
	if OS.get_environment("SHOT_SAVES") != "":
		for i in int(OS.get_environment("SHOT_SAVES")):
			gs.set_slot(i + 1)
			gs.kayn_path = i % 3
			gs.path_locked = i % 3 != 0
			gs.save_game()
		gs.set_slot(1)
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as MainMenu
	menu.dry_run = true
	menu.fade_time = 0.1
	add_child(menu)
	await get_tree().create_timer(2.6).timeout
	var pn := OS.get_environment("SHOT_PANEL")
	if OS.get_environment("SHOT_FOCUS") != "":
		(menu.items[OS.get_environment("SHOT_FOCUS")] as MenuItem).grab_focus()
	if pn in ["load", "settings", "gallery", "credits"]:
		menu.activate(pn)
		await get_tree().create_timer(0.8).timeout
		if menu.panel is SettingsPanel:
			if OS.get_environment("SHOT_TAB") != "":
				(menu.panel as SettingsPanel)._set_tab(int(OS.get_environment("SHOT_TAB")))
				await get_tree().create_timer(0.3).timeout
	elif pn == "quit":
		menu.activate("quit")
		await get_tree().create_timer(0.6).timeout
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_PATH"))
	for i in range(1, 4):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.slot_path(i)))
	get_tree().quit()
