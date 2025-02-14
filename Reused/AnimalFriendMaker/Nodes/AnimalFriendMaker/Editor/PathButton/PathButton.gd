tool
extends Control
class_name PathButton

onready var hbox_container_node: = $HBoxContainer
onready var button_node: = hbox_container_node.get_node("Button")
onready var arrow_texture_node: = hbox_container_node.get_node("ArrowTexture")

export var path_name: String = "Default name" setget set_path_name

var path: Array = []
var function: String = ""

signal path_button_pressed

func set_path_name(value: String):
	if not is_instance_valid(button_node):
		button_node = $Button
	path_name = value
	button_node.text = value

func _on_Button_pressed():
	emit_signal("path_button_pressed", path, function)

func ui_accept_action(focus: FocusCursor):
	_on_Button_pressed()

func _on_HBoxContainer_resized():
	# Resize this control to the hbox_container_node's size
	if is_instance_valid(hbox_container_node):
		rect_min_size = hbox_container_node.rect_size
	# Set arrow texture visibility based on if it's the last child
	if is_instance_valid(arrow_texture_node):
		var is_last_child: bool = get_index() < get_parent().get_child_count() - 1
		arrow_texture_node.visible = is_last_child
