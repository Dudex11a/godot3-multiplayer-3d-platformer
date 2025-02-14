extends Node

const controller_abbreviation: String = "Con"

var default_actions: Dictionary = {}

func _ready():
	# Store default actions from InputMap
	default_actions = get_actions()
	Input.connect("joy_connection_changed", self, "joy_connection_changed")
	specify_joypad_input_map()
	# Tests
#	print(serialize_actions(get_controller_actions(ControllerData.new(["joypad", 0]))))
#	print_actions(get_actions())
#	var serialized_actions: Dictionary = serialize_actions(get_actions())
#	var unserialized_actions: Dictionary = unserialize_actions(serialized_actions)
#	print_actions(unserialized_actions)

#func _input(event: InputEvent):
#	var actions: Array = get_input_actions(event)
#	if actions.size() > 0:
#		print(actions)

func get_input_actions(input_event: InputEvent) -> Array:
	var actions: Array = []
	for action_name in InputMap.get_actions():
		for action in InputMap.get_action_list(action_name):
			# Does input match
			if input_event.shortcut_match(action) and (action.device == input_event.device or action.device == -1):
				actions.append(action_name)
	return actions

func get_input_device_type(event: InputEvent) -> String:
	var type: String = "unknown"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		type = "joypad"
	if event is InputEventKey:
		type = "keyboard"
	if event is InputEventMouse:
		type = "mouse"
	if event is InputEventScreenTouch:
		type = "touch"
	return type

func get_input_event_type(event: InputEvent) -> String:
	var type: String = "unknown"
	if event is InputEventJoypadButton or event is InputEventMouseButton or event is InputEventKey:
		type = "button"
	if event is InputEventJoypadMotion:
		type = "axis"
	return type

func joy_connection_changed(device: int, connected: bool):
	if connected:
		add_joypad_actions(device)
	else:
		remove_joypad_actions(device)

# Change the Project Input Map controls to specify for each controller connected
# for the "All Devices" option in joypad. This is used for custom controls by
# player later down the line
func specify_joypad_input_map():
	# Remove joypad controls from InputMap
	remove_joypad_actions(-1)
	# Re-add joypad controls for each existing joypad
	for joypad_id in Input.get_connected_joypads():
		add_joypad_actions(joypad_id)
	
func add_joypad_actions(id: int):
	for action_name in default_actions.keys():
		var actions: Array = default_actions[action_name]
		for action in actions:
			if get_input_device_type(action) == "joypad":
				var new_action: InputEvent = action.duplicate()
				new_action.device = id
				InputMap.action_add_event(action_name, new_action)

func get_controller_actions(controller_datas) -> Dictionary:
	var actions: Dictionary = {}
	# If controller datas isn't an array make it one
	if not controller_datas is Array:
		controller_datas = [controller_datas]
	# Add actions to actions
	for action_name in InputMap.get_actions():
		actions[action_name] = []
		for action in InputMap.get_action_list(action_name):
			for controller_data in controller_datas:
				if get_input_device_type(action) == controller_data.device_type and action.device == controller_data.device_id:
					actions[action_name].append(action)
	return actions

func remove_joypad_actions(id: int):
	for action_name in InputMap.get_actions():
		for action in InputMap.get_action_list(action_name):
			if get_input_device_type(action) == "joypad" and action.device == id:
				InputMap.action_erase_event(action_name, action)

func get_actions() -> Dictionary:
	var actions: Dictionary = {}
	for action_name in InputMap.get_actions():
		actions[action_name] = []
		for action in InputMap.get_action_list(action_name):
			actions[action_name].append(action.duplicate())
	return actions

func print_actions(actions: Dictionary):
	var spacer: String = "    "
	for action_name in actions.keys():
		print(action_name)
		for action in actions[action_name]:
			print(spacer + get_input_device_type(action) + " " + String(action.device))
			print(spacer + spacer + action.as_text())

func serialize_actions(actions: Dictionary) -> Dictionary:
	var serialized_actions: Dictionary = {}
	for action_name in actions.keys():
		serialized_actions[action_name] = []
		for action in actions[action_name]:
			var serialized_action: Dictionary = serialize_action(action)
			serialized_actions[action_name].append(serialized_action)
	return serialized_actions

func serialize_action(action: InputEvent) -> Dictionary:
	var serialized_action: Dictionary = {}
	serialized_action.device_type = get_input_device_type(action)
	serialized_action.device_id = action.device
	# Device specific actions
	var action_type: String = get_input_event_type(action)
	serialized_action.action_type = action_type
	match action_type:
		"button":
			var button_id: int = -1
			if action is InputEventJoypadButton or action is InputEventMouseButton:
				button_id = action.button_index
			if action is InputEventKey:
				button_id = action.scancode
			serialized_action.button_id = button_id
		"axis":
			var axis: int = -1
			if action is InputEventJoypadMotion:
				axis = action.axis
			serialized_action.axis = axis
	return serialized_action

func unserialize_actions(serialized_actions: Dictionary) -> Dictionary:
	var actions: Dictionary = {}
	for action_name in serialized_actions.keys():
		actions[action_name] = []
		for action in serialized_actions[action_name]:
			actions[action_name].append(unserialize_action(action))
	return actions

func unserialize_action(serialized_action: Dictionary) -> InputEvent:
	var action: InputEvent
	match serialized_action.device_type:
		"joypad":
			match serialized_action.action_type:
				"button":
					action = InputEventJoypadButton.new()
					action.button_index = serialized_action.button_id
				"axis":
					action = InputEventJoypadMotion.new()
					action.axis = serialized_action.axis
		"keyboard":
			action = InputEventKey.new()
			action.scancode = serialized_action.button_id
		"mouse":
			action = InputEventMouseButton.new()
			action.button_index = serialized_action.button_id
	return action

func get_controllers() -> Array:
	var controllers: Array = []
	controllers.append(ControllerData.new(["keyboard", 0]))
	for joypad_id in Input.get_connected_joypads():
		controllers.append(ControllerData.new(["joypad", joypad_id]))
	return controllers
