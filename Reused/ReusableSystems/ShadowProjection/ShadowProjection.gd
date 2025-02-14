extends Spatial

onready var box_node: = $Box
onready var numbered_raycast_nodes: Array = [$RayCast1, $RayCast2, $RayCast3]
onready var all_raycasts: Array = [$CenterRayCast]

export var raycast_distance: float = 0.5
var margin: float = 0.1

func _ready():
	all_raycasts.append_array(numbered_raycast_nodes)
	# Rotate numbered raycasts in circle around character
	for index in range(numbered_raycast_nodes.size()):
		var raycast: RayCast = numbered_raycast_nodes[index]
		# Move out
		raycast.translation.z = raycast_distance
		# Rotate
		G.rotate_around(raycast, global_transform.origin, Vector3.UP, ((PI * 2) / numbered_raycast_nodes.size()) * float(index))

func _process(delta: float):
	# Set the shadow box's distance to the floor
	var closest_raycast : RayCast = get_closest_raycast()
	if is_instance_valid(closest_raycast):
		box_node.translation.y = (closest_raycast.get_collision_point() - global_transform.origin).y + margin

func is_raycasts_colliding() -> bool:
	for raycast in all_raycasts:
		if raycast.is_colliding():
			return true
	return false

# Compare all raycast's distance and get the closest
func get_closest_raycast() -> RayCast:
	var closest_raycast: RayCast = null
	var closest_distance: float = 10000
	for raycast in all_raycasts:
		var new_distance: float = raycast.get_collision_point().distance_to(global_transform.origin)
		if new_distance < closest_distance:
			closest_distance = new_distance
			closest_raycast = raycast
	return closest_raycast
