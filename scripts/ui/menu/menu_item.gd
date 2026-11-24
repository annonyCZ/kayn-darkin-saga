class_name MenuItem
extends Button
## Main-menu entry: diamond marker, Cinzel text and an animated, jagged red "brush" bar behind the
## focused/hovered item. Hover and keyboard/gamepad focus share one state (focus).

static var sound_enabled: bool = true

var label_text: String = ""
var hint: String = ""
var _glow: float = 0.0
var _tween: Tween

func _init(text_: String = "", hint_: String = "") -> void:
	label_text = text_
	hint = hint_
	flat = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(440, 54)
	for sb in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(sb, StyleBoxEmpty.new())

func _ready() -> void:
	mouse_entered.connect(func() -> void:
		if not disabled and focus_mode != Control.FOCUS_NONE:
			grab_focus())
	focus_entered.connect(func() -> void:
		_animate(1.0)
		if sound_enabled:
			Sfx.play("ui_move", null, -8.0))
	focus_exited.connect(func() -> void: _animate(0.0))
	pressed.connect(func() -> void:
		if sound_enabled:
			Sfx.play("ui_click", null, -6.0))

func _animate(target: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(v: float) -> void:
		_glow = v
		queue_redraw(), _glow, target, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_ENABLED:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if _glow > 0.01 and not disabled:
		var len_ := lerpf(0.30, 1.0, _glow) * w
		var pts := PackedVector2Array([
			Vector2(0, 3), Vector2(len_ * 0.55, 1), Vector2(len_ * 0.93, 0), Vector2(len_ * 0.99, h * 0.28),
			Vector2(len_ * 0.90, h * 0.5), Vector2(len_, h * 0.74), Vector2(len_ * 0.94, h),
			Vector2(len_ * 0.5, h - 2), Vector2(0, h - 3)])
		var cols := PackedColorArray()
		for p in pts:
			var a := (1.0 - p.x / maxf(len_, 1.0)) * 0.85 * _glow
			cols.append(Color(0.62, 0.05, 0.09, clampf(a + 0.05 * _glow, 0.0, 1.0)))
		draw_polygon(pts, cols)
		draw_line(Vector2(0, 4), Vector2(0, h - 4), MenuTheme.RED_HI, 3.0)
	var base := MenuTheme.DIM if not disabled else Color(MenuTheme.DIM, 0.35)
	var col := base.lerp(Color.WHITE, _glow) if not disabled else base
	# diamond marker
	var c := Vector2(34.0 + _glow * 6.0, h * 0.5)
	var r := 7.0
	var d := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0), c + Vector2(0, -r)])
	draw_polyline(d, col, 1.6, true)
	if _glow > 0.05 and not disabled:
		draw_circle(c, 2.6 * _glow, MenuTheme.RED_HI)
	var f := MenuTheme.title_font()
	var fs := 26
	var tx := 70.0 + _glow * 10.0
	var ty := h * 0.5 + fs * 0.36
	draw_string(f, Vector2(tx + 1, ty + 2), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
	draw_string(f, Vector2(tx, ty), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
