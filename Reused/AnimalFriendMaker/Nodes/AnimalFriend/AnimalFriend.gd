extends Spatial
class_name AnimalFriend

onready var skeleton_node: = $rigify_rig_deform/Skeleton
onready var anim_player_node: = $AnimationPlayer
onready var anim_tree: = $AnimationTree

onready var body_node: = skeleton_node.get_node("Body")
onready var left_arm_node: = skeleton_node.get_node("Arm_L")
onready var right_arm_node: = skeleton_node.get_node("Arm_R")
onready var left_leg_node: = skeleton_node.get_node("Leg_L")
onready var right_leg_node: = skeleton_node.get_node("Leg_R")

onready var head_skeleton: = skeleton_node.get_node("HeadBoneAttachment/Cat1Armature")
onready var head_node: = head_skeleton.get_node("Mesh1")
onready var tail_skeleton: = skeleton_node.get_node("TailBoneAttachment/LongTailArmature")
onready var tail_node: = tail_skeleton.get_node("LongTail")

onready var component_objects: Dictionary = {
	"Head" : {
		"node": head_node,
		"type" : "limb"
	},
	"Body" : {
		"node": body_node,
		"type" : "limb"
	},
	"Arm_L" : {
		"node": left_arm_node,
		"type" : "limb"
	},
	"Arm_R" : {
		"node": right_arm_node,
		"type" : "limb"
	},
	"Leg_L" : {
		"node": left_leg_node,
		"type" : "limb"
	},
	"Leg_R" : {
		"node": right_leg_node,
		"type" : "limb"
	},
	"Tail" : {
		"node": tail_node,
		"type" : "limb"
	},
}

var linked_colors: Array = []

var af_info: AnimalFriendInfo setget set_af_info

## DEBUGGING
#func _input(event: InputEvent):
#	if event.is_action_pressed("debug_1"):
#		self.anim_full_body_state = "Airborne"
#	if event.is_action_pressed("debug_3"):
#		self.anim_full_body_state = "Climb"

func _ready():
	# Initialize linked colors
	for index in range(6):
		var linked_color: LinkedColor = LinkedColor.new(Color.white)
		linked_colors.append(linked_color)
	# Start blinking
	self.is_blinking = true

func update_colors():
	for linked_color in linked_colors:
		linked_color.update_image_palette_colors()

func add_linked_color_link(limb_name: String, linked_color_index: int, image_palette_color_index: int):
	var limb_info: Dictionary = af_info[String(limb_name)]
	var linked_color: LinkedColor = linked_colors[int(linked_color_index)]
	var image_palette: ImagePalette = component_objects[String(limb_name)].image_palette
	# Remove unique color from UniqueColors in af_info if there is one
	if "UniqueColors" in limb_info:
		# Acount for if the index is a String or an int
		if int(image_palette_color_index) in limb_info.UniqueColors:
			limb_info.UniqueColors.erase(int(image_palette_color_index))
		if String(image_palette_color_index) in limb_info.UniqueColors:
			limb_info.UniqueColors.erase(String(image_palette_color_index))
	# Add to af_info
	limb_info.LinkedColors[int(image_palette_color_index)] = int(linked_color_index)
	# TEMP TEMP TEMP
	# Fix color from string to color
	var color = af_info.LinkedColors[int(linked_color_index)]
	if color is String:
		color = G.string_to_color(color)
		af_info.LinkedColors[int(linked_color_index)] = color
	# Set the linked_color to the af_infos LinkedColor to update the ImageTexture
	set_linked_color_color(int(linked_color_index), af_info.LinkedColors[int(linked_color_index)])
	# Add to linked_colors ( This needs to be at the bottom of the method,
	# head color doesn't load for some reason otherwise )
	linked_color.add_link(String(limb_name), image_palette, int(image_palette_color_index))

func remove_linked_color_link(limb_name: String, image_palette_color_index: int):
	var limb_info: Dictionary = af_info[String(limb_name)]
	var linked_color_index: int = af_info[String(limb_name)].LinkedColors[int(image_palette_color_index)]
	# Remove link from af_info
	# I check for int and String ids in LinkedColors because
	# I think I made a mistake at somepoint where both String and ints were stored
	# When I only want ints.
	if int(image_palette_color_index) in limb_info.LinkedColors:
		limb_info.LinkedColors.erase(int(image_palette_color_index))
	if String(image_palette_color_index) in limb_info.LinkedColors:
		limb_info.LinkedColors.erase(String(image_palette_color_index))
	# Remove to linked_colors
	var linked_color: LinkedColor = linked_colors[int(linked_color_index)]
	linked_color.remove_link(String(limb_name), image_palette_color_index)
	# Create a unique color in UniqueColors in af_info since the color is no longer linked
	set_unique_limb_color(String(limb_name), int(image_palette_color_index), linked_color.color)

