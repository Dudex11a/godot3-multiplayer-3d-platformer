extends VBoxContainer

onready var editor_node: = get_node("../../../../..")

#func focus_entered(focus_cursor: FocusCursor):
#	# Go back to directories
#	focus_cursor.set_current_node(get_node("../../../.."))

func focus_looped_p(focus: FocusCursor, looped: int, parent: Node):
	editor_node.focus_directory_looped(focus, looped)

func ui_cancel_action_p(focus: FocusCursor, parent: Node):
	editor_node.previous_directory()
