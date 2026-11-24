class_name MainMenu
extends Control
## Main menu: dark cinematic key art (right), menu column (left), animated mist/embers/leaves.
## Entries: continue, new game, load, settings, gallery, credits, quit (with confirmation).
## Game flow goes through the GameState autoload; options through the Settings autoload.

signal game_requested(slot: int, new_game: bool)
signal quit_requested

const GAME_SCENE := "res://scenes/main/main.tscn"
const ART_PATH := "res://assets/ui/menu/kayn_menu_art.jpg"
const ART_ASPECT := 1112.0 / 941.0
const PATH_NAMES := {0: "bez zvolené cesty", 1: "Stínový vrah", 2: "Rhaast"}

## Tests set this so no scene change / quit happens.
var dry_run: bool = false
var fade_time: float = 0.9

var items: Dictionary = {}
var panel: MenuPanel = null
var confirm_open: bool = false

var _gs: Node
var _t: float = 0.0
var _mouse_par: Vector2 = Vector2.ZERO
var _launching: bool = false
var _art_clip: Control
var _art: TextureRect
var _glows: Array[TextureRect] = []
var _fogs: Array[ColorRect] = []
var _overlay: ColorRect
var _particles: Array[CPUParticles2D] = []
var _column: Control
var _title_box: Control
var _desc: Label
var _toast: Label
var _toast_tween: Tween
var _fade: ColorRect
var _panel_host: Control
var _dim: ColorRect
var _frame: PanelContainer
var _confirm_host: Control
var _return_focus: Control
var _hints: Control

func _ready() -> void:
	_gs = get_node("/root/GameState")
	theme = MenuTheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_background()
	_build_fx()
	_build_column()
	_build_hints()
	_build_hosts()
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	resized.connect(_layout)
	_layout()
	refresh_state()
	Sfx.start_ambience()
	_intro()

# ------------------------------------------------------------------ building
func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.015, 0.025)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_art_clip = Control.new()
	_art_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_clip.clip_contents = true
	_art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_clip)
	_art = TextureRect.new()
	_art.texture = load(ART_PATH) as Texture2D
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/menu_art.gdshader")
	_art.material = m
	_art_clip.add_child(_art)
	# Pulsing purple glow around the Darkin arm (additive, positioned in art-relative coordinates).
	for g: Array in [[0.415, 0.50, 0.17, 0.30], [0.395, 0.66, 0.12, 0.22]]:
		var glow := TextureRect.new()
		glow.texture = MenuTheme.soft_dot(128)
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = mat
		glow.modulate = Color(0.55, 0.12, 1.0, 0.25)
		var cx: float = g[0]
		var cy: float = g[1]
		var rw: float = g[2]
		var rh: float = g[3]
		glow.anchor_left = cx - rw * 0.5
		glow.anchor_right = cx + rw * 0.5
		glow.anchor_top = cy - rh * 0.5
		glow.anchor_bottom = cy + rh * 0.5
		_art.add_child(glow)
		_glows.append(glow)

func _fog_rect(col: Color, density: float, scale_: float, spd: Vector2, bottom: float) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/menu_fog.gdshader")
	m.set_shader_parameter("fog_color", col)
	m.set_shader_parameter("density", density)
	m.set_shader_parameter("noise_scale", scale_)
	m.set_shader_parameter("speed", spd)
	m.set_shader_parameter("bottom_bias", bottom)
	r.material = m
	add_child(r)
	_fogs.append(r)
	return r

func _particle(amount: int, life: float, tex: Texture2D) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.texture = tex
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.local_coords = false
	add_child(p)
	_particles.append(p)
	return p

