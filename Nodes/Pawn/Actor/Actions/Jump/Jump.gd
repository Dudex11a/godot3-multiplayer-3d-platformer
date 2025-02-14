extends Action
func get_class() -> String: return "JumpAction"

onready var coyote_timer: = $CoyoteTime

# The velocity that is stored before leaving the platform.
# This will be used to set the 
var coyote_velocity: Vector3 = Vector3.ZERO

export var up_velocity: float = 33.0

var jumping: bool = false
var floor_check: bool = false

func _ready():
	actor_node.connect("landed", self, "landed")
	actor_node.connect("left_floor", self, "left_floor")

func action_pressed():
	pressed_default_rpc()
	jump_action()
	.action_pressed()
	
func action_released():
	if actor_node.velocity.y > 0 and jumping:
		jumping = false
		actor_node.velocity.y /= 4
	.action_released()

remote func jump_action():
	if initial_jump_check():
		# Actually jump
		jump_launch()
	# Pickup action related
	if "PickupAction held" in actor_node.state_info:
		var pickup_action = get_node(actor_node.state_info["PickupAction held"])
		if is_instance_valid(pickup_action):
			actor_node.velocity = pickup_action.actor_node.velocity
			pickup_action.release_actor()
			jump_launch()

func jump_launch():
	# Launch actor_node
	var launch_velocity: Vector3 = -actor_node.gravity_direction * up_velocity
	if not coyote_timer.is_stopped() and not actor_node.is_on_floor():
		actor_node.launch_set(G.lerp_vec3_w_vec3(coyote_velocity, launch_velocity, actor_node.up_direction))
	else:
		actor_node.launch_add(launch_velocity)
	jumping = true
	yield(actor_node, "physics_process")
	yield(actor_node, "physics_process")
	yield(actor_node, "physics_process")
	coyote_timer.stop()
	self.progression = 0

func landed():
	jumping = false
	self.progression = 100
	coyote_velocity = Vector3.ZERO

# When leave floor trigger coyote time
func left_floor():
	# Store velocity
	coyote_velocity = actor_node.velocity
	# Start timer for coyote timer
	coyote_timer.start()

func is_floor_or_coyote() -> bool:
	return actor_node.is_on_floor() or not coyote_timer.is_stopped()

func initial_jump_check() -> bool:
	var checks: Array = [
		not jumping,
		is_floor_or_coyote(),
		not actor_node.is_state_active() or "CrouchAction" in actor_node.state_info or "PickupAction" in actor_node.state_info
	]
	return G.array_is_true(checks)

func AirDash_pressed(action: Action):
	pressed = false

func get_status() -> Dictionary:
	var status: Dictionary = .get_status()
	status.up_velocity = up_velocity
	return status

#func set_status(status: Dictionary):
#	up_velocity = float(status.up_velocity)
#	.set_status(status)

# ===== Signals

func _on_CoyoteTime_timeout():
	self.progression = 0
