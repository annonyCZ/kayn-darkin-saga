class_name MenuTheme
extends RefCounted
## Fonts, colours and the shared Theme of the main menu (dark, cinematic, red accent).
## Fonts: Cinzel (titles) and Cormorant Garamond (text), both SIL OFL 1.1 - see docs/ASSET_REGISTER.md.

const TITLE_FONT_PATH := "res://assets/ui/fonts/Cinzel.ttf"
const BODY_FONT_PATH := "res://assets/ui/fonts/CormorantGaramond.ttf"

const RED := Color(0.70, 0.07, 0.11)
const RED_HI := Color(0.95, 0.24, 0.22)
const BONE := Color(0.90, 0.86, 0.82)
const DIM := Color(0.62, 0.57, 0.57)
const PANEL_BG := Color(0.03, 0.02, 0.035, 0.92)

static var _title: Font
static var _body: Font
static var _theme: Theme

static func _variation(path: String, weight: int, spacing: int = 0) -> Font:
	var base := load(path) as Font
	if base == null:
		return ThemeDB.fallback_font
	var f := FontVariation.new()
	f.base_font = base
	var ts := TextServerManager.get_primary_interface()
	if ts != null:
		f.variation_opentype = {ts.name_to_tag("wght"): weight}
	f.spacing_glyph = spacing
	return f

static func title_font() -> Font:
	if _title == null:
		_title = _variation(TITLE_FONT_PATH, 600)
	return _title

static func body_font() -> Font:
	if _body == null:
		_body = _variation(BODY_FONT_PATH, 600)
	return _body

## Cinzel with wide letter spacing, used for the subtitle.
static func spaced_font(spacing: int) -> Font:
	return _variation(TITLE_FONT_PATH, 500, spacing)

static func box(bg: Color, border: Color = Color(0, 0, 0, 0), border_w: int = 0, pad: float = 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	return s

## Soft horizontal red -> transparent line texture.
static func red_line(width: int = 400, height: int = 3) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([RED_HI, Color(RED.r, RED.g, RED.b, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = width
	t.height = height
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 0)
	return t

static func _diamond(size: int, col: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) * 0.5
	for y in size:
		for x in size:
			var d := absf(x - c) + absf(y - c)
			if d <= c:
				img.set_pixel(x, y, col)
			elif d <= c + 1.0:
				img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a * (1.0 - (d - c))))
	return ImageTexture.create_from_image(img)

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 24
	# Labels
	t.set_color("font_color", "Label", BONE)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.7))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 2)
	# Buttons (generic: back, yes/no, key capture, tabs)
	t.set_font("font", "Button", title_font())
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Button", BONE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(DIM, 0.5))
	t.set_stylebox("normal", "Button", box(Color(0.08, 0.05, 0.07, 0.92), Color(0.32, 0.09, 0.11), 1, 12))
	t.set_stylebox("hover", "Button", box(Color(0.14, 0.05, 0.07, 0.95), RED, 1, 12))
	t.set_stylebox("pressed", "Button", box(Color(0.35, 0.05, 0.08, 0.98), RED_HI, 1, 12))
	t.set_stylebox("hover_pressed", "Button", box(Color(0.35, 0.05, 0.08, 0.98), RED_HI, 1, 12))
	t.set_stylebox("focus", "Button", box(Color(0.16, 0.05, 0.07, 0.95), RED_HI, 2, 12))
	t.set_stylebox("disabled", "Button", box(Color(0.05, 0.04, 0.05, 0.8), Color(0.2, 0.15, 0.16), 1, 12))
	# Sliders
	var track := box(Color(0.14, 0.1, 0.12), Color(0.3, 0.1, 0.12), 1, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(RED, Color(0, 0, 0, 0), 0, 0)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", box(RED_HI, Color(0, 0, 0, 0), 0, 0))
	t.set_icon("grabber", "HSlider", _diamond(22, BONE))
	t.set_icon("grabber_highlight", "HSlider", _diamond(22, Color.WHITE))
	t.set_icon("grabber_disabled", "HSlider", _diamond(22, DIM))
	t.set_stylebox("focus", "HSlider", StyleBoxEmpty.new())
	# Scrollbars
	t.set_stylebox("scroll", "VScrollBar", box(Color(0.08, 0.06, 0.07, 0.8), Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber", "VScrollBar", box(Color(0.45, 0.08, 0.1), Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(RED_HI, Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(RED_HI, Color(0, 0, 0, 0), 0, 3))
	# Panels
	t.set_stylebox("panel", "PanelContainer", box(PANEL_BG, Color(0.35, 0.08, 0.1, 0.9), 1, 24))
	_theme = t
	return t

## Procedural small red maple-like leaf for the falling-leaf particles.
static func leaf_texture() -> ImageTexture:
	var w := 22
	var h := 12
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u := (x + 0.5) / w * 2.0 - 1.0
			var v := (y + 0.5) / h * 2.0 - 1.0
			var width_here := (1.0 - u * u) * (0.9 + 0.1 * sin(u * 5.0))
			if absf(v) < width_here * 0.95:
				var shade := 0.75 + 0.25 * (1.0 - absf(v))
				img.set_pixel(x, y, Color(0.75 * shade, 0.06 * shade, 0.08 * shade, 1.0))
	return ImageTexture.create_from_image(img)

static func soft_dot(size: int = 24) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
