extends Control
class_name InputButton

onready var open_button_node: = $Button
onready var icon_texture_node: = $IconTexture
onready var debug_label_node: = $DebugLabel
onready var options_popup_node: = $OptionsPopup
onready var options_main_node: = options_popup_node.get_node("OptionsMain")
onready var edit_button_node: = options_main_node.get_node("EditButton")
onready var delete_button_node: = options_main_node.get_node("DeleteButton")

var action_name: String = ""
var input_event: InputEvent = null
var controller_data: ControllerData = null
# When watching for input, if the controller need to be the same
var allow_different_controller: bool = false

var watch_for_input: bool = false setget set_watch_for_input

signal stop_watching

func _input(event: InputEvent):
	if watch_for_input:
		var new_controller_data: ControllerData = ControllerData.new(event)
		# If controller is the same
		if controller_data.to_string() == new_controller_data.to_string() or allow_different_controller:
			# If event is a button, make sure it's being pressed, not released
			if Controls.get_input_event_type(event) == "button":
				if not event.pressed:
					return
			set_input_event(event)
			set_watch_for_input(false)

func set_input_event(value: InputEvent):
	# Remove previous input_event from InputMap if InputButton already has an InputEvent
	if is_instance_valid(input_event):
		InputMap.action_erase_event(action_name, input_event)
	# Set input_event to new event
	input_event = value
	debug_label_node.text = value.as_text()
	# Set controller data from input
	controller_data = ControllerData.new(value)
	# Set input_event in InputMap
	if action_name != "":
		InputMap.action_add_event(action_name, input_event)

func _on_Button_pressed():
	G.debug_print("This used to be 'G.create_popup_control(rect_global_position + (rect_size * Vector2.DOWN))'")
#	G.create_popup_control(rect_global_position + (rect_size * Vector2.DOWN))

func set_watch_for_input(value: bool):
	# Wait a moment for the last input pressed to go through
	yield(get_tree(), "idle_frame")
	watch_for_input = value
	if watch_for_input:
		icon_texture_node.texture = G.R.get_resource("refresh_texture")
	else:
		icon_texture_node.texture = null
		emit_signal("stop_watching")

func ui_accept_action(focus_cursor: FocusCursor):
	set_watch_for_input(true)
	# Disable focus_cursor input until input set
	focus_cursor.set_process_input(false)
	yield(self, "stop_watching")
	focus_cursor.set_process_input(true)

func get_ui_cancel_node(focus_cursor: FocusCursor) -> Node:
	return get_parent().get_parent().get_parent()

func get_open_button_nodes() -> Array:
	return [open_button_node]

func popup_options():
	options_main_node.set_global_position(get_global_transform().origin)

func _on_EditButton_pressed():
	set_watch_for_input(true)

func _on_DeleteButton_pressed():
	pass # Replace with function body.
