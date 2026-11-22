class_name PathChoice
extends CanvasLayer
## Permanent Kayn path selection. Shows each path's pros and cons, then asks for confirmation.

signal finished(path: int)

var _pick: int = KaynPaths.Path.HUMAN
var _cards: Control
var _confirm: Control
var _confirm_label: Label

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_cards = VBoxContainer.new()
	_cards.set_anchors_preset(Control.PRESET_CENTER)
	_cards.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_cards.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_cards)
	var title := Label.new()
	title.text = "Kayn's Choice - this decision is permanent for this save"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	_cards.add_child(row)
	for p: int in [KaynPaths.Path.SHADOW_ASSASSIN, KaynPaths.Path.RHAAST]:
		row.add_child(_card(p))

	_confirm = PanelContainer.new()
	_confirm.set_anchors_preset(Control.PRESET_CENTER)
	_confirm.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_confirm.grow_vertical = Control.GROW_DIRECTION_BOTH
	_confirm.visible = false
	var cv := VBoxContainer.new()
	_confirm.add_child(cv)
	_confirm_label = Label.new()
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(_confirm_label)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_child(hb)
	var yes := Button.new(); yes.name = "ConfirmButton"; yes.text = "Confirm (cannot be undone)"
	yes.pressed.connect(confirm)
	var no := Button.new(); no.name = "BackButton"; no.text = "Go back"
	no.pressed.connect(cancel)
	hb.add_child(yes)
	hb.add_child(no)
	add_child(_confirm)

	get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _card(p: int) -> Control:
	var prof := KaynPaths.profile(p)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var n := Label.new()
	n.text = prof["name"]
	n.add_theme_font_size_override("font_size", 30)
	n.add_theme_color_override("font_color", (prof["body_color"] as Color).lightened(0.45))
	v.add_child(n)
	var t := Label.new(); t.text = prof["tagline"]; t.autowrap_mode = TextServer.AUTOWRAP_WORD; v.add_child(t)
	var pr := Label.new()
	pr.text = "\n".join((prof["pros"] as Array).map(func(x: String) -> String: return "+ " + x))
	pr.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	v.add_child(pr)
	var co := Label.new()
	co.text = "\n".join((prof["cons"] as Array).map(func(x: String) -> String: return "- " + x))
	co.add_theme_color_override("font_color", Color(0.95, 0.5, 0.45))
	v.add_child(co)
	var q := Label.new(); q.text = prof["line"]; q.autowrap_mode = TextServer.AUTOWRAP_WORD
	q.modulate = Color(1, 1, 1, 0.7)
	v.add_child(q)
	var b := Button.new()
	b.name = "Choose%d" % p
	b.text = "Become " + String(prof["name"])
	b.pressed.connect(select.bind(p))
	v.add_child(b)
	return panel

## Step 1: pick a path (shows the confirmation prompt).
func select(p: int) -> void:
	_pick = p
	_confirm_label.text = "Become %s?\nYou cannot switch to the other path in this campaign." % KaynPaths.profile(p)["name"]
	_cards.visible = false
	_confirm.visible = true

func cancel() -> void:
	_pick = KaynPaths.Path.HUMAN
	_confirm.visible = false
	_cards.visible = true

## Step 2: confirm. Applies the choice through GameState and closes the screen.
func confirm() -> void:
	if _pick == KaynPaths.Path.HUMAN:
		return
	var gs := get_node("/root/GameState")
	var ok: bool = gs.choose_path(_pick)
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	finished.emit(_pick if ok else gs.kayn_path)
	queue_free()
