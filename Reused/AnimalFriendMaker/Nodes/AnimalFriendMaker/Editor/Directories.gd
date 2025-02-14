extends Control

onready var editor_node: = get_parent()

func focus_entered(focus: FocusCursor):
	var active_directory: Node = editor_node.active_directory
	if active_directory.has_method("get_first_node"):
		focus.set_current_node(active_directory.get_first_node())
	else:
		focus.set_current_node(active_directory)
