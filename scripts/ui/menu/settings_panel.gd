class_name SettingsPanel
extends MenuPanel
## Real settings: graphics, audio, controls. Every change is applied immediately and persisted
## via the Settings autoload (user://settings.cfg).

const BIND_ACTIONS: Array = [
	["move_forward", "Pohyb vpřed"], ["move_back", "Pohyb vzad"], ["move_left", "Pohyb vlevo"],
	["move_right", "Pohyb vpravo"], ["sprint", "Sprint"], ["jump", "Skok"], ["dodge", "Úhyb"],
	["light_attack", "Lehký útok"], ["heavy_attack", "Těžký útok"], ["block", "Blok"],
	["ability_1", "Schopnost 1"], ["ability_2", "Schopnost 2"], ["lock_on", "Zaměřit cíl"],
	["interact", "Interakce"],
]
const SCALES: Array[float] = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

var tab: int = 0
var capturing_action: String = ""
var _content: VBoxContainer
var _scroll: ScrollContainer
var _tabs: Array[Button] = []
var _bind_buttons: Dictionary = {}
var _note: Label
var _st: Node

func _init() -> void:
	panel_title = "Nastavení"
	panel_width = 900.0

func _ready() -> void:
	_st = get_node("/root/Settings")
	add_theme_constant_override("separation", 14)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	var group := ButtonGroup.new()
	for i in 3:
		var b := Button.new()
		b.text = ["Grafika", "Zvuk", "Ovládání"][i]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = (i == tab)
		b.custom_minimum_size = Vector2(150, 44)
		b.pressed.connect(_set_tab.bind(i))
		bar.add_child(b)
		_tabs.append(b)
	add_child(bar)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 420)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 18)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 4)
	pad.add_child(_content)
	_scroll.add_child(pad)
	add_child(_scroll)
	_note = Label.new()
	_note.add_theme_font_size_override("font_size", 20)
	_note.add_theme_color_override("font_color", MenuTheme.DIM)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(panel_width - 60.0, 56)
	add_child(_note)
	var reset := Button.new()
	reset.text = "Obnovit výchozí hodnoty"
	reset.custom_minimum_size = Vector2(0, 44)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(reset_defaults)
	add_child(reset)
	_build_tab()

func focus_first() -> void:
	var c := _first_focusable(_content)
	if c != null:
		c.grab_focus()
	elif not _tabs.is_empty():
		_tabs[0].grab_focus()

func _set_tab(i: int) -> void:
	tab = i
	_build_tab()

func reset_defaults() -> void:
	_st.reset_options()
	_st.reset_bindings()
	_build_tab()
	_note.text = "Výchozí hodnoty obnoveny."

func _clear() -> void:
	capturing_action = ""
	_bind_buttons.clear()
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()

func _opt(arr: Array) -> Array[String]:
	var out: Array[String] = []
	for a in arr:
		out.append(str(a))
	return out

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", MenuTheme.title_font())
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", MenuTheme.RED_HI)
	l.custom_minimum_size = Vector2(0, 40)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_content.add_child(l)

func _build_tab() -> void:
	_clear()
	_note.text = ""
	match tab:
		0: _build_graphics()
		1: _build_audio()
		2: _build_controls()

func _build_graphics() -> void:
	var s := _st
	var mode := ChoiceRow.new("Režim okna", _opt(["V okně", "Okno bez okrajů", "Celá obrazovka"]), s.window_mode)
	mode.changed.connect(func(i: int) -> void:
		s.window_mode = i
		_commit_graphics())
	_content.add_child(mode)
	var res_names: Array[String] = []
	for r: Vector2i in s.RESOLUTIONS:
		res_names.append("%d × %d" % [r.x, r.y])
	var res := ChoiceRow.new("Rozlišení okna", res_names, s.resolution_index)
	res.changed.connect(func(i: int) -> void:
		s.resolution_index = i
		_commit_graphics())
	_content.add_child(res)
	var vs := ChoiceRow.new("Vertikální synchronizace", _opt(["Zapnuto", "Vypnuto"]), 0 if s.vsync else 1)
	vs.changed.connect(func(i: int) -> void:
		s.vsync = (i == 0)
		_commit_graphics())
	_content.add_child(vs)
	var aa := ChoiceRow.new("Vyhlazování hran (MSAA)", _opt(["Vypnuto", "2×", "4×", "8×"]), s.msaa)
	aa.changed.connect(func(i: int) -> void:
		s.msaa = i
		_commit_graphics())
	_content.add_child(aa)
	var scale_names: Array[String] = []
	var sidx := 0
	for i in SCALES.size():
		scale_names.append("%d %%" % roundi(SCALES[i] * 100.0))
		if absf(SCALES[i] - s.render_scale) < absf(SCALES[sidx] - s.render_scale):
			sidx = i
	var sc := ChoiceRow.new("Škálování 3D vykreslování", scale_names, sidx)
	sc.changed.connect(func(i: int) -> void:
		s.render_scale = SCALES[i]
		_commit_graphics())
	_content.add_child(sc)
	var fps_names: Array[String] = []
	var fidx := 0
	for i in s.FPS_CAPS.size():
		fps_names.append("Bez omezení" if s.FPS_CAPS[i] == 0 else "%d FPS" % s.FPS_CAPS[i])
		if s.FPS_CAPS[i] == s.fps_cap:
			fidx = i
	var fp := ChoiceRow.new("Limit snímků", fps_names, fidx)
	fp.changed.connect(func(i: int) -> void:
		s.fps_cap = s.FPS_CAPS[i]
		_commit_graphics())
	_content.add_child(fp)
	_note.text = "Rozlišení platí v režimu „V okně“. MSAA a škálování se projeví ve 3D scéně hry."

