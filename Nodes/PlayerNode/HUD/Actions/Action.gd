extends Control

onready var action_icon: = $HBoxContainer/ActionIcon
onready var button_icon: = $HBoxContainer/ButtonIcon
onready var button_text_container: = $HBoxContainer/ButtonTextContainer
onready var button_text: = button_text_container.get_node("ButtonText")
onready var progress_bar: = $HBoxContainer/ProgressBar

var action_node: Action = null setget set_action_node

func set_action_node(value: Action):
	action_node = value
	var action_id: String = action_node.name
	# Set name
	name = action_id
	# Set Action icon based on action_id
	action_icon.texture = action_node.get_icon()
	# Set Button icon based on action_id
	var input_event: InputEvent = action_node.get_input_event()
	var input_event_image: StreamTexture = null
	button_text_container.visible = value.display_input
	if is_instance_valid(input_event):
		input_event_image = G.input_event_to_image(input_event)
	if is_instance_valid(input_event_image):
		button_text_container.visible = false
		button_icon.texture = input_event_image
	else:
		button_icon.visible = false
		button_text.text = input_event.as_text()
	# Connect button press or progress
	action_node.connect("progression_changed", self, "set_progress")

func set_progress(value: int):
	progress_bar.value = value

func delete():
	queue_free()
