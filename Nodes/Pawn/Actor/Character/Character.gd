extends Actor
class_name Character
func get_class() -> String: return "Character"

onready var animation_node: = $Animation
onready var player_node: = get_parent().get_parent()
onready var rotate_w_move_input_node: = $RotateWMoveInput
onready var bounce_box_node: = $BounceBox
var info: CharacterInfo = CharacterInfo.new()
var af_node: AnimalFriend = null

# I use arrays to disable input so other processes
# don't re-enable input when another process still needs
# it disabled.
var disable_input_array: Array = []
var disable_move_input_array: Array = []

var controller_forward_input: float = 0.0
var controller_right_input: float = 0.0
var controller_back_input: float = 0.0
var controller_left_input: float = 0.0

signal created_animal_friend

func _ready():
	# Character spawns in with no collision (until af_node is created)
	self.disable_physics_process = true
	add_intangibility_value("start", true)

func set_character_info(value: CharacterInfo):
	info = value
	if is_instance_valid(info.af_info):
		set_af_info(info.af_info)
#	if is_instance_valid(info.af_info):
#		create_animal_friend(info.af_info)

func _input(event: InputEvent):
	# Abort if not controller
	var event_controller_data: = ControllerData.new(event)
	if get_controller_data().to_name() != event_controller_data.to_name():
		return
	
	# Execute actions
	# For each action input
	# Create action names
	var action_names: Array = []
	var action_name_prefix: String = "character_action-"
	for index in range(6):
		action_names.append(action_name_prefix + String(index + 1))
	# Execute action from action_names
	for index in range(action_names.size()):
		var action_name: String = action_names[index]
		var action_index: int = index + 1
		# For each action node assoiated with the action_index
		for action_node in get_actions_by_index(action_index):
			# Press and release functions for each action
			if event.is_action_pressed(action_name):
				action_node.action_pressed()
			elif event.is_action_released(action_name):
				action_node.action_released()
	
	# Write character movement to variable here, I need to do this because
	# if I try to detect input in _physics_process I would be able to tell
	# if the "event" belongs to the controller this character is associated with.
	for direction in ["forward", "right", "back", "left"]:
		var action_name: String = "character_move-" + direction
		var variable_name: String = "controller_%s_input" % [direction]
		if event.is_action(action_name):
			self[variable_name] = event.get_action_strength(action_name)

func _physics_process(delta: float):
	if not can_move_input():
		return
	if player_node.is_local:
		move_input.x = controller_right_input - controller_left_input
		move_input.y = controller_back_input - controller_forward_input
	# Rotate input if camera
	var camera_node: Spatial = player_node.camera_node
	if is_instance_valid(camera_node):
		move_input = move_input.rotated((camera_node.rotation.y * -1))
	if (not can_input() or not can_move_input()) and player_node.is_local:
		move_input = Vector2.ZERO

func create_animal_friend(af_info: AnimalFriendInfo):
	info.af_info = af_info
	# Remove old animal friend node ??? TEMP
	#
	af_node = AF_Maker.R.get_instance("af_node")
	model_node.add_child(af_node)
#	# Set af_info
#	set_af_info(af_info)
	# Update af's size and position to better fit world
	af_node.scale *= 0.8
	# Connect signals
	af_node.connect("full_body_state_changed", animation_node, "full_body_state_changed")
	af_node.connect("upper_body_state_changed", animation_node, "upper_body_state_changed")
	# Set animation_node stuff
	animation_node.af_node = af_node
	animation_node.init_animation()
	# Enable character's physics and make tangible
	self.disable_physics_process = false
	remove_intangibility_value("start")

func get_actions_by_index(action_index: int) -> Array:
	var actions: Array = []
	for action_node in actions_node.get_children():
		if action_node.action_index == action_index:
			actions.append(action_node)
	return actions

func get_forward_vector() -> Vector3:
	var forward_vector: = Vector3.BACK
	forward_vector = forward_vector.rotated(up_direction, forward_direction)
	return forward_vector

func get_controller_data() -> ControllerData:
	return player_node.controller_data

func add_disable_input(value: String):
	disable_input_array.append(value)
	set_disable_input()

func remove_disable_input(value: String):
	disable_input_array.erase(value)
	set_disable_input()

func can_input() -> bool:
	return disable_input_array.size() <= 0

func set_disable_input(value: bool = can_input()):
	set_process_input(value)
	set_process_unhandled_input(value)
	set_process_unhandled_key_input(value)
	
	if value:
		# Reset move_input
		move_input = Vector2.ZERO
		controller_forward_input = 0.0
		controller_right_input = 0.0
		controller_back_input = 0.0
		controller_left_input = 0.0

func add_disable_move_input(value: String):
	disable_move_input_array.append(value)
	if value:
		# Reset move_input
		move_input = Vector2.ZERO

func remove_disable_move_input(value: String):
	disable_move_input_array.erase(value)

func can_move_input() -> bool:
	return disable_move_input_array.size() <= 0

func set_af_info(value: AnimalFriendInfo):
	# Make af_node if there is one
	if not is_instance_valid(af_node):
		create_animal_friend(value)
	af_node.set_af_info(value)
	# If client owns character
	if G.is_node_network_master(player_node, true):
#		rpc("set_af_info_dic", value.to_dictionary())
		O3DP.O.custom_rpc(self, "set_af_info_dic", [value.to_dictionary()])

remote func set_af_info_dic(value: Dictionary):
	var af_info: = AnimalFriendInfo.new()
	af_info.from_dictionary(value)
	set_af_info(af_info)

## State debug
#func set_state(state: Dictionary):
#	G.debug_print("%s set_state" % [player_node.name])
#	.set_state(state)
#
#func reset_state():
#	G.debug_print("%s reset_state" % [player_node.name])
#	.reset_state()

# ===== Game methods =====

func DisableLocalPlayerInput(value: bool, id: String):
	if player_node.is_local:
		if value:
			add_disable_input(id)
		else:
			remove_disable_input(id)
