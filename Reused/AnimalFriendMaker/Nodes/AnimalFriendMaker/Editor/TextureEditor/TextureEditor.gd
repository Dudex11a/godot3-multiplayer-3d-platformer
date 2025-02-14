extends Control

onready var vbox_container_node: = $ScrollContainer/VBoxContainer

onready var editor_node: = get_parent().get_parent().get_parent()
onready var main_node: = editor_node.get_parent()

var limbs_to_edit: Array = []

func setup(args: Array):
	limbs_to_edit = args.duplicate()
	# Remove prior buttons
	for child in vbox_container_node.get_children():
		child.queue_free()
	yield(get_tree(), "idle_frame")
	#
	var limb_name: String = args[0]
	var part_name: String = main_node.af_info[limb_name].PartName
	var full_path: Array = args.duplicate()
	full_path.append(part_name)
	full_path.append("Texture")
	# For each texture of current part
	var textures = AF_Maker.R.get_af_resource(full_path)
	# Make buttons for texture editor
	for texture_name in textures.keys():
		var texture: StreamTexture = textures[texture_name]
		# Make button for texture
		var button: TextureEditorButton = AF_Maker.R.get_instance("texture_editor_button_node")
		vbox_container_node.add_child(button)
		button.text = texture_name
		button.connect("pressed", self, "change_af_texture", [part_name, texture_name])

func change_af_texture(part_name: String, texture_name: String):
	for limb_name in limbs_to_edit:
		var texture_path: Array = [limb_name, part_name, "Texture", texture_name]
		# Change model's texture
		main_node.af_node.set_limb_color_texture_from_path(texture_path)
		# Update af_info
		main_node.af_info[limb_name].ColorTexture = texture_path

# What node to go to when this is opened
#func goto_focus_node(focus_cursor: FocusCursor):
#	# Wait a moment until done setting up
#	yield(get_tree(), "idle_frame")
#	var node_to_focus: Node = vbox_container_node.get_children()[0]
#	focus_cursor.set_current_node(node_to_focus)

func get_first_node() -> Node:
	return CustomFocus.get_first_valid_node(vbox_container_node)
	
func get_last_node() -> Node:
	return CustomFocus.get_last_valid_node(vbox_container_node)
