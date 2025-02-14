extends Button

signal ui_right_action(focus)
signal ui_left_action(focus)

# ===== Focus

func ui_right_action(focus: FocusCursor):
	emit_signal("ui_right_action", focus)

func ui_left_action(focus: FocusCursor):
	emit_signal("ui_left_action", focus)