func has_linked_color_link(limb_name: String, image_palette_color_index: int) -> bool:
	return image_palette_color_index in af_info[String(limb_name)].LinkedColors

func change_linked_color_link(limb_name: String, new_linked_color_index: int, image_palette_index: int):
	# Remove old link
	if has_linked_color_link(limb_name, image_palette_index):
		remove_linked_color_link(limb_name, image_palette_index)
	# Add to link
	add_linked_color_link(limb_name, new_linked_color_index, image_palette_index)

# ===== setget

func set_af_info(new_af_info: AnimalFriendInfo = af_info):
	af_info = new_af_info
	# Update self with the new af_info
	# Correct LinkedColors that are still Strings in af_info.
	# I'm unsure how this happens in the first place.
	for color_index in range(af_info.LinkedColors.size()):
		var value = af_info.LinkedColors[int(color_index)]
		if value is String:
			af_info.LinkedColors[int(color_index)] = G.string_to_color(value)
	# Set up each limb with their...
	# Mesh, Texture, Unique Colors, and Linked Colors
	for key in component_objects.keys():
		set_limb_mesh(key, new_af_info[key])
	# Anims
	load_all_anims()

func set_limb_mesh(limb_name: String, limb_info: Dictionary):
	var limb_objects: Dictionary = component_objects[limb_name]
	var limb_node: MeshInstance = limb_objects.node
	# Remove prior limb stuff
	# Remove prior limb linked_color data
	if "image_palette" in limb_info:
		for linked_color in linked_colors:
			linked_color.remove_image_palette(limb_name, limb_info.image_palette)
	#
	var mesh_path: Array = limb_info.Mesh.duplicate()
	var color_texture_path: Array = limb_info.ColorTexture.duplicate()
	# Change mesh if it's different MESH
#	var new_mesh: Mesh = AF_Maker.R.get_af_resource(mesh_path)
#	if not G.do_resources_match(limb_node.mesh, new_mesh):
#		limb_node.mesh = new_mesh
	# Re-apply the skin so animations work. I don't know why the issue is a thing
	# in the first place, I don't know why this fixes the issue.
	limb_node.skin = limb_node.skin
	var material: Material = AF_Maker.R.get_resource("part_texture_material").duplicate()
	# Update material to part_texture_material if they don't match
	var old_material = limb_node.get_surface_material(0)
	if G.do_resources_match(material, old_material):
		material = old_material
	else:
		limb_node.set_surface_material(0, material)
	
	var color_texture = AF_Maker.R.get_af_resource(color_texture_path)
	if not is_instance_valid(color_texture):
		print("Color texture was not found, changing path to default")
		print("From ", color_texture_path)
		var default_af_info: = AnimalFriendInfo.new()
		color_texture_path = default_af_info[color_texture_path[0]]["ColorTexture"]
		print("To ", color_texture_path)
		color_texture = AF_Maker.R.get_af_resource(color_texture_path)
		if not is_instance_valid(color_texture):
			print("Path still not valid...")
	material.set("shader_param/color_sampler", color_texture)
	# Set up palette as ImagePalette
	var image_palette: ImagePalette = ImagePalette.new()
	material.set("shader_param/palette", image_palette.image_texture)
	limb_objects.image_palette = image_palette
	# Link colors based on defaults
	# If LinkedColors don't exist in limb_info use defaults
	if not "LinkedColors" in limb_info:
		if limb_name in AF_Maker.part_defaults[limb_info.PartName]:
			limb_info.LinkedColors = AF_Maker.part_defaults[limb_info.PartName][limb_name].LinkedColors.duplicate()
		else:
			limb_info.LinkedColors = AF_Maker.part_defaults[limb_info.PartName].LinkedColors.duplicate()
	# TEMP TEMP TEMP
	# Add linked colors and convert the keys in ints if they're strings
	for image_palette_color_index in limb_info.LinkedColors.keys():
		# Convert key from String to int
		if image_palette_color_index is String:
			var value = limb_info.LinkedColors[image_palette_color_index]
			limb_info.LinkedColors.erase(image_palette_color_index)
			limb_info.LinkedColors[int(image_palette_color_index)] = value
			
		var linked_color_index = limb_info.LinkedColors[int(image_palette_color_index)]
		add_linked_color_link(limb_name, linked_color_index, int(image_palette_color_index))
	# Unique colors
	if "UniqueColors" in limb_info:
		for image_palette_color_index in limb_info.UniqueColors.keys():
			var value = limb_info.UniqueColors[image_palette_color_index]
			# Convert UniqueColors String keys to ints
			if image_palette_color_index is String:
				limb_info.UniqueColors.erase(int(image_palette_color_index))
				limb_info.UniqueColors[int(image_palette_color_index)] = value
		
			# Convert UniqueColors from Strings to Colors if Strings
			limb_info.UniqueColors[int(image_palette_color_index)] = G.string_to_color(value)
			
			# Change the image_palette to the color
			image_palette.set_color(int(image_palette_color_index), limb_info.UniqueColors[int(image_palette_color_index)])
