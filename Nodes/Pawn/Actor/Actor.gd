extends Pawn
class_name Actor
func get_class() -> String: return "Actor"

onready var actions_node: = $Actions

var velocity: = Vector3.ZERO
var previous_velocity: = Vector3.ZERO

var move_input: Vector2 = Vector2.ZERO

var actor_spawner = null

export var disable_physics_process: bool = false setget set_disable_physics_process
export var can_land: bool = true

export var base_gravity_value: float = 1.0

var gravity_multipliers: Dictionary = {}

export var terminal_velocity: float = 50

export var base_air_acceleration_multiplier: float = 0.5
var air_acceleration_multiplier: float = base_air_acceleration_multiplier

export var base_run_acceleration_value: float = 1.0
var run_acceleration_value: float = base_run_acceleration_value setget set_run_acceleration_value
export var base_run_acceleration_multiplier: float = 90.0
var run_acceleration_multiplier: float = base_run_acceleration_multiplier setget set_run_acceleration_multiplier
var run_acceleration: float = run_acceleration_value * run_acceleration_multiplier  # Needs to be calculated

export var base_max_run_speed: float = 22.0
var max_run_speed: float = base_max_run_speed

export var base_max_walk_speed: float = 5.0
var max_walk_speed: float = base_max_walk_speed

var max_speed_modifiers: Dictionary = {}

export var base_ground_friction: float = 1.0
var ground_friction_multipliers: Dictionary = {}

export var base_air_friction: float = 0.5
var air_friction_multipliers: Dictionary = {}

var sync_to_physics: bool = false setget set_sync_to_physics, get_sync_to_physics

# Grip is how much influence the move_input has on movement
# A character can have low friction and still come to a standstill when
# letting go of the move input because of how it tries to reach the destination
# speed.
export var base_ground_grip_value: float = 1.0
var ground_grip_modifiers: Dictionary = {}
export var base_air_grip_value: float = 1.0
var air_grip_modifiers: Dictionary = {}

export var weight: float = 1

export var default_wall_slide_angle: float = 0.78
onready var wall_slide_angle: float = default_wall_slide_angle
var is_pushing: bool = false
var is_pushing_actor: bool = false

var snap = Vector3.ZERO
var snap_normal_override: Vector3 = Vector3.ZERO
var snap_multiplier: float = 0
# Up according to floor
var up_direction: = Vector3.UP
# Down according to gravity
var gravity_direction: = Vector3.DOWN
var forward_direction: float = 0
var update_direction: bool = true
var apply_movement: bool = true

var state_info: Dictionary = {}

var intangibility_modifiers: Dictionary = {}
var invincibility_modifiers: Dictionary = {}

# Collision layer needs to be save when intangibility is set
var saved_collision_mask: int = -1
var saved_collision_layer: int = -1
var saved_collision_masks: Dictionary = {}
var saved_collision_layers: Dictionary = {}

signal landed
signal left_floor
signal pre_move_and_slide(velocity, delta)
signal physics_process
signal reset_state
signal state_changed(state)
signal action_added(action_node)
signal action_removed(action_node)

func _ready():
	set_disable_physics_process()

func _process(delta: float):
#	# ACCELERATION -----
	# What acceleration should be applied to the velocity
	var acceleration_2d: Vector2 = move_input.normalized() * run_acceleration
	# Get the ground velocity (The X and Z of velocity)
	var velocity_2d: Vector2 = Vector2(velocity.x, velocity.z)
	var acceleration_multiplier2: float = 1.0
	var friction: float = 50.0
	if is_on_floor():
		friction *= get_ground_friction()
		# Get snap
		snap = -get_floor_normal()
	else:
		acceleration_multiplier2 = air_acceleration_multiplier
		friction *= get_air_friction()
	var final_max_run_speed: float = max_run_speed * min(move_input.length(), 1.0)
	# Slow down by friction
	velocity_2d = velocity_2d.move_toward(Vector2.ZERO, friction * delta)
	# Move twords max_run_speed at a rate of run_acceration
	var move_input_to_move: Vector2 = move_input.normalized() * float(apply_movement)
	#
	var target_move: Vector2 = velocity_2d.move_toward(move_input_to_move * final_max_run_speed, (run_acceleration * acceleration_multiplier2) * delta)
	# grip
	var grip: float = 1.0
	if is_on_floor():
		grip = get_ground_grip()
	else:
		grip = get_air_grip()
	#
	velocity_2d = velocity_2d.linear_interpolate(target_move, clamp(grip, 0, 1))
