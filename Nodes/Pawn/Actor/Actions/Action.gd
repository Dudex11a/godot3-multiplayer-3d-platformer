extends Spatial
class_name Action
func get_class() -> String: return "Action"

export var action_index: int = 1
export var display_input: bool = true

var actor_node: Actor = null
var is_sub_action: bool = false
var pressed: bool = false
# Progression through the Action, this is mostly for ui but
# I could use it for more down the line
# 100 = ability available
var progression: int = 100 setget set_progression

signal pressed
signal released
signal progression_changed(value)

func _ready():
	init_actor_node()
	var action_container: Node = get_parent()
	if "Action" in action_container.get_class():
		action_container = action_container.get_parent()
	# Connect pressed signal to other actions that need to know when the action
	# is pressed. Also Connect other actions pressed signal to this action if 
	# this action needs the signal
	# Get all actions in action container
	for action in G.get_children_of_class(action_container, "Action"):
		# Connect other to self
		var signal_method_names: Dictionary = get_signal_method_names(action.name)
		for signal_name in signal_method_names.keys():
			var method_name: String = signal_method_names[signal_name]
			if has_method(method_name):
				if not action.is_connected(signal_name, self, method_name):
					action.connect(signal_name, self, method_name, [action])
		# Connect self to other
		signal_method_names = get_signal_method_names()
		for signal_name in signal_method_names.keys():
			var method_name: String = signal_method_names[signal_name]
			if action.has_method(method_name):
				if not is_connected(signal_name, action, method_name):
					connect(signal_name, action, method_name, [self])

remote func action_pressed():
	for child in get_children():
		if child.has_method("action_pressed"):
			child.action_pressed()
	pressed = true
	emit_signal("pressed")

remote func action_released():
	for child in get_children():
		if child.has_method("action_released"):
			child.action_released()
	pressed = false
	emit_signal("released")

func add_default_state():
	actor_node.add_state(get_class(), create_default_state())

func remove_default_state():
	actor_node.remove_state(get_class())

func pressed_default_rpc():
	if G.is_node_network_master(self):
#		rpc("action_pressed")
		O3DP.O.custom_rpc(self, "action_pressed")

func released_default_rpc():
	if G.is_node_network_master(self):
#		rpc("action_released")
		O3DP.O.custom_rpc(self, "action_released")

func on_reset_actor_node():
	pass

func on_exiting():
	# Emit signal from actor
	actor_node.emit_signal("action_removed", self)

func connect_to_actor_node(new_actor_node: Actor = actor_node):
	actor_node = new_actor_node
	# Signals
	if is_instance_valid(actor_node):
		actor_node.connect("reset_state", self, "on_reset_actor_node")

func get_player_node() -> Node:
	return actor_node.player_node

func create_default_state() -> Dictionary:
	return {
			"state_start" : {
				"node_path" : get_path(),
				"method" : "action_pressed"
			}}

func get_signal_method_names(action_name: String = name) -> Dictionary:
	var names: Dictionary = {}
	for signal_name in ["pressed", "released"]:
		names[signal_name] = "%s_%s" % [action_name, signal_name]
	return names

func init_actor_node():
	if is_instance_valid(actor_node):
		return
	var parent = get_parent()
	var action_container: Node = parent
	# Set actor_node if parent structure matches
	if parent.name == "Actions" and parent.get_parent() is Actor:
		connect_to_actor_node(parent.get_parent())
	# Set action as sub_action
	if "Action" in parent.get_class():
		is_sub_action = true
		action_container = parent.get_parent()
		# Wait and keep on trying to set actor_node from parent until parent has a actor_node
		while not is_instance_valid(actor_node):
			connect_to_actor_node(parent.actor_node)
			yield(get_tree(), "idle_frame")
	# Wait a frame for status to potetially set
	yield(get_tree(), "idle_frame")
	# Emit signal that this action was added
	actor_node.emit_signal("action_added", self)

func get_input_event() -> InputEvent:
	# Get action input id
	var action_input_id: String = get_action_input_id()
	# Get player_node
	var controller_data: ControllerData = null
	if "player_node" in actor_node:
		controller_data = actor_node.player_node.controller_data
	# Search inputs in action list for an event that matches the player's ControllerData
	if is_instance_valid(controller_data):
		# Get action_list from actions
		var action_list: Array = InputMap.get_action_list(action_input_id)
		# Sort so mouse events are first
		action_list.sort_custom(self, "sort_action_list")
		# Check if event matches
		for input_event in action_list:
			if controller_data.event_matches(input_event):
				return input_event
	# Find event in input
	return null

func sort_action_list(a, b):
	return a is InputEventMouseButton and not b is InputEventMouseButton

func get_action_input_id():
	return "character_action-%s" % action_index

func get_icon() -> StreamTexture:
	var action_dictionary: Dictionary = get_action_dictionary()
	if "Icon" in action_dictionary:
		return action_dictionary["Icon"]
	return null

func get_action_dictionary() -> Dictionary:
	return O3DP.R.actions_resources[name]

func get_status() -> Dictionary:
	# I need variable values, state (last) and children.
	# This will all be in a Dictionary
	var status: Dictionary = {
		"children" : {}
	}
	# Add child Actions to status
	for child in get_children():
		if "Action" in child.get_class():
			status.children[child.name] = child.get_status()
	# Add some variables to status
	status.action_index = action_index
	
	return status

# Template for other Actions for status
#func get_status() -> Dictionary:
#	var status: Dictionary = .get_status()
#
#	return status

func set_status(status: Dictionary):
	# Set variables
	for status_key in status.keys():
		if status_key in self:
			self[status_key] = status[status_key]
	# Add children to this action
	if "children" in status:
		for child_id in status.children.keys():
			var child_status: Dictionary = status.children[child_id]
			O3DP.create_action_from_status(child_id, child_status, self)

# Template for other Actions for status
#func set_status(status: Dictionary):
#	
#	.set_status(status)

# ===== setget

func set_progression(value: int):
	progression = value
	emit_signal("progression_changed", progression)

# ===== Signals

func _on_Action_tree_exiting():
	on_exiting()
