extends HitBox
class_name BounceBox

enum VELOCITY_TYPE {
	OVERWRITE,
	SET,
	ADD
}
# Velocity to launch object
export var launch_velocity: = Vector3(0, 30, 0)
# Type of method to run for velocity
#export(VELOCITY_TYPE) var velocity_type = VELOCITY_TYPE.OVERWRITE
export(VELOCITY_TYPE) var velocity_type = VELOCITY_TYPE.OVERWRITE
# If to ADD the parent's velocity to the launch
export var add_parent_velocity: bool = true

# ===== Signals

func _on_BounceBox_actor_entered(actor: Actor):
	var final_launch_velocity: Vector3 = launch_velocity
	# ADD the parent's launch velocity (if there is a parent with velocity)
	if add_parent_velocity:
		var parent = G.get_parent_with_property(self, "previous_velocity")
		if is_instance_valid(parent):
			final_launch_velocity += parent.previous_velocity / 2
			parent.launch_overwrite(-final_launch_velocity, -final_launch_velocity.normalized())
	match velocity_type:
		VELOCITY_TYPE.SET:
			actor.launch_set(final_launch_velocity)
		VELOCITY_TYPE.ADD:
			actor.launch_ADD(final_launch_velocity)
		VELOCITY_TYPE.OVERWRITE:
			actor.launch_overwrite(final_launch_velocity, final_launch_velocity.normalized())
	# If actor has AirDash reSET it
	var air_dash_action: Action = actor.find_action("AirDash")
	if is_instance_valid(air_dash_action):
		air_dash_action.can_dash = true