#	velocity_2d = velocity_2d.move_toward(move_input_to_move * final_max_run_speed, (run_acceleration * acceleration_multiplier2) * delta)
	velocity = Vector3(velocity_2d.x, velocity.y, velocity_2d.y)
	# -----
	
	# Apply gravity, also remove gravity on floor
	var gravity_vec: Vector3 = -get_floor_normal()
	if not is_on_floor():
		gravity_vec = gravity_direction
	gravity_vec *= get_gravity()
	
	var v_velocity: float = (gravity_direction * velocity).length()
	# If gravity velocity is not more than the terminal velocity, apply gravity
	if v_velocity > -terminal_velocity:
		velocity += gravity_vec * delta
	
#	get_floor_velocity()
	if snap_normal_override.length() > 0:
		snap = -snap_normal_override
	if not can_land:
		snap = Vector3.ZERO
	snap *= snap_multiplier
	
	previous_velocity = velocity
	emit_signal("pre_move_and_slide", previous_velocity, delta)
	velocity = move_and_slide_with_defaults()
	
	# Re-enable snap when hitting floor also well as emit a landed signal
	if is_on_floor():
		# Once floor is hit
		if snap_multiplier != 1:
			snap_multiplier = 1
			emit_signal("landed")
	
	# Emit signal when leaving the floor
	if is_on_floor():
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		if not is_on_floor():
			snap_multiplier = 0
			up_direction = -gravity_direction
			emit_signal("left_floor")
	
	# Set y rotation
	if move_input != Vector2.ZERO:
		var move_input_rotation: float = get_rotation_from_vec2()
		if update_direction:
			forward_direction = move_input_rotation
	
	emit_signal("physics_process")

func move_and_slide_with_defaults(value: Vector3 = velocity) -> Vector3:
	if not sync_to_physics:
		return move_and_slide_with_snap(value, snap, up_direction, false, 4, wall_slide_angle)
	return velocity

func get_rotation_from_vec2(vec2: Vector2 = move_input) -> float:
	return (vec2.angle() * -1) + (PI / 2)

func get_vec3_from_rotation(rot: float = forward_direction) -> Vector3:
	return Vector3.FORWARD.rotated(up_direction, rot)

func pre_launch():
	snap_multiplier = 0
	snap *= snap_multiplier
	# If can jump, stop jumping
	var jump_action = find_action("Jump")
	if is_instance_valid(jump_action):
		jump_action.jumping = false

func post_launch():
	pass

func launch_add(launch_vector: Vector3):
	pre_launch()
	velocity += launch_vector
	post_launch()

func launch_set(launch_vector: Vector3):
	pre_launch()
	velocity = launch_vector
	post_launch()

# Overwrite velocity to launch_vector and only on axis given
func launch_set_on_axis(launch_vector: Vector3, axis: Vector3):
	pre_launch()
	velocity = launch_vector * axis
	post_launch()

# Overwrite the velocity on the axis
# The point of this is so if I want to overwrite an axis' velocity
# but not effect other axis.
func launch_overwrite(launch_vector: Vector3, axis: Vector3):
	pre_launch()
	# Remove axis velocity
	velocity -= velocity * axis
	# Add launch
	velocity += launch_vector
	post_launch()

#func launch_add_axis(axis: String, launch_force: float):
#	pre_launch()
#	velocity[axis] += launch_force
#	post_launch()
#
#func launch_set_axis(axis: String, launch_force: float):
#	pre_launch()
#	velocity[axis] = launch_force
#	post_launch()

func is_on_slope() -> bool:
	return (Vector3.DOWN.distance_to(get_floor_normal()) < 2 - 0.001) and get_floor_normal() != Vector3.ZERO

func get_wall_amount(normal: Vector3) -> float:
	return (normal * G.reverse_vec3(up_direction)).length()

func get_rotated_up_velocity(vel: Vector3 = velocity, up: Vector3 = up_direction) -> float:
	var up_velocity: Vector3 = up * vel
#	# TEMP this the rot_amount rotates it up even if I'm going down
#	# I'll work on this later
#	var rot_axis: Vector3 = vel.cross(up).normalized()
#	# Rotate if their a axis to rotate around
#	if rot_axis.is_normalized():
#		var rot_amount: float = acos(up.dot(vel.normalized()))
#		return up_velocity.rotated(rot_axis, rot_amount).y
	return up_velocity.y

func spawner_respawn():
	if is_instance_valid(actor_spawner):
		actor_spawner.respawn_actor()

func set_disable_physics_process(value: bool = disable_physics_process):
	disable_physics_process = value
	set_process(not disable_physics_process)

func move_actor_to(target_pos: Vector3, strength: float = 2500):
	var delta: float = get_physics_process_delta_time()
	var self_pos: Vector3 = global_transform.origin
	var move_vector: Vector3 = target_pos - self_pos
	move_and_slide(move_vector * delta * strength)

func get_horizontal() -> Vector3:
	return G.reverse_vec3(-gravity_direction)

