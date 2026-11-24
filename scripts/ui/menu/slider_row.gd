class_name SliderRow
extends HBoxContainer
## "Name  [-----o-----]  value" row backed by an HSlider.

signal changed(value: float)

var slider: HSlider
var _value: Label
var _fmt: Callable

func _init(row_name: String = "", min_v: float = 0.0, max_v: float = 1.0, step_v: float = 0.01, start: float = 0.5, formatter: Callable = Callable()) -> void:
	_fmt = formatter if formatter.is_valid() else func(v: float) -> String: return "%d %%" % roundi(v * 100.0)
	custom_minimum_size = Vector2(0, 50)
	add_theme_constant_override("separation", 16)
	var name_l := Label.new()
	name_l.text = row_name
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(name_l)
	slider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = start
	slider.custom_minimum_size = Vector2(300, 36)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_ALL
	add_child(slider)
	_value = Label.new()
	_value.custom_minimum_size = Vector2(80, 0)
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_value)
	_value.text = _fmt.call(start)
	slider.value_changed.connect(func(v: float) -> void:
		_value.text = _fmt.call(v)
		changed.emit(v))
	slider.drag_ended.connect(func(_c: bool) -> void: Sfx.play("ui_move", null, -6.0))
	slider.focus_entered.connect(queue_redraw)
	slider.focus_exited.connect(queue_redraw)
	slider.mouse_entered.connect(slider.grab_focus)

func _draw() -> void:
	if slider != null and slider.has_focus():
		draw_rect(Rect2(Vector2.ZERO, size), Color(MenuTheme.RED, 0.20))
		draw_rect(Rect2(0, 0, 3, size.y), MenuTheme.RED_HI)
