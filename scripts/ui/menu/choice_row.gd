class_name ChoiceRow
extends HBoxContainer
## "Name  <  value  >" selector. Left/Right (or Enter) change the value; also clickable.

signal changed(index: int)

var options: Array[String] = []
var index: int = 0
var _value: Label

func _init(row_name: String = "", opts: Array[String] = [], idx: int = 0) -> void:
	options = opts
	index = clampi(idx, 0, maxi(opts.size() - 1, 0))
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(0, 50)
	add_theme_constant_override("separation", 8)
	var name_l := Label.new()
	name_l.text = row_name
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.add_theme_constant_override("margin_left", 12)
	add_child(name_l)
	var l := MenuArrow.new(-1)
	l.pressed.connect(step.bind(-1))
	add_child(l)
	_value = Label.new()
	_value.custom_minimum_size = Vector2(250, 0)
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_value)
	var r := MenuArrow.new(1)
	r.pressed.connect(step.bind(1))
	add_child(r)
	_refresh()
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(grab_focus)

func set_index(i: int) -> void:
	index = clampi(i, 0, maxi(options.size() - 1, 0))
	_refresh()

func step(dir: int) -> void:
	if options.is_empty():
		return
	index = posmod(index + dir, options.size())
	_refresh()
	Sfx.play("ui_move", null, -6.0)
	changed.emit(index)

func _refresh() -> void:
	_value.text = options[index] if not options.is_empty() else ""

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		step(-1)
		accept_event()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		step(1)
		accept_event()

func _draw() -> void:
	if has_focus():
		draw_rect(Rect2(Vector2.ZERO, size), Color(MenuTheme.RED, 0.20))
		draw_rect(Rect2(0, 0, 3, size.y), MenuTheme.RED_HI)
