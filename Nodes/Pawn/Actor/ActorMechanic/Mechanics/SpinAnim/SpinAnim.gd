extends ActorMechanic

export var spin_speed: float = 1.0
export var spin_speed_modifier: float = 1.0

var enabled: bool = true

func _process(delta: float):
	# If checks met spin
	if is_instance_valid(actor_node) and enabled:
		var spin_rotation: float = (spin_speed * spin_speed_modifier) * delta
		actor_node.model_node.rotation.y += spin_rotation
		actor_node.collision_shape.rotation.y += spin_rotation
