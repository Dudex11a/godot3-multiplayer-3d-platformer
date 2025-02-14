extends Spatial

var camera_input: = Vector2.ZERO

onready var camera_node: = $Camera
var camera_rotation: = Vector2.ZERO setget set_camera_rotation
var camera_rotation_speed: float = 20.0
var camera_fp_speed: float = 3.0
var camera_zoom: float = 0.5 setget set_camera_zoom
var camera_zoom_speed: float = 1.0
var is_camera_rotating: bool = false
const close_camera_translation: = Vector3(0, 2, 5)
const close_camera_rotation: = Vector3(-13, 0, 0)
const far_camera_translation: = Vector3(0, 10, 15)
const far_camera_rotation: = Vector3(-19, 0, 0)
const fp_camera_translation: = Vector3(0, 1, 0)

var camera_mode: int = THIRD_PERSON_CHARACTER setget set_camera_mode
# Camera modes
enum {
	THIRD_PERSON_CHARACTER,
	CAMERA_FOLLOW,
	CAMERA_FP
}

var controller_up_input: float = 0.0
var controller_right_input: float = 0.0
var controller_down_input: float = 0.0
var controller_left_input: float = 0.0

# Cull mask to use for First Person mode
var cull_mask_in_use: int = -1

signal process_end

func _process(delta: float):
	
	var player_node: PlayerNode = get_player_node()
	var character_node: Character = get_character_node()
	
	if is_instance_valid(character_node):
		if character_node.can_input():
			# Stick camera rotation
			var x_strength: float = controller_right_input - controller_left_input
			var y_strength: float = controller_up_input - controller_down_input
			camera_input.x += x_strength * 3.5
			camera_input.y += y_strength * 2.0
		
			# Mouse camera
			var controller_data: ControllerData = player_node.controller_data
			if controller_data.can_use_mouse():
				if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
					var custom_focus: Node = CustomFocus.get_self()
					yield(custom_focus, "before_clear")
					var mouse_input: Vector2 = custom_focus.get_mouse_relative()
					match camera_mode:
						THIRD_PERSON_CHARACTER:
							mouse_input *= Vector2(0.2, 0.0)
#						CAMERA_FP:
#							mouse_input *= Vector2(0.06, -0.06)
					camera_input += mouse_input
					# Modify camera_input based on settings
					var sensitivity_x = player_node.get_general_setting("Camera Sensitivity X")
					if sensitivity_x != null:
						camera_input.x *= (sensitivity_x / 25)
					var sensitivity_y = player_node.get_general_setting("Camera Sensitivity Y")
					if sensitivity_y != null:
						camera_input.y *= (sensitivity_y / 25)
					var invert_y = player_node.get_general_setting("Camera Invert Y")
					if invert_y:
						camera_input.y *= -1
	
	match camera_mode:
		THIRD_PERSON_CHARACTER:
			# Location
			if is_instance_valid(character_node):
				global_transform.origin = character_node.global_transform.origin
			# Rotation
			var rod_rotation: float = get_rod_rotation_2d().x
			rod_rotation += -camera_input.x * delta
			self.camera_rotation.x = rod_rotation
			# Zoom
			var y_amount: float = -camera_input.y * camera_zoom_speed * delta
			var next_zoom: float = camera_zoom + y_amount
			next_zoom = clamp(next_zoom, 0, 1)
			set_camera_zoom(next_zoom)
#		CAMERA_FP:
#			var rotation_2d: Vector2 = camera_input * camera_fp_speed * delta
#			rotation_2d.x *= -1
#			self.camera_rotation += rotation_2d
#			self.camera_rotation.y = clamp(self.camera_rotation.y, -PI / 2, PI / 2) 
			
	# Reset camera input
	camera_input = Vector2.ZERO

func _input(event: InputEvent):
	
	# Abort if not controller
	var player_node: PlayerNode = get_player_node()
	if is_instance_valid(player_node):
		if not get_player_node().controller_data.event_matches(event):
			return
	
	var character_node: Character = get_character_node()
	if is_instance_valid(character_node):
		if not character_node.can_input():
			return
	
