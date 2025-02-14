extends Control

signal pressed_with_focus

func ui_accept_action(focus_cursor: FocusCursor):
	emit_signal("pressed_with_focus", focus_cursor)
	# Change focus to input added

func get_ui_cancel_node(focus_cursor: FocusCursor) -> Node:
	return get_parent().get_parent().get_parent()

func _on_Button_pressed():
	emit_signal("pressed_with_focus", null)

func get_button_nodes() -> Array:
	return [$Button]
