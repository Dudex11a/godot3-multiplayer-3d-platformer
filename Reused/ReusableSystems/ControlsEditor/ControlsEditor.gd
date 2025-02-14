extends Control

onready var option_editor_node: = $OptionEditor
onready var tabs_node: = option_editor_node.get_node("OptionTabs")

func _ready():
	# Connect controller connections
	Input.connect("joy_connection_changed", self, "joy_connection_changed")
	# Create controls UI
	var actions: Dictionary = Controls.get_actions()
	var controllers: Array = Controls.get_controllers()
	# Create a tab for each controller and create each action within the controller
	for controller in controllers:
		add_controller_tab(controller)
#	for action_name in actions.keys():
		# Create each action in each controller
#		add_action_item(action_name, input_event)
#		for input_event in actions[action_name]:
#			var controller_data: ControllerData = ControllerData.new(input_event)
#			var controller_tab: OptionContainer = add_controller_tab(controller_data)
#			add_action_item(action_name, input_event)

# Create and return a controller tab based on ControllerData given
func add_controller_tab(controller_data: ControllerData) -> OptionContainer:
	var controller_tab: OptionContainer = tabs_node.get_node_or_null(controller_data.to_name())
	if controller_tab == null:
		# Make new controller_tab
		controller_tab = G.R.get_instance("option_container_node")
		controller_tab.name = controller_data.to_name()
		tabs_node.add_child(controller_tab)
		var controller_actions: Dictionary = Controls.get_controller_actions(controller_data)
		# Add action_items
		for action_name in InputMap.get_actions():
			var action_item: ItemInput = add_action_item(action_name, controller_data)
			# Add Input Events to action item
			if action_name in controller_actions.keys():
				var input_events: Array = controller_actions[action_name]
				action_item.add_input_events(input_events)
	return controller_tab

func remove_controller_tab(controller_data: ControllerData):
	var controller_tab: OptionContainer = tabs_node.get_node_or_null(controller_data.to_name())
	if is_instance_valid(controller_tab):
		controller_tab.queue_free()

func joy_connection_changed(device: int, connected: bool):
	var controller_data: ControllerData = ControllerData.new(["joypad", device])
	if connected:
		add_controller_tab(controller_data)
	else:
		remove_controller_tab(controller_data)

func add_action_item(action_name: String, controller_data: ControllerData):
	var controller_tab: OptionContainer = add_controller_tab(controller_data)
	var action_item: ItemInput = controller_tab.option_container_node.get_node_or_null(action_name)
	if is_instance_valid(action_item):
		pass
	else:
		# Create action_item
		action_item = G.R.get_instance("item_input_node")
		action_item.set_action_name(action_name)
		action_item.controller_data = controller_data
		controller_tab.add_child(action_item)
	return action_item

#func add_input_event_???(action_name: String, input_event: InputEvent) -> OptionItem:
#	var controller_data: ControllerData = ControllerData.new(input_event)
#	var controller_tab: OptionContainer = add_controller_tab(controller_data)
#	var input_event_item: OptionItem = controller_tab.option_container_node.get_node_or_null(action_name)
#	if is_instance_valid(input_event_item):
#		pass
#	else:
#		# Create input_event_item
#		input_event_item = G.R.get_resource("option_item_node").instance()
#		input_event_item
#		controller_tab.add_child(input_event_item)
#	return input_event_item
