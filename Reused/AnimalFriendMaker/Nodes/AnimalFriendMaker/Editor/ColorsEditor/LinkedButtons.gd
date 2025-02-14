extends HBoxContainer

func ui_accept_action_p(focus: FocusCursor, parent: Node):
	# Press button
	focus.current_node.emit_signal("pressed")
	# Change focus
	focus.set_current_node(CustomFocus.get_first_valid_node(focus.current_node.get_parent()))