#			set_unique_limb_color(String(limb_name), int(image_palette_color_index), limb_info.UniqueColors[int(image_palette_color_index)])

# I want modify my linked_colors through these functions so the changes
# to a LinkedColor are mirrored to the af_info
func set_linked_color_color(index: int, color: Color):
	# Set the linked color in the linked_colors object
	linked_colors[int(index)].set_color(color)
	# Also set the linked color in the af_info
	af_info.LinkedColors[int(index)] = color

func set_unique_limb_color(limb_name: String, color_index: int, color: Color):
	# Remove link if there is one
	if has_linked_color_link(limb_name, color_index):
		remove_linked_color_link(limb_name, color_index)
	var image_palette: ImagePalette = component_objects[String(limb_name)].image_palette
	# Set color in image palette
	image_palette.set_color(color_index, color)
	# Save color in af_info
	var limb_info: Dictionary = af_info[String(limb_name)]
	# Create UniqueColors Dictionary if needed
	if not "UniqueColors" in limb_info:
		limb_info.UniqueColors = {}
	limb_info.UniqueColors[int(color_index)] = color

func set_limb_color_texture(limb_name: String, texture: Texture):
	var limb_node: MeshInstance = component_objects[String(limb_name)].node
	var limb_material: Material = limb_node.get_surface_material(0)
	limb_material.set("shader_param/color_sampler", texture)

func set_limb_color_texture_from_path(path: Array):
	var limb_name: String = path[0]
	var texture: Texture = AF_Maker.R.get_af_resource(path)
	set_limb_color_texture(limb_name, texture)

func set_visual_layer(layer: int, value: bool):
	for child in skeleton_node.get_children():
		if child is MeshInstance:
			child.set_layer_mask_bit(layer, value)

#func get_unique_colors() -> Array:
#	var colors: Array = []
#
#	# Get Unique colors from parts
#	for part_id in component_objects:
#		pass
#
#	return colors

func get_all_colors() -> Array:
	var colors: Array = []
	# Make color references for each color that exists so
	# I can point to the color data in the editor
	# Get Linked colors
	for linked_color_index in range(linked_colors.size()):
		var color_reference: Dictionary = {
			"type" : "linked_color",
			"linked_color_index" : linked_color_index,
			"linked_color" : linked_colors[linked_color_index]
		}
		colors.append(color_reference)
	
	# Append unique colors
	for limb_id in component_objects.keys():
		var part: Dictionary = af_info[limb_id]
		if "UniqueColors" in part:
			var unique_colors: Dictionary = part["UniqueColors"]
			for image_palette_index in unique_colors.keys():
				var color_reference: Dictionary = {
					"type" : "unique_color",
					"image_palette_index" : image_palette_index,
					"limb_id" : limb_id,
					"unique_color" : unique_colors[image_palette_index]
				}
				colors.append(color_reference)
	
	return colors

