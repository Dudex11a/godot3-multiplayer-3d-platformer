extends Spatial
class_name MovingPlatform

enum {
	TRAVEL,
	WAIT
}

onready var body_node: = $Body
onready var location_container_node: = $LocationContainer
onready var current_location: Spatial = location_container_node.get_children()[0]
onready var next_location: Spatial = location_container_node.get_children()[1]
onready var timer_node: = $Timer

export var travel_time: float = 2.0
export var wait_time: float = 2.0
export var travel_curve: Curve

var current_location_id: = 0
var travel_state: int = TRAVEL

func _ready():
	move_platform()

func _process(delta: float):
	if travel_state == TRAVEL:
		var time_pos = timer_node.time_left / travel_time
		time_pos = travel_curve.interpolate(time_pos)
		body_node.transform = next_location.transform.interpolate_with(current_location.transform, time_pos)

func move_platform(timer_pos: float = 0.0):
	travel_state = TRAVEL
	# Start platform movement
	timer_node.stop()
	timer_node.wait_time = travel_time
	timer_node.start(timer_pos)

func start_wait(timer_pos: float = 0.0):
	travel_state = WAIT
	body_node.transform = next_location.transform
	# Stop platform movement
	timer_node.stop()
	timer_node.wait_time = wait_time
	timer_node.start(timer_pos)

func set_locations():
	var children: Array = location_container_node.get_children()
	current_location = children[current_location_id]
	next_location = children[(current_location_id + 1) % children.size()]

func increment_locations():
	# Update the next and current_location
	current_location_id = (current_location_id + 1) % location_container_node.get_children().size()
	set_locations()

func _on_Timer_timeout():
	# Platform start or wait
	match travel_state:
		TRAVEL:
			if wait_time > 0:
				start_wait()
			else:
				increment_locations()
				move_platform()
		WAIT:
			increment_locations()
			move_platform()

func get_state() -> Dictionary:
	var state: Dictionary = {}
	state.travel_state = travel_state
	state.timer_playing = not timer_node.is_stopped()
	state.timer_pos = timer_node.time_left
	state.current_location_id = current_location_id
	return state

func set_state(state: Dictionary):
	travel_state = state.travel_state
	current_location_id = state.current_location_id
	set_locations()
	if state.timer_playing:
		match travel_state:
			TRAVEL:
				move_platform(state.timer_pos)
			WAIT:
				start_wait(state.timer_pos)
	else:
		timer_node.stop()
		timer_node.time_left = state.timer_pos
		match travel_state:
			TRAVEL: timer_node.wait_time = travel_time
			WAIT: timer_node.wait_time = wait_time
