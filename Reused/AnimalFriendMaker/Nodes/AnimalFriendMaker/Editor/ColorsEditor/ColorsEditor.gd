extends BasicDirectory
class_name ColorsEditor

onready var available_colors_container: = vbox_container.get_node("AvailableColors")
onready var color_picker: = vbox_container.get_node("DColorPicker")

signal color_pressed(color_reference)

func _ready():
	# Connect color picker
	color_picker.connect("color_changed", self, "color_picker_changed")

func populate_with_available_colors():
	# Remove old editor_colors
	for child in available_colors_container.get_children():
		child.queue_free()
	# Populate available colors container with colors
	for color_reference in af_maker_node.af_node.get_all_colors():
		var color_node = AF_Maker.R.get_resource("editor_color_node").instance()
		available_colors_container.add_child(color_node)
		color_node.color_reference = color_reference
		color_node.connect("pressed", self, "available_color_pressed", [color_node])
		# Make color nodes
		match color_reference.type:
			"unique_color":
				color_node.color = G.string_to_color(color_reference.unique_color)
			"linked_color":
				var linked_color: LinkedColor = color_reference.linked_color
				color_node.color = linked_color.color
	yield(get_tree(), "idle_frame")

func edit_character_color(color_reference: Dictionary, color: Color):
	var af_node: AnimalFriend = af_maker_node.af_node
	match color_reference.type:
		"linked_color":
			af_node.set_linked_color_color(color_reference.linked_color_index, color)
		"unique_color":
			var ipi: = int(color_reference.image_palette_index)
			var limb_id: String = color_reference.limb_id
			af_node.set_unique_limb_color(limb_id, ipi, color)

# ===== Signals

func available_color_pressed(focus: FocusCursor = null, editor_color: EditorColor = null):
	pass

func color_picker_changed(color: Color):
	pass
