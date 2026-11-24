class_name PauseMenu
extends CanvasLayer
## Esc / Start toggles pause. Resume or quit to desktop.

var _panel: PanelContainer

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.visible = false
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(260, 0)
	_panel.add_child(v)
	var t := Label.new(); t.text = "PAUSED"; t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 32)
	v.add_child(t)
	var r := Button.new(); r.text = "Resume"; r.pressed.connect(toggle); v.add_child(r)
	var mm := Button.new(); mm.text = "Main menu"; mm.pressed.connect(_to_main_menu); v.add_child(mm)
	var q := Button.new(); q.text = "Quit game"; q.pressed.connect(func() -> void: get_tree().quit()); v.add_child(q)
	add_child(_panel)

## Back to the main menu (progress is already saved by GameState on every change).
func _to_main_menu() -> void:
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func is_open() -> bool:
	return _panel.visible

func toggle() -> void:
	var open := not _panel.visible
	_panel.visible = open
	get_tree().paused = open
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# The path-choice screen owns the pause state while it is open.
		for c in get_tree().root.get_children():
			if c is PathChoice:
				return
		toggle()
		get_viewport().set_input_as_handled()
