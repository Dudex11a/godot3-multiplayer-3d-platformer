extends ColorsEditor

var current_editor_color: EditorColor = null

func setup():
	# Wait for colors to populate
	populate_with_available_colors()
	# Select first available color
	available_color_pressed(null, CustomFocus.get_first_valid_node(available_colors_container))
	# Wait for colors to be populated
	yield(get_tree(), "idle_frame")
	# Set cursor focus
	af_maker_node.focus_cursor.set_current_node(available_colors_container)

# ===== Signals

func available_color_pressed(focus: FocusCursor = null, editor_color: EditorColor = null):
	# Remove select graphic from last editor_color
	if is_instance_valid(current_editor_color):
		current_editor_color.selected = false
	# Set current editor_color
	current_editor_color = editor_color
	# Display select graphic
	editor_color.selected = true
	# Update color in color picker
	color_picker.color = editor_color.color
	# Update focus to color picker if focus used
	if is_instance_valid(focus):
		focus.set_current_node(color_picker)

func color_picker_changed(color: Color):
	if is_instance_valid(current_editor_color):
		edit_character_color(current_editor_color.color_reference, color)
		current_editor_color.color = color
