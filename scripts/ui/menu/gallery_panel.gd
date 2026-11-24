class_name GalleryPanel
extends MenuPanel
## Concept-art gallery: the artwork that exists in assets/ui (supplied by the project author).

const ITEMS: Array = [
	{"path": "res://assets/ui/gallery/kayn_koncept_cely.jpg", "title": "Kayn – celá postava",
		"text": "Koncept hlavní postavy: bílé vlasy, maska, černo-červený kabát a fialová démonická paže."},
	{"path": "res://assets/ui/gallery/kayn_koncept_telo.jpg", "title": "Kayn – tělo a démonická paže",
		"text": "Postava bez kabátu – podklad pro modelování a rigování."},
	{"path": "res://assets/ui/gallery/kayn_koncept_kabat.jpg", "title": "Kayn – kabát",
		"text": "Samostatný koncept kabátu s ostnatými rameny a červenou podšívkou."},
	{"path": "res://assets/ui/menu/kayn_menu_art.jpg", "title": "Ruiny pod měsícem",
		"text": "Ilustrace použitá na pozadí hlavního menu."},
]

var index: int = 0
var _tex: TextureRect
var _title: Label
var _text: Label
var _counter: Label
var _thumbs: Array[Button] = []
var _tween: Tween
var _prev: Button
var _next: Button

func _init() -> void:
	panel_title = "Galerie"
	panel_width = 980.0

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_tex = TextureRect.new()
	_tex.custom_minimum_size = Vector2(0, 440)
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_tex)
	_title = Label.new()
	_title.add_theme_font_override("font", MenuTheme.title_font())
	_title.add_theme_font_size_override("font_size", 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.custom_minimum_size = Vector2(panel_width - 60.0, 56)
	_text.add_theme_color_override("font_color", MenuTheme.DIM)
	add_child(_text)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 14)
	_prev = Button.new()
	_prev.text = "Předchozí"
	_prev.custom_minimum_size = Vector2(150, 44)
	_prev.pressed.connect(show_index.bind(-1, true))
	nav.add_child(_prev)
	for i in ITEMS.size():
		var tb := Button.new()
		tb.custom_minimum_size = Vector2(88, 56)
		tb.icon = load(ITEMS[i]["path"]) as Texture2D
		tb.expand_icon = true
		tb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tb.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		tb.pressed.connect(show_index.bind(i, false))
		nav.add_child(tb)
		_thumbs.append(tb)
	_next = Button.new()
	_next.text = "Další"
	_next.custom_minimum_size = Vector2(150, 44)
	_next.pressed.connect(show_index.bind(1, true))
	nav.add_child(_next)
	add_child(nav)
	_counter = Label.new()
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter.add_theme_color_override("font_color", MenuTheme.DIM)
	add_child(_counter)
	_apply(0, false)

func focus_first() -> void:
	if _next != null:
		_next.grab_focus()

## relative = true: move by `value` (wraps); false: jump to absolute index.
func show_index(value: int, relative: bool) -> void:
	var target := posmod(index + value, ITEMS.size()) if relative else clampi(value, 0, ITEMS.size() - 1)
	if target == index and _tex.texture != null:
		return
	Sfx.play("ui_move", null, -6.0)
	_apply(target, true)

func _apply(i: int, animate: bool) -> void:
	index = i
	if _tween:
		_tween.kill()
	var set_content := func() -> void:
		_tex.texture = load(ITEMS[index]["path"]) as Texture2D
		_title.text = ITEMS[index]["title"]
		_text.text = ITEMS[index]["text"]
		_counter.text = "%d / %d" % [index + 1, ITEMS.size()]
		for k in _thumbs.size():
			_thumbs[k].modulate = Color.WHITE if k == index else Color(1, 1, 1, 0.45)
	if not animate:
		set_content.call()
		return
	_tween = create_tween()
	_tween.tween_property(_tex, "modulate:a", 0.0, 0.12)
	_tween.tween_callback(set_content)
	_tween.tween_property(_tex, "modulate:a", 1.0, 0.25)

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_left"):
		show_index(-1, true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		show_index(1, true)
		get_viewport().set_input_as_handled()
