extends Spatial
class_name Spectator

onready var camera_node: = $Camera

var active: bool = false
var move_active: bool = true setget set_move_active

var go_fast: bool = false
var move_speed: float = 30.0
var camera_rot_speed: float = 20.0

var mouse_movement: = Vector2.ZERO

func _input(event: InputEvent):
	if event is InputEventMouseMotion and active:
		mouse_movement += event.relative
	# Allow mouse to leave Window when input is pressed
	if event.is_action_pressed("character_action-1"):
		set_move_active(not move_active)

func _physics_process(delta: float):
	if not active or not move_active:
		return
	# Camera rotation
	var rotate_value: = Vector2.ZERO
	rotate_value.x = Input.get_action_strength("character_camera-left") - Input.get_action_strength("character_camera-right")
	rotate_value.y = Input.get_action_strength("character_camera-up") - Input.get_action_strength("character_camera-down")
	# Add mouse movement
	rotate_value.x -= mouse_movement.x / 50
	rotate_value.y -= mouse_movement.y / 50
	# Reset mouse movement
	mouse_movement = Vector2.ZERO
	# Up down rotation
	var camera_rotation_amount: Vector2 = rotate_value
	camera_rotation_amount *= camera_rot_speed
	# Apply rotation
	# Up Down
	camera_node.rotation.x += camera_rotation_amount.y * delta
	# Right Left
	camera_node.rotation.y += camera_rotation_amount.x * delta
	
	# Node movement
	var move_value: = Vector2.ZERO
	move_value.x = Input.get_action_strength("character_move-back") - Input.get_action_strength("character_move-forward")
	move_value.y = Input.get_action_strength("character_move-right") - Input.get_action_strength("character_move-left")
	var movement: = Vector3.ZERO
	movement.z = move_value.x * move_speed
	movement.x = move_value.y * move_speed
	# Rotate movement to point in camera direction
	movement = movement.rotated(Vector3.RIGHT, camera_node.rotation.x)
	movement = movement.rotated(Vector3.UP, camera_node.rotation.y)
	# Apply movement
	translate(movement * delta)

func set_move_active(value: bool):
	move_active = value
	if move_active:
		# Reset mouse movement
		mouse_movement = Vector2.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
