extends ActorMechanic

onready var actor_model: Spatial = actor_node.model_node

export var lean_into_rotation: bool = false

var move_input: Vector2 = Vector2.ZERO
var rotation_destination: float = 0.0 setget set_rotation_destination
const rotation_speed: float = 2.0
var rotating: bool = false
const lean_speed: float = 2.0
const lean_threshold: float = 0.005
var lean_destination: float = 0.0 setget set_lean_destination
var leaning: bool = false

func _process(delta: float):
	move_input = actor_node.move_input

func rotate_to_destination():
	if not is_instance_valid(actor_model):
		actor_model = actor_node.model_node
	if not rotating and is_instance_valid(actor_model):
		rotating = true
		var actor_model_rotation: float = get_actor_model_rotation()
		while actor_model_rotation != rotation_destination:
			var delta: float = get_process_delta_time()
			var normalized_actor_model_rotation: float = normalize_rotation(actor_model_rotation)
			var normalized_rotation_destination: float = normalize_rotation(rotation_destination)
			
			var current_close_to_one: = bool(round(normalized_rotation_destination))
			var destination_close_to_one: = bool(round(normalized_rotation_destination))
			
			var in_different_halves: bool = current_close_to_one != destination_close_to_one
			var abs_diff_move_than_half: bool = abs(normalized_actor_model_rotation - normalized_rotation_destination) >= 0.5
			
			var normal_rotation_progress: float = 0.0
			if abs_diff_move_than_half:
				var wierd_destination: float = normalized_rotation_destination
				wierd_destination += (int(normalized_actor_model_rotation > normalized_rotation_destination) * 2) - 1.0
				normal_rotation_progress = fposmod(move_toward(normalized_actor_model_rotation, wierd_destination, rotation_speed * delta), 1.0)
			else:
				normal_rotation_progress = move_toward(normalized_actor_model_rotation, normalized_rotation_destination, rotation_speed * delta)
			
			var rotation_progress: float = value_to_rotation(normal_rotation_progress)
			set_actor_model_rotation(rotation_progress)
			if lean_into_rotation:
				# Lean character into rotation
				var lean_amount: float = normalized_actor_model_rotation - normalized_rotation_destination
				if lean_amount > lean_threshold or lean_amount < -lean_threshold:
					var lean_strength: float = min(actor_node.get_horizontal_velocity() / 40.0, 0.35)
					lean_amount = (lean_amount / abs(lean_amount)) * lean_strength
					self.lean_destination = lean_amount
				else:
					self.lean_destination = 0.0
			# End
			actor_model_rotation = get_actor_model_rotation()
			yield(get_tree(), "idle_frame")
		rotating = false
		# Reset lean rotation
		self.lean_destination = 0.0

func lean_to_destination():
	# Only have one instance of leaning at a time
	if not leaning:
		leaning = true
		# Lean to destination
		var actor_model_lean: float = get_actor_model_lean()
		var delta: float = get_process_delta_time()
		while lean_destination != actor_model_lean:
			actor_model_lean = get_actor_model_lean()
			# If 
			if abs(actor_model_lean) - 0.4 < abs(lean_destination) or lean_destination == 0.0:
				var lean_progress: float = move_toward(actor_model_lean, lean_destination, lean_speed * delta)
				set_actor_model_lean(lean_progress)
			# End
			yield(get_tree(), "idle_frame")
		leaning = false

func get_actor_model_rotation() -> float:
	return actor_model.rotation.y

func set_actor_model_rotation(value: float):
	actor_node.rotate_to_forward_direction(value)

func get_actor_model_lean() -> float:
	return actor_model.rotation.z

func set_actor_model_lean(value: float):
	actor_model.rotation.z = value

func normalize_rotation(value: float) -> float:
	return (value + (PI / 2)) / (PI * 2)

func value_to_rotation(value: float) -> float:
	return (value * (PI * 2)) - (PI / 2)

# ===== setget

func set_rotation_destination(value: float):
	rotation_destination = value
	rotate_to_destination()
	
func set_lean_destination(value: float):
	lean_destination = value
	lean_to_destination()
