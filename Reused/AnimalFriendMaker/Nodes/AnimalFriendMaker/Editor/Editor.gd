extends Control

onready var af_maker_node: = get_parent()
onready var path_node: = $Path
onready var path_container_node: = path_node.get_node("ScrollContainer/PathContainer")
onready var directories_node: = $Directories
onready var directory_container_node: = directories_node.get_node("DirectoryContainer")
onready var dt_timer_node: = $DirectoryTransitionTimer
onready var controls_bottom_node: = $ControlsBottom
onready var back_button_node: = path_node.get_node("ScrollContainer/PathContainer/BackButton")
onready var save_button_node: = controls_bottom_node.get_node("HBoxContainer/SaveButton")
onready var load_button_node: = controls_bottom_node.get_node("HBoxContainer/LoadButton")
onready var file_select_node: = $FileSelect
onready var file_selector_node: = file_select_node.get_node("FileSelector")

# Curve for transition animation
export var dt_curve: Curve

const default_path: Array = ["Home"]

var current_path: Array = default_path
var active_directory: Control = null
# The af_info that is set, I have this to keep it separate when previewing other af_info
var stored_af_info: AnimalFriendInfo = null

signal exit

func _ready():
	create_directory()
	goto_directory()

#func _input(event: InputEvent):
#	# If focus_cursor is in the directories, make next and previous buttons go forward and back in the path
#	var focus_cursor: FocusCursor = af_maker_node.focus_cursor
#	if is_instance_valid(focus_cursor):
#		var is_focus_cursor_in_directories: bool = directory_container_node.is_a_parent_of(focus_cursor.current_node)
#		if is_focus_cursor_in_directories:
#			if event.is_action_pressed("ui_next"):
#				# If current_node is a DirectoryButton, press that button
#				var current_node: Node = focus_cursor.current_node
#				if current_node is DirectoryButton:
#					current_node.ui_accept_action(focus_cursor)
#					# Play sound
#					CustomFocus.A.play_sound("Select2")
#			if event.is_action_pressed("ui_previous"):
#				if previous_directory():
#					# Play sound if success on previous directory
#					CustomFocus.A.play_sound("Unselect1")

func goto_directory(path: Array = current_path, function: String = "directory", args: Array = []):
	update_path(path, function)
	var old_path: Array = current_path.duplicate()
	var old_directory: Control = active_directory
	current_path = path.duplicate()
	var directory_string: String = make_path_string(path)
	# Get the new directory and make all nodes not visible
	for child in directory_container_node.get_children():
		child.visible = false
	match function:
		"directory":
			active_directory = directory_container_node.get_node(directory_string)
		"limb_colors_editor":
			active_directory = directory_container_node.get_node("LimbColorsEditor")
			if args.size() > 0:
				active_directory.setup(args)
		"old_part_colors_editor":
			active_directory = directory_container_node.get_node("OldPartColorsEditor")
			if args.size() > 0:
				active_directory.setup(args)
		"all_colors_editor":
			active_directory = directory_container_node.get_node("AllColorsEditor")
			active_directory.setup()
		"texture_editor":
			active_directory = directory_container_node.get_node("TextureEditor")
			if args.size() > 0:
				active_directory.setup(args)
				# Wait a sec to setup
				yield(get_tree(), "idle_frame")
		_:
			active_directory = directory_container_node.get_node(function.capitalize())
	active_directory.visible = true
	# Deal with focus
	if is_instance_valid(af_maker_node.focus_cursor):
		af_maker_node.focus_cursor.set_current_node(directories_node)
	# 
	# TRANSITION ANIMATION
	if is_instance_valid(old_directory) and old_directory != active_directory:
		old_directory.visible = true
		# Anim
		var reverse_anim: bool = old_path.size() >= path.size()
		dt_timer_node.stop()
		dt_timer_node.start()
		while not dt_timer_node.is_stopped():
			# Get time remaining
			var timer_remaining: float = dt_curve.interpolate(
				dt_timer_node.time_left / dt_timer_node.wait_time
			)
			# Reverse the animation if need be
			if reverse_anim:
				timer_remaining = abs(timer_remaining - 1)
			# Adjust positions
			old_directory.rect_position.x = (old_directory.rect_size.x * timer_remaining)
			active_directory.rect_position.x = active_directory.rect_size.x * timer_remaining
			
			if reverse_anim:
				active_directory.rect_position.x -= active_directory.rect_size.x
			else:
				old_directory.rect_position.x -= old_directory.rect_size.x
			yield(get_tree(), "idle_frame")
		# Guarantee positions reset after animation
		old_directory.rect_position = Vector2.ZERO
		old_directory.visible = false
		active_directory.rect_position = Vector2.ZERO
		active_directory.visible = true

func update_path(path: Array, function: String):
	# Remove old path nodes
	for child in path_container_node.get_children():
		if child.name != "BackButton":
			child.queue_free()
	# Create path nodes
	var path_directory: Array = []
	for option in path:
		path_directory.append(option)
		var path_button = AF_Maker.R.get_instance("path_button_node")
		path_container_node.add_child(path_button)
		path_button.path_name = option
		path_button.path = path_directory.duplicate()
		# Previous paths are directories but the current option is what function was given
		if path[path.size() - 1] == option:
			path_button.function = function
		else:
			path_button.function = "directory"
		path_button.connect("path_button_pressed", self, "goto_directory")

func enter_directory(option: String):
	current_path.append(option)
	goto_directory()

# Go to the directory one prior, if you can't go back any furthur return false
func previous_directory() -> bool:
	if current_path.size() > 1:
		var new_path: Array = current_path.duplicate()
		new_path.pop_back()
		goto_directory(new_path)
		return true
	else:
		emit_signal("exit")
	return false

