extends Control

onready var editor_node: = get_node("../..")
onready var file_selector_node: = get_node("../FileSelector")

func focus_entered(focus: FocusCursor):
	focus.set_current_node(CustomFocus.get_first_valid_node(self))
 
func ui_up_action_p(focus: FocusCursor, parent: Node):
	focus.set_current_node(CustomFocus.get_last_valid_node(file_selector_node.file_list_node))

func ui_down_action_p(focus: FocusCursor, parent: Node):
	focus.set_current_node(CustomFocus.get_first_valid_node(file_selector_node.file_list_node))

func ui_cancel_action_p(focus: FocusCursor, parent: Node):
	editor_node.toggle_file_selector(false)
