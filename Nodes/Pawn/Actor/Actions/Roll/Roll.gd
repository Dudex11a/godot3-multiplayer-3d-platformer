extends Action
func get_class() -> String: return "RollAction"

onready var duration_timer: = $Duration

export var roll_strength: float = 50.0
export var speed_curve: Curve
export var turn_speed: float = 3.0
var forward_vector: = Vector3.ZERO

func action_pressed():
	if not actor_node.is_state_active() and actor_node.is_on_floor():
		pressed_default_rpc()
		start_roll()
	.action_pressed()

func action_released():
	.action_released()

func start_roll():
	actor_node.add_state(get_class(), true)
	forward_vector = -actor_node.get_vec3_from_rotation()
	duration_timer.start()
	while is_rolling():
		while_roll()
		yield(get_tree(), "physics_frame")
	self.progression = 100

func end_roll():
	actor_node.remove_state(get_class())
	duration_timer.stop()
	self.progression = 100

func while_roll():
	var delta: float = get_physics_process_delta_time()
	var position_in_duration: float = 0.0
	if not duration_timer.is_stopped():
		var time_elapsed: float = duration_timer.wait_time - duration_timer.time_left
		position_in_duration = time_elapsed / duration_timer.wait_time
		# Progression
		var normal_time_elapsed: float = time_elapsed / duration_timer.wait_time
		self.progression = int(normal_time_elapsed * 100)
	var current_strength: float = speed_curve.interpolate(position_in_duration)
	# Adjust forward vector
	var forward_dir: Vector3 = -actor_node.get_vec3_from_rotation()
	# Rotate forward vector according to slope
	if actor_node.is_on_floor():
		var axis: Vector3 = actor_node.get_floor_normal().cross(forward_dir).normalized()
#		var rot: float = abs(actor_node.up_direction.dot(actor_node.get_floor_normal()) - 1.0)
		var rot: float = forward_dir.dot(actor_node.get_floor_normal())
		forward_dir = forward_dir.rotated(axis, rot)
	forward_vector = forward_vector.move_toward(forward_dir, delta * turn_speed)
	var forward_velocity: Vector3 = forward_vector * current_strength * roll_strength
	actor_node.velocity = lerp(actor_node.velocity, forward_velocity, current_strength)

func _on_Duration_timeout():
	end_roll()

func Jump_pressed(action: Action):
	if is_rolling():
		end_roll()
		action.jump_launch()

func Crouch_pressed(action: Action):
	if is_rolling():
		end_roll()
		action.action_pressed()

func is_rolling() -> bool:
	return not duration_timer.is_stopped()
