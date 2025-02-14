extends Control
class_name OptionItem
func get_class() -> String: return "OptionItem"

onready var name_node: = $_Name
onready var option_editor = G.get_parent_of_type(self, OptionEditor)

# I have to use a null in an array here so I can use any type with export
export var default_value: Array = [null]
var value setget set_value, get_value

var emit_value_change: bool = false

signal value_changed(value)
signal cancel

func _ready():
	name_node.text = name
	self.value = default_value[0]
	# Moved to OptionEditor
#	emit_value_change = true

func get_editor() -> Node:
	return G.get_parent_of_type(self, OptionEditor)

# ===== setget

func set_value(new_value = value):
	var old_value = value
	# Set new value
	value = new_value
	# If value has changed then emit signal
	if old_value != value:
		if is_instance_valid(option_editor):
			option_editor.option_changed(name, value)
		if emit_value_change:
			emit_signal("value_changed", value)

func get_value():
	return value

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(CustomFocus.get_first_valid_node(self))

func ui_up_action_p(focus: FocusCursor, parent: Node):
	move_cursor(focus, -1)

func ui_down_action_p(focus: FocusCursor, parent: Node):
	move_cursor(focus, 1)

func ui_cancel_action_p(focus: FocusCursor, parent: Node):
	emit_signal("cancel")

func move_cursor(focus: FocusCursor, amount: int):
	var node_name: String = focus.current_node.name
	# Move cursor to next node
	var move_cursor_info: Dictionary = focus.move_cursor_child(amount, self)
	if move_cursor_info.node.has_node(node_name):
		focus.set_current_node(move_cursor_info.node.get_node(node_name))
#	var last_index: int = focus.current_node.get_index()
#	# Move cursor to next node
#	var move_cursor_info: Dictionary = focus.move_cursor_child(amount, self)
#	if move_cursor_info.node is get_script() and move_cursor_info.looped < 0:
#		focus.set_current_node(move_cursor_info.node.get_children()[last_index])

#func get_ui_cancel_node(focus_cursor: FocusCursor) -> Node:
#	return get_parent().get_parent()

# ===== Signals

func _on_ResetButton_pressed():
	self.value = default_value[0]
