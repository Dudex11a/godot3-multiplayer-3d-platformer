extends Action
func get_class() -> String: return "PickupAction"

onready var actor_raycast: = $ActorRayCast
onready var pickup_box_node: = $PickupBox
onready var height_measure_node: = $HeightMeasure
onready var hm_top_raycast: = height_measure_node.get_node("TopRayCast")
onready var hm_bottom_raycast: = height_measure_node.get_node("BottomRayCast")
onready var place_timer: = $PlaceTimer
onready var drop_timer: = $DropTimer

export var throw_velocity: = Vector2(15, 10)

var picked_up_actor: Actor = null
var actor_height: float = 2.0
const pick_up_padding: float = 1.4
var velocity_offset: = Vector3.ZERO
var update_actor_position: bool = false
var move_pickup_w_actor: bool = false

enum {
	PICKUP,
	HOLD,
	PLACE,
	THROW
}
#var state: int = PICKUP setget set_state
signal sub_state_changed(new_state, old_state)
signal actor_released

func _process(delta: float):
	# Rotate pickup box
	G.rotate_around(pickup_box_node, Vector3.ZERO, actor_node.up_direction, -actor_node.forward_direction)
	if move_pickup_w_actor:
		move_pick_up_w_actor_node()

func action_pressed():
	if is_instance_valid(picked_up_actor):
		throw_actor()
	else:
		# Pickup
		for body in pickup_box_node.get_overlapping_bodies():
			if body is Actor and body != actor_node:
				if can_pickup(body):
					pickup_actor(body.get_path())
	.action_pressed()

func action_released():
	.action_released()

func can_pickup(body: Actor) -> bool:
	return G.array_is_true([
		not is_instance_valid(picked_up_actor),
		not get_held_state_name() in body.state_info,
		not "WallClimbAction" in actor_node.state_info
	])

remote func pickup_actor(actor_path: NodePath):
	# Network
	if G.is_node_network_master(get_player_node()):
#		rpc("pickup_actor", actor_path)
		O3DP.O.custom_rpc(self, "pickup_actor", [actor_path])
	var actor: Actor = get_node(actor_path)
	actor_height = measure_node_height(actor) + pick_up_padding
	picked_up_actor = actor
	# Set network master to actor_node holding host
	picked_up_actor.update_network_movement = false
#	picked_up_actor.disable_physics_process = true
#	picked_up_actor.apply_velocity = false
	# Change actor to sync with physics
	picked_up_actor.sync_to_physics = true
	# Change raycast collision
	actor_raycast.collision_mask = picked_up_actor.collision_layer
	# Set intangibility on BounceBox
	if "bounce_box_node" in actor_node:
		actor_node.set_intangibility(true, actor_node.bounce_box_node)
	# Start timer
	start_drop_timer()
	# Signals
	move_pickup_w_actor = true
	actor_node.connect("pre_move_and_slide", self, "move_pick_up_w_actor_node")
	update_actor_position = true
	# Add state to actor_node
	actor_node.add_state(get_class(), {
		"state_start" : {
			"node_path" : get_path(),
			"method" : "pickup_actor",
			"args" : [actor_path]
		},
		"sub_state" : PICKUP
	})
	set_sub_state(PICKUP)
	# Add state to picked_up_actor
	picked_up_actor.add_state(get_held_state_name(), get_path())

remote func release_actor():
	if is_instance_valid(picked_up_actor):
		picked_up_actor.sync_to_physics = false
#		picked_up_actor.disable_physics_process = false
#		picked_up_actor.apply_velocity = true
		move_pickup_w_actor = false
		actor_node.disconnect("pre_move_and_slide", self, "move_pick_up_w_actor_node")
		# Remove actor_node state
		actor_node.remove_state(get_class())
		# Add state to picked_up_actor
		picked_up_actor.remove_state(get_held_state_name())
		update_actor_position = false
		# Set network master to host
		picked_up_actor.update_network_movement = true
		picked_up_actor = null
		emit_signal("actor_released")
		# Set intangibility on BounceBox after waiting so
		# the thrown actor doesn't immediatly bounce off
		yield(get_tree().create_timer(0.3), "timeout")
		if "bounce_box_node" in actor_node:
			actor_node.set_intangibility(false, actor_node.bounce_box_node)
		# Re-adjust actor_raycast to default pos
#		actor_raycast.translation = Vector3.ZERO

remote func throw_actor():
	if is_instance_valid(picked_up_actor) and not get_is_placing():
		# Network
		if G.is_node_network_master(get_player_node()):
#			rpc("throw_actor")
			O3DP.O.custom_rpc(self, "throw_actor")
		set_sub_state(THROW)
		actor_node.state_info[get_class()]
		var char_vel: Vector3 = actor_node.velocity
		var hor_vel: Vector3 = actor_node.get_forward_vector() * throw_velocity.x
		var vir_vel: Vector3 = actor_node.up_direction * throw_velocity.y
		picked_up_actor.launch_set(char_vel + hor_vel + vir_vel)
		release_actor()

remote func place_actor():
	if is_instance_valid(picked_up_actor) and not get_is_placing():
		# Network
		if G.is_node_network_master(get_player_node()):