func _build_fx() -> void:
	_fog_rect(Color(0.50, 0.46, 0.58), 0.30, 2.2, Vector2(0.012, 0.003), 0.0)
	# Ash flakes drifting across the whole frame.
	var ash := _particle(70, 14.0, MenuTheme.soft_dot(12))
	ash.direction = Vector2(0.9, 0.3)
	ash.spread = 30.0
	ash.initial_velocity_min = 10.0
	ash.initial_velocity_max = 36.0
	ash.scale_amount_min = 0.5
	ash.scale_amount_max = 1.4
	ash.color = Color(0.8, 0.78, 0.8, 0.35)
	ash.name = "Ash"
	# Rising embers from the bottom.
	var embers := _particle(55, 9.0, MenuTheme.soft_dot(16))
	embers.direction = Vector2(0.25, -1.0)
	embers.spread = 20.0
	embers.initial_velocity_min = 24.0
	embers.initial_velocity_max = 72.0
	embers.tangential_accel_min = -10.0
	embers.tangential_accel_max = 10.0
	embers.scale_amount_min = 0.35
	embers.scale_amount_max = 0.9
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 0.55, 0.2, 0.0), Color(1.0, 0.35, 0.12, 0.95), Color(0.85, 0.1, 0.1, 0.6), Color(0.5, 0.05, 0.08, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.6, 1.0])
	embers.color_ramp = g
	var em := CanvasItemMaterial.new()
	em.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	embers.material = em
	embers.name = "Embers"
	# Falling red leaves.
	var leaves := _particle(14, 12.0, MenuTheme.leaf_texture())
	leaves.direction = Vector2(-0.55, 1.0)
	leaves.spread = 25.0
	leaves.initial_velocity_min = 30.0
	leaves.initial_velocity_max = 70.0
	leaves.angular_velocity_min = -120.0
	leaves.angular_velocity_max = 120.0
	leaves.tangential_accel_min = -14.0
	leaves.tangential_accel_max = 14.0
	leaves.scale_amount_min = 0.7
	leaves.scale_amount_max = 1.5
	leaves.color = Color(1, 1, 1, 0.85)
	leaves.name = "Leaves"
	_fog_rect(Color(0.42, 0.36, 0.5), 0.55, 3.2, Vector2(-0.02, 0.0), 1.0)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var om := ShaderMaterial.new()
	om.shader = load("res://assets/shaders/menu_overlay.gdshader")
	_overlay.material = om
	add_child(_overlay)

func _label(text_: String, font: Font, fs: int, col: Color = MenuTheme.BONE) -> Label:
	var l := Label.new()
	l.text = text_
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_column() -> void:
	_column = MarginContainer.new()
	_column.set_anchors_preset(Control.PRESET_FULL_RECT)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override("margin_left", 92)
	_column.add_theme_constant_override("margin_top", 56)
	_column.add_theme_constant_override("margin_bottom", 44)
	_column.add_theme_constant_override("margin_right", 700)
	add_child(_column)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(v)
	# Title
	var tb := VBoxContainer.new()
	tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tb.add_theme_constant_override("separation", 0)
	var t1 := _label("KAYN", MenuTheme.title_font(), 112)
	t1.add_theme_color_override("font_shadow_color", Color(0.5, 0.02, 0.05, 0.8))
	t1.add_theme_constant_override("shadow_offset_x", 3)
	t1.add_theme_constant_override("shadow_offset_y", 4)
	tb.add_child(t1)
	tb.add_child(_label("THE DARKIN SAGA", MenuTheme.spaced_font(9), 27, Color(0.85, 0.2, 0.2)))
	var line := TextureRect.new()
	line.texture = MenuTheme.red_line(420, 3)
	line.custom_minimum_size = Vector2(420, 3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lw := MarginContainer.new()
	lw.add_theme_constant_override("margin_top", 14)
	lw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lw.add_child(line)
	tb.add_child(lw)
	_title_box = tb
	v.add_child(tb)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	# Items
	var list := VBoxContainer.new()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_theme_constant_override("separation", 2)
	var defs: Array = [
		["continue", "Pokračovat", ""],
		["new", "Nová hra", ""],
		["load", "Načíst hru", "Vyberte jednu z uložených pozic."],
		["settings", "Nastavení", "Grafika, zvuk a ovládání."],
		["gallery", "Galerie", "Koncepty postavy Kayna."],
		["credits", "Autoři", "O projektu a použité zdroje."],
		["quit", "Ukončit hru", "Zavřít hru."],
	]
	for d: Array in defs:
		var it := MenuItem.new(d[1], d[2])
		it.name = d[0]
		it.pressed.connect(activate.bind(d[0]))
		it.focus_entered.connect(func() -> void: _desc.text = it.hint)
		list.add_child(it)
		items[d[0]] = it
	v.add_child(list)
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp2.custom_minimum_size = Vector2(0, 24)
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp2)
	# Footer
	var dline := TextureRect.new()
	dline.texture = MenuTheme.red_line(520, 2)
	dline.custom_minimum_size = Vector2(520, 2)
	dline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(dline)
	_desc = _label("", MenuTheme.body_font(), 25, Color(0.82, 0.78, 0.76))
	_desc.custom_minimum_size = Vector2(520, 58)
	_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_desc)
	v.add_child(_label("Neoficiální fanouškovský projekt · není spojen s Riot Games", MenuTheme.body_font(), 17, Color(0.5, 0.46, 0.46)))

