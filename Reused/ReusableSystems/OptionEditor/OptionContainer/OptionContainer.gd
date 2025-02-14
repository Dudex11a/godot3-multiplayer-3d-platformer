extends ScrollContainer
class_name OptionContainer
func get_class() -> String: return "OptionContainer"

onready var option_container_node: = $OptionContainer

signal looped(focus, loop)
signal cancel

func _ready():
	# Reparent children to option conainer node so I don't have to open up
	# Editable Children when I add nodes in the scene editor.
	for child in .get_children():
		if child != option_container_node:
			G.reparent_node(child, option_container_node)
			connect_node(child)

func get_children() -> Array:
	return $OptionContainer.get_children()

func add_child(node: Node, legible_unique_name: bool = false):
	option_container_node.add_child(node, legible_unique_name)
	connect_node(node)

func connect_node(node: Node):
	if node is OptionItem:
		node.connect("cancel", self, "cancel")

func get_first_option() -> Node:
	return CustomFocus.get_first_valid_node(option_container_node)

func get_last_option() -> Node:
	return CustomFocus.get_last_valid_node(option_container_node)

func cancel():
	emit_signal("cancel")

# ===== Focus

func focus_entered(focus: FocusCursor):
	# Go to first option
	var first_option: Node = get_first_option()
	if is_instance_valid(first_option):
		focus.set_current_node(first_option)

func focus_looped_pp(focus: FocusCursor, looped: int, parent: Node):
	# If in DTabContainer, go up to tabs on up loop
	if looped == 1:
		var self_parent = get_parent()
		if self_parent is DTabContainerContent:
			yield(get_tree(), "idle_frame")
			focus.set_current_node(self_parent.dtab_container.get_tab_hbox_container())
			return
	
	emit_signal("looped", focus, looped)
