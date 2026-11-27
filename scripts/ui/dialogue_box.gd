class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen dialogue panel. Lines advance with the interact / jump / light-attack action;
## `finished` fires after the last line. The game keeps running underneath (combat arena).

signal finished

var speaker: String = ""
var lines: Array[String] = []
var index: int = 0
var _label: Label
var _name: Label
var _hint: Label
var _closed: bool = false

func _init(speaker_: String = "", lines_: Array[String] = []) -> void:
	speaker = speaker_
	lines = lines_

func _ready() -> void:
	layer = 20
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.custom_minimum_size = Vector2(760, 0)
	panel.offset_bottom = -150
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.02, 0.03, 0.92)
	sb.border_color = Color(0.78, 0.62, 0.3, 0.9)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	_name = Label.new()
	_name.text = speaker
	_name.add_theme_font_override("font", MenuTheme.title_font())
	_name.add_theme_font_size_override("font_size", 22)
	_name.add_theme_color_override("font_color", Color(0.9, 0.75, 0.45))
	v.add_child(_name)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(720, 70)
	_label.add_theme_font_size_override("font_size", 19)
	v.add_child(_label)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.modulate = Color(1, 1, 1, 0.55)
	v.add_child(_hint)
	_show()

func _show() -> void:
	_label.text = lines[index]
	_hint.text = "[G] dál" if index < lines.size() - 1 else "[G] zavřít"

func advance() -> void:
	if _closed:
		return
	index += 1
	if index >= lines.size():
		_closed = true
		finished.emit()
		queue_free()
	else:
		_show()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		advance()
		get_viewport().set_input_as_handled()