func _key_cap(key: String, what: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap := PanelContainer.new()
	cap.add_theme_stylebox_override("panel", MenuTheme.box(Color(0.05, 0.03, 0.04, 0.8), Color(0.6, 0.55, 0.55, 0.8), 1, 6))
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(_label(key, MenuTheme.body_font(), 20))
	h.add_child(cap)
	h.add_child(_label(what, MenuTheme.body_font(), 22, Color(0.8, 0.76, 0.74)))
	return h

func _build_hints() -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 34)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_key_cap("Enter", "Vybrat"))
	hb.add_child(_key_cap("Esc", "Zpět"))
	hb.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hb.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hb.offset_right = -60
	hb.offset_bottom = -40
	add_child(hb)
	_hints = hb

func _build_hosts() -> void:
	_panel_host = Control.new()
	_panel_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_host.visible = false
	add_child(_panel_host)
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.0, 0.01, 0.62)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_host.add_child(_dim)
	_confirm_host = Control.new()
	_confirm_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_host.visible = false
	add_child(_confirm_host)
	_toast = _label("", MenuTheme.body_font(), 24, Color(1, 0.8, 0.78))
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_bottom = -90
	_toast.modulate.a = 0.0
	add_child(_toast)

# ------------------------------------------------------------------ layout & animation
func _layout() -> void:
	var vp := size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var h := vp.y * 1.06
	var w := h * ART_ASPECT
	var min_w := vp.x * 0.66
	if w < min_w:
		w = min_w
		h = w / ART_ASPECT
	_art.size = Vector2(w, h)
	_art.pivot_offset = Vector2(w * 0.7, h)
	_art_base = Vector2(vp.x - w + w * 0.015, vp.y - h + h * 0.01)
	_art.position = _art_base
	var asp := vp.x / vp.y
	for f in _fogs:
		(f.material as ShaderMaterial).set_shader_parameter("aspect", asp)
	# Particle emitters follow the viewport.
	for p in _particles:
		match p.name:
			"Ash":
				p.position = vp * 0.5
				p.emission_rect_extents = vp * 0.5
			"Embers":
				p.position = Vector2(vp.x * 0.5, vp.y + 12.0)
				p.emission_rect_extents = Vector2(vp.x * 0.5, 6.0)
			"Leaves":
				p.position = Vector2(vp.x * 0.62, -16.0)
				p.emission_rect_extents = Vector2(vp.x * 0.5, 6.0)
	_column.add_theme_constant_override("margin_right", int(maxf(vp.x - 700.0, 400.0)))

var _art_base: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	_t += delta
	var vp := size
	if vp.x > 0.0 and _art != null:
		var mp := get_local_mouse_position() / vp - Vector2(0.5, 0.5)
		_mouse_par = _mouse_par.lerp(mp.clampf(-0.5, 0.5), clampf(delta * 2.5, 0.0, 1.0))
		var s := 1.0 + 0.016 * (0.5 + 0.5 * sin(_t * 0.22))
		_art.scale = Vector2(s, s)
		_art.position = _art_base + _mouse_par * Vector2(-22.0, -12.0)
	for i in _glows.size():
		var a := 0.20 + 0.10 * sin(_t * (1.6 + i * 0.5) + i * 1.7) + 0.04 * sin(_t * 5.3 + i)
		_glows[i].modulate.a = clampf(a, 0.05, 0.5)

func _intro() -> void:
	_fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, fade_time * 1.4)
	_title_box.modulate.a = 0.0
	var tt := create_tween()
	tt.tween_property(_title_box, "modulate:a", 1.0, 1.4).set_delay(0.3)
	var i := 0
	for id: String in items:
		var it: MenuItem = items[id]
		it.modulate.a = 0.0
		var tn := create_tween().set_parallel(true)
		tn.tween_property(it, "modulate:a", 1.0, 0.5).set_delay(0.5 + i * 0.07)
		i += 1
	await get_tree().create_timer(0.5 + items.size() * 0.07 + 0.1).timeout
	if not is_instance_valid(self) or panel != null:
		return
	focus_first_item()