func get_up_velocity() -> float:
	return (up_direction * velocity).length()

func get_horizontal_velocity() -> float:
	return (get_horizontal() * velocity).length()

func find_action(value) -> Node:
	if value is int:
		return find_action_from_int(value)
	if value is String:
		return find_action_from_id(value)
	return null

func find_action_from_id(action_id: String) -> Node:
	return actions_node.find_node(action_id, true, false)

func find_action_from_int(index: int) -> Node:
	if (actions_node.get_child_count() - 1) >= index:
		return actions_node.get_children()[index]
	return null

func press_action(value):
	var action_node: Node = find_action(value)
	if is_instance_valid(action_node):
		action_node.action_pressed()
	else:
		print("%s cannot press_action; The action_node \"%s\" cannot be found." % [name, value])

func release_action(value):
	var action_node: Node = find_action(value)
	if is_instance_valid(action_node):
		action_node.action_released()
	else:
		print("%s cannot release_action; The action_node \"%s\" cannot be found." % [name, value])

func rotate_to_forward_direction(forward: float = forward_direction):
	model_node.rotation.y = forward
	collision_shape.rotation.y = forward

func get_visual_forward_direction() -> float:
	return model_node.rotation.y

func is_intangible() -> bool:
	return intangibility_modifiers.size() > 0

func add_intangibility_value(key: String, value):
	intangibility_modifiers[key] = value
	set_intangibility()

func remove_intangibility_value(key: String):
	intangibility_modifiers.erase(key)
	set_intangibility()

#func set_intangibility(value: bool = is_intangible()):
#	if value:
#		if saved_collision_mask == -1:
#			# Remember collision
#			saved_collision_mask = collision_mask
#			saved_collision_layer = collision_layer
#			# Remove collision
#			collision_mask = 0
#			collision_layer = 0
#	else:
#		# Reload remembered collision
#		if saved_collision_mask != -1:
#			collision_mask = saved_collision_mask
#			collision_layer = saved_collision_layer
#			saved_collision_mask = -1
#			saved_collision_layer = -1

func set_intangibility(value: bool = is_intangible(), node: Node = self):
	# Set intangibility in node
	# A local path to character
	var node_path: String = get_path_to(node)
	# collision_mask
	if "collision_mask" in node:
		if value:
			if not node_path in saved_collision_masks:
				# Remember mask
				saved_collision_masks[node_path] = node.collision_mask
				# Clear mask
				node.collision_mask = 0
		else:
			if node_path in saved_collision_masks:
				# Reload remembered collision
				node.collision_mask = saved_collision_masks[node_path]
				# Clear memory of collision mask
				saved_collision_masks.erase(node_path)
	# collision_layer
	if "collision_layer" in node:
		if value:
			if not node_path in saved_collision_layers:
				# Remember mask
				saved_collision_layers[node_path] = node.collision_layer
				# Clear mask
				node.collision_layer = 0
		else:
			if node_path in saved_collision_layers:
				# Reload remembered collision
				node.collision_layer = saved_collision_layers[node_path]
				# Clear memory of collision mask
				saved_collision_layers.erase(node_path)
	
	# Set intangibility in children
	for child in node.get_children():
		set_intangibility(value, child)

func is_invincible() -> bool:
	return invincibility_modifiers.size() > 0

# ===== Set functions and calculation functions =====

func set_sync_to_physics(value: bool):
	sync_to_physics = value
	return set("motion/sync_to_physics", value)

func get_sync_to_physics() -> bool:
	return get("motion/sync_to_physics")

# == Gravity ==

func get_gravity() -> float:
	var gravity: float = base_gravity_value
	for key in gravity_multipliers.keys():
		gravity *= gravity_multipliers[key]
	return gravity * 100

# == run_acceleration

func set_run_acceleration_value(value: float):
	run_acceleration_value = value
	# Calculate
	calculate_run_acceleration()

func set_run_acceleration_multiplier(value: float):
	run_acceleration_multiplier = value
	# Calculate
	calculate_run_acceleration()

func calculate_run_acceleration():
	run_acceleration = run_acceleration_value * run_acceleration_multiplier
	
# == friction

func get_ground_friction():
	var ground_friction: float = base_ground_friction
	for key in ground_friction_multipliers.keys():
		ground_friction *= ground_friction_multipliers[key]
	return ground_friction

func get_air_friction():
	var air_friction: float = base_air_friction
	for key in air_friction_multipliers.keys():
		air_friction *= air_friction_multipliers[key]
	return air_friction

# ===== max speed

