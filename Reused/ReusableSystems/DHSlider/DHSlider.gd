extends Control

onready var slider_node: = $Slider

export var increment_amount: float = 1
export var lower_bounds: float = 0
export var upper_bounds: float = 100
onready var increment_normal_amount: float = increment_amount / get_bounds_length()

var value: float = 0.0 setget set_value, get_value
var normal_value: float = 0.5 setget set_normal_value
var left_click_state: bool = false
const hold_wait_time: float = 0.5
const hold_speed: float = 0.5

signal value_changed(value)

func _input(event: InputEvent):
	# Set slider value with mouse
	if is_visible_in_tree():
		if event is InputEventMouseButton:
			# If left click
			if event.button_index == 1:
				left_click_state = event.pressed
				if event.pressed:
					if G.within_box(event.position, rect_global_position, rect_size):
						# Update value until mouse release
						while left_click_state:
							set_value_with_global_pos()
							emit_signal("value_changed", self.value)
							yield(get_tree(), "idle_frame")
						round_normal_value_to_increment()
						emit_signal("value_changed", self.value)

# ===== setget

func set_normal_value(new_normal_value: float = normal_value):
	normal_value = clamp(new_normal_value, 0.0, 1.0)
	
	update_slider_pos()

func set_value_with_global_pos(pos: Vector2 = get_global_mouse_position()):
	# Make value from global pos
	# Make local pos
	var local_pos: Vector2 = pos - rect_global_position
	set_normal_value((local_pos / rect_size).x)

func update_slider_pos():
	# Set slider pos based on value
	if is_instance_valid(slider_node):
		slider_node.rect_position.x = (rect_size.x * normal_value) - (slider_node.rect_size.x / 2)

func get_value_from_normal_value() -> float:
	return (normal_value * get_bounds_length()) + lower_bounds

func round_normal_value_to_increment():
	self.normal_value = round(self.normal_value / increment_normal_amount) * increment_normal_amount
#	self.value = (round(value * increment_amount)) / increment_amount

func set_value(new_value: float):
	value = new_value
	# Change normal_value with convertion
	self.normal_value = (value - lower_bounds) / get_bounds_length()

func get_value() -> float:
	return get_value_from_normal_value()

func get_bounds_length() -> float:
	return upper_bounds - lower_bounds

# ===== Focus

# slider Focus

func ui_right_action_p(focus: FocusCursor, _parent: Node):
	focus_increment_value(focus, 1, "ui_right")

func ui_left_action_p(focus: FocusCursor, _parent: Node):
	focus_increment_value(focus, -1, "ui_left")

func focus_increment_value(focus: FocusCursor, direction: float, action_name: String):
	self.normal_value += direction * increment_normal_amount
	round_normal_value_to_increment()
	# Update focus visual
	focus.update_visible_to_current_node()
	emit_signal("value_changed", self.value)
	# Start hold wait time timer
	var timer: SceneTreeTimer = get_tree().create_timer(hold_wait_time)
	var end: bool = false
	while timer.time_left > 0:
		if not action_name in focus.pressed_actions:
			end = true
		yield(get_tree(), "idle_frame")
	# If not end keep sliding
	if not end:
		while action_name in focus.pressed_actions:
			# I don't set "self.value" here so I don't call the value_changed signal each idle_frame
			self.normal_value += direction * (get_process_delta_time() * hold_speed)
			emit_signal("value_changed", self.value)
			focus.update_visible_to_current_node()
			yield(get_tree(), "idle_frame")
		round_normal_value_to_increment()
	emit_signal("value_changed", self.value)

func ui_accept_action_p(focus: FocusCursor, _parent: Node):
	focus.set_current_node(self)
