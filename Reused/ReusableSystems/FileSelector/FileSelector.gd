extends Control
class_name FileSelector

onready var background_node: = $_Background
onready var file_list_node: = $ScrollContainer/FileList

export var file_item_res: PackedScene
export(Array, String) var valid_extentions = []
export var path: String = "res://"

var refreshing_file_list: bool = false

signal file_list_loaded
signal file_selected # params (file_name: String, file_path: String)
signal file_hovered # params (file_name: String, file_path: String)
signal focus_cursor_exit_file_list # params (focus_cursor: FocusCursor)

signal list_looped # params (focus: FocusCursor, looped: int)

func refresh_file_list():
	refreshing_file_list = true
	# Remove old FileItems
	for child in file_list_node.get_children():
		child.queue_free()
	# Create new FileItems
	var unfiltered_file_paths: Array = G.get_file_paths(path, true, true)
	var file_paths: Array = []
	# Filter through files by extentions if there are any to sort by
	if valid_extentions.size() > 0:
		for extention in valid_extentions:
			for file_path in unfiltered_file_paths:
				var file_extention: String = file_path.get_extension()
				if file_extention == extention:
					file_paths.append(file_path)
	else:
		file_paths = unfiltered_file_paths
	# Filter file_paths to only include valid file extentions
	for file_path in file_paths:
		create_file_item(file_path)
	# Done
	refreshing_file_list = false
	emit_signal("file_list_loaded")

func create_file_item(file_path: String):
	# Get file_name from path
	var file_name: String = file_path.get_file().replace("." + file_path.get_extension(), "")
	# Create FileItem
	var file_item_node: FileItem = file_item_res.instance()
	file_list_node.add_child(file_item_node)
	file_item_node.setup(file_name, file_path)
	# Connect selected and hovered for buttons
	file_item_node.connect("selected", self, "file_selected")
	file_item_node.connect("hovered", self, "file_hovered")

func remove_file_item(file_path: String):
	# Find file item
	for child in file_list_node.get_children():
		if child.path == file_path:
			# Remove it
			child.queue_free()

func file_selected(file_name: String, file_path: String):
	emit_signal("file_selected", file_name, file_path)

func file_hovered(file_name: String, file_path: String):
	emit_signal("file_hovered", file_name, file_path)

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus_goto_files(focus)

func ui_accept_action(focus: FocusCursor):
	pass

func ui_cancel_action_pp(focus: FocusCursor, parent: Node):
	emit_signal("focus_cursor_exit_file_list")

func looped(focus: FocusCursor, looped: int):
	emit_signal("list_looped", focus, looped)

func focus_goto_files(focus: FocusCursor, top: bool = true):
	# Wait until file_list is loaded
	while refreshing_file_list:
		yield(get_tree(), "idle_frame")
	# If there are files set the focus to the first child,
	# otherwise set the focus to the background to represent nothing.
	var node: Node = null
	if top:
		node = CustomFocus.get_first_valid_node(file_list_node)
	else:
		node = CustomFocus.get_last_valid_node(file_list_node)
	if is_instance_valid(node):
		focus.set_current_node(node)

func _on_FileList_exit():
	emit_signal("focus_cursor_exit_file_list")
