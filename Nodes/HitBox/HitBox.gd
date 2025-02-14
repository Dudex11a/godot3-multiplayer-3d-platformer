extends Area
class_name HitBox

export var can_hit_self: bool = false
# If the hitbox should check again after the actor has entered itself
# and how long to wait
export var repeating_timer: float = 0

var actors_to_ignore: Array = []

signal actor_entered(actor)

func _ready():
	# Add owning actor to actors_to_ignore if can't hit self
	if not can_hit_self:
		var self_actor = G.get_parent_of_type(self, Actor)
		if is_instance_valid(self_actor):
			actors_to_ignore.append(self_actor)

func _on_HitBox_body_entered(body):
	if body is Actor:
		actor_entered(body)

func actor_entered(actor: Actor):
	# If the actor hasn't entered before 
	if not actor in actors_to_ignore:
		# Add the actor so it doesn't check again
		actors_to_ignore.append(actor)
		emit_signal("actor_entered", actor)
		# Allow the actor to re-enter the hitbox after the timer has ended
		if repeating_timer > 0:
			yield(get_tree().create_timer(repeating_timer), "timeout")
			actors_to_ignore.erase(actor)
			# Check if the actor is in the hitbox to re-apply actor entered
			if overlaps_body(actor):
				actor_entered(actor)
