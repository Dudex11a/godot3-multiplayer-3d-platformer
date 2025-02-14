extends Action
func get_class() -> String: return "WallClimbAction"

onready var raycasts_node: = $Raycasts
onready var top_raycast: = $Raycasts/Top
onready var mantle_raycast: = $Raycasts/Mantle
onready var bottom_raycast: = $Raycasts/Bottom
onready var down_raycast: = $Raycasts/Down

onready var meter_sprite: = $Meter
onready var meter_viewport: = meter_sprite.get_node("Viewport")
onready var meter_bar: = meter_viewport.get_node("ProgressBar")
onready var meter_anim_player: = meter_sprite.get_node("AnimationPlayer")
export var meter_alpha: float = 0.0 setget set_meter_alpha
onready var show_meter: bool = G.is_node_network_master(self, false)
var update_meter_sprite: bool = true

# Keep in mind this only applies to the y
const wall_friction_value: = Vector2(70.0, 40.0)
#export var wall_acceleration_value: = Vector2(200.0, 150.0)
export var wall_acceleration_value: = Vector2(65.0, 200.0)
export var wall_max_speed_value: = Vector2(20.0, 6.0)
var wall_velocity: = Vector3.ZERO

var is_climbing: bool = false setget set_is_climbing
# If actor_node will mantle if the situation calls for it
var will_mantle: bool = false
#var can_climb: bool = true

var move_input: = Vector2.ZERO
var crouch_pressed: bool = false

var wall_stamina: float = 1 setget set_wall_stamina

func _ready():
	# Set viewport background to invisible
	meter_viewport.transparent_bg = true
	# Duplicate material so other meters don't copy eachother
	meter_sprite.material_override = meter_sprite.material_override.duplicate()
	# Wait for actor_node to exist
	while not is_instance_valid(actor_node):
		yield(get_tree(), "idle_frame")
	# Signals
	actor_node.connect("landed", self, "landed")
	

func _physics_process(delta: float):
	# Rotate raycasts
	if is_instance_valid(actor_node):
		raycasts_node.rotation.y = actor_node.forward_direction - (PI / 2)
	# Check for wall connection
	if initial_wall_check():
		set_is_climbing(true)

func initial_wall_check() -> bool:
	# All the checks
	if is_instance_valid(actor_node):
		return G.array_is_true([
#			actor_node.is_on_wall(),
			is_either_raycast_colliding(),
			is_collider_climbable(),
			not is_climbing,
			not actor_node.is_on_floor(),
			not actor_node.is_state_active(),
			not crouch_pressed,
			wall_stamina > 0 or is_only_mantle_and_bottom_raycast_colliding(),
			# Only grab wall when start falling (basically)
			actor_node.get_rotated_up_velocity() < actor_node.get_rotated_up_velocity(wall_velocity) + 4,
			not down_raycast.is_colliding(),
			not is_only_top_raycast_colliding()
		])
	return false

func is_either_raycast_colliding() -> bool:
	return top_raycast.is_colliding() or bottom_raycast.is_colliding()

func is_only_bottom_raycast_colliding() -> bool:
	return not top_raycast.is_colliding() and not mantle_raycast.is_colliding() and bottom_raycast.is_colliding()

func is_only_mantle_and_bottom_raycast_colliding() -> bool:
	return not top_raycast.is_colliding() and mantle_raycast.is_colliding() and bottom_raycast.is_colliding()

func is_only_top_raycast_colliding() -> bool:
	return top_raycast.is_colliding() and not mantle_raycast.is_colliding() and not bottom_raycast.is_colliding()

func get_raycast_collider() -> Node:
	for raycast in [top_raycast, bottom_raycast]:
		if raycast.is_colliding():
			return raycast.get_collider()
	return null

func is_collider_climbable() -> bool:
	return not get_raycast_collider() is Character

remote func set_is_climbing(value: bool, needs_network_master: bool = true):
	# Network
	# Return if needs to be network master and it's not network master then exit
	if needs_network_master and not G.is_node_network_master(self, false):
		return
	# RPC if network master
	if G.is_node_network_master(self):
