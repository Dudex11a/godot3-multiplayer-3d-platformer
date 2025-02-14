extends Action
func get_class() -> String: return "AirDashAction"

onready var hold_timer: = $Hold

var is_holding: bool = false
var can_dash: bool = true setget set_can_dash
var air_dash_count: int = 0

export var up_power: float = 24.0
export var forward_power: float = 30.0
export var v_friction: float = 9.0

signal start_dash_end

func _ready():
	# Wait for actor_node to exist
	while not is_instance_valid(actor_node):
		yield(get_tree(), "idle_frame")
	actor_node.connect("landed", self, "landed")

func action_pressed():
	if not actor_node.is_on_floor() and not actor_node.is_state_active() and can_dash:
		start_dash()
		pressed_default_rpc()
	.action_pressed()

func action_released():
	if is_holding:
		cancel_and_launch()
		released_default_rpc()
	.action_released()

func dash_launch():
	# Launch actor_node up and in direction facing
	# Forward velocity
	var forward_vector: Vector3 = actor_node.get_forward_vector()
	var forward_velocity: Vector3 = forward_vector * forward_power
	# Apply horizonal velocity (additive)
	actor_node.launch_add(forward_velocity)
	# UP VELOCITY USED
	# Apply verticle velocity (set)
	actor_node.velocity.y = up_power
	

func start_dash():
	# Stop in air
	actor_node.air_friction_multipliers[get_class()] = 10
	actor_node.air_acceleration_multiplier = 0
#	actor_node.gravity_value = 0
	actor_node.gravity_multipliers[get_class()] = 0
	#
	actor_node.add_state(get_class(), true)
	#
	hold_timer.start()
	is_holding = true
	while not hold_timer.is_stopped():
		while_dash()
		yield(get_tree(), "physics_frame")

func cancel_dash():
	# Stop hold_timer
	hold_timer.stop()
	# Reset air mobility
	actor_node.air_friction_multipliers.erase(get_class())
	actor_node.air_acceleration_multiplier = actor_node.base_air_acceleration_multiplier
#	actor_node.gravity_value = actor_node.base_gravity_value
	if get_class() in actor_node.gravity_multipliers:
		actor_node.gravity_multipliers.erase(get_class())
		
	actor_node.remove_state(get_class())
	# Adjust WallClimb stamina if has WallClimb
	var wall_climb_action = actor_node.find_action("WallClimb")
	if is_instance_valid(wall_climb_action) and air_dash_count > 0:
		wall_climb_action.wall_stamina -= 0.50
	#
	self.can_dash = false
	air_dash_count += 1
	#
	is_holding = false

func while_dash():
	# Custom verticle friction
	var up_weight: Vector3 = actor_node.up_direction * v_friction * get_physics_process_delta_time()
	actor_node.velocity = G.lerp_vec3_w_vec3(actor_node.velocity, Vector3.ZERO, up_weight)

func landed():
	# Cancel dash if is holding
	if is_holding:
		cancel_dash()
	# This needs to be done after cancel dash so can_dash isn't set back to false
	self.can_dash = true
	air_dash_count = 0

func cancel_and_launch():
		cancel_dash()
		dash_launch()

func Crouch_pressed(_action: Action):
	if not hold_timer.is_stopped():
		cancel_dash()
		# Fast fall in air
		if not actor_node.is_on_floor():
			actor_node.velocity = (-actor_node.up_direction * (actor_node.terminal_velocity))

func _on_HoldTime_timeout():
	if is_holding:
		cancel_and_launch()

# ===== setget

func set_can_dash(value: bool):
	can_dash = value
	self.progression = int(value) * 100
