extends Control

onready var label_node: = $Label

export(Array, String) var options = []

var selected_option: String = "" setget set_selected_option

signal option_changed
signal option_select

func _ready():
	# Init
	if options.size() > 0:
		self.selected_option = options[0]

func ui_accept_action(focus: FocusCursor):
	emit_signal("option_select", selected_option)

func ui_right_action(focus: FocusCursor):
	increment_option(1)
	
func ui_left_action(focus: FocusCursor):
	increment_option(-1)

func increment_option(increment: int):
	var current_id: int = options.find(selected_option)
	if current_id >= 0:
		var next_id: int = (current_id + increment) % options.size()
		self.selected_option = options[next_id]

func set_selected_option(value: String):
	selected_option = value
	label_node.text = selected_option
	emit_signal("option_changed", selected_option)

func _on_RightButton_pressed():
	increment_option(1)

func _on_LeftButton_pressed():
	increment_option(-1)

func _on_SelectedButton_pressed():
	emit_signal("option_select", selected_option)