func focus_first_item() -> void:
	MenuItem.sound_enabled = false
	for id in ["continue", "new"]:
		var it: MenuItem = items[id]
		if not it.disabled:
			it.grab_focus()
			break
	MenuItem.sound_enabled = true

# ------------------------------------------------------------------ state
## Re-reads save slots and updates Continue / New game descriptions.
func refresh_state() -> void:
	var latest: int = _gs.latest_slot()
	var cont: MenuItem = items["continue"]
	cont.disabled = (latest == 0)
	cont.queue_redraw()
	if latest == 0:
		cont.hint = "Zatím není žádná uložená hra."
	else:
		var info: Dictionary = _gs.slot_info(latest)
		cont.hint = "Pokračujte v posledním uloženém postupu: pozice %d, %s." % [latest, PATH_NAMES.get(int(info["kayn_path"]), "")]
	var nw: MenuItem = items["new"]
	var empty: int = _gs.first_empty_slot()
	if empty != 0:
		nw.hint = "Začít novou hru (uloží se do pozice %d)." % empty
	else:
		nw.hint = "Začít novou hru (přepíše nejstarší uloženou pozici)."
	var load_it: MenuItem = items["load"]
	load_it.disabled = (latest == 0)
	load_it.queue_redraw()
	load_it.hint = "Vyberte jednu z uložených pozic." if latest != 0 else "Zatím není žádná uložená hra."
	var f := get_viewport().gui_get_focus_owner()
	if f is MenuItem:
		_desc.text = (f as MenuItem).hint

func toast(msg: String) -> void:
	_toast.text = msg
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)

# ------------------------------------------------------------------ actions
func activate(id: String) -> void:
	if _launching or confirm_open or panel != null:
		return
	var it: MenuItem = items.get(id)
	if it == null or it.disabled:
		return
	_return_focus = it
	match id:
		"continue":
			_start_game(_gs.latest_slot(), false)
		"new":
			_new_game()
		"load":
			var lp := LoadPanel.new()
			lp.slot_chosen.connect(func(s: int) -> void: _start_game(s, false))
			open_panel(lp)
		"settings":
			open_panel(SettingsPanel.new())
		"gallery":
			open_panel(GalleryPanel.new())
		"credits":
			open_panel(CreditsPanel.new())
		"quit":
			ask_quit()

func _new_game() -> void:
	var empty: int = _gs.first_empty_slot()
	if empty != 0:
		_start_game(empty, true)
		return
	var oldest := 1
	var oldest_t := 1 << 60
	for i in range(1, int(_gs.SLOT_COUNT) + 1):
		var inf: Dictionary = _gs.slot_info(i)
		if int(inf["saved_unix"]) < oldest_t:
			oldest_t = int(inf["saved_unix"])
			oldest = i
	ask("Všechny pozice jsou obsazené.\nNová hra přepíše nejstarší uložení (pozice %d). Pokračovat?" % oldest,
		"Přepsat a začít", "Zrušit", func() -> void: _start_game(oldest, true))

func _start_game(slot: int, new_game: bool) -> void:
	if _launching or slot < 1:
		return
	_gs.set_slot(slot)
	if new_game:
		_gs.reset_campaign()
		if not _gs.save_game():
			toast("Hru se nepodařilo uložit – zkontrolujte místo na disku.")
			return
	elif not _gs.load_game():
		toast("Uloženou hru se nepodařilo načíst.")
		refresh_state()
		return
	_launching = true
	game_requested.emit(slot, new_game)
	if dry_run:
		return
	Sfx.play("ui_click", null, -4.0)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, fade_time)
	await tw.finished
	get_tree().change_scene_to_file(GAME_SCENE)

func ask_quit() -> void:
	ask("Opravdu chcete ukončit hru?", "Ukončit", "Zůstat", _do_quit, 1)

func _do_quit() -> void:
	quit_requested.emit()
	if dry_run:
		return
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().quit()

