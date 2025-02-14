extends VBoxContainer

signal exit_main_menu

func focus_entered(focus_cursor: FocusCursor):
	# Exit menu
	emit_signal("exit_main_menu")
