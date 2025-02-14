extends Action
func get_class() -> String: return "CrouchAction"

export var max_speed: float = 60
# The minimum angle you start sliding at
export var min_angle: float = 0.25

func _physics_process(delta):
	# Only slide down slope when crouching and is on slope
	if pressed and actor_node.is_on_slope() and (get_class() in actor_node.state_info):
		# Get floor normal for calculating down slope
		var floor_normal: Vector3 = actor_node.get_floor_normal()
		var floor_tilt: float = floor_normal.distance_to(-actor_node.gravity_direction)
		if floor_tilt < min_angle:
			return
		var horizontal_velocity: Vector3 = actor_node.velocity * Vector3(1, 0, 1)
		# Make the rotation axis to point the floor_normal down the slope
		var rotate_axis: Vector3 = floor_normal.rotated(actor_node.gravity_direction, PI / 2)
		rotate_axis.y = 0
		# Axis has to be normalized otherwise "rotated" method doesn't work
		rotate_axis = -rotate_axis.normalized()
		# Make slide velocity from floor_normal rotated 90deg down
		var slide_velocity: Vector3 = floor_normal.rotated(rotate_axis, PI / 2) * (100 * floor_tilt)
		actor_node.velocity += slide_velocity * delta

func action_pressed():
	if not actor_node.is_state_active():
		add_default_state()
#		# Create crouch state in actor_node
#		actor_node.state_info[get_class()] = true
		# Slow the run acceleration value
		actor_node.max_run_speed = max_speed
		actor_node.run_acceleration_value = actor_node.run_acceleration_value / 10.0
		# Decrease the friction_value
		actor_node.ground_friction_multipliers[get_class()] = 0.0
		# Adjust wall slide angle
		actor_node.wall_slide_angle = 1
#		# Move camera if first person
#		var camera_node: Node = actor_node.player_node.camera_node
#		if is_instance_valid(camera_node):
#			if camera_node.camera_mode == camera_node.CAMERA_FP:
#				camera_node.translation = Vector3.ZERO
		pressed_default_rpc()
	.action_pressed()

func action_released():
	if get_class() in actor_node.state_info:
		released_default_rpc()
#		# Remove crouch state in actor_node
#		actor_node.state_info.erase(get_class())
		# Revert the changes to run acceleration value and friction_value
		actor_node.run_acceleration_value = actor_node.base_run_acceleration_value
		actor_node.max_run_speed = actor_node.base_max_run_speed
		actor_node.ground_friction_multipliers.erase(get_class())
		# Return animation to normal
		actor_node.animation_node.manual_anim_state = ""
		# Adjust wall slide angle
		actor_node.wall_slide_angle = actor_node.default_wall_slide_angle
		# Move camera if first person
#		var camera_node: Node = actor_node.player_node.camera_node
#		if is_instance_valid(camera_node):
#			if camera_node.camera_mode == camera_node.CAMERA_FP:
#				camera_node.translation = camera_node.fp_camera_translation
		remove_default_state()
	.action_released()

func on_reset_actor_node():
	action_released()
