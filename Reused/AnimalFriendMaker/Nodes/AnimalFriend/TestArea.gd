extends Spatial

onready var camera_rod: = $CameraRod
onready var camera: = camera_rod.get_node("Camera")
onready var af_node: = $AnimalFriend
onready var skeleton: Skeleton = af_node.skeleton

const distance: float = 12.0
const speed: float = 5.0

func _input(event: InputEvent):
	if event.is_action_pressed("debug_1"):
		af_node.anim_player.play("g_Idle_loop")
		
	if event.is_action_pressed("debug_2"):
		af_node.anim_player.play("g_Walk_loop")
		
	if event.is_action_pressed("debug_3"):
		af_node.anim_player.play("g_TPose")
	
	if event.is_action_pressed("ui_accept"):
		while Input.is_action_pressed("ui_accept"):
			rotate_head()
			yield(get_tree(), "idle_frame")
#		var neck_id: int = skeleton.find_bone("DEF-neck")
#		var bone_pose: Transform = skeleton.get_bone_pose(neck_id)
#		var angle: Vector3 = af_node.global_transform.origin.direction_to(camera.global_transform.origin)
##		G.debug_print("%s" % [bone_pose], 20)
#		G.debug_print(angle)
#		var trans: = Transform.IDENTITY
#		trans.basis = Basis(angle)
#		skeleton.set_bone_custom_pose(neck_id, trans)
		

func _process(delta: float):
	var x_axis: float = Input.get_axis("ui_left", "ui_right")
	var y_axis: float = Input.get_axis("ui_up", "ui_down")
	
	camera_rod.rotation.y += x_axis * delta * speed
	camera_rod.rotation.x += y_axis * delta * speed

func rotate_head():
	var half_pi: float = PI / 2
	var neck_id: int = skeleton.find_bone("DEF-neck")
	var obj: Spatial = camera
	# Anim bone rotation
	var bone_rotation: Vector3 = skeleton.get_bone_pose(neck_id).basis.get_euler()
	var af_pos: Vector3 = af_node.global_transform.origin
	af_pos.y += 1.8
	var obj_pos: Vector3 = obj.global_transform.origin
	# Normalized target position for adjusting how vertical or horizonal
	# one should look when both combine
	var normal_pos: Vector3 = (obj_pos - af_pos).normalized()
	var angle: = Vector3.ZERO
	# Up down adjust
	var af_forward_pos: = Vector2(af_pos.z, af_pos.y)
	var obj_forward_pos: = Vector2(obj_pos.z, obj_pos.y)
	var side_factor: float = abs(normal_pos.x)
	var forward_rotation: float = -af_forward_pos.angle_to_point(obj_forward_pos) + PI
	var forward_destination: float = round(forward_rotation / (PI * 2)) * (PI * 2)
	forward_rotation = lerp(forward_rotation, forward_destination, side_factor)
	angle.x = forward_rotation
	# Left right adjust
	var af_side_pos: = Vector2(af_pos.x, af_pos.z)
	var obj_side_pos: = Vector2(obj_pos.x, obj_pos.z)
	var up_factor: float = abs(normal_pos.y) * 0.3
	var side_rotation: float = -af_side_pos.angle_to_point(obj_side_pos) - (half_pi)
	side_rotation = lerp(side_rotation, 0, up_factor)
	angle.y = side_rotation
	# Apply rotation to bone
	var trans: = Transform.IDENTITY
	trans.basis = Basis(angle)
	skeleton.set_bone_custom_pose(neck_id, trans)
