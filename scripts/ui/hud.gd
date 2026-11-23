class_name Hud
extends CanvasLayer
## Prototype HUD built in code: health, stamina, lock-on target bar, hints, death overlay.

var _player: Player
var _hp: ProgressBar
var _st: ProgressBar
var _target_box: VBoxContainer
var _target_name: Label
var _target_hp: ProgressBar
var _death: Label
var _hint: Label
var _mouse_hint: Label
var _path_label: Label
var _fx: ColorRect
var _hurt: float = 0.0
var _last_hp: float = 1.0
var _ability_bars: Dictionary = {}
var _ability_labels: Dictionary = {}

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_fx = ColorRect.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fxm := ShaderMaterial.new()
	fxm.shader = load("res://assets/shaders/screen_fx.gdshader")
	_fx.material = fxm
	root.add_child(_fx)

	var tl := VBoxContainer.new()
	tl.position = Vector2(24, 20)
	tl.custom_minimum_size = Vector2(340, 0)
	root.add_child(tl)
	_hp = _bar(Color(0.78, 0.12, 0.16), 22)
	_st = _bar(Color(0.25, 0.7, 0.35), 12)
	tl.add_child(_hp)
	tl.add_child(_st)
	_path_label = Label.new()
	_path_label.add_theme_font_size_override("font_size", 14)
	tl.add_child(_path_label)

	_target_box = VBoxContainer.new()
	_target_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_target_box.custom_minimum_size = Vector2(420, 0)
	_target_box.position = Vector2(-210, -120)
	_target_box.visible = false
	root.add_child(_target_box)
	_target_name = Label.new()
	_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_hp = _bar(Color(0.85, 0.5, 0.1), 14)
	_target_box.add_child(_target_name)
	_target_box.add_child(_target_hp)

	_hint = Label.new()
	_hint.text = "WASD move  |  Shift sprint  |  Space jump  |  Ctrl dodge  |  LMB light combo  |  RMB heavy  |  F block (tap just before a hit = parry)  |  Q/E abilities  |  Tab lock-on (wheel: switch)  |  Esc pause"
	_hint.position = Vector2(24, 0)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(24, -34)
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.modulate = Color(1, 1, 1, 0.7)
	root.add_child(_hint)

	_death = Label.new()
	_death.text = "YOU DIED"
	_death.set_anchors_preset(Control.PRESET_CENTER)
	_death.position = Vector2(-120, -30)
	_death.add_theme_font_size_override("font_size", 56)
	_death.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	_death.visible = false
	root.add_child(_death)

	var ab := HBoxContainer.new()
	ab.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ab.position = Vector2(-330, -110)
	ab.add_theme_constant_override("separation", 12)
	root.add_child(ab)
	for key: String in ["dashslash", "slam"]:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(150, 0)
		var lbl := Label.new()
		lbl.text = "%s [%s]" % [Player.ABILITY_NAMES[key], "Q" if key == "dashslash" else "E"]
		var bar := _bar(Color(0.3, 0.55, 0.95), 10)
		box.add_child(lbl)
		box.add_child(bar)
		ab.add_child(box)
		_ability_bars[key] = bar
		_ability_labels[key] = lbl

	_mouse_hint = Label.new()
	_mouse_hint.text = "Paused - click to resume"
	_mouse_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_mouse_hint.position = Vector2(-90, 60)
	_mouse_hint.add_theme_font_size_override("font_size", 20)
	_mouse_hint.visible = false
	root.add_child(_mouse_hint)

func _bar(color: Color, height: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, height)
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(1)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.02, 0.02, 0.75)
	bg.border_color = Color(0.78, 0.62, 0.3, 0.9)     # thin gold frame
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(2)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	return b

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	var frac := _player.health.fraction()
	if frac < _last_hp - 0.001:
		_hurt = 1.0
	_last_hp = frac
	_hurt = maxf(0.0, _hurt - get_process_delta_time() * 2.5)
	var sm := _fx.material as ShaderMaterial
	sm.set_shader_parameter("hurt", _hurt)
	sm.set_shader_parameter("low_health", clampf((0.35 - frac) / 0.35, 0.0, 1.0))
	_hp.value = frac
	_st.value = _player.stamina / _player.max_stamina
	_path_label.text = String(_player.profile["name"])
	for key: String in _ability_bars:
		(_ability_bars[key] as ProgressBar).value = 1.0 - _player.cooldown_fraction(key)
	_death.visible = _player.state == Player.State.DEAD
	var t := _player.lock_target
	if t != null and is_instance_valid(t):
		var h := t.get_node_or_null("Health") as HealthComponent
		_target_box.visible = h != null
		if h:
			_target_hp.value = h.fraction()
			_target_name.text = str(t.get("display_name"))
	else:
		_target_box.visible = false
	_mouse_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