#		rpc("set_is_climbing", value, false)
		O3DP.O.custom_rpc(self, "set_is_climbing", [value, false])
	#
	is_climbing = value
	# Init actor_node if not set
	# I need to call this here because "set_is_climbing" can be called before
	# the actor_node is initialized
	init_actor_node()
	actor_node.update_direction = not value
	if is_climbing:
		# When true
		# Create state
		actor_node.add_state(get_class(), {
			"state_start" : {
				"node_path" : get_path(),
				"method" : "set_is_climbing",
				"args" : [true, false]
			}})
		# Wall stamina meter visible
		update_meter_sprite = true
		if not meter_alpha >= 1:
			meter_anim_player.stop()
			meter_anim_player.play("FadeIn")
		# Disable gravity and movement and friction
#		actor_node.gravity_value = 0
		actor_node.gravity_multipliers[get_class()] = 0
		actor_node.add_disable_move_input(get_class())
		actor_node.air_friction_multipliers[get_class()] = 0.0
		# Face wall
		var wall_normal: Vector3 = get_wall_normal()
		var actor_node_direction: Vector3 = -wall_normal
		# Stop virticle velocity when grabbing edge
		actor_node.velocity = actor_node.velocity * actor_node.get_horizontal()
		#
		while is_either_raycast_colliding() and is_climbing:
			while_on_wall()
			yield(get_tree(), "idle_frame")
		# Mantle if situation calls for it
		set_is_climbing(false)
		if will_mantle:
			mantle()
	else:
		# When false
		# Remove state
		actor_node.remove_state(get_class())
		# Enable gravity and movement and friction
#		actor_node.gravity_value = actor_node.base_gravity_value
		if get_class() in actor_node.gravity_multipliers:
			actor_node.gravity_multipliers.erase(get_class())
		actor_node.remove_disable_move_input(get_class())
		actor_node.air_friction_multipliers.erase(get_class())
		# Reset Air Dash
		var air_dash_action = actor_node.find_action("AirDash")
		if is_instance_valid(air_dash_action):
			air_dash_action.can_dash = true
		# Reset snap override since we're no longer snaping to a wall
		actor_node.snap_normal_override = Vector3.ZERO
		move_input = Vector2.ZERO

func set_meter_alpha(value: float):
	meter_alpha = value
	if show_meter:
		meter_sprite.modulate.a = value
		meter_sprite.material_override.albedo_color.a = value

# Jump off wall on action pressed
func action_pressed():
	if is_climbing:
		set_is_climbing(false)
		# Start he jmup velocity as the wall velocity.
		# I devide by delta here because the wall velocity has already
		# been multiplied by delta?
		var jump_velocity: Vector3 = wall_velocity / get_process_delta_time()
		# Up velocity
		jump_velocity += actor_node.up_direction * 30
		# Horizontal velocity
		jump_velocity += actor_node.get_vec3_from_rotation() * 18
		# Rotate actor_node to face oppisite direction
		actor_node.forward_direction += PI
		# Remove y velocity
		actor_node.velocity = G.reverse_vec3(actor_node.up_direction) * actor_node.velocity
		actor_node.launch_add(jump_velocity)
#		# Remove some wall stamina
#		var wall_stamina_used: float = 0.1
#		set_wall_stamina(max(0, wall_stamina - wall_stamina_used))
		yield(get_tree(), "physics_frame")
#		can_climb = true
	.action_pressed()

