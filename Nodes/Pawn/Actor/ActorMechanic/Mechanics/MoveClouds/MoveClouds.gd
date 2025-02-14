extends ActorMechanic

onready var cloud_particles: = $CloudParticles
onready var cloud_part_mat: ParticlesMaterial = cloud_particles.process_material

#export var cloud_amount_p_sec: int = 5
#var custom_cloud_multiplier: float = 1.0

#func _ready():
#	cloud_particles.amount = cloud_amount_p_sec

func _process(delta):
	if is_instance_valid(actor_node):
		# Is emitting
		var emit: bool = actor_node.is_on_floor() and actor_node.velocity.length() > 1
		cloud_particles.emitting = emit
		# Direction
		cloud_part_mat.direction = -actor_node.velocity.normalized()
#		# Velocity is equates to the amount of clouds
#		G.debug_value("move clouds vel", actor_node.velocity.length())
#		var cloud_multiplier: float = actor_node.velocity.length() / actor_node.max_run_speed
#		cloud_particles.amount = int(cloud_amount_p_sec * cloud_multiplier)
		
