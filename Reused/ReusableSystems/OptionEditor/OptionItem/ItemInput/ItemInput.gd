extends OptionItem
class_name ItemInput

onready var input_container_node: = $ScrollContainer/InputContainer
onready var add_input_node: = input_container_node.get_node("AddInput")

var action_name: String = "unknown_action" setget set_action_name
var controller_data: ControllerData = null

func add_input_events(input_events: Array):
	for input_event in input_events:
		add_input_event(input_event)

func add_input_event(input_event: InputEvent):
	var input_button_node: InputButton = create_input_button()
	input_button_node.set_input_event(input_event)
	input_button_node.action_name = action_name

func create_input_button() -> InputButton:
	var input_button_node: InputButton = G.R.get_instance("input_button_node")
	input_container_node.add_child(input_button_node)
	# Move add_input node to the back for the InputContainer list
	input_container_node.move_child(add_input_node, input_container_node.get_child_count())
	return input_button_node

func set_action_name(value: String):
	action_name = value
	name = action_name
	name[0] = name[0].capitalize()
	while name.find("_") >= 0:
		var index = name.find("_")
		name[index] = " "
		if name.length() > index:
			name[index + 1] = name[index + 1].capitalize()
	if is_instance_valid(name_node):
		name_node.text = name

func get_ui_accept_node(focus_cursor: FocusCursor) -> Node:
	var node: Control = input_container_node.get_children()[0]
	return node

func _on_AddInput_pressed_with_focus(focus_cursor: FocusCursor):
	# Hide add_input_node button until the new input_button_node is set
	add_input_node.visible = false
	# Create new input_button and set it to the next input
	var input_button_node: InputButton = create_input_button()
	input_button_node.controller_data = controller_data
	input_button_node.action_name = action_name
	input_button_node.watch_for_input = true
	# Change focus if it was used
	if is_instance_valid(focus_cursor):
		focus_cursor.set_process_input(false)
		yield(get_tree(), "idle_frame")
		focus_cursor.set_current_node(input_button_node)
	yield(input_button_node, "stop_watching")
	if is_instance_valid(focus_cursor):
		focus_cursor.set_process_input(true)
	add_input_node.visible = true
