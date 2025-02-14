extends ActorMechanic

var previous_velocity: = Vector3.ZERO

func _ready():
	# Connect physics
	actor_node.connect("physics_process", self, "actor_physics_process")

func actor_pre_move_and_slide(new_previous_velocity: Vector3):
	previous_velocity = new_previous_velocity

func actor_physics_process():
	actor_node.is_pushing = false
	# Reset run speed if was pushing
	if "wall_push" in actor_node.max_speed_modifiers:
		actor_node.max_speed_modifiers.erase("wall_push")
		actor_node.calculate_max_speeds()
	actor_node.is_pushing_actor = false
	for index in range(actor_node.get_slide_count()):
		on_collision(actor_node.get_slide_collision(index), previous_velocity)

func on_collision(collision: KinematicCollision, previous_velocity: Vector3):
	if is_instance_valid(collision.collider):
		# Get collider node
		var collider = instance_from_id(collision.collider_id)
		# If wall collision
		if actor_node.get_wall_amount(collision.normal) > actor_node.wall_slide_angle:
			# PUSH
			actor_node.is_pushing = true
			# Enable physics if physics can be disabled
			if "disable_physics_process" in collider:
				if collider.disable_physics_process:
					collider.disable_physics_process = false
			# Push if there's velocity in collider (velocity is in Actor type)
			if "velocity" in collider:
				# Adjust move speed based on pushed node's weight
				if not actor_node.is_pushing_actor:
					if "weight" in collider:
						actor_node.max_speed_modifiers["wall_push"] = actor_node.weight / (collider.weight * 2)
						actor_node.calculate_max_speeds()
				actor_node.is_pushing_actor = true
				# Don't let pusher velocity stop on collision
				actor_node.velocity = (previous_velocity * G.reverse_vec3(actor_node.up_direction)) + (actor_node.velocity * actor_node.up_direction)
				# Adjust pushed velocity
				collider.velocity = actor_node.velocity * collision.normal.abs()
			
