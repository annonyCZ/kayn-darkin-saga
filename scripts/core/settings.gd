extends Node
## Autoload "Settings": input map defaults, rebinding, and user settings.
## Input actions are registered in code so they are always valid and rebindable.

const SETTINGS_PATH := "user://settings.cfg"

var mouse_sensitivity: float = 1.0
var invert_y: bool = false

## action -> Array of default InputEvents (built in _default_bindings)
var _defaults: Dictionary = {}

func _ready() -> void:
	_register_defaults()
	load_settings()

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

func _mouse(btn: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = btn
	return e

func _pad_btn(btn: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	return e

func _pad_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e

func _register_defaults() -> void:
	_defaults = {
		"move_forward": [_key(KEY_W), _pad_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"move_back": [_key(KEY_S), _pad_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"move_left": [_key(KEY_A), _pad_axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [_key(KEY_D), _pad_axis(JOY_AXIS_LEFT_X, 1.0)],
		"cam_left": [_pad_axis(JOY_AXIS_RIGHT_X, -1.0)],
		"cam_right": [_pad_axis(JOY_AXIS_RIGHT_X, 1.0)],
		"cam_up": [_pad_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"cam_down": [_pad_axis(JOY_AXIS_RIGHT_Y, 1.0)],
		"sprint": [_key(KEY_SHIFT), _pad_btn(JOY_BUTTON_LEFT_STICK)],
		"jump": [_key(KEY_SPACE), _pad_btn(JOY_BUTTON_A)],
		"dodge": [_key(KEY_CTRL), _pad_btn(JOY_BUTTON_B)],
		"light_attack": [_mouse(MOUSE_BUTTON_LEFT), _pad_btn(JOY_BUTTON_X)],
		"heavy_attack": [_mouse(MOUSE_BUTTON_RIGHT), _pad_btn(JOY_BUTTON_Y)],
		"block": [_key(KEY_F), _pad_btn(JOY_BUTTON_LEFT_SHOULDER)],
		"ability_1": [_key(KEY_Q), _pad_btn(JOY_BUTTON_RIGHT_SHOULDER)],
		"ability_2": [_key(KEY_E), _pad_btn(JOY_BUTTON_DPAD_DOWN)],
		"lock_on": [_key(KEY_TAB), _pad_btn(JOY_BUTTON_RIGHT_STICK)],
		"target_next": [_mouse(MOUSE_BUTTON_WHEEL_DOWN), _pad_btn(JOY_BUTTON_DPAD_RIGHT)],
		"target_prev": [_mouse(MOUSE_BUTTON_WHEEL_UP), _pad_btn(JOY_BUTTON_DPAD_LEFT)],
		"interact": [_key(KEY_G), _pad_btn(JOY_BUTTON_DPAD_UP)],
		"pause": [_key(KEY_ESCAPE), _pad_btn(JOY_BUTTON_START)],
	}
	for action: String in _defaults:
		_apply_events(action, _defaults[action])

func _apply_events(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	InputMap.action_erase_events(action)
	for e: InputEvent in events:
		InputMap.action_add_event(action, e)

## Replace all events of an action with a single new event (rebinding) and persist.
func rebind(action: String, event: InputEvent) -> void:
	if not _defaults.has(action):
		return
	_apply_events(action, [event])
	save_settings()

func reset_bindings() -> void:
	for action: String in _defaults:
		_apply_events(action, _defaults[action])
	save_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("input", "invert_y", invert_y)
	for action: String in _defaults:
		var evs: Array = []
		for e in InputMap.action_get_events(action):
			evs.append(var_to_str(e))
		cfg.set_value("bindings", action, evs)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", 1.0)
	invert_y = cfg.get_value("input", "invert_y", false)
	if cfg.has_section("bindings"):
		for action: String in cfg.get_section_keys("bindings"):
			if not _defaults.has(action):
				continue
			var parsed: Array = []
			for s: String in cfg.get_value("bindings", action, []):
				var e: Variant = str_to_var(s)
				if e is InputEvent:
					parsed.append(e)
			if not parsed.is_empty():
				_apply_events(action, parsed)
