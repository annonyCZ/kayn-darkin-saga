extends Node
## Autoload "Settings": input map defaults, rebinding, and user settings.
## Input actions are registered in code so they are always valid and rebindable.

const SETTINGS_PATH := "user://settings.cfg"

var mouse_sensitivity: float = 1.0
var invert_y: bool = false

# --- Graphics (applied live by apply_graphics) ---
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const FPS_CAPS: Array[int] = [0, 30, 60, 90, 120, 144, 240]
enum WindowMode { WINDOWED, BORDERLESS, FULLSCREEN }
var window_mode: int = WindowMode.WINDOWED
var resolution_index: int = 1
var vsync: bool = true
var msaa: int = 0 ## 0 = off, 1 = 2x, 2 = 4x, 3 = 8x
var render_scale: float = 1.0
var fps_cap: int = 0

# --- Audio (linear 0..1, applied to the Master / SFX / Ambience buses) ---
var vol_master: float = 0.8
var vol_sfx: float = 1.0
var vol_ambience: float = 1.0

## action -> Array of default InputEvents (built in _default_bindings)
var _defaults: Dictionary = {}

func _ready() -> void:
	_register_defaults()
	ensure_audio_buses()
	load_settings()
	apply_audio()
	apply_graphics()

## Creates the SFX and Ambience buses (children of Master) if they do not exist yet.
func ensure_audio_buses() -> void:
	for bus_name in ["SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))

func apply_audio() -> void:
	_set_bus_linear("Master", vol_master)
	_set_bus_linear("SFX", vol_sfx)
	_set_bus_linear("Ambience", vol_ambience)

func apply_graphics() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var vp := tree.root
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X][clampi(msaa, 0, 3)]
	vp.scaling_3d_scale = clampf(render_scale, 0.5, 1.0)
	Engine.max_fps = fps_cap
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	match window_mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			var size: Vector2i = RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]
			var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
			size = Vector2i(mini(size.x, screen.size.x), mini(size.y, screen.size.y))
			DisplayServer.window_set_size(size)
			DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)

## Restores graphics + audio + mouse options to defaults (key bindings are reset separately).
func reset_options() -> void:
	mouse_sensitivity = 1.0
	invert_y = false
	window_mode = WindowMode.WINDOWED
	resolution_index = 1
	vsync = true
	msaa = 0
	render_scale = 1.0
	fps_cap = 0
	vol_master = 0.8
	vol_sfx = 1.0
	vol_ambience = 1.0
	apply_audio()
	apply_graphics()
	save_settings()

## Rebinds only the keyboard/mouse event of an action; gamepad bindings are kept.
## If another action already uses that key, the two actions swap keys.
## Returns the name of the action that was swapped (or "" if none).
func rebind_kbm(action: String, event: InputEvent) -> String:
	if not _defaults.has(action) or not (event is InputEventKey or event is InputEventMouseButton):
		return ""
	var old_kbm: InputEvent = null
	var rest: Array = []
	for e: InputEvent in InputMap.action_get_events(action):
		if e is InputEventKey or e is InputEventMouseButton:
			old_kbm = e
		else:
			rest.append(e)
	var swapped := ""
	for other: String in _defaults:
		if other == action:
			continue
		var other_events := InputMap.action_get_events(other)
		for oe: InputEvent in other_events:
			if (oe is InputEventKey or oe is InputEventMouseButton) and _same_binding(oe, event):
				var keep: Array = []
				for e2: InputEvent in other_events:
					if e2 != oe:
						keep.append(e2)
				if old_kbm != null:
					keep.append(old_kbm)
				_apply_events(other, keep)
				swapped = other
				break
		if swapped != "":
			break
	rest.append(event)
	_apply_events(action, rest)
	save_settings()
	return swapped

func _same_binding(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return false

## Human-readable (Czech) label of the keyboard/mouse binding of an action.
func binding_text(action: String) -> String:
	for e: InputEvent in InputMap.action_get_events(action):
		if e is InputEventKey:
			var k := e as InputEventKey
			return k.as_text_physical_keycode() if k.physical_keycode != KEY_NONE else k.as_text_keycode()
		if e is InputEventMouseButton:
			match (e as InputEventMouseButton).button_index:
				MOUSE_BUTTON_LEFT: return "Levé tlačítko myši"
				MOUSE_BUTTON_RIGHT: return "Pravé tlačítko myši"
				MOUSE_BUTTON_MIDDLE: return "Prostřední tlačítko myši"
				MOUSE_BUTTON_WHEEL_UP: return "Kolečko nahoru"
				MOUSE_BUTTON_WHEEL_DOWN: return "Kolečko dolů"
				_: return "Tlačítko myši %d" % (e as InputEventMouseButton).button_index
	return "—"

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
	cfg.set_value("graphics", "window_mode", window_mode)
	cfg.set_value("graphics", "resolution_index", resolution_index)
	cfg.set_value("graphics", "vsync", vsync)
	cfg.set_value("graphics", "msaa", msaa)
	cfg.set_value("graphics", "render_scale", render_scale)
	cfg.set_value("graphics", "fps_cap", fps_cap)
	cfg.set_value("audio", "master", vol_master)
	cfg.set_value("audio", "sfx", vol_sfx)
	cfg.set_value("audio", "ambience", vol_ambience)
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
	window_mode = clampi(int(cfg.get_value("graphics", "window_mode", WindowMode.WINDOWED)), 0, 2)
	resolution_index = clampi(int(cfg.get_value("graphics", "resolution_index", 1)), 0, RESOLUTIONS.size() - 1)
	vsync = bool(cfg.get_value("graphics", "vsync", true))
	msaa = clampi(int(cfg.get_value("graphics", "msaa", 0)), 0, 3)
	render_scale = clampf(float(cfg.get_value("graphics", "render_scale", 1.0)), 0.5, 1.0)
	fps_cap = int(cfg.get_value("graphics", "fps_cap", 0))
	vol_master = clampf(float(cfg.get_value("audio", "master", 0.8)), 0.0, 1.0)
	vol_sfx = clampf(float(cfg.get_value("audio", "sfx", 1.0)), 0.0, 1.0)
	vol_ambience = clampf(float(cfg.get_value("audio", "ambience", 1.0)), 0.0, 1.0)
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
