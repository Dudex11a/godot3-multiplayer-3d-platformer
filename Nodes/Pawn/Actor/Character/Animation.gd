extends Node

onready var character_node: = get_parent()

var af_node: AnimalFriend setget set_af_node

var manual_anim_state: String = ""
var move_input: Vector2 = Vector2.ZERO
# Save these node so I'm not looking for it constantly in process
var climb_node = null
var roll_node = null
var airdash_node = null
var pickup_node = null

func _process(delta: float):
	# Animation
	if is_instance_valid(af_node):
#		# Debug anim_full_body_state
#		G.debug_value("%s anim_full_body_state" % character_node.player_node.name, af_node.anim_full_body_state)
		move_input = character_node.move_input
		# Anim state
		match af_node.anim_full_body_state:
			"Walk":
				# Get anim speed
				var anim_speed: float = character_node.get_horizontal_velocity() / 10.0
				var anim_blend: float = max(anim_speed, 0.25)
				# Take the maximum value between the move_input and anim_speed
				# This way if rubbing up against a wall you'll still be walking
				anim_speed = max(anim_speed, move_input.normalized().length())
				# If not moving make sure idle is playing
				if character_node.move_input.length() < 0.01:
					anim_blend = 0
					anim_speed = 1
				# Adjust position in animation
				var anim_move_vec: = Vector2.ZERO
				anim_move_vec.y = anim_blend
				af_node.set_bs2d_value(anim_move_vec, "Walk")
				# Adjust animation speed
				af_node.set_full_body_speed(anim_speed)
			"Airborne":
				# Set the anim position in the Airborne animation
				var anim_position: float = ((-character_node.velocity.y / 18.0) + 0.5) / 2.0
				af_node.set_bs1d_value(anim_position, "Airborne")
			"Crouch":
				# Update crouch anim pos
				var destination: float = character_node.move_input.length()
				var current_value: float = af_node.get_bs1d_value("Crouch")
				var next_value: float = move_toward(current_value, destination, delta * 8)
				af_node.set_bs1d_value(next_value, "Crouch")
			"Climb":
				# Find climb node
				if not is_instance_valid(climb_node):
					climb_node = character_node.find_action("WallClimb")
				if is_instance_valid(climb_node):
					# Get velocity on wall (these are only the positive values)
					var velocity_destination = Vector2(character_node.get_horizontal_velocity(), character_node.get_up_velocity() * 3.33)
					# Apply direction to velocity direction
					var normal_move_input: Vector2 = climb_node.move_input.normalized()
					var non_0_move_input: Vector2 = normal_move_input
					if non_0_move_input.x == 0:
						non_0_move_input.x = 1
					if non_0_move_input.y == 0:
						non_0_move_input.y = 1
					velocity_destination *= normal_move_input.abs() / non_0_move_input
					velocity_destination /= 20
					af_node.set_bs2d_value(velocity_destination, "Climb")
					# Adjust animation speed
					var anim_speed: float = (velocity_destination * Vector2(2.0, 3.0)).length()
					anim_speed = max(anim_speed, 0.3)
					af_node.set_full_body_speed(anim_speed)
			"Roll":
				# Find roll node
				if not is_instance_valid(roll_node):
					roll_node = character_node.find_action("Roll")
				if is_instance_valid(roll_node):
					var timer_pos: float = roll_node.duration_timer.time_left / roll_node.duration_timer.wait_time
					# Flip timer_pos value from going 1.0 -> 0.0 to 0.0 -> 1.0
					timer_pos = abs(timer_pos - 1.0)
					# Set pos of anim
					af_node.set_blend_tree_seek(timer_pos, "Roll")
			"Pickup":
				if is_instance_valid(pickup_node):
					var timer_pos: float = pickup_node.drop_timer.time_left / pickup_node.drop_timer.wait_time
					# Flip timer_pos value from going 1.0 -> 0.0 to 0.0 -> 1.0
					timer_pos = abs(timer_pos - 1.0)
					# Set pos of anim
					af_node.set_blend_tree_seek(timer_pos, "Pickup")
			"Place":
				if is_instance_valid(pickup_node):
					var timer_pos: float = pickup_node.place_timer.time_left / pickup_node.place_timer.wait_time
					# Flip timer_pos value from going 1.0 -> 0.0 to 0.0 -> 1.0
					timer_pos = abs(timer_pos - 1.0)
					# Set pos of anim
					af_node.set_blend_tree_seek(timer_pos, "Place")
		
		# Set rotation
		character_node.rotate_w_move_input_node.rotation_destination = character_node.forward_direction

