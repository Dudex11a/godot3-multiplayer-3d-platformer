extends Control

onready var host_options_editor_node: = $HostOptionEditor

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(host_options_editor_node)