## Modal yes/no dialog. default_no_focus: index of the button focused first (0 = yes, 1 = no).
func ask(message: String, yes_text: String, no_text: String, on_yes: Callable, default_focus: int = 1) -> void:
	if confirm_open:
		return
	confirm_open = true
	for c in _confirm_host.get_children():
		c.queue_free()
	_confirm_host.visible = true
	_set_items_enabled(false)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_host.add_child(dim)
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	v.custom_minimum_size = Vector2(560, 0)
	var l := Label.new()
	l.text = message
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 28)
	v.add_child(l)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	var yes := Button.new()
	yes.text = yes_text
	yes.name = "Yes"
	yes.custom_minimum_size = Vector2(210, 48)
	var no := Button.new()
	no.text = no_text
	no.name = "No"
	no.custom_minimum_size = Vector2(210, 48)
	hb.add_child(yes)
	hb.add_child(no)
	v.add_child(hb)
	box.add_child(v)
	_confirm_host.add_child(box)
	yes.pressed.connect(func() -> void:
		Sfx.play("ui_click", null, -6.0)
		_close_confirm()
		on_yes.call())
	no.pressed.connect(_close_confirm)
	box.modulate.a = 0.0
	create_tween().tween_property(box, "modulate:a", 1.0, 0.18)
	(no if default_focus == 1 else yes).grab_focus()

func _close_confirm() -> void:
	if not confirm_open:
		return
	confirm_open = false
	_confirm_host.visible = false
	for c in _confirm_host.get_children():
		c.queue_free()
	if panel == null:
		_set_items_enabled(true)
		if is_instance_valid(_return_focus) and not (_return_focus as BaseButton).disabled:
			MenuItem.sound_enabled = false
			_return_focus.grab_focus()
			MenuItem.sound_enabled = true

func _set_items_enabled(on: bool) -> void:
	for id: String in items:
		var it: MenuItem = items[id]
		it.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
		it.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE

# ------------------------------------------------------------------ panels
func open_panel(p: MenuPanel) -> void:
	if panel != null:
		return
	panel = p
	_set_items_enabled(false)
	_frame = PanelContainer.new()
	_frame.anchor_left = 0.0
	_frame.anchor_right = 0.0
	_frame.anchor_top = 0.5
	_frame.anchor_bottom = 0.5
	_frame.offset_left = 80
	_frame.offset_right = 80 + p.panel_width
	_frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	var title := _label(p.panel_title.to_upper(), MenuTheme.title_font(), 38)
	v.add_child(title)
	var line := TextureRect.new()
	line.texture = MenuTheme.red_line(int(p.panel_width * 0.6), 2)
	line.custom_minimum_size = Vector2(0, 2)
	line.stretch_mode = TextureRect.STRETCH_SCALE
	line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.add_child(line)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(p)
	var back := Button.new()
	back.text = "Zpět"
	back.name = "Back"
	back.custom_minimum_size = Vector2(180, 46)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(close_panel)
	v.add_child(back)
	_frame.add_child(v)
	_panel_host.add_child(_frame)
	p.close_requested.connect(close_panel)
	_panel_host.visible = true
	_dim.modulate.a = 0.0
	_frame.modulate.a = 0.0
	_frame.position.x -= 30
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 1.0, 0.3)
	tw.tween_property(_frame, "modulate:a", 1.0, 0.3)
	tw.tween_property(_frame, "position:x", _frame.position.x + 30, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_column, "modulate:a", 0.0, 0.25)
	tw.tween_property(_hints, "modulate:a", 0.0, 0.25)
	p.focus_first.call_deferred()

func close_panel() -> void:
	if panel == null:
		return
	var old_frame := _frame
	panel = null
	_frame = null
	Sfx.play("ui_move", null, -6.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(old_frame, "modulate:a", 0.0, 0.2)
	tw.tween_property(_dim, "modulate:a", 0.0, 0.25)
	tw.tween_property(_column, "modulate:a", 1.0, 0.3)
	tw.tween_property(_hints, "modulate:a", 1.0, 0.3)
	tw.chain().tween_callback(func() -> void:
		old_frame.queue_free()
		if panel == null:
			_panel_host.visible = false)
	_set_items_enabled(true)
	refresh_state()
	if is_instance_valid(_return_focus) and not (_return_focus as BaseButton).disabled:
		MenuItem.sound_enabled = false
		_return_focus.grab_focus()
		MenuItem.sound_enabled = true
	else:
		focus_first_item()

func _unhandled_input(event: InputEvent) -> void:
	if _launching:
		return
	if event.is_action_pressed("ui_cancel"):
		if confirm_open:
			_close_confirm()
		elif panel != null:
			close_panel()
		else:
			ask_quit()
		get_viewport().set_input_as_handled()
