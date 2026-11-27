class_name Hud
extends CanvasLayer
## Prototype HUD built in code: health, stamina, lock-on target bar, hints, death overlay.

var _player: Player
var _hp: HudBar
var _st: HudBar
var _target_box: VBoxContainer
var _target_name: Label
var _target_hp: HudBar
var _death: Label
var _hint: Label
var _mouse_hint: Label
var _path_label: Label
var _fx: ColorRect
var _hurt: float = 0.0
var _last_hp: float = 1.0
var _slots: Dictionary = {}
var _hint_age: float = 0.0

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
	tl.position = Vector2(34, 26)
	tl.add_theme_constant_override("separation", 6)
	root.add_child(tl)
	_path_label = Label.new()
	_path_label.add_theme_font_override("font", MenuTheme.title_font())
	_path_label.add_theme_font_size_override("font_size", 17)
	_path_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.78))
	tl.add_child(_path_label)
	_hp = HudBar.new(Color(0.74, 0.09, 0.11), 20, 380)
	_hp.ticks = 10
	_st = HudBar.new(Color(0.78, 0.66, 0.28), 9, 270)
	_st.trail_color = Color(0.9, 0.9, 0.8, 0.5)
	tl.add_child(_hp)
	tl.add_child(_st)

	_target_box = VBoxContainer.new()
	_target_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_target_box.custom_minimum_size = Vector2(420, 0)
	_target_box.position = Vector2(-210, -120)
	_target_box.visible = false
	root.add_child(_target_box)
	_target_name = Label.new()
	_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_name.add_theme_font_override("font", MenuTheme.title_font())
	_target_name.add_theme_font_size_override("font_size", 20)
	_target_hp = HudBar.new(Color(0.8, 0.32, 0.08), 14, 420)
	_target_box.add_child(_target_name)
	_target_box.add_child(_target_hp)

	_hint = Label.new()
	_hint.text = "WASD pohyb  |  Shift sprint  |  Mezerník skok  |  Ctrl úhyb  |  LMB lehký útok  |  PMB těžký  |  F blok (těsně před zásahem = odražení)  |  Q/E schopnosti  |  R tykev  |  G interakce  |  Tab zaměření  |  Esc pauza"
	_hint.position = Vector2(24, 0)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(24, -34)
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.modulate = Color(1, 1, 1, 0.7)
	root.add_child(_hint)

	_death = Label.new()
	_death.text = "ZEMŘEL JSI"
	_death.set_anchors_preset(Control.PRESET_CENTER)
	_death.position = Vector2(-120, -30)
	_death.add_theme_font_size_override("font_size", 56)
	_death.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	_death.visible = false
	root.add_child(_death)

	var ab := HBoxContainer.new()
	ab.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ab.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ab.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ab.offset_bottom = -44
	ab.add_theme_constant_override("separation", 16)
	root.add_child(ab)
	for key: String in ["gourd", "dashslash", "slam"]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		var slot := AbilitySlot.new({"gourd": "R", "dashslash": "Q", "slam": "E"}[key], {"gourd": "gourd", "dashslash": "dash", "slam": "slam"}[key])
		if key == "gourd":
			slot.count = 3
		col.add_child(slot)
		var lbl := Label.new()
		lbl.text = "Léčivá tykev" if key == "gourd" else {"dashslash": "Krok stínu", "slam": "Úder do země"}[key]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = Color(1, 1, 1, 0.75)
		col.add_child(lbl)
		ab.add_child(col)
		_slots[key] = slot

	_mouse_hint = Label.new()
	_mouse_hint.text = "Pozastaveno - kliknutím pokračuj"
	_mouse_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_mouse_hint.position = Vector2(-90, 60)
	_mouse_hint.add_theme_font_size_override("font_size", 20)
	_mouse_hint.visible = false
	root.add_child(_mouse_hint)

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
	for key: String in _slots:
		if key == "gourd":
			var gs := _slots[key] as AbilitySlot
			gs.count = _player.gourd_charges
			gs.set_cooldown(1.0 if _player.gourd_charges == 0 else 0.0)
		else:
			(_slots[key] as AbilitySlot).set_cooldown(_player.cooldown_fraction(key))
	_hint_age += get_process_delta_time()
	_hint.modulate.a = 0.7 * clampf((24.0 - _hint_age) / 4.0, 0.0, 1.0)
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