func calculate_max_speeds():
	var max_speed_names: Array = ["max_run_speed", "max_walk_speed"]
	for max_speed_name in max_speed_names:
		var base_max_speed: float = self["base_" + max_speed_name]
		var final_max_speed: float = base_max_speed
		for key in max_speed_modifiers.keys():
			var modifier: float = max_speed_modifiers[key]
			final_max_speed *= modifier
		self[max_speed_name] = final_max_speed

# ===== grip

func get_ground_grip() -> float:
	var grip: float = base_ground_grip_value
	for key in ground_grip_modifiers.keys():
		grip *= ground_grip_modifiers[key]
	return grip

func get_air_grip() -> float:
	var grip: float = base_air_grip_value
	for key in air_grip_modifiers.keys():
		grip *= air_grip_modifiers[key]
	return grip

# ===== State

# State serialization
# Position and action state
func get_movement_state() -> Dictionary:
	return {
		"translation" : global_transform.origin,
		"velocity" : velocity
	}

func set_movement_state(state: Dictionary):
	global_transform.origin = state.translation
	velocity = state.velocity

func get_state() -> Dictionary:
	return {
		"movement" : get_movement_state(),
		"forward_direction" : forward_direction,
		"move_input" : move_input,
		"state_info" : state_info,
		"action_status" : get_action_status()
	}

remote func set_state(state: Dictionary):
	# Movement
	set_movement_state(state.movement)
	# Forward Direction
	forward_direction = state.forward_direction
	rotate_to_forward_direction()
	# Move Input
	move_input = state.move_input
	# State info (Action state mostly)
	state_info = state.state_info
	init_state_info()
	# Action Status (What actions does the actor have?)
	set_actions_from_status(state.action_status)

# Example start_state state
#{
#	"state_start" : {
#		"node_path" : "PATH TO NODE THAT HAS METHOD",
#		"method" : "METHOD NAME",
#		"args" : "METHOD ARGS"
#	}
#}

func init_state_info():
	# Run state start on state
	for key in state_info.keys():
		var state = state_info[key]
		if state is Dictionary:
			if "state_start" in state:
				var state_start: Dictionary = state["state_start"]
				var node: Node = get_node(state_start.node_path)
				if is_instance_valid(node):
					if "args" in state_start:
						node.callv(state_start.method, state_start.args)
					else:
						node.call(state_start.method)

func add_state(key: String, state):
	state_info[key] = state
	state_changed()

func remove_state(key: String):
	if key in state_info:
		state_info.erase(key)
		state_changed()
#	else:
#		print("No state '%s' in state_info" % key)

func state_changed():
	emit_signal("state_changed", state_info)

func reset_state():
	velocity = Vector3.ZERO
	emit_signal("reset_state")

func is_state_active() -> bool:
	return state_info.keys().size() > 0

# Get status of actions
func get_action_status() -> Dictionary:
	var status: Dictionary = {}
	for child in actions_node.get_children():
		status[child.name] = child.get_status()
	return status

# Create actions from status
remote func set_actions_from_status(status: Dictionary):
	# Clear current actions
	clear_actions()
	# Wait until current actions have been cleared
	while actions_node.get_child_count() > 0:
		yield(get_tree(), "idle_frame")
	# Create new actions
	for action_key in status.keys():
		var action_status: Dictionary = status[action_key]
		add_action(action_key, action_status)

func add_action(action_id: String, status: Dictionary = {}):
	O3DP.create_action_from_status(action_id, status, actions_node)
	

func clear_actions():
#	for child in actions_node.get_children():
#		child.queue_free()
	pass

func reset_status():
	clear_actions()

# ===== Online

# For watching character translation and rotation to update when needed
var old_translation: = Vector3.ZERO
var old_move_input: = Vector2.ZERO
var old_forward_direction: float = 0.0
var update_network_movement: bool = true

func NetworkUpdate():
	# Make sure the character is local so it's not called from other clients or server
	if G.is_node_network_master(self):
		# Movement
		# set_movement if the character's translation is different than last
		if old_translation != global_transform.origin:
			if update_network_movement:
#				rpc_unreliable("set_movement", get_movement_state())
				O3DP.O.custom_rpc(self, "set_movement", [get_movement_state()], false)
			old_translation = global_transform.origin
		if old_move_input != move_input:
#			rpc_unreliable("set_move_input", move_input)
			O3DP.O.custom_rpc(self, "set_move_input", [move_input], false)
			old_move_input = move_input
		if old_forward_direction != forward_direction:
#			rpc_unreliable("set_forward_direction", forward_direction)
			O3DP.O.custom_rpc(self, "set_forward_direction", [forward_direction], false)
			old_forward_direction = forward_direction

remote func set_movement(state: Dictionary):
	global_transform.origin = state.translation
	velocity = state.velocity

remote func set_move_input(value: Vector2):
	move_input = value

remote func set_forward_direction(value: float):
	forward_direction = value
	rotate_to_forward_direction()
