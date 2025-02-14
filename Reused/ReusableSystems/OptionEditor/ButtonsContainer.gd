extends HBoxContainer

signal ui_up_action(focus)
signal ui_down_action(focus)

# ===== Focus

func ui_up_action_p(focus: FocusCursor, parent: Node):
	emit_signal("ui_up_action", focus)

func ui_down_action_p(focus: FocusCursor, parent: Node):
	emit_signal("ui_down_action", focus)

func ui_accept_action_p(focus: FocusCursor, parent: Node):
	pass
