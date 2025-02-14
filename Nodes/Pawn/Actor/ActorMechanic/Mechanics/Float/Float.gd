extends ActorMechanic
class_name ActorMechanicFloat
func get_class() -> String: return "ActorMechanicFloat"

export var distance_down: float = 6
export var velocity_strength: float = 20
export var velocity_change_speed: float = 150
var velocity_change_speed_multiplier: float = 1.0
export var position_met_threshold: float = 1

onready var raycast_node: = $RayCast

func _ready():
	actor_node.connect("physics_process", self, "actor_physics_process")
	raycast_node.add_exception(actor_node)
#	raycast_node.add_exception(actor_node.collision_shape)
	raycast_node.cast_to.y = -distance_down

func _process(delta):
	# If out of position move to position
	pass

func actor_physics_process():
	var actor_pos: Vector3 = actor_node.global_transform.origin
	var position_to_be: Vector3 = get_position_to_be()
	# If position has been met disable physics
#	var checks: Array = [
#		is_close_enough_to_floor(actor_pos, position_to_be),
#		not actor_node.is_state_active(),
#		actor_node.get_rotated_up_velocity() < 0
#	]
	# Move actor towords -cast_to collision
	if raycast_node.is_colliding():
		# Give gravity mod
		actor_node.gravity_multipliers[get_class()] = 0
		# Move to pos
		var delta: float = get_physics_process_delta_time()
		var direction_to_position: Vector3 = actor_pos.direction_to(position_to_be)
		# Make pull stronger when furthur away
		var velocity_destination: Vector3 = direction_to_position * actor_pos.distance_to(position_to_be) * velocity_strength
		actor_node.velocity = actor_node.velocity.move_toward(velocity_destination, velocity_change_speed * delta)
	else:
		# Remove gravity mod
		if get_class() in actor_node.gravity_multipliers:
			actor_node.gravity_multipliers.erase(get_class())

func is_close_enough_to_floor(
	actor_pos: Vector3 = actor_node.global_transform.origin,
	position_to_be: Vector3 = get_position_to_be()) -> bool:
		
	return actor_pos.distance_to(position_to_be) < position_met_threshold and not actor_node.is_state_active()

func get_position_to_be() -> Vector3:
	return raycast_node.get_collision_point() - raycast_node.cast_to
