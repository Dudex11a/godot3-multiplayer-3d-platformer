extends Spatial
class_name ActorSpawner

var actor_instance: Actor = null setget set_actor_instance
var spawn_rotation: = Vector3.ZERO

func respawn_actor():
	if is_instance_valid(actor_instance):
		actor_instance.reset_state()
		# Translation
		actor_instance.global_transform.origin = global_transform.origin
		# Rotation
		apply_rotation_to_actor()

func set_actor_instance(value: Actor = get_children()[0]):
	actor_instance = value
	# Set to respawn here
	if "actor_spawner" in actor_instance:
		actor_instance.actor_spawner = self

func apply_rotation_to_actor(value: Vector3 = spawn_rotation):
	actor_instance.rotation = value

# ===== Signals

# Wait for actor to be loaded in
func _on_ActorSpawner_child_entered_tree(node):
	set_actor_instance(node)
	# Save rotation
	spawn_rotation = rotation
	# Remove rotation
	rotation = Vector3.ZERO
	rotation_degrees = Vector3.ZERO
	# Apply rotation to actor
	apply_rotation_to_actor()
