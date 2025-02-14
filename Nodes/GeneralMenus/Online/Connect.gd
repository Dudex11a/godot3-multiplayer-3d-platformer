extends Control

onready var connect_options_editor_node: = $ConnectOptionEditor

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(connect_options_editor_node)
