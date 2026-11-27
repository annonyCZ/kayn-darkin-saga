class_name AbilitySlot
extends Control
## Hotbar slot: dark frame, drawn icon, key cap and a clockwise cooldown wipe that flashes when ready.

var key_text: String = "Q"
var icon_kind: String = "dash"
var count: int = -1   # charges drawn in the corner when >= 0
var cooldown: float = 0.0   ## remaining fraction 0..1 (0 = ready)
var _flash: float = 0.0
var _was_cooling: bool = false

func _init(key_: String = "Q", icon_: String = "dash") -> void:
	key_text = key_
	icon_kind = icon_
	custom_minimum_size = Vector2(76, 76)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_cooldown(f: float) -> void:
	f = clampf(f, 0.0, 1.0)
	if _was_cooling and f <= 0.0:
		_flash = 1.0
	_was_cooling = f > 0.0
	if f != cooldown or _flash > 0.0:
		cooldown = f
		queue_redraw()

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.5)
		queue_redraw()

func _draw() -> void:
	var s := size
	var c := s * 0.5
	var gold := Color(0.78, 0.62, 0.3, 0.95)
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.03, 0.02, 0.03, 0.88))
	var ready_col := Color(0.82, 0.88, 1.0) if cooldown <= 0.0 else Color(0.45, 0.48, 0.55)
	match icon_kind:
		"dash":
			for i in 3:
				var o := (i - 1) * 9.0
				draw_line(Vector2(c.x - 20 + o, c.y + 18), Vector2(c.x + 14 + o, c.y - 20), ready_col, 3.0 - absf(i - 1) * 0.8, true)
			draw_circle(Vector2(c.x + 18, c.y - 18), 3.0, Color(0.7, 0.3, 1.0) if cooldown <= 0.0 else Color(0.35, 0.25, 0.45))
		"slam":
			draw_line(Vector2(c.x, c.y - 22), Vector2(c.x, c.y + 4), ready_col, 4.0, true)
			draw_colored_polygon(PackedVector2Array([Vector2(c.x - 10, c.y), Vector2(c.x + 10, c.y), Vector2(c.x, c.y + 14)]), ready_col)
			draw_arc(Vector2(c.x, c.y + 14), 18.0, PI * 1.1, PI * 1.9, 16, ready_col, 2.5, true)
			draw_arc(Vector2(c.x, c.y + 14), 26.0, PI * 1.15, PI * 1.85, 16, Color(ready_col, 0.55), 2.0, true)
		"gourd":
			var gc := Color(0.78, 0.62, 0.32) if count != 0 else Color(0.4, 0.36, 0.3)
			draw_circle(Vector2(c.x, c.y + 6), 13.0, gc)
			draw_circle(Vector2(c.x, c.y - 9), 8.0, gc)
			draw_rect(Rect2(c.x - 3, c.y - 21, 6, 6), Color(0.3, 0.16, 0.1))
			draw_line(Vector2(c.x - 8, c.y + 2), Vector2(c.x + 8, c.y + 2), Color(0.5, 0.08, 0.1), 3.0)
	if cooldown > 0.0:
		var pts := PackedVector2Array([c])
		var a0 := -PI * 0.5
		var a1 := a0 + TAU * cooldown
		var steps := maxi(2, int(40.0 * cooldown))
		var rad := s.length()
		for i in steps + 1:
			var a := lerpf(a0, a1, float(i) / steps)
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		# clip the pie to the slot by intersecting with the rect via polygon clipping
		for poly in Geometry2D.intersect_polygons(pts, PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)])):
			draw_colored_polygon(poly, Color(0, 0, 0, 0.66))
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 0.95, 0.8, 0.45 * _flash))
	draw_rect(Rect2(Vector2.ZERO, s), gold, false, 2.0)
	draw_rect(Rect2(Vector2(5, 5), s - Vector2(10, 10)), Color(gold, 0.25), false, 1.0)
	if count >= 0:
		draw_string(MenuTheme.title_font(), Vector2(s.x - 20, 22), str(count), HORIZONTAL_ALIGNMENT_RIGHT, 16, 18, Color(0.95, 0.85, 0.55))
	# key cap
	var f := MenuTheme.title_font()
	var cap := Rect2(Vector2(s.x * 0.5 - 13, s.y - 11), Vector2(26, 22))
	draw_rect(cap, Color(0.05, 0.03, 0.04, 0.95))
	draw_rect(cap, gold, false, 1.5)
	draw_string(f, cap.position + Vector2(0, 16), key_text, HORIZONTAL_ALIGNMENT_CENTER, cap.size.x, 16, Color(0.92, 0.88, 0.82))