func _commit_graphics() -> void:
	_st.apply_graphics()
	_st.save_settings()

func _build_audio() -> void:
	var rows: Array = [
		["Hlavní hlasitost", "vol_master"],
		["Efekty (souboje, kroky, rozhraní)", "vol_sfx"],
		["Atmosféra (vítr, ambient)", "vol_ambience"],
	]
	for r: Array in rows:
		var prop: String = r[1]
		var row := SliderRow.new(r[0], 0.0, 1.0, 0.01, float(_st.get(prop)))
		row.changed.connect(func(v: float) -> void:
			_st.set(prop, v)
			_st.apply_audio()
			_st.save_settings())
		_content.add_child(row)
	_note.text = "Hra zatím obsahuje jen syntetizované efekty a ambient; hudba bude doplněna později."

func _build_controls() -> void:
	var sens := SliderRow.new("Citlivost myši", 0.2, 3.0, 0.05, _st.mouse_sensitivity,
		func(v: float) -> String: return "%.2f×" % v)
	sens.changed.connect(func(v: float) -> void:
		_st.mouse_sensitivity = v
		_st.save_settings())
	_content.add_child(sens)
	var inv := ChoiceRow.new("Invertovat osu Y kamery", _opt(["Vypnuto", "Zapnuto"]), 1 if _st.invert_y else 0)
	inv.changed.connect(func(i: int) -> void:
		_st.invert_y = (i == 1)
		_st.save_settings())
	_content.add_child(inv)
	_header("KLÁVESNICE A MYŠ")
	for a: Array in BIND_ACTIONS:
		_content.add_child(_make_bind_row(a[0], a[1]))
	_note.text = "Klikněte na tlačítko a stiskněte novou klávesu nebo tlačítko myši (Esc = zrušit). Použitá klávesa se prohodí. Ovladač zůstává na výchozím mapování."

func _make_bind_row(action: String, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 46)
	var l := Label.new()
	l.text = label_text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 40)
	b.text = _st.binding_text(action)
	b.pressed.connect(begin_capture.bind(action))
	row.add_child(b)
	_bind_buttons[action] = b
	return row

func begin_capture(action: String) -> void:
	if capturing_action != "":
		_refresh_binds()
	capturing_action = action
	(_bind_buttons[action] as Button).text = "Stiskněte klávesu…"

func _refresh_binds() -> void:
	for a: String in _bind_buttons:
		(_bind_buttons[a] as Button).text = _st.binding_text(a)

## Applies a captured event (also used directly by tests). Returns the swapped action, if any.
func apply_capture(event: InputEvent) -> String:
	if capturing_action == "":
		return ""
	var swapped: String = _st.rebind_kbm(capturing_action, event)
	var changed_action := capturing_action
	capturing_action = ""
	_refresh_binds()
	if swapped != "":
		var nice := swapped
		for a: Array in BIND_ACTIONS:
			if a[0] == swapped:
				nice = a[1]
		_note.text = "Klávesa byla prohozena s akcí „%s“." % nice
	else:
		_note.text = ""
	(_bind_buttons[changed_action] as Button).grab_focus()
	return swapped

func _input(event: InputEvent) -> void:
	if capturing_action == "" or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).physical_keycode == KEY_ESCAPE:
			capturing_action = ""
			_refresh_binds()
		else:
			var k := InputEventKey.new()
			k.physical_keycode = (event as InputEventKey).physical_keycode
			apply_capture(k)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var m := InputEventMouseButton.new()
		m.button_index = (event as InputEventMouseButton).button_index
		apply_capture(m)
		get_viewport().set_input_as_handled()