remote func init_animation():
	# Get and connect action nodes
	# Find pickup node
	if not is_instance_valid(pickup_node):
		pickup_node = character_node.find_action("Pickup")
	if is_instance_valid(pickup_node):
		# Connect state changed
		if not pickup_node.is_connected("sub_state_changed", self, "pickup_sub_state_changed"):
			pickup_node.connect("sub_state_changed", self, "pickup_sub_state_changed")
		if not pickup_node.is_connected("actor_released", self, "pickup_actor_released"):
			pickup_node.connect("actor_released", self, "pickup_actor_released")
	#
	# Full body
	var full_body_state: String = get_full_body_anim_based_on_state()
	af_node.anim_full_body_state = full_body_state
	# Upper body
	var upper_body_state: String = get_upper_body_anim_based_on_state()
	af_node.anim_upper_body_state = upper_body_state

func get_full_body_anim_based_on_state() -> String:
	var state_info: Dictionary = character_node.state_info
#	# When in pickup always walk
	if "PickupAction" in state_info:
#		match pickup_node.state:
		match state_info["PickupAction"].sub_state:
			pickup_node.PICKUP:
				return "Pickup"
			pickup_node.HOLD:
				return "Walk"
			pickup_node.PLACE:
				return "Place"
	# When Held
	if "PickupAction held" in state_info:
		return "Walk"
	# Crouch
	if "CrouchAction" in state_info:
		return "Crouch"
	# Wall Climb
	if "WallClimbAction" in state_info:
		return "Climb"
	# Roll
	if "RollAction" in state_info:
		return "Roll"
	# AirDash
	if "AirDashAction" in state_info:
		return "AirDash"
	
	if character_node.is_on_floor():
		return "Walk"
	else:
		return "Airborne"

func get_upper_body_anim_based_on_state() -> String:
	var state_info: Dictionary = character_node.state_info
#	# Pickup
#	if "PickupAction" in state_info or "PickupAction placing" in state_info:
#		return "Pickup"
	
	return ""

# ===== setget

func set_af_node(value: AnimalFriend):
	af_node = value

# ===== Signals

func _on_Character_left_floor():
	if is_instance_valid(af_node):
		init_animation()

func _on_Character_landed():
	if is_instance_valid(af_node):
		init_animation()

func _on_Character_state_changed(state: Dictionary):
	init_animation()

func full_body_state_changed(value: String, previous_value: String):
#	G.debug_print("%s %s" % [value, previous_value])
	# Reset anim speed
	af_node.anim_full_body_speed = 1.0
	# Air dash anim state
	if G.array_is_true([
		"AirDash" == previous_value,
		"AirDash" != value
	]):
		if value == "Crouch":
			pass
		else:
			af_node.play_anim_state("AirDash")
			# Go into next phase of animation on AirDash
			af_node.travel_in_state_machine("Release", "AirDash")
	# Exiting behavior
#	match previous_value:
#		"Walk":
#			# Reset anim speed
#			af_node.set_full_body_speed(1.0)

func upper_body_state_changed(value: String, previous_value: String):
	pass
#	G.debug_print("%s %s" % [value, previous_value])
	# Set upper body blend if there is a state
#	af_node.set_upper_body_blend(float(value != ""))

func pickup_sub_state_changed(state: int, old_state: int):
#	G.debug_print("pickup_sub_state_changed %s %s" % [state, old_state])
	match old_state:
		pickup_node.HOLD:
			reset_upper_body()
	match state:
		pickup_node.HOLD:
			af_node.set_upper_body_blend(1.0)
			af_node.anim_upper_body_state = "Hold"
			af_node.anim_full_body_state = "Walk"
			character_node.rotate_w_move_input_node.lean_into_rotation = false
			character_node.rotate_w_move_input_node.lean_destination = 0.0
		pickup_node.PICKUP:
			af_node.anim_full_body_state = "Pickup"
		pickup_node.PLACE:
			af_node.anim_full_body_state = "Place"

func pickup_actor_released():
	reset_upper_body()

func reset_upper_body():
		af_node.set_upper_body_blend(0.0)
		af_node.anim_upper_body_state = ""
		character_node.rotate_w_move_input_node.lean_into_rotation = true
