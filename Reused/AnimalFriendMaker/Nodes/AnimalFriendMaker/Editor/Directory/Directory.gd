extends Control
class_name AFDirectory

onready var option_container_node: = $ScrollContainer/OptionContainer

# Add directory buttons under the option container
func add_child(node: Node, legible_unique_name: bool = false):
	if node is DirectoryButton:
		option_container_node.add_child(node, legible_unique_name)
	else:
		.add_child(node, legible_unique_name)

func get_directory_button(button_name: String = option_container_node.get_children()[0].name) -> DirectoryButton:
	var node = option_container_node.get_node_or_null(button_name)
	# Fall back if failed, this can happen when given a wrong button_name (which does happen)
	if not is_instance_valid(node):
		node = option_container_node.get_children()[0]
	if node is DirectoryButton:
		return node
	return null

func focus_entered(focus: FocusCursor):
	focus.set_current_node(get_first_node())

func get_first_node() -> Node:
	return CustomFocus.get_first_valid_node(option_container_node)

func get_last_node() -> Node:
	return CustomFocus.get_last_valid_node(option_container_node)