func get_limb_colors(limb_id: String) -> Array:
	var limb_colors: Array = []
	
	# Limb colors I need to get the colors from the limb, single limb
	var limb_info: Dictionary = af_info[limb_id]
	if "LinkedColors" in limb_info:
		for image_palette_index in limb_info.LinkedColors.keys():
			var color_reference: Dictionary = {
				"type" : "linked_color",
				"image_palette_index" : image_palette_index,
				"linked_color_index" : limb_info.LinkedColors[image_palette_index]
			}
			color_reference.linked_color = linked_colors[color_reference.linked_color_index]
			limb_colors.append(color_reference)
	if "UniqueColors" in limb_info:
		for image_palette_index in limb_info.UniqueColors.keys():
			var color_reference: Dictionary = {
				"type" : "unique_color",
				"image_palette_index" : image_palette_index,
				"color" : limb_info.UniqueColors[image_palette_index]
			}
			limb_colors.append(color_reference)
	# Sort colors by image_palette_index
	limb_colors.sort_custom(self, "sort_color_references_by_image_palette_index")
	
	return limb_colors

func sort_color_references_by_image_palette_index(a: Dictionary, b: Dictionary):
	return a.image_palette_index < b.image_palette_index

func get_eye_materials(eyes: Array = ["L", "R"]) -> Dictionary:
	if not is_instance_valid(head_node):
		return {}
	var eye_materials: Dictionary = {}
	if "L" in eyes:
		eye_materials.L = head_node.get_surface_material(1)
	if "R" in eyes:
		eye_materials.R = head_node.get_surface_material(2)
	return eye_materials

# =============================
# ===== ANIMATION CONTROL =====
# =============================

onready var anim_tree_root: AnimationNodeBlendTree = anim_tree.tree_root

export var anim_full_body_state: String = "Walk" setget set_full_body_state
export var anim_upper_body_state: String = "" setget set_upper_body_state
export var anim_full_body_speed: float = 1.0 setget set_full_body_speed
#export var anim_full_body_seek: float = -1.0 setget set_full_body_seek
export var anim_upper_body_blend: float = 0.0 setget set_upper_body_blend
export var state_machine_transition: AnimationNodeStateMachineTransition

signal full_body_state_changed(value, previous_value)
signal upper_body_state_changed(value, previous_value)

func load_all_anims():
	# add_anim for each anim in af_info
	for state_machine_id in af_info.Anims.keys():
		var state_machine_anims: Dictionary = af_info.Anims[state_machine_id]
		for anim_state_id in state_machine_anims:
			var path: Array = state_machine_anims[anim_state_id]
			add_anim(path, state_machine_id)

func add_anim(path: Array, state_machine_id: String = "FullBody"):
	# Get anim resource from path in af_resources
	var anim_res = AF_Maker.R.get_af_resource(path).duplicate()
	# Get state_id from the path and state machine from id
	var state_id: String = path[path.size() - 2]
	var state_machine: AnimationNodeStateMachine = get_state_machine(state_machine_id)
	# Remove old state anim if there is one
	if state_machine.has_node(state_id):
		state_machine.remove_node(state_id)
	# Add anim resource to state_machine
	state_machine.add_node(state_id, anim_res)
	# Add transitions between all other state anims in state machine
	for other_state_id in af_info.Anims[state_machine_id].keys():
		if state_machine.has_node(other_state_id) and state_id != other_state_id:
			# Make connections
			state_machine.add_transition(state_id, other_state_id, state_machine_transition.duplicate())
			state_machine.add_transition(other_state_id, state_id, state_machine_transition.duplicate())

func play_anim_state(state_id: String, state_machine_id: String = "FullBody", reset: bool = true):
#	G.debug_print("play_anim_state %s %s" % [state_id, state_machine_id])
	# Play state anim in state machine
	var state_machine: AnimationNodeStateMachine = get_state_machine(state_machine_id)
	var state_machine_playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/%s/playback" % state_machine_id)
	if state_machine_playback.is_playing():
		# If traveling stop travel
		state_machine_playback.travel(state_id)
	else:
		state_machine_playback.start(state_id)

func set_bs2d_value(value: Vector2, state_id: String, state_machine_id: String = "FullBody"):
	# Set state's blend space 2d value within state machine
	anim_tree.set("parameters/%s/%s/blend_position" % [state_machine_id, state_id], value)

func get_bs1d_value(state_id: String, state_machine_id: String = "FullBody") -> float:
	return anim_tree.get("parameters/%s/%s/blend_position" % [state_machine_id, state_id])

func set_bs1d_value(value: float, state_id: String, state_machine_id: String = "FullBody"):
	# Set state's blend space 2d value within state machine
	anim_tree.set("parameters/%s/%s/blend_position" % [state_machine_id, state_id], value)

func set_blend_tree_seek(value: float, state_id: String, state_machine_id: String = "FullBody"):
	anim_tree.set("parameters/%s/%s/Seek/seek_position" % [state_machine_id, state_id], value)