#			rpc("place_actor")
			O3DP.O.custom_rpc(self, "place_actor")
		set_sub_state(PLACE)
		place_timer.start()
		update_actor_position = false
		actor_node.add_state(get_placing_state_name(), true)
		# Sync to physics before moving the object with move_and_slide
		picked_up_actor.sync_to_physics = false
		while not place_timer.is_stopped():
			picked_up_actor.move_actor_to(get_in_front_pos())
			yield(actor_node, "physics_process")
		actor_node.remove_state(get_placing_state_name())
		picked_up_actor.velocity = actor_node.velocity
		release_actor()

func measure_node_height(node: Actor) -> float:
	var height: float = 2.0
	var previous_node_position = node.global_transform.origin
	# Adjust node positions to be location off the general plane of existance
	height_measure_node.global_transform.origin = previous_node_position
	# Set the node to the collision layer that the height measures on
	node.set_collision_layer_bit(31, true)
	# If both raycast are colliding get the difference and that's the height
	hm_top_raycast.force_raycast_update()
	hm_bottom_raycast.force_raycast_update()
	if hm_top_raycast.is_colliding() and hm_bottom_raycast.is_colliding():
		height = hm_top_raycast.get_collision_point().y - hm_bottom_raycast.get_collision_point().y
	# Disable the height measure collision
	node.set_collision_layer_bit(31, false)
	return height

func move_pick_up_w_actor_node(velocity: Vector3 = actor_node.velocity, delta: float = get_process_delta_time()):
	var holder_pos: Vector3 = actor_node.global_transform.origin + (actor_node.up_direction * (actor_height / 2)) + (actor_node.up_direction * pick_up_padding)
	if update_actor_position and is_instance_valid(picked_up_actor):
		# Add velocity to position, otherwise it lags behind
		holder_pos += velocity * delta
		picked_up_actor.velocity = velocity
		picked_up_actor.global_transform.origin = holder_pos
		# Rotate with actor_node if not another actor_node
		if picked_up_actor.get_class() != "actor_node":
			actor_node.rotate_w_move_input_node
			picked_up_actor.forward_direction = actor_node.get_visual_forward_direction()
			picked_up_actor.rotate_to_forward_direction()
		# Adjust actor raycast w/ velocity
#		actor_raycast.translation = velocity
		# Check raycast collision
		if actor_raycast.get_collider() != picked_up_actor:
			if drop_timer.is_stopped():
				start_drop_timer()

#func move_actor_to(target_pos: Vector3):
#	var delta: float = picked_up_actor.get_physics_process_delta_time()
#	var holded_pos: Vector3 = picked_up_actor.global_transform.origin
#	var move_vector: Vector3 = target_pos - holded_pos
#	picked_up_actor.move_and_slide(move_vector * delta * 2500)

func get_state() -> Dictionary:
	if get_class() in actor_node.state_info:
		return actor_node.state_info[get_class()]
	return {}

func get_in_front_pos(velocity_offset: = Vector3.ZERO) -> Vector3:
	return actor_node.global_transform.origin + (actor_node.get_forward_vector() * 1.5) + velocity_offset

func get_placing_state_name() -> String:
	return get_class() + " placing"

func get_held_state_name() -> String:
	return get_class() + " held"

func get_is_placing() -> bool:
	return get_placing_state_name() in actor_node.state_info

func Crouch_pressed(action: Action):
	place_actor()

func Jump_pressed(action: Action):
	if is_instance_valid(picked_up_actor):
		action.jump_action()

func start_drop_timer():
	# Only allow host to start drop timer as I only want the host to check
	# if the actor should be dropped
	if G.is_node_network_master(actor_node, false):
		drop_timer.start()

func on_exiting():
	.on_exiting()
	if is_instance_valid(picked_up_actor):
		picked_up_actor.velocity = actor_node.velocity
		release_actor()

func on_reset_actor_node():
	on_exiting()

remote func set_sub_state(value: int):
	# Manage sub_state
	var state: Dictionary = get_state()
	if state.size() > 0:
		var old_sub_state: int = state.sub_state
		state.sub_state = value
		emit_signal("sub_state_changed", state.sub_state, old_sub_state)
	else:
		print("Pickup set_sub_state: There is no state for PickupAction")
	# Progress
	self.progression = int(value != HOLD) * 100
	

# ===== Signal

# DROP, this will only happen on the cariers end so I need to rpc release_actor
# on other clients from here
func _on_DropTimer_timeout():
#	if actor_raycast.get_collider() != picked_up_actor and not get_is_placing():
	if G.array_is_true([
		actor_raycast.get_collider() != picked_up_actor,
		not get_is_placing(),
		is_instance_valid(picked_up_actor),
		is_instance_valid(actor_node)
	]):
		picked_up_actor.velocity = actor_node.velocity
		if G.is_node_network_master(self):
#			rpc("release_actor")
			O3DP.O.custom_rpc(self, "release_actor")
		release_actor()
	else:
		# Network
		# I have to manually do this because DropTimer doesn't start
		# in other clients besides the owner's.
		if G.is_node_network_master(self):
#			rpc("set_sub_state", HOLD)
			O3DP.O.custom_rpc(self, "set_sub_state", [HOLD])
		set_sub_state(HOLD)