func while_on_wall():
	will_mantle = is_only_bottom_raycast_colliding() and move_input.y > 0.05
	# Abort wall behavior
	if actor_node.is_on_floor():
		reset_stamina()
		set_is_climbing(false)
		return
	if not is_either_raycast_colliding() or will_mantle or is_only_top_raycast_colliding():
		set_is_climbing(false)
		return
	# What to do on wall
	# Move toword wall to get collision data
	var collision: KinematicCollision = collide_with_wall()
	if is_instance_valid(collision):
		var collider = collision.collider
		# Snap to wall
		var normal: Vector3 = collision.normal
		actor_node.snap_normal_override = collision.normal
		# actor_node forward_direction to wall normal
		var direction: float = actor_node.get_rotation_from_vec2(-Vector2(normal.x, normal.z))
		actor_node.forward_direction = direction
		# Apply collider travel
		var collider_travel: Vector3 = Vector3.ZERO
		if collider is KinematicBody:
			collider_travel = collider.global_transform.origin
			yield(get_tree(), "idle_frame")
			collider_travel -= collider.global_transform.origin
			collider_travel *= -1
		actor_node.translation += collider_travel
		wall_velocity = collider_travel
		# Move on wall
		# Input
		var forward_strength: float = actor_node.controller_forward_input
		var back_strength: float = actor_node.controller_back_input
		var right_strength: float = actor_node.controller_right_input
		var left_strength: float = actor_node.controller_left_input
		var y_strength: float = forward_strength - back_strength
		var x_strength: float = right_strength - left_strength
		var suggested_input: = Vector2(x_strength, y_strength)
		
		# Rotate suggested_input based on actor_node direction
		var camera_node = actor_node.player_node.camera_node
		if is_instance_valid(camera_node):
			# Camera context
			suggested_input = suggested_input.rotated(camera_node.rotation.y)
			# Wall / actor_node context
			suggested_input = suggested_input.rotated(-actor_node.forward_direction)
			#
			suggested_input = suggested_input.rotated(PI)
		move_input = suggested_input
		# Vertical Velocity
		var normalized_y_strength: float = (move_input.y + 1) / 2
		var up_rotation_axis: Vector3 = actor_node.up_direction.cross(normal).normalized()
		var up_direction: Vector3 = normal.rotated(up_rotation_axis, PI / 2)
		var down_direction: Vector3 = normal.rotated(up_rotation_axis, -PI / 2)
		var y_velocity_influence: Vector3 = up_direction.linear_interpolate(down_direction, normalized_y_strength)
		var y_velocity_destination: Vector3 = wall_max_speed_value.y * y_velocity_influence
		# Horzontal Velocity
		var normalized_x_strength: float = (move_input.x + 1) / 2
		var right_direction: Vector3 = normal.rotated(up_direction, -PI / 2)
		var left_direction: Vector3 = normal.rotated(up_direction, PI / 2)
		var x_velocity_influence: Vector3 = left_direction.linear_interpolate(right_direction, normalized_x_strength)
		var x_velocity_destination: Vector3 = wall_max_speed_value.x * x_velocity_influence
		# Apply Velocity
		var strength: float = min(1.0, forward_strength + back_strength + right_strength + left_strength)
#		var target_velocity: Vector3 = y_velocity_destination + x_velocity_destination
		var delta: float = get_physics_process_delta_time()
		# Horizontal velocity
		var current_horizontal_velocity: Vector3 = actor_node.get_horizontal() * actor_node.velocity
		var next_horizonal_velocity_position: Vector3 = current_horizontal_velocity.move_toward(
			x_velocity_destination,
			abs(suggested_input.x) * wall_acceleration_value.x * delta)
		# Y FRICTION If not too much input, apply friction
		if x_velocity_influence.distance_to(Vector3.ZERO) < 0.3:
			next_horizonal_velocity_position = next_horizonal_velocity_position.move_toward(Vector3.ZERO, wall_friction_value.x * delta)
		# Verticle velocity
		var current_verticle_velocity: Vector3 = actor_node.up_direction * actor_node.velocity
		var next_verticle_velocity_position: Vector3 = current_verticle_velocity.move_toward(
			y_velocity_destination,
			abs(suggested_input.y) * wall_acceleration_value.y * delta)
		# Y FRICTION If not too much input, apply friction
		if y_velocity_influence.distance_to(Vector3.ZERO) < 0.3:
			next_verticle_velocity_position = next_verticle_velocity_position.move_toward(Vector3.ZERO, wall_friction_value.y * delta)
		# Apply
		actor_node.velocity = next_horizonal_velocity_position + next_verticle_velocity_position
		# Only reduce stamina if not on edge
		if top_raycast.is_colliding():
			# Idle reduce wall stamina
			set_wall_stamina(wall_stamina - (delta / 20))
			# Cimbing reduce wall stamina
			# Walk horizontally takes less stamina than climbing wall
			var modified_velocity: Vector3 = actor_node.velocity / 100
			# This will make the up_direction require 5x as much stamina
			modified_velocity *= (actor_node.up_direction * 5) + actor_node.get_horizontal()
			var stamina_decrease: float = modified_velocity.length()
			set_wall_stamina(wall_stamina - (delta * stamina_decrease))
		# Fall off wall if out of stamina
		if wall_stamina <= 0 and not is_only_mantle_and_bottom_raycast_colliding():
			set_is_climbing(false)
		# Meter visual
		if update_meter_sprite:
			var meter_texture: Texture = meter_viewport.get_texture()
			meter_sprite.texture = meter_texture
			meter_sprite.material_override.albedo_texture = meter_texture