func set_sub_blend_tree_seek(value: float, state_id: String, sub_state_machine_id: String, state_machine_id: String = "FullBody"):
	anim_tree.set("parameters/%s/%s/%s/Seek/seek_position" % [state_machine_id, sub_state_machine_id, state_id], value)

func get_state_machine(state_machine_id: String = "FullBody") -> AnimationNodeStateMachine:
	var state_machine = anim_tree_root.get_node(state_machine_id)
	if state_machine is AnimationNodeStateMachine:
		return state_machine
	return null

func get_state_machine_playback(state_machine_id: String = "FullBody") -> AnimationNodeStateMachinePlayback:
	return anim_tree.get("parameters/%s/playback" % state_machine_id)

func travel_in_state_machine(anim_state: String, sub_state_machine_id: String, state_machine_id: String = "FullBody"):
	var state_machine_playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/%s/%s/playback" % [state_machine_id, sub_state_machine_id])
	if state_machine_playback.is_playing():
		state_machine_playback.travel(anim_state)
	else:
		state_machine_playback.start(anim_state)

# ===== Blinking

onready var blink_timer: = $BlinkTimer
const blink_length: float = 3.5
const blink_variance: float = 1.2
const blink_duration: float = 0.08
var is_blinking: bool = true setget set_is_blinking

func blink():
	# Play anim
	blink_anim()
	if is_blinking:
		start_next_blink()

func start_next_blink():
	# Reset timer
	blink_timer.stop()
	# Get time until next blink
	var time_until_next_blink: float = blink_length + ((randf() * blink_variance) - (blink_variance / 2))
	blink_timer.wait_time = time_until_next_blink
		# Have a chance to double blink
	if randf() < 0.1:
		blink_timer.wait_time = 0.2
	blink_timer.start()

func blink_anim():
	# Change to blink image
	var blink_image: Texture = AF_Maker.R.get_af_resource(["Face", "Eye", "Blink1_L"])
	set_eyes_color_sampler(blink_image)
	# Blink blend shape
	set_blink_blend_shape(1.0)
	yield(get_tree().create_timer(blink_duration), "timeout")
	# Change back to eye image image
	# TEMP, I need to change this once I get to setting the eye image
	var eye_image: Texture = AF_Maker.R.get_af_resource(["Face", "Eye", "Eye1_L"])
	set_eyes_color_sampler(eye_image)
	# Blink blend shape
	set_blink_blend_shape(0.1)

func set_eyes_color_sampler(sampler: Texture):
	var eye_materials: Dictionary = get_eye_materials()
	for eye in eye_materials.keys():
		var eye_mat: Material = eye_materials[eye]
		eye_mat.set("shader_param/color_sampler", sampler)

func set_blink_blend_shape(value: float, eyes: Array = ["L", "R"]):
	if not is_instance_valid(head_node):
		return
	for eye in eyes:
		head_node.set("blend_shapes/EyeBlink%s" % eye, value)

func set_is_blinking(value: bool):
	is_blinking = value
	# Start or stop automatic blinking
	if is_blinking:
		start_next_blink()
	else:
		blink_timer.stop()

func _on_BlinkTimer_timeout():
	blink()

# ===== setget

func set_full_body_speed(value: float):
	anim_full_body_speed = value
	# Adjust full body anim speed within anim tree
	anim_tree.set("parameters/FullBodySpeed/scale", value)

#func set_full_body_seek(value: float):
#	anim_full_body_seek = value
#	# Adjust full body anim seek within anim tree
#	anim_tree.set("parameters/FullBodySeek/seek_position", value)

func set_upper_body_blend(value: float):
	anim_upper_body_blend = value
	# Adjust UpperBody's blend2 with FullBody within anim tree
	anim_tree.set("parameters/UpperBodyBlend/blend_amount", value)

# Move this to character
func set_full_body_state(value: String):
	var previous_value: String = anim_full_body_state
	anim_full_body_state = value
	# Play state anim
	play_anim_state(anim_full_body_state)
	emit_signal("full_body_state_changed", anim_full_body_state, previous_value)

# Move this to character
func set_upper_body_state(value: String):
	var previous_value: String = anim_upper_body_state
	anim_upper_body_state = value
	# Play state anim
	play_anim_state(anim_upper_body_state, "UpperBody")
	emit_signal("upper_body_state_changed", anim_upper_body_state, previous_value)
