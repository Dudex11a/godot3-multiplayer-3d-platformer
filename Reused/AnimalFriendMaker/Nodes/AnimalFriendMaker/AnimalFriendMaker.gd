extends Control
class_name AnimalFriendMaker

onready var editor_node: = $Editor
onready var viewport_container_node: = $ViewportContainer
onready var viewport_node: = viewport_container_node.get_node("Viewport")
onready var af_node: AnimalFriend = viewport_node.get_node("World/AnimalFriend")

export var af_path: String = "user://AnimalFriends/"
# Save current af when exiting chartacter editor and on ready if there isn't a af_friend saved
export var current_af_path: String = "../current"
export var af_file_extention: Array = ["af"]

var af_info: AnimalFriendInfo = AnimalFriendInfo.new()

var focus_cursor: FocusCursor = null

signal exit

func _ready():
	# Set FileSelect path
	editor_node.file_selector_node.path = af_path
	editor_node.file_selector_node.valid_extentions = af_file_extention

func open():
	# Set af to walk
	af_node.play_anim_state("Walk")
	af_node.set_bs2d_value(Vector2(0, 0.5), "Walk")

# DEBUG
#func _input(event):
#	if event.is_action_pressed("character_action-2"):
#		# Focus
#		focus_cursor = CustomFocus.add_cursor()
#		yield(focus_cursor, "ready")
#		focus_cursor.set_current_node(self)
#		# AF
#		var new_af_info: = AnimalFriendInfo.new()
#		af_info = new_af_info
#		af_node.set_af_info(new_af_info)
##		initialize_af_from_path()

func initialize_af_from_path(new_current_af_path: String = current_af_path):
	current_af_path = new_current_af_path
	# Save af_info if there is no default save
	var file: File = File.new()
	var path: String = make_current_af_path()
	var current_af_exists: bool = file.file_exists(path)
	if current_af_exists:
		# Load file
		var json_file: Dictionary = G.load_json_file(path)
		af_info = af_info.from_dictionary(json_file)
	else:
		save_current_af()
	af_node.set_af_info(af_info)

func save_current_af():
	# Wait until current_af is a thing
	while(not is_instance_valid(af_info)):
		yield(get_tree(), "idle_frame")
	# Save
	G.save_json_file(make_current_af_path(), af_info.to_dictionary())

# Set af_info value based on the path given
func set_af_info_value(value, editor_path: Array = editor_node.current_path):
	var af_info_data = get_af_info_value_container(editor_path)
	G.debug_print("set_af_info_value %s" % af_info_data.index)
	af_info_data.parent[af_info_data.index] = value

func get_af_info_value(editor_path: Array = editor_node.current_path):
	var af_info_data = get_af_info_value_container(editor_path)
	G.debug_print("get_af_info_value %s" % af_info_data.index)
	return af_info_data.parent[af_info_data.index]

func get_af_info_value_container(editor_path: Array = editor_node.current_path) -> Dictionary:
	# Go through af_info to get to the value
	var af_info_path: Array = get_af_info_path(editor_path)
	var af_info_value = af_info
	for index in range(af_info_path.size()):
		G.debug_print("get_af_info_value_container index %s" % index)
		var path_value: String = af_info_path[index]
		if index < af_info_path.size() - 1:
			# If not the last value from the path, go further into af_info
			G.debug_print("get_af_info_value_container path_value %s" % path_value)
			af_info_value = af_info_value[path_value]
		else:
			# If this is the last value in the path, set the value in af_info
			return {
				"parent" : af_info_value,
				"index" : path_value
			}
	push_error("get_af_info_value_container: never got to value_container in path" + String(editor_path))
	return {}

func get_af_info_path(editor_path: Array = editor_node.current_path) -> Array:
	# Starting position for the layout value
	var layout_value = AF_Maker.directory_layout
	editor_path = editor_path.duplicate()
	editor_path.pop_front()
	for path_value in editor_path:
		G.debug_print("get_af_info_path path_value %s" % path_value)
		layout_value = layout_value[path_value]
	# Get the path to the af_info value to be changed
	var af_path: Array = []
	if "path" in layout_value:
		af_path = layout_value.path.duplicate()
	else:
		push_error("There is no path in the editor path of: " + String(editor_path))
	return af_path

func make_current_af_path() -> String:
	return af_path + current_af_path + "." + af_file_extention[0]

# ===== Focus

# Goto editor
func focus_entered(focus: FocusCursor):
	focus.set_current_node(editor_node)

# ===== Settings

func SetShadows(value: Dictionary = O3DP.get_shadow_settings()):
	O3DP.set_shadows_in_viewport(viewport_node, value)

# ===== Signals

func _on_Editor_exit():
	emit_signal("exit")

func _on_Color_color_changed(color: Color):
	# Update af_info
	set_af_info_value(color)
	# Update character with new af_info
	af_node.set_af_info(af_info)
