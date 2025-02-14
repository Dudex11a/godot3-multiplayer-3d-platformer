extends VBoxContainer

signal looped
signal exit

func ui_up_action_pp(focus: FocusCursor, parent: Node):
	ui_up_down(focus, parent, -1, focus.current_node)

func ui_down_action_pp(focus: FocusCursor, parent: Node):
	ui_up_down(focus, parent, 1, focus.current_node)

func ui_up_down(focus: FocusCursor, parent: Node, increment: int, last_node: Node):
	var next_child_info: Dictionary = G.get_next_child_ext(parent, increment)
	var node: Node = next_child_info.node
	if next_child_info.looped >= 0:
		emit_signal("looped", focus , next_child_info.looped)
	else:
		# If previous node is a FileItem set node with context of last node
		var next_node: Node = node.get_children()[last_node.get_index()]
		if is_instance_valid(next_node):
			node = next_node
		focus.set_current_node(node)

func ui_accept_action_pp(focus: FocusCursor, parent: Node):
	if focus.current_node is Button:
		focus.current_node.emit_signal("pressed")
	# TEMP
	if focus.current_node.name == "Delete":
		ui_up_down(focus, parent, 1, focus.current_node)

func ui_cancel_action_pp(focus: FocusCursor, parent: Node):
	emit_signal("exit")
