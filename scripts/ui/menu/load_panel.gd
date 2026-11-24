class_name LoadPanel
extends MenuPanel
## Lists the save slots. Occupied slots can be loaded; empty ones are shown disabled.

signal slot_chosen(slot: int)

const PATH_NAMES := {0: "Cesta dosud nezvolena", 1: "Stínový vrah", 2: "Rhaast"}

var cards: Array[Button] = []

func _init() -> void:
	panel_title = "Načíst hru"
	panel_width = 760.0

static func describe(info: Dictionary) -> String:
	if not info["exists"]:
		return "Prázdná pozice"
	var path_i: int = int(info["kayn_path"])
	var s: String = PATH_NAMES.get(path_i, "Cesta dosud nezvolena")
	if path_i != 0 and info["path_locked"]:
		s = "Cesta: " + s
	return s

static func format_time(unix: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(unix + bias)
	return "%d. %d. %d  %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]

func _ready() -> void:
	var gs := get_node("/root/GameState")
	add_theme_constant_override("separation", 12)
	for i in range(1, int(gs.SLOT_COUNT) + 1):
		var info: Dictionary = gs.slot_info(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 92)
		b.disabled = not info["exists"]
		b.focus_mode = Control.FOCUS_ALL
		var m := MarginContainer.new()
		m.set_anchors_preset(Control.PRESET_FULL_RECT)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in ["left", "right", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 14)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var t := Label.new()
		t.text = "POZICE %d" % i
		t.add_theme_font_override("font", MenuTheme.title_font())
		t.add_theme_font_size_override("font_size", 24)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		var d := Label.new()
		d.text = describe(info)
		if info["exists"]:
			d.text += "   ·   " + format_time(int(info["saved_unix"]))
		d.add_theme_color_override("font_color", MenuTheme.BONE if info["exists"] else MenuTheme.DIM)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(d)
		m.add_child(v)
		b.add_child(m)
		b.pressed.connect(func() -> void:
			Sfx.play("ui_click", null, -6.0)
			slot_chosen.emit(i))
		b.mouse_entered.connect(func() -> void:
			if not b.disabled:
				b.grab_focus())
		add_child(b)
		cards.append(b)
	var any := cards.any(func(c: Button) -> bool: return not c.disabled)
	if not any:
		var l := Label.new()
		l.text = "Zatím nejsou žádné uložené hry. Uložení vzniká automaticky při spuštění nové hry a po volbě cesty."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(panel_width - 60.0, 0)
		l.add_theme_color_override("font_color", MenuTheme.DIM)
		add_child(l)

func focus_first() -> void:
	for c in cards:
		if not c.disabled:
			c.grab_focus()
			return
