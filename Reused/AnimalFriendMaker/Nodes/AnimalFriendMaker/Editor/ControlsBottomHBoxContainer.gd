extends HBoxContainer

onready var editor_node: = get_node("../..")

func ui_cancel_action_p(focus: FocusCursor, parent: Node):
	editor_node.previous_directory()

func ui_up_action_p(focus: FocusCursor, parent: Node):
	focus.set_current_node(editor_node.active_directory.get_last_node())

func ui_down_action_p(focus: FocusCursor, parent: Node):
	focus.set_current_node(editor_node.path_node)
