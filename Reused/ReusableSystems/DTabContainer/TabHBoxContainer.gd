extends HBoxContainer

signal focus_cursor_entered(focus)
signal tab_looped(focus, looped)

# ===== Focus

func focus_entered(focus: FocusCursor):
	emit_signal("focus_cursor_entered", focus)

func focus_looped_p(focus: FocusCursor, looped: int, _parent: Node):
	emit_signal("tab_looped", focus, looped)
