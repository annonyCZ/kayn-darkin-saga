class_name PathAltar
extends Area3D
## Interactable altar where Kayn makes his permanent path choice (press interact).

var _player_inside: bool = false
var _open: Node = null
@onready var _prompt: Label3D = $Prompt

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(b: Node3D) -> void: if b is Player: _player_inside = true)
	body_exited.connect(func(b: Node3D) -> void: if b is Player: _player_inside = false)

func _process(_delta: float) -> void:
	var gs := get_node_or_null("/root/GameState")
	var locked: bool = gs != null and bool(gs.path_locked)
	_prompt.visible = _player_inside and not locked and _open == null
	_prompt.text = "[G] Poklekni k oltáři - vyber Kaynovu cestu"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_open()

func try_open() -> bool:
	var gs := get_node_or_null("/root/GameState")
	if not _player_inside or _open != null or gs == null or gs.path_locked:
		return false
	var ui := (load("res://scripts/ui/path_choice.gd") as GDScript).new() as PathChoice
	_open = ui
	ui.finished.connect(func(_p: int) -> void: _open = null)
	get_tree().root.add_child(ui)
	return true
