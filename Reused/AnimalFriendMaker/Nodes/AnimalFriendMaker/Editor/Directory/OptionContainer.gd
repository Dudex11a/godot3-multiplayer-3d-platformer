extends VBoxContainer

onready var editor_node: = get_node("../../../../..")

#func ui_cancel_action_parent(focus: FocusCursor):
#	editor_node.previous_directory()

func focus_looped_p(focus: FocusCursor, looped: int, parent: Node):
	editor_node.focus_directory_looped(focus, looped)
