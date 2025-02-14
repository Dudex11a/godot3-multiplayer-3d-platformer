extends Control

#func ui_accept_action(focus_cursor: FocusCursor):
#	focus_cursor.set_current_node(get_node("ScrollContainer/PathContainer").get_children()[0])

func focus_entered(focus: FocusCursor):
	focus.set_current_node(get_node("ScrollContainer/PathContainer/BackButton"))
