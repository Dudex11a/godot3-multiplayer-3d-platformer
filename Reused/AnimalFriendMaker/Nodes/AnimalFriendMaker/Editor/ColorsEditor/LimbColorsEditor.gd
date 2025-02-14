extends ColorsEditor

onready var limb_colors_container: = vbox_container.get_node("LimbColors")

var current_limb_editor_color: EditorColor = null
var matching_available_editor_color: EditorColor = null
var current_limbs: Array = []

var update_color: bool = true

func setup(new_limbs: Array):
	current_limbs = new_limbs
	populate_with_available_colors()
	populate_with_limb_colors()
	# Wait for colors to be updated
	yield(get_tree(), "idle_frame")
	# Select first limb_color
	limb_color_pressed(null, CustomFocus.get_first_valid_node(limb_colors_container))
	# Adjust focus so it doesn't stop working, I don't know why it stops working
	af_maker_node.focus_cursor.set_current_node(limb_colors_container)

func populate_with_limb_colors(limbs: Array = current_limbs):
	# Remove old editor_colors
	for child in limb_colors_container.get_children():
		child.queue_free()
	# Add new colors
	for limb in limbs:
		var limb_colors: Array = af_maker_node.af_node.get_limb_colors(limb)
		for color_reference in limb_colors:
			var editor_color: EditorColor = AF_Maker.R.get_resource("editor_color_node").instance()
			limb_colors_container.add_child(editor_color)
			editor_color.color_reference = color_reference
			match color_reference.type:
				"linked_color":
					var linked_color: LinkedColor = color_reference.linked_color
					editor_color.color = linked_color.color
				"unique_color":
					editor_color.color = G.string_to_color(color_reference.color)
			editor_color.connect("pressed", self, "limb_color_pressed", [editor_color])

func get_matching_available_editor_color(limb_editor_color: EditorColor = current_limb_editor_color) -> EditorColor:
	var current_color_reference: Dictionary = current_limb_editor_color.color_reference
	for editor_color in available_colors_container.get_children():
		var available_color_reference: Dictionary = editor_color.color_reference
		if current_color_reference.type == available_color_reference.type:
			match current_color_reference.type:
				"linked_color":
					# Linked color references match
					if current_color_reference.linked_color_index == available_color_reference.linked_color_index:
						return editor_color
				"unique_color":
					# If image palette index matches
					if current_color_reference.image_palette_index == available_color_reference.image_palette_index:
						return editor_color
	return null

# ===== Signals

func available_color_pressed(focus: FocusCursor = null, editor_color: EditorColor = null):
	var af_node: AnimalFriend = af_maker_node.af_node
	# Link current_limb_editor_color with the available color that was pressed
	var available_color_reference: Dictionary = editor_color.color_reference
	var limb_color_reference: Dictionary = current_limb_editor_color.color_reference
	# Last editor_color index
	var last_index: int = current_limb_editor_color.get_index()
	for limb_id in current_limbs:
		match available_color_reference.type:
			"linked_color":
				# Change link to color that was pressed
				af_node.change_linked_color_link(
					limb_id,
					available_color_reference.linked_color_index,
					limb_color_reference.image_palette_index)
				# Update UI
				populate_with_limb_colors()
				populate_with_available_colors()
				# Wait for limb_colors to be updated
				yield(get_tree(), "idle_frame")
			"unique_color":
				pass 
				
	# Reselect the last active color
	limb_color_pressed(null, limb_colors_container.get_children()[last_index])
	
	# Update focus because the list get re-organized
	if is_instance_valid(focus):
		focus.set_current_node(available_colors_container)

func limb_color_pressed(focus: FocusCursor = null, editor_color: EditorColor = null):
	# Remove select graphic from last editor_color
	if is_instance_valid(current_limb_editor_color):
		current_limb_editor_color.selected = false
	# Set current editor_color
	current_limb_editor_color = editor_color
	# Display select graphic
	editor_color.selected = true
	# Update color in color picker
	update_color = false
	color_picker.color = editor_color.color
	update_color = true
	# Set linked icon in available colors to color associated
	# Remove linked icon from any previous available colors
	for available_editor_color in available_colors_container.get_children():
		available_editor_color.linked = false
	# Find linked color and set
	matching_available_editor_color = get_matching_available_editor_color()
	if is_instance_valid(matching_available_editor_color):
		matching_available_editor_color.linked = true
	# Update focus to color picker if focus used
	if is_instance_valid(focus):
		focus.set_current_node(color_picker)

func color_picker_changed(color: Color):
	var af_node: AnimalFriend = af_maker_node.af_node
	# Make currently selected color unique and set color
	if is_instance_valid(current_limb_editor_color) and update_color:
		current_limb_editor_color.color = color
		var color_reference: Dictionary = current_limb_editor_color.color_reference
		for limb in current_limbs:
			af_node.set_unique_limb_color(limb, color_reference.image_palette_index, color)
			match color_reference.type:
				"linked_color":
					# This string of events will remove the link icon and
					# update the color reference of the changed color
					# Last editor_color index
					var last_index: int = current_limb_editor_color.get_index()
					# Update the colors
					populate_with_limb_colors()
					populate_with_available_colors()
					# Wait for limb_colors to be updated
					yield(get_tree(), "idle_frame")
					# Reselect the last active color
					limb_color_pressed(null, limb_colors_container.get_children()[last_index])
				"unique_color":
					current_limb_editor_color.color = color
					color_reference.color = color
					# Update matching available_editor_color as well
					if is_instance_valid(matching_available_editor_color):
						matching_available_editor_color.color = color
