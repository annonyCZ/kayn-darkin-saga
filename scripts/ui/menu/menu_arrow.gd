class_name MenuArrow
extends Button
## Small triangular arrow button (drawn, so it needs no glyph from the font).

var dir: int = 1 ## -1 = left, +1 = right

func _init(direction: int = 1) -> void:
	dir = direction
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(36, 36)
	for sb in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(sb, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _draw() -> void:
	var c := size * 0.5
	var s := 8.0
	var pts := PackedVector2Array([c + Vector2(-s * dir, -s), c + Vector2(s * dir, 0), c + Vector2(-s * dir, s)])
	var col := MenuTheme.RED_HI if is_hovered() else MenuTheme.BONE
	draw_colored_polygon(pts, col)
