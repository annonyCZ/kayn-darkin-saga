class_name CreditsPanel
extends MenuPanel
## About / credits. Only facts that are true for this repository (see NOTICE.md, docs/ASSET_REGISTER.md).

const TEXT := """[center][font_size=30][color=#e8d9c9]KAYN: THE DARKIN SAGA[/color][/font_size]
Fanouškovská akční RPG hra · open source (MIT)[/center]

[color=#f23c38]AUTOR PROJEKTU[/color]
annonyCZ  —  github.com/annonyCZ/kayn-darkin-saga
Koncepty postavy a ilustrace hlavního menu dodal autor projektu.

[color=#f23c38]VÝVOJ[/color]
Programování a nástroje: vyvíjeno s pomocí Claude (Anthropic).
Herní engine: Godot Engine 4.5 (MIT) s fyzikou Jolt.
Zvukové efekty a ambient: syntetizované přímo ve hře.

[color=#f23c38]POUŽITÉ ZDROJE[/color]
Písma Cinzel a Cormorant Garamond — SIL Open Font License 1.1.
Skály a textury terénu — Terrain3D demo / ambientCG, licence CC0.

[color=#f23c38]UPOZORNĚNÍ[/color]
Neoficiální, nekomerční fanouškovský projekt. Není spojen s Riot Games, Inc. ani jimi schválen. „League of Legends“, „Kayn“, „Rhaast“ a „Aatrox“ jsou obchodní značky a duševní vlastnictví Riot Games. Hra neobsahuje žádné assety Riot Games.
"""

func _init() -> void:
	panel_title = "Autoři"
	panel_width = 860.0

func _ready() -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 470)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.focus_mode = Control.FOCUS_ALL
	sc.follow_focus = true
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", 24)
	r.add_theme_font_override("bold_font", MenuTheme.title_font())
	r.add_theme_color_override("default_color", MenuTheme.BONE)
	r.text = TEXT
	sc.add_child(r)
	add_child(sc)
	_scroll = sc
	sc.gui_input.connect(func(e: InputEvent) -> void:
		if e.is_action_pressed("ui_down"):
			sc.scroll_vertical += 70
			sc.accept_event()
		elif e.is_action_pressed("ui_up"):
			sc.scroll_vertical -= 70
			sc.accept_event())

var _scroll: ScrollContainer

func focus_first() -> void:
	if _scroll != null:
		_scroll.grab_focus()
