extends ViewportContainer

onready var af_maker_node: = get_node("..")
onready var camera_rod_node: = $Viewport/World/CameraRod
onready var camera_node: Camera = camera_rod_node.get_node("Camera")
onready var behind_node: Spatial = camera_node.get_node("Behind")

var camera_direction: Vector3 = Vector3.ZERO
var camera_rotation: Vector2 = Vector2.ZERO
const camera_zoom_sensitivity: int = 1
#const mouse_camera_sensitivity: float = 100.0
const stick_camera_sensitivity: float = 2.0

var controller_up_input: float = 0.0
var controller_right_input: float = 0.0
var controller_down_input: float = 0.0
var controller_left_input: float = 0.0

func _input(event: InputEvent):
	var new_controller_data: = ControllerData.new(event)
	var current_controller_data: ControllerData = get_controller_data()
	var current_controller_name: String = current_controller_data.to_name()
	if current_controller_name != new_controller_data.to_name() and current_controller_name != "unknown":
		return
	
	# Controller camera
	for direction in ["up", "right", "down", "left"]:
		var action_name: String = "character_camera-" + direction
		var variable_name: String = "controller_%s_input" % [direction]
		if event.is_action(action_name):
			var strength: float = event.get_action_strength(action_name)
			# If event is scroll wheel treat it differently
			self[variable_name] = strength

func _process(delta: float):
	# Stick camera rotation
	var x_strength: float = controller_right_input - controller_left_input
	var y_strength: float = controller_up_input - controller_down_input
	camera_rotation.x += x_strength * 3.5
	camera_rotation.y -= y_strength * 2.0
	
	if can_use_mouse():
		var custom_focus: Node = CustomFocus.get_self()
		yield(custom_focus, "before_clear")
		var mouse_input: Vector2 = custom_focus.get_mouse_relative()
		camera_rotation += mouse_input
	
	# Apply camera rotation
	if is_visible_in_tree():
		camera_rod_node.rotation += Vector3(camera_rotation.y, camera_rotation.x, 0) * delta
		# Clamp up down camera rotation
		var half_pi: float = PI / 2
		camera_rod_node.rotation.x = clamp(camera_rod_node.rotation.x, -half_pi, half_pi)
		# Reset camera rotation
		camera_rotation = Vector2.ZERO

func can_use_mouse() -> bool:
	var mouse_within_box: bool = G.within_box(get_global_mouse_position() - G.get_viewport_global_offset_in_node(self), get_global_transform().origin, rect_size)
	var checks: Array = [
		get_controller_data().can_use_mouse(),
		mouse_within_box,
		Input.is_mouse_button_pressed(1)
	]
	return G.array_is_true(checks)

func get_controller_data() -> ControllerData:
	if is_instance_valid(af_maker_node.focus_cursor):
		if is_instance_valid(af_maker_node.focus_cursor.controller_data):
			return af_maker_node.focus_cursor.controller_data
	return ControllerData.new()
