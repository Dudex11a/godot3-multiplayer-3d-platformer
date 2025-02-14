extends RigidBody
class_name PhysicsObject

onready var kinematic_body: = $KinematicBody

func _physics_process(delta: float):
	kinematic_body.move_and_slide(Vector3.ZERO)
	for index in kinematic_body.get_slide_count():
		var collision: KinematicCollision = kinematic_body.get_slide_collision(index)
		G.debug_print(collision.collider, 0.1)
