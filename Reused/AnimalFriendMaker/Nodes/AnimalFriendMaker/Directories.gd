extends Control

onready var directory_container_node: = $DirectoryContainer

var current_directory: Array = ["Home"]

func _ready():
	goto_directory()

func goto_directory(directory: Array = current_directory):
	current_directory = directory
	var directory_string: String = make_directory_string(directory)
	# Only show directory that is being goto
	for child in directory_container_node.get_children():
		child.visible = child.name == directory_string
	# Create path nodes
	for option in directory:
		var path_button = AF_Maker.R.get_instance("path_button_node")

func enter_directory(option: String):
	current_directory.append(option)
	goto_directory()

func exit_directory():
	print("pop_back before: ", current_directory)
	current_directory.pop_back()
	print("pop_back after: ", current_directory)
	goto_directory()

func make_directory_string(directory: Array = current_directory) -> String:
	var value: String = ""
	for option in directory:
		value += option + AF_Maker.directory_divider
	# Remove last directory divider
	value = value.left(value.length() - 1)
	return value
