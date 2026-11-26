class_name HudBar
extends Control
## Slim ornate HUD bar: dark glass, gradient fill, a pale "damage trail" that drains behind the
## fill (Souls/Wukong style), thin gold frame with corner diamonds. API compatible with ProgressBar.value.

var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
var fill_color: Color = Color(0.72, 0.1, 0.12)
var trail_color: Color = Color(0.95, 0.85, 0.7, 0.85)
var frame_color: Color = Color(0.78, 0.62, 0.3, 0.9)
var ticks: int = 0
var _shown: float = 1.0
var _trail: float = 1.0

func _init(color: Color = Color(0.72, 0.1, 0.12), height: float = 18.0, width: float = 0.0) -> void:
	fill_color = color
	custom_minimum_size = Vector2(width, height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	var prev_shown := _shown
	_shown = move_toward(_shown, value, delta * 3.5)
	if value >= _trail:
		_trail = value
	else:
		_trail = move_toward(_trail, value, delta * 0.22) if _trail > _shown else _shown
	if absf(prev_shown - _shown) > 0.0001 or _trail != _shown:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var inner := Rect2(2, 2, w - 4, h - 4)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.02, 0.82))
	if _trail > _shown:
		draw_rect(Rect2(inner.position, Vector2(inner.size.x * _trail, inner.size.y)), trail_color)
	var fw := inner.size.x * _shown
	if fw > 0.5:
		var top := fill_color.lightened(0.25)
		var bot := fill_color.darkened(0.35)
		var pts := PackedVector2Array([inner.position, inner.position + Vector2(fw, 0), inner.position + Vector2(fw, inner.size.y), inner.position + Vector2(0, inner.size.y)])
		draw_polygon(pts, PackedColorArray([top, top, bot, bot]))
		draw_rect(Rect2(inner.position, Vector2(fw, 1.0)), Color(1, 1, 1, 0.18))
	for i in range(1, ticks):
		var x := inner.position.x + inner.size.x * i / ticks
		draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color(0, 0, 0, 0.55), 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), frame_color, false, 1.5)
	var r := 3.5
	for c in [Vector2(0, h * 0.5), Vector2(w, h * 0.5)]:
		draw_colored_polygon(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r)]), frame_color)
