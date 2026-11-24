class_name MenuPanel
extends VBoxContainer
## Base of the content shown inside the main-menu frame (settings, load, gallery, credits).

signal close_requested

var panel_title: String = ""
var panel_width: float = 860.0

## Gives keyboard/gamepad focus to the first interactive control.
func focus_first() -> void:
	pass

func _first_focusable(node: Node) -> Control:
	for c in node.get_children():
		if c is Control:
			var ctl := c as Control
			if ctl.focus_mode == Control.FOCUS_ALL and ctl.is_visible_in_tree():
				if not (ctl is BaseButton and (ctl as BaseButton).disabled):
					return ctl
		var r := _first_focusable(c)
		if r != null:
			return r
	return null