#	# Change camera mode
#	if event.is_action_pressed("character_change_camera_mode"):
#		match camera_mode:
#			THIRD_PERSON_CHARACTER:
#				set_camera_mode(CAMERA_FP)
#			CAMERA_FP:
#				set_camera_mode(THIRD_PERSON_CHARACTER)
	
	# Controller camera
	for direction in ["up", "right", "down", "left"]:
		var action_name: String = "character_camera-" + direction
		var variable_name: String = "controller_%s_input" % [direction]
		if event.is_action(action_name):
			var strength: float = event.get_action_strength(action_name)
			# If event is scroll wheel treat it differently
			if event is InputEventMouseButton:
				if event.pressed:
					self[variable_name] += strength
					yield(get_tree().create_timer(0.05), "timeout")
					self[variable_name] -= strength
			else:
				self[variable_name] = strength
	
	# Button camera movement
	if "pressed" in event:
		if event.is_action_pressed("character_camera-up"):
			camera_input.y += 1
		if event.is_action_pressed("character_camera-down"):
			camera_input.y -= 1

func set_camera_zoom(value: float = camera_zoom):
	camera_zoom = value
	camera_node.translation = close_camera_translation.linear_interpolate(far_camera_translation, value)
	camera_node.rotation_degrees = close_camera_rotation.linear_interpolate(far_camera_rotation, value)

func set_camera_mode(value: int):
	var old_mode: int = camera_mode
	camera_mode = value
	match old_mode:
		THIRD_PERSON_CHARACTER:
			pass
#		CAMERA_FP:
#			# Come out of FP
#			if cull_mask_in_use >= 0:
#				O3DP.used_cull_masks.erase(cull_mask_in_use)
#				# What camera can see
#				camera_node.set_cull_mask_bit(cull_mask_in_use, true)
#				var af_node: AnimalFriend = character_node.af_node
#				# What can see af
#				if is_instance_valid(af_node):
#					af_node.set_visual_layer(0, true)
#					af_node.set_visual_layer(cull_mask_in_use, false)
	match camera_mode:
		THIRD_PERSON_CHARACTER:
			self.camera_rotation.y = 0.0
#		CAMERA_FP:
#			# Go into FP
#			cull_mask_in_use = O3DP.get_unused_cull_mask()
#			if cull_mask_in_use >= 0:
#				O3DP.used_cull_masks.append(cull_mask_in_use)
#				# What camera can see
#				camera_node.set_cull_mask_bit(cull_mask_in_use, false)
#				# What can see af
#				var af_node: AnimalFriend = character_node.af_node
#				if is_instance_valid(af_node):
#					af_node.set_visual_layer(0, false)
#					af_node.set_visual_layer(cull_mask_in_use, true)
			
			translation = Vector3(0, 1, 0)
			camera_node.translation = Vector3.ZERO
			camera_node.rotation = Vector3.ZERO
	# Reset camera_input so value doesn't carry over
	camera_input = Vector2.ZERO

func set_camera_rotation(value: Vector2):
	camera_rotation = value
	set_rod_rotation_2d(camera_rotation)
	# Camera rotating animation
#	if not is_camera_rotating:
#		is_camera_rotating = true
#		while is_camera_rotating:
#			camera_rotating()
#			yield(get_tree(), "idle_frame")

func get_rod_rotation_2d() -> Vector2:
	return Vector2(rotation.y, rotation.x)

func set_rod_rotation_2d(val: Vector2):
	rotation = Vector3(val.y, val.x, rotation.z)

func camera_rotating():
	var rod_rotation: Vector2 = get_rod_rotation_2d()
	rod_rotation = rod_rotation.move_toward(camera_rotation, camera_rotation_speed * get_process_delta_time())
	set_rod_rotation_2d(rod_rotation)
	if rod_rotation == camera_rotation:
		is_camera_rotating = false

func get_player_node() -> PlayerNode:
	var parent = get_parent().get_parent()
	if parent is PlayerNode:
		return parent
	return null

func get_character_node() -> Character:
	var player_node: PlayerNode = get_player_node()
	if is_instance_valid(player_node):
		var character_node: Character = player_node.character_node
		if is_instance_valid(character_node):
			return character_node
	return null
