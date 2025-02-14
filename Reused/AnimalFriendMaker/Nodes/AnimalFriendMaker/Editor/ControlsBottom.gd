extends Control

func focus_entered(focus: FocusCursor):
	focus.set_current_node(CustomFocus.get_first_valid_node(get_node("HBoxContainer")))