func mantle():
	var modified_wall_velocity: Vector3 = wall_velocity / get_process_delta_time()
	var up_mantle_velocity: Vector3 = actor_node.up_direction * 20
	up_mantle_velocity += modified_wall_velocity
	# Pull up
	actor_node.launch_set(up_mantle_velocity)
	# Forward velocity
	var forward_mantle_velocity: Vector3 = -actor_node.get_vec3_from_rotation() * 5
#	forward_mantle_velocity += modified_wall_velocity
	# Wait a moment for pulled above edge
	yield(get_tree().create_timer(0.05), "timeout")
	# Pull up
	actor_node.launch_add(forward_mantle_velocity)
	

func Crouch_pressed(action: Action):
	crouch_pressed = true
	if is_climbing:
		set_is_climbing(false)

func Crouch_released(action: Action):
	crouch_pressed = false

#func AirDash_released(action: Action):
#	# IF JUST DASHED
#	if action.can_dash:
#		# Reduce stamina based on count
#		self.wall_stamina -= action.air_dash_count * 0.25

func landed():
	wall_velocity = Vector3.ZERO
	update_meter_sprite = false
	reset_stamina()
	if is_climbing:
		set_is_climbing(false)
	for i in range(5):
		yield(get_tree(), "physics_frame")

func reset_stamina():
	# Reset wall stamina
	set_wall_stamina(1)
	# Fade out meter
	if meter_alpha != 0:
		meter_anim_player.stop()
		meter_anim_player.play("FadeOut")

#func left_floor():
#	can_climb = true

func get_wall_normal() -> Vector3:
	if is_either_raycast_colliding():
		if bottom_raycast.is_colliding():
			return bottom_raycast.get_collision_normal()
		if top_raycast.is_colliding():
			return top_raycast.get_collision_normal()
	return Vector3.ZERO

func set_wall_stamina(value: float):
	wall_stamina = value
	if is_instance_valid(meter_bar):
		meter_bar.value = wall_stamina * 100
	# Progression
	self.progression = int(wall_stamina * 100)

func collide_with_wall() -> KinematicCollision:
	return actor_node.move_and_collide(-get_wall_normal() * get_physics_process_delta_time() * 10)

func on_reset_actor_node():
	if is_climbing:
		self.is_climbing = false
		
# ===== Online

# For watching WallClimb specific move_input
# This is mainly for animation reasons
var old_move_input: = Vector2.ZERO

func NetworkUpdate():
	# Make sure the actor_node is local so it's not called from other clients or server
	if G.is_node_network_master(self):
		if old_move_input != move_input:
#			rpc("set_move_input", move_input)
			O3DP.O.custom_rpc(self, "set_move_input", [move_input])
			old_move_input = move_input

remote func set_move_input(value: Vector2):
	move_input = value
