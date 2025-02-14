tool
extends Control
class_name DirectoryButton

onready var button_node: = $Button

signal goto_directory
signal previous_directory

var path: Array = []
var function: String = "directory button default"
# Arguments for the function if needed
var args: Array = []

func _ready():
	set_button_node_text()

func set_name(value: String):
	.set_name(value)
	set_button_node_text(value)

func set_button_node_text(value: String = name):
	if not is_instance_valid(button_node):
		button_node = $Button
	button_node.text = value

func _on_Button_pressed():
	emit_signal("goto_directory", path, function, args)

func ui_accept_action(focus_cursor: FocusCursor):
	_on_Button_pressed()
	
func ui_cancel_action(focus_cursor: FocusCursor):
	emit_signal("previous_directory")
