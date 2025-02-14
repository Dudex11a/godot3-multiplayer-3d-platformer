extends Control
class_name DTextInput
func get_class() -> String: return "DTextInput"
tool

onready var label_node: = $Label

signal pressed
signal text_changed(text)

export var text: String = "" setget set_text

func pressed():
	emit_signal("pressed")

func set_text(value: String):
	text = value
	emit_signal("text_changed", text)
	if is_instance_valid(label_node):
		label_node.text = text

# ===== Focus

func ui_accept_action(focus: FocusCursor):
	focus.open_text_window(self)
#	pressed()

# ===== Signal

func _on_Button_pressed():
	pressed()
