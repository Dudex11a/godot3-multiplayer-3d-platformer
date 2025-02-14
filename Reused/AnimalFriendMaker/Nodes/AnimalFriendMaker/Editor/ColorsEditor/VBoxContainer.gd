extends VBoxContainer

signal looped(focus, direction)

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(CustomFocus.get_first_valid_node(self))

func focus_entered_p(focus: FocusCursor, _parent: Node):
	# If focus enters an hbox go to it's first child
	if focus.current_node is HBoxContainer:
		var node_to_goto: Node = null
		# Check if any of the nodes are selected
		for child in focus.current_node.get_children():
			if child.linked:
				node_to_goto = child
			elif child.selected:
				node_to_goto = child
		if not is_instance_valid(node_to_goto):
			node_to_goto = CustomFocus.get_first_valid_node(focus.current_node)
		if is_instance_valid(node_to_goto):
			focus.set_current_node(node_to_goto)

func ui_up_action_pp(focus: FocusCursor, parent: Node):
	focus_move(focus, parent, -1)
	
func ui_down_action_pp(focus: FocusCursor, parent: Node):
	focus_move(focus, parent, 1)

func focus_move(focus: FocusCursor, parent: Node, increment: int = 1):
	# Moving up from hbox container, leave hbox and go to next node
	if parent is HBoxContainer or parent is DColorPicker:
		# Get next child data
		var next_child_data: Dictionary = G.get_next_child_ext(parent, increment)
		# Goto next child
		focus.set_current_node(next_child_data.node)
		# Emit looped data if looped
		if next_child_data.looped >= 0:
			emit_signal("looped", focus, next_child_data.looped)

func focus_looped_p(focus: FocusCursor, looped: int, parent: Node):
	emit_signal("looped", focus, looped)