func make_path_string(directory: Array = current_path) -> String:
	var value: String = ""
	for option in directory:
		value += option + AF_Maker.directory_divider
	# Remove last directory divider
	value = value.left(value.length() - 1)
	return value

func create_directory(dictionary: Dictionary = AF_Maker.directory_layout, path: Array = default_path):
	var current_directory_node = make_directory_node(path)
	for key in dictionary.keys():
		var value = dictionary[key]
		var new_path = path.duplicate()
		new_path.append(key)
		# Create Directory Button
		var button = AF_Maker.R.get_instance("directory_button_node")
		button.name = key
		current_directory_node.add_child(button)
		button.path = new_path.duplicate()
		button.connect("goto_directory", self, "goto_directory")
		button.connect("previous_directory", self, "previous_directory")
		# Create new directory if this child is one
		if value is Dictionary:
			# This is not a directory
			if "_type" in value:
				# Change button based on value type
				button.function = value._type
			# This is a directory
			else:
				button.function = "directory"
				# Create sub-directory
				create_directory(value, new_path)
			if "args" in value:
				button.args = value.args
		if value is String:
			pass

func make_directory_node(path: Array) -> Directory:
	var path_string: String = make_path_string(path)
	var directory_node = AF_Maker.R.get_instance("directory_node")
	directory_container_node.add_child(directory_node)
	directory_node.name = path_string
	return directory_node

func get_directory_node_from_path(path: Array = current_path) -> Node:
	var directory_node: Node = directory_container_node.get_node_or_null(make_path_string(path))
	if directory_node is AFDirectory:
		return directory_node
	return null

func toggle_file_selector(open: bool):
	file_select_node.visible = open
	if open:
		file_selector_node.refresh_file_list()
		# Wait a moment for refresh_file_list
		yield(get_tree(), "idle_frame")
		# Update stored_af_info to remember
#		var copied_af_info: AnimalFriendInfo = AnimalFriendInfo.new()
#		copied_af_info.from_dictionary(af_maker_node.af_info.to_dictionary())
		stored_af_info = af_maker_node.af_info
		# Focus
		if is_instance_valid(af_maker_node.focus_cursor):
			file_selector_node.focus_goto_files(af_maker_node.focus_cursor)
	else:
		# Update the af_node to the af_info in the af_node
		af_maker_node.af_node.set_af_info(stored_af_info)
		af_maker_node.af_info = af_maker_node.af_node.af_info
		# Focus goto load button
		af_maker_node.focus_cursor.set_current_node(get_node("ControlsBottom/HBoxContainer/LoadButton"))
		goto_directory(default_path)

func save_af(af_name: String, af_info: AnimalFriendInfo = af_maker_node.af_info):
	# Get file path
	var af_path: String = make_af_path(af_name)
	# Check if file already exists
	var file: File = File.new()
	if file.file_exists(af_path):
		# Open overwrite_popup TEMP
		return
	# Save the af_info
	G.save_json_file(af_path, af_info.to_dictionary())

func make_af_path(af_name: String) -> String:
	return file_selector_node.path + af_name + "." + file_selector_node.valid_extentions[0]

# ===== Focus

# Goto current directory
func focus_entered(focus: FocusCursor):
	focus.set_current_node(directories_node)

func focus_directory_looped(focus: FocusCursor, looped: int):
	match looped:
		G.LOOPED_BACK:
			focus.set_current_node(path_node)
		G.LOOPED_FORWARD:
			focus.set_current_node(controls_bottom_node)

# ===== Signals

func _on_FileSelector_file_hovered(file_name: String, file_path: String):
	var af_info: AnimalFriendInfo = AnimalFriendInfo.new()
	af_info.from_dictionary(G.load_json_file(file_path))
	# Reload af_node
	af_maker_node.af_node.set_af_info(af_info)

func _on_FileSelector_focus_cursor_entered(focus: FocusCursor):
	file_selector_node.focus_goto_files(focus)

func _on_FileSelect_BackButton_pressed():
	# Exit file select and change focus
	toggle_file_selector(false)
	
func _on_FileSelector_focus_cursor_exit_file_list():
	toggle_file_selector(false)

func _on_FileSelector_list_looped(focus: FocusCursor, looped: int):
	match looped:
		G.LOOPED_FORWARD, G.LOOPED_BACK:
			focus.set_current_node(get_node("FileSelect/Back"))

func _on_FileSelector_file_selected(file_name: String, file_path: String):
	# Load af_info from file
	var af_info: AnimalFriendInfo = AnimalFriendInfo.new()
	af_info.from_dictionary(G.load_json_file(file_path))
	# Reload af_node
	af_maker_node.af_node.set_af_info(af_info)
	stored_af_info = af_info
	# Back out of FileSelect
	toggle_file_selector(false)
	goto_directory(default_path)
	af_maker_node.focus_cursor.set_current_node(directories_node)

func _on_LoadButton_pressed():
	toggle_file_selector(true)

func _on_ExitButton_pressed():
	emit_signal("exit")

func _on_BackButton_pressed():
	# Goto previous directory, if it didn't go to the previous directory
	# emit exit signal
	if not previous_directory():
		emit_signal("exit")

func _on_SaveButton_pressed():
	# Create file name
	var path: String = ""
	var index: int = 0
	var end: bool = false
	while not end:
		# Increment
		index += 1
		var dir: = Directory.new()
		path = make_af_path(String(index))
		# Check if this file exists
		end = not dir.file_exists(path)
	# Save the character
	save_af(String(index))
	# Show a message that the character is saved
	var save_message: String = "Character saved as \"%s\"." % index
	af_maker_node.focus_cursor.create_notification_popup(save_message)
